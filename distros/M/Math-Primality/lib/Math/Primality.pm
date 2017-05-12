package Math::Primality;
{
  $Math::Primality::VERSION = '0.08';
}
use warnings;
use strict;
use Data::Dumper;
use Math::GMPz qw/:mpz/;
use base 'Exporter';
use Carp qw/croak/;
my %small_primes = (
    2   => 2,
    3   => 2,
    5   => 2,
    7   => 2,
    11  => 2,
    13  => 2,
    17  => 2,
    19  => 2,
    23  => 2,
    29  => 2,
    31  => 2,
    37  => 2,
    41  => 2,
    43  => 2,
    47  => 2,
    53  => 2,
    59  => 2,
    61  => 2,
    67  => 2,
    71  => 2,
    73  => 2,
    79  => 2,
    83  => 2,
    89  => 2,
    97  => 2,
    101 => 2,
    103 => 2,
    107 => 2,
    109 => 2,
    113 => 2,
    127 => 2,
    131 => 2,
    137 => 2,
    139 => 2,
    149 => 2,
    151 => 2,
    157 => 2,
    163 => 2,
    167 => 2,
    173 => 2,
    179 => 2,
    181 => 2,
    191 => 2,
    193 => 2,
    197 => 2,
    199 => 2,
    211 => 2,
    223 => 2,
    227 => 2,
    229 => 2,
    233 => 2,
    239 => 2,
    241 => 2,
    251 => 2,
    257 => 2,
);

use constant
	DEBUG => 0
;

use constant GMP => 'Math::GMPz';

# ABSTRACT: Check for primes with Perl



our @EXPORT_OK = qw/is_pseudoprime is_strong_pseudoprime is_strong_lucas_pseudoprime is_prime next_prime prev_prime prime_count/;

our %EXPORT_TAGS = ( all => \@EXPORT_OK );


sub is_pseudoprime($;$)
{
    my ($n, $base) = @_;
    return 0 unless $n;
    $base ||= 2;
    # we should check if we are passed a GMPz object
    $base   = GMP->new("$base");
    $n      = GMP->new("$n");

    my $m    = GMP->new();
    Rmpz_sub_ui($m, $n, 1);              # $m = $n - 1

    my $mod = GMP->new();
    Rmpz_powm($mod, $base, $m, $n );     # $mod = ($base ^ $m) mod $n 
    return ! Rmpz_cmp_ui($mod, 1);       # pseudoprime if $mod = 1
}

# checks if $n is in %small_primes
# private functions expect a Math::GMPz object
sub _is_small_prime
{
    my $n = shift;
    $n = Rmpz_get_ui($n);
    return $small_primes{$n} ? 2 : 0;

}

sub debug {
    if ( DEBUG ) {
      warn $_[0];
    }
}


sub is_strong_pseudoprime($;$)
{
    my ($n, $base) = @_;

    $base ||= 2;
    $base   = GMP->new("$base");
    $n      = GMP->new("$n");

    # unnecessary but faster if $n is even
    my $cmp = _check_two_and_even($n);
    return $cmp if $cmp != 2;

    my $m   = GMP->new();
    Rmpz_sub_ui($m,$n,1);              # $m = $n - 1

    my ($s,$d) = _find_s_d($m);
    debug "m=$m, s=$s, d=$d" if DEBUG;

    my $residue = GMP->new();
    Rmpz_powm($residue, $base,$d, $n); # $residue = ($base ^ $d) mod $n
    debug "$base^$d % $n = $residue" if DEBUG;

    # if $base^$d = +-1 (mod $n) , $n is a strong pseudoprime

    if ( Rmpz_cmp_ui($residue,1) == 0 ) {
        debug "found $n as spsp since $base^$d % $n == $residue == 1\n" if DEBUG;
        return 1;
    }

    if ( Rmpz_cmp($residue,$m) == 0 ) {
        debug "found $n as spsp since $base^$d % $n == $residue == $m\n" if DEBUG;
        return 1;
    }

    map {
        Rmpz_powm($residue, $residue, GMP->new(2), $n);
        if (Rmpz_cmp($residue, $m) == 0) {
            debug "$_:$residue == $m => spsp!" if DEBUG;
            return 1;
        }
    } ( 1 .. $s-1 );

    return 0;
}

