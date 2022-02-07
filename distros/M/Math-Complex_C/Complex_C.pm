use strict;
use warnings;
package Math::Complex_C;

require Exporter;
*import = \&Exporter::import;
require DynaLoader;

use overload
    '**'    => \&_overload_pow,
    '*'     => \&_overload_mul,
    '+'     => \&_overload_add,
    '/'     => \&_overload_div,
    '-'     => \&_overload_sub,
    '**='   => \&_overload_pow_eq,
    '*='    => \&_overload_mul_eq,
    '+='    => \&_overload_add_eq,
    '/='    => \&_overload_div_eq,
    '-='    => \&_overload_sub_eq,
    'sqrt'  => \&_overload_sqrt,
    '=='    => \&_overload_equiv,
    '!='    => \&_overload_not_equiv,
    '!'     => \&_overload_not,
    'bool'  => \&_overload_true,
    '='     => \&_overload_copy,
    '""'    => \&_overload_string,
    'abs'   => \&_overload_abs,
    'exp'   => \&_overload_exp,
    'log'   => \&_overload_log,
    'sin'   => \&_overload_sin,
    'cos'   => \&_overload_cos,
    'atan2' => \&_overload_atan2,
;

our $VERSION = '0.15';

Math::Complex_C->DynaLoader::bootstrap($VERSION);

@Math::Complex_C::EXPORT = ();
@Math::Complex_C::EXPORT_OK = qw(

    create_c assign_c mul_c mul_c_nv mul_c_iv mul_c_uv div_c div_c_nv div_c_iv div_c_uv add_c
    add_c_nv add_c_iv add_c_uv sub_c sub_c_nv sub_c_iv sub_c_uv real_c
    imag_c arg_c abs_c conj_c acos_c asin_c atan_c cos_c sin_c tan_c acosh_c asinh_c atanh_c
    cosh_c sinh_c tanh_c exp_c log_c sqrt_c proj_c pow_c
    get_nan get_neg_inf get_inf is_nan is_inf MCD
    add_c_pv sub_c_pv mul_c_pv div_c_pv

    str_to_d d_to_str d_to_strp d_set_prec d_get_prec set_real_c set_imag_c
    );

%Math::Complex_C::EXPORT_TAGS = (all => [qw(

    create_c assign_c mul_c mul_c_nv mul_c_iv mul_c_uv div_c div_c_nv div_c_iv div_c_uv add_c
    add_c_nv add_c_iv add_c_uv sub_c sub_c_nv sub_c_iv sub_c_uv real_c
    imag_c arg_c abs_c conj_c acos_c asin_c atan_c cos_c sin_c tan_c acosh_c asinh_c atanh_c
    cosh_c sinh_c tanh_c exp_c log_c sqrt_c proj_c pow_c
    get_nan get_neg_inf get_inf is_nan is_inf MCD
    add_c_pv sub_c_pv mul_c_pv div_c_pv

    str_to_d d_to_str d_to_strp d_set_prec d_get_prec set_real_c set_imag_c
    )]);

sub dl_load_flags {0} # Prevent DynaLoader from complaining and croaking

sub d_to_str {
    return join ' ', _d_to_str($_[0]);
}

sub d_to_strp {
    return join ' ', _d_to_strp($_[0], $_[1]);
}

sub str_to_d {
    my($re, $im) = split /\s+/, $_[0];
    $im = 0 if !defined($im);

    $re = get_nan() if $re =~ /^(\+|\-)?nan/i;
    $im = get_nan() if $im =~ /^(\+|\-)?nan/i;

    if($re =~ /^(\+|\-)?inf/i) {
      if($re =~ /^\-inf/i) {$re = get_neg_inf()}
      else {$re = get_inf()}
    }

    if($im =~ /^(\+|\-)?inf/i) {
      if($re =~ /^\-inf/i) {$im = get_neg_inf()}
      else {$im = get_inf()}
    }

    return MCD($re, $im);
}

