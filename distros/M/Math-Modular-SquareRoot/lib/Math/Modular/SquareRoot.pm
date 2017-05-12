=head1 Name

Math::Modular::SquareRoot - Modular square roots

=head1 Synopsis

=cut


package Math::Modular::SquareRoot;

use Carp;
use strict;
use Scalar::Util qw(looks_like_number);


# Check a parameter is a positive integer

sub posInteger($$$)
 {my ($s, $p, $n) = @_;
  ++$p;
  if (ref($n) eq "Math::BigInt")
   {$n > 0                or croak "$s(parameter $p) must be a positive integer not $n";
   }
  else
   {looks_like_number($n) or croak "$s(parameter $p): $n not a number";
    int($n) == $n         or croak "$s(parameter $p): $n not an integer";
    $n > 1                or croak "$s(parameter $p): $n not allowed as argument";
   }
 }


# Check a parameter is any integer

sub anyInteger($$$)
 {my ($s, $p, $n) = @_;
  ++$p;
  if (ref($n) eq "Math::BigInt")
   {}
  else
   {looks_like_number($n) or croak "$s(parameter $p): $n not a number";
    int($n) == $n         or croak "$s(parameter $p): $n not an integer";
   }
 }


=pod

Find the integer square roots of $S modulo $a, where $S,$a are integers:

 use Math::Modular::SquareRoot qw(:msqrt);

 msqrt1(3,11);

 # 5 6

=cut

sub msqrt1($$)
 {my ($S, $a) = @_;
  anyInteger('msqrt1',0,$S);
  posInteger('msqrt1',1,$a);

  $S %= $a;

  my @r;
  push @r, 0 if $S == 0;
  my $l = 0;
  for($_ = 1; $_ < $a; ++$_)
   {$l += 2*$_-1;
    $l %= $a;
    push @r, $_ if $l == $S;
   }
  @r
 }


=pod