# given an odd number N find (s, d) such that N = d * 2^s + 1
# private functions expect a Math::GMPz object
sub _find_s_d($)
{
    my $m   = $_[0];
    my $s   = Rmpz_scan1($m,1);
    my $d   = GMP->new();
    Rmpz_tdiv_q_2exp($d,$m,$s);
    return ($s,$d);
}


sub is_strong_lucas_pseudoprime($)
{
    my ($n) = @_;
    $n      = GMP->new("$n");
    # we also need to handle all N < 3 and all even N 
    my $cmp = _check_two_and_even($n);
    return $cmp if $cmp != 2;
    # handle all perfect squares
    if ( Rmpz_perfect_square_p($n) ) {
        return 0;
    }
    # determine Selfridge parameters D, P and Q
    my ($D, $P, $Q) = _find_dpq_selfridge($n);
    if ($D == 0) {  #_find_dpq_selfridge found a factor of N
      return 0;
    }
    my $m = GMP->new();
    Rmpz_add_ui($m, $n, 1);  # $m = $n + 1

    # determine $s and $d such that $m = $d * 2^$s + 1
    my ($s,$d) = _find_s_d($m);
    # compute U_d and V_d
    # initalize $U, $V, $U_2m, $V_2m
    my $U = GMP->new(1);     # $U = U_1 = 1
    my $V = GMP->new($P);    # $V = V_1 = P
    my $U_2m = GMP->new(1);  # $U_2m = U_1
    my $V_2m = GMP->new($P); # $V_2m = P
    # initalize Q values (eventually need to calculate Q^d, which will be used in later stages of test)
    my $Q_m = GMP->new($Q);
    my $Q2_m = GMP->new(2 * $Q);  # Really 2Q_m, but perl will barf with a variable named like that
    my $Qkd = GMP->new($Q);
    # start doubling the indicies!
    my $dbits = Rmpz_sizeinbase($d,2);
    for (my $i = 1; $i < $dbits; $i++) {  #since d is odd, the zeroth bit is on so we skip it
      # U_2m = U_m * V_m (mod N)
      Rmpz_mul($U_2m, $U_2m, $V_2m);  # U_2m = U_m * V_m
      Rmpz_mod($U_2m, $U_2m, $n);     # U_2m = U_2m mod N
      # V_2m = V_m * V_m - 2 * Q^m (mod N)
      Rmpz_mul($V_2m, $V_2m, $V_2m);  # V_2m = V_2m * V_2m
      Rmpz_sub($V_2m, $V_2m, $Q2_m);  # V_2m = V_2m - 2Q_m
      Rmpz_mod($V_2m, $V_2m, $n);     # V_2m = V_2m mod N
      # calculate powers of Q for V_2m and Q^d (used later)
      # 2Q_m = 2 * Q_m * Q_m (mod N)
      Rmpz_mul($Q_m, $Q_m, $Q_m);     # Q_m = Q_m * Q_m
      Rmpz_mod($Q_m, $Q_m, $n);       # Q_m = Q_m mod N
      Rmpz_mul_2exp($Q2_m, $Q_m, 1);  # 2Q_m = Q_m * 2
      if (Rmpz_tstbit($d, $i)) {      # if bit i of d is set
        # add some indicies
        # initalize some temporary variables
        my $T1 = GMP->new();
        my $T2 = GMP->new();
        my $T3 = GMP->new();
        my $T4 = GMP->new();
        # this is how we do it
        # U_(m+n) = (U_m * V_n + U_n * V_m) / 2
        # V_(m+n) = (V_m * V_n + D * U_m * U_n) / 2
        Rmpz_mul($T1, $U_2m, $V);     # T1 = U_2m * V
        Rmpz_mul($T2, $U, $V_2m);     # T2 = U * V_2m
        Rmpz_mul($T3, $V_2m, $V);     # T3 = V_2m * V
        Rmpz_mul($T4, $U_2m, $U);     # T4 = U_2m * U
        Rmpz_mul_si($T4, $T4, $D);    # T4 = T4 * D = U_2m * U * D
        Rmpz_add($U, $T1, $T2);       # U = T1 + T2 = U_2m * V - U * V_2m
        if (Rmpz_odd_p($U)) {         # if U is odd
          Rmpz_add($U, $U, $n);       # U = U + n
        }
        Rmpz_fdiv_q_2exp($U, $U, 1);  # U = floor(U / 2)
        Rmpz_add($V, $T3, $T4);       # V = T3 + T4 = V_2m * V + U_2m * U * D
        if (Rmpz_odd_p($V)) {         # if V is odd
          Rmpz_add($V, $V, $n);       # V = V + n 
        }
        Rmpz_fdiv_q_2exp($V, $V, 1);  # V = floor(V / 2)
        Rmpz_mod($U, $U, $n);         # U = U mod N
        Rmpz_mod($V, $V, $n);         # V = V mod N
        # Get our Q^d calculating on (to be used later)
        Rmpz_mul($Qkd, $Qkd, $Q_m);   # Qkd = Qkd * Q_m
        Rmpz_mod($Qkd, $Qkd, $n);     # Qkd = Qkd mod N
      }
    }
    # if U_d or V_d = 0 mod N, then N is prime or a strong Lucas pseudoprime
    if(Rmpz_sgn($U) == 0 || Rmpz_sgn($V) == 0) {
      return 1;
    }
    # ok, if we're still here, we have to compute V_2d, V_4d, V_8d, ..., V_{2^(s-1)*d}
    # initalize 2Qkd
    my $Q2kd = GMP->new;
    Rmpz_mul_2exp($Q2kd, $Qkd, 1);    # 2Qkd = 2 * Qkd
    # V_2m = V_m * V_m - 2 * Q^m (mod N)
    for (my $r = 1; $r < $s; $r++) {
      Rmpz_mul($V, $V, $V);      # V = V * V;
      Rmpz_sub($V, $V, $Q2kd);   # V = V - 2Qkd
      Rmpz_mod($V, $V, $n);      # V = V mod N
      # if V = 0 mod N then N is a prime or a strong Lucas pseudoprime
      if(Rmpz_sgn($V) == 0) {
        return 1;
      }
      # calculate Q ^(d * 2^r) for next r (unless on final iteration)
      if ($r < ($s - 1)) {
        Rmpz_mul($Qkd, $Qkd, $Qkd);     # Qkd = Qkd * Qkd
        Rmpz_mod($Qkd, $Qkd, $n);       # Qkd = Qkd mod N
        Rmpz_mul_2exp($Q2kd, $Qkd, 1);  # 2Qkd = 2 * Qkd
      } 
    }
    # otherwise N is definitely composite 
    return 0;
}

