package Getopt::AsDocumented;
$VERSION = v0.0.2;

use warnings;
use strict;
use Carp;

use base 'Getopt::Base';

=head1 NAME

Getopt::AsDocumented - declare options as pod documentation

=head1 SYNOPSIS

  =head1 Options
  ...
  =item -w, --what WHAT

  =cut

  sub main {
    my (@args) = @_;
    my $opt = Getopt::AsDocumented->process(\@args) or return;

    my $what = $opt->what;
    ...
  }

=head1 About

This module allows you to declare your program's command-line options as
pod documentation.  It provides syntax to declare types and defaults in
a way which is also readable as documentation.

Note: This is built on Getopt::Base and some advanced features are still
growing.  Your help is welcome.

=head1 Methods

=head2 process

Loads the pod from your current file and processes the command-line
arguments.

  my $opt = Getopt::AsDocumented->process(\@args) or return;

=cut

sub process {
  my $self = shift;
  my $args = shift;
  (@_ % 2) and croak("odd number of elements in \%settings");
  my %also = @_;
  $self = $self->new(%also) unless(ref $self);

  return $self->SUPER::process($args);
} # process ############################################################

=head1 Option Specification

=head2 With/Without Opterands

If an option is followed by a word, it requires an opterand.

  =item --foo FOO

Otherwise, it is a simple flag (boolean) option

  =item --foo

=head3 Booleans

Each boolean option will automatically generate a '--no-' form which
negates it.  You may choose to mention this and/or link aliases to it.

  =item --foo

  Sets the fooness.

  =item -x, --ex-foo, --no-foo

=head2 Types

Non-boolean options may be typed as strings, numbers, or integers.  The
type is included in parenthesis after the option spec.  If the type is not mentioned, it defaults to C<string>.

=head3 integer

An integer.

  =item --foo FOO (integer)

=head3 number

A floating-point number.

  =item --foo FOO (number)

=head3 string

A string.  This is the default, but may be included for clarity.

  =item --foo FOO (string)

=head2 Scalar/HASH/ARRAY

Any non-boolean option can take one of the following forms.

=head3 Scalar

An option followed by a simple word means that only one value is
assigned to it (if the user repeats it, a prior value is overwritten.)

  =item --foo FOO

=head3 HASH

A HASH option is followed by something of the form C<\w+=.*>.  Each
opterand is treated as a $key=$value pair.

  =item --foo BAR=BAZ

=head3 LIST

A LIST option is followed by another mention of itself within []
brackets with an ellipsis to indicate optional additional elements.

  =item --foo FOO [--foo ...]

If a list option requires an explicit type, this must be included after
the bracketed text.

  =item --foo FOO [--foo ...] (integer)

=head2 Defaults

An option's default may be set by the string "DEFAULT: " at the
beginning of a paragraph.  The remainder of that paragraph contains the
default value.

  =item --foo FOO

  The setting for foo.

  DEFAULT: bar

Any leading whitespace after the ':' is removed.

A single leading backslash (if present) will be removed and the rest of
the string will be treated as a literal.

A boolean default may be "NO".  Without a value, a boolean will default
to undef.  Anything true will be translated to '1'.

  =item --foo

  Whether to foo or not.

  DEFAULT:  yes.  Use --no-foo to disable this.

The strings "no" or "false" may also be used as "0".

If the default is enclosed with braces ({}), it is interpreted as a
block of code.  For literal braces, use a leading backslash.

  =item --input FILENAME

  Input file.

  DEFAULT: {File::Fu->home + 'input.txt'}

=head1 Handlers

=head2 config_file_handler

Loads the user's configuration file.  All of the values from the
configuration will be loaded into the options object I<before> any
options from the command-line are processed.

  $go->config_file_handler;

=cut

sub config_file_handler {
  my $self = shift;
  my ($file) = shift;
  $self->load_config_file($file);
} # config_file_handler ################################################

=head2 load_config_file

  $self->load_config_file($file);

=cut

sub load_config_file {
  my $self = shift;
  my ($file) = @_;

  my $mod = sub {
    foreach my $m (qw(YAML::XS YAML::Syck YAML)) {
      eval("require $m") and return($m);
    }
    croak("cannot load any yaml module $@");
  }->();
  croak("what?") unless($mod);

  my $loader = $mod->can('LoadFile');

  my ($data) = $loader->($file);
  $self->set_values(%$data);
} # load_config_file ###################################################

=head2 make_object

Wraps the super method in order to load the config file.

  $obj = $self->make_object;

=cut

sub make_object {
  my $self = shift;
  my $obj = $self->SUPER::make_object(@_);

  if(my $do = $obj->can('config_file')) {
    # XXX this is so wrong
    my %defaults = map({@$_} @{$self->{_defaults}});
    my $lazy = $defaults{config_file};

    if(my $file = $do->($obj) ||
      $lazy && do {$obj->{config_file} = $lazy->()}
    ) {
      local $self->{object} = $obj; # must have a context
      $self->load_config_file($file) if(-e $file);
    }
  }

  return($obj);
} # make_object ########################################################


