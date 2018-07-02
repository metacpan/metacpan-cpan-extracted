use strict;
use warnings;
package Math::Complex_C::L;

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

DynaLoader::bootstrap Math::Complex_C::L $VERSION;

@Math::Complex_C::L::EXPORT = ();
@Math::Complex_C::L::EXPORT_OK = qw(

    create_cl assign_cl mul_cl mul_c_nvl mul_c_ivl mul_c_uvl div_cl div_c_nvl div_c_ivl div_c_uvl add_cl
    add_c_nvl add_c_ivl add_c_uvl sub_cl sub_c_nvl sub_c_ivl sub_c_uvl real_cl real_cl2LD imag_cl2LD
    LD2cl cl2LD real_cl2str imag_cl2str arg_cl2LD arg_cl2str abs_cl2LD abs_cl2str
    imag_cl arg_cl abs_cl conj_cl acos_cl asin_cl atan_cl cos_cl sin_cl tan_cl acosh_cl asinh_cl atanh_cl
    cosh_cl sinh_cl tanh_cl exp_cl log_cl sqrt_cl proj_cl pow_cl
    get_nanl get_neg_infl get_infl is_nanl is_infl MCL
    add_c_pvl sub_c_pvl mul_c_pvl div_c_pvl

    str_to_l l_to_str l_to_strp l_set_prec l_get_prec set_real_cl set_imag_cl
    ld_to_str ld_to_strp long_set_prec long_get_prec
    );

%Math::Complex_C::L::EXPORT_TAGS = (all => [qw(

    create_cl assign_cl mul_cl mul_c_nvl mul_c_ivl mul_c_uvl div_cl div_c_nvl div_c_ivl div_c_uvl add_cl
    add_c_nvl add_c_ivl add_c_uvl sub_cl sub_c_nvl sub_c_ivl sub_c_uvl real_cl real_cl2LD imag_cl2LD
    LD2cl cl2LD real_cl2str imag_cl2str arg_cl2LD arg_cl2str abs_cl2LD abs_cl2str
    imag_cl arg_cl abs_cl conj_cl acos_cl asin_cl atan_cl cos_cl sin_cl tan_cl acosh_cl asinh_cl atanh_cl
    cosh_cl sinh_cl tanh_cl exp_cl log_cl sqrt_cl proj_cl pow_cl
    get_nanl get_neg_infl get_infl is_nanl is_infl MCL
    add_c_pvl sub_c_pvl mul_c_pvl div_c_pvl

    str_to_l l_to_str l_to_strp l_set_prec l_get_prec set_real_cl set_imag_cl
    ld_to_str ld_to_strp long_set_prec long_get_prec
    )]);

sub dl_load_flags {0} # Prevent DynaLoader from complaining and croaking

sub l_to_str {
    return join ' ', _l_to_str($_[0]);
}

sub l_to_strp {
    return join ' ', _l_to_strp($_[0], $_[1]);
}

sub str_to_l {
    my($re, $im) = split /\s+/, $_[0];
    $im = 0 if !defined($im);

    $re = get_nanl() if $re =~ /^(\+|\-)?nan/i;
    $im = get_nanl() if $im =~ /^(\+|\-)?nan/i;

    if($re =~ /^(\+|\-)?inf/i) {
      if($re =~ /^\-inf/i) {$re = get_neg_infl()}
      else {$re = get_infl()}
    }

    if($im =~ /^(\+|\-)?inf/i) {
      if($re =~ /^\-inf/i) {$im = get_neg_infl()}
      else {$im = get_infl()}
    }

    return MCL($re, $im);
}

sub _overload_string {
    my($real, $imag) = (real_cl($_[0]), imag_cl($_[0]));
    my($r, $i) = _l_to_str($_[0]);

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
    # Math::Complex_C::L object

    if(!@_) {return create_cl()}

    if(@_ > 3) {die "Too many arguments supplied to new()"}

    # If 'new' has been called OOP style, the first arg is the string
    # "Math::Complex_C::L" which we don't need - so let's remove it.

    if(!ref($_[0]) && $_[0] eq "Math::Complex_C::L") {
      shift;
      if(!@_) {return create_cl()}
    }

    if(@_ > 2) {die "Bad argument list supplied to new()"}

    my $ret;

    if(@_ == 2) {
      $ret = create_cl();
      assign_cl($ret, $_[0], $_[1]);
    }
    else {
      return $_[0] if _itsa($_[0]) == 226;
      $ret = create_cl();
      assign_cl($ret, $_[0], 0.0);
    }

    return $ret;
}

