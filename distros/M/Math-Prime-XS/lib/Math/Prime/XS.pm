package Math::Prime::XS;

use strict;
use warnings;
use base qw(Exporter);
use boolean qw(true false);

use Carp qw(croak);
use Params::Validate ':all';
use Scalar::Util qw(looks_like_number);

our ($VERSION, @EXPORT_OK, %EXPORT_TAGS);
my @subs;

$VERSION = '0.27';
@subs = qw(is_prime primes count_primes
           mod_primes sieve_primes sum_primes trial_primes);
@EXPORT_OK = @subs;
%EXPORT_TAGS = ('all' => [ @subs ]);

validation_options(
    on_fail => sub
{
    my ($error) = @_;
    chomp $error;
    croak $error;
},
    stack_skip => 2,
);

*primes = \&sieve_primes;
sub count_primes { _validate(@_); @_ == 1 ? xs_sieve_count_primes($_[0], 2) : xs_sieve_count_primes(reverse @_) }

# Reverse arguments for xs_*_primes() when both base and number are specified
sub mod_primes   { _validate(@_); @_ == 1 ? xs_mod_primes  ($_[0], 2) : xs_mod_primes  (reverse @_) }
sub sieve_primes { _validate(@_); @_ == 1 ? xs_sieve_primes($_[0], 2) : xs_sieve_primes(reverse @_) }
sub sum_primes   { _validate(@_); @_ == 1 ? xs_sum_primes  ($_[0], 2) : xs_sum_primes  (reverse @_) }
sub trial_primes { _validate(@_); @_ == 1 ? xs_trial_primes($_[0], 2) : xs_trial_primes(reverse @_) }

sub _validate
{
    my $positive_num = sub { looks_like_number($_[0]) && $_[0] >= 0 };

    validate_pos(@_,
        { type => SCALAR,
          callbacks => {
            'is a positive number' => $positive_num,
          },
        },
        { type => SCALAR,
          optional => true,
          callbacks => {
            'is a positive number' => $positive_num,
          },
        },
    );
    if (@_ == 2) {
        my ($base, $number) = @_;
        croak 'Base is greater than the number' if $base > $number;
    }
}

require XSLoader;
XSLoader::load(__PACKAGE__, $VERSION);

1;
__END__

=head1 NAME

Math::Prime::XS - Detect and calculate prime numbers with deterministic tests

=head1 SYNOPSIS

 use Math::Prime::XS ':all';
 # or
 use Math::Prime::XS qw(is_prime primes mod_primes sieve_primes sum_primes trial_primes);

 print "prime" if is_prime(59);

 @all_primes   = primes(100);
 @range_primes = primes(30, 70);

 @all_primes   = mod_primes(100);
 @range_primes = mod_primes(30, 70);

 @all_primes   = sieve_primes(100);
 @range_primes = sieve_primes(30, 70);

 @all_primes   = sum_primes(100);
 @range_primes = sum_primes(30, 70);

 @all_primes   = trial_primes(100);
 @range_primes = trial_primes(30, 70);

=head1 DESCRIPTION

C<Math::Prime::XS> detects and calculates prime numbers by either applying
Modulo operator division, the Sieve of Eratosthenes, a Summation calculation
or Trial division.

=head1 FUNCTIONS

=head2 is_prime

 is_prime($number);

Returns true if the number is prime, false if not.

