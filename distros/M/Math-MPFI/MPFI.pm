package Math::MPFI;
use strict;
use warnings;
use Math::MPFR;

require Exporter;
*import = \&Exporter::import;
require DynaLoader;

our $VERSION = '0.09';
#$VERSION = eval $VERSION;

DynaLoader::bootstrap Math::MPFI $VERSION;

    use constant BOTH_ENDPOINTS_EXACT => 0;
    use constant LEFT_ENDPOINT_INEXACT => 1;
    use constant RIGHT_ENDPOINT_INEXACT => 2;
    use constant BOTH_ENDPOINTS_INEXACT => 3;

    use constant  _UOK_T   => 1;
    use constant  _IOK_T   => 2;
    use constant  _NOK_T   => 3;
    use constant  _POK_T   => 4;
    use constant  _MATH_MPFR_T   => 5;
    use constant  _MATH_GMPf_T   => 6;
    use constant  _MATH_GMPq_T   => 7;
    use constant  _MATH_GMPz_T   => 8;
    use constant  _MATH_GMP_T    => 9;
    use constant  _MATH_MPC_T    => 10;
    use constant  _MATH_MPFI_T    => 11;

    use subs qw(MPFI_VERSION_MAJOR MPFI_VERSION_MINOR
                MPFI_VERSION_PATCHLEVEL MPFI_VERSION_STRING);

    use overload
     '+'	=> \&overload_add,
     '-'	=> \&overload_sub,
     '*'	=> \&overload_mul,
     '/'	=> \&overload_div,
     '+='	=> \&overload_add_eq,
     '-='	=> \&overload_sub_eq,
     '*='	=> \&overload_mul_eq,
     '/='	=> \&overload_div_eq,
     'sqrt'	=> \&overload_sqrt,
     '<'	=> \&overload_lt,
     '>'	=> \&overload_gt,
     '<='	=> \&overload_lte,
     '>='	=> \&overload_gte,
     '<=>'	=> \&overload_spaceship,
     '=='	=> \&overload_equiv,
     '!='	=> \&overload_not_equiv,
     '""'	=> \&overload_string,
     'atan2'    => \&overload_atan2,
     'cos'      => \&overload_cos,
     'sin'      => \&overload_sin,
     'log'      => \&overload_log,
     'exp'      => \&overload_exp,
     'abs'      => \&overload_abs,
     'bool'     => \&overload_true,
     '!'        => \&overload_not;

@Math::MPFI::EXPORT = ();
@Math::MPFI::EXPORT_OK = qw(
BOTH_ENDPOINTS_EXACT LEFT_ENDPOINT_INEXACT
RIGHT_ENDPOINT_INEXACT BOTH_ENDPOINTS_INEXACT
RMPFI_BOTH_ARE_EXACT RMPFI_LEFT_IS_INEXACT
RMPFI_RIGHT_IS_INEXACT RMPFI_BOTH_ARE_INEXACT
RMPFI_ERROR MPFI_VERSION_MAJOR
MPFI_VERSION_MINOR MPFI_VERSION_PATCHLEVEL MPFI_VERSION_STRING
Rmpfi_set_default_prec Rmpfi_get_default_prec
Rmpfi_abs Rmpfi_acos Rmpfi_acosh Rmpfi_add Rmpfi_add_d Rmpfi_add_fr
Rmpfi_add_q Rmpfi_add_si Rmpfi_add_ui Rmpfi_add_z Rmpfi_alea
Rmpfi_asin Rmpfi_asinh Rmpfi_atan Rmpfi_atanh Rmpfi_bisect
Rmpfi_blow Rmpfi_bounded_p Rmpfi_clear Rmpfi_cmp Rmpfi_cmp_d
Rmpfi_cmp_fr Rmpfi_cmp_q Rmpfi_cmp_si Rmpfi_cmp_ui Rmpfi_cmp_z
Rmpfi_const_euler Rmpfi_const_log2 Rmpfi_const_pi Rmpfi_cos
Rmpfi_cosh Rmpfi_d_div Rmpfi_d_sub Rmpfi_diam Rmpfi_diam_abs
Rmpfi_diam_rel Rmpfi_div Rmpfi_div_2exp Rmpfi_div_2si Rmpfi_div_2ui
Rmpfi_div_d Rmpfi_div_fr Rmpfi_div_q Rmpfi_div_si Rmpfi_div_ui
Rmpfi_div_z Rmpfi_exp Rmpfi_exp2 Rmpfi_expm1 Rmpfi_fr_div
Rmpfi_fr_sub Rmpfi_get_d Rmpfi_get_fr Rmpfi_get_left Rmpfi_get_prec
Rmpfi_get_right Rmpfi_has_zero Rmpfi_increase Rmpfi_inf_p Rmpfi_init
Rmpfi_init2 Rmpfi_init_set Rmpfi_init_set_d Rmpfi_init_set_fr
Rmpfi_init_set_q Rmpfi_init_set_si Rmpfi_init_set_str Rmpfi_init_set_ui
Rmpfi_init_set_z
Rmpfi_init_nobless Rmpfi_init2_nobless Rmpfi_init_set_nobless
Rmpfi_init_set_d_nobless Rmpfi_init_set_fr_nobless
Rmpfi_init_set_q_nobless Rmpfi_init_set_si_nobless Rmpfi_init_set_str_nobless
Rmpfi_init_set_ui_nobless Rmpfi_init_set_z_nobless
Rmpfi_inp_str Rmpfi_intersect Rmpfi_interv_d
Rmpfi_interv_fr Rmpfi_interv_q Rmpfi_interv_si Rmpfi_interv_ui
Rmpfi_interv_z Rmpfi_inv Rmpfi_is_empty Rmpfi_is_error
Rmpfi_is_inside Rmpfi_is_inside_d Rmpfi_is_inside_fr Rmpfi_is_inside_q
Rmpfi_is_inside_si Rmpfi_is_inside_ui Rmpfi_is_inside_z Rmpfi_is_neg
Rmpfi_is_nonneg Rmpfi_is_nonpos Rmpfi_is_pos Rmpfi_is_strictly_inside
Rmpfi_is_strictly_neg Rmpfi_is_strictly_pos Rmpfi_is_zero Rmpfi_log
Rmpfi_log10 Rmpfi_log1p Rmpfi_log2 Rmpfi_mag Rmpfi_mid Rmpfi_mig
Rmpfi_mul Rmpfi_mul_2exp Rmpfi_mul_2si Rmpfi_mul_2ui Rmpfi_mul_d
Rmpfi_mul_fr Rmpfi_mul_q Rmpfi_mul_si Rmpfi_mul_ui Rmpfi_mul_z
Rmpfi_nan_p Rmpfi_neg Rmpfi_out_str Rmpfi_print_binary Rmpfi_put
Rmpfi_put_d Rmpfi_put_fr Rmpfi_put_q Rmpfi_put_si Rmpfi_put_ui
Rmpfi_put_z Rmpfi_q_div Rmpfi_q_sub Rmpfi_reset_error
Rmpfi_revert_if_needed Rmpfi_round_prec Rmpfi_set Rmpfi_set_d
Rmpfi_set_error Rmpfi_set_fr Rmpfi_set_prec Rmpfi_set_q
Rmpfi_set_si Rmpfi_set_str Rmpfi_set_ui Rmpfi_set_z Rmpfi_si_div
Rmpfi_si_sub Rmpfi_sin Rmpfi_sinh Rmpfi_sqr Rmpfi_sqrt
Rmpfi_sub Rmpfi_sub_d Rmpfi_sub_fr Rmpfi_sub_q Rmpfi_sub_si
Rmpfi_sub_ui Rmpfi_sub_z Rmpfi_swap Rmpfi_t Rmpfi_tan
Rmpfi_tanh Rmpfi_ui_div Rmpfi_ui_sub Rmpfi_union Rmpfi_z_div
Rmpfi_z_sub
TRmpfi_out_str TRmpfi_inp_str
Rmpfi_get_version Rmpfi_const_catalan Rmpfi_cbrt Rmpfi_hypot
Rmpfi_sec Rmpfi_csc Rmpfi_cot Rmpfi_sech Rmpfi_csch Rmpfi_coth
Rmpfi_atan2 Rmpfi_urandom
Rmpfi_get_NV Rmpfi_set_NV
);

