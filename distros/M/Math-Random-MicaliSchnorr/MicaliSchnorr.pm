package Math::Random::MicaliSchnorr;
use strict;

require Exporter;
*import = \&Exporter::import;
require DynaLoader;

our $VERSION = '0.06';
#$VERSION = eval $VERSION;

DynaLoader::bootstrap Math::Random::MicaliSchnorr $VERSION;

@Math::Random::MicaliSchnorr::EXPORT_OK = qw(ms ms_seedgen monobit longrun runs poker autocorrelation autocorrelation_20000);
%Math::Random::MicaliSchnorr::EXPORT_TAGS =(all => [qw(ms ms_seedgen monobit longrun runs poker autocorrelation autocorrelation_20000)]);

sub dl_load_flags {0} # Prevent DynaLoader from complaining and croaking

1;

__END__

=head1 NAME

   Math::Random::MicaliSchnorr - the Micali-Schnorr pseudorandom bit generator.

=head1 DEPENDENCIES

   To build this module the GMP C library needs to be installed. Source for
   this library is available from:
   http://gmplib.org

   The functions in this module take either Math::GMP or Math::GMPz objects
   as their arguments - so you'll need either Math::GMP or Math::GMPz as
   well. (Actually, *any* perl scalar that's a reference to a GMP mpz
   structure will suffice - it doesn't *have* to be a Math::GMP or
   Math::GMPz object.)

=head1 DESCRIPTION

   An implementation of the Micali-Schnorr pseudorandom bit generator.

=head1 SYNOPSIS

   use warnings;
   use Math::Random::MicaliSchnorr qw(ms ms_seedgen);

   use Math::GMP;
   # and/or:
   #use Math::GMPz;

   my $s1 = '615389388455725613122981570401989286707';
   my $s2 = '8936277569639798554773638405675965349567';
   my $prime1    = Math::GMP->new($s1);
   my $prime2    = Math::GMP->new($s2);
   my $seed      = Math::GMP->new(time + int(rand(10000)));
   my $exp;
   my $bitstream = Math::GMP->new();
   my $bits_out  = 500;

   # Generate the seed value
   ms_seedgen($seed, $exp, $prime1, $prime2);

   # Fill $bitstream with 500 random bits using $seed, $prime1 and $prime2
   ms($bitstream, $prime1, $prime2, $seed, $exp, $bits_out);

   # Other working examples (using Math::GMPz as well as Math::GMP can be
   # found in the test script that ships with the
   # Math::Random::MicaliSchnorr source.

=head1 FUNCTIONS

   ms($o, $prime1, $prime2, $seed, $exp, $bits);

    "$o", "$prime1", "$prime2", and "$seed" are all Math::GMP or Math::GMPz
    objects. $prime1 and $prime2 are large primes. (The ms function does
    not check that they are, in fact, prime. Both Math::GMPz and Math::GMP
    modules provide functions for creating large primes.)
    Output a $bits-bit random bitstream to $o - calculated using the
    Micali-Schnorr algorithm, based on the inputs $prime1, $prime2, $seed
    and $exp. See the ms_seedgen documentation (below) for the requirements
    regarding $seed and $exp.

   ms_seedgen($seed, $exp, $prime1, $prime2);
    $seed is a Math::GMP or Math::GMPz object. $exp is just a normal perl
    scalar (that will have an unsigned integer value assigned to it). The
    ms_seedgen function assigns values to both $seed and $exp that are
    suitable for passing to the ms() function. You can, of course, write
    your own routine for determining these values. (The ms function checks
    that $seed and $exp values it has been passed are in the allowed range.)
    Here are the rules for determining those values:
    Let N be the bitlength of n = $prime1 * $prime2.
    Let phi = ($prime1 - 1) * ($prime2 - 1). $exp must satisfy all 3 of the
    following conditions:
     i) 2 < $exp < phi
     ii) The greatest common denominator of $exp and phi is 1
     iii) $exp * 80 <= N
    Conditions i) and iii) mean that N has to be at least 240 (80 * 3) - ie
    the no. of bits in the product of the two primes must be at least 240.
    The ms_seedgen function selects the largest value for $exp that
    satisfies those 3 conditions. Having found a suitable value for $exp, we
    then need to calculate the integer value k = int(N *(1 - (2 / $exp))).
    Then calculate r = N - k, where r is the bitlength of the random value
    that will be chosen to seed the MicaliSchnorr generator..
    The ms_seedgen function uses the GMP library's mpz_urandomb function to
    select a suitable value for $seed. The mpz_urandomb function itself is
    seeded by the value *supplied* in the $seed argument. $seed is then
    overwritten with the value that mpz_urandomb has come up with, and that
    is the value that gets passed to ms().
    By my understanding, the method of selecting $seed and $exp has no impact
    upon the security of the MicaliSchnorr generator - save that the seed
    needs to be r (or less) bits in size, that no seed value should be
    re-used, and that $exp satisfies the 3 conditions given above.
    Afaik, the security relies solely on the values of the 2 primes being
    secret ... I could be wrong, but.

   $bool = monobit($op);
   $bool = longrun($op);
   $bool = runs($op);
   $bool = poker($op);

    These are the 4 standard FIPS-140 statistical tests for testing
    prbg's. They return '1' for success and '0' for failure.
    They test 20000-bit pseudorandom sequences, stored in the
    Math::GMPz/Math::GMP object $op.

   $bool = autocorrelation_20000($op, $offset);
    $op is a sequence (Math::GMPz/Math::GMP object) of 20000 + $offset bits.
    Returns true ("success") if the no. of bits in $op not equal to their
    $offset-leftshifts lies in the range [9655 .. 10345] (inclusive).
    Else returns 0 ("failure").

  ($count, $x5val) = autocorrelation($op, $offset);
    $op is a sequence (Math::GMPz/Math::GMP object) of 20000 bits.
    Returns (resp.) the no. of bits in $op not equal to their
    $offset-leftshifts, and the X5 value as specified in section 5.4.4
    of "Handbook of Applied Cryptography" (Menezes at al).

=head1 BUGS

   You can get segfaults if you pass the wrong type of argument to the
   functions - so if you get a segfault, the first thing to do is to check
   that the argument types you have supplied are appropriate.

=head1 LICENSE

   This program is free software; you may redistribute it and/or
   modify it under the same terms as Perl itself.
   Copyright 2006-2008, 2009, 2010, 2014, Sisyphus

=head1 AUTHOR

   Sisyhpus <sisyphus at(@) cpan dot (.) org>


=cut
