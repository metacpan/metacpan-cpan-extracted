#################################################################
#
#   Math::Polynom - Operations on polynoms
#
#   $Id: Polynom.pm,v 1.10 2007/07/11 13:01:48 erwan_lemonnier Exp $
#
#   061025 erwan Started implementation
#   061206 erwan Added the secant method
#   061214 erwan Added Brent's method
#   070112 erwan Fixed bug in identification of nan scalars
#   070220 erwan Updated POD to warn for convergence toward non roots
#   070404 erwan Added $DEBUG
#   070412 erwan Updated POD
#   070417 erwan Modified disclaimer
#   070711 erwan Use looks_like_number and float_is_nan
#

package Math::Polynom;

use 5.006;
use strict;
use warnings;
use Carp qw(confess croak);
use Data::Dumper;
use Data::Float qw(float_is_nan);
use Scalar::Util qw(looks_like_number);

use accessors qw(error error_message iterations xpos xneg);

use constant NO_ERROR             => 0;
use constant ERROR_NAN            => 1;
use constant ERROR_MAX_DEPTH      => 2;
use constant ERROR_EMPTY_POLYNOM  => 3;
use constant ERROR_DIVIDE_BY_ZERO => 4;
use constant ERROR_WRONG_SIGNS    => 5;
use constant ERROR_NOT_A_ROOT     => 6;

our $VERSION = '0.13';
our $DEBUG = 0;

#----------------------------------------------------------------
#
#   _debug
#

sub _debug {
    my $msg = shift;
    print STDOUT "Math::Polynom: $msg\n" if ($DEBUG);
}

#----------------------------------------------------------------
#
#   _add_monom - add a monom to a polynomial, ie a $coef**$power
#

sub _add_monom {
    my($self,$coef,$power) = @_;

    if (exists $self->{polynom}->{$power}) {
	$self->{polynom}->{$power} += $coef;
    } else {
	$self->{polynom}->{$power} = $coef;
    }
    return $self;
}

#----------------------------------------------------------------
#
#   _clean - remove terms with zero as coefficient
#

sub _clean {
    my $self = shift;

    while (my($power,$coef) = each %{$self->{polynom}}) {
	if ($coef == 0) {
	    delete $self->{polynom}->{$power};
	}
    }

    return $self;
}

#----------------------------------------------------------------
#
#   _is_root - return true if the polynomial evaluates to something close enough to 0 on the root
#

sub _is_root {
    my ($self,$value) = @_;
    return (abs($self->eval($value)) < 1);
}

#----------------------------------------------------------------
#
#   _error - die nicely
#

sub _error {
    my $msg = shift;
    croak __PACKAGE__." ERROR: $msg\n";
}

sub _exception {
    my ($self,$code,$msg,$args) = @_;

    $msg = "ERROR: $msg\nwith polynom:\n".$self->stringify."\n";
    if (defined $args) {
	$msg .= "with arguments:\n".Dumper($args);
    }
    $msg .= "at iteration ".$self->iterations."\n";

    $self->error_message($msg);
    $self->error($code);

    croak $self->error_message;
}

#################################################################
#
#
#   PUBLIC
#
#
#################################################################

#----------------------------------------------------------------
#
#   new - construct a new polynomial
#

sub new {
    my($pkg,@args) = @_;
    $pkg = ref $pkg || $pkg;

    _error("new() got odd number of arguments. can not be a hash") if (scalar(@args) % 2);

    my %hash = @args;
    foreach my $n (@args) {
	_error("at least one argument of new() is not numeric:\n".Dumper(\%hash)) if (!looks_like_number($n));
    }

    my $self = bless({polynom => \%hash},$pkg)->_clean;
    $self->error(NO_ERROR);
    $self->iterations(0);

    return $self;
}

#----------------------------------------------------------------
#
#   clone - return a clone of self
#

sub clone {
    my $self = shift;
    return __PACKAGE__->new(%{$self->{polynom}});
}

#----------------------------------------------------------------
#
#   stringify - return current polynomial as a string
#

sub stringify {
    my $self = shift;
    return join(" + ", map { $self->{polynom}->{$_}."*x^".$_ } reverse sort keys %{$self->{polynom}});
}

#----------------------------------------------------------------
#
#   derivate - return the polynomial's derivate
#