sub _overload_string {
    my($real, $imag) = (real_c($_[0]), imag_c($_[0]));
    my($r, $i) = _d_to_str($_[0]);

    if($real == 0) {
      $r = $real =~ /^\-/ ? '-0' : '0';
    }
    elsif($real != $real) {
      $r = 'NaN';
    }
    elsif(($real / $real) != ($real / $real)) {
      $r = $real < 0 ? '-Inf' : 'Inf';
    }
    else {
      my @re = split /e/i, $r;
      while(substr($re[0], -1, 1) eq '0' && substr($re[0], -2, 1) ne '.') {
        chop $re[0];
      }
      $r = $re[0] . 'e' . $re[1];
    }

    if($imag == 0) {
      $i = $imag =~ /^\-/ ? '-0' : '0';
    }
    elsif($imag != $imag) {
      $i = 'NaN';
    }
    elsif(($imag / $imag) != ($imag / $imag)) {
      $i = $imag < 0 ? '-Inf' : 'Inf';
    }
    else {
      my @im = split /e/i, $i;
      while(substr($im[0], -1, 1) eq '0' && substr($im[0], -2, 1) ne '.') {
        chop $im[0];
      }
      $i = $im[0] . 'e' . $im[1];
    }

    return "(" . $r . " " . $i . ")";
}

sub new {


    # This function caters for 2 possibilities:
    # 1) that 'new' has been called OOP style - in which
    #    case there will be a maximum of 3 args
    # 2) that 'new' has been called as a function - in
    #    which case there will be a maximum of 2 args.
    # If there are no args, then we just want to return a
    # Math::Complex_C object

    if(!@_) {return create_c()}

    if(@_ > 3) {die "Too many arguments supplied to new()"}

    # If 'new' has been called OOP style, the first arg is the string
    # "Math::Complex_C" which we don't need - so let's remove it.

    if(!ref($_[0]) && $_[0] eq "Math::Complex_C") {
      shift;
      if(!@_) {return create_c()}
    }

    if(@_ > 2) {die "Bad argument list supplied to new()"}

    my $ret;

    if(@_ == 2) {
      $ret = create_c();
      assign_c($ret, $_[0], $_[1]);
    }
    else {
      return $_[0] if _itsa($_[0]) == 226;
      $ret = create_c();
      assign_c($ret, $_[0], 0.0);
    }

    return $ret;
}

*MCD		= \&Math::Complex_C::new;

1;

__END__

=head1 NAME

Math::Complex_C - perl interface to C's double precision complex operations.


=head1 DESCRIPTION

   use warnings;
   use strict;
   use Math::Complex_C qw(:all);
   # For brevity, use MCD which is an alias for Math::Complex_C::new
   my $c =    MCD(12.5, 1125); # assign as NV
   my $root = MCD();

   sqrt_c($root, $c);
   print "Square root of $c is $root\n";

   See also the Math::Complex_C test suite for some (simplistic) examples
   of usage.

   This module is written largely for the use of perl builds whose nvtype is
   'double'. Run "perl -V:nvtype" to see what your perl's NV type is. If your
   nvtype is 'long double' consider using Math::Complex_C::L instead, and if
   your nvtype is '__float128' consider using Math::Complex_C::Q.
   Irrespective of the nvtype, you can still use this module - it's just
   that there are a number of functions returning 'double' - which, for 'long
   double' and '__float128' builds do not utilise the full precision that the
   'long double' or '__float128' NV provides.
   OTOH, you *can* use Math::Complex_C::L and/or Math::Complex_C::Q (making
   full use of the extra precision their operations provide) even if your
   nvtype is double - so long as your compiler supports the building of those
   modules. See the "Which Math::Complex_C" section of the README that ships
   with this module's source for a more detailed explanation.

   A number of the functions below accept string arguments. These arguments
   will be tested by the perl API function looks_like_number() for the
   presence of non-numeric characters. If any such non-numeric characters
   are detected, then the global non-numeric flag (which is initially set to
   0) will be incremented. You can query the value this global flag holds by
   running Math::Complex_C::nnumflag() and you can manually alter the value of
   the global using Math::Complex_C::set_nnum and Math::Complex_C::clear_nnum.
   These functions are documented below.

