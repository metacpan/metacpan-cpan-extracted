package Math::BigApprox;
use strict;

# use POSIX qw( floor );    # Maybe, maybe not.

use vars qw( $VERSION @EXPORT_OK );
BEGIN {
    $VERSION= 0.001_005;

    require Exporter;
    *import= \&Exporter::import;
    @EXPORT_OK= qw( c Fact Prod $SigDigs );

    my $useFloor= 0;
    if(  eval { require POSIX; 1 }  ) {
        # On "long double" Perls, POSIX::floor converts to "double"
        $useFloor=  "4e+102" eq POSIX::floor(4e102);
    }
    if(  $useFloor  ) {
        *_floor= \&POSIX::floor;
    } else {
        *_floor= sub {
            return  $_[0] < 0  ?  -int(-$_[0])  :  int($_[0]);
        };
    }
}

use overload(
    '+' =>  \&_add,
    '-' =>  \&_sub,
    neg =>  \&_neg,
    '*' =>  \&_mul,
    '/' =>  \&_div,
    '**' => \&_pow,
    '^' =>  \&_prd,  # $x^$y = factorial($y)/factorial($x)
    '<<' => \&_shl,
    '>>' => \&_shr,
    '<=>'=> \&_cmp,
    '!' =>  \&_fct,  # !$x = factorial($x)
    '0+' => \&_num,
    '""' => \&_str,
    '=' =>  \&_clone,
    abs =>  \&_abs,
    log =>  \&_log,
    sqrt => \&_half,
    bool => \&_chastise,
    fallback => 1,  # autogenerate if possible
);

# Don't use these as a methods
sub c
{
    return __PACKAGE__->new( @_ );
}

sub Prod
{
    my( $x, $y )= @_;
    my $p= c( 1 );
    while(  $x <= $y  ) {
        $p *= $x++;
    }
    return $p;
}

sub Fact
{
    return Prod( 1, @_ );
}

# Public methods:
sub new
{
    my $us= shift @_;
    if(  ! @_  ) {
        die "new() needs an object or a value"
            if  ! ref $us;
        return bless [ @$us ];
    }
    my $val= shift @_;
    return bless [ 0, 0 ]
        if  0 == $val;
    return bless [ log( -$val ), -1 ]
        if  $val < 0;
    return bless [ log( $val ), 1 ]
}

sub Get
{
    my( $x )= @_;
    return wantarray ? (0,0) : 0
        if  ! $x->[1];
    return wantarray ? @$x : $x->[0];
}

sub Sign
{
    my $x= shift @_;
    my $old= $x->[1];
    if(  @_  ) {
        my $new= shift @_;
        $x->[1]= 0<$new ? 1 : 0==$new ? 0 : -1;
    }
    return $old;
}

# Private methods (please don't call these):

# This just ignores extra arguments so overload.pm can use it
sub _clone
{
    return $_[0]->new();
}

sub _chastise
{
    die "You can't use a Math::BigApprox as a Boolean.\n";
}

sub _mul
{
    my( $x, $y )= @_;
    $y= $x->new( $y )
        if  ! ref $y;
    return bless [  $x->[0] + $y->[0],  $x->[1] * $y->[1]  ];
}

sub __args
{
    my( $x, $y, $rev )= @_;
    $y= $x->new( $y )
        if  ! ref $y;
    ( $x, $y )= ( $y, $x )
        if  $rev;
    return( $x, $y );
}

sub _div
{
    my( $x, $y )= __args( @_ );
    die "Division by 0"
        if  ! $y->[1];
    return bless [  $x->[0] - $y->[0],  $x->[1] * $y->[1]  ];
}

sub _pow
{
    my( $x, $y )= __args( @_ );
    return bless [ 0, 1 ]
        if  ! $y->[1];
    return bless [ 0, 0 ]
        if  ! $x->[1];
    # We rather "punt" on the sign.
    my $sign= 1;
    if(     $x->[1] < 0
        &&  0 < $y->[1]
        &&  $y->[0] < log(1e9)
        &&  1 == int( 0.5 + exp($y->[0]) ) % 2
    ) {
        $sign= -1;
    }
    return bless [  $x->[0] * $y->_num(),  $sign  ];
}

sub _add
{
    my( $x, $y )= @_;
    $y= $x->new( $y )
        if  ! ref $y;
    return $y->new()
        if  ! $x->[1];
    return $x->new()
        if  ! $y->[1];
    ( $x, $y )= ( $y, $x )
        if  $y->[0] < $x->[0];
    if(  $x->[1] == $y->[1]  ) {
        return bless [
            $y->[0] + log( 1 + exp( $x->[0] - $y->[0] ) ),
            $x->[1],
        ];
    }
    return bless [ 0, 0 ]
        if  $x->[0] == $y->[0];
    return bless [
        $y->[0] + log( 1 - exp( $x->[0] - $y->[0] ) ),
        $y->[1],
    ];
}

