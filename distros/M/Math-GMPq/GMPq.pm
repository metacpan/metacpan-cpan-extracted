    package Math::GMPq;
    use strict;
    use warnings;
    use Math::GMPq::Random;
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
    use constant _MATH_MPC_T    => 10;
    use constant GMPQ_PV_NV_BUG => Math::GMPq::Random::_has_pv_nv_bug();

use subs qw( __GNU_MP_VERSION __GNU_MP_VERSION_MINOR __GNU_MP_VERSION_PATCHLEVEL
             __GNU_MP_RELEASE __GMP_CC __GMP_CFLAGS GMP_LIMB_BITS GMP_NAIL_BITS);

use overload
    '++'   => \&overload_inc,
    '--'   => \&overload_dec,
    '+'    => \&overload_add,
    '-'    => \&overload_sub,
    '*'    => \&overload_mul,
    '/'    => \&overload_div,
    '**'   => \&overload_pow,
    '+='   => \&overload_add_eq,
    '-='   => \&overload_sub_eq,
    '*='   => \&overload_mul_eq,
    '/='   => \&overload_div_eq,
    '**='  => \&overload_pow_eq,
    '""'   => \&overload_string,
    '0+'   => \&overload_num,
    '>'    => \&overload_gt,
    '>='   => \&overload_gte,
    '<'    => \&overload_lt,
    '<='   => \&overload_lte,
    '<=>'  => \&overload_spaceship,
    '=='   => \&overload_equiv,
    '!='   => \&overload_not_equiv,
    '!'    => \&overload_not,
    '='    => \&overload_copy,
    'int'  => \&overload_int,
    'abs'  => \&overload_abs;

    my @untagged = qw(
__GNU_MP_VERSION __GNU_MP_VERSION_MINOR __GNU_MP_VERSION_PATCHLEVEL
__GNU_MP_RELEASE __GMP_CC __GMP_CFLAGS
IOK_flag NOK_flag POK_flag
    );

my @tagged = qw(
GMPQ_PV_NV_BUG
Rmpq_abs Rmpq_add Rmpq_canonicalize Rmpq_clear Rmpq_cmp Rmpq_cmp_si Rmpq_cmp_ui
Rmpq_cmp_z Rmpq_add_z Rmpq_sub_z Rmpq_z_sub Rmpq_mul_z Rmpq_div_z Rmpq_z_div
Rmpq_pow_ui
Rmpq_create_noval Rmpq_denref Rmpq_div Rmpq_div_2exp Rmpq_equal
Rmpq_fprintf
Rmpq_get_d
Rmpq_get_den Rmpq_get_num Rmpq_get_str Rmpq_init Rmpq_init_nobless Rmpq_inp_str
Rmpq_inv Rmpq_mul Rmpq_mul_2exp Rmpq_neg Rmpq_numref Rmpq_out_str Rmpq_printf
Rmpq_set Rmpq_set_d Rmpq_set_den Rmpq_set_f Rmpq_set_num Rmpq_set_si Rmpq_set_str
Rmpq_set_NV Rmpq_get_NV Rmpq_cmp_NV
Rmpq_set_IV Rmpq_cmp_IV
Rmpq_set_ui Rmpq_set_z Rmpq_sgn
Rmpq_sprintf Rmpq_snprintf
Rmpq_sub Rmpq_swap
Rmpq_integer_p
TRmpq_out_str TRmpq_inp_str
qgmp_randseed qgmp_randseed_ui qgmp_randclear
qgmp_randinit_default qgmp_randinit_mt qgmp_randinit_lc_2exp qgmp_randinit_lc_2exp_size
qgmp_randinit_set qgmp_randinit_default_nobless qgmp_randinit_mt_nobless
qgmp_randinit_lc_2exp_nobless qgmp_randinit_lc_2exp_size_nobless qgmp_randinit_set_nobless
qgmp_urandomb_ui qgmp_urandomm_ui
    );

    @Math::GMPq::EXPORT_OK = (@untagged, @tagged);
    our $VERSION = '0.55';
    #$VERSION = eval $VERSION;

    Math::GMPq->DynaLoader::bootstrap($VERSION);

    %Math::GMPq::EXPORT_TAGS =(mpq => \@tagged);