# selfridge's method for finding the tuple (D,P,Q) for is_strong_lucas_pseudoprime
# private functions expect a Math::GMPz object
sub _find_dpq_selfridge($) {
  my $n = $_[0];
  my ($d,$sign,$wd) = (5,1,0);
  my $gcd = GMP->new;

  # determine D
  while (1) {
    $wd = $d * $sign;

    Rmpz_gcd_ui($gcd, $n, abs $wd);
    if ($gcd > 1 && Rmpz_cmp($n, $gcd) > 0) {
      debug "1 < $gcd < $n => $n is composite with factor $wd" if DEBUG;
      return 0;
    }
    my $j = Rmpz_jacobi(GMP->new($wd), $n);
    if ($j == -1) {
      debug "Rmpz_jacobi($wd, $n) == -1 => found D" if DEBUG;
      last; 
    }
    # didn't find D, increment and swap sign
    $d += 2;
    $sign = -$sign;
  }
  # P = 1
  my ($p,$q) = (1,0);
  {
      use integer;
      # Q = (1 - D) / 4
      $q = (1 - $wd) / 4;
  }
  debug "found P and Q: ($p, $q)" if DEBUG;
  return ($wd, $p, $q);
}

# method returns 0 if N < two or even, returns 1 if N == 2
# returns 2 if N > 2 and odd
# private functions expect a Math::GMPz object
sub _check_two_and_even($) {
  my $n = $_[0];

  my $cmp = Rmpz_cmp_ui($n, 2);
  return 1 if $cmp == 0;
  return 0 if $cmp < 0;
  return 0 if Rmpz_even_p($n);
  return 2;
}