sub _sub
{
    my( $x, $y )= __args( @_ );
    return $x->_add( $y->_neg() );
}

sub _neg
{
    my( $x )= @_;
    return bless [ $x->[0], -$x->[1] ];
}

sub _shl
{
    my( $x, $y )= __args( @_ );
    return bless [ $x->[0] + $y->_num()*log(2), $x->[1] ];
}

sub _shr
{
    my( $x, $y )= __args( @_ );
    return bless [ $x->[0] - $y->_num()*log(2), $x->[1] ];
}

sub _log
{
    my( $x )= @_;
    die "Can't take log(" . $x . ")\n"
        if  1 != $x->[1];
    return $x->[0];
}

sub _abs
{
    my( $x )= @_;
    return bless [ $x->[0], abs( $x->[1] ) ];
}

sub _half
{
    my( $x )= @_;
    die "Can't take sqrt(" . $x . ")\n"
        if  $x->[1] < 0;
    return bless [ $x->[0]/2, $x->[1] ];
}

sub _cmp
{
    my( $x, $y, $rev )= @_;
    $y= $x->new( $y )
        if  ! ref $y;
    return 0
        if  $x eq $y;
    ( $x, $y )= ( $y, $x )
        if  $rev;
    return $x->[1] <=> $y->[1] || $x->[1]*$x->[0] <=> $y->[1]*$y->[0];
}

sub _prd
{
    my( $x, $y )= __args( @_ );
    return bless [ 0, 1 ]
        if  $y < $x;
    my $p= $x->new();
    my $m= $x + 1;
    while(  $m <= $y  ) {
        $p= $p * $m;
        $m= $m + 1;
    }
    return $p;
}

sub _fct
{
    my( $x )= @_;
    return 1^$x;
}

sub _num
{
    my( $x )= @_;
    return $x->[1] * exp( $x->[0] );
}

use vars qw( $SigDigs $FloorMag $LenMag );
# Figure out how many significant digits are in an NV on this platform:
BEGIN {

    # Cheap trick to get at how many sig digs Perl figured out it has:
    $SigDigs= length( 10 / 7 );

    # Don't call floor() on numbers larger than this, since they can't
    # have a factional part [and floor(4e102) can substract 8e80!]
    $FloorMag= "1e" . $SigDigs;

    # Minus 1 for decmical point, minus another two just
    # because our calculations lose some precision:
    $SigDigs -= 3;

    # Long doubles leave $SigDigs set too high (probably
    # not all C RTL calls are fully long-double-using):
    $SigDigs -= 3
        if  14 < $SigDigs;

    # Don't us length() to measure magnitude on numbers larger than this:
    $LenMag= "1e" . $SigDigs;
}

sub _str
{
    my( $x )= @_;
    return 0
        if  ! $x->[1];
    my $exp= $x->[0] / log(10);
    if(  $exp  &&  2*$exp == $exp  ) {
        return 0
            if  $exp < 0;
        return $x->[1] * $exp;
    }
    $exp= sprintf "%.*g", $SigDigs-1, $exp;
    $exp= _floor( $exp )
        if  abs($exp) < $FloorMag;
    my $mant= exp( $x->[0] - log(10)*$exp );
    $mant=  1
        if  2*$mant == $mant;
    $exp= "+$exp"
        if  $exp !~ /^-/;
    my $digs=  $LenMag <= abs($exp)  ?  1  :  $SigDigs - length($exp);
    $digs= 1
        if  $digs < 1;
    $mant= sprintf "%s%.*f", $x->[1] < 0 ? '-' : '', $digs-1, $mant;
    $mant =~ s/[.]?0+$//;
    $mant .=  0==$exp  ?  ""  :  "e" . $exp;
    return $mant
        if  $digs < abs($exp);
    return 0+$mant;
}

__PACKAGE__;
__END__

=head1 NAME

Math::BigApprox - Fast and small way to closely approximate very large values.

=head1 SYNOPSIS

    require Math::BigApprox;

    my $cards=  Math::BigApprox->new( 52 );
    my $decks=  ! $cards;                   # Factorial
    my $deals=  $cards-4 ^ $cards;          # Product of sequence
    my $hands=  $deals / ! Math::BigApprox->new( 5 );

    # also

    use Math::BigApprox qw( c Prod Fact );

    $hands= ( 52-4 ^ c(52) ) / !c(5);
    # or
    $hands= Prod( 52-4, 52 ) / Fact(5)

=head1 DESCRIPTION