*MCL		= \&Math::Complex_C::L::new;
*long_get_prec	= \&l_get_prec; # for backwards-compatibility
*long_set_prec	= \&l_set_prec; # for backwards-compatibility
*ld_to_str	= \&l_to_str;	# for backwards-compatibility
*ld_to_strp	= \&l_to_strp;	# for backwards-compatibility

1;

__END__

=head1 NAME

Math::Complex_C::L - perl interface to C's long double complex operations.


=head1 DESCRIPTION

   use warnings;
   use strict;
   use Math::Complex_C::L qw(:all);
   # For brevity, use MCL which is an alias for Math::Complex_C::L::new
   my $c =    MCL(12.5, 1125); # assign as NV
   my $root = MCL();

   sqrt_cl($root, $c);
   print "Square root of $c is $root\n";

   See also the Math::Complex_C::L test suite for some (simplistic) examples
   of usage.

   This module is written largely for the use of perl builds whose nvtype is
   'long double'. Run "perl -V:nvtype" to see what your perl's NV type is. If
   your nvtype is 'double' consider using Math::Complex_C instead, and if
   your nvtype is '__float128' consider using Math::Complex_C::Q.
   Irrespective of the nvtype, you can still use this module - it's just
   that there are a number of functions returning 'long double' - which, for
   'double' and '__float128' builds do not utilise the full precision that the
   'long double' or '__float128' NV provides.
   OTOH, you *can* use Math::Complex_C - or, if your compiler supports it, use
   Math::Complex_C::Q (and make full use of the extra precision its operations
   provide) irrespective of your nvtype. See the "Which Math::Complex_C"
   section of the README that ships with this module's source for a more
   detailed explanation.

   A number of the functions below accept string arguments. These arguments
   will be tested by the perl API function looks_like_number() for the
   presence of non-numeric characters. If any such non-numeric characters
   are detected, then the global non-numeric flag (which is initially set to
   0) will be incremented. You can query the value this global flag holds by
   running Math::Complex_C::L::nnumflag() and you can manually alter the
   value of the global using Math::Complex_C::L::set_nnum and
   Math::Complex_C::L::clear_nnum. These functions are documented below.