sub is_prime($) {
    my $n = shift;
    $n = GMP->new("$n");

    if (Rmpz_cmp_ui($n, 2) == -1) {
        return 0;
    }
    if (Rmpz_cmp_ui($n, 257) == -1) {
        return _is_small_prime($n);
    } elsif ( Rmpz_cmp_ui($n, 9_080_191) == -1 ) {
        return 0 unless is_strong_pseudoprime($n,31);
        return 0 unless is_strong_pseudoprime($n,73);
        return 2;
    } elsif ( Rmpz_cmp_ui($n, 4_759_123_141) == -1 ) {
        return 0 unless is_strong_pseudoprime($n,2);
        return 0 unless is_strong_pseudoprime($n,7);
        return 0 unless is_strong_pseudoprime($n,61);
        return 2;
    }
    # the strong_pseudoprime test is quicker, do it first
    return is_strong_pseudoprime($n,2) && is_strong_lucas_pseudoprime($n);
}


sub next_prime($) {
  my $n = shift;
  $n = GMP->new("$n");
  my $cmp = Rmpz_cmp_ui($n, 2 ); #check if $n < 2
  if ($cmp < 0) {
    return GMP->new(2);
  }
  if (Rmpz_odd_p($n)) {         # if N is odd
    Rmpz_add_ui($n, $n, 2);     # N = N + 2
  } else {
    Rmpz_add_ui($n, $n, 1);     # N = N + 1
  }
  # N is now the next odd number
  while (1) {
    return $n if is_prime($n);  # check primality of that number, return if prime
    Rmpz_add_ui($n, $n, 2);     # N = N + 2
  }
}


sub prev_prime($) {
  my $n = shift;
  $n = GMP->new("$n");
  my $cmp = Rmpz_cmp_ui($n, 3);   # compare N with 3
  if ($cmp == 0) {                # N = 3
    return GMP->new(2);
  } elsif ($cmp < 0) {            # N < 3
    return undef;
  } else {
    if (Rmpz_odd_p($n)) {         # if N is odd
      Rmpz_sub_ui($n, $n, 2);     # N = N - 2
    } else {
      Rmpz_sub_ui($n, $n, 1);     # N = N - 1
    }
    # N is now the previous odd number
    while (1) {
      return $n if is_prime($n);  # check primality of that number, return if prime
      Rmpz_sub_ui($n, $n, 2);     # N = N - 2
    } 
  }
}


sub prime_count($) {
  my $n      = shift;
  $n = GMP->new("$n") unless ref($n) eq 'Math::GMPz';
  my $primes = 0;

  return 0 if $n <= 1;

  do { $primes++ if $n >= $_ } for (2,3,5,7,11,13,17,19,23,29);
  for (my $i = GMP->new(31); Rmpz_cmp($i, $n) <= 0; Rmpz_add_ui($i, $i, 2)) {
    next unless 1 == Rmpz_gcd_ui($Math::GMPz::NULL, $i, 3234846615);
    $primes++ if is_prime($i);
  }

  return $primes;
}


