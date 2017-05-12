package Getopt::Base;
$VERSION = v0.0.3;

use warnings;
use strict;
use Carp;

=head1 NAME

Getopt::Base - foundation for oo GetOpt support

=head1 SYNOPSIS

  package Getopt::YAWTDI;

  use base 'Getopt::Base';
  ...

  sub main {
    my $opt = Getopt::YAWTDI->new(%setup)->process(\@args) or return;

    my $foo = $opt->foo;
    ...
  }

=head1 ABOUT

This module provides a foundation on which to build numerous forms of
Getopt:: support, but does not supply any particular frontend.

=head1 ALPHA

This module is still growing.  Your help with documentation and API
suggestions are welcome.

=head1 Features

Modules built on this foundation will have the following features:

=over

=item object-based output

The get() method returns an object with accessors.  You may supply your
own object.

=item loadable modes

A program (such as svn, svk, git) with multiple modes may cleanly load
an additional set of options during @args processing.

=item long/short options, types, &c

Options are of the --long-form or the '-s' (short form).  Short options
may be bundled (opterand must follow the bundle.)  Long options can be
give in one or two-word form (e.g. '--opt=foo' or '--opt foo'.)  Options
may be 'typed' as boolean/string/integer/float and and be of the single
or multi-element array/hash form.  All boolean-type options
automatically support the '--no-foo' negated form.

=item ordered callbacks

Items in C<actions> will be triggered in as-defined order before any of
the items in C<options> are processed.  This allows for e.g. loading
config files or printing help/version messages.

=item cleanly callable

It should not be necessary for any callbacks to exit().  If one of them
called stop(), then get() returns false and the caller should do the
same.  Errors will throw an error with croak().

=back

=cut

=head1 Constructor

=head2 new

  my $go = Getopt::Base->new(%setup);

=cut

sub new {
  my $package = shift;
  my $class = ref($package) || $package;
  my $self = {
    opt_data   => {},
    short      => {},
    aliases    => {},
    positional => [],
  };
  bless($self, $class);
  $self->_prepare(@_);
  return($self);
} # end subroutine new definition
########################################################################

=head2 _prepare

  $self->_prepare(%params);

=cut

sub _prepare {
  my $self = shift;
  my %params = @_;

  my $options = $params{options} || [];
  (@$options % 2) and croak("odd number of elements in 'options'");
  for(my $i = 0; $i < @$options; $i+=2) {
    $self->add_option($options->[$i], %{$options->[$i+1]});
  }

  if(my $pos = $params{positional}) {
    $self->add_positionals(@$pos);
  }

  foreach my $key (qw(arg_handler)) {
    $self->{$key} = $params{$key} if(exists($params{$key}));
  }

} # end subroutine _prepare definition
########################################################################

=head1 Methods

=head2 process

Process the @argv, removing options and opterands in-place.

  my $obj = $go->process(\@argv) or return;

The storage object may also be passed explicitly.

  $obj = $go->process(\@argv, object => $obj) or return;

=cut