sub derivate {
    my $self = shift;
    my $result = __PACKAGE__->new();
    while (my($power,$coef) = each %{$self->{polynom}} ) {
	$result->_add_monom($coef*$power,$power-1);
    }
    return $result->_clean;
}

#----------------------------------------------------------------
#
#   eval - evaluate the polynomial on a given value, return result
#

sub eval {
    my($self,$x) = @_;

    _error("eval() got wrong number of arguments")  if (scalar @_ != 2);
    _error("eval() got undefined argument")         if (!defined $x);
    _error("eval()'s argument is not numeric ($x)") if (!looks_like_number($x));

    my $r = 0;
    while (my($power,$coef) = each %{$self->{polynom}} ) {
	$r += $coef*($x**$power);
    }

    if (!float_is_nan($r)) {
	if (!defined $self->xpos && $r > 0) {
	    $self->xpos($x);
	} elsif (!defined $self->xneg && $r < 0) {
	    $self->xneg($x);
	}
    }

    return $r;
}

#----------------------------------------------------------------
#
#   add - add a polynomial/number to current polynomial
#

sub add {
    my($self,$p) = @_;

    _error("add() got wrong number of arguments") if (scalar @_ != 2);
    _error("add() got undefined argument")        if (!defined $p);

    # adding 2 polynomials
    if (ref $p eq __PACKAGE__) {
	my $result = $self->clone;
	while (my($power,$coef) = each %{$p->{polynom}}) {
	    $result->_add_monom($coef,$power);
	}
	return $result->_clean;
    }

    # adding a constant to a polynomial
    _error("add() got non numeric argument") if (!looks_like_number($p));

    return $self->clone->_add_monom($p,0)->_clean;
}

#----------------------------------------------------------------
#
#   minus - substract a polynomial/number to current polynomial
#

sub minus {
    my($self,$p) = @_;

    _error("minus() got wrong number of arguments") if (scalar @_ != 2);
    _error("minus() got undefined argument")        if (!defined $p);

    if (ref $p eq __PACKAGE__) {
	return $self->clone->add($p->negate)->_clean;
    }

    _error("minus() got non numeric argument") if (!looks_like_number($p));

    return $self->clone->_add_monom(-$p,0)->_clean;
}

#----------------------------------------------------------------
#
#   negate - negate current polynomial
#

sub negate {
    my $self = shift;
    return __PACKAGE__->new(map { $_, - $self->{polynom}->{$_} } keys %{$self->{polynom}})->_clean;
}

#----------------------------------------------------------------
#
#   multiply - multiply current polynomial with a polynomial/number
#

sub multiply {
    my($self,$p) = @_;

    _error("multiply() got wrong number of arguments") if (scalar @_ != 2);
    _error("multiply() got undefined argument")        if (!defined $p);

    if (ref $p eq __PACKAGE__) {
	my $result = __PACKAGE__->new;
	while (my($power1,$coef1) = each %{$self->{polynom}}) {
	    while (my($power2,$coef2) = each %{$p->{polynom}}) {
		$result->_add_monom($coef1 * $coef2, $power1 + $power2);
	    }
	}
	return $result->_clean;
    }

    _error("multiply() got non numeric argument") if (!looks_like_number($p));

    return __PACKAGE__->new(map { $_, $p * $self->{polynom}->{$_} } keys %{$self->{polynom}})->_clean;
}

#----------------------------------------------------------------
#
#   divide - divide the current polynomial with a float
#

sub divide {
    my($self,$x) = @_;

    _error("divide() got wrong number of arguments") if (scalar @_ != 2);
    _error("divide() got undefined argument")        if (!defined $x);
    _error("divide() got non numeric argument")      if (!looks_like_number($x));
    _error("cannot divide by 0")                     if ($x == 0);

    return __PACKAGE__->new(map { $_, $self->{polynom}->{$_}/$x } keys %{$self->{polynom}})->_clean;
}

#----------------------------------------------------------------
#
#   newton_raphson - attempt to find a polynomial's root with Newton Raphson
#

