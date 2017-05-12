package Math::Random::NormalDistribution;
# coding: UTF-8

use utf8;
use strict;
use warnings;

# ------------------------------------------------------------------------------
our $VERSION = '0.01';

use Exporter;
use base qw(Exporter);
our @EXPORT = qw(
    rand_nd_generator
);
# ------------------------------------------------------------------------------
use constant TWOPI => 2.0 * 4.0 * atan2(1.0, 1.0);

sub rand_nd_generator(;@)
{
    my ($mean, $stddev) = @_;
    $mean = 0.0 if ! defined $mean;
    $stddev = 1.0 if ! defined $stddev;

    return sub {
        return $mean + $stddev * cos(TWOPI * (1.0 - rand)) * sqrt(-2.0 * log(1.0 - rand));
    }
}
# ------------------------------------------------------------------------------
1;
__END__

=head1 NAME

Math::Random::NormalDistribution - Normally distributed random numbers.

=head1 SYNOPSIS

    use Math::Random::NormalDistribution;

    # Create generator of normally distributed numbers
    # with mean 5.0 and standard deviation 3.0
    my $generator = rand_nd_generator(5.0, 3.0);

    # Generate ten numbers
    my @nums = map { $generator->() } (1..10);


=head1 DESCRIPTION

This module uses I<Box-Muller transform> to generate independent, normally
distributed random fractional numbers (the normal deviates), given uniformly
distributed random numbers (the source is common C<rand>).


=head1 FUNCTIONS

There's only one function in this package and it's exported by default.

=over

=item C<rand_nd_generator($mean, $stddev)>

Accepts the mean (also known as expected value, or mathematical expectation)
and the standard deviation (the square root of variance).
Both arguments are optional - by default, the generator returns standard numbers
(with expected value 0 and standard deviation 1).

Returns a subref: reference to a function without arguments, which returns
a new random number on each call.

For example, just draw a simple chart:

    use Math::Random::NormalDistribution;

    my $LINES = 10;
    my $VALUES = $LINES * 15;

    my @count = (0) x $LINES;
    my $generator = rand_nd_generator($LINES / 2, $LINES / 6);

    for (1 .. $VALUES) {
        my $x = $generator->();
        my $idx = int($x);
        next if $idx < 0 || $idx >= $LINES;
        $count[$idx]++;
    }

    print '|' x $_, "\n" for (@count);

Output:

    ||
    ||||
    |||||||||||||
    ||||||||||||||||||||||
    |||||||||||||||||||||||||||||||||||||||||||
    ||||||||||||||||||||||||||||||||
    |||||||||||||||
    |||||||||||||
    |||||
    |

=back


=head1 SEE ALSO

L<Math::Random::SkewNormal>.


=head1 COPYRIGHT

Copyright E<0x00a9> 2013 Oleg Alistratov. All rights reserved.

This module is free software.  You can redistribute it and/or
modify it under the terms of the Artistic License 2.0.

This program is distributed in the hope that it will be useful,
but without any warranty; without even the implied warranty of
merchantability or fitness for a particular purpose.


=head1 AUTHOR

Oleg Alistratov <zero@cpan.org>

=cut