Math::BigApprox stores numbers as the logarithm of their (absolute) value
(along with separately tracking their sign) and so can keep track of numbers
having absolute value less than about 1e100000000 with several digits
of precision (and quite a bit of precision for numbers that are not quite so
ridiculously large).  You also lose precision for numbers ridiculuous close
to zero like 1e-10000000000.

Therefore, Math::BigApprox numbers never require a large amount of memory
and calculations with them are rather fast (usually about as fast as you'll
get with overloaded operations in Perl).

It can even do calculations with numbers as large as 10**(1e300)
(which is too large for this space even when written as "1e...").  But for
such obscenely huge numbers it only knows their magnitude, having zero
digits of precision in the mantissa (or "significand") but having reasonable
precision in the base-10 exponent (the number after the "e").  It even
displays such numbers as something like "1e1.0217e300" since the usual XeN
scientific notation is too cumbersome for such obscenely large numbers.

Math::BigApprox overloads the basic arithmatic operations (plus a few others)
so that, once you've created a Math::BigApprox number object, you can just
use it like an ordinary Perl variable to make calculations, including using
ordinary numbers in those calculations.  Calculations that mix Math::BigApprox
numbers with other types of overloaded numbers are not supported at this
time.

Addition and subtraction are done carefully so that combining values of wildly
different magnitude results in an expression like exp(-1e100) (which returns
0, a result that can safely be added/subtracted, giving a reasonably accurate
final result) not like exp(1e100) (which returns "infinity", fouling any
further calculations).

=head2 Methods

=head3 C<new>

    my $six= Math::Approx->new( 6 );
    my $halfdozen= $six->new();     # Makes a copy
    my $ten= $six->new( 10 );       # Convenient short-hand

=head3 C<Get>

In a scalar context, C<< $x->Get() >> returns "0" if C<$x==0>, otherwise
C<log(abs($x))>.  The return value is a simple Perl (floating-point) number,
not a Math::BigApprox object.

In a list context, C<< $x->Get() >> returns two scalars: the above value
followed by C<< $x->Sign() >>.

=head3 C<Sign>

C<< $x->Sign() >> returns "-1" if C<$x < 0>, "0" if C<$x == 0>, and "1" if
C<0 < $x>.

C<< $x->Sign($y) >> sets the sign of $x to match the sign of $y.  $y doesn't
have to be a plain Perl number or a Math::BigApprox number object; it can
be anything that can be used in C<0<$y> and C<0==$y>.  The previous value
of the sign is returned.

=head2 Operations

=head3 C<+>, C<->, C<*>, C</>, C<**>

The basic arithmatic operations (including unary "-", negation) serve the
traditional purposes, returning a new, overloaded Math::BigApprox object.

Of course, C<$x**0> is "1" (even for C<$x==0>) while C<0**$x> is "0" (unless
C<$x==0>).

Note that overload.pm handles expressions like C<10**$x> where $x is a
Math::BigApprox number object or even C<1+$x>, so you don't have to convert
all parts of an expression into Math::BigApprox objects, nor even the first
term in the expression.

=head3 C< <<>, C<<< >> >>>

C< $x << $y > calculates C<$x * 2**$y>.

C<<< $x >> $y >>> calculates C<$x / 2**$y>.

Each returns a Math::BigApprox number object.  Note that C<$y> doesn't have
to be an integer (nor positive).

=head3 C<!>

Logical negation has been usurped to perform factorial.  It being a unary
operation even means its precedence is reasonable for such a use, binding
tighter than the arithmatic operations so C<!$x/!$y> works as expected.

=head3 C<^>

Bit-wise xor has been usurped to perform the product of a series.
C<1^$x> is the same as C<!$x>, that is, C<1*2*3*...*$x>.  C<$x^$y> is
C<$x*($x+1)*($x+2)*...*$y> (unless C<$y-$x> is not an integer, in which
case the multiplications stop at the largest integer $N where
C<$x+$N <= $y>).  If C<$y < $x> then C<$x^$y> is "1" (the product of
nothing).

Note that C<^> binds very losely so C<$x+1 ^ 2*$y> works as expected but
C<$x^$y / !$z> really means C<$x ^ ($y/!$z)> and so needs to be written
as C<($x^$y) / !$z>.

=head3 C<< <=> >>

All of the numerical comparison operators work in the traditional manner,
comparing the values.  Only C<< <=> >> is specifically overloaded but
overload.pm automatically generates the other numeric comparisons from it.

Note that two values are considered numerically equal (C<==>) if they have
the same string representation (like C<eq>).  This avoids some of the
pitfalls of using C<==> on floating-point values.  So C<==> really means
"approximately numerically equal".

=head3 C<abs>, C<log>, C<sqrt>