sub newton_raphson {
    my($self,%hash) = @_;
    my $new_guess = 1;
    my $precision = 0.1;
    my $max_depth = 100;

    $self->iterations(0);
    $self->error(NO_ERROR);

    $new_guess = $hash{guess}     if (exists $hash{guess});
    $precision = $hash{precision} if (exists $hash{precision});
    $max_depth = $hash{max_depth} if (exists $hash{max_depth});

    _error("newton_raphson() got undefined guess")       if (!defined $new_guess);
    _error("newton_raphson() got undefined precision")   if (!defined $precision);
    _error("newton_raphson() got undefined max_depth")   if (!defined $max_depth);
    _error("newton_raphson() got non numeric guess")     if (!looks_like_number($new_guess));
    _error("newton_raphson() got non numeric precision") if (!looks_like_number($precision));
    _error("newton_raphson() got non integer max_depth") if ($max_depth !~ /^\d+$/);

    $self->_exception(ERROR_EMPTY_POLYNOM,"cannot find the root of an empty polynom",\%hash)
	if (scalar keys %{$self->{polynom}} == 0);

    my $derivate = $self->derivate;
    my $old_guess = $new_guess - 2*$precision; # pass the while condition first time

    while (abs($new_guess - $old_guess) > $precision) {
	$old_guess = $new_guess;

	my $dividend = $derivate->eval($old_guess);
	$self->_exception(ERROR_DIVIDE_BY_ZERO,"division by zero: polynomial's derivate is 0 at $old_guess",\%hash)
	    if ($dividend == 0);

	$new_guess = $old_guess - $self->eval($old_guess)/$dividend;

	$self->iterations($self->iterations + 1);
	$self->_exception(ERROR_MAX_DEPTH,"reached maximum number of iterations [$max_depth] without getting close enough to the root.",\%hash)
	    if ($self->iterations > $max_depth);

	$self->_exception(ERROR_NAN,"new guess is not a real number in newton_raphson().",\%hash)
	    if (float_is_nan($new_guess));
    }

    if (!$self->_is_root($new_guess)) {
	$self->_exception(ERROR_NOT_A_ROOT,"newton_raphson() converges toward $new_guess but that doesn't appear to be a root.",\%hash);
    }

    return $new_guess;
}

#----------------------------------------------------------------
#
#   secant - implement the Secant algorithm to approximate the root of this polynomial
#

sub secant {
    my ($self,%hash) = @_;
    my $precision = 0.1;
    my $max_depth = 100;
    my ($p0,$p1);

    $self->iterations(0);
    $self->error(NO_ERROR);

    $precision = $hash{precision} if (exists $hash{precision});
    $max_depth = $hash{max_depth} if (exists $hash{max_depth});
    $p0        = $hash{p0}        if (exists $hash{p0});
    $p1        = $hash{p1}        if (exists $hash{p1});

    _error("secant() got undefined precision")      if (!defined $precision);
    _error("secant() got undefined max_depth")      if (!defined $max_depth);
    _error("secant() got non numeric precision")    if (!looks_like_number($precision));
    _error("secant() got non integer max_depth")    if ($max_depth !~ /^\d+$/);
    _error("secant() got undefined p0")             if (!defined $p0);
    _error("secant() got undefined p1")             if (!defined $p1);
    _error("secant() got non numeric p0")           if (!looks_like_number($p0));
    _error("secant() got non numeric p1")           if (!looks_like_number($p1));
    _error("secant() got same value for p0 and p1") if ($p0 == $p1);

    $self->_exception(ERROR_EMPTY_POLYNOM,"cannot find the root of an empty polynomial",\%hash)
	if (scalar keys %{$self->{polynom}} == 0);

    # NOTE: this code is almost a copy/paste from Math::Function::Roots, I just added exception handling

    my $q0 = $self->eval($p0);
    my $q1 = $self->eval($p1);
    my $p;

    $self->_exception(ERROR_NAN,"q0 or q1 are not a real number in first eval in secant()",\%hash)
	if (float_is_nan($q0) || float_is_nan($q1));

    return $p0 if ($q0 == 0);
    return $p1 if ($q1 == 0);

    for (my $depth = 1; $depth <= $max_depth; $depth++) {

	$self->iterations($depth);

	$self->_exception(ERROR_DIVIDE_BY_ZERO,"division by zero with p0=$p0, p1=$p1, q1=q0=$q1 in secant()",\%hash)
	    if (($q1 - $q0) == 0);

	$p = ($q1 * $p0 - $p1 * $q0) / ($q1 - $q0);

	$self->_exception(ERROR_NAN,"p is not a real number in secant()",\%hash)
	    if (float_is_nan($p));

	my $debug = "secant at depth ".$self->iterations.", p0=$p0, p1=$p1, p=$p";

	$p0 = $p1;
	$q0 = $q1;
	$q1 = $self->eval($p);

	$self->_exception(ERROR_NAN,"q1 is not a real number in secant()",\%hash)
	    if (float_is_nan($q1));

	_debug($debug.", poly(p)=$q1");

	if ($q1 == 0 || abs($p - $p1) <= $precision) {
	    if (!$self->_is_root($p)) {
		$self->_exception(ERROR_NOT_A_ROOT,"secant() converges toward $p but that doesn't appear to be a root.",\%hash);
	    }
	    return $p;
	}

	$p1 = $p;
    }

    $self->_exception(ERROR_MAX_DEPTH,"reached maximum number of iterations [$max_depth] without getting close enough to the root in secant()",\%hash);
}

