    package Math::GMPf;
    use strict;
    use warnings;
    use Math::GMPf::Random;
    require Exporter;
    *import = \&Exporter::import;
    require DynaLoader;

    use constant _UOK_T         => 1;
    use constant _IOK_T         => 2;
    use constant _NOK_T         => 3;
    use constant _POK_T         => 4;
    use constant _MATH_MPFR_T   => 5;
    use constant _MATH_GMPf_T   => 6;
    use constant _MATH_GMPq_T   => 7;
    use constant _MATH_GMPz_T   => 8;
    use constant _MATH_GMP_T    => 9;
    use constant _MATH_MPC_T 	=> 10;
    use constant GMPF_PV_NV_BUG => Math::GMPf::Random::_has_pv_nv_bug();

    # Inspired by https://github.com/Perl/perl5/issues/19550:
    use constant ISSUE_19550    => Math::GMPf::Random::_issue_19550();

use subs qw( __GNU_MP_VERSION __GNU_MP_VERSION_MINOR __GNU_MP_VERSION_PATCHLEVEL
             __GNU_MP_RELEASE __GMP_CC __GMP_CFLAGS GMP_LIMB_BITS GMP_NAIL_BITS);

use overload
    '++'   => \&overload_inc,
    '--'   => \&overload_dec,
    '+'    => \&overload_add,
    '-'    => \&overload_sub,
    '*'    => \&overload_mul,
    '/'    => \&overload_div,
    '+='   => \&overload_add_eq,
    '-='   => \&overload_sub_eq,
    '*='   => \&overload_mul_eq,
    '/='   => \&overload_div_eq,
    '""'   => \&overload_string,
    '>'    => \&overload_gt,
    '>='   => \&overload_gte,
    '<'    => \&overload_lt,
    '<='   => \&overload_lte,
    '<=>'  => \&overload_spaceship,
    '=='   => \&overload_equiv,
    '!='   => \&overload_not_equiv,
    '!'    => \&overload_not,
    '='    => \&overload_copy,
    'abs'  => \&overload_abs,
    '**'   => \&overload_pow,
    '**='  => \&overload_pow_eq,
    'int'  => \&overload_int,
    'sqrt' => \&overload_sqrt;

    @Math::GMPf::EXPORT_OK = qw(
__GNU_MP_VERSION __GNU_MP_VERSION_MINOR __GNU_MP_VERSION_PATCHLEVEL
__GNU_MP_RELEASE __GMP_CC __GMP_CFLAGS
GMPF_PV_NV_BUG
IOK_flag NOK_flag POK_flag
Rmpf_abs Rmpf_add Rmpf_add_ui Rmpf_ceil Rmpf_clear Rmpf_clear_mpf Rmpf_clear_ptr
Rmpf_cmp Rmpf_cmp_d Rmpf_cmp_si Rmpf_cmp_ui Rmpf_cmp_NV Rmpf_cmp_IV
Rmpf_deref2 Rmpf_div Rmpf_div_2exp Rmpf_div_ui
Rmpf_eq Rmpf_fits_sint_p Rmpf_fits_slong_p Rmpf_fits_sshort_p Rmpf_fits_uint_p
Rmpf_fits_ulong_p Rmpf_fits_ushort_p Rmpf_floor Rmpf_fprintf
Rmpf_get_d Rmpf_get_d_2exp
Rmpf_get_default_prec Rmpf_get_prec Rmpf_get_si Rmpf_get_str Rmpf_get_ui
Rmpf_init Rmpf_init2 Rmpf_init2_nobless Rmpf_init_nobless Rmpf_init_set
Rmpf_init_set_d Rmpf_init_set_d_nobless Rmpf_init_set_nobless Rmpf_init_set_si
Rmpf_init_set_si_nobless Rmpf_init_set_str Rmpf_init_set_str_nobless
Rmpf_init_set_ui Rmpf_init_set_ui_nobless Rmpf_inp_str
Rmpf_init_set_NV Rmpf_init_set_IV Rmpf_init_set_NV_nobless Rmpf_init_set_IV_nobless
TRmpf_inp_str
Rmpf_integer_p Rmpf_mul
Rmpf_mul_2exp Rmpf_mul_ui Rmpf_neg Rmpf_out_str
TRmpf_out_str
Rmpf_pow_ui Rmpf_printf
Rmpf_random2 Rmpf_reldiff Rmpf_set Rmpf_set_d Rmpf_set_default_prec Rmpf_set_prec
Rmpf_set_prec_raw Rmpf_set_q Rmpf_set_si Rmpf_set_str Rmpf_set_ui Rmpf_set_z
Rmpf_sgn Rmpf_sprintf Rmpf_snprintf
Rmpf_sqrt Rmpf_sqrt_ui Rmpf_sub Rmpf_sub_ui Rmpf_swap Rmpf_trunc
Rmpf_ui_div Rmpf_ui_sub Rmpf_urandomb
fgmp_randseed fgmp_randseed_ui fgmp_randclear
fgmp_randinit_default fgmp_randinit_mt fgmp_randinit_lc_2exp fgmp_randinit_lc_2exp_size
fgmp_randinit_set fgmp_randinit_default_nobless fgmp_randinit_mt_nobless
fgmp_randinit_lc_2exp_nobless fgmp_randinit_lc_2exp_size_nobless fgmp_randinit_set_nobless
fgmp_urandomb_ui fgmp_urandomm_ui
Rmpf_get_NV Rmpf_set_NV Rmpf_get_NV_rndn Rmpf_get_d_rndn
Rmpf_get_IV Rmpf_set_IV Rmpf_fits_IV_p
    );
    our $VERSION = '0.48';
    #$VERSION = eval $VERSION;

    Math::GMPf->DynaLoader::bootstrap($VERSION);

    %Math::GMPf::EXPORT_TAGS =(mpf => [qw(
GMPF_PV_NV_BUG
Rmpf_abs Rmpf_add Rmpf_add_ui Rmpf_ceil Rmpf_clear Rmpf_clear_mpf Rmpf_clear_ptr
Rmpf_cmp Rmpf_cmp_d Rmpf_cmp_si Rmpf_cmp_ui Rmpf_cmp_NV Rmpf_cmp_IV
Rmpf_deref2 Rmpf_div Rmpf_div_2exp Rmpf_div_ui
Rmpf_eq Rmpf_fits_sint_p Rmpf_fits_slong_p Rmpf_fits_sshort_p Rmpf_fits_uint_p
Rmpf_fits_ulong_p Rmpf_fits_ushort_p Rmpf_floor Rmpf_fprintf
Rmpf_get_d Rmpf_get_d_2exp
Rmpf_get_default_prec Rmpf_get_prec Rmpf_get_si Rmpf_get_str Rmpf_get_ui
Rmpf_init Rmpf_init2 Rmpf_init2_nobless Rmpf_init_nobless Rmpf_init_set
Rmpf_init_set_d Rmpf_init_set_d_nobless Rmpf_init_set_nobless Rmpf_init_set_si
Rmpf_init_set_si_nobless Rmpf_init_set_str Rmpf_init_set_str_nobless
Rmpf_init_set_ui Rmpf_init_set_ui_nobless Rmpf_inp_str
Rmpf_init_set_NV Rmpf_init_set_IV Rmpf_init_set_NV_nobless Rmpf_init_set_IV_nobless
TRmpf_inp_str
Rmpf_integer_p Rmpf_mul
Rmpf_mul_2exp Rmpf_mul_ui Rmpf_neg Rmpf_out_str
TRmpf_out_str
Rmpf_pow_ui Rmpf_printf
Rmpf_random2 Rmpf_reldiff Rmpf_set Rmpf_set_d Rmpf_set_default_prec Rmpf_set_prec
Rmpf_set_prec_raw Rmpf_set_q Rmpf_set_si Rmpf_set_str Rmpf_set_ui Rmpf_set_z
Rmpf_sgn Rmpf_sprintf Rmpf_snprintf
Rmpf_sqrt Rmpf_sqrt_ui Rmpf_sub Rmpf_sub_ui Rmpf_swap Rmpf_trunc
Rmpf_ui_div Rmpf_ui_sub Rmpf_urandomb
fgmp_randseed fgmp_randseed_ui fgmp_randclear
fgmp_randinit_default fgmp_randinit_mt fgmp_randinit_lc_2exp fgmp_randinit_lc_2exp_size
fgmp_randinit_set fgmp_randinit_default_nobless fgmp_randinit_mt_nobless
fgmp_randinit_lc_2exp_nobless fgmp_randinit_lc_2exp_size_nobless fgmp_randinit_set_nobless
fgmp_urandomb_ui fgmp_urandomm_ui
Rmpf_get_NV Rmpf_set_NV Rmpf_get_NV_rndn Rmpf_get_d_rndn
Rmpf_get_IV Rmpf_set_IV  Rmpf_fits_IV_p
)]);