These math functions work in the traditional manner.  C<log($x)> returns
an ordinary number, not a Math::BigApprox number, and dies if C<$x> is not
positive [see also Get()].  C<abs($x)> and C<sqrt($x)> return Math::BigApprox
number objects (when $x is a Math::BigApprox object).

=head3 C<"">

Math::BigApprox values are displayed (stringified) mostly like oridinary
Perl numbers, using simple decimal notation for mundane values ("-45.3")
and scientific notation for huge and tiny values ("-2.687e-97").  For
obscenely huge/tiny values, a "double scientific notation" format is
used ("1e2.68e213").

Note that Math::BigApprox doesn't overload string concatenation (C<.>),
so C<''.$x> stringifies $x just like C<"$x">.

=head3 C<0+>

Using a Math:BigApprox number object in a way that requires a simple numeric
value attempts to compute a simple number.  If the number is too tiny, then
0 is used.  If the number is too huge, then an "infinity" reserved value
will be used (the details of this vary between platforms).

For example

    printf "%g", 100 ** Math::BigApprox->new(500);

might produce

    1.#INF

Note that, despite the name used by overload.pm, C<0+$x> doesn't return a
simple number; it returns a Math::BigApprox number object (when $x is such),
a copy of $x.

=head3 Boolean

Using a Math::BigApprox alone as a Boolean expression is a fatal error.  This
is to help prevent accidental attempts to use C<!> as "Boolean not".

    if(  $x  ) {        # A fatal error
    if(  0 != $x  ) {   # What to use instead of the above

    if(  ! $x  ) {      # A coding error
    if(  0 != !$x  ) {  # What the above really means
    if(  0 == $x  ) {   # What to use instead

=head3 Other

Any other operations such as other Boolean or bit-wise operations are not
supported and using them may cause strange things to happen.  Some of these
may be usurped for other purposes in a future release of this module.

Several math functions are not explicitly supported (atan2, cos, sin, exp,
and int).  Using them on a Math::BigApprox number will cause a simple number
to be computed (possibly giving "infinity") and that value to be passed
to the math function.  This situation is unlikely to change (these functions
rarely make sense to use on really huge numbers).

=head2 Exportable Functions

The following fuctions can optionally be exported.

=head3 C<c>

C<c($num)> is just short-hand for C<< Math::BigApprox->new($num) >>.
"c" is a standard abbreviate for "circa" which means "approximate".

=head3 C<Fact>

C<Fact($n)> returns the factorial of $n.  Here $n is a regular Perl number
rather than a Math::BigApprox number object, which allows the computation
to be done slightly more efficiently than C<!c($n)>.

=head3 C<Prod>

C<Prod($from,$to)> returns the product of the numbers in the range
C<$from..$to>.  $from and $to are a regular Perl numbers rather than
Math::BigApprox number objects, which allows the computation to be done
slightly more efficiently than C<c($from) ^ c($to)>.

=head1 FUTURE IDEAS

Add an C<< $x->e($y) >> method that multiples C<$x> by C<10**$y> and a
c'tor that takes a separate significand and base-10 exponent.

=head1 SHORTCOMINGS

new() should accept string values of the same format that Math::BigApprox
values are displayed in.  Currently new() only accepts ordinary Perl
floating-point numbers (or things that can be converted to such).

Floating point imprecision means that C<$x^$y> or even C<!$x> might not
perform the final multiplication.  Since C<==> really means C<eq> for
Math::BigApprox numbers, the dynamic display precision should prevent
this from being a problem in most cases.

Calculations that mix Math::BigApprox numbers with other types of
overloaded numbers are not supported at this time.

Writing a class that inherits from Math::BigApprox is not supported
at this time.

Requesting that bare numeric constants be silently promoted to
Math::BigApprox numbers is not currently supported.

Calculating 1e-1001 ** 1e1002 (for example) produces 1e-infinity which is
displayed as "0" (and so also == 0) but should be converted to a real zero
value so that it behaves like "0" in all situations.  Then again, 1/$notzero
produces infinity, which may be even more appropriate.  This also provides a
way to represent "negative zero".

Raising a negative number to a power often ignores that the number is
negative.  c(-1)**.5 is the same as c(1)**.5 (not "NaN" because it should
be imaginary).  c(-1)**$big will usually be just 1, even when you might
consider $big to be odd (we make a half-hearted effort to decide whether
$big is odd, but don't depend on it nor be surprised if the details of
this "effort" change in future releases).

A few places C<die> that should C<croak>.

=head1 AUTHOR

Tye McQueen, http://perlmonks.org/?node=tye

=head1 SEE ALSO

The Museum of Jurassic Technology, L.A., CA, USA.

and http://perlmonks.org/?node_id=631244

=cut