#----------------------------------------------------------------
#
#   brent - implement Brent's method to approximate the root of this polynomial
#

sub brent {
    my($self,%hash) = @_;
    my $precision = 0.1;
    my $max_depth = 100;
    my $mflag;
    my($a,$b,$c,$s,$d);
    my($f_a,$f_b,$f_c,$f_s);

    $self->iterations(0);
    $self->error(NO_ERROR);

    $precision = $hash{precision} if (exists $hash{precision});
    $max_depth = $hash{max_depth} if (exists $hash{max_depth});
    $a         = $hash{a}         if (exists $hash{a});
    $b         = $hash{b}         if (exists $hash{b});

    _error("brent() got undefined precision")      if (!defined $precision);
    _error("brent() got undefined max_depth")      if (!defined $max_depth);
    _error("brent() got non numeric precision")    if (!looks_like_number($precision));
    _error("brent() got non integer max_depth")    if ($max_depth !~ /^\d+$/);
    _error("brent() got undefined a")              if (!defined $a);
    _error("brent() got undefined b")              if (!defined $b);
    _error("brent() got non numeric a")            if (!looks_like_number($a));
    _error("brent() got non numeric b")            if (!looks_like_number($b));
    _error("brent() got same value for a and b")   if ($a == $b);

    $self->_exception(ERROR_EMPTY_POLYNOM,"cannot find the root of an empty polynomial in brent()",\%hash)
	if (scalar keys %{$self->{polynom}} == 0);

    # The following is an implementation of Brent's method as described on wikipedia
    # variable names are chosen to match the pseudocode listed on wikipedia
    # There are a few differences between this code and the pseudocode on wikipedia though...

    $f_a = $self->eval($a);
    $f_b = $self->eval($b);

    # if the polynom evaluates to a complex number on $a or $b (ex: square root, when $a = -1)
    $self->_exception(ERROR_NAN,"polynomial is not defined on interval [a=$a, b=$b] in brent()",\%hash)
	if (float_is_nan($f_a) || float_is_nan($f_b));

    # did we hit the root by chance?
    return $a if ($f_a == 0);
    return $b if ($f_b == 0);

    # $a and $b should be chosen so that poly($a) and poly($b) have opposite signs.
    # It is a prerequisite for the bisection part of Brent's method to work
    $self->_exception(ERROR_WRONG_SIGNS,"polynomial does not have opposite signs at a=$a and b=$b in brent()",\%hash)
	if ($f_a*$f_b > 0);

    # eventually swap $a and $b (don't forget to even switch f(c))
    if (abs($f_a) < abs($f_b)) {
	($a,$b) = ($b,$a);
	($f_a,$f_b) = ($f_b,$f_a);
    }

    $c = $a;
    $f_c = $f_a;

    $mflag = 1;

    # repeat while we haven't found the root nor are close enough to it
    while ($f_b != 0 && abs($b - $a) > $precision) {

	# did we reach the maximum number of iterations?
	$self->_exception(ERROR_MAX_DEPTH,"reached maximum number of iterations [$max_depth] without getting close enough to the root in brent()",\%hash)
	    if ($self->iterations > $max_depth);

	# evaluate f(a), f(b) and f(c) if necessary
	if ($self->iterations != 0) {
	    $f_a = $self->eval($a);
	    $f_b = $self->eval($b);
	    $f_c = $self->eval($c);

	    $self->_exception(ERROR_NAN,"polynomial leads to an imaginary number on a=$a in brent()",\%hash) if (float_is_nan($f_a));
	    $self->_exception(ERROR_NAN,"polynomial leads to an imaginary number on b=$b in brent()",\%hash) if (float_is_nan($f_b));
	    $self->_exception(ERROR_NAN,"polynomial leads to an imaginary number on c=$c in brent()",\%hash) if (float_is_nan($f_c));
	}

	my $debug = "brent at depth ".$self->iterations.", a=$a, b=$b";

	# calculate the next root candidate
	if ($f_a == $f_b) {
	    # we should not be able to get $f_b == $f_a since it's a prerequisite of the method. that would be a bug
	    _error("BUG: got same values for polynomial at a=$a and b=$b:\n".$self->stringify);

	} elsif ( ($f_a != $f_c) && ($f_b != $f_c) ) {
	    # use quadratic interpolation
	    $s = ($a*$f_b*$f_c)/(($f_a - $f_b)*($f_a - $f_c)) +
		($b*$f_a*$f_c)/(($f_b - $f_a)*($f_b - $f_c)) +
		($c*$f_a*$f_b)/(($f_c - $f_a)*($f_c - $f_b));
	} else {
	    # otherwise use the secant
	    $s = $b - $f_b*($b - $a)/($f_b - $f_a);
	}

	# now comes the main difference between Brent's method and Dekker's method: we want to use bisection when appropriate
	if ( ( ($s < (3*$a+$b)/4) && ($s > $b) ) ||
	     ( $mflag  && (abs($s-$b) >= (abs($b-$c)/2)) ) ||
	     ( !$mflag && (abs($s-$b) >= (abs($c-$d)/2)) ) ) {
	    # in that case, use the bisection to get $s
	    $s = ($a + $b)/2;
	    $mflag = 1;
	} else {
	    $mflag = 0;
	}

	# calculate f($s)
	$f_s = $self->eval($s);

	$self->_exception(ERROR_NAN,"polynomial leads to an imaginary number on s=$s in brent()",\%hash) if (float_is_nan($f_s));

	_debug($debug.", s=$s, poly(s)=$f_s");

	$d = $c;
	$c = $b;
	$f_c = $f_b;

	if ($f_a*$f_s <= 0) {
	    # important that b=s if f(s)=0 since the while loop checks f(b)
	    # if f(a)=0, and f(b)!=0, then a and b will be swaped and we will therefore have f(b)=0
	    $b = $s;
	    $f_b = $f_s;
	} else {
	    $a = $s;
	    $f_a = $f_s;
	}

	# eventually swap $a and $b
	if (abs($f_a) < abs($f_b)) {
	    # in the special case when
	    ($a,$b) = ($b,$a);
	    ($f_a,$f_b) = ($f_b,$f_a);
	}

	$self->iterations($self->iterations + 1);
    }

    if (!$self->_is_root($b)) {
	$self->_exception(ERROR_NOT_A_ROOT,"brent() converges toward $b but that doesn't appear to be a root.",\%hash);
    }

    return $b;
}

