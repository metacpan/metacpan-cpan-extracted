package Devel::ebug::Backend::Plugin::Run;

use strict;
use warnings;

our $VERSION = '0.63'; # VERSION

sub register_commands {
    return (
      next        => { sub => \&next, record => 1 },
      return      => { sub => \&return, record => 1 },
      run         => { sub => \&run, record => 1 },
      step        => { sub => \&step, record => 1 },
    );
}

sub next {
  my($req, $context) = @_;
  $context->{mode} = "next"; # single step (but over subroutines)
  $context->{last} = 1;      # and out of the loop
  return {};
}

sub return {
  my($req, $context) = @_;
  if ($req->{values}) {
    $context->{stack}->[0]->{'return'} = $req->{values};
  }
  $context->{mode} = "return"; # run until returned from subroutine
  $DB::single = 0; # run
  if ($context->{stack}->[-1]) {
    $context->{stack}->[-1]->{single} = 1; # single step higher up
  }
  $context->{last} = 1;      # and out of the loop
  return {};
}

sub run {
  my($req, $context) = @_;
  $context->{mode} = "run"; # run until break point
  if (@{$context->{watch_points}}) {
    # watch points, let's go slow
    $context->{watch_single} = 0;
  } else {
    # no watch points? let's go fast!
    $DB::single = 0; # run until next break point
  }
  $context->{last} = 1;      # and out of the loop
  return {};
}


sub step {
  my($req, $context) = @_;
  $DB::single = 1;           # single step
  $context->{mode} = "step"; # single step (into subroutines)
  $context->{last} = 1;      # and out of the loop, onto the next command
  return {};
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Devel::ebug::Backend::Plugin::Run

=head1 VERSION

version 0.63

=head1 AUTHOR

Original author: Leon Brocard E<lt>acme@astray.comE<gt>

Current maintainer: Graham Ollis E<lt>plicease@cpan.orgE<gt>

Contributors:

Brock Wilcox E<lt>awwaiid@thelackthereof.orgE<gt>

Taisuke Yamada

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2005-2020 by Leon Brocard.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