Find the integer square roots of $S modulo $a*$b when $S,$a,$b are
integers:

 use Math::Modular::SquareRoot qw(:msqrt);

 msqrt2((243243 **2, 1_000_037, 1_000_039);

 # 243243 243252243227 756823758219 1000075758200

=cut

sub msqrt2($$$)
 {my ($S, $a, $b) = @_;             

  anyInteger('msqrt2',0,$S);
  posInteger('msqrt2',1,$a);
  posInteger('msqrt2',2,$b);

  my  @A = msqrt1($S, $a);
  my  @B = msqrt1($S, $b);
  my ($m, $n) = dgcd($a, $b);
  
  my @r;
  for my $A(@A)
   {for my $B(@B)
     {push @r, (($B-$A)*$a*$m+$A) % ($a*$b);
     }
   }
  @r
 }


=pod

Find the greatest common divisor of a list of numbers:

 use Math::Modular::SquareRoot qw(gcd);

 gcd 10,12,6;

 # 2

=cut


sub gcd(@)
 {my (@n) = grep {$_} @_;

# Validate

  anyInteger('gcd',$_,$_[$_]) for 0..$#_;

  @n > 0 or croak "gcd(@_) requires at least one non zero numeric argument";

  $_ = abs($_) for @n;


# Find gcd

  my $g = sub 
   {my ($a, $b) = @_;

    for(;my $r = $a % $b;) 
     {$a = $b; $b = $r;
     }
     $b
    };

# Find gcd of list


  my $n = shift @n;
  $n = &$g($n, $_) for @n;
   
  $n
 }


=pod

Find the greatest common divisor of two numbers, optimized for speed
with no parameter checking:

 use Math::Modular::SquareRoot qw(gcd2);

 gcd2 9,24;

 # 3

=cut

sub gcd2($$)
 {my ($a, $b) = @_;

  for(;my $r = $a % $b;) 
   {$a = $b; $b = $r;
   }

  abs $b
 }


my $comment = << 'end';

given: a,b, gcd(a,b) == 1, N % a = A,  N % b = B find N
 => N = ai + A = bj + B
 => ai - bj = B - A = C

We can find am-bn = 1
 => Cam-Cbn = C
 => Cam = ai, Cbn = bj
 => N = Cam+A      = Cbn+B
 => N = (B-A)am+A  = (B-A)bn+B

To find m,n for 41m-12n=1
   a*m  -  b*n   =  c
  41    - 12*3   =  5  12/5 = 2, 2+1 = 3                  
  41*3  - 12*10  =  3 
  5     - 3      =  2
  5*2   - 3*3    =  1
 =>
  41*2  - 12*6   = 10
  41*9  - 12*30  =  9
 =>
  41*-7 - 12*-24 =  1
 =>
  12*24 - 41*7   =  1

end


=pod

Solve $a*$m+$b*$n == 1 for integers $m,$n, given integers $a,$b where
gcd($a,$b) == 1 

 use Math::Modular::SquareRoot qw(dgcd);

 dgcd(12, 41); 

 # 24 -7
 # 24*12-7*41 == 1 

=cut

sub dgcd($$)
 {anyInteger('dgcd',$_,$_[$_]) for 0..$#_;
   {my $d = gcd2($_[0], $_[1]);
    $d == 1 or croak "dgcd(@_) == $d: arguments are not coprime to each other"; 
   }

  my $d; $d = sub
   {my ($a,  $b)  = @_;
    return ($a,$b) if $b == 1;
    my ($m, $n) = (1, ($a - $a % $b) / $b);
    my  $c      = ($a*$m - $b*$n);

    return($m, $n) if $c == 1;

    my $c1 = ($b - $b % $c) / $c + 1;
    my ($M, $N) = ($c1*$m, $c1*$n+1);
    my  $C      = $a*$M - $b*$N;

    return($M, $N) if $C == 1;
       
    my ($mM, $nN);
    ($mM, $nN) = &$d($c, $C) if $c > $C;
    ($nN, $mM) = &$d($C, $c) if $C > $c;

    ($m*$mM-$M*$nN, $n*$mM-$N*$nN) 
   };

  my ($a, $b) = @_;
  my ($A, $B) = (0, 0);
  my ($m, $n);
  ($A = 1, $a = -$a) if $a < 0; 
  ($B = 1, $b = -$b) if $b < 0;
  if ($a > $b)
   {($m, $n) = &$d($a, $b); $n = -$n;
   }
  else
   {($n, $m) = &$d($b, $a); $m = -$m;
   }
  $m = -$m if $A;
  $n = -$n if $B;
   {$a = -$a if $A; 
    $b = -$b if $B;
    my $r = $m*$a+$b*$n;
    $r == 1 or croak "dgcd(@_): m=$m*a=$a+b=$b*n=$n == $r != 1";
   }

  ($m, $n);
 }


=pod

Factorial of a number:

 use Math::Modular::SquareRoot qw(factorial);

 factorial(6);

 # 720

=cut

sub factorial($)
 {my ($n) = @_;
  posInteger('factorial',0,$n);

  return 1 if $n == 1;

  my $p = 1; $p *= $_ for 2..$n;

  $p
 }  



=pod

Check whether an integer is a prime: 

 use Math::Modular::SquareRoot qw(prime);

 prime(9);

 # 0 

or possibly prime by trying to factor a specified number of times:

 use Math::Modular::SquareRoot qw(prime);

 prime(2**31-1, 7);

 # 1 

=cut

sub prime($;$)
 {my ($p, $n) = @_;
  posInteger('prime',$_,$_[$_]) for 0..$#_;

  return 1 if $p == 1 or $p == 2 or$p == 3 or $p == 5 or $p == 7;
  return 0 if $p < 11;

  my $s = int(sqrt($p))+1;
  return 0 if $p % $s == 0;

  unless ($n)
   {for(2..$s)
     {return 0 unless $p % $_;
     }
    return 1;
   }  

  my $N = 10**$n;
  $N = $s if $s < $N;
  my $D = $s - $N;

  for(2..$N)
   {return 0 if $p % $_ == 0 or gcd2($N+int(rand($D)), $p) > 1;
   }

  1
 }  


# Export details
 
require 5;
require Exporter;

use vars qw(@ISA @EXPORT_OK %EXPORT_TAGS $VERSION);

@ISA          = qw(Exporter);
@EXPORT_OK    = qw(dgcd gcd gcd2 factorial msqrt1 msqrt2 prime);
%EXPORT_TAGS  = (all=>[@EXPORT_OK], msqrt=>[qw(msqrt1 msqrt2)]);
$VERSION      = '1.001'; # Monday 23 March 2009

=head1 Description

The routines 

  msqrt1 ($S,$a*$b)> 
  msqrt2 ($S,$a,$b)>

demonstrate the difference in time required to find the modular square
root of a number $S modulo $p when the factorization of $p is
respectively unknown and known. To see this difference, compare the time
required to process test: C<t/1.t> with line 11 uncommented with that of
C<test/2.t>. The time required to find the modular square root of $S
modulo $p grows exponentially with the length $l in characters of the
number $p. For well chosen:

  $p=$a*$b

the difference in times required to recover the square root can be made
very large for small $l. The difference can be made so large that the
unfactored version takes more than a year's effort by all the computers
on planet Earth to solve, whilst the factored version can be solved in a
few seconds on one personal computer.

Ideally $a,$b and should be prime. This prevents alternate
factorizarizations of $p being present which would lower the difference
in time to find the modular square root. 


=head2 msqrt1() msqrt2()

C<msqrt1($S,$a)> finds the square roots of $S modulo $a where $S,$a are
integers. There are normally either zero or two roots for a given pair
of numbers if gcd($S,$a) == 1 although in the case that $S==0 and $a is
prime, zero will have just one square root: zero. If gcd($S,$a) != 1
there will be more pairs of square roots. The square roots are returned
as a list. C<msqrt1($a,$S)> will croak if its arguments are not
integers, or if $a is zero.

C<msqrt2($a,$b,$S)> finds the square roots of $S modulo $a*$b where
$S,$a,$b are integers. There are normally either zero or four roots for
a given triple of numbers if gcd($S,$a) == 1 and gcd($S,$b) == 1. If
this is not so there will be more pairs of square roots. The square
roots are returned as a list. C<msqrt2($a,$b,$S)> will croak if its
arguments are not integers, or if $a or $b are zero.


=head2 gcd() gcd2()

C<gcd(@_)> finds the greatest common divisor of a list of numbers @_,
with error checks to validate the parameter list. C<gcd(@_)> will croak
unless all of its arguments are integers. At least one of these integers
must be non zero.

C<gcd2($a,$b)> finds the greatest common divisor of two integers $a,$b
as quickly as possible with no error checks to validate the parameter
list. C<gcd2(@_)> can always be used as a plug in replacement for
C<gcd($a,$b)> but not vice versa.

C<dgcd($a,$b)> solves the equation:

 $a*$m+$b*$n == 1

for $m,$n given $a,$b where $a,$b,$m,$n are integers and 

 gcd($a,$b) == 1

The returned value is the list:

 ($m, $n)

A check is made that the solution does solve the above equation, a croak
is issued if this test fails. C<dgcd($a,$b)> will also croak unless
supplied with two non zero integers as parameters.


=head2 prime()

C<prime($p)> checks that $p is prime, returning 1 if it is, 0 if it is
not. C<prime($p)> will croak unless it is supplied with one integer
parameter greater than zero.

C<prime($p,$n)> checks that $p is prime by trying the first $N =
10**$n integers as divisors, while at the same time, finding the
greatest common divisor of $p and a number at chosen at random between
$N and the square root of $p $N times. If neither of these techniques
finds a divisor, it is possible that $p is prime and the
function retuerns 1, else 0. 


=head2 factorial()

C<factorial($n)> finds the product of the integers from 1 to $n.
C<factorial($n)> will croak unless $n is a positive integer.


=head1 Export

C<dgcd() factorial() gcd() gcd2() msqrt1() msqrt2() prime()> are
exported upon request. Alternatively the tag B<:all> exports all these
functions, while the tag B<:sqrt> exports just C<msqrt1() msqrt2()>.


=head1 Installation

Standard Module::Build process for building and installing modules:

  perl Build.PL
  ./Build
  ./Build test
  ./Build install

Or, if you're on a platform (like DOS or Windows) that doesn't require
the "./" notation, you can do this:

  perl Build.PL
  Build
  Build test
  Build install

=head1 Author

PhilipRBrenan@handybackup.com

http://www.handybackup.com

=head1 See Also

=over

=back

=head1 Copyright

Copyright (c) 2009 Philip R Brenan.

This module is free software. It may be used, redistributed and/or
modified under the same terms as Perl itself.

=cut