$Math::GMPf::NOK_POK = 0; # Set to 1 to allow warnings in new() and overloaded operations when
                          # a scalar that has set both NOK (NV) and POK (PV) flags is encountered

sub dl_load_flags {0} # Prevent DynaLoader from complaining and croaking

sub new {

    # This function caters for 2 possibilities:
    # 1) that 'new' has been called OOP style - in which
    #    case there will be a maximum of 3 args
    # 2) that 'new' has been called as a function - in
    #    which case there will be a maximum of 2 args.
    # If there are no args, then we just want to return an
    # initialized Math::GMPf object
    if(!@_) {return Rmpf_init()}

    if(@_ > 3) {die "Too many arguments supplied to new()"}

    # If 'new' has been called OOP style, the first arg is the string
    # "Math::GMPf" which we don't need - so let's remove it. However,
    # if the first arg is a Math::GMPf object (which is a possibility),
    # then we'll get a fatal error when we check it for equivalence to
    # the string "Math::GMPf". So we first need to check that it's not
    # an object - which we'll do by using the ref() function:
    if(!ref($_[0]) && $_[0] eq "Math::GMPf") {
      shift;
      if(!@_) {return Rmpf_init()}
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
    $base = 10;

    $type = _itsa($arg1);
    if(!$type) {die "Inappropriate argument supplied to new()"}

    # Create a Math::GMPz object that has $arg1 as its value.
    # Die if there are any additional args (unless $type == 4)
    if($type == _UOK_T || $type == _IOK_T) {
      if(@_ ) {die "Too many arguments supplied to new() - expected only one"}
      return Rmpf_init_set_IV($arg1);
    }

    if($type == _POK_T) {
      if(@_ > 1) {die "Too many arguments supplied to new() - expected no more than two"}
      if(_SvNOK($arg1)) {
        set_nok_pok(nok_pokflag() + 1);
        if($Math::GMPf::NOK_POK) {
          warn "Scalar passed to new() is both NV and PV. Using PV (string) value";
        }
      }
      $base = shift if @_;
      if(($base < 2 && $base > -2) || $base < -62 || $base > 62) {die "Invalid value for base"}
      return Rmpf_init_set_str($arg1, $base);
    }

    if($type == _NOK_T) {
      if(@_ ) {die "Too many arguments supplied to new() - expected only one"}

      if(GMPF_PV_NV_BUG) {
        if(_SvPOK($arg1)) {
          set_nok_pok(nok_pokflag() + 1);
          if($Math::GMPf::NOK_POK) {
            warn "Scalar passed to new() is both NV and PV. Using NV (numeric) value";
          }
        }
      }

      return Rmpf_init_set_NV($arg1);
    }

    if($type == _MATH_GMPf_T) {
      if(@_) {die "Too many arguments supplied to new() - expected only one"}
      return Rmpf_init_set($arg1);
    }
}

sub Rmpf_out_str {
    if(@_ == 3) {
       die "Inappropriate 1st arg supplied to Rmpf_out_str" if _itsa($_[0]) != _MATH_GMPf_T;
       return _Rmpf_out_str($_[0], $_[1], $_[2]);
    }
    if(@_ == 4) {
      if(_itsa($_[0]) == _MATH_GMPf_T) {return _Rmpf_out_strS($_[0], $_[1], $_[2], $_[3])}
      die "Incorrect args supplied to Rmpf_out_str" if _itsa($_[1]) != _MATH_GMPf_T;
      return _Rmpf_out_strP($_[0], $_[1], $_[2], $_[3]);
    }
    if(@_ == 5) {
      die "Inappropriate 2nd arg supplied to Rmpf_out_str" if _itsa($_[1]) != _MATH_GMPf_T;
      return _Rmpf_out_strPS($_[0], $_[1], $_[2], $_[3], $_[4]);
    }
    die "Wrong number of arguments supplied to Rmpf_out_str()";
}

sub TRmpf_out_str {
    if(@_ == 4) {
      die "Inappropriate 4th arg supplied to TRmpf_out_str" if _itsa($_[3]) != _MATH_GMPf_T;
      return _TRmpf_out_str($_[0], $_[1], $_[2], $_[3]);
    }
    if(@_ == 5) {
      if(_itsa($_[3]) == _MATH_GMPf_T) {return _TRmpf_out_strS($_[0], $_[1], $_[2], $_[3], $_[4])}
      die "Incorrect args supplied to TRmpf_out_str" if _itsa($_[4]) != _MATH_GMPf_T;
      return _TRmpf_out_strP($_[0], $_[1], $_[2], $_[3], $_[4]);
    }
    if(@_ == 6) {
      die "Inappropriate 5th arg supplied to TRmpf_out_str" if _itsa($_[4]) != _MATH_GMPf_T;
      return _TRmpf_out_strPS($_[0], $_[1], $_[2], $_[3], $_[4], $_[5]);
    }
    die "Wrong number of arguments supplied to TRmpf_out_str()";
}

sub Rmpf_get_str {
    my $sep = $_[1] <=10 ? 'e' : '@';
    my ($mantissa, $exponent) = Rmpf_deref2($_[0], $_[1], $_[2]);

    if($mantissa =~ /\-/ && $mantissa !~ /[^0,\-]/) {return '-0'}
    if($mantissa !~ /[^0]/ || $mantissa eq '' ) {return '0'}

    if(substr($mantissa, 0, 1) eq '-') {
       substr($mantissa, 0, 1, '');
       return "-0." . $mantissa . $sep . $exponent if $exponent;
       return "-0." . $mantissa;
       }
    return "0." . $mantissa . $sep . $exponent if $exponent;
    return "0." . $mantissa;
}

sub overload_string {
    return Rmpf_get_str($_[0], 10, 0);
}

sub _rewrite {
    my $len = length($_[0]);
    my @split = ();
    my @ret = ();
    for(my $i = 0; $i < $len - 1; $i++) {
       if(substr($_[0], $i, 1) eq '%') {
         if(substr($_[0], $i + 1, 1) eq '%') { $i++ }
         else { push(@split, $i) }
         }
       }

    push(@split, $len);
    shift(@split);

    my $start = 0;

    for(@split) {
       push(@ret, substr($_[0], $start, $_ - $start));
       $start = $_;
       }

    return @ret;
}

sub Rmpf_printf {
    local $| = 1;
    push @_, 0 if @_ == 1; # add a dummy second argument
    die "Rmpf_printf must pass 2 arguments: format string, and variable" if @_ != 2;
    wrap_gmp_printf(@_);
}

sub Rmpf_fprintf {
    push @_, 0 if @_ == 2; # add a dummy third argument
    die "Rmpf_fprintf must pass 3 arguments: filehandle, format string, and variable" if @_ != 3;
    wrap_gmp_fprintf(@_);
}

sub Rmpf_sprintf {
    my $len;

    if(@_ == 3) {      # optional arg wasn't provided
      $len = wrap_gmp_sprintf($_[0], $_[1], 0, $_[2]);  # Set missing arg to 0
    }
    else {
      die "Rmpf_sprintf must pass 4 arguments: buffer, format string, variable, buflen" if @_ != 4;
      $len = wrap_gmp_sprintf(@_);
    }

    return $len;
}

sub Rmpf_snprintf {
    my $len;

    if(@_ == 4) {      # optional arg wasn't provided
      $len = wrap_gmp_snprintf($_[0], $_[1], $_[2], 0, $_[3]);  # Set missing arg to 0
    }
    else {
      die "Rmpf_snprintf must pass 5 arguments: buffer, bytes written, format string, variable and buflen" if @_ != 5;
      $len = wrap_gmp_snprintf(@_);
    }

    return $len;
}

# _Rmpz_get_IV may have returned a "string" - in which case we want to coerce it
# to an IV. It may be more efficient to do this in XS space (TODO), but in the
# meantime I've taken the soft option of having perl perform the coercion:

sub Rmpf_get_IV {
   my $ret = _Rmpf_get_IV(shift);
   $ret += 0 unless _SvIOK($ret); # Set the IV flag
   return $ret;
}

sub __GNU_MP_VERSION            () {return ___GNU_MP_VERSION()}
sub __GNU_MP_VERSION_MINOR      () {return ___GNU_MP_VERSION_MINOR()}
sub __GNU_MP_VERSION_PATCHLEVEL () {return ___GNU_MP_VERSION_PATCHLEVEL()}
sub __GNU_MP_RELEASE            () {return ___GNU_MP_RELEASE()}
sub __GMP_CC                    () {return ___GMP_CC()}
sub __GMP_CFLAGS                () {return ___GMP_CFLAGS()}
sub GMP_LIMB_BITS               () {return _GMP_LIMB_BITS()}
sub GMP_NAIL_BITS               () {return _GMP_NAIL_BITS()}

*fgmp_randseed =                      \&Math::GMPf::Random::Rgmp_randseed;
*fgmp_randseed_ui =                   \&Math::GMPf::Random::Rgmp_randseed_ui;
*fgmp_randclear =                     \&Math::GMPf::Random::Rgmp_randclear;
*fgmp_randinit_default =              \&Math::GMPf::Random::Rgmp_randinit_default;
*fgmp_randinit_mt =                   \&Math::GMPf::Random::Rgmp_randinit_mt;
*fgmp_randinit_lc_2exp =              \&Math::GMPf::Random::Rgmp_randinit_lc_2exp;
*fgmp_randinit_lc_2exp_size =         \&Math::GMPf::Random::Rgmp_randinit_lc_2exp_size;
*fgmp_randinit_set =                  \&Math::GMPf::Random::Rgmp_randinit_set;
*fgmp_randinit_default_nobless =      \&Math::GMPf::Random::Rgmp_randinit_default_nobless;
*fgmp_randinit_mt_nobless =           \&Math::GMPf::Random::Rgmp_randinit_mt_nobless;
*fgmp_randinit_lc_2exp_nobless =      \&Math::GMPf::Random::Rgmp_randinit_lc_2exp_nobless;
*fgmp_randinit_lc_2exp_size_nobless = \&Math::GMPf::Random::Rgmp_randinit_lc_2exp_size_nobless;
*fgmp_randinit_set_nobless =          \&Math::GMPf::Random::Rgmp_randinit_set_nobless;
*fgmp_urandomb_ui =                   \&Math::GMPf::Random::Rgmp_urandomb_ui;
*fgmp_urandomm_ui =                   \&Math::GMPf::Random::Rgmp_urandomm_ui;

1;

__END__