=head2 handler

Accessor.

  my $handler = $go->handler;

=cut

sub handler { shift->{handler} }

=head2 version_handler

Prints the version from your handler/caller()'s package.

  $go->version_handler;

Sets the quit flag.

=cut

sub version_handler {
  my $self = shift;

  my $caller = $self->{handler};
  $caller = ref($caller) || $caller;
  eval {require version}; # for stringy VERSION() support (I hope)
  my $v = $caller->VERSION || main->VERSION || '<undefined>';
  my $name = $self->{program_name} || do {
    require File::Basename;
    File::Basename::basename($0)
  };
  print "$name version $v\n";
  $self->quit;
} # version_handler ####################################################

=head2 help_handler

Prints a help message based on the USAGE and OPTIONS sections from your
pod.  Uses the first sentence from each C<=item> section, or
alternatively: C<=for help> content found within the C<=item> section.

  $go->help_handler;

Sets the quit flag.

=cut

sub help_handler {
  my $self = shift;
  print "Usage:\n", $self->{usage}, "\n\n";

  my @options = map({
    my $d = $self->{opt_data}{$_};
    my $type = $d->{type};
    [
    $self->{help_bits}{$_} .
    (($type ne 'boolean' and $type ne 'string') ?
      (' (' . substr($type, 0, 3) . ')') : '')
    ,
    $self->{help}{$_}
    ]
  } @{$self->{help_order}});
  my ($longest) = sort({$b <=> $a} map({length($_->[0])} @options));
  @options = map({sprintf('%-'.$longest."s  %s", @$_)} @options);
  print join("\n  ",
    "Options:", @options
    ), "\n";

  $self->quit;
} # help_handler #######################################################

=head1 Other Methods

=head2 new

  my $go = Getopt::AsDocumented->new(%settings);

=over

=item pod       => $string

=item from_file => $filename

=item handler   => $classname

=back

=cut

sub new {
  my $class = shift;
  (@_ % 2) and croak("odd number of elements in \%settings");
  my %setup = @_;

  my %pass;
  foreach my $key (qw(arg_handler)) {
    $pass{$key} = delete($setup{$key}) if(exists($setup{$key}));
  }

  my $self = $class->SUPER::new(%pass);

  $self->_init(%setup);

  return($self);
} # new ################################################################


=for internal
=head2 _init

  $self->_init(%setup);

=cut

sub _init {
  my $self = shift;
  my %setup = @_;

  my $fh;
  if(my $pod = $setup{pod}) {
    open($fh, '<', \$pod) or croak("cannot open string $!");
  }
  else {
    my $file = $setup{from_file} || (caller(2))[1];
    # TODO allow searching @INC?
    open($fh, '<', $file) or croak("cannot open '$file' $!");
  }

  # TODO check this against the =for getopt_handler ... case
  $self->{handler} = $setup{handler} || (caller(2))[0];

  $self->{help_order} = [];

  my $parser = Getopt::AsDocumented::PodParser->new;
  $parser->{__go} = $self;
  $parser->{__the_fh} = $fh;
  $parser->parse_from_filehandle($fh);
} # _init ##############################################################