The XS function invoked within C<is_prime()> is subject to change (currently
it's an all-XS trial division skipping multiples of 2,3,5).

=head2 primes

 @all_primes   = primes($number);
 @range_primes = primes($base, $number);

Returns all primes for the given number or primes between the base and number.

The resolved function called is subject to change (currently C<sieve_primes()>).

=head2 count_primes

 $count = count_primes($number);
 $count = count_primes($base, $number);

Return a count of primes from 0 to C<$number>, or from C<$base> to
C<$number>, inclusive.  The arguments are the same as C<primes()> but the
return is just a count of the primes.

=head1 SPECIFIC ALGORITHMS

=head2 mod_primes

 @all_primes   = mod_primes($number);
 @range_primes = mod_primes($base, $number);

Applies the Modulo operator division algorithm:

Divide the number by 2 and all odd numbers E<lt>= sqrt(n); if any divides
exactly then the number is not prime.

Returns all primes between 2 and C<$number>, or between C<$base> and
C<$number> (inclusive).

(This function differs from C<trial_primes> in that the latter takes some
trouble to divide only by primes below sqrt(n), whereas C<mod_primes>
divides by all integers not easily identifiable as composite.)

=head2 sieve_primes

 @all_primes   = sieve_primes($number);
 @range_primes = sieve_primes($base, $number);

Applies the Sieve of Eratosthenes algorithm:

One of the most efficient ways to find all the small primes (say, all those less
than 10,000,000) is by using the Sieve of Eratosthenes (ca 240 BC). Make a list
of all numbers less than or equal to n (and greater than one) and strike out
the multiples of all primes less than or equal to the square root of n:
the numbers that are left are primes.

Returns all primes for the given number or primes between the base and number.

L<http://primes.utm.edu/glossary/page.php?sort=SieveOfEratosthenes>

=head2 sum_primes

 @all_primes   = sum_primes($number);
 @range_primes = sum_primes($base, $number);

Applies the Summation calculation algorithm:

The summation calculation algorithm resembles the modulo operator division
algorithm, but also shares some common properties with the Sieve of
Eratosthenes. For each saved prime smaller than or equal to the square root
of the number, recall the corresponding sum (if none, start with zero);
add the prime to the sum being calculated while the summation is smaller
than the number. If none of the sums equals the number, then the number
is prime.

Returns all primes for the given number or primes between the base and number.

L<http://www.geraldbuehler.de/primzahlen/>

=head2 trial_primes

 @all_primes   = trial_primes($number);
 @range_primes = trial_primes($base, $number);

Applies the Trial division algorithm:

To see if an individual small number is prime, trial division works well:
just divide by all the primes less than or equal to its square root. For
example, to assert 211 is prime, divide by 2, 3, 5, 7, 11 and 13. Since
none of these primes divides the number evenly, it is prime.

Returns all primes for the given number or primes between the base and number.

L<http://primes.utm.edu/glossary/page.php?sort=TrialDivision>

=head1 BENCHMARK

Following output resulted from a benchmark measuring the time to calculate
primes up to 1,000,000 with 100 iterations for each function. The tests
were conducted by the C<cmpthese> function of the Benchmark module.

                Rate   mod_primes trial_primes   sum_primes sieve_primes
 mod_primes   1.32/s           --         -58%         -79%         -97%
 trial_primes 3.13/s         137%           --         -49%         -93%
 sum_primes   6.17/s         366%          97%           --         -86%
 sieve_primes 43.3/s        3173%        1284%         602%           --

The "Rate" column is the speed in how many times per second, so
C<sieve_primes()> is the fastest for this particular test.

=head1 EXPORT

=head2 Functions

C<is_prime(), primes(), mod_primes(), sieve_primes(), sum_primes(), trial_primes()>
are exportable.

=head2 Tags

C<:all - *()>

=head1 BUGS & CAVEATS

Note that the order of execution speed for functions may differ from the
benchmarked results when numbers get larger or smaller.

=head1 SEE ALSO

L<http://primes.utm.edu>,
L<http://www.it.fht-esslingen.de/~schmidt/vorlesungen/kryptologie/seminar/ws9798/html/prim/prim-1.html>

=head1 AUTHOR

Steven Schubiger <schubiger@cpan.org>

=head1 LICENSE

This program is free software; you may redistribute it and/or
modify it under the same terms as Perl itself.

See L<http://dev.perl.org/licenses/>

=cut
