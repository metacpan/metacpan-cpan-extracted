#############################################################################
# Math/Big.pm -- useful routines with big numbers (Math::BigInt/Math::BigFloat)

package Math::Big;

require 5.006002;	# anything lower is simple untested

use strict;
use warnings;

use Math::BigInt '1.97';
use Math::BigFloat;
use Exporter;

our $VERSION   = '1.16';
our @ISA       = qw( Exporter );
our @EXPORT_OK = qw( primes fibonacci base to_base hailstone factorial
                     euler bernoulli pi log
                     tan cos sin cosh sinh arctan arctanh arcsin arcsinh
                  );

# some often used constants:
my $four    = Math::BigFloat->new(4);
my $sixteen = Math::BigFloat->new(16);
my $fone    = Math::BigFloat->bone();		# pi
my $one     = Math::BigInt->bone();		# hailstone, sin, cos etc
my $two     = Math::BigInt->new(2);		# hailstone, sin, cos etc
my $three   = Math::BigInt->new(3);		# hailstone

my $five         = Math::BigFloat->new(5);	# for pi
my $twothreenine = Math::BigFloat->new(239);	# for pi

# In scalar context this returns the prime count (# of primes <= N).
# In array context it returns a list of primes from 2 to N.
sub primes {
  my $end = shift;
  return unless defined $end;
  $end = $end->numify() if ref($end) =~ /^Math::Big/;
  if ($end < 2) { return !wantarray ? Math::BigInt->bzero() : (); }
  if ($end < 3) { return !wantarray ? $one->copy : ($two->copy); }
  if ($end < 5) { return !wantarray ? $two->copy : ($two->copy, $three->copy); }

  $end-- unless ($end & 1);
  my $s_end = $end >> 1;
  my $whole = int( ($end>>1) / 15);
  # Be conservative.  This would result in terabytes of array output.
  die "Cannot return $end primes!" if $whole > 1_145_324_612;  # ~32 GB string
  my $sieve = "100010010010110" . "011010010010110" x $whole;
  substr($sieve, $s_end+1) = ''; # Clip to the right number of entries
  my ($n, $limit) = ( 7, int(sqrt($end)) );
  while ( $n <= $limit ) {
    for (my $s = ($n*$n) >> 1; $s <= $s_end; $s += $n) {
      substr($sieve, $s, 1) = '1';
    }
    do { $n += 2 } while substr($sieve, $n>>1, 1);
  }

  return Math::BigInt->new(1 + $sieve =~ tr/0//) if !wantarray;

  my @primes = (2, 3, 5);
  $n = 7-2;
  foreach my $s (split("0", substr($sieve, 3), -1)) {
    $n += 2 + 2 * length($s);
    push @primes, $n if $n <= $end;
  }
  return map { Math::BigInt->new($_) } @primes;
}

sub fibonacci
  {
      my $x = shift;
      $x = Math::BigInt -> new($x)
        unless ref($x) && $x -> isa("Math::BigInt");
      $x -> bfib();
  }

sub base
  {
  my ($number,$base) = @_;

  $number = Math::BigInt->new($number) unless ref $number;
  $base = Math::BigInt->new($base) unless ref $base;

  return if $number < $base;
  my $n = Math::BigInt->new(0);
  my $trial = $base;
  # 9 = 2**3 + 1
  while ($trial < $number)
    {
    $trial *= $base; $n++;
    }
  $trial /= $base; $a = $number - $trial;
  ($n,$a);
  }

sub to_base
  {
      my $x = shift;
      $x = Math::BigInt->new($x)
        unless ref($x) && $x -> isa("Math::BigInt");
      $x -> to_base(@_);
  }

sub hailstone
  {
  # return in list context the hailstone sequence, in scalar context the
  # number of steps to reach 1
  my ($n) = @_;

  $n = Math::BigInt->new($n) unless ref $n;

  return if $n->is_nan() || $n->is_negative();

  # Use the Math::BigInt lib directly for more speed, since all numbers
  # involved are positive integers.

  my $lib = Math::BigInt->config()->{lib};
  $n = $n->{value};
  my $three_ = $three->{value};
  my $two_ = $two->{value};

  if (wantarray)
    {
    my @seq;
    while (! $lib->_is_one($n))
      {
      # push @seq, Math::BigInt->new( $lib->_str($n) );
      push @seq, bless { value => $lib->_copy($n), sign => '+' }, "Math::BigInt";

      # was: ($n->is_odd()) ? ($n = $n * 3 + 1) : ($n = $n / 2);
      if ($lib->_is_odd($n))
        {
        $n = $lib->_mul ($n, $three_); $n = $lib->_inc ($n);

        # We now know that $n is at least 10 ( (3 * 3) + 1 ) because $n > 1
        # before we entered, and since $n was odd, it must have been at least
        # 3. So the next step is $n /= 2:
        push @seq, bless { value => $lib->_copy($n), sign => '+' }, "Math::BigInt";
        # this is better, but slower:
        #push @seq, Math::BigInt->new( $lib->_str($n) );
        # next step is $n /= 2 as usual (we save the else {} block, too)
        }
      $n = $lib->_div($n, $two_);
      }
    push @seq, Math::BigInt->bone();
    return @seq;
    }

  my $i = 1;
  while (! $lib->_is_one($n))
    {
    $i++;
    # was: ($n->is_odd()) ? ($n = $n * 3 + 1) : ($n = $n / 2);
    if ($lib->_is_odd($n))
      {
      $n = $lib->_mul ($n, $three_); $n = $lib->_inc ($n);

      # We now know that $n is at least 10 ( (3 * 3) + 1 ) because $n > 1
      # before we entered, and since $n was odd, it must have been at least 3.
      # So the next step is $n /= 2 as usual (we save the else {} block, too).
      $i++;			# one more (we know that $n cannot be 1)
      }
    $n = $lib->_div($n, $two_);
    }
  Math::BigInt->new($i);
  }

sub factorial
  {
  # calculate n! - use Math::BigInt bfac() for speed
  my ($n) = shift;

  if (ref($n))
    {
    $n->copy()->bfac();
    }
  else
    {
    Math::BigInt->new($n)->bfac();
    }
  }

sub bernoulli
  {
  # returns the nth Bernoulli number. In scalar context as Math::BigFloat
  # fraction, in list context as two Math:BigFloat objects, which, if divided,
  # give the same result. The series runs this:
  # 1/6, 1/30, 1/42, 1/30, 5/66, 691/2730, etc

  # Since I do not have yet a way to compute this, I have a table of the
  # first 40. So bernoulli(41) will fail for now.

  my $n = shift;

  return if $n < 0;
  my @table_1 = ( 1,1, -1,2 );					# 0, 1
  my @table = (
                1,6, -1,30, 1,42, -1,30, 5,66, -691,2730,	# 2, 4,
                7,6, -3617,510, 43867,798,
		-174611,330,
                854513,138,
		'-236364091',2730,
		'8553103',6,
                '-23749461029',870,
                '8615841276005',14322,
		'-7709321041217',510,
		'2577687858367',6,
		'-26315271553053477373',1919190,
		'2929993913841559',6,
		'-261082718496449122051',13530,			# 40
              );
  my ($a,$b);
  if ($n < 2)
    {
    $a = Math::BigFloat->new($table_1[$n*2]);
    $b = Math::BigFloat->new($table_1[$n*2+1]);
    }
  # n is odd:
  elsif (($n & 1) == 1)
    {
    $a = Math::BigFloat->bzero();
    $b = Math::BigFloat->bone();
    }
  elsif ($n <= 40)
    {
    $n -= 2;
    $a = Math::BigFloat->new($table[$n]);
    $b = Math::BigFloat->new($table[$n+1]);
    }
  else
    {
    die 'Bernoulli numbers over 40 not yet implemented.' if $n > 40;
    }
  wantarray ? ($a,$b): $a/$b;
  }

sub euler
  {
  # Calculate Euler's number.
  # first argument is x, so that result is e ** x
  # Second argument is accuracy (number of significant digits), it
  # stops when at least so much plus one digits are 'stable' and then
  # rounds it. Default is 42.
  my $x = $_[0];
  $x = Math::BigFloat->new($x) if !ref($x) || (!$x->isa('Math::BigFloat'));

  $x->bexp($_[1]);
  }

sub sin
  {
  # calculate sinus
  # first argument is x, so that result is sin(x)
  # Second argument is accuracy (number of significant digits), it
  # stops when at least so much plus one digits are 'stable' and then
  # rounds it. Default is 42.
  my $x = shift; $x = 0 if !defined $x;
  my $d = abs(shift || 42); $d = abs($d)+1;

  $x = Math::BigFloat->new($x) if ref($x) ne 'Math::BigFloat';

  # taylor:      x^3   x^5   x^7   x^9
  #    sin = x - --- + --- - --- + --- ...
  # 		  3!    5!    7!    9!

  # difference for each term is thus x^2 and 1,2

  my $sin = $x->copy(); my $last = 0;
  my $sign = 1;				# start with -=
  my $x2 = $x * $x; 			# X ^ 2, difference between terms
  my $over = $x2 * $x; 			# X ^ 3
  my $below = Math::BigFloat->new(6); my $factorial = Math::BigFloat->new(4);
  while ($sin->bcmp($last) != 0) # no $x-$last > $diff because bdiv() limit on accuracy
    {
    $last = $sin->copy();
    if ($sign == 0)
      {
      $sin += $over->copy()->bdiv($below,$d);
      }
    else
      {
      $sin -= $over->copy()->bdiv($below,$d);
      }
    $sign = 1-$sign;					# alternate
    $over *= $x2;					# $x*$x
    $below *= $factorial; $factorial++;			# n*(n+1)
    $below *= $factorial; $factorial++;
    }
  $sin->bround($d-1);
  }

sub cos
  {
  # calculate cosinus
  # first argument is x, so that result is cos(x)
  # Second argument is accuracy (number of significant digits), it
  # stops when at least so much plus one digits are 'stable' and then
  # rounds it. Default is 42.
  my $x = shift; $x = 0 if !defined $x;
  my $d = abs(shift || 42); $d = abs($d)+1;

  $x = Math::BigFloat->new($x) if ref($x) ne 'Math::BigFloat';

  # taylor:      x^2   x^4   x^6   x^8
  #    cos = 1 - --- + --- - --- + --- ...
  # 		  2!    4!    6!    8!

  # difference for each term is thus x^2 and 1,2

  my $cos = Math::BigFloat->bone(); my $last = 0;
  my $over = $x * $x;			# X ^ 2
  my $x2 = $over->copy();		# X ^ 2; difference between terms
  my $sign = 1;				# start with -=
  my $below = Math::BigFloat->new(2); my $factorial = Math::BigFloat->new(3);
  while ($cos->bcmp($last) != 0) # no $x-$last > $diff because bdiv() limit on accuracy
    {
    $last = $cos->copy();
    if ($sign == 0)
      {
      $cos += $over->copy()->bdiv($below,$d);
      }
    else
      {
      $cos -= $over->copy()->bdiv($below,$d);
      }
    $sign = 1-$sign;					# alternate
    $over *= $x2;					# $x*$x
    $below *= $factorial; $factorial++;			# n*(n+1)
    $below *= $factorial; $factorial++;
    }
  $cos->round($d-1);
  }

sub tan
  {
  # calculate tangens
  # first argument is x, so that result is tan(x)
  # Second argument is accuracy (number of significant digits), it
  # stops when at least so much plus one digits are 'stable' and then
  # rounds it. Default is 42.
  my $x = shift; $x = 0 if !defined $x;
  my $d = abs(shift || 42); $d = abs($d)+1;

  $x = Math::BigFloat->new($x) if ref($x) ne 'Math::BigFloat';

  # taylor:  1         2            3            4           5

  #		      x^3          x^5          x^7          x^9
  #    tan = x + 1 * -----  + 2 * ----- + 17 * ----- + 62 * ----- ...
  # 		       3           15           315         2835
  #
  #  2^2n * ( 2^2n - 1) * Bn * x^(2n-1)          256*255 * 1 * x^7   17
  #  ---------------------------------- : n=4:  ----------------- = --- * x^7
  #               (2n)!                            40320 * 30       315
  #
  # 8! = 40320, B4 (Bernoully number 4) = 1/30

  # for each term we need: 2^2n, but if we have 2^2(n-1) we use n = (n-1)*2
  # 2 copy, 7 bmul, 2 bdiv, 3 badd, 1 bernoulli

  my $tan = $x->copy(); my $last = 0;
  my $x2 = $x*$x;
  my $over = $x2*$x;
  my $below = Math::BigFloat->new(24);	 	# (1*2*3*4) (2n)!
  my $factorial = Math::BigFloat->new(5);	# for next (2n)!
  my $two_n = Math::BigFloat->new(16);	 	# 2^2n
  my $two_factor = Math::BigFloat->new(4); 	# 2^2(n+1) = $two_n * $two_factor
  my ($b,$b1,$b2); $b = 4;
  while ($tan->bcmp($last) != 0) # no $x-$last > $diff because bdiv() limit on accuracy
    {
    $last = $tan->copy();
    ($b1,$b2) = bernoulli($b);
    $tan += $over->copy()->bmul($two_n)->bmul($two_n - $fone)->bmul($b1->babs())->bdiv($below,$d)->bdiv($b2,$d);
    $over *= $x2;				# x^3, x^5 etc
    $below *= $factorial; $factorial++;		# n*(n+1)
    $below *= $factorial; $factorial++;
    $two_n *= $two_factor;			# 2^2(n+1) = 2^2n * 4
    $b += 2;					# next bernoulli index
    last if $b > 40;				# safeguard
    }
  $tan->round($d-1);
  }

sub sinh
  {
  # calculate sinus hyperbolicus
  # first argument is x, so that result is sinh(x)
  # Second argument is accuracy (number of significant digits), it
  # stops when at least so much plus one digits are 'stable' and then
  # rounds it. Default is 42.
  my $x = shift; $x = 0 if !defined $x;
  my $d = abs(shift || 42); $d = abs($d)+1;

  $x = Math::BigFloat->new($x) if ref($x) ne 'Math::BigFloat';

  # taylor:       x^3   x^5   x^7
  #    sinh = x + --- + --- + --- ...
  # 	           3!    5!    7!

  # difference for each term is thus x^2 and 1,2

  my $sinh = $x->copy(); my $last = 0;
  my $x2 = $x*$x;
  my $over = $x2 * $x; my $below = Math::BigFloat->new(6); my $factorial = Math::BigFloat->new(4);
  while ($sinh->bcmp($last)) # no $x-$last > $diff because bdiv() limit on accuracy
    {
    $last = $sinh->copy();
    $sinh += $over->copy()->bdiv($below,$d);
    $over *= $x2;					# $x*$x
    $below *= $factorial; $factorial++;			# n*(n+1)
    $below *= $factorial; $factorial++;
    }
  $sinh->bround($d-1);
  }

sub cosh
  {
  # calculate cosinus hyperbolicus
  # first argument is x, so that result is cosh(x)
  # Second argument is accuracy (number of significant digits), it
  # stops when at least so much plus one digits are 'stable' and then
  # rounds it. Default is 42.
  my $x = shift; $x = 0 if !defined $x;
  my $d = abs(shift || 42); $d = abs($d)+1;

  $x = Math::BigFloat->new($x) if ref($x) ne 'Math::BigFloat';

  # taylor:       x^2   x^4   x^6
  #    cosh = x + --- + --- + --- ...
  # 	           2!    4!    6!

  # difference for each term is thus x^2 and 1,2

  my $cosh = Math::BigFloat->bone(); my $last = 0;
  my $x2 = $x*$x;
  my $over = $x2; my $below = Math::BigFloat->new(); my $factorial = Math::BigFloat->new(3);
  while ($cosh->bcmp($last)) # no $x-$last > $diff because bdiv() limit on accuracy
    {
    $last = $cosh->copy();
    $cosh += $over->copy()->bdiv($below,$d);
    $over *= $x2;					# $x*$x
    $below *= $factorial; $factorial++;			# n*(n+1)
    $below *= $factorial; $factorial++;
    }
  $cosh->bround($d-1);
  }

sub arctan
  {
  # calculate arcus tangens
  # first argument is x, so that result is arctan(x)
  # Second argument is accuracy (number of significant digits), it
  # stops when at least so much plus one digits are 'stable' and then
  # rounds it. Default is 42.
  my $x = shift; $x = 0 if !defined $x;
  my $d = abs(shift || 42); $d = abs($d)+1;

  $x = Math::BigFloat->new($x) if ref($x) ne 'Math::BigFloat';

  # taylor:      x^3   x^5   x^7   x^9
  # arctan = x - --- + --- - --- + --- ...
  # 		  3     5    7      9

  # difference for each term is thus x^2 and 2:
  # 2 copy, 1 bmul, 1 badd, 1 bdiv

  my $arctan = $x->copy(); my $last = 0;
  my $x2 = $x*$x;
  my $over = $x2*$x; my $below = Math::BigFloat->new(3); my $add = Math::BigFloat->new(2);
  my $sign = 1;
  while ($arctan->bcmp($last)) # no $x-$last > $diff because bdiv() limit on A
    {
    $last = $arctan->copy();
    if ($sign == 0)
      {
      $arctan += $over->copy()->bdiv($below,$d);
      }
    else
      {
      $arctan -= $over->copy()->bdiv($below,$d);
      }
    $sign = 1-$sign;					# alternate
    $over *= $x2;					# $x*$x
    $below += $add;
    }
  $arctan->bround($d-1);
  }

sub arctanh
  {
  # calculate arcus tangens hyperbolicus
  # first argument is x, so that result is arctanh(x)
  # Second argument is accuracy (number of significant digits), it
  # stops when at least so much plus one digits are 'stable' and then
  # rounds it. Default is 42.
  my $x = shift; $x = 0 if !defined $x;
  my $d = abs(shift || 42); $d = abs($d)+1;

  $x = Math::BigFloat->new($x) if ref($x) ne 'Math::BigFloat';

  # taylor:       x^3   x^5   x^7   x^9
  # arctanh = x + --- + --- + --- + --- + ...
  # 	 	   3     5    7      9

  # difference for each term is thus x^2 and 2:
  # 2 copy, 1 bmul, 1 badd, 1 bdiv

  my $arctanh = $x->copy(); my $last = 0;
  my $x2 = $x*$x;
  my $over = $x2*$x; my $below = Math::BigFloat->new(3); my $add = Math::BigFloat->new(2);
  while ($arctanh->bcmp($last)) # no $x-$last > $diff because bdiv() limit on A
    {
    $last = $arctanh->copy();
    $arctanh += $over->copy()->bdiv($below,$d);
    $over *= $x2;					# $x*$x
    $below += $add;
    }
  $arctanh->bround($d-1);
  }

sub arcsin
  {
  # calculate arcus sinus
  # first argument is x, so that result is arcsin(x)
  # Second argument is accuracy (number of significant digits), it
  # stops when at least so much plus one digits are 'stable' and then
  # rounds it. Default is 42.
  my $x = shift; $x = 0 if !defined $x;
  my $d = abs(shift || 42); $d = abs($d)+1;

  $x = Math::BigFloat->new($x) if ref($x) ne 'Math::BigFloat';

  # taylor:      1 * x^3   1 * 3 * x^5   1 * 3 * 5 * x^7
  # arcsin = x + ------- + ----------- + --------------- + ...
  # 		 2 *  3    2 * 4 *  5    2 * 4 * 6 *   7

  # difference for each term is thus x^2 and two muls (fac1, fac2):
  # 3 copy, 3 bmul, 1 bdiv, 3 badd

  my $arcsin = $x->copy(); my $last = 0;
  my $x2 = $x*$x;
  my $over = $x2*$x; my $below = Math::BigFloat->new(6);
  my $fac1 = Math::BigFloat->new(1);
  my $fac2 = Math::BigFloat->new(2);
  my $two = Math::BigFloat->new(2);
  while ($arcsin->bcmp($last)) # no $x-$last > $diff because bdiv() limit on A
    {
    $last = $arcsin->copy();
    $arcsin += $over->copy()->bmul($fac1)->bdiv($below->copy->bmul($fac2),$d);
    $over *= $x2;					# $x*$x
    $below += $one;
    $fac1 += $two;
    $fac2 += $two;
    }
  $arcsin->bround($d-1);
  }

sub arcsinh
  {
  # calculate arcus sinus hyperbolicus
  # first argument is x, so that result is arcsinh(x)
  # Second argument is accuracy (number of significant digits), it
  # stops when at least so much plus one digits are 'stable' and then
  # rounds it. Default is 42.
  my $x = shift; $x = 0 if !defined $x;
  my $d = abs(shift || 42); $d = abs($d)+1;

  $x = Math::BigFloat->new($x) if ref($x) ne 'Math::BigFloat';

  # taylor:      1 * x^3   1 * 3 * x^5   1 * 3 * 5 * x^7
  # arcsin = x - ------- + ----------- - --------------- + ...
  # 		 2 *  3    2 * 4 *  5    2 * 4 * 6 *   7

  # difference for each term is thus x^2 and two muls (fac1, fac2):
  # 3 copy, 3 bmul, 1 bdiv, 3 badd

  my $arcsinh = $x->copy(); my $last = 0;
  my $x2 = $x*$x; my $sign = 0;
  my $over = $x2*$x; my $below = 6;
  my $fac1 = Math::BigInt->new(1);
  my $fac2 = Math::BigInt->new(2);
  while ($arcsinh ne $last) # no $x-$last > $diff because bdiv() limit on A
    {
    $last = $arcsinh->copy();
    if ($sign == 0)
      {
      $arcsinh += $over->copy()->bmul(
        $fac1)->bdiv($below->copy->bmul($fac2),$d);
      }
    else
      {
      $arcsinh -= $over->copy()->bmul(
        $fac1)->bdiv($below->copy->bmul($fac2),$d);
      }
    $over *= $x2;					# $x*$x
    $below += $one;
    $fac1 += $two;
    $fac2 += $two;
    }
  $arcsinh->round($d-1);
  }

sub log
  {
  my ($x,$base,$d) = @_;

  my $y;
  if (!ref($x) || !$x->isa('Math::BigFloat'))
    {
    $y = Math::BigFloat->new($x);
    }
  else
    {
    $y = $x->copy();
    }
  $y->blog($base,$d);
  $y;
  }

sub pi
  {
  # calculate PI (as suggested by Robert Creager)
  my $digits = abs(shift || 1024);

  my $d = $digits+5;

  my $pi =  $sixteen * arctan( scalar $fone->copy()->bdiv($five,$d), $d )
             - $four * arctan( scalar $fone->copy()->bdiv($twothreenine,$d), $d);
  $pi->bround($digits+1);	# +1 for the "3."
  }

1;

__END__

#############################################################################

=pod

=head1 NAME

Math::Big - routines (cos,sin,primes,hailstone,euler,fibbonaci etc) with big numbers

=head1 SYNOPSIS

    use Math::Big qw/primes fibonacci hailstone factors wheel
      cos sin tan euler bernoulli arctan arcsin pi/;

    @primes	= primes(100);		# first 100 primes
    $count	= primes(100);		# number of primes <= 100
    @fib	= fibonacci (100);	# first 100 fibonacci numbers
    $fib_1000	= fibonacci (1000);	# 1000th fibonacci number
    $hailstone	= hailstone (1000);	# length of sequence
    @hailstone	= hailstone (127);	# the entire sequence

    $factorial	= factorial(1000);	# factorial 1000!

    $e = euler(1,64); 			# e to 64 digits

    $b3 = bernoulli(3);

    $cos	= cos(0.5,128);		# cosinus to 128 digits
    $sin	= sin(0.5,128);		# sinus to 128 digits
    $cosh	= cosh(0.5,128);	# cosinus hyperbolicus to 128 digits
    $sinh	= sinh(0.5,128);	# sinus hyperbolicus to 128 digits
    $tan	= tan(0.5,128);		# tangens to 128 digits
    $arctan	= arctan(0.5,64);	# arcus tangens to 64 digits
    $arcsin	= arcsin(0.5,32);	# arcus sinus to 32 digits
    $arcsinh	= arcsin(0.5,18);	# arcus sinus hyperbolicus to 18 digits

    $pi		= pi(1024);		# first 1024 digits
    $log	= log(64,2);		# $log==6, because 2**6==64
    $log	= log(100,10);		# $log==2, because 10**2==100
    $log	= log(100);		# base defaults to 10: $log==2

=head1 REQUIRES

perl5.006002, Exporter, Math::BigInt, Math::BigFloat

=head1 EXPORTS

Exports nothing on default, but can export C<primes()>, C<fibonacci()>,
C<hailstone()>, C<bernoulli>, C<euler>, C<sin>, C<cos>, C<tan>, C<cosh>,
C<sinh>, C<arctan>, C<arcsin>, C<arcsinh>, C<pi>, C<log> and C<factorial>.

=head1 DESCRIPTION

This module contains some routines that may come in handy when you want to
do some math with really, really big (or small) numbers. These are primarily
examples.

=head1 FUNCTIONS

=over

=item primes()

	@primes = primes($n);
	$primes = primes($n);

Calculates all the primes below N and returns them as array. In scalar context
returns the prime count of N (the number of primes less than or equal to N).

This uses an optimized version of the B<Sieve of Eratosthenes>, which takes
half of the time and half of the space, but is still O(N).

=item fibonacci()

	@fib = fibonacci($n);
	$fib = fibonacci($n);

Calculates the first N fibonacci numbers and returns them as array.
In scalar context returns the Nth number of the Fibonacci series.

The scalar context version uses an ultra-fast conquer-divide style algorithm
to calculate the result and is many times faster than the straightforward way
of calculating the linear sum.

=item hailstone()

	@hail = hailstone($n);		# sequence
	$hail = hailstone($n);		# length of sequence

Calculates the I<Hailstone> sequence for the number N. This sequence is defined
as follows:

	while (N != 0)
	  {
          if (N is even)
	    {
            N is N /2
   	    }
          else
	    {
            N = N * 3 +1
	    }
          }

It is not yet proven whether for every N the sequence reaches 1, but it
apparently does so. The number of steps is somewhat chaotically.

=item base()

	($n,$a) = base($number,$base);

Reduces a number to C<$base> to the C<$n>th power plus C<$a>. Example:

	use Math::BigInt :constant;
	use Math::Big qw/base/;

	print base ( 2 ** 150 + 42,2);

This will print 150 and 42.

=item to_base()

	$string = to_base($number,$base);

	$string = to_base($number,$base, $alphabet);

Returns a string of C<$number> in base C<$base>. The alphabet is optional if
C<$base> is less or equal than 36. C<$alphabet> is a string.

Examples:

	print to_base(15,2);		# 1111
	print to_base(15,16);		# F
	print to_base(31,16);		# 1F

=item factorial()

	$n = factorial($number);

Calculate C<n!> for C<n >= 0>.

Uses internally Math::BigInt's bfac() method.

=item bernoulli()

	$b = bernoulli($n);
	($c,$d) = bernoulli($n);	# $b = $c/$d

Calculate the Nth number in the I<Bernoulli> series. Only the first 40 are
defined for now.

=item euler()

	$e = euler($x,$d);

Calculate I<Euler's constant> to the power of $x (usual 1), to $d digits.
Defaults to 1 and 42 digits.

=item sin()

	$sin = sin($x,$d);

Calculate I<sinus> of C<$x>, to C<$d> digits.

=item cos()

	$cos = cos($x,$d);

Calculate I<cosinus> of C<$x>, to C<$d> digits.

=item tan()

	$tan = tan($x,$d);

Calculate I<tangens> of C<$x>, to C<$d> digits.

=item arctan()

	$arctan = arctan($x,$d);

Calculate I<arcus tangens> of C<$x>, to C<$d> digits.

=item arctanh()

	$arctanh = arctanh($x,$d);

Calculate I<arcus tangens hyperbolicus> of C<$x>, to C<$d> digits.

=item arcsin()

	$arcsin = arcsin($x,$d);

Calculate I<arcus sinus> of C<$x>, to C<$d> digits.

=item arcsinh()

	$arcsinh = arcsinh($x,$d);

Calculate I<arcus sinus hyperbolicus> of C<$x>, to C<$d> digits.

=item cosh()

	$cosh = cosh($x,$d);

Calculate I<cosinus hyperbolicus> of C<$x>, to C<$d> digits.

=item sinh()

	$sinh = sinh($x,$d);

Calculate I<sinus hyperbolicus> of $<$x>, to C<$d> digits.

=item pi()

	$pi = pi($N);

The number PI to C<$N> digits after the dot.

=item log()

	$log = log($number,$base,$A);

Calculates the logarithmn of C<$number> to base C<$base>, with C<$A> digits
accuracy and returns a new number as the result (leaving C<$number> alone).

Math::BigInt objects are promoted to Math::BigFloat objects, meaning you will
never get a truncated integer result like when using C<Math::BigInt->blog()>.

=back

=head1 CAVEATS

=over 4

=item *

Primes and the Fibonacci series use an array of size N and will not be able
to calculate big sequences due to memory constraints.

The exception is fibonacci in scalar context, this is able to calculate
arbitrarily big numbers in O(N) time:

	use Math::Big;
	use Math::BigInt qw/:constant/;

	$fib = Math::Big::fibonacci( 2 ** 320 );

=item *

The Bernoulli numbers are not yet calculated, but looked up in a table, which
has only 40 elements. So C<bernoulli($x)> with $x > 42 will fail.

If you know of an algorithmn to calculate them, please drop me a note.

=back

=head1 BUGS

Please report any bugs or feature requests to
C<bug-math-big at rt.cpan.org>, or through the web interface at
L<https://rt.cpan.org/Ticket/Create.html?Queue=Math-Big>
(requires login).
We will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Math::Big

You can also look for information at:

=over 4

=item * GitHub

L<https://github.com/pjacklam/p5-Math-Big>

=item * RT: CPAN's request tracker

L<https://rt.cpan.org/Dist/Display.html?Name=Math-Big>

=item * MetaCPAN

L<https://metacpan.org/release/Math-Big>

=item * CPAN Testers Matrix

L<http://matrix.cpantesters.org/?dist=Math-Big>

=item * CPAN Ratings

L<https://cpanratings.perl.org/dist/Math-Big>

=back

=head1 LICENSE

This program is free software; you may redistribute it and/or modify it under
the same terms as Perl itself.

=head1 AUTHOR

=over

=item *

Tels http://bloodgate.com 2001-2007.

=item *

Peter John Acklam E<lt>pjacklam@gmail.comE<gt> 2016-.

=back

=cut
