use strict;
use warnings;
package Math::Complex_C::Q;

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

our $VERSION = '0.06';

DynaLoader::bootstrap Math::Complex_C::Q $VERSION;

@Math::Complex_C::Q::EXPORT = ();
@Math::Complex_C::Q::EXPORT_OK = qw(

    create_cq assign_cq mul_cq mul_c_nvq mul_c_ivq mul_c_uvq div_cq div_c_nvq div_c_ivq div_c_uvq add_cq
    add_c_nvq add_c_ivq add_c_uvq sub_cq sub_c_nvq sub_c_ivq sub_c_uvq real_cq real_cq2F imag_cq2F F2cq
    cq2F real_cq2str imag_cq2str arg_cq2F arg_cq2str abs_cq2F abs_cq2str
    imag_cq arg_cq abs_cq conj_cq acos_cq asin_cq atan_cq cos_cq sin_cq tan_cq acosh_cq asinh_cq atanh_cq
    cosh_cq sinh_cq tanh_cq exp_cq log_cq sqrt_cq proj_cq pow_cq
    get_nanq get_neg_infq get_infq is_nanq is_infq MCQ
    add_c_pvq sub_c_pvq mul_c_pvq div_c_pvq

    str_to_q q_to_str q_to_strp q_set_prec q_get_prec set_real_cq set_imag_cq
    );

%Math::Complex_C::Q::EXPORT_TAGS = (all => [qw(

    create_cq assign_cq mul_cq mul_c_nvq mul_c_ivq mul_c_uvq div_cq div_c_nvq div_c_ivq div_c_uvq add_cq
    add_c_nvq add_c_ivq add_c_uvq sub_cq sub_c_nvq sub_c_ivq sub_c_uvq real_cq real_cq2F imag_cq2F F2cq
    cq2F real_cq2str imag_cq2str arg_cq2F arg_cq2str abs_cq2F abs_cq2str
    imag_cq arg_cq abs_cq conj_cq acos_cq asin_cq atan_cq cos_cq sin_cq tan_cq acosh_cq asinh_cq atanh_cq
    cosh_cq sinh_cq tanh_cq exp_cq log_cq sqrt_cq proj_cq pow_cq
    get_nanq get_infq get_neg_infq is_nanq is_infq MCQ
    add_c_pvq sub_c_pvq mul_c_pvq div_c_pvq

    str_to_q q_to_str q_to_strp q_set_prec q_get_prec set_real_cq set_imag_cq
    )]);

sub dl_load_flags {0} # Prevent DynaLoader from complaining and croaking

sub q_to_str {
    return join ' ', _q_to_str($_[0]);
}

sub q_to_strp {
    return join ' ', _q_to_strp($_[0], $_[1]);
}

sub str_to_q {
    my($re, $im) = split /\s+/, $_[0];
    $im = 0 if !defined($im);

    $re = get_nanq() if $re =~ /^(\+|\-)?nan/i;
    $im = get_nanq() if $im =~ /^(\+|\-)?nan/i;

    if($re =~ /^(\+|\-)?inf/i) {
      if($re =~ /^\-inf/i) {$re = get_neg_infq()}
      else {$re = get_infq()}
    }

    if($im =~ /^(\+|\-)?inf/i) {
      if($re =~ /^\-inf/i) {$im = get_neg_infq()}
      else {$im = get_infq()}
    }

    return MCQ($re, $im);
}

sub _overload_string {
    my($real, $imag) = (real_cq($_[0]), imag_cq($_[0]));
    my($r, $i) = _q_to_str($_[0]);

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
    # Math::Complex_C::Q object

    if(!@_) {return create_cq()}

    if(@_ > 3) {die "Too many arguments supplied to new()"}

    # If 'new' has been called OOP style, the first arg is the string
    # "Math::Complex_C::Q" which we don't need - so let's remove it.

    if(!ref($_[0]) && $_[0] eq "Math::Complex_C::Q") {
      shift;
      if(!@_) {return create_cq()}
    }

    if(@_ > 2) {die "Bad argument list supplied to new()"}

    my $ret;

    if(@_ == 2) {
      $ret = create_cq();
      assign_cq($ret, $_[0], $_[1]);
    }
    else {
      return $_[0] if _itsa($_[0]) == 226;
      $ret = create_cq();
      assign_cq($ret, $_[0], 0.0);
    }

    return $ret;
}

*MCQ = \&Math::Complex_C::Q::new;

1;

__END__

=head1 NAME

Math::Complex_C::Q - perl interface to C's __complex128 (quadmath) operations.

=head1 DEPENDENCIES

   In order to compile this module, the quadmath library is needed.