exp(0); # End of Math::Primality

__END__

=pod

=head1 NAME

Math::Primality - Check for primes with Perl

=head1 VERSION

version 0.08

=head1 SYNOPSIS

    use Math::Primality qw/:all/;

    my $t1 = is_pseudoprime($x,$base);
    my $t2 = is_strong_pseudoprime($x);

    print "Prime!" if is_prime($outrageously_large_prime);

    my $t3 = next_prime($x); 

=head1 DESCRIPTION

Math::Primality implements is_prime() and next_prime() as a replacement for Math::PARI::is_prime().  It uses the GMP library through Math::GMPz.  The is_prime() method is actually a Baillie-PSW primality test which consists of two steps:

=over 4

=item * Perform a strong Miller-Rabin probable prime test (base 2) on N

=item * Perform a strong Lucas-Selfridge test on N (using the parameters suggested by Selfridge)

=back

At any point the function may return 2 which means N is definitely composite.  If not, N has passed the strong Baillie-PSW test and is either prime or a strong Baillie-PSW pseudoprime.  To date no counterexample (Baillie-PSW strong pseudoprime) is known to exist for N < 10^15.  Baillie-PSW requires O((log n)^3) bit operations.  See L<http://www.trnicely.net/misc/bpsw.html> for a more thorough introduction to the Baillie-PSW test. Also see L<http://mpqs.free.fr/LucasPseudoprimes.pdf> for a more theoretical introduction to the Baillie-PSW test. 

=head1 NAME

Math::Primality - Advanced Primality Algorithms using GMP

=head1 EXPORT

=head1 FUNCTIONS

=head2 is_pseudoprime($n,$b)

Returns true if $n is a base $b pseudoprime, otherwise false.  The variable $n
should be a Perl integer or Math::GMPz object.

The default base of 2 is used if no base is given. Base 2 pseudoprimes are often called Fermat pseudoprimes.

    if ( is_pseudoprime($n,$b) ) {
        # it's a pseudoprime
    } else {
        # not a psuedoprime
    }

=head3 Details

A pseudoprime is a number that satisfies Fermat's Little Theorm, that is, $b^ ($n - 1) = 1 mod $n.

=head2 is_strong_pseudoprime($n,$b)

Returns true if $n is a base $b strong pseudoprime, false otherwise.  The variable $n should be a Perl integer
or a Math::GMPz object. Strong psuedoprimes are often called Miller-Rabin pseudoprimes.

The default base of 2 is used if no base is given.

    if ( is_strong_pseudoprime($n,$b) ) {
        # it's a strong pseudoprime
    } else {
        # not a strong psuedoprime
    }

=head3 Details

A strong pseudoprime to $base is an odd number $n with ($n - 1) = $d * 2^$s that either satisfies

=over 4

=item * $base^$d = 1 mod $n

=item * $base^($d * 2^$r) = -1 mod $n, for $r = 0, 1, ..., $s-1

=back

=head3 Notes

The second condition is checked by sucessive squaring $base^$d and reducing that mod $n.

=head2 is_strong_lucas_pseudoprime($n)

Returns true if $n is a strong Lucas-Selfridge pseudoprime, false otherwise.  The variable $n should be a Perl
integer or a Math::GMPz object.  

    if ( is_strong_lucas_pseudoprime($n) ) {
        # it's a strong Lucas-Selfridge pseudoprime
    } else {
        # not a strong Lucas-Selfridge psuedoprime
        # i.e. definitely composite
    }

=head3 Details

If we let

=over 4

=item * $D be the first element of the sequence 5, -7, 9, -11, 13, ... for which ($D/$n) = -1.  Let $P = 1 and $Q = (1 - $D) /4

=item * U($P, $Q) and V($P, $Q) be Lucas sequences