{
package Getopt::AsDocumented::PodParser;
use base 'Pod::Parser';

sub command {
  my ($self, $command, $p) = @_;

  $p =~ s/\n+$//;

  #warn "-- ", $p, "\n";
  if($command =~ m/^head/) {
    if($self->{__options}) {
      # done
      $self->__store_last;
      return seek($self->{__the_fh}, 0, 2);
    }
    elsif($p =~ m/^options$/i) {
      $self->{__options} = {};
    }
    elsif($p =~ m/^usage$/i) {
      #warn "usage: $p";
      $self->{__usage} = $p;
    }
    return;
  }
  # hmm, we also need to ditch any directives which aren't in the Usage
  # or Options sections

  $self->{__options} or return;  # not there yet

  if($command eq 'item') {
    $self->__store_last;

    my %setup;

    my @opts;
    while($p =~ s/^([^ ,]+)(,?)(?: |$)//) {
      push(@opts, $1); last unless($2);
    }

    # number|integer|string type
    if($p =~ s/ \(([^ ]+)\)$//) { $setup{type} = $1; }

    $setup{help_bit} = join(', ', @opts) . ($p ? ' '.$p : '');

    # list/hash form detection
    if($p =~ s/ \[--[^ ]+ \.\.\.\]$//) {
      $setup{form} = 'ARRAY';
    }
    elsif($p =~ m/^\w+=/) {
      $setup{form} = 'HASH';
    }

    # warn "    stuff($p)\n" if($p);
    $setup{example} = $p if($p);
    if($p) {
      $setup{type} ||= 'string';
    }
    else {
      $setup{type} = 'boolean';
    }

    # parse-out the various short and alias forms
    # the last one is the canonical form
    my @short;
    my @long;
    foreach my $opt (@opts) {
      if($opt =~ s/^--//) {
        $opt =~ s/-/_/g;
        push(@long, $opt);
      }
      else {
        $opt =~ s/^-// or Carp::croak("'$opt' must have a leading dash");
        (length($opt) == 1) or Carp::croak("'$opt' malformed");
        push(@short, $opt);
      }
    }

    my $canon = pop(@long);

    if($canon =~ m/^no_(.*)/) {
      my $what = $1;
      $setup{opposes} = $what;
      # implicit 'opposes' -- vs 
      # warn "$canon (@long)- opposes $what\n";
      #$self->{__go}->add_aliases($canon, \@short, @long);
      #return;
    }
    # warn "canon: $canon\n";
    # warn "long: @long\n";
    # warn "short: @short\n";
    $setup{aliases} = \@long;
    $setup{short}   = \@short;

    $setup{canon} = $canon;
    $self->{__current} = \%setup;
    return;
  }
  elsif($command eq 'back') {
    $self->__store_last;
    return;
  }

  if($command eq 'for') {
    my ($t, @and) = split(/\n=for /, $p);

    my %for_items = map({$_ => 1} qw(positional help isa call opposes));
    my %for_globals = (
      handler => sub {
        my $class = shift;
        unless($class->can('VERSION')) {
          eval("require $class");
          $@ and Carp::croak("cannot load your handler: $@");
        }
        $self->{__go}{handler} = $class;
      },
      program_name => sub {
        $self->{__go}{program_name} = shift;
      },
    );


    my ($thing, $val) = split(/ /, $t, 2);

    if($for_items{$thing}) {
      $self->{__current} or Carp::croak("'=for $thing' out of context");
      $self->{__current}{$thing} = defined($val) ? $val : 1;
    }
    elsif(my $do = $for_globals{$thing}) {
      $self->{__current} and Carp::croak("'=for $thing' out of context");
      $do->($val);
    }
    else {warn "unhandled: $t\n"}

    $self->command('for' => $_) for(@and);
  }
}
sub verbatim {
  my ($parser, $t) = @_;
  if(delete($parser->{__usage})) {
    $t =~ s/\n+$//;
    $parser->{__go}->{usage} = $t;
  }
}

sub end_pod {
  shift->__store_last;
}
sub textblock {
  my ($self, $p) = @_;

  my $s = $self->{__current} or return;
  if($p =~ m/^DEFAULT(?::|\s*=)\s*(.*)/) {
    my $def = $1;

    if($def =~ s/^\\//) {
      # everything after that is literal
    }
    elsif($def =~ s/^\{//) {
      $def =~ s/\}$// or croak("DEFAULT must have closing brace");
      my $sub = eval("sub { $def }");
      $@ and Carp::croak("error $@\nin DEFAULT block '$def'");
      $def = $sub;
    }
    else { # normalize it
      if($def =~ s/^(["'])//) {
        $def =~ s/$1$//;
      }
      # warn "$s->{canon} $s->{type}\n";
      if($s->{type} eq 'boolean') {
        $def =~ s/^(no|false)$/0/i;
        $def = 1 if($def);
      }
    }

    $s->{default} = $def;
  }
  elsif(not $s->{help}) {
    # make help from the first sentence
    $p =~ s/\n+$//;
    $p = lcfirst($p);
    $p =~ s/\.(\)?)( *|$).*/$1/s;
    # TODO some coverage of this - and what to do about parens?
    #warn "text: $p\n";
    $s->{help} = $p;
  }
}

sub __store_last {
  my $parser = shift;

  my $setup = delete($parser->{__current}) or return;
  my $name = delete($setup->{canon}) or die "nothing here";
  my $pos = delete($setup->{positional});

  my $self = $parser->{__go};

  my %auto_actions = map({$_ => 1}
    qw(help version config_file));
  if(my $call = $setup->{call}) {
    my $handler = $call =~ s/^(.*)::// ? $1 : $self->{handler};
    # TODO caller should be able to pass handler as an object?
    $setup->{call} = $handler->can($call) or
        Carp::croak("'$handler' cannot '$call()'");
  }
  elsif($auto_actions{$name}) {
    $setup->{call} = $self->can($name . '_handler') or
      Carp::croak("no handler defined for $name");
  }

  push(@{$self->{help_order}}, $name);
  # TODO ^-- does not work with =for opposes $something

  $self->{help_bits}{$name} = delete($setup->{help_bit});
  $self->{help}{$name} = delete($setup->{help});
  $self->add_option($name, %$setup);
  $self->add_positionals($name) if($pos);
}

}
########################################################################






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