=head1 DESCRIPTION

   use warnings;
   use strict;
   use Math::Complex_C::Q qw(:all);
   # For brevity, use MCQ which is an alias for Math::Complex_C::Q::new
   my $c =    MCQ(12.5, 1125); # assign as NV
   my $root = MCQ();

   sqrt_cq($root, $c);
   print "Square root of $c is $root\n";

   See also the Math::Complex_C::Q test suite for some (simplistic) examples
   of usage.

   This module is written largely for the use of perl builds whose nvtype is
   '__float128'. Run "perl -V:nvtype" to see what your perl's NV type is. If
   your nvtype is not '__float128' you can still use this module  and utilise
   the extra precision it provides. See the "Which Math::Complex_C" section
   of the README that ships with this module's source for a more detailed
   explanation.
   You can also install Math::Complex_C and/or Math::Complex_C::L if this
   module won't build for you or you prefer to work with less precision.

   A number of the functions below accept string arguments. These arguments
   will be tested by the perl API function looks_like_number() for the
   presence of non-numeric characters. If any such non-numeric characters
   are detected, then the global non-numeric flag (which is initially set to
   0) will be incremented. You can query the value this global flag holds by
   running Math::Complex_C::Q::nnumflag() and you can manually alter the
   value of the global using Math::Complex_C::Q::set_nnum and
   Math::Complex_C::Q::clear_nnum. These functions are documented below.