%Math::MPFI::EXPORT_TAGS =(mpfi => [qw(
BOTH_ENDPOINTS_EXACT LEFT_ENDPOINT_INEXACT
RIGHT_ENDPOINT_INEXACT BOTH_ENDPOINTS_INEXACT
RMPFI_BOTH_ARE_EXACT RMPFI_LEFT_IS_INEXACT
RMPFI_RIGHT_IS_INEXACT RMPFI_BOTH_ARE_INEXACT
RMPFI_ERROR MPFI_VERSION_MAJOR
MPFI_VERSION_MINOR MPFI_VERSION_PATCHLEVEL MPFI_VERSION_STRING
Rmpfi_set_default_prec Rmpfi_get_default_prec
Rmpfi_abs Rmpfi_acos Rmpfi_acosh Rmpfi_add Rmpfi_add_d Rmpfi_add_fr
Rmpfi_add_q Rmpfi_add_si Rmpfi_add_ui Rmpfi_add_z Rmpfi_alea
Rmpfi_asin Rmpfi_asinh Rmpfi_atan Rmpfi_atanh Rmpfi_bisect
Rmpfi_blow Rmpfi_bounded_p Rmpfi_clear Rmpfi_cmp Rmpfi_cmp_d
Rmpfi_cmp_fr Rmpfi_cmp_q Rmpfi_cmp_si Rmpfi_cmp_ui Rmpfi_cmp_z
Rmpfi_const_euler Rmpfi_const_log2 Rmpfi_const_pi Rmpfi_cos
Rmpfi_cosh Rmpfi_d_div Rmpfi_d_sub Rmpfi_diam Rmpfi_diam_abs
Rmpfi_diam_rel Rmpfi_div Rmpfi_div_2exp Rmpfi_div_2si Rmpfi_div_2ui
Rmpfi_div_d Rmpfi_div_fr Rmpfi_div_q Rmpfi_div_si Rmpfi_div_ui
Rmpfi_div_z Rmpfi_exp Rmpfi_exp2 Rmpfi_expm1 Rmpfi_fr_div
Rmpfi_fr_sub Rmpfi_get_d Rmpfi_get_fr Rmpfi_get_left Rmpfi_get_prec
Rmpfi_get_right Rmpfi_has_zero Rmpfi_increase Rmpfi_inf_p Rmpfi_init
Rmpfi_init2 Rmpfi_init_set Rmpfi_init_set_d Rmpfi_init_set_fr
Rmpfi_init_set_q Rmpfi_init_set_si Rmpfi_init_set_str Rmpfi_init_set_ui
Rmpfi_init_set_z
Rmpfi_init_nobless Rmpfi_init2_nobless Rmpfi_init_set_nobless
Rmpfi_init_set_d_nobless Rmpfi_init_set_fr_nobless
Rmpfi_init_set_q_nobless Rmpfi_init_set_si_nobless Rmpfi_init_set_str_nobless
Rmpfi_init_set_ui_nobless Rmpfi_init_set_z_nobless
Rmpfi_inp_str Rmpfi_intersect Rmpfi_interv_d
Rmpfi_interv_fr Rmpfi_interv_q Rmpfi_interv_si Rmpfi_interv_ui
Rmpfi_interv_z Rmpfi_inv Rmpfi_is_empty Rmpfi_is_error
Rmpfi_is_inside Rmpfi_is_inside_d Rmpfi_is_inside_fr Rmpfi_is_inside_q
Rmpfi_is_inside_si Rmpfi_is_inside_ui Rmpfi_is_inside_z Rmpfi_is_neg
Rmpfi_is_nonneg Rmpfi_is_nonpos Rmpfi_is_pos Rmpfi_is_strictly_inside
Rmpfi_is_strictly_neg Rmpfi_is_strictly_pos Rmpfi_is_zero Rmpfi_log
Rmpfi_log10 Rmpfi_log1p Rmpfi_log2 Rmpfi_mag Rmpfi_mid Rmpfi_mig
Rmpfi_mul Rmpfi_mul_2exp Rmpfi_mul_2si Rmpfi_mul_2ui Rmpfi_mul_d
Rmpfi_mul_fr Rmpfi_mul_q Rmpfi_mul_si Rmpfi_mul_ui Rmpfi_mul_z
Rmpfi_nan_p Rmpfi_neg Rmpfi_out_str Rmpfi_print_binary Rmpfi_put
Rmpfi_put_d Rmpfi_put_fr Rmpfi_put_q Rmpfi_put_si Rmpfi_put_ui
Rmpfi_put_z Rmpfi_q_div Rmpfi_q_sub Rmpfi_reset_error
Rmpfi_revert_if_needed Rmpfi_round_prec Rmpfi_set Rmpfi_set_d
Rmpfi_set_error Rmpfi_set_fr Rmpfi_set_prec Rmpfi_set_q
Rmpfi_set_si Rmpfi_set_str Rmpfi_set_ui Rmpfi_set_z Rmpfi_si_div
Rmpfi_si_sub Rmpfi_sin Rmpfi_sinh Rmpfi_sqr Rmpfi_sqrt
Rmpfi_sub Rmpfi_sub_d Rmpfi_sub_fr Rmpfi_sub_q Rmpfi_sub_si
Rmpfi_sub_ui Rmpfi_sub_z Rmpfi_swap Rmpfi_t Rmpfi_tan
Rmpfi_tanh Rmpfi_ui_div Rmpfi_ui_sub Rmpfi_union Rmpfi_z_div
Rmpfi_z_sub
TRmpfi_out_str TRmpfi_inp_str
Rmpfi_get_version Rmpfi_const_catalan Rmpfi_cbrt Rmpfi_hypot
Rmpfi_sec Rmpfi_csc Rmpfi_cot Rmpfi_sech Rmpfi_csch Rmpfi_coth
Rmpfi_atan2 Rmpfi_urandom
Rmpfi_get_NV Rmpfi_set_NV
)]);

*TRmpfi_out_str = \&Rmpfi_out_str;
*TRmpfi_inp_str = \&Rmpfi_inp_str;

$Math::MPFI::NOK_POK = 0; # Set to 1 to allow warnings in new() and overloaded operations when
                          # a scalar that has set both NOK (NV) and POK (PV) flags is encountered

sub dl_load_flags {0} # Prevent DynaLoader from complaining and croaking