1;

__END__

=head1 NAME

Math::Polynom - Operations on polynomials

=head1 SYNOPSIS

    use Math::Polynom;

To create the polynomial 'x^3 + 4*x^2 + 1', write:

    my $p1 = Math::Polynom->new(3 => 1, 2 => 4, 0 => 1);

To create '3.5*x^4.2 + 1.78*x^0.9':

    my $p2 = Math::Polynom->new(4.2 => 3.5, 0.9 => 1.78);

Common operations:

    my $p3 = $p1->multiply($p2); # multiply 2 polynomials
    my $p3 = $p1->multiply(4.5); # multiply a polynomial with a constant

    my $p3 = $p1->add($p2);      # add 2 polynomials
    my $p3 = $p1->add(3.6);      # add a constant to a polynomial

    my $p3 = $p1->minus($p2);    # substract 2 polynomials
    my $p3 = $p1->minus(1.5);    # substract a constant to a polynomial

    my $p3 = $p1->negate();      # negate a polynomial

    my $p3 = $p1->divide(3.2);   # divide a polynomial by a constant

    my $v = $p1->eval(1.35);     # evaluate the polynomial on a given value

    my $p3 = $p1->derivate();    # return the derivate of a polynomial

    print $p1->stringify."\n";   # stringify polynomial