=head1 FUNCTIONS

   $rop = Math::Complex_C::Q->new($re, $im);
   $rop = Math::Complex_C::Q::new($re, $im);
   $rop = MCQ($re, $im); # MCQ is an alias to Math::Complex_C::Q::new()
    $rop is a returned Math::Complex_C::Q object; $re and $im are the real and
    imaginary values (respectively) that $rop holds. They (ie $re, $im) can be
    integer values (IV or UV), floating point values (NV), numeric strings
    or Math::Float128 objects.IV, UV and NV values will be cast to __float128
    values before being assigned. Strings (PV) will be assigned using C's
    strtoflt128() function.
    Note that the two arguments ($re & $im) are optional - ie they can be omitted.
    If no arguments are supplied, then $rop will be assigned NaN for both the real
    and imaginary parts.
    If only one argument is supplied, and that argument is a Math::Complex_C::Q
    object then $rop will be a duplicate of that Math::Complex_C::Q object.
    Otherwise the single argument will be assigned to the real part of $rop, and
    the imaginary part will be set to zero.
    The functions croak if an invalid arg is supplied.

   $rop = create_cq();
    $rop is a Math::Complex_C::Q object, created with both real and imaginary
    values set to NaN. (Same result as calling new() without any args.)

   assign_cq($rop, $re, $im);
    The real part of $rop is set to the value of $re, the imaginary part is set to
    the value of $im. $re and $im can be  integers (IV or UV),  floating point
    values (NV), numeric strings, or Math::Float128 objects .

   set_real_cq($rop, $re);
    The real part of $rop is set to the value of $re. $re can be an integer (IV or
    UV),  floating point value (NV), numeric string, or Math::Float128 object.

   set_imag_cq($rop, $im);
    The imaginary part of $rop is set to the value of $im. $im can be an integer
    (IV/UV),  floating point value (NV), numeric string, or Math::Float128 object.

   F2cq($rop, $r_f, $i_f); #$r_f & $i_f are Math::Float128 objects
    Assign the real and imaginary part of $rop from the Math::Float128 objects $r_f
    and $i_f (respectively).

   cq2F($r_f, $f_i, $op); #$r_f & $i_f are Math::Float128 objects
    Assign the real and imaginary parts of $op to the Math::Float128 objects $r_f
    and $i_f (respectively).

   mul_cq   ($rop, $op1, $op2);
   mul_cq_iv($rop, $op1, $si);
   mul_cq_uv($rop, $op1, $ui);
   mul_cq_nv($rop, $op1, $nv);
   mul_cq_pv($rop, $op1, $pv);
    Multiply $op1 by the 3rd arg, and store the result in $rop.
    The "3rd arg" is (respectively, from top) a Math::Complex_C::Q object,
    a signed integer value (IV), an unsigned integer value (UV), a floating point
    value (NV), a numeric string (PV). The UV, IV, NV and PV values are real only -
    ie no imaginary component. The PV will be set to a __float128 value using C's
    strtoflt128() function. The UV, IV and NV values will be cast to __float128
    values.

   add_cq   ($rop, $op1, $op2);
   add_cq_iv($rop, $op1, $si);
   add_cq_uv($rop, $op1, $ui);
   add_cq_nv($rop, $op1, $nv);
   add_cq_pv($rop, $op1, $pv);
    As for mul_cq(), etc., but performs addition.

   div_cq   ($rop, $op1, $op2);
   div_cq_iv($rop, $op1, $si);
   div_cq_uv($rop, $op1, $ui);
   div_cq_nv($rop, $op1, $nv);
   div_cq_pv($rop, $op1, $pv);
    As for mul_cq(), etc., but performs division.

   sub_cq   ($rop, $op1, $op2);
   sub_cq_iv($rop, $op1, $si);
   sub_cq_uv($rop, $op1, $ui);
   sub_cq_nv($rop, $op1, $nv);
   sub_cq_pv($rop, $op1, $pv);
    As for mul_cq(), etc., but performs subtraction.

   $nv = real_cq($op);
    Returns the real part of $op as an NV. If your perl's NV is not __float128
    use either real_cq2F($op) or (q_to_str($op))[1].
    Wraps C's 'crealq' function.

   $nv = imag_cq($op);
    Returns the imaginary part of $op as an NV. If your perl's NV is not
    __float128 use either real_cq2F($op) or (q_to_str($op))[1].
    Wraps C's 'cimagq' function.

   $f = real_cq2F($op);
   $f = imag_cq2F($op);
    Returns a Math::Float128 object $f set to the value of $op's real (and
    respectively, imag) component. No point in using this function unless
    Math::Float128 is loaded.
    Wraps 'crealq' and 'cimagq' to obtain the values.

   $str = real_cq2str($op);
   $str = imag_cq2str($op);
    Returns a string set to the value of $op's real (and respectively, imag)
    component.
    Wraps 'crealq' and 'cimagq' to obtain the values.

   $nv = arg_cq($op);
    Returns the argument of $op as an NV.If your perl's NV is not
    __float128 use either arg_cq2F() or arg_cq2str().
    Wraps C's 'cargq' function.

   $f = arg_cq2F($op);
    Returns the Math::Float128 object $f, set to the value of the argument
    of $op. No point in using this function unless Math::Float128 is loaded.
    Wraps C's 'cargq' function.

   $str = arg_cq2str($op);
    Returns the string $str, set to the value of the argument of $op. No
    point in using this function unless Math::Float128 is loaded.
    Wraps C's 'cargq' function.

   $nv = abs_cq($op);
    Returns the absolute value of $op as an NV.If your perl's NV is not
    __float128 use either arg_cq2F() or arg_cq2str().
    Wraps C's 'cabsq' function.

   $f = abs_cq2F($op);
    Returns the Math::Float128 object $f, set to the absolute value of $op.
    No point in using this function unless Math::Float128 is loaded.
    Wraps C's 'cabsq' function.

   $str = abs_cq2str($op);
    Returns the string $str, set to the absolute value of $op. No point
    in using this function unless Math::Float128 is loaded.
    Wraps C's 'cabsq' function.

   conj_cq($rop, $op);
    Sets $rop to the conjugate of $op.
    Wraps C's 'conjq' function.

   acos_cq($rop, $op);
    Sets $rop to acos($op). Wraps C's 'cacosq' function.

   asin_cq($rop, $op);
    Sets $rop to asin($op). Wraps C's 'casinq' function.

   atan_cq($rop, $op);
    Sets $rop to atan($op). Wraps C's 'catanq' function.

   cos_cq($rop, $op);
    Sets $rop to cos($op). Wraps C's 'ccosq' function.
    Not presently implemented with mingw-64 compilers - crashes perl.

   sin_cq($rop, $op);
    Sets $rop to sin($op). Wraps C's 'csinq' function.
    Not presently implemented with mingw-64 compilers - crashes perl.

   tan_cq($rop, $op);
    Sets $rop to tan($op). Wraps C's 'ctanq' function.
    Not presently implemented with mingw-64 compilers - crashes perl.
    Implemented as sin divided by cos in those situations where the
    Makefile.PL's investigations have indicated that the bug is
    present. Math::Complex_C::Q::_gcc_tan_bug() returns true iff the
    workaround has been implemented.

   acosh_cq($rop, $op);
    Sets $rop to acosh($op). Wraps C's 'cacoshq' function.

   asinh_cq($rop, $op);
    Sets $rop to asinh($op). Wraps C's 'casinhq' function.

   atanh_cq($rop, $op);
    Sets $rop to atanh($op). Wraps C's 'catanhq' function.

   cosh_cq($rop, $op);
    Sets $rop to cosh($op). Wraps C's 'ccoshq' function.
    Not presently implemented with mingw-64 compilers - crashes perl.

   sinh_cq($rop, $op);
    Sets $rop to sinh($op). Wraps C's 'csinhq' function.
    Not presently implemented with mingw-64 compilers - crashes perl.

   tanh_cq($rop, $op);
    Sets $rop to tanh($op). Wraps C's 'ctanhq' function.
    Not presently implemented with mingw-64 compilers - crashes perl.
    Implemented as sinh divided by cosh in those situations where the
    Makefile.PL's investigations have indicated that the bug is
    present. Math::Complex_C::Q::_gcc_tan_bug() returns true iff the
    workaround has been implemented.

   exp_cq($rop, $op);
    Sets $rop to e ** $op. Wraps C's 'cexpq' function.
    Not presently implemented with mingw-64 compilers - crashes perl.

   log_cq($rop, $op);
    Sets $rop to log($op). Wraps C's 'clogq' function.
    Not presently implemented with mingw-64 compilers - crashes perl.

   pow_cq($rop, $op1, $op2);
    Sets $rop to $op1 ** $op2. Wraps C's 'cpowq' function.
    Not presently implemented with mingw-64 compilers - crashes perl.

   sqrt_cq($rop, $op);
    Sets $rop to sqrt($op). Wraps C's 'csqrtq' function.

   proj_cq($rop, $op);
    Sets $rop to a projection of $op onto the Riemann sphere.
    Wraps C's 'cprojq' function.

   $nv = get_nanq();
    Sets $nv to NaN.

   $nv = get_infq();
    Sets $nv to Inf.

   $bool = is_nanq($nv);
    Returns true if $nv is a NaN - else returns false

   $bool = is_infq($nv);
    Returns true if $nv is -Inf or +Inf - else returns false


