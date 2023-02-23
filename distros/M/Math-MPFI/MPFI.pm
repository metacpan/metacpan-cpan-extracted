package Math::MPFI;
use strict;
use warnings;
use Math::MPFR;
use Math::MPFI::Constant;

require Exporter;
*import = \&Exporter::import;
require DynaLoader;

our $VERSION = '0.13';
#$VERSION = eval $VERSION;

Math::MPFI->DynaLoader::bootstrap($VERSION);

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
    use constant  MPFI_PV_NV_BUG => Math::MPFI::Constant::_has_pv_nv_bug();

    # Inspired by https://github.com/Perl/perl5/issues/19550, which affects only perl-5.35.10:
    use constant ISSUE_19550    => Math::MPFI::Constant::_issue_19550();

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
my @tagged = qw(
MPFI_PV_NV_BUG
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

@Math::MPFI::EXPORT_OK = (@tagged);
%Math::MPFI::EXPORT_TAGS =(mpfi => \@tagged);

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
    $arg1 = shift; # At this point, an infnan might acquire a POK flag - thus
                   # assigning to $type a value of 4, instead of 3. Such behaviour also
                   # turns $arg into a PV and NV dualvar. It's a fairly inconsequential
                   # bug - https://github.com/Perl/perl5/issues/19550.
                   # I could workaround this by simply not shifting and re-assigning, but
                   # I'll leave it as it is - otherwise there's nothing to mark that this
                   # minor issue (which might also show up in user code) ever existed.
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

      if(MPFI_PV_NV_BUG) {
        if(_SvPOK($arg1)) {
          set_nok_pok(nok_pokflag() + 1);
          if($Math::MPFI::NOK_POK) {
            warn "Scalar passed to new() is both NV and PV. Using NV (numeric) value";
          }
        }
      }

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

sub MPFI_VERSION_MAJOR      () {return _MPFI_VERSION_MAJOR()}
sub MPFI_VERSION_MINOR      () {return _MPFI_VERSION_MINOR()}
sub MPFI_VERSION_PATCHLEVEL () {return _MPFI_VERSION_PATCHLEVEL()}
sub MPFI_VERSION_STRING     () {return _MPFI_VERSION_STRING()}

1;

__END__

