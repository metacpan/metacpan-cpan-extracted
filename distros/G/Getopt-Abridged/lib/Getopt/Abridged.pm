package Getopt::Abridged;
$VERSION = v0.0.1;

use warnings;
use strict;
use Carp;

use base 'Getopt::Base';

=head1 NAME

Getopt::Abridged - quick and simple full-featured option handling

=head1 SYNOPSIS

  sub main {
    my @args = @_;

    my $opt = Getopt::Abridged->new(
      'w|world=s=world',
      'g|greeting=s=hello',
      'v|verbose=1',
      'q|quiet=!verbose',
      -positional => ['world'],
    )->process(\@args) or return;

    print $opt->greeting, ' ', $opt->world, "\n" if($opt->verbose);
  }

  main(@ARGV) if($0 eq __FILE__);

=head1 About

This module is provided as a shortcut for using Getopt::Base and to
support easily transitioning into Getopt::AsDocumented.

=cut

=head2 new

  my $opt = Getopt::Abridged->new(@opts, @args);

=cut

sub new {
  my $package = shift;
  my (@args) = @_;
  my $self = $package->SUPER::new();

  my $order = $self->{defined_options} = [];

  my %opt_do = (
    -positional => sub {
      my $list = shift;
      ((ref($list)||'') eq 'ARRAY') or
        croak("'positional' value must be an array-ref");
      $self->add_positionals(@$list);
    },
  );
  my %type_map = (
    s => 'string',
    i => 'integer',
    n => 'number',
  );
  while(@args) {
    my $opt = shift(@args);
    if($opt =~ m/^-/) {
      @args or croak("'$opt' must have a value");
      my $val = shift(@args);
      my $do = $opt_do{$opt} or croak("no such option: $opt");
      $do->($val);
    }
    else {
      my ($spec, $type, @def) = split(/=/, $opt, 3);
      my %setup;
      if(! defined($type)) {
        $type = '0';
      }
      elsif($type =~ s/^(\@|\%)//) {
        $setup{form} = ($1 eq '@' ? 'ARRAY' : 'HASH');
      }

      my @spec = split(/\|/, $spec);
      my @short;
      push(@short, shift(@spec))
        while(@spec and length($spec[0]) == 1);

      my $long = pop(@spec);

      if(@def) {
        my $def = shift(@def);
        $setup{default} = $setup{form} ? 
          ($setup{form} eq 'ARRAY' ?
            [split(/,/, $def)] : {split(/,|=/, $def)}
          ) : $def;
      }
      elsif($type =~ m/^[10]/) {
        $setup{type} = 'boolean';
        $setup{default} = $type;
      }
      elsif($type =~ s/^\!//) {
        my $name = 'no_' . $type;
        push(@$order, $name);
        $self->add_aliases($name => \@short, @spec, $long);
        next;
      }

      push(@$order, $long);

      $setup{type} ||= $type_map{$type} or
        croak("no such type '$type'");

      $setup{short} = [@short] if(@short);
      $setup{aliases} = [@spec] if(@spec);
      $self->add_option($long => %setup);
    }
  }

  return($self);
} # new ################################################################

=head2 import

This translates your options into pod for use with Getopt::AsDocumented.

  Getopt::Abridged->import('pod');

=cut

my %installed;
sub import {
  my $package = shift;
  my @arg = @_ or return;

  (@arg == 1) or croak("usage: import('pod')");
  my $process = sub {
    my $self = shift;
    @_ and croak("should have no arguments!");
    $self->print_pod;
    return();
  };

  $installed{process} = 1;
  { no strict 'refs'; *{$package . '::process'} = $process};

} # import #############################################################

=head2 unimport

  Getopt::Abridged->unimport;

=cut

sub unimport {
  my $package = shift;
  foreach my $key (keys %installed) {
    delete($installed{$key}) or next;
    my $st = do {no strict 'refs'; \%{$package . '::'}};
    delete($st->{$key});
  }
} # unimport ###########################################################

our $PODHANDLE;

=head2 print_pod

This is activated via import and the call to process().  If your
application is written to return/exit when process() returns false, you
may simply do:

  perl -MGetopt::Abridged=pod -S your_program

You will then want to see L<Getopt::AsDocumented> and change your
process() call to:

  Getopt::AsDocumented->process(\@args) or return;

The builtin --version and --help options will be automatically included
in the pod output.

TODO C<=for positional> directives need to be printed from here.

=cut

sub print_pod {
  my $self = shift;

  my $fh = $PODHANDLE || \*STDOUT;

  require File::Basename;
  my $name = File::Basename::basename($0);
  print $fh "=head1 Usage\n\n  $name [options]\n\n";
  print $fh "=head1 Options\n\n=over\n\n";

  # Best way I can think of at the moment to get them to come out in the
  # same order:
  my $order = $self->{defined_options} or
    croak("must have defined some options for me to print pod");

  my $optd = $self->{opt_data};

  my $short = $self->{short};
  my %shortmap;
  foreach my $s (keys %$short) {
    my $list = $shortmap{$short->{$s}} ||= [];
    push(@$list, $s);
  }

  my $aliases = $self->{aliases};
  my %aliasmap;
  foreach my $n (keys %$aliases) {
    my $list = $aliasmap{$aliases->{$n}} ||= [];
    push(@$list, $n);
  }


  foreach my $canon (@$order) {
    my $item = $optd->{$canon};
    my $short = $shortmap{$canon} || [];
    my $alias = $aliasmap{$canon} || [];

    print $fh "=item ",
      join(', ', map({"-$_"} @$short),
        map({s/_/-/g; $_} map({"--$_"} @$alias, $canon)));

    if($item->{type} ne 'boolean') {
      my $example = uc($canon);
      if(my $f = $item->{form}) {
        if($f eq 'HASH') {
          $example = 'NAME=' . $example;
        }
        else {
          $example .= ' [' . (map({s/_/-/g; $_} '--' . $canon))[0] .
            ' ...]';
        }
      }

      $example .= ' ' . "($item->{type})" if($item->{type} ne 'string');

      print $fh " ", $example;
    }
    print $fh "\n\nThe $canon.\n\n";
    if(defined($item->{default}) and $canon !~ m/^no_/) {
      print $fh "DEFAULT: $item->{default}\n\n";
    }
  }

  print $fh "=item --version\n\nPrint version number and quit.\n\n";
  print $fh "=item -h, --help\n\nShow help about options.\n\n";

  print $fh "=back\n\n=cut\n\n";
} # print_pod ##########################################################

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