=head1 OUTPUT FUNCTIONS

   Default precision for output of Math::Complex_C::Q objects is 33
   decimal digits.

   This default can be altered using q_set_prec (see below).

   q_set_prec($si);
   $si = q_get_prec();
    Set/get the precision of output values

   $str = q_to_str($op);
    Return a string of the form "real imag".
    Both "real" and "imag" will be expressed in scientific
    notation, to the precision returned by the q_get_prec() function (above).
    Use q_set_prec() to alter this precision.
    Infinities are stringified to 'inf' (or '-inf' for -ve infinity).
    NaN values (including positive and negative NaN vlaues) are stringified to
    'nan'.

   $str = q_to_strp($op, $si);
    As for q_to_str, except that the precision setting for the output value
    is set by the 2nd arg (which must be greater than 1).

   $rop = str_to_q($str);
    Takes a string as per that returned by q_to_str() or q_to_strp().
    Returns a Math::Complex_C::Q object set to the value represented by that
    string.

   cq2F($f_r, $f_i, $op);
    Assign the real part of $op to the Math::Float128 object $f_r, and the
    imaginary part of $op to the Math::Float128 object $f_i.


=head1 OPERATOR OVERLOADING

   Math::Complex_C::Q overloads the following operators:
    *, +, /, -, **,
    *=, +=, /=, -=, **=,
    !, bool,
    ==, !=,
    =, "",
    abs, exp, log, cos, sin, atan2, sqrt

    Note: abs() returns an NV, not a Math::Complex_C::Q object. If your NV-type
    is not __float128 then you should probably call abs_cq2F() or abs_cq2str()
    instead. Check the documentation (above) of those two alternatives.

    Note: With mingw-w64 compilers exp, log, sin, cos, ** and **= overloading
    is not provided because calling the underlying C functions crashes perl.

    Overloaded arithmetic operations are provided the following types:
     IV, UV, NV, PV, Math::Complex_C::Q object.
    The IV, UV, NV and PV values are real only (ie no imaginary component). The
    PV values will be converted to __float128 values using C's strtoflt128()
    function. The IV, UV and NV values will be cast to __float128 values.

    Note: For the purposes of the overloaded 'not', '!' and 'bool'
    operators, a "false" Math::Complex_C object is one with real
    and imaginary parts that are both "false" - where "false"
    currently means either 0 (including -0) or NaN.
    (A "true" Math::Complex_C object is, of course, simply one
    that is not "false".)

=head1 OTHER FUNCTIONS

    $iv = Math::Complex_C::Q::nnumflag(); # not exported
     Returns the value of the non-numeric flag. This flag is
     initialized to zero, but incemented by 1 whenever a function
     is handed a string containing non-numeric characters. The
     value of the flag therefore tells us how many times functions
     have been handed such a string. The flag can be reset to 0 by
     running clear_nnum().

    Math::Complex_C::Q::set_nnum($iv); # not exported
     Resets the global non-numeric flag to the value specified by
     $iv.

    Math::Complex_C::Q::clear_nnum(); # not exported
     Resets the global non-numeric flag to 0.(Essentially the same
     as running set_nnum(0).)

=head1 LICENSE

   This module is free software; you may redistribute it and/or
   modify it under the same terms as Perl itself.
   Copyright 2014-16, Sisyphus.

=head1 AUTHOR

   Sisyphus <sisyphus at(@) cpan dot (.) org>

=cut