=head1 FUNCTIONS

   $rop = Math::Complex_C->new($re, $im);
   $rop = Math::Complex_C::new($re, $im);
   $rop = MCD($re, $im); # MCD is an alias to Math::Complex_C::new()
    $rop is a returned Math::Complex_C object; $re and $im are the real and
    imaginary values (respectively) that $rop holds. They (ie $re, $im) can be
    integer values (IV or UV), floating point values (NV) or numeric strings
    IV, UV, and NV values will be cast to double before being assigned.
    Strings (PV) will be assigned using C's strtod() function. Note that the
    two arguments ($re and $im) are optional - ie they can be omitted.
    If no arguments are supplied, then $rop will be assigned NaN for both the real
    and imaginary parts.
    If only one argument is supplied, and that argument is a Math::Complex_C
    object then $rop will be a duplicate of that Math::Complex_C object.
    Otherwise the single argument will be assigned to the real part of $rop, and
    the imaginary part will be set to zero.
    The functions croak if an invalid arg is supplied.

   $rop = create_c();
    $rop is a Math::Complex_C object, created with both real and imaginary
    values set to NaN. (Same result as calling new() without any args.)

   assign_c($rop, $re, $im);
    The real part of $rop is set to the value of $re, the imaginary part is set to
    the value of $im. $re and $im can be integers (IV or UV),  floating point
    values (NV) or strings (PV).

   set_real_c($rop, $re);
    The real part of $rop is set to the value of $re. $re can be an integer (IV or
    UV),  floating point value (NV) or a string (PV).

   set_imag_c($rop, $im);
    The imaginary part of $rop is set to the value of $re. $re can be an integer
    (IV or UV),  floating point value (NV) or a string (PV).

   mul_c   ($rop, $op1, $op2);
   mul_c_iv($rop, $op1, $si);
   mul_c_uv($rop, $op1, $ui);
   mul_c_nv($rop, $op1, $nv);
   mul_c_pv($rop, $op1, $pv);
    Multiply $op1 by the 3rd arg, and store the result in $rop.
    The "3rd arg" is (respectively, from top) a Math::Complex_C object,
    a signed integer value (IV), an unsigned integer value (UV), a floating point
    value (NV), a numeric string (PV). The UV, IV, NV and PV values are real only -
    ie no imaginary component. The PV will be set to a long double value using C's
    strtod() function. The UV, IV and NV values will be cast to long double
    values.

   add_c   ($rop, $op1, $op2);
   add_c_iv($rop, $op1, $si);
   add_c_uv($rop, $op1, $ui);
   add_c_nv($rop, $op1, $nv);
   add_c_pv($rop, $op1, $pv);
    As for mul_c(), etc., but performs addition.

   div_c   ($rop, $op1, $op2);
   div_c_iv($rop, $op1, $si);
   div_c_uv($rop, $op1, $ui);
   div_c_nv($rop, $op1, $nv);
   div_c_pv($rop, $op1, $pv);
    As for mul_c(), etc., but performs division.

   sub_c   ($rop, $op1, $op2);
   sub_c_iv($rop, $op1, $si);
   sub_c_uv($rop, $op1, $ui);
   sub_c_nv($rop, $op1, $nv);
   sub_c_pv($rop, $op1, $pv);
    As for mul_c(), etc., but performs subtraction.

   $nv = real_c($op);
    Returns the real part of $op as a (double precision) NV.
    Wraps C's 'creal' function.

   $nv = imag_c($op);
    Returns the imaginary part of $op as a (double precision) NV.

   $nv = arg_c($op);
    Returns the argument of $op as a (double precision) NV.
    Wraps C's 'carg' function.

   $nv = abs_c($op);
    Returns the absolute value of $op as a (double precision) NV.
    Wraps C's 'cabs' function.

   conj_c($rop, $op);
    Sets $rop to the conjugate of $op.
    Wraps C's 'conj' function.

   acos_c($rop, $op);
    Sets $rop to acos($op). Wraps C's 'cacos' function.

   asin_c($rop, $op);
    Sets $rop to asin($op). Wraps C's 'casin' function.

   atan_c($rop, $op);
    Sets $rop to atan($op). Wraps C's 'catan' function.

   cos_c($rop, $op);
    Sets $rop to cos($op). Wraps C's 'ccos' function.

   sin_c($rop, $op);
    Sets $rop to sin($op). Wraps C's 'csin' function.

   tan_c($rop, $op);
    Sets $rop to tan($op). Wraps C's 'ctan' function.

   acosh_c($rop, $op);
    Sets $rop to acosh($op). Wraps C's 'cacosh' function.

   asinh_c($rop, $op);
    Sets $rop to asinh($op). Wraps C's 'casinh' function.

   atanh_c($rop, $op);
    Sets $rop to atanh($op). Wraps C's 'catanh' function.

   cosh_c($rop, $op);
    Sets $rop to cosh($op). Wraps C's 'ccosh' function.

   sinh_c($rop, $op);
    Sets $rop to sinh($op). Wraps C's 'csinh' function.

   tanh_c($rop, $op);
    Sets $rop to tanh($op). Wraps C's 'ctanh' function.

   exp_c($rop, $op);
    Sets $rop to e ** $op. Wraps C's 'cexp' function.

   log_c($rop, $op);
    Sets $rop to log($op). Wraps C's 'clog' function.

   pow_c($rop, $op1, $op2);
    Sets $rop to $op1 ** $op2. Wraps C's 'cpow' function.

   sqrt_c($rop, $op);
    Sets $rop to sqrt($op). Wraps C's 'csqrt' function.

   proj_c($rop, $op);
    Sets $rop to a projection of $op onto the Riemann sphere.
    Wraps C's 'cproj' function.

   $nv = get_nan();
    Sets $nv to NaN.

   $nv = get_inf();
    Sets $nv to Inf.

   $bool = is_nan($nv);
    Returns true if $nv is a NaN - else returns false

   $bool = is_inf($nv);
    Returns true if $nv is -Inf or +Inf - else returns false