sub new {
    # This function caters for 2 possibilities:
    # 1) that 'new' has been called OOP style - in which
    #    case there will be a maximum of 3 args
    # 2) that 'new' has been called as a function - in
    #    which case there will be a maximum of 2 args.
    # If there are no args, then we just want to return an
    # initialized Math::MPFI object
    if(!@_) {return Rmpfi_init()}

    if(@_ > 3) {die "Too many arguments supplied to new()"}

    # If 'new' has been called OOP style, the first arg is the string
    # "Math::MPFI" which we don't need - so let's remove it. However,
    # if the first arg is a Math::MPFI object (which is a possibility),
    # then we'll get a fatal error when we check it for equivalence to
    # the string "Math::MPFI". So we first need to check that it's not
    # an object - which we'll do by using the ref() function:
    if(!ref($_[0]) && $_[0] eq "Math::MPFI") {
      shift;
      if(!@_) {return Rmpfi_init()}
      }

    # @_ can now contain a maximum of 2 args - the value, and iff the value is
    # a string, (optionally) the base of the numeric string.
    if(@_ > 2) {die "Too many arguments supplied to new() - expected no more than two"}

    my ($arg1, $type, $base);

    # $_[0] is the value, $_[1] (if supplied) is the base of the number
    # in the string $[_0].
    $arg1 = shift;
    $base = 0;

    $type = _itsa($arg1);
    if(!$type) {die "Inappropriate argument supplied to new()"}

    my @ret;

    # Create a Math::MPFI object that has $arg1 as its value.
    # Die if there are any additional args (unless $type == _POK_T)
    if($type == _UOK_T) {
      if(@_ ) {die "Too many arguments supplied to new() - expected only one"}
       if(_has_longlong()) {
         my $t = Math::MPFR->new();
         Math::MPFR::Rmpfr_set_uj($t, $arg1, Math::MPFR::Rmpfr_get_default_rounding_mode());
         @ret = Rmpfi_init_set_fr($t);
       }
       else {@ret = Rmpfi_init_set_ui($arg1)}
      return $ret[0];
    }

    if($type == _IOK_T) {
      if(@_ ) {die "Too many arguments supplied to new() - expected only one"}
       if(_has_longlong()) {
         my $t = Math::MPFR->new();
         Math::MPFR::Rmpfr_set_sj($t, $arg1, Math::MPFR::Rmpfr_get_default_rounding_mode());
         @ret = Rmpfi_init_set_fr($t);
       }
       else {@ret = Rmpfi_init_set_si($arg1)}
      return $ret[0];
    }

    if($type == _NOK_T) {
      if(@_ ) {die "Too many arguments supplied to new() - expected only one"}
       if(_has_longdouble()) {
         $ret[0] = Math::MPFI->new();
         Rmpfi_set_NV($ret[0], $arg1);
       }
       else {@ret = Rmpfi_init_set_d($arg1)}
      return $ret[0];
    }

    if($type == _POK_T) {
      if(@_ > 1) {die "Too many arguments supplied to new() - expected no more than two"}
      $base = shift if @_;
      if($base < 0 || $base == 1 || $base > 36) {die "Invalid value for base"}
      if(_SvNOK($arg1)) {
        set_nok_pok(nok_pokflag() + 1);
        if($Math::MPFI::NOK_POK) {
          warn "Scalar passed to new() is both NV and PV. Using PV (string) value";
        }
      }
      @ret = Rmpfi_init_set_str($arg1, $base);
      if($ret[1]) {warn "string supplied to new() contained invalid characters"}
      return $ret[0];
    }

    if($type == _MATH_MPFI_T) {
      if(@_) {die "Too many arguments supplied to new() - expected only one"}
      @ret = Rmpfi_init_set($arg1);
      return $ret[0];
    }

    if($type == _MATH_MPFR_T) {
      if(@_) {die "Too many arguments supplied to new() - expected only one"}
      @ret = Rmpfi_init_set_fr($arg1);
      return $ret[0];
    }

     ### Currently Unavailable
     if($type == _MATH_GMPf_T) {die "Inappropriate argument supplied to new()"}
#    if($type == _MATH_GMPf_T) {
#      if(@_) {die "Too many arguments supplied to new() - expected only one"}
#      @ret = Rmpfi_init_set_f($arg1);
#      return $ret[0];
#    }

    if($type == _MATH_GMPq_T) {
      if(@_) {die "Too many arguments supplied to new() - expected only one"}
      @ret = Rmpfi_init_set_q($arg1);
      return $ret[0];
    }

    if($type == _MATH_GMPz_T || $type == _MATH_GMP_T) {
      if(@_) {die "Too many arguments supplied to new() - expected only one"}
      @ret = Rmpfi_init_set_z($arg1);
      return $ret[0];
    }

    die "new() was passed an invalid argument";
}

sub Rmpfi_out_str {
    if(@_ == 4) {
      die "Inappropriate 4th arg supplied to Rmpfi_out_str" if _itsa($_[3]) != _MATH_MPFI_T;
      return _Rmpfi_out_str($_[0], $_[1], $_[2], $_[3]);
    }
    if(@_ == 5) {
      if(_itsa($_[3]) == _MATH_MPFI_T) {return _Rmpfi_out_strS($_[0], $_[1], $_[2], $_[3], $_[4])}
      die "Incorrect args supplied to Rmpfi_out_str" if _itsa($_[4]) != _MATH_MPFI_T;
      return _Rmpfi_out_strP($_[0], $_[1], $_[2], $_[3], $_[4]);
    }
    if(@_ == 6) {
      die "Inappropriate 5th arg supplied to Rmpfi_out_str" if _itsa($_[4]) != _MATH_MPFI_T;
      return _Rmpfi_out_strPS($_[0], $_[1], $_[2], $_[3], $_[4], $_[5]);
    }
    die "Wrong number of arguments supplied to Rmpfi_out_str()";
}

sub Rmpfi_set_default_prec { # Sets default prec for both Math::MPFR and Math::MPFI
    _Rmpfi_set_default_prec($_[0]);
    # Need to call Math::MPFR::Rmpfr_set_default_prec in
    # case Math::MPFR and Math::MPFI use different copies
    # of the mpfr library - eg if they've been built against
    # static libraries
    Math::MPFR::Rmpfr_set_default_prec($_[0]);
}

sub overload_string {
    my $prec = Rmpfi_get_prec($_[0]);
    my $mpfr = Math::MPFR::Rmpfr_init2($prec);
    Rmpfi_get_left($mpfr, $_[0]);
    my $ret = '[' . Math::MPFR::Rmpfr_get_str($mpfr, 10, 0, Math::MPFR::GMP_RNDD) . ',';
    #my $ret = '[' . "$mpfr" . ','; # Wrong - we need GMP_RNDD.
    Rmpfi_get_right($mpfr, $_[0]);
    $ret .= Math::MPFR::Rmpfr_get_str($mpfr, 10, 0, Math::MPFR::GMP_RNDU) . ']';
    #$ret .= "$mpfr" . ']'; # Wrong - we need GMP_RNDU.
    return $ret;
}

sub overload_not_equiv {
    return !overload_equiv(@_);
}

# Moved to XS
# sub overload_spaceship {
#    if(Rmpfi_nan_p($_[0]) || ($_[1] != $_[1])) {return undef}
#    if(overload_equiv(@_)) {return 0}
#    if(overload_gt(@_)) {return 1}
#    if(overload_lt(@_)) {return -1}
#}

sub MPFI_VERSION_MAJOR {return _MPFI_VERSION_MAJOR()}
sub MPFI_VERSION_MINOR {return _MPFI_VERSION_MINOR()}
sub MPFI_VERSION_PATCHLEVEL {return _MPFI_VERSION_PATCHLEVEL()}
sub MPFI_VERSION_STRING {return _MPFI_VERSION_STRING()}

1;

__END__

=head1 NAME


Math::MPFI - perl interface to the MPFI (interval arithmetic) library.