=head1 FUNCTIONS

   $rop = Math::Complex_C::L->new($re, $im);
   $rop = Math::Complex_C::L::new($re, $im);
   $rop = MCL($re, $im); # MCL is an alias to Math::Complex_C::L::new()
    $rop is a returned Math::Complex_C::L object; $re and $im are the real and
    imaginary values (respectively) that $rop holds. They (ie $re, $im) can be
    integer values (IV or UV), floating point values (NV), numeric strings
    or Math::LongDouble objects. IV, UV and NV values will be cast to long
    long double before being assigned. Strings (PV) will be assigned using C's
    strtold() function.
    Note that the two arguments ($re & $im) are optional - ie they can be omitted.
    If no arguments are supplied, then $rop will be assigned NaN for both the real
    and imaginary parts.
    If only one argument is supplied, and that argument is a Math::Complex_C::L
    object then $rop will be a duplicate of that Math::Complex_C::L object.
    Otherwise the single argument will be assigned to the real part of $rop, and
    the imaginary part will be set to zero.
    The functions croak if an invalid arg is supplied.

   $rop = create_cl();
    $rop is a Math::Complex_C::L object, created with both real and imaginary
    values set to NaN. (Same result as calling new() without any args.)

   assign_cl($rop, $re, $im);
    The real part of $rop is set to the value of $re, the imaginary part is set to
    the value of $im. $re and $im can be  integers (IV or UV),  floating point
    values (NV), numeric strings, or Math::LongDouble objects .

   set_real_cl($rop, $re);
    The real part of $rop is set to the value of $re. $re can be an integer (IV or
    UV),  floating point value (NV), numeric string, or Math::LongDouble object.

   set_imag_cl($rop, $im);
    The imaginary part of $rop is set to the value of $im. $im can be an integer
    (IV/UV),  floating point value (NV), numeric string, or Math::LongDouble object.

   LD2cl($rop, $r_f, $i_f); #$r_f & $i_f are Math::LongDouble objects
    Assign the real and imaginary part of $rop from the Math::LongDouble objects $r_f
    and $i_f (respectively).

   cl2LD($r_f, $f_i, $op); #$r_f & $i_f are Math::LongDouble objects
    Assign the real and imaginary parts of $op to the Math::LongDouble objects $r_f
    and $i_f (respectively).

   mul_cl   ($rop, $op1, $op2);
   mul_c_ivl($rop, $op1, $si);
   mul_c_uvl($rop, $op1, $ui);
   mul_c_nvl($rop, $op1, $nv);
   mul_c_pvl($rop, $op1, $pv);
    Multiply $op1 by the 3rd arg, and store the result in $rop.
    The "3rd arg" is (respectively, from top) a Math::Complex_C::L object,
    a signed integer value (IV), an unsigned integer value (UV), a floating point
    value (NV), a numeric string (PV). The UV, IV, NV and PV values are real only -
    ie no imaginary component. The PV will be set to a long double value using C's
    strtold() function. The UV, IV and NV values will be cast to long double
    values.

   add_cl   ($rop, $op1, $op2);
   add_c_ivl($rop, $op1, $si);
   add_c_uvl($rop, $op1, $ui);
   add_c_nvl($rop, $op1, $nv);
   add_c_pvl($rop, $op1, $pv);
    As for mul_cl(), etc., but performs addition.

   div_cl   ($rop, $op1, $op2);
   div_c_ivl($rop, $op1, $si);
   div_c_uvl($rop, $op1, $ui);
   div_c_nvl($rop, $op1, $nv);
   div_c_pvl($rop, $op1, $pv);
    As for mul_cl(), etc., but performs division.

   sub_cl   ($rop, $op1, $op2);
   sub_c_ivl($rop, $op1, $si);
   sub_c_uvl($rop, $op1, $ui);
   sub_c_nvl($rop, $op1, $nv);
   sub_c_pvl($rop, $op1, $pv);
    As for mul_cl(), etc., but performs subtraction.

   $nv = real_cl($op);
    Returns the real part of $op as an NV. If your perl's NV is not long
    double use either real_cl2LD($op) or (l_to_str($op))[1].
    Wraps C's 'creall' function.

   $nv = imag_cl($op);
    Returns the imaginary part of $op as an NV. If your perl's NV is not
    long double use either real_cl2LD($op) or (l_to_str($op))[1].
    Wraps C's 'cimagl' function.

   $f = real_cl2LD($op);
   $f = imag_cl2LD($op);
    Returns a Math::LongDouble object $f set to the value of $op's real (and
    respectively, imag) component. No point in using this function unless
    Math::LongDouble is loaded.
    Wraps 'creall' and 'cimagl' to obtain the values.

   $str = real_cl2str($op);
   $str = imag_cl2str($op);
    Returns a string set to the value of $op's real (and respectively, imag)
    component.
    Wraps 'creall' and 'cimagl' to obtain the values.

   $nv = arg_cl($op);
    Returns the argument of $op as an NV.If your perl's NV is not
    long double use either arg_cl2LD() or arg_cl2str().
    Wraps C's 'cargl' function.

   $f = arg_cl2LD($op);
    Returns the Math::LongDouble object $f, set to the value of the argument
    of $op. No point in using this function unless Math::LongDouble is loaded.
    Wraps C's 'cargl' function.

   $str = arg_cl2str($op);
    Returns the string $str, set to the value of the argument of $op. No
    point in using this function unless Math::LongDouble is loaded.
    Wraps C's 'cargl' function.

   $nv = abs_cl($op);
    Returns the absolute value of $op as an NV.If your perl's NV is not
    long double use either arg_cl2LD() or arg_cl2str().
    Wraps C's 'cabsl' function.

   $f = abs_cl2LD($op);
    Returns the Math::LongDouble object $f, set to the absolute value of $op.
    No point in using this function unless Math::LongDouble is loaded.
    Wraps C's 'cabsl' function.

   $str = abs_cl2str($op);
    Returns the string $str, set to the absolute value of $op. No point
    in using this function unless Math::LongDouble is loaded.
    Wraps C's 'cabsl' function.

   conj_cl($rop, $op);
    Sets $rop to the conjugate of $op.
    Wraps C's 'conjl' function.

   acos_cl($rop, $op);
    Sets $rop to acos($op). Wraps C's 'cacosl' function.

   asin_cl($rop, $op);
    Sets $rop to asin($op). Wraps C's 'casinl' function.

   atan_cl($rop, $op);
    Sets $rop to atan($op). Wraps C's 'catanl' function.

   cos_cl($rop, $op);
    Sets $rop to cos($op). Wraps C's 'ccosl' function.

   sin_cl($rop, $op);
    Sets $rop to sin($op). Wraps C's 'csinl' function.

   tan_cl($rop, $op);
    Sets $rop to tan($op). Wraps C's 'ctanl' function.

   acosh_cl($rop, $op);
    Sets $rop to acosh($op). Wraps C's 'cacoshl' function.

   asinh_cl($rop, $op);
    Sets $rop to asinh($op). Wraps C's 'casinhl' function.

   atanh_cl($rop, $op);
    Sets $rop to atanh($op). Wraps C's 'catanhl' function.

   cosh_cl($rop, $op);
    Sets $rop to cosh($op). Wraps C's 'ccoshl' function.

   sinh_cl($rop, $op);
    Sets $rop to sinh($op). Wraps C's 'csinhl' function.

   tanh_cl($rop, $op);
    Sets $rop to tanh($op). Wraps C's 'ctanhl' function.

   exp_cl($rop, $op);
    Sets $rop to e ** $op. Wraps C's 'cexpl' function.

   log_cl($rop, $op);
    Sets $rop to log($op). Wraps C's 'clogl' function.

   pow_cl($rop, $op1, $op2);
    Sets $rop to $op1 ** $op2. Wraps C's 'cpowl' function.

   sqrt_cl($rop, $op);
    Sets $rop to sqrt($op). Wraps C's 'csqrtl' function.

   proj_cl($rop, $op);
    Sets $rop to a projection of $op onto the Riemann sphere.
    Wraps C's 'cprojl' function.

   $nv = get_nanl();
    Sets $nv to NaN.

   $nv = get_infl();
    Sets $nv to Inf.

   $bool = is_nanl($nv);
    Returns true if $nv is a NaN - else returns false

   $bool = is_infl($nv);
    Returns true if $nv is -Inf or +Inf - else returns false