sub process {
  my $self = shift;
  my $args = shift;
  (@_ % 2) and croak('odd number of arguments');
  my %also = @_;

              local $self->{stopped} = 0; # loop control
  my $keep  = local $self->{tokeep}  = [];
  my $toset = local $self->{toset}   = [];

  my $o     = local $self->{object}  = $also{object} || $self->object;

  while(@$args) {
    last if($self->{stopped});
    my $arg = shift(@$args);

    last if($arg eq '--');

    my ($dash) = $arg =~ m/^(-*)/;

    if($dash eq '') { $self->process_arg($arg); }
    elsif($dash eq '--') {
      if($arg =~ s/=(.*)//) { unshift(@$args, $1); }
      $self->process_option($self->_find_option($arg), $args);
    }
    elsif($dash eq '-') {
      my @got = $self->_unbundle($arg);
      my $last = pop(@got);
      $self->process_option($_) for(@got);
      $self->process_option($last, $args);
    }
    else { croak("oops: $arg") }
  }
  @$args = (@$keep, @$args);
  return() if($self->{stopped} < 0);

  my %is_set = map({$_->[0]->{name} => 1} @$toset);

  # always call hooked options with defined defaults
  #   (or else need to define a setting for this)
  foreach my $d (
    grep {$_->{call} and $_->{default}} values %{$self->{opt_data}}
  ) {
    next if $is_set{$d->{name}};
    my $def = $d->{default};
    $def = (ref($def) || '') eq 'CODE' ? $def->() : $def;
    $self->store($d, $def);
    $d->{call}->($self, $def);
  }

  # store all other inputs
  $self->store(@$_) for(@$toset);

  # evaluate positionals
  if(@$args) {
    # TODO this needs better logic for e.g. qw(list scalar scalar)
    foreach my $k (@{$self->{positional}}) {
      if(! $is_set{$k} or $self->{opt_data}{$k}{form}) {
        $self->store($k, shift(@$args));
      }
      @$args or last; # TODO check requiredness?
    }
  }

  # pickup any lazy defaults at this point
  if(my $def = $self->{_defaults}) {
    foreach my $do (@$def) {
      my ($k, $sub) = @$do;
      next if(exists $o->{$k});
      if(my $isa = $self->{opt_data}{$k}{isa}) {
        eval("require $isa");
        $@ and croak("ack: $@");
      }
      $self->store($k, $sub->());
    }
  }

  return($o);
} # end subroutine process definition
########################################################################

=head1 Controlling process()

=head2 stop

Stops the option processing when called from an action handler.  Always
returns false.

  $go->stop;

This is used for some forms of two-stage processing, where an action or
argument indicates that all of the remaining inputs are to be handled
elsewhere.

=head2 quit

Stops the option processing and prevents process() from returning an object .  Always returns false.

  $go->quit;

This is used for options like C<--version> and C<--help>, where you have
a terminal action.

=cut

sub stop { shift->{stopped} = 1; return(); }
sub quit { shift->{stopped} = -1; return(); }
########################################################################

=head1 Handling Inputs

=head2 process_option

  $self->process_option($name, \@argv);

=cut

sub process_option {
  my $self = shift;
  my ($name, $argv) = @_;
  $argv ||= [];

  my $toset = $self->{toset} or croak("out of context");

  my $d = ref($name) ? $name : $self->{opt_data}{$name} or
    croak("invalid: $name");
  $name = $d->{name};

  my $v;
  if($d->{type} eq 'boolean') {
    $v = $d->{opposes} ? 0 : 1;
  }
  else {
    @$argv or croak("option '$d->{name}' requires a value");
    $v = shift(@$argv);
  }

  if(my $sub = $d->{call}) {
    # TODO should we try to set a value?
    # TODO this should probably also be in the store() routine?
    my $check = $self->_checker($name);
    push(@$toset, [$d, $v]);
    return $sub->($self, $check->($v));
  }
  else {
    if(($d->{form}||'') eq 'HASH') {
      my @pair = split(/=/, $v, 2);
      croak("hash options require 'key=value' form (not '$v')")
        unless(@pair == 2);
      push(@$toset, [$d, @pair]);
    }
    else {
      push(@$toset, [$d, $v]);
    }
  }
} # end subroutine process_option definition
########################################################################

=head2 process_arg

  $self->process_arg($arg);

=cut

sub process_arg {
  my $self = shift;
  my ($arg) = @_;

  my $keep = $self->{tokeep} or croak("out of context");

  # check for mode
  if(my $do = $self->{arg_handler}) {
    # XXX what's the API for this?  Return vs stop and so on.
    $do->($self, $arg) or return;
  }

  push(@$keep, $arg);
} # end subroutine process_arg definition
########################################################################

=head1 Setup

=head2 add_option

Add an option.

  $go->add_option(name => %settings);

=cut

sub add_option {
  my $self = shift;
  my $name = shift;
  (@_ % 2) and croak("odd number of arguments");
  my %s = @_;

  croak("options cannot contain dashes ('$name')") if($name =~ m/-/);
  unless($s{form}) {
    my $ref = ref($s{default});
    $s{form} = $ref if($ref and $ref ne 'CODE');
  }
  else {
    $s{form} = uc($s{form});
  }

  unless($s{type}) {
    $s{type} = $s{form} ? 'string' : 'boolean';
  }

  if(my $callback = $s{call}) {
   croak("not a code reference") unless(ref($callback) ||'' eq 'CODE');
  }

  $s{name} = $name; # XXX I guess

  if($self->{opt_data}{$name}) {
    # warn "$name already defined\n";
    # TODO no big deal?
    croak("option '$name' already defined") unless($name =~ m/^no_/);
  }
  else {
    $self->{opt_data}{$name} = \%s;
  }

  if($s{type} eq 'boolean') {
    $self->{opt_data}{"no_$name"} = {%s, opposes => $name};
  }

  $self->add_aliases($name => $s{short}, @{$s{aliases} || []});

} # end subroutine add_option definition
########################################################################

# TODO this is only sugar then?
# =head2 add_action
# 
#   $go->add_action(name => sub {...}, %settings);
# 
# =cut
# 
# sub add_action {
#   my $self = shift;
#   my ($name, $callback, @and) = @_;
# 
#   $self->add_option($name, @and, call => $callback);
# } # end subroutine add_action definition
# ########################################################################

=head2 add_positionals

  $go->add_positionals(@list);

=cut

sub add_positionals {
  my $self = shift;
  my (@list) = @_;

  foreach my $item (@list) {
    my $d = $self->{opt_data}{$item} or
      croak("positional '$item' is not an option");
    croak("positional '$item' cannot be a boolean")
      if($d->{type} eq 'boolean');
    push(@{$self->{positional}}, $item);
  }
} # end subroutine add_positionals definition
########################################################################

=head2 add_aliases

  $go->add_aliases($canonical => \@short, @list);

=cut

sub add_aliases {
  my $self = shift;
  my ($canon, $short, @and) = @_;

  if(defined($short)) {
    my $st = $self->{short};
    ref($short) or croak("'shortlist' argument must be an array ref");
    foreach my $item (@$short) {
      croak("short options must be only one character ('$item')")
        if(length($item) != 1);
      croak("short option '$item' is already linked to '$st->{$item}'")
        if(exists($st->{$item}));
      $st->{$item} = $canon;
    }
  }

  my $at = $self->{aliases};
  foreach my $item (@and) {
    croak("aliases cannot contain dashes ('$item')") if($item =~ m/-/);
    croak("alias '$item' is already linked to '$at->{$item}'")
      if(exists($at->{$item}));
    $at->{$item} = $canon;
  }
  
} # end subroutine add_aliases definition
########################################################################

=head2 store

  $go->store(key => $value, $value2, ...);

=cut

sub store {
  my $self = shift;
  my ($k, @v) = @_;

  my $o = $self->{object} or croak("out of context");
  my $d = ref($k) ? $k : $self->{opt_data}{$k} or
    croak("no such option: $k");
  $k = $d->{name};

  my $check = $self->_checker($k);

  if(my $form = $d->{form}) {
    if($form eq 'HASH') {
      $o->{$k} ||= {};
      (@v % 2) and croak("odd number of values to store for '$k'");
      while(@v) {
        my $key = shift(@v); my $val = shift(@v);
        $o->{$k}{$key} = $check->($val);
      }
    }
    else {
      push(@{$o->{$k}}, map({$check->($_)} @v));
    }
  }
  else {
    $o->{$k} = $check->($v[0]);
  }
} # end subroutine store definition
########################################################################

=head2 _checker

Builds a check subref for the given $name.

  my $subref = $self->_checker($name);

=cut

sub _checker {
  my $self = shift;
  my ($item) = @_;

  my $d = $self->{opt_data}{$item} or die("nothing for $item");

  my $checkcode = '';
  if(my $isa = $d->{isa}) {
    eval("require $isa");
    $@ and croak("ack: $@");
    $checkcode .= '$val = ' . "$isa" . '->new($val) ' .
      " unless(eval {\$val->isa('$isa')});";
  }
  if(my $type = $d->{type}) {
    # TODO check integer/number-ness
  }
  my $check = eval("sub {
    my \$val = shift;
    $checkcode
    return(\$val);
  }");
  $@ and die "ouch $@";

  return($check);
} # _checker ###########################################################

=head2 set_values

  $go->set_values(%hash);

=cut

sub set_values {
  my $self = shift;
  my %hash = @_;

  foreach my $k (keys %hash) {
    # XXX I need to think about whether this has exceptional cases
    my $v = $hash{$k};
    my $ref = ref($v);
    $self->store($k, $ref
      ? $ref eq 'HASH'
        ? %$v
        : $ref eq 'ARRAY'
          ? @$v
          : $v
      : $v);
  }
} # end subroutine set_values definition
########################################################################

=head2 object

Default/current result-storage object.  Subclasses may wish to
override this.

  my $obj = $go->object;

=cut

sub object {
  my $self = shift;
  return $self->{object} if($self->{object});

  return $self->make_object;
} # end subroutine object definition
########################################################################

=head2 make_object

Constructs an empty (with defaults) data object from the set options.

  my $obj = $self->make_object;

=cut

sub make_object {
  my $self = shift;
  my $obj = Getopt::Base::Accessors->new($self->{opt_data});
  # XXX should find a nicer way to pass these around
  $self->{_defaults} = delete $obj->{__defaults};

  # XXX ugly, but we need to honor isa on default values
  foreach my $k (keys %$obj) {
    my $checker = $self->_checker($k);
    $obj->{$k} = $checker->($obj->{$k});
  }

  return $obj;
} # make_object ########################################################


=head2 _find_option

Fetches the option data for the canonical match (de-aliased) of $opt.

  my $d = $self->_find_option($opt);

=cut

sub _find_option {
  my $self = shift;
  my ($opt) = @_;

  my $key = $opt;
  $key =~ s/^--//; $key =~ s/-/_/g;

  # exact match
  if(my $d = $self->{opt_data}{$key}) { return($d); }

  my @hit = grep({$_ =~ m/^$key/} 
    keys %{$self->{aliases}},
    keys %{$self->{opt_data}}
  );
  croak("option '$opt' is invalid") unless(@hit);
  croak("option '$opt' is not long enough to be unique") if(@hit > 1);

  my $canon = $self->{aliases}{$hit[0]} || $hit[0];
  my $d = $self->{opt_data}{$canon} or
    croak("alias '$hit[0]' has no canonical form ($canon)");

  return($d);
} # end subroutine _find_option definition
########################################################################

=head2 _unbundle

  my @d = $self->_unbundle($blah);

=cut

sub _unbundle {
  my $self = shift;
  my $bun = shift;
  $bun =~ s/^-//;

  my @d;
  foreach my $c (split(//, $bun)) {
    my $canon = $self->{short}{$c} or
      croak("short option '$c' is not defined");
    my $data = $self->{opt_data}{$canon} or
      croak("short option '$c' points to non-existent '$canon'");
    push(@d, $data);
  }

  foreach my $i (0..($#d-1)) {
    croak("option '$d[$i]->{name}' is not a bundle-able flag")
      unless($d[$i]->{type} eq 'boolean');
  }
  return(@d);
} # end subroutine _unbundle definition
########################################################################

{
package Getopt::Base::Accessors;

=head1 Accessor Class

This is the default object for holding results.  It will contain
accessors for all of the defined options.

=head2 new

  my $o = Getopt::Base::Accessors->new($opt_data);

=cut

sub new {
  my $class = shift;
  my $opt_data = shift;

  my $self = {};

  $class .= "::$self";

  bless($self, $class);

  foreach my $k (keys %$opt_data) {
    # warn "$k\n";
    my $o = $opt_data->{$k};
    next if(($o->{type} ||'' eq 'boolean') and $o->{opposes});
    my $sub;
    if(my $r = $o->{form}) {
      # warn "form for $k : $r";
      my $def = $o->{default};
      if($r eq 'HASH') {
        $self->{$k} = {$def ? %$def : ()};
        $sub = eval("sub {\%{shift->{$k}}}");
      }
      elsif($r eq 'ARRAY') {
        $self->{$k} = [$def ? @$def : ()];
        $sub = eval("sub {\@{shift->{$k}}}");
      }
      else {
        Carp::croak("unknown ref type '$r'");
      }
    }
    else {
      $sub = eval("sub {shift->{$k}}");
      if(exists $o->{default}) {
        my $def = $o->{default};
        if((ref($def)||'') eq 'CODE') {
          # lazy
          push(@{$self->{__defaults}}, [$k, $def]);
        }
        else {
          $self->{$k} = $def
        }
      }
    }
    {
      no strict 'refs';
      *{$class . '::' . $k} = $sub;
    }
  }
  # and we need to cleanup this object class
  my $destroy = sub {
    my $st = do { no strict 'refs'; \%{$class . '::'}};
    delete($st->{$_}) for(keys %$st);
    return;
  };
  { no strict 'refs'; *{$class . '::' . 'DESTROY'} = $destroy; }

  return $self;
} # end subroutine new definition
########################################################################

};


=head1 AUTHOR

Eric Wilhelm @ <ewilhelm at cpan dot org>

http://scratchcomputing.com/

=head1 BUGS

If you found this module on CPAN, please report any bugs or feature
requests through the web interface at L<http://rt.cpan.org>.  I will be
notified, and then you'll automatically be notified of progress on your
bug as I make changes.

If you pulled this development version from my /svn/, please contact me
directly.

=head1 COPYRIGHT

Copyright (C) 2009 Eric L. Wilhelm, All Rights Reserved.

=head1 NO WARRANTY

Absolutely, positively NO WARRANTY, neither express or implied, is
offered with this software.  You use this software at your own risk.  In
case of loss, no person or entity owes you anything whatsoever.  You
have been warned.

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

# vi:ts=2:sw=2:et:sta
1;