=head1 DEPENDENCIES


   This module needs the MPFI, MPFR and GMP C libraries. (Install GMP
   first, then MPFR, then MPFI.)

   The GMP library is availble from http://gmplib.org
   The MPFR library is available from http://www.mpfr.org/
   The MPFI library is available from
       http://gforge.inria.fr/projects/mpfi/

=head1 DESCRIPTION


   An arbitrary precision interval arithmetic module utilising the MPFI
   library. Basically, this module simply wraps the 'mpfi' interval
   arithmetic functions provided by that library.
   Operator overloading is also available.
   The following documentation heavily plagiarises the mpfi documentation.

=head1 SYNOPSIS


   use warnings;
   use Math::MPFI qw(:mpfi);
   Rmpfi_set_default_prec(100); # Set default precision to 100 bits
   my $mpfi1 = Math::MPFI->new(2);
   $mpfi2 = sqrt($mpfi1);
   print "Square root of $mpfi1 lies in the interval $mpfi2\n";

   See also the Math::MPFI test suite for some (simplistic) examples of
   usage.

=head1 FUNCTIONS


   Most of the following functions are simply wrappers around an mpfi
   function of the same name. eg. Rmpfi_mul() is a wrapper around
   mpfi_mul().

   "$rop", "$op1", "$op2", etc. are Math::MPFI objects - the
   return value of one of the Rmpfi_init* functions. They are in fact
   references to mpfi structures. The "$op" variables are the operands
   and "$rop" is the variable that stores the result of the operation.
   Generally, $rop, $op1, $op2, etc. can be the same perl variable
   referencing the same mpfi structure, though often they will be
   distinct perl variables referencing distinct mpfi structures.
   Eg something like Rmpfi_add($r1, $r1, $r1),
   where $r1 *is* the same reference to the same mpfi structure,
   would add $r1 to itself and store the result in $r1. Alternatively,
   you could (courtesy of operator overloading) simply code it
   as $r1 += $r1. Otoh, Rmpfi_add($r1, $r2, $r3), where each of the
   arguments is a different reference to a different mpfi structure
   would add $r2 to $r3 and store the result in $r1. Alternatively
   it could be coded as $r1 = $r2 + $r3.

   In the documentation that follows:

   "$ui" means an integer that will fit into a C 'unsigned long int',

   "$si" means an integer that will fit into a C 'signed long int'.

   "$double" is a C double.

   "$bool" means a value (usually a 'signed long int') in which
   the only interest is whether it evaluates as false or true.

   "$str" simply means a string of symbols that represent a number,
   eg '1234567'.

   "$p" is the value for precision.

   "$q" is a Math::GMPq object (rational). You'll need Nath::GMPq
          installed and loaded in order to create $q.

   "$z" is a Math::GMP or Math::GMPz object (integer). You'll need
        Math::GMPz or Math::GMP installed and loaded in order to
        create $z.

   "$fr" is a Math::MPFR object (floating point). Math::MPFR is a
         pre-requisite module for Math::MPFI.)

   #########

   PRECISION

    Rmpfi_set_default_prec($p);
     Sets the default precision for both Math::MPFI and Math::MPFR to
     be *exactly* $p bits. The precision of a variable means the
     number of bits used to store the mantissas of its endpoints.
     All subsequent calls to `mpfi_init' will use this precision,
     but previously initialized variables are unaffected.
     This default precision is set to 53 bits initially.
     The precision $p can be any integer between `MPFR_PREC_MIN' and
     `MPFR_PREC_MAX'.

    $ui = Rmpfi_get_default_prec();
     Returns the default Math::MPFR/Math::MPFI precision in bits.

    $si = Rmpfi_set_prec ($op, $p);
     Resets the precision of $x to be *exactly* PREC bits. The previous
     value stored in $x is lost. It is equivalent to a call to
     `Rmpfi_clear($op)' followed by a call to `Rmpfi_init2($op, $p)', but
     more efficient as no allocation is done in case the current
     allocated space for the mantissas of the endpoints of $op is enough.
     It returns a non-zero value iff the memory allocation failed.
     In case you want to keep the previous value stored in $op, use
     `Rmpfi_round_prec' instead.

    $ui = Rmpfi_get_prec($op);
     Return the largest precision actually used for assignments of $op,
     i.e.  the number of bits used to store the mantissas of its
     endpoints.  Should the two endpoints have different precisions,
     the largest one is returned.

    $si = Rmpfi_round_prec($op, $p);
     Rounds $op with precision $p, which may be different from that of
     $op.  If $p is greater or equal to the precision of $op, then new
     space is allocated for the endpoints' mantissas, and they are
     filled with zeroes.  Otherwise, the mantissas are outwards rounded
     to precision $p.  In both cases, the precision of $op is changed
     to $p.  It returns a value indicating whether the possibly
     rounded endpoints are exact or not.

   ########################

   INITIALISATION FUNCTIONS

    An Math::MPFI object must be initialized before storing the first
    value in it. The functions `Rmpfi_init' and `Rmpfi_init2' are used
    for that purpose.

    $rop = Rmpfi_init();
    $rop = Rmpfi_init_nobless();
     Initializes $op, and sets its value to NaN, to prevent from using an
     unassigned variable inadvertently. (The "_nobless" version of the
     function will create an unblessed variable. I don't know why you
     would want to use it, but you can if you want.) The precision of $op
     is the default precision, which can be changed by a call to
     `Rmpfi_set_default_prec'.

    $rop = Rmpfi_init2 ($prec);
    $rop = Rmpfi_init2_nobless ($prec);
     Initializes $op, sets its precision (or more precisely the precision
     of its endpoints) to be *exactly* $prec bits, and sets its
     endpoints to NaN. (The "_nobless" version of the function will create
     an unblessed variable. I don't know why you would want to use it, but
     you can if you want.) To change the precision of a variable which has
     already been initialized, use `Rmpfi_set_prec' instead, or
    `Rmpfi_round_prec' if you want to keep its value.

    Rmpfi_clear ($op)
     Not normally called.
     Frees the space occupied by the significands of the endpoints of
     $op. Call this only on objects that have *not* been blessed into the
     Math::MPFI package - ie only with objects created using the 'nobless'
     variants of the initialisation routines. For all blessed Math::MPFI
     objects, the space will be freed automatically as they go out of
     scope.

   ####################

   ASSIGNMENT FUNCTIONS

    These functions assign new values to already initialized intervals

    $si = Rmpfi_set    ($rop, $op);
    $si = Rmpfi_set_ui ($rop, $ui);
    $si = Rmpfi_set_si ($rop, $si);
    $si = Rmpfi_set_d  ($rop, $double);
    $si = Rmpfi_set_NV ($rop, $NV); # $NV is $Config{nvtype}
    $si = Rmpfi_set_z  ($rop, $z);  # $z is a Math::GMP
                                    # or Math::GMPz object.
    $si = Rmpfi_set_q  ($rop, $q);  # $q is a Math::GMPq object
    $si = Rmpfi_set_fr ($rop, $fr); # $fr is a Math::MPFR object
     Sets the value of $rop from 2nd arg, rounded outward to the precision
     of $rop. (The value of $op is then contained within $rop.)
     The returned value indicates whether none, one or both endpoints
     are exact.  Please note that even a `long int' may have to be rounded,
     if the destination precision is less than the machine word width.

    $si = Rmpfi_set_str ($rop, $str, $ui);
     Sets $rop to the value of the $str, in base $ui (between 2 and
     36), outward rounded to the precision of $rop.
     The exponent is read in decimal.  The string ($str) is of the form
     `number' or `[ number1 , number 2 ]'.  Each endpoint has the form
     `M@N' or, if the base is 10 or less, alternatively `MeN' or `MEN'.
     `M' is the mantissa and `N' is the exponent.  The mantissa is
     always in the specified base.  The exponent is in decimal.  The
     argument $ui may be in the ranges 2 to 36.
     This function returns 1 if the input is incorrect, and 0 otherwise.

    Rmpfi_swap ($x, $y);
     Swaps the values $x and $ efficiently. Warning: the precisions are
     exchanged too; in case the precisions are different, `Rmpfi_swap'
     is thus not equivalent to three `Rmpfi_set' calls using a third
     auxiliary variable.

   ################################################

   COMBINED INITIALISATION AND ASSIGNMENT FUNCTIONS

    ($rop, $si) = Rmpfi_init_set ($op);
    ($rop, $si) = Rmpfi_init_set_ui ($ui);
    ($rop, $si) = Rmpfi_init_set_si ($si2);
    ($rop, $si) = Rmpfi_init_set_d ($double);
    ($rop, $si) = Rmpfi_init_set_z ($z);   # $z is a Math::GMP
                                           # or a Math::GMPz object
    ($rop, $si) = Rmpfi_init_set_q ($q);   # $q is a Math::GMPq object
    ($rop, $si) = Rmpfi_init_set_fr ($fr); # $fr is a Math::MPFR object
    ($rop, $si) = Rmpfi_init_set_nobless ($op);
    ($rop, $si) = Rmpfi_init_set_ui_nobless ($ui);
    ($rop, $si) = Rmpfi_init_set_si_nobless ($si2);
    ($rop, $si) = Rmpfi_init_set_d_nobless ($double);
    ($rop, $si) = Rmpfi_init_set_z_nobless ($z);
    ($rop, $si) = Rmpfi_init_set_q_nobless ($q);
    ($rop, $si) = Rmpfi_init_set_fr_nobless ($fr);
     Initializes $rop and sets its value from the 1st arg, outward
     rounded so that the 1st arg is contained in $rop. The precision
     of $rop will be taken from the active default precision, as set
     by `Rmpfi_set_default_prec'. (The "_nobless" versions of the
     functions will create an unblessed variable. I don't know why
     you would want to use them, but you can if you want.)
     The value $si indicates whether none, one or both endpoints
     are exact.

    ($rop, $si) = Rmpfi_init_set_str ($str, $ui);
    ($rop, $si) = Rmpfi_init_set_str_nobless ($str, $ui);
     Initializes $rop and sets its value to the value of $str,
     in base $ui (between 2 and 36), outward rounded to the precision
     of $rop. The value of $str is then contained within $rop.
     The exponent is read in decimal. See `Rmpfi_set_str'.
     (The "_nobless" version of the function will create an unblessed
     variable. I don't know why you would want to use it, but you can
     if you want.)

   ##############################################

   INTERVAL FUNCTIONS WITH FLOATING-POINT RESULTS

    Some functions on intervals return floating-point results, such as
    the center or the width, also called diameter, of an interval.

    $si = Rmpfi_diam_abs ($fr, $op); # $fr is a Math::MPFR object
     Sets the value of $fr to the upward rounded diameter of $op, or in
     other words to the upward rounded difference between the right
     endpoint of $op and its left endpoint.  Returns 0 if the diameter
     is exact and a positive value if the rounded value is greater than
     the exact diameter.

    $si = Rmpfi_diam_rel ($fr, $op); # $fr is a Math::MPFR object
     Sets the value of $fr to the upward rounded relative diameter of
     $op, or in other words to the upward rounded difference between the
     right endpoint of $op and its left endpoint, divided by the
     absolute value of the center of $op if it is not zero.  Returns 0
     if the result is exact and a positive value if the returned value
     is an overestimation, in this case the returned value may not be
     the correct rounding of the exact value.

    $si = Rmpfi_diam ($fr, $op); # $fr is a Math::MPFR object
     Sets the value of $fr to the relative diameter of $op if $op does
     not contain zero and to its absolute diameter otherwise.  Returns
     0 if the result is exact and a positive value if the returned value
     is an overestimation, it may not be the correct rounding of the
     exact value in the latter case.

    $si = Rmpfi_mag ($fr, $op); # $fr is a Math::MPFR object
     Sets the value of $fr to the magnitude of $op, i.e. to the largest
     absolute value of the elements of $op.  Returns 0 if the result is
     exact and a positive value if the returned value is an
     overestimation.

    $si = Rmpfi_mig ($fr, $op); # $fr is a Math::MPFR object
     Sets the value of $fr to the mignitude of $op, i.e. to the smallest
     absolute value of the elements of $op.  Returns 0 if the result is
     exact and a negative value if the returned value is an
     underestimation.

    $si = Rmpfi_mid ($fr, $op); # $fr is a Math::MPFR object
     Sets $fr to the middle of $op.  Returns 0 if the result is exact, a
     positive value if $rop > the middle of $op and a negative value if
     $rop < the middle of $op.

    $si = Rmpfi_alea ($fr, $op); # $fr is a Math::MPFR object
     Sets $fr to a floating-point number picked up at random in $op,
     according to a uniform distribution.
     This function is deprecated and may disappear in future versions
     of MPFI; `Rmpfi_urandom' should be used instead.

    Rmpfi_urandom ($fr, $op, $state); # $state is a gmp_randstate_t object.
                                      # $fr is a Math::MPFR object
     Sets $fr to a floating-point number picked up at random in $op,
     according to a uniform distribution.
     The argument $state should be initialized with one of the
     Math::GMPz, Math::GMPf or Math::GMPq random state initialization
     functions - see the Math::GMPz/GMPq/GMPf documentation.

   ####################

   CONVERSION FUNCTIONS

    $double = Rmpfi_get_d ($op);
     Converts $op to a double, which is the center of $op rounded to the
     nearest double.

    $NV = Rmpfi_get_NV ($op); # $NV is $Config{nvtype}
     Converts $op to an NV, which is the center of $op rounded to the
     nearest NV.

    Rmpfi_get_fr ($fr, $op); # $fr is a Math::MPFR object
     Converts $op to a floating-point number, which is the center of $op
     rounded to nearest.

   ##########################

   BASIC ARITHMETIC FUNCTIONS

    $si = Rmpfi_add ($rop, $op1, $op2);
    $si = Rmpfi_add_d ($rop, $op, $double);
    $si = Rmpfi_add_ui ($rop, $op, $ui);
    $si = Rmpfi_add_si ($rop, $op, $si);
    $si = Rmpfi_add_z ($rop, $op, $z);   # $z is a Math::GMP or
                                         # Math::GMPz object
    $si = Rmpfi_add_q ($rop, $op, $q);   # $q is a Math::GMPq object
    $si = Rmpfi_add_fr ($rop, $op, $fr); # $fr is a Math::MPFR object
     Sets $rop to the sum of the 2nd and 3rd args.  Returns a value
     indicating whether none, one or both endpoints are exact.

    $si = Rmpfi_sub ($rop, $op1, $op2);
    $si = Rmpfi_sub_d ($rop, $op, $double);
    $si = Rmpfi_d_sub ($rop, $double, $op);
    $si = Rmpfi_sub_ui ($rop, $op, $ui);
    $si = Rmpfi_ui_sub ($rop, $ui, $op);
    $si = Rmpfi_sub_si ($rop, $op, $si);
    $si = Rmpfi_si_sub ($rop, $si, $op);
    $si = Rmpfi_sub_z ($rop, $op, $z);   # $z is a Math::GMP or
    $si = Rmpfi_z_sub ($rop, $z, $op);   # Math::GMPz object
    $si = Rmpfi_sub_q ($rop, $op, $q);   # $q is a Math::GMPq object
    $si = Rmpfi_q_sub ($rop, $q, $op);   # $q is a Math::GMPq object
    $si = Rmpfi_sub_fr ($rop, $op, $fr); # $fr is a Math::MPFR object
    $si = Rmpfi_fr_sub ($rop, $fr, $op); # $fr is a Math::MPFR object
     Sets $rop to the 2nd arg minus the 3rd arg. Returns a value
     indicating whether none, one or both endpoints are exact.

    $si = Rmpfi_mul ($rop, $op1, $op2);
    $si = Rmpfi_mul_d ($rop, $op, $double);
    $si = Rmpfi_mul_ui ($rop, $op, $ui);
    $si = Rmpfi_mul_si ($rop, $op, $si);
    $si = Rmpfi_mul_z ($rop, $op, $z);   # $z is a Math::GMP or
                                         # or Math::GMPz object
    $si = Rmpfi_mul_q ($rop, $op, $q);   # $q is a Math::GMPq object
    $si = Rmpfi_mul_fr ($rop, $op, $fr); # $fr is a Math::MPFR object
     Sets $rop to the product of the 2nd and 3rd args.
     Multiplication by an interval containing only zero results in 0.
     Returns a value indicating whether none, one or both endpoints
     are exact.

   Division is defined even if the divisor contains zero: when the
   divisor contains zero in its interior, the result is the whole real
   interval [-Inf, Inf].  When the divisor has one of its endpoints equal
   to 0, for instance, [1,2]/[+0,1] results in [1, Inf].  It is not
   guaranteed in the current version that everything behaves properly if
   the divisor contains only 0.  In this example, both endpoints are exact.

    $si = Rmpfi_div ($rop, $op1, $op2);
    $si = Rmpfi_div_d ($rop, $op, $double);
    $si = Rmpfi_d_div ($rop, $double, $op);
    $si = Rmpfi_div_ui ($rop, $op, $ui);
    $si = Rmpfi_ui_div ($rop, $ui, $op);
    $si = Rmpfi_div_si ($rop, $op, $si);
    $si = Rmpfi_si_div ($rop, $si, $op);
    $si = Rmpfi_div_z ($rop, $op, $z);   # $z is a Math::GMP or
    $si = Rmpfi_z_div ($rop, $z, $op);   # Math::GMPz object
    $si = Rmpfi_div_q ($rop, $op, $q);   # $q is a Math::GMPq object
    $si = Rmpfi_q_div ($rop, $q, $op);   # $q is a Math::GMPq object
    $si = Rmpfi_div_fr ($rop, $op, $fr); # $fr is a Math::MPFR object
    $si = Rmpfi_fr_div ($rop, $fr, $op); # $fr is a Math::MPFR object
     Sets $rop to the 2nd arg divided by the 3rd arg.  Returns an
     indication of whether none, one or both endpoints are exact.

    $si = Rmpfi_neg ($rop, $op);
     Sets $rop to -$op.  Returns an indication of whether none, one or
     both endpoints are exact.

    $si = Rmpfi_sqr ($rop, $op);
     Sets $rop to the nonnegative square of $op.  Returns an indication
     of whether none, one or both endpoints are exact.  Indeed, in
     interval arithmetic, the square of an interval is a nonnegative
     interval whereas the product of an interval by itself can contain
     negative values.

    $si = Rmpfi_inv ($rop, $op);
     Sets $rop to 1/$op.  Inverse is defined even if the interval
     contains zero: when the denominator contains zero, the result is
     the whole real interval ]-Inf, Inf[.  Returns an indication of
     whether none, one or both endpoints are exact.

    $si = mpfi_sqrt ($rop, $op);
     Sets $rop to the square root of $op.  Sets $rop to NaN if $op is
     negative.  Returns an indication of whether none, one or both
     endpoints are exact.

    $si = Rmpfi_cbrt ($rop, $op);
     Sets $rop to the cubic root of $op.  Returns an indication of
     whether none, one or both endpoints are exact.

    $si = Rmpfi_abs ($rop, $op);
     Sets $rop to the interval containing the absolute value of every
     element of $op.  Returns an indication of whether none, one or both
     endpoints are exact.

    $si = Rmpfi_mul_2exp ($rop, $op, $ui);
    $si = Rmpfi_mul_2ui ($rop, $op, $ui);
    $si = Rmpfi_mul_2si ($rop, $op, $si);
     Sets $rop to the 2nd arg times 2 raised to the value of the 3rd arg.
     `Rmpfi_mul_2exp' is identical to `Rmpfi_mul_2ui' and is kept for
     compatibility with former versions of MPFI only. It is deprecated
     and could disappear in future versions of MPFI.  Returns an
     indication of whether none, one or both endpoints are exact.  Just
     increases the exponents of the endpoints by OP2 when ROP and OP1
     are identical.

    $si = Rmpfi_div_2exp ($rop, $op1, $ui);
    $si = Rmpfi_div_2ui ($rop, $op, $ui);
    $si = Rmpfi_div_2si ($rop, $op, $si);
     Sets $rop to $op1 divided by 2 raised to the value of the 3rd arg.
     Returns an indication of whether none, one or both endpoints are
     exact. Just decreases the exponents of the endpoints by the value
     of the 3rd arg when $rop and $op are identical.

   #################

   SPECIAL FUNCTIONS

    $si = Rmpfi_log ($rop, $op);
     Sets $rop to the natural logarithm of $op, with the precision of $rop.
     Returns an indication of whether none, one or both endpoints are
     exact.  If $op contains negative numbers, then $rop has at least one
     NaN endpoint.

    $si = Rmpfi_exp ($rop, $op);
     Sets $rop to the exponential of $op, with the precision of ROP.
     Returns an indication of whether none, one or both endpoints are
     exact.

    $si = Rmpfi_exp2 ($rop, $op);
     Sets $rop to 2 to the power $op, with the precision of $rop.  Returns
     an indication of whether none, one or both endpoints are exact.

    $si = Rmpfi_cos ($rop, $op);
    $si = Rmpfi_sin ($rop, $op);
    $si = Rmpfi_tan ($rop, $op);
     Sets $rop to the cosine, sine or tangent of $op, with the precision
     of $rop.  Returns an indication of whether none, one or both
     endpoints are exact.

    $si = Rmpfi_sec ($rop, $op);
    $si = Rmpfi_csc ($rop, $op);
    $si = Rmpfi_cot ($rop, $op);
     Sets ROP to the secant, cosecant or cotangent of $op, with the
     precision of $rop.  Returns an indication of whether none, one or
     both endpoints are exact.

    $si = Rmpfi_acos ($rop, $op);
    $si = Rmpfi_asin ($rop, $op);
    $si = Rmpfi_atan ($rop, $op);
     Sets $rop to the arc-cosine, arc-sine or arc-tangent of $op, with
     the precision of $rop.  Returns an indication of whether none, one
     or both endpoints are exact.

    $si = Rmpfi_atan2 ($rop, $op1, $op2);
     Sets $rop to the arc-tangent2 of $op1 and $op2, with the precision of
     $rop.  Returns an indication of whether none, one or both endpoints
     are exact.

    $si = Rmpfi_cosh ($rop, $op);
    $si = Rmpfi_sinh ($rop, $op);
    $si = Rmpfi_tanh ($rop, $op)
     Sets $rop to (respectively) the hyperbolic cosine, the hyperbolic
     sine and the hyperbolic tangent of $op.  Returns an indication of
     whether none, one or both endpoints are exact.

    $si = Rmpfi_sech ($rop, $op);
    $si = Rmpfi_csch ($rop, $op);
    $si = Rmpfi_coth ($rop, $op);
     Sets $rop to the hyperbolic secant, cosecant or cotangent of $op,
     with the precision of $rop.  Returns an indication of whether none,
     one or both endpoints are exact.

    $si = Rmpfi_acosh ($rop, $op);
    $si = Rmpfi_asinh ($rop, $op);
    $si = Rmpfi_atanh ($rop, $op);
     Sets $rop to the inverse hyperbolic cosine, sine or tangent of $op,
     with the precision of $rop.  Returns an indication of whether none,
     one or both endpoints are exact.

    $si = Rmpfi_log1p ($rop, $op);
     Sets $rop to the natural logarithm of one plus $op, with the
     precision of $rop.  Returns an indication of whether none, one or
     both endpoints are exact.  If $op contains negative numbers, then
     $rop has at least one NaN endpoint.

    $si = Rmpfi_expm1 ($rop, $op);
     Sets $rop to the exponential of $op, minus one, with the precision
     of $rop.  Returns an indication of whether none, one or both
     endpoints are exact.

    $si = Rmpfi_log2 ($rop, $op);
    $si = Rmpfi_log10 ($rop, $op);
     Sets $rop to log[t] $op with t=2 or 10 the base for the logarithm,
     with the precision of $rop.  Returns an indication of whether none,
     one or both endpoints are exact.  If $op contains negative numbers,
     then $rop has at least one NaN endpoint.

    $si = Rmpfi_hypot ($rop, $op1, $op2);
     Sets $rop to the euclidean distance between points in $op1 and
     points in $op2, with the precision of $rop.  Returns an indication
     of whether none, one or both endpoints are exact.

    $si = Rmpfi_const_log2 ($rop);
    $si = Rmpfi_const_pi ($rop);
    $si = Rmpfi_const_euler ($rop);
    $si = Rmpfi_const_catalan ($rop);
     Sets $rop respectively to the logarithm of 2, to the value of Pi,
     to the Euler's constant, and to the Catalan's constant, with the
     precision of $rop.
     Returns an indication of whether none, one or both endpoints are
     exact.

   ####################

   COMPARISON FUNCTIONS

    The comparison of two intervals is not clearly defined when they
    overlap.  MPFI proposes default comparison functions, but they can
    easily be customized according to the user's needs.  The default
    comparison functions return a positive value if the first interval has
    all its elements strictly greater than all elements of the second one, a
    negative value if the first interval has all its elements strictly
    lower than all elements of the second one and 0 otherwise, i.e. if
    they overlap or if one is contained in the other.

    $si = Rmpfi_cmp ($op1, $op2);
    $si = Rmpfi_cmp_d ($op, $double);
    $si = Rmpfi_cmp_ui ($op, $ui);
    $si = Rmpfi_cmp_si ($op, $si);
    $si = Rmpfi_cmp_z ($op, $z);   # $z is Math::GMP or
                                   # or Math::GMPz object
    $si = Rmpfi_cmp_q ($op, $q);   # $q is a Math::GMP object
    $si = Rmpfi_cmp_fr ($op, $fr); # $fr is a Math::MPFR object
     Compares $op and the 2nd arg.  Return a positive value if
     $op > 2nd arg, zero if $op overlaps or contains the 2nd arg, and a
     negative value if $op < 2nd arg.
     In case one of the operands is invalid (which is represented by at
     least one NaN endpoint), it returns 1, even if both are invalid.

    $si = Rmpfi_is_pos ($op);
     Returns a positive value if $op contains only positive numbers, the
     left endpoint can be zero.

    $si = Rmpfi_is_strictly_pos ($op);
     Returns a positive value if $op contains only positive numbers.

    $si = Rmpfi_is_nonneg ($op);
     Returns a positive value if $op contains only nonnegative numbers.

    $si = Rmpfi_is_neg ($op)
     Returns a positive value if $op contains only negative numbers, the
     right endpoint can be zero.

    $si = Rmpfi_is_strictly_neg ($op);
     Returns a positive value if $op contains only negative numbers.

    $si = Rmpfi_is_nonpos ($op);
     Returns a positive value if $op contains only nonpositive numbers.

    $si = Rmpfi_is_zero ($op);
     Returns a positive value if $op contains only 0.

    $si = Rmpfi_has_zero ($op);
     Returns a positive value if $op contains 0 (and possibly other
     numbers).

    $si = Rmpfi_nan_p ($op);
     Returns non-zero if $op is invalid, i.e. at least one of its
     endpoints is a Not-a-Number (NaN), zero otherwise.

    $si = Rmpfi_inf_p ($op);
     Returns non-zero if at least one of the endpoints of $op is plus or
     minus infinity, zero otherwise.

    $si = Rmpfi_bounded_p ($op);
     Returns non-zero if OP is a bounded interval, i.e. neither invalid
     nor (semi-)infinite.

   ##########################

   INPUT AND OUTPUT FUNCTIONS

    Functions that perform input from a stdio stream, and functions that
    output to a stdio stream.  Passing a NULL pointer for a STREAM argument
    to any of these functions will make them read from `stdin' and write to
    `stdout', respectively.


    The input and output functions are based on the representation by
    endpoints.  The input function has to be improved. For the time being,
    it is mandatory to insert spaces between the interval brackets and the
    endpoints and also around the comma separating the endpoints.

    $si = Rmpfi_out_str ($stream, int $base, $digits, $op);
     Outputs $op on stdio stream $stream, as a string of digits in base
     $base. The output is an opening square bracket "[", followed by the
     lower endpoint, a separating comma, the upper endpoint and a
     closing square bracket "]".

     The base may vary from 2 to 36.  For each endpoint, it prints at
     most $digits significant digits, or if $digits is 0, the maximum
     number of digits accurately representable by $op.  In addition to
     the significant digits, a decimal point at the right of the first
     digit and a trailing exponent, in the form `eNNN', are printed.
     If $base is greater than 10, `@' will be used instead of `e' as
     exponent delimiter.

     Returns the number of bytes written, or if an error occurred,
     return 0.

     As `Rmpfi_out_str' outputs an enclosure of the input interval, and
     as `Rmpfi_inp_str' provides an enclosure of the interval it reads,
     these functions are not reciprocal. More precisely, when they are
     called one after the other, the resulting interval contains the
     initial one, and this inclusion may be strict.

    $si = Rmpfi_inp_str ($rop, $stream, $base);
     Inputs a string in base $base from stdio stream $stream, and puts the
     read float in $rop.  The string is of the form `number' or `[
     number1 , number 2 ]'.  Each endpoint has the form `M@N' or, if the
     base is 10 or less, alternatively `MeN' or `MEN'.  `M' is the
     mantissa and `N' is the exponent.  The mantissa is always in the
     specified base.  The exponent is in decimal.

     The argument $base may be in the ranges 2 to 36.

     Unlike the corresponding `mpz' function, the base will not be
     determined from the leading characters of the string if BASE is 0.
     This is so that numbers like `0.23' are not interpreted as octal.

     Returns the number of bytes read, or if an error occurred, return
     0.

    Rmpfi_print_binary ($op);
     Outputs $op on stdout in raw binary format for each endpoint (the
     exponent is in decimal, yet).  The last bits from the least
     significant limb which do not belong to the mantissa are printed
     between square brackets; they should always be zero.

   ################################

   FUNCTIONS OPERATING ON ENDPOINTS

    $si = Rmpfi_get_left ($fr, $op); # $fr is a Math::MPFR object
     Sets $fr to the left endpoint of $op, rounded toward minus infinity.
     It returns a negative value if $fr differs from the left endpoint
     of $op (due to rounding) and 0 otherwise.

    $si = Rmpfi_get_right ($fr, $op); # $fr is a Math::MPFR object
     Sets $fr to the right endpoint of $op, rounded toward plus infinity.
     It returns a positive value if $fr differs from the right endpoint
     of $op (due to rounding) and 0 otherwise.

    The following function should never be used... but it helps to
    return correct intervals when there is a bug.

    $si = Rmpfi_revert_if_needed ($rop);
     Swaps the endpoints of $rop if they are not properly ordered, i.e.
     if the lower endpoint is greater than the right one.  It returns a
     non-zero value if the endpoints have been swapped, zero otherwise.

    $si = Rmpfi_put ($rop, $op);
    $si = Rmpfi_put_d ($rop, $double);
    $si = Rmpfi_put_ui ($rop, $ui);
    $si = Rmpfi_put_si ($rop, $si);
    $si = Rmpfi_put_z ($rop, $z);   # $z is a Math::GMP or
                                    # Math::GMPz object
    $si = Rmpfi_put_q ($rop, $q);   # $q is a Math::GMPq object
    $si = Rmpfi_put_fr ($rop, $fr); # $fr is a Math::MPFR object
     Extends the interval $rop so that it contains $op.  In other words,
     $rop is set to the convex hull of $rop and $op.  It returns a value
     indicating whether none, one or both endpoints are inexact (due to
     possible roundings).

    $si = Rmpfi_interv_d ($rop, $double1, $double2);
    $si = Rmpfi_interv_ui ($rop, $ui1, $ui2);
    $si = Rmpfi_interv_si ($rop, $si1, $si2);
    $si = Rmpfi_interv_z ($rop, $z1, $z2);   # $z1 & $z2 are Math::GMP
                                             # or Math::GMPz objects
    $si = Rmpfi_interv_q ($rop, $q1, $q2);   # $q1 & $q2 are Math::GMPq
                                             # objects
    $si = Rmpfi_interv_fr($rop, $fr1, $fr2); # $fr1 & $fr2 are
                                             # Math::MPFR objects
     Sets $rop to the interval having as endpoints the 2nd and 3rd args.
     The values of the 2nd and 3rd args are given in any order, the left
     endpoint of $rop is always the minimum of the other 2 args.
     It returns a value indicating whether none, one or both endpoints
     are inexact (due to possible roundings).

   ##########################

   SET FUNCTIONS ON INTERVALS

    $si = Rmpfi_is_strictly_inside ($op1, $op2);
     Returns a positive value if the second interval $op2 is contained in
     the interior of $op1, 0 otherwise.

    $si = Rmpfi_is_inside ($op1, $op2);
    $si = Rmpfi_is_inside_d ($double, $op);
    $si = Rmpfi_is_inside_ui ($ui, $op);
    $si = Rmpfi_is_inside_si ($si, $op);
    $si = Rmpfi_is_inside_z ($z, $op);   # $z is a Math::GMP or
                                         # or Math::GMPz object
    $si = Rmpfi_is_inside_q ($q, $op);   # $q is a Math::GMPq object
    $si = Rmpfi_is_inside_fr ($fr, $op); # $fr is a Math::MPFR object
     Returns a positive value if the value of the 1at arg is contained
     in the 2nd arg, 0 otherwise.
     Return 0 if at least one argument is NaN or an invalid interval.

    $si = Rmpfi_is_empty ($op);
     Returns a positive value if $op is empty (its endpoints are in
     reverse order) and 0 otherwise. Nothing is done in arithmetic or
     special functions to handle empty intervals: this is the
     responsibility of the user to avoid computing with empty intervals.

    $si = Rmpfi_intersect ($rop, $op1, $op2);
     Sets $rop to the intersection (possibly empty) of the intervals $op1
     and $op2.  It returns a value indicating whether none, one or both
     endpoints are inexact (due to possible roundings).  Warning: this
     function can return an empty interval (i.e. with endpoints in
     reverse order).

    $si = Rmpfi_union ($rop, $op1, $op2);
     Sets $rop to the convex hull of the union of the intervals $op1 and
     $op2.  It returns a value indicating whether none, one or both
     endpoints are inexact (due to possible roundings).

   ################################

   MISCELLANEOUS INTERVAL FUNCTIONS

    $si = Rmpfi_increase ($rop, $op);
     Subtracts $op to the lower endpoint of $rop and adds it to the upper
     endpoint of $rop, sets the resulting interval to $rop.  It returns a
     value indicating whether none, one or both endpoints are inexact.

    $si = Rmpfi_blow ($rop, $op, $double);
     Sets $rop to the interval whose center is the center of $op and
     whose radius is the radius of $op multiplied by (1 + abs($double)).
     It returns a value indicating whether none, one or both endpoints
     are inexact.

    $si = Rmpfi_bisect ($rop1, $rop2, $op);
     Splits $op into two halves and sets them to $rop1 and $rop2.  Due to
     outward rounding, the two halves $rop1 and $rop2 may overlap.  It
     returns a value >0 if the splitting point is greater than the
     exact centre, <0 if it is smaller and 0 if it is the exact centre.

    $str = Rmpfi_get_version ()
     Returns the version number of the mpfi library being used by
     Math::MPFI (as a NULL terminated string).

   $MPFR_version = Math::MPFI::mpfr_v();
    $MPFR_version is set to the version of the mpfr library
    being used by the mpfi library that Math::MPFI uses.
    (The function is not exportable.)

   $GMP_version = Math::MPFI::gmp_v();
    $GMP_version is set to the version of the gmp library being
    used by the mpfi library that Math::MPFI uses.
    (The function is not exportable.)

   $iv = Math::MPFI::nok_pokflag(); # not exported
    Returns the value of the nok_pok flag. This flag is
    initialized to zero, but incemented by 1 whenever a
    scalar that is both a float (NOK) and string (POK) is passed
    to new() or to an overloaded operator. The value of the flag
    therefore tells us how many times such events occurred . The
    flag can be reset to 0 by running clear_nok_pok().

   Math::MPFI::set_nok_pok($iv); # not exported
    Resets the nok_pok flag to the value specified by $iv.

   Math::MPFI::clear_nok_pok(); # not exported
    Resets the nok_pok flag to 0.(Essentially the same as
    running Math::MPFI::set_nok_pok(0).)

   ##############

   ERROR HANDLING

    RMPFI_ERROR ($str);
     If there is no previous error, sets the error number to 1 and
     prints the message $str to the standard error stream. If the error
     number is already set, do nothing.

    $si = Rmpfi_is_error ()
     Returns 1 if the error number is set (to 1).

    Rmpfi_set_error ($si)
     Sets the error number to $si.

    Rmpfi_reset_error ()
     Resets the error number to 0.

   ####################

   OPERATOR OVERLOADING

    Overloading works with numbers, strings and Math::MPFI objects.
    Currently, the only overloaded operators are:
     +, -, *, /, +=, -=, *=, /=,
     >, >=, <, <=, <=>,
     ==, !=,
     "", =,
     **, **=, sqrt
     atan2, cos, sin,
     log, exp,
     abs, bool, !

###############################################
###############################################

=head1 LICENSE

    This program is free software; you may redistribute it and/or
    modify it under the same terms as Perl itself.
    Copyright 2010, 2011, 2014, 2016 Sisyphus

=head1 AUTHOR

    Sisyphus <sisyphus at(@) cpan dot (.) org>

=cut