=item * $n + 1 = $d * 2^$s + 1

=back

Then a strong Lucas-Selfridge pseudoprime is an odd, non-perfect square number $n with that satisfies either

=over 4

=item * U_$d = 0 mod $n

=item * V_($d * 2^$r) = 0 mod $n, for $r = 0, 1, ..., $s-1

=back

=head3 Notes

($d/$n) refers to the Legendre symbol.

=head2 is_prime($n)

Returns 2 if $n is definitely prime, 1 is $n is a probable prime, 0 if $n is composite.

    if ( is_prime($n) ) {
        # it's a prime
    } else {
        # definitely composite
    }

=head3 Details

is_prime() is implemented using the BPSW algorithim which is a combination of two probable-prime 
algorithims, the strong Miller-Rabin test and the strong Lucas-Selfridge test.  While no
psuedoprime has been found for N < 10^15, this does not mean there is not a pseudoprime. A 
possible improvement would be to instead implement the AKS test which runs in quadratic time and 
is deterministic with no false-positives.

=head3 Notes

The strong Miller-Rabin test is implemented by is_strong_pseudoprime(). The strong Lucas-Selfridge test is implemented
by is_strong_lucas_pseudoprime().

We have implemented some optimizations.  We have an array of small primes to check all $n <= 257. According to 
L<http://primes.utm.edu/prove/prove2_3.html> if $n < 9,080,191 is a both a base-31 and a base-73 strong pseudoprime,
 then $n is prime. If $n < 4,759,123,141 is a base-2, base-7 and base-61 strong pseudoprime, then $n is prime.

=head2 next_prime($n)

Given a number, produces the next prime number.

    my $q = next_prime($n);

=head3 Details

Each next greatest odd number is checked until one is found to be prime

=head3 Notes

Checking of primality is implemented by is_prime()

=head2 prev_prime($n)

Given a number, produces the previous prime number.

    my $q = prev_prime($n);

=head3 Details

Each previous odd number is checked until one is found to be prime.  prev_prime(2) or for any number less than 2 returns undef

=head3 Notes

Checking of primality is implemented by is_prime()

=head2 prime_count($n)

Returns the number of primes less than or equal to $n.

    my $count = prime_count(1000);          # $count = 168
    my $bigger_count = prime_count(10000);  # $bigger_count = 1229

=head3 Details

This is implemented with a simple for loop.  The Meissel, Lehmer, Lagarias, Miller,
Odlyzko method is considerably faster.  A paper can be found at 
L<http://www.ams.org/mcom/1996-65-213/S0025-5718-96-00674-6/S0025-5718-96-00674-6.pdf>
that describes this method in rigorous detail.

=head3 Notes

Checking of primality is implemented by is_prime()

=head1 AUTHORS

Jonathan "Duke" Leto, C<< <jonathan at leto.net> >>
Bob Kuo, C<< <bobjkuo at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-math-primality at
rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Math::Primality>.  I will be
notified, and then you'll automatically be notified of progress on your bug as I
make changes.

=head1 THANKS

The algorithms in this module have been ported from the C source code in
bpsw1.zip by Thomas R. Nicely, available at http://www.trnicely.net/misc/bpsw.html
or in the spec/bpsw directory of the Math::Primality source code. Without his
research this module would not exist.

The Math::GMPz module that interfaces with the GMP C-library was written and is 
maintained by Sysiphus.  Without his work, our work would be impossible.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Math::Primality

You can also look for information at:

=over 4

=item * Math::Primality on Github

L<http://github.com/leto/math--primality/tree/master>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Math::Primality>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Math::Primality>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Math::Primality>

=item * Search CPAN

L<http://search.cpan.org/dist/Math::Primality>

=back

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

Copyright 2009-2011 Jonathan "Duke" Leto, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 AUTHOR

Jonathan "Duke" Leto <jonathan@leto.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Leto Labs LLC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
