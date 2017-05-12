#!/usr/bin/perl

package Every;

use Devel::Callsite;
use strict;
use warnings;

our $VERSION = '0.08';
$VERSION = eval $VERSION;

use Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw(every);

use Scalar::Util qw(looks_like_number);

my %counters;
my %time_counters;

# Arg must be defined and be a positive number
sub _check_arg
{
    my $arg = $_[0];

    if (! defined($arg)) {
        require Carp;
        Carp::croak('Argument missing or undefined');
    }
    if (! Scalar::Util::looks_like_number($arg)) {
        require Carp;
        Carp::croak('Argument is not numeric');
    }
    if ($arg <= 0) {
        require Carp;
        Carp::croak('Argument must be greater than zero');
    }
}

sub every
{
    my ($div, @id) = @_;

    my $site = callsite() . '/' . context();
    
    if (defined($div) && ($div =~ /^sec/)) {    # Allows 'seconds', 'secs', etc.
        my $now = time();   # Capture current time

        $div = shift(@id);
        _check_arg($div);   # Validate arg

        my $key = join('_', caller(), $div, $site, @id);  # Hash key

        if (my $then = $time_counters{$key}) {
            my $diff = $now - ($then + $div);
            return ($diff >= 0) ? ($time_counters{$key} = $now) : 0;
        } else {
            # First time called
            $time_counters{$key} = $now;
            return;
        }
    }

    _check_arg($div);
    if (int($div) != $div) {    # Non-timer arg should also be an integer
        require Carp;
        Carp::croak('Argument is not an integer');
    }

    my $key = join('_', caller(), $div, $site, @id);   # Hash key
    return !(++$counters{$key} % $div) ? 1 : 0;
}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Every - return true every N cycles or S seconds

=head1 SYNOPSIS

 for (0..200)
 {
  print_stats() if every(20);           # every 20 cycles
  print_times() if every(seconds => 5); # every 5 or more seconds
  sleep 3;
 }

=head1 FUNCTION-ORIENTED INTERFACE

=head2 every( $number [, @id] )

=head2 every( seconds => $number [, @id] )

Returns true every C<$number> times it's called, or every time C<$number>
seconds have elapsed since the last time it was called.

The C<every()> function keeps track of where it was called by line, even
if you call it twice on the same line, e.g.

 print "hello" if every(5) or every(6);

The C<every()> function will use the Devel::Callsite module to find the
opcode and interpreter context (both unique numbers).

The optional @id is a list of arguments that compose a unique identifier.
In other words, C<every(100, 'x')> will run its 100 cycles independently of
C<every(100, 'x', 'y')>.

=head1 DESCRIPTION

Returns true when the conditions (cycles or seconds elapsed) are met.
The first cycle doesn't count (so e.g. C<every(100)> will be true at
100, 200, etc.)

Thanks to Dr.Ruud on comp.lang.perl.misc for helping with this idea,
and to Jerry Hedden for cleaning it up.  Thanks to Ben Morrow for
getting Devel::Callsite started, which module is essential to Every.

Thanks to Jerrad Pierce and ikegami for the bug reports and help.

=head1 BUGS

None known.

=head1 COPYRIGHT

Copyright 2008, Ted Zlatanov (Теодор Златанов). All Rights
Reserved. This module can be redistributed under the same terms as
Perl itself.

=head1 AUTHOR

Ted Zlatanov <tzz@lifelogs.com>

=head1 SEE ALSO