=head1 OUTPUT FUNCTIONS

   Default precision for output of Math::Complex_C::L objects is set
   in the XS global _MATH_COMPLEX_C_L_DIGITS to
        1 + ceil(MANT_PREC * log(2) / log(10)
    where MANT_PREC is LDBL_MANT_DIG if float.h defines that symbol.
    Else MANT_PREC is DBL_MANT_DIG if float.h defines that symbol.
    Else MANT_PREC is 21 (which is the correct value for a 64-bit
    precision mantissa).

   This default can be altered using l_set_prec (see below).

   l_set_prec($si);
   $si = l_get_prec();
    Set/get the precision of output values

   $str = l_to_str($op);
    Return a string of the form "real imag".
    Both "real" and "imag" will be expressed in scientific
    notation, to the precision returned by the l_get_prec() function (above).
    Use l_set_prec() to alter this precision.
    Infinities are stringified to 'inf' (or '-inf' for -ve infinity).
    NaN values (including positive and negative NaN vlaues) are stringified to
    'nan'.

   $str = l_to_strp($op, $si);
    As for l_to_str, except that the precision setting for the output value
    is set by the 2nd arg (which must be greater than 1).

   $rop = str_to_l($str);
    Takes a string as per that returned by l_to_str() or l_to_strp().
    Returns a Math::Complex_C::L object set to the value represented by that
    string.

   cl2LD($f_r, $f_i, $op);
    Assign the real part of $op to the Math::LongDouble object $f_r, and the
    imaginary part of $op to the Math::LongDouble object $f_i.


=head1 OPERATOR OVERLOADING

   Math::Complex_C::L overloads the following operators:
    *, +, /, -, **,
    *=, +=, /=, -=, **=,
    !, bool,
    ==, !=,
    =, "",
    abs, exp, log, cos, sin, atan2, sqrt

    Note: abs() returns an NV, not a Math::Complex_C::L object. If your NV-type
    is not _long double then you should probably call abs_cl2LD() or abs_cl2str()
    instead. Check the documentation (above) of those two alternatives.

    Overloaded arithmetic operations are provided the following types:
     IV, UV, NV, PV, Math::Complex_C::L object.
    The IV, UV, NV and PV values are real only (ie no imaginary component). The
    PV values will be converted to long double values using C's strtold()
    function. The IV, UV and NV values will be cast to long double values.

    Note: For the purposes of the overloaded 'not', '!' and 'bool'
    operators, a "false" Math::Complex_C object is one with real
    and imaginary parts that are both "false" - where "false"
    currently means either 0 (including -0) or NaN.
    (A "true" Math::Complex_C object is, of course, simply one
    that is not "false".)

=head1 OTHER FUNCTIONS

    $iv = Math::Complex_C::L::nnumflag(); # not exported
     Returns the value of the non-numeric flag. This flag is
     initialized to zero, but incemented by 1 whenever a function
     is handed a string containing non-numeric characters. The
     value of the flag therefore tells us how many times functions
     have been handed such a string. The flag can be reset to 0 by
     running clear_nnum().

    Math::Complex_C::L::set_nnum($iv); # not exported
     Resets the global non-numeric flag to the value specified by
     $iv.

    Math::Complex_C::L::clear_nnum(); # not exported
     Resets the global non-numeric flag to 0.(Essentially the same
     as running set_nnum(0).)

=head1 LICENSE

   This module is free software; you may redistribute it and/or modify it under
   the same terms as Perl itself.
   Copyright 2014, 2016, Sisyphus.

=head1 AUTHOR

   Sisyphus <sisyphus at(@) cpan dot (.) org>

=cut
