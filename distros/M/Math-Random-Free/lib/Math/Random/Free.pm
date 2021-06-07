package Math::Random::Free;

use strict;
use warnings;

# ABSTRACT: Free drop-in replacement for Math::Random
our $VERSION = '0.2.0'; # VERSION

=pod

=head1 NAME

Math::Random::Free - free drop-in replacement for Math::Random

=head1 DESCRIPTION

This is free (see below) implementation of L<Math::Random|Math::Random>
0.72, serving as drop-in replacement for this module.

=head1 MOTIVATION

L<Math::Random|Math::Random> is a great and widely-used module for the
generation of random numbers and permutations. Despite being open-source,
L<Math::Random|Math::Random> does not fulfill free open-source software
definitions as established by the Open Source Initiative
(L<https://opensource.org/osd>) and the Debian Project
(L<https://www.debian.org/social_contract#guidelines>, a.k.a. DFSG). This
is mostly because C<randlib> code cannot be copied nor distributed for
direct commercial advantage. Math::Random::Free is created to free the
code depending on L<Math::Random|Math::Random> from these limitations.

=cut

use Digest::SHA qw( sha1_hex );
use List::Util qw( shuffle );

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw(
    random_normal
    random_permutation
    random_permuted_index
    random_set_seed_from_phrase
);
our @EXPORT_OK = qw(
    random_exponential
    random_normal
    random_permutation
    random_permuted_index
    random_set_seed_from_phrase
    random_uniform
    random_uniform_integer
);
our $PI = 4 * atan2( 1, 1 );

=head1 SUPPORT

    our @EXPORT = qw(
        random_normal
        random_permutation
        random_permuted_index
        random_set_seed_from_phrase
    );
    our @EXPORT_OK = qw(
        random_exponential
        random_normal
        random_permutation
        random_permuted_index
        random_set_seed_from_phrase
        random_uniform
        random_uniform_integer
    );

=cut

sub random_exponential
{
    my( $n, $rate ) = @_;

    $n    = 1 unless defined $n;
    $rate = 1 unless defined $rate;

    if( wantarray ) {
        return map { scalar random_exponential( $n, $rate ) } 1..$n;
    } else {
        return log( 1 - rand ) / -$rate;
    }
}

sub random_normal
{
    my( $n, $mean, $sd ) = @_;

    $n    = 1 unless defined $n;
    $mean = 0 unless defined $mean;
    $sd   = 1 unless defined $sd;

    if( wantarray ) {
        return map { scalar random_normal( $n, $mean, $sd ) } 1..$n;
    } else {
        # Box-Muller method
        return $mean + $sd * cos( 2 * $PI * (1 - rand) )
                           * sqrt( -2 * log(1 - rand) );
    }
}

sub random_permutation
{
    my( @array ) = @_;
    return @array[random_permuted_index( scalar @array )];
}

sub random_permuted_index
{
    my( $n ) = @_;

    return shuffle 0..$n-1;
}

sub random_set_seed_from_phrase
{
    my( $seed ) = @_;

    # On 64-bit machine the max. value for srand() seems to be 2**50-1
    srand hex substr( sha1_hex( $seed ), 0, 6 );
}

sub random_uniform
{
    my( $n, $low, $high ) = @_;

    $n    = 1 unless defined $n;
    $low  = 0 unless defined $low;
    $high = 1 unless defined $high;

    if( wantarray ) {
        return map { rand() * ($high - $low) + $low } 1..$n;
    } else {
        return rand() * ($high - $low) + $low;
    }
}

sub random_uniform_integer
{
    my( $n, $low, $high ) = @_;

    my $range = int($high) - int($low) + 1;

    if( wantarray ) {
        return map { int( rand($range) + $low ) } 1..$n;
    } else {
        return int( rand($range) + $low );
    }
}

=head1 CAVEATS

This module has only a subset of L<Math::Random|Math::Random> subroutines
(contributions welcome), implemented using either Perl core subroutines
or other well-known modules. Thus Math::Random::Free is neither as
complete, nor as fast, nor as random as L<Math::Random|Math::Random>.
Also Math::Random::Free does not aim for cryptographic security.

While Math::Random::Free supports seed setting, it does that differently
from L<Math::Random|Math::Random>. It means that one should not expect
the same seed producing identical random sequences in both modules.

As Math::Random::Free employs L<List::Util|List::Util> for producing
random permutations, these are influenced by C<$List::Util::RAND>
variable.

=head1 TESTED WITH

=over 4

=item *

L<Graph::Maker> 0.02

=back

=head1 AUTHOR

Andrius Merkys, L<mailto:merkys@cpan.org>

=cut

1;
