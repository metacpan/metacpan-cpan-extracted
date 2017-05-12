package Math::Random::BlumBlumShub;
use strict;

require Exporter;
*import = \&Exporter::import;
require DynaLoader;

our $VERSION = '0.06';
#$VERSION = eval $VERSION;

DynaLoader::bootstrap Math::Random::BlumBlumShub $VERSION;

@Math::Random::BlumBlumShub::EXPORT_OK = qw(bbs bbs_seedgen monobit longrun runs poker autocorrelation autocorrelation_20000);
%Math::Random::BlumBlumShub::EXPORT_TAGS =(all => [qw(bbs bbs_seedgen monobit longrun runs poker autocorrelation autocorrelation_20000)]);

sub dl_load_flags {0} # Prevent DynaLoader from complaining and croaking

1;

__END__

=head1 NAME

   Math::Random::BlumBlumShub - the Blum-Blum-Shub pseudorandom bit generator.

=head1 DEPENDENCIES

   This module needs the GMP C library - available from:
   http://gmplib.org

   The functions in this module take either Math::GMP or Math::GMPz objects
   as their arguments - so you'll need either Math::GMP or Math::GMPz as
   well. (Actually, *any* perl scalar that's a reference to a GMP mpz
   structure will suffice - it doesn't *have* to be a Math::GMP or
   Math::GMPz object.)

=head1 DESCRIPTION

   An implementation of the Blum-Blum-Shub pseudorandom bit generator.

=head1 SYNOPSIS

   use warnings;
   use Math::Random::BlumBlumShub qw(bbs bbs_seedgen);

   use Math::GMP;
   # and/or:
   # use Math::GMPz;
   my $s1 = '615389388455725613122981570401989286707';
   my $s2 = '8936277569639798554773638405675965349567';
   my $prime1    = Math::GMP->new($s1);
   my $prime2    = Math::GMP->new($s2);
   my $seed      = Math::GMP->new(time + int(rand(10000)));
   my $bitstream = Math::GMP->new();
   my $bits_out  = 500;

   # Generate the seed value
   bbs_seedgen($seed, $prime1, $prime2);

   # Fill $bitstream with 500 random bits using $seed, $prime1 and $prime2
   bbs($bitstream, $prime1, $prime2, $seed, $bits_out);

   # See the test script that ships with the Math::Random::BlumBlumShub
   # module source for other working demos (using both the Math::GMP and
   # Math::GMPz modules).

=head1 FUNCTIONS

   bbs($o, $p, $q, $seed, $bits);
    "$o", "$p", "$q", and "$seed" are all Math::GMP or Math::GMPz objects.
    $p and $q must be large primes congruent to 3 modulus 4. (The bbs
    function checks $p and $q for congruence to 3 modulus 4, but does not
    verify that $p and $q are, in fact, prime.)
    Output a $bits-bit random bitstream to $o - calculated using the
    Blum-Blum-Shub algorithm, based on the inputs $p, $q, and $seed. See
    the bbs_seedgen documentation below for the requirements that $seed
    needs to meet.

   bbs_seedgen($seed, $p, $q);
    "$seed", "$p", and "$q" are all Math::GMP or Math::GMPz objects.
    $p and $q are the 2 large primes being used by the BlumBlumShub PRBG.
    The seed needs to be less than N = $p * $q, and gcd(seed, N) must be 1.
    This routine uses the mpz_urandomm() function to pseudorandomly
    generate a seed less than N. (The supplied value of $seed is used to
    seed mpz_urandomm.) If gcd(seed, N) != 1, then the seed is decremented
    until gcd(seed, N) == 1. $seed is then set to that seed value.
    You can, of course, write your own routine to create the seed.

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