To try to find a root to a polynomial using the Newton Raphson method:

    my $r;
    eval { $r = $p1->newton_raphson(guess => 2, precision => 0.001); };
    if ($@) {
	if ($p1->error) {
	    # that's an internal error
	    if ($p1->error == Math::Polynom::ERROR_NAN) {
		# bumped on a complex number
	    }
	} else {
	    # either invalid arguments (or a bug in solve())
	}
    }

Same with the secant method:

    eval { $r = $p1->secant(p0 => 0, p2 => 2, precision => 0.001); };


=head1 DESCRIPTION

What! Yet another module to manipulate polynomials!!
No, don't worry, there is a good reason for this one ;)

I needed (for my work at a large financial institution) a robust way to compute the internal rate of return (IRR)
of various cashflows.
An IRR is typically obtained by solving a usually ugly looking polynomial of one variable with up to hundreds of
coefficients and non integer powers (ex: powers with decimals). I also needed thorough exception handling.
Other CPAN modules providing operations on polynomials did not fill those requirements.

If what you need is to manipulate simple polynomials with integer powers, without concern for failures,
check out Math::Polynomial since it provides a more complete api than Math::Polynom.

An instance of Math::Polynom is a representation of a 1-variable polynomial.
It supports a few basic operations specific to polynomials such as addition, substraction and multiplication.

Math::Polynom also implements various root finding algorithms (which is kind of
the main purpose of this module) such as the Newton Raphson, Secant and Brent methods.


=head1 API

=over 4

=item $p1 = B<new(%power_coef)>

Create a new Math::Polynom. Each key in the hash C<%power_coef> is a power
and each value the corresponding coefficient.

=item $p3 = $p1->B<clone()>

Return a clone of the current polynomial.

=item $p3 = $p1->B<add($p2)>

Return a new polynomial that is the sum of the current polynomial with the polynomial C<$p2>.
If C<$p2> is a scalar, we add it to the current polynomial as a numeric constant.

Croaks if provided with weird arguments.

=item $p3 = $p1->B<minus($p2)>

Return a new polynomial that is the current polynomial minus the polynomial C<$p2>.
If C<$p2> is a scalar, we substract it from the current polynomial as a numeric constant.

Croaks if provided with weird arguments.

=item $p3 = $p1->B<multiply($p2)>

Return a new polynomial that is the current polynomial multiplied by C<$p2>.
If C<$p2> is a scalar, we multiply all the coefficients in the current polynomial with it.

Croaks if provided with weird arguments.

=item $p3 = $p1->B<negate()>

Return a new polynomial in which all coefficients have the negated sign of those in the current polynomial.

=item $p3 = $p1->B<divide($float)>

Return a new polynomial in which all coefficients are equal to those of the current polynomial divided by the number C<$float>.

Croaks if provided with weird arguments.

=item $p3 = $p1->B<derivate()>

Return a new polynomial that is the derivate of the current polynomial.

=item $v = $p1->B<eval($float)>

Evaluate the current polynomial on the value C<$float>.

If you call C<eval> with a negative value that would yield a complex (non real) result,
C<eval> will no complain but return the string 'nan'.

Croaks if provided with weird arguments.

=item $s = $p1->B<stringify()>

Return a basic string representation of the current polynomial. For exemple '3*x^5 + 2*x^2 + 1*x^0'.

=item $r = $p1->B<< newton_raphson(guess => $float1, precision => $float2, max_depth => $integer) >>

Uses the Newton Raphson algorithm to approximate a root for this polynomial. Beware that this require
your polynomial AND its derivate to be continuous.
Starts the search with C<guess> and returns the root when the difference between two
consecutive estimations of the root is smaller than C<precision>. Make at most C<max_depth>
iterations.

If C<guess> is omitted, 1 is used as default.
If C<precision> is omitted, 0.1 is used as default.
If C<max_depth> is omitted, 100 is used as default.