sub dl_load_flags {0} # Prevent DynaLoader from complaining and croaking

    $Math::GMPq::RETYPE = 0; # set to 1 to enable a Math::GMPq object to be coerced to
                             # a Math::MPFR object in certain overloaded operations.
                             # (See the 'OPERATOR OVERLOADING' section of the POD
                             # documentation for details.)
                             # With this variable set to 0, these "certain overloaded
                             # operations" alluded to will throw a fatal error.

sub new {

    # This function caters for 2 possibilities:
    # 1) that 'new' has been called OOP style - in which
    #    case there will be a maximum of 3 args
    # 2) that 'new' has been called as a function - in
    #    which case there will be a maximum of 2 args.
    # If there are no args, then we just want to return an
    # initialized Math::GMPq
    if(!@_) {return Rmpq_init()}

    if(@_ > 3) {die "Too many arguments supplied to new()"}

    # If 'new' has been called OOP style, the first arg is the string
    # "Math::GMPq" which we don't need - so let's remove it. However,
    # if the first arg is a Math::GMPq object (which is a possibility),
    # then we'll get a fatal error when we check it for equivalence to
    # the string "Math::GMPq". So we first need to check that it's not
    # an object - which we'll do by using the ref() function:
    if(!ref($_[0]) && Math::GMPq::_SvPOK($_[0]) && $_[0] eq "Math::GMPq") {
      shift;
      if(!@_) {return Rmpq_init()}
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

    my $ret = Rmpq_init();

    # Create a Math::GMPq object that has $arg1 as its value.
    # Die if there are any additional args (unless $type == _POK_T)
    if($type == _UOK_T || $type == _IOK_T) {
      if(@_ ) {die "Too many arguments supplied to new() - expected only one"}
      Rmpq_set_str($ret, $arg1, 10);
      return $ret;
    }

    if($type == _NOK_T) {
      if(@_ ) {die "Too many arguments supplied to new() - expected only one"}
      Rmpq_set_NV($ret, $arg1);
      return $ret;
    }

    if($type == _POK_T) {
      if(@_ > 1) {die "Too many arguments supplied to new() - expected no more than two"}
      $base = shift if @_;
      if(($base < 2 && $base != 0) || $base > 62) {die "Invalid value for base"}
      Rmpq_set_str($ret, $arg1, $base);
      Rmpq_canonicalize($ret);
      return $ret;
    }

    if($type == _MATH_GMPq_T) { # Math::GMPq object
      if(@_) {die "Too many arguments supplied to new() - expected only one"}
      Rmpq_set($ret, $arg1);
      return $ret;
    }
}

sub Rmpq_out_str {
    if(@_ == 2) {
       die "Inappropriate 1st arg supplied to Rmpq_out_str" if _itsa($_[0]) != _MATH_GMPq_T;
       return _Rmpq_out_str($_[0], $_[1]);
    }
    if(@_ == 3) {
      if(_itsa($_[0]) == _MATH_GMPq_T) {return _Rmpq_out_strS($_[0], $_[1], $_[2])}
      die "Incorrect args supplied to Rmpq_out_str" if _itsa($_[1]) != _MATH_GMPq_T;
      return _Rmpq_out_strP($_[0], $_[1], $_[2]);
    }
    if(@_ == 4) {
      die "Inappropriate 2nd arg supplied to Rmpq_out_str" if _itsa($_[1]) != _MATH_GMPq_T;
      return _Rmpq_out_strPS($_[0], $_[1], $_[2], $_[3]);
    }
    die "Wrong number of arguments supplied to Rmpq_out_str()";
}

sub TRmpq_out_str {
    if(@_ == 3) {
      die "Inappropriate 3rd arg supplied to TRmpq_out_str" if _itsa($_[2]) != _MATH_GMPq_T;
      return _TRmpq_out_str($_[0], $_[1], $_[2]);
    }
    if(@_ == 4) {
      if(_itsa($_[2]) == _MATH_GMPq_T) {return _TRmpq_out_strS($_[0], $_[1], $_[2], $_[3])}
      die "Incorrect args supplied to TRmpq_out_str" if _itsa($_[3]) != _MATH_GMPq_T;
      return _TRmpq_out_strP($_[0], $_[1], $_[2], $_[3]);
    }
    if(@_ == 5) {
      die "Inappropriate 4th arg supplied to TRmpq_out_str" if _itsa($_[3]) != _MATH_GMPq_T;
      return _TRmpq_out_strPS($_[0], $_[1], $_[2], $_[3], $_[4]);
    }
    die "Wrong number of arguments supplied to TRmpq_out_str()";
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

sub Rmpq_printf {
    local $| = 1;
    push @_, 0 if @_ == 1; # add a dummy second argument
    die "Rmpz_printf must pass 2 arguments: format string, and variable" if @_ != 2;
    wrap_gmp_printf(@_);
}

sub Rmpq_fprintf {
    push @_, 0 if @_ == 2; # add a dummy third argument
    die "Rmpq_fprintf must pass 3 arguments: filehandle, format string, and variable" if @_ != 3;
    wrap_gmp_fprintf(@_);
}

sub Rmpq_sprintf {
    my $len;

    if(@_ == 3) {      # optional arg wasn't provided
      $len = wrap_gmp_sprintf($_[0], $_[1], 0, $_[2]);  # Set missing arg to 0
    }
    else {
      die "Rmpq_sprintf must pass 4 arguments: buffer, format string, variable, buflen" if @_ != 4;
      $len = wrap_gmp_sprintf(@_);
    }

    return $len;
}

sub Rmpq_snprintf {
    my $len;

    if(@_ == 4) {      # optional arg wasn't provided
      $len = wrap_gmp_snprintf($_[0], $_[1], $_[2], 0, $_[3]);  # Set missing arg to 0
    }
    else {
      die "Rmpq_snprintf must pass 5 arguments: buffer, bytes written, format string, variable and buflen" if @_ != 5;
      $len = wrap_gmp_snprintf(@_);
    }

    return $len;
}

sub __GNU_MP_VERSION            () {return ___GNU_MP_VERSION()}
sub __GNU_MP_VERSION_MINOR      () {return ___GNU_MP_VERSION_MINOR()}
sub __GNU_MP_VERSION_PATCHLEVEL () {return ___GNU_MP_VERSION_PATCHLEVEL()}
sub __GNU_MP_RELEASE            () {return ___GNU_MP_RELEASE()}
sub __GMP_CC                    () {return ___GMP_CC()}
sub __GMP_CFLAGS                () {return ___GMP_CFLAGS()}
sub GMP_LIMB_BITS               () {return _GMP_LIMB_BITS()}
sub GMP_NAIL_BITS               () {return _GMP_NAIL_BITS()}

*qgmp_randseed =                      \&Math::GMPq::Random::Rgmp_randseed;
*qgmp_randseed_ui =                   \&Math::GMPq::Random::Rgmp_randseed_ui;
*qgmp_randclear =                     \&Math::GMPq::Random::Rgmp_randclear;
*qgmp_randinit_default =              \&Math::GMPq::Random::Rgmp_randinit_default;
*qgmp_randinit_mt =                   \&Math::GMPq::Random::Rgmp_randinit_mt;
*qgmp_randinit_lc_2exp =              \&Math::GMPq::Random::Rgmp_randinit_lc_2exp;
*qgmp_randinit_lc_2exp_size =         \&Math::GMPq::Random::Rgmp_randinit_lc_2exp_size;
*qgmp_randinit_set =                  \&Math::GMPq::Random::Rgmp_randinit_set;
*qgmp_randinit_default_nobless =      \&Math::GMPq::Random::Rgmp_randinit_default_nobless;
*qgmp_randinit_mt_nobless =           \&Math::GMPq::Random::Rgmp_randinit_mt_nobless;
*qgmp_randinit_lc_2exp_nobless =      \&Math::GMPq::Random::Rgmp_randinit_lc_2exp_nobless;
*qgmp_randinit_lc_2exp_size_nobless = \&Math::GMPq::Random::Rgmp_randinit_lc_2exp_size_nobless;
*qgmp_randinit_set_nobless =          \&Math::GMPq::Random::Rgmp_randinit_set_nobless;
*qgmp_urandomb_ui =                   \&Math::GMPq::Random::Rgmp_urandomb_ui;
*qgmp_urandomm_ui =                   \&Math::GMPq::Random::Rgmp_urandomm_ui;

1;

__END__

