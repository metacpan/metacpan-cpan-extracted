package Guard::Timer;

use strict;
use warnings;
use Exporter 'import';
our $VERSION = '1.0.0'; # VERSION
# ABSTRACT: a scope guard that keeps time


our @EXPORT = our @EXPORT_OK = qw/ timer_guard /;

use Carp;
use Time::HiRes qw/ gettimeofday tv_interval /;
use Guard;


sub timer_guard(&;$) { ## no critic(ProhibitSubroutinePrototypes)
    my ($subref, $decimal_points) = @_;
    $decimal_points ||= 3;
    $decimal_points =~ /\A\d+\Z/
        or croak("timer_guard: Number of decimal points isn't an integer");

    my $t0 = [ gettimeofday() ];

    return guard {
        my $duration = sprintf( "%.${decimal_points}f", tv_interval( $t0 ) );
        $subref->($duration);
    };
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Guard::Timer - a scope guard that keeps time

=head1 VERSION

version 1.0.0

=head1 SYNOPSIS

  sub foo {
      my $guard = timer_guard { say "it took $_[0] seconds" };
      do_a_thing;
  }

=head1 FUNCTIONS

=head2 C<timer_guard>

  my $timer1 = timer_guard { ... };
  my $timer2 = timer_guard \&logger, $precision;

Returns an object. When the object is destroyed, the given coderef is
invoked with a single argument: the time elapsed between creation and
destruction, to C<$precision> decimals (defaults to 3).

=head1 AUTHORS

=over 4

=item *

Johan Lindstrom <Johan.Lindstrom@broadbean.com>

=item *

Gianni Ceccarelli <gianni.ceccarelli@broadbean.com>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by BroadBean UK, a CareerBuilder Company.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