C<newton_raphson> will fail (croak) in a few cases: If the successive approximations of the root
still differ with more than C<precision> after C<max_depth> iterations, C<newton_raphson> dies,
and C<< $p1->error >> is set to the code Math::Polynom::ERROR_MAX_DEPTH. If an approximation
is not a real number, C<newton_raphson> dies and C<< $p1->error >> is set to the code Math::Polynom::ERROR_NAN.
If the polynomial is empty, C<newton_raphson> dies and C<< $p1->error >> is set to the code
Math::Polynom::ERROR_EMPTY_POLYNOM. If C<newton_raphson> converges toward a number but this number is
not a root (ie the polynomial evaluates to a large number on it), C<newton_raphson> dies and the
error attribute is set to Math::Polynom::ERROR_NOT_A_ROOT.

C<newton_raphson> will also croak if provided with weird arguments.

Exemple:

    eval { $p->newton_raphson(guess => 1, precision => 0.0000001, max_depth => 50); };
    if ($@) {
	if ($p->error) {
	    if ($p->error == Math::Polynom::ERROR_MAX_DEPTH) {
		# do something wise
	    } elsif ($p->error == Math::Polynom::ERROR_MAX_DEPTH) {
		# do something else
	    } else { # empty polynomial
		die "BUG!";
	    }
	} else {
	    die "newton_raphson died for unknown reason";
	}
    }


=item $r = $p1->B<< secant(p0 => $float1, p1 => $float2, precision => $float3, max_depth => $integer) >>

Use the secant method to approximate a root for this polynomial. C<p0> and C<p1> are the two start values
to initiate the search, C<precision> and C<max_depth> have the same meaning as for C<newton_raphson>.

The polynomial should be continuous. Therefore, the secant method might fail on polynomialial having monoms
with degrees lesser than 1.

If C<precision> is omitted, 0.1 is used as default.
If C<max_depth> is omitted, 100 is used as default.

C<secant> will fail (croak) in a few cases: If the successive approximations of the root
still differ with more than C<precision> after C<max_depth> iterations, C<secant> dies,
and C<< $p1->error >> is set to the code Math::Polynom::ERROR_MAX_DEPTH. If an approximation
is not a real number, C<secant> dies and C<< $p1->error >> is set to the code Math::Polynom::ERROR_NAN.
If the polynomial is empty, C<secant> dies and C<< $p1->error >> is set to the code
Math::Polynom::ERROR_EMPTY_POLYNOM. If C<secant> converges toward a number but this number is
not a root (ie the polynomial evaluates to a large number on it), C<secant> dies and the
error attribute is set to Math::Polynom::ERROR_NOT_A_ROOT.

C<secant> will also croak if provided with weird arguments.


=item $r = $p1->B<< brent(a => $float1, b => $float2, precision => $float3, max_depth => $integer) >>

Use Brent's method to approximate a root for this polynomial. C<a> and C<b> are two floats such that
C<< p1->eval(a) >> and C<< p1->eval(b) >> have opposite signs.
C<precision> and C<max_depth> have the same meaning as for C<newton_raphson>.

The polynomial should be continuous on the interval [a,b].

Brent's method is considered to be one of the most robust root finding methods. It alternatively
uses the secant, inverse quadratic interpolation and bisection to find the next root candidate
at each iteration, making it a robust but quite fast converging method.

The difficulty with Brent's method consists in finding the start values a and b for which
the polynomial evaluates to opposite signs. This is somewhat simplified in Math::Polynom
by the fact that C<eval()> automatically sets C<xpos()> and C<xneg()> when possible.

If C<precision> is omitted, 0.1 is used as default.
If C<max_depth> is omitted, 100 is used as default.

C<brent> will fail (croak) in a few cases: If the successive approximations of the root
still differ with more than C<precision> after C<max_depth> iterations, C<brent> dies,
and C<< $p1->error >> is set to the code Math::Polynom::ERROR_MAX_DEPTH. If an approximation
is not a real number, C<brent> dies and C<< $p1->error >> is set to the code Math::Polynom::ERROR_NAN.
If the polynomial is empty, C<brent> dies and C<< $p1->error >> is set to the code
Math::Polynom::ERROR_EMPTY_POLYNOM. If provided with a and b that does not lead to values
having opposite signs, C<brent> dies and C<< $p1->error >> is set to the code Math::Polynom::ERROR_WRONG_SIGNS.
If C<brent> converges toward a number but this number is not a root (ie the polynomial evaluates
to a large number on it), C<brent> dies and the
error attribute is set to Math::Polynom::ERROR_NOT_A_ROOT.