=head1 OUTPUT FUNCTIONS

   Default precision for output of Math::Complex_C objects is whatever is
   17 decimal digits.

   This default can be altered using d_set_prec (see below).

   d_set_prec($si);
   $si = d_get_prec();
    Set/get the precision (decimal digits) of output values

   $str = d_to_str($op);
    Return a string of the form "real imag".
    Both "real" and "imag" will be expressed in scientific
    notation, to the precision returned by the d_get_prec() function (above).
    Use d_set_prec() to alter this precision.
    Infinities are stringified to 'inf' (or '-inf' for -ve infinity).
    NaN values (including positive and negative NaN vlaues) are stringified to
    'nan'.

   $str = d_to_strp($op, $si);
    As for d_to_str, except that the precision setting for the output value
    is set by the 2nd arg (which must be greater than 1).

   $rop = str_to_d($str);
    Takes a string as per that returned by d_to_str() or d_to_strp().
    Returns a Math::Complex_C object set to the value represented by that
    string.


=head1 OPERATOR OVERLOADING

   Math::Complex_C overloads the following operators:
    *, +, /, -, **,
    *=, +=, /=, -=, **=,
    !, bool,
    ==, !=,
    "",
    abs, exp, log, cos, sin, atan2, sqrt,
    =

    NOTE: Making use of the '=' overloading is not recommended unless
          you understand its caveats. See 'perldoc overload' and
          read it thoroughly, including the documentation regarding
          'copy constructors'.

    Note: abs() returns a (double precision) NV, not a Math::Complex_C object.

    Overloaded arithmetic operations are provided the following types:
     IV, UV, NV, PV, Math::Complex_C object.
    The IV, UV, NV and PV values are real only (ie no imaginary
    component). The PV values will be converted to double values
    using C's strtod() function. The IV, UV and NV values will be
    cast to double precision values.

    Note: For the purposes of the overloaded 'not', '!' and 'bool'
    operators, a "false" Math::Complex_C object is one with real
    and imaginary parts that are both "false" - where "false"
    currently means either 0 (including -0) or NaN.
    (A "true" Math::Complex_C object is, of course, simply one
    that is not "false".)

=head1 OTHER FUNCTIONS

    $iv = Math::Complex_C::nnumflag(); # not exported
     Returns the value of the non-numeric flag. This flag is
     initialized to zero, but incemented by 1 whenever a function
     is handed a string containing non-numeric characters. The
     value of the flag therefore tells us how many times functions
     have been handed such a string. The flag can be reset to 0 by
     running clear_nnum().

    Math::Complex_C::set_nnum($iv); # not exported
     Resets the global non-numeric flag to the value specified by
     $iv.

    Math::Complex_C::clear_nnum(); # not exported
     Resets the global non-numeric flag to 0.(Essentially the same
     as running set_nnum(0).)

=head1 LICENSE

   This module is free software; you may redistribute it and/or modify it under
   the same terms as Perl itself.
   Copyright 2014, 2016 Sisyphus.

=head1 AUTHOR

   Sisyphus <sisyphus at(@) cpan dot (.) org>

=cut