C<brent> will also croak if provided with weird arguments.


=item $p1->B<error>, $p1->B<error_message>

Respectively the error code and error message set by the last method that failed to run
on this polynomial. For exemple, if C<newton_raphson> died, you would access the code of the error
with C<error()> and a message describing the context of the error in details with
C<error_message>.

If the polynomial has no error, C<error> returns Math::polynom::NO_ERROR and
C<error_message> returns undef.


=item $p1->B<iterations>

Return the number of iterations it took to find the polynomial's root. Must be called
after calling one of the root finding methods.


=item $p1->B<xpos>, $p1->B<xneg>

Each time C<eval> is called, it checks whether we know a value xpos for which the polynomial
evaluates to a positive value. If not and if the value provided to C<eval> lead to a positive
result, this value is stored in C<xpos>. Same thing with C<xneg> and negative results.

This comes in handy when you wish to try the Brent method after failing with the secant
or Newton methods. If you are lucky, those failed attempts will have identified both a
xpos and xneg that you can directly use as a and b in C<brent()>.


=back


=head1 DEBUG

To display debug information, set in your code:

    local $Math::Polynom::DEBUG = 1;


=head1 ERROR HANDLING

Each method of a polynomial may croak if provided with wrong arguments. Methods that take arguments
do thorough controls on whether the arguments are of the proper type and in the right quantity.
If the error is internal, the method will croak after setting the polynomial's error and error_message
to specific values.

Math::Polynom defines a few error codes, returned by the method C<error>:

=over 4

=item B<Math::polynom::NO_ERROR> is the default return value of method C<error>, and is always set to 0.

=item B<Math::polynom::ERROR_NAN> means the function jammed on a complex number. Most likely because your polynomial is not continuous on the search interval.

=item B<Math::polynom::ERROR_DIVIDE_BY_ZERO> means what it says.

=item B<Math::polynom::ERROR_MAX_DEPTH> means the root finding algorithm failed to find a good enough root after the specified maximum number of iterations.

=item B<Math::polynom::ERROR_EMPTY_POLYNOM> means you tried to perform an operation on an empty polynomial (such as C<newton_raphson)>

=item B<Math::polynom::ERROR_WRONG_SIGNS> means that the polynomial evaluates to values having the same signs instead of opposite signs on the boundaries of the interval you provided to start the search of the root (ex: Brent's method)

=item B<Math::polynom::ERROR_NOT_A_ROOT> means the root finding method converged toward one value but this value appears not to be a root. A value is accepted as a root if the polynomial evaluates on it to a number between -1 and 1 (ie close enough to 0).

=back

=head1 BUGS AND LIMITATIONS

This module is built for robustness in order to run in requiring production environments.
Yet it has one limitation: due to Perl's
inability at handling large floats, root finding algorithms will get lost if starting on a guess
value that is too far from the root. Example:

    my $p = Math::Polynom->new(2 => 1, 1 => -2, 0 => 1); # x^2 -2*x +1
    $p->newton_raphson(guess => 100000000000000000);
    # returns 1e17 as the root

=head1 REPOSITORY

The source of Math::Polynom is hosted at sourceforge as part of the xirr4perl project. You can access
it at https://sourceforge.net/projects/xirr4perl/.

=head1 SEE ALSO

See Math::Calculus::NewtonRaphson, Math::Polynomial, Math::Function::Roots.

=head1 VERSION

$Id: Polynom.pm,v 1.10 2007/07/11 13:01:48 erwan_lemonnier Exp $

=head1 THANKS

Thanks to Spencer Ogden who wrote the implementation of the Secant algorithm in his module Math::Function::Roots.

=head1 AUTHORS

Erwan Lemonnier C<< <erwan@cpan.org> >>,
as part of the Pluto developer group at the Swedish Premium Pension Authority.

=head1 LICENSE

This code was developed at the Swedish Premium Pension Authority as part of
the Authority's software development activities. This code is distributed
under the same terms as Perl itself. We encourage you to help us improving
this code by sending feedback and bug reports to the author(s).

This code comes with no warranty. The Swedish Premium Pension Authority and the author(s)
decline any responsibility regarding the possible use of this code or any consequence
of its use.

=cut









