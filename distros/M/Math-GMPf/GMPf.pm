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
    use constant _MATH_MPC_T    => 10;

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
Rmpf_abs Rmpf_add Rmpf_add_ui Rmpf_ceil Rmpf_clear Rmpf_clear_mpf Rmpf_clear_ptr
Rmpf_cmp Rmpf_cmp_d Rmpf_cmp_si Rmpf_cmp_ui
Rmpf_deref2 Rmpf_div Rmpf_div_2exp Rmpf_div_ui
Rmpf_eq Rmpf_fits_sint_p Rmpf_fits_slong_p Rmpf_fits_sshort_p Rmpf_fits_uint_p
Rmpf_fits_ulong_p Rmpf_fits_ushort_p Rmpf_floor Rmpf_fprintf
Rmpf_get_d Rmpf_get_d_2exp
Rmpf_get_default_prec Rmpf_get_prec Rmpf_get_si Rmpf_get_str Rmpf_get_ui
Rmpf_init Rmpf_init2 Rmpf_init2_nobless Rmpf_init_nobless Rmpf_init_set
Rmpf_init_set_d Rmpf_init_set_d_nobless Rmpf_init_set_nobless Rmpf_init_set_si
Rmpf_init_set_si_nobless Rmpf_init_set_str Rmpf_init_set_str_nobless
Rmpf_init_set_ui Rmpf_init_set_ui_nobless Rmpf_inp_str
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
Rmpf_get_NV Rmpf_set_NV
Rmpf_get_IV Rmpf_set_IV Rmpf_fits_UV_p Rmpf_fits_IV_p
    );
    our $VERSION = '0.42';
    #$VERSION = eval $VERSION;

    DynaLoader::bootstrap Math::GMPf $VERSION;

    %Math::GMPf::EXPORT_TAGS =(mpf => [qw(
Rmpf_abs Rmpf_add Rmpf_add_ui Rmpf_ceil Rmpf_clear Rmpf_clear_mpf Rmpf_clear_ptr
Rmpf_cmp Rmpf_cmp_d Rmpf_cmp_si Rmpf_cmp_ui
Rmpf_deref2 Rmpf_div Rmpf_div_2exp Rmpf_div_ui
Rmpf_eq Rmpf_fits_sint_p Rmpf_fits_slong_p Rmpf_fits_sshort_p Rmpf_fits_uint_p
Rmpf_fits_ulong_p Rmpf_fits_ushort_p Rmpf_floor Rmpf_fprintf
Rmpf_get_d Rmpf_get_d_2exp
Rmpf_get_default_prec Rmpf_get_prec Rmpf_get_si Rmpf_get_str Rmpf_get_ui
Rmpf_init Rmpf_init2 Rmpf_init2_nobless Rmpf_init_nobless Rmpf_init_set
Rmpf_init_set_d Rmpf_init_set_d_nobless Rmpf_init_set_nobless Rmpf_init_set_si
Rmpf_init_set_si_nobless Rmpf_init_set_str Rmpf_init_set_str_nobless
Rmpf_init_set_ui Rmpf_init_set_ui_nobless Rmpf_inp_str
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
Rmpf_get_NV Rmpf_set_NV
Rmpf_get_IV Rmpf_set_IV Rmpf_fits_UV_p Rmpf_fits_IV_p
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
    $arg1 = shift;
    $base = 10;

    $type = _itsa($arg1);
    if(!$type) {die "Inappropriate argument supplied to new()"}

    # Create a Math::GMPz object that has $arg1 as its value.
    # Die if there are any additional args (unless $type == 4)
    if($type == _UOK_T || $type == _IOK_T) {
      if(@_ ) {die "Too many arguments supplied to new() - expected only one"}
      return Rmpf_init_set_str($arg1, 10);
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
      if(Math::GMPf::_has_longdouble()) {
        my $ret = Rmpf_init();
        _Rmpf_set_ld($ret, $arg1);
        return $ret;
      }
      return Rmpf_init_set_d($arg1);
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

sub __GNU_MP_VERSION {return ___GNU_MP_VERSION()}
sub __GNU_MP_VERSION_MINOR {return ___GNU_MP_VERSION_MINOR()}
sub __GNU_MP_VERSION_PATCHLEVEL {return ___GNU_MP_VERSION_PATCHLEVEL()}
sub __GNU_MP_RELEASE {return ___GNU_MP_RELEASE()}
sub __GMP_CC {return ___GMP_CC()}
sub __GMP_CFLAGS {return ___GMP_CFLAGS()}
sub GMP_LIMB_BITS {return _GMP_LIMB_BITS()}
sub GMP_NAIL_BITS {return _GMP_NAIL_BITS()}

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

=head1 NAME

   Math::GMPf - perl interface to the GMP library's floating point (mpf) functions.

=head1 DEPENDENCIES

   This module needs the GMP C library - available from:
   http://gmplib.org

=head1 DESCRIPTION

   A bigfloat module utilising the Gnu MP (GMP) library.
   Basically this module simply wraps all of the 'mpf'
   floating point functions provided by that library.
   The documentation below extensively plagiarises the
   GMP documentation at http://gmplib.org .
   See the Math::GMPf test suite for some examples
   of usage.

=head1 SYNOPSIS

   use Math::GMPf qw(:mpf);

   my $string = '.123542@2'; # mantissa = (.)12345
                         # exponent = 2
   # my $string = '12.354'; # alternative string format

   my $base = 10;

   # Set the default precision to at least 80 bits.
   Rmpf_set_default_prec(80);

   # Create the Math::GMPf object
   my $bn1 = Rmpf_init_set_str($string, $base);

   # Create another Math::GMPf object that holds
   # an initial value of zero, but with at least
   # 131 bits of precision.
   my $bn2 = Rmpf_init2(131);

   # Create another Math::GMPf object that holds
   # an initial value of zero, with default precision.
   my $bn3 = Rmpf_init();

   # Or just use the new() function:
   my $bn4 = Math::GMPf->new(116.8129);

   # Perform some operations ... see 'FUNCTIONS' below.

   .
   .

   # print out the value held by $bn1 (in octal):
   print Rmpf_get_str($bn1, 8, 0), "\n";

   # print out the value held by $bn1 (in decimal):
   print Rmpf_get_str($bn1, 10, 0);

   # print out the value held by $bn1 (in base 29)
   # using the (alternative) TRmpf_out_str()
   # function. (This function doesn't print a newline.)
   TRmpf_out_str(*STDOUT, 29, 0, $bn1);

=head1 MEMORY MANAGEMENT

   Objects created with Rmpf_init* functions have been
   blessed into package Math::GMPf. They will
   therefore be automatically cleaned up by the
   DESTROY() function whenever they go out of scope.

   For each Rmpf_init* fnction there is a corresponding
   Rmpf_init*_nobless function. If you wish you can
   create unblessed objects using these functions.
   It will then be up to you to clean up the memory
   associated with these objects by calling
   Rmpf_clear($op), for each object. Alternatively the objects
   will be cleaned up when the script ends. I don't know
   why you would want to create unblessed objects. The
   point is that you can if you want to.

=head1 FUNCTIONS

   See the GMP documentation at http://gmplib.org

   These next 3 functions are demonstrated above:
   $rop   = Rmpf_init_set_str($str, $base); # 1 < abs($base) < 63
   $rop   = Rmpf_init2($bits); # $bits > 0
   $str = Rmpf_get_str($r, $base, $digits); # 1 < abs($base) < 63
   The third argument to Rmpf_get_str() specifies the number
   of digits required to be output. Up to $digits digits
   will be generated.  Trailing zeros are not returned.  No
   more digits than can be accurately represented by OP are
   ever generated.  If $digits is 0 then that accurate
   maximum number of digits are generated.

   The following functions are simply wrappers around a GMP
   function of the same name. eg. Rmpf_swap() is a wrapper around
   mpf_swap() which is fully documented in the GMP manual at
   http://gmplib.org.

   "$rop", "$op1", "$op2", etc. are simply Math::GMPf objects
   - the return value of one of the Rmpf_init* functions
   (or their '_nobless' counterpart).
   They are in fact references to GMP structures.
   The "$rop" argument(s) contain the result(s) of the calculation
   being done, the "$op" argument(s) being the input(s) into that
   calculation.
   Generally, $rop, $op1, $op2, etc. can be the same perl variable,
   though usually they will be distinct perl variables referencing
   distinct GMP structures.
   Eg. something like Rmpf_add($r1, $r1, $r1),
   where $r1 *is* the same reference to the same GMP structure,
   would add $r1 to itself and store the result in $r1. Think of it
   as $r1 += $r1. Otoh, Rmpf_add($r1, $r2, $r3), where each of the
   arguments is a different reference to a different GMP structure
   would add $r2 to $r3 and store the result in $r1. Think of it as
   $r1 = $r2 + $r3. Mostly, the first argument is the argument that
   stores the result and subsequent arguments provide the input values.
   Exceptions to this can be found in some of the functions that
   actually return a value.
   Like I say, see the GMP manual for details. I hope it's
   intuitively obvious or quickly becomes so. Also see the test
   suite that comes with the distro for some examples of usage.

   "$ui" means any integer that will fit into a C 'unsigned long int'.

   "$si" means any integer that will fit into a C 'signed long int'.

   "$double" means any number (not necessarily integer) that will fit
   into a C 'double

   "$bool" means a value (usually a 'signed long int') in which
   the only interest is whether it's true or false.

   "$str" simply means a string of symbols that represent a number,
   eg "1234567890987654321234567@7" which might be a base 10 number,
   or "zsa34760sdfgq123r5@11" which would have to represent at least
   a base 36 number (because "z" is a valid digit only in bases 36
   or higher). Valid bases for GMP numbers are 2 to 62 (inclusive).

   ########################

   INITIALIZATION FUNCTIONS

   Normally, a variable should be initialized once only or at least be
   cleared, using `Rmpf_clear', between initializations.
   'DESTROY' (which calls 'Rmpf_clear') is automatically called on
   blessed objects whenever they go out of scope.

   First read the section 'MEMORY MANAGEMENT' (above).

   $bits = Rmpf_get_default_prec();
    Return the current default default precision.

   Rmpf_set_default_prec($bits);
    Set the default precision to be *at least* $bits bits.  All
    subsequent calls to `Rmpf_init' will use this precision, but
    previously initialized variables are unaffected.

   $rop = Math::GMPf::new();
   $rop = Math::GMPf->new();
   $rop = new Math::GMPf();
   $rop = Rmpf_init();
   $rop = Rmpf_init_nobless();
    Initialize $rop to 0. The precision of $rop is undefined
    unless a default precision has already been established by
    a call to `Rmpf_set_default_prec'.

   $rop = Rmpf_init2($bits);
   $rop = Rmpf_init2_nobless($bits);
     Initialize $rop to 0 and set its precision to be
     *at least* $bits bits.

   $bits = Rmpf_get_prec($op);
    Return the current precision of $op, in bits.

   Rmpf_set_prec($rop, $bits);
    Set the precision of $rop to be *at least* $bits bits.
    The value in $rop will be truncated to the new precision.
    This function requires internal reallocation of memory,
    and so should not be used in a tight loop.

   Rmpf_set_prec_raw($rop, $bits);
    Set the precision of $rop to be *at least* $bits bits, without
    changing the memory allocated. $bits must be no more than the
    allocated precision for $rop, that being the precision when $rop
    was initialized, or in the most recent `Rmpf_set_prec'.
    The value in $rop is unchanged, and in particular if it had a
    higher precision than $bits it will retain that higher precision
    New values written to $rop will use the new value $bits.
    Before calling `Rmpf_clear' (which will happen when a blessed
    Math::GMPf object goes out of scope) or the full `Rmpf_set_prec',
    another `Rmpf_set_prec_raw' call must be made to restore $rop to
    its original allocated precision.  Failing to do so will have
    unpredictable results.
    `Rmpf_get_prec' can be used before `Rmpf_set_prec_raw' to get the
    original allocated precision.  After `Rmpf_set_prec_raw' it
    reflects the $bits value set.
    `Rmpf_set_prec_raw' is an efficient way to use a Math::GMPf
    object at different precisions during a calculation, perhaps to
    gradually increase precision in an iteration, or just to use
    various different precisions for different purposes during a
    calculation.

   ####################

   ASSIGNMENT FUNCTIONS

   Rmpf_set($rop, $op);
   Rmpf_set_ui($rop, $ui);
   Rmpf_set_si($rop, $si);
   Rmpf_set_d($rop, $double);
   Rmpf_set_NV($rop, $NV); # $NV is $Config{nvtype}
   Rmpf_set_IV($rop, $IV); # $IV is $Config{ivtype}
                           # (or $Config{uvtype}).
   Rmpf_set_z($rop, $z); # $z is a Math::GMPz object.
   Rmpf_set_q($rop, $q); # $q is a Math::GMPq object.
    Set the value of $rop from the 2nd arg.

   Rmpf_set_str($rop, $str, $base);
    Set the value of $rop from the string in $str. The string is of
    the form `M@N' or, if the base is 10 or less, alternatively
    `MeN'. `M' is the mantissa and `N' is the exponent. The mantissa
    is always in the specified base. The exponent is either in the
    specified base or, if base is negative, in decimal.
    The argument $base may be in the ranges 2 to 62, or -62 to -2.
    Negative values are used to specify that the exponent is in
    decimal. For bases up to 36, case is ignored; upper-case and
    lower-case letters have the same value; for bases 37 to 62,
    upper-case letter represent the usual 10..35 while lower-case
    letter represent 36..61.
    Unlike the corresponding mpz function, the base will not be
    determined from the leading characters of the string if base is 0.
    This is so that numbers like `0.23' are not interpreted as octal.
    This function croaks if the entire string is not a valid number
    in base $base.

   Rmpf_swap($rop1, $rop2);
    Swap $rop1 and $rop2. Both the values and the
    precisions of the two variables are swapped.

   ######################################

   COMBINED INITIALIZATION AND ASSIGNMENT

   NOTE: Do NOT use these functions if $rop has already
   been initialised. Instead use the Rmpz_set* functions
   in 'Assignment Functions' (above)

   First read the section 'MEMORY MANAGEMENT' (above).

   $rop = Math::GMPf->new($arg);
   $rop = Math::GMPf::new($arg);
   $rop = new Math::GMPf($arg);
    Returns a Math::GMPf object with the value of $arg, with default
    precision. $arg can be either a number (signed integer, unsigned
    integer, signed fraction or unsigned fraction) or a string that
    represents a numeric value. If $arg is a string, an optional
    additional argument that specifies the base of the number can
    be supplied to new(). If $arg is a string and no additional
    argument is supplied, base 10 is assumed.
    The base may be in the ranges 2..62, -62..-2. Negative
    values are used to specify that the exponent is in decimal.


   $rop = Rmpf_init_set($op);
   $rop = Rmpf_init_set_nobless($op);
   $rop = Rmpf_init_set_ui($ui);
   $rop = Rmpf_init_set_ui_nobless($ui);
   $rop = Rmpf_init_set_si($si);
   $rop = Rmpf_init_set_si_nobless($si);
   $rop = Rmpf_init_set_d($double);
   $rop = Rmpf_init_set_d_nobless($double);
    Initialise $rop and assign to it the value held by
    the functions argument. See the 'Rmpf_set*'
    functions above.

   $rop = Rmpf_init_set_str($str, $base);
   $rop = Rmpf_init_set_str_nobless($str, $base);
    Initialise $rop and assign to it the base $base
    value represented by $str. See the 'Rmpf_set_str'
    documentation above for details.

   ####################

   CONVERSION FUNCTIONS

   $double = Rmpf_get_d($op);
    Convert $op to a 'double'.

   $NV = Rmpf_get_NV($op); # $NV is $Config{nvtype}
    Convert $op to an NV.

   $si = Rmpf_get_si($op);
   $ui = Rmpf_get_ui($op);
    Convert $op to a `signed long' or `unsigned long',
    truncating any fraction part.  If $op is too big for
    the return type, the result is undefined.

   $IV = Rmpf_get_IV($op);
    If $op (truncated to an integer value) fits into either an
    IV or a UV return that IV/UV value of (truncated) $op.
    Otherwise die with an appropriate error message. To find
    find out if the truncated value of $op will fit, use the
    functions 'Rmpf_fits_IV_p' and 'Rmpf_fits_UV_p'.

   ($double, $exp) = Rmpf_get_d_2exp($op);
    Find $double and $exp such that $double * (2 ** $exp),
    with 0.5<=abs($double)<1, is a good approximation to $op.
    This is similar to the standard C function `frexp'.

   $str = Rmpf_get_str($op, $base, $digits);
    Convert $op to a string of digits in base $base. $base can
    be 2 to 62.  Up to $digits digits will be generated.
    Trailing zeros are not returned.  No more digits than can be
    accurately represented by $op are ever generated.  If $digits
    is 0 then that accurate maximum number of digits are generated.

   ($man, $exp) = Rmpf_deref2($op, $base, $digits);
    Returns the mantissa to $man (as a string of digits, prefixed with
    a minus sign if $op is negative), and returns the exponent to $exp.
    There's an implicit decimal point to the left of the first digit in
    $man. The third argument to Rmpf_deref2() specifies the number of
    digits required to be output in the mantissa. No more digits than
    can be accurately represented by $op are ever generated. If $digits
    is 0 then that accurate maximum number of digits are generated

   ####################

   ARITHMETIC FUNCTIONS

   Rmpf_add($rop, $op1, $op2);
   Rmpf_add_ui($rop, $op, $ui);
    $rop = 2nd arg + 3rd arg.

   Rmpf_sub($rop, $op1, $op2);
   Rmpf_sub_ui($rop, $op, $ui);
   Rmpf_ui_sub($rop, $ui, $op);
    $rop = 2nd arg - 3rd arg.

   Rmpf_mul($rop, $op1, $op2);
   Rmpf_mul_ui($rop, $op, $ui);
    $rop = 2nd arg * 3rd arg.

   Rmpf_div($rop, $op1, $op2);
   Rmpf_ui_div($rop, $ui, $op);
   Rmpf_div_ui($rop, $op, $ui);
    $rop = 2nd arg / 3rd arg.

   Rmpf_sqrt($rop, $op);
   Rmpf_sqrt_ui($rop, $ui);
    $rop = 2nd arg ** 0.5.

   Rmpf_pow_ui($rop, $op, $ui);
    $ROP = $OP ** $ui.

   Rmpf_neg($rop, $op);
    $rop = -$op.

   Rmpf_abs($rop, $op);
    $rop = abs($op).

   Rmpf_mul_2exp($rop, $op, $ui);
    $rop = $op * (2 ** $ui).

   Rmpf_div_2exp($rop, $op, $ui);
    $rop = $op / (2 ** $ui).

   ####################

   COMPARISON FUNCTIONS

   $si = Rmpf_cmp($op1, $op2);
   $si = Rmpf_cmp_ui($op, $ui);
   $si = Rmpf_cmp_si($op, $si);
   $si = Rmpf_cmp_d($op, $double);
    Compare 1st arg and 2nd arg.  Return a positive value if
    1st arg >  2nd arg, zero if 1st arg = 2nd arg, and a
    negative value if 1st arg < 2nd arg.

   Rmpf_eq($op1, $op2, $bits);
    Return non-zero if the first $bits bits of $op1 and $op2
    are equal, zero otherwise.  I.e., test if $op1 and $op2
    are approximately equal.
    Caution: Currently only whole limbs are compared, and only in an
    exact fashion.

   Rmpf_reldiff($rop, $op1, $op2);
    $rop = abs($op1 - $op2) / $op1.

   $si = Rmpf_sgn($op);
    Returns either +1 or -1 (or 0 if $op is zero).

   ##########################

   INPUT AND OUTPUT FUNCTIONS

   $bytes_read = Rmpf_inp_str($rop, $base);
    BEST TO USE TRmpf_inp_str INSTEAD.
    Read a string in base $base from STDIN, and put the read
    float in $rop. The string is of the form `M@N' or, if
    $base is 10 or less, alternatively `MeN'.  `M' is the
    mantissa and `N' is the exponent.  The mantissa is always
    in the specified base. The exponent is either in the
    specified base or, if $base is negative,in decimal. The
    decimal point expected is taken from the current locale,
    on systems providing `localeconv'. The argument $base may
    be in the ranges 2 to 36, or -36 to -2. Negative values
    are used to specify that the exponent is in decimal.
    Unlike the corresponding `Math::GMPz' function, the
    base will not be determined from the leading characters
    of the string if $base is 0. This is so that numbers
    like `0.23' are not interpreted as octal.

   $bytes_read = TRmpf_inp_str($rop, $stream, $base);
    As for Rmpf_inp_str, except that there's the capability to read
    from somewhere other than STDIN.
    To read from STDIN:
       TRmpf_inp_str($rop, *stdin, $base);
    To read from an open filehandle (let's call it FH):
       TRmpf_inp_str($rop, \*FH, $base);

   $bytes_written = Rmpf_out_str([$prefix,] $op, $base, $digits  [, $suffix]);
    BEST TO USE TRmpf_out_str INSTEAD.
    Print $op to stream, as a string of digits. Return the number of
    bytes written, or if an error occurred, return 0. The mantissa is
    prefixed with an `0.' and is in the given base, which may vary
    from 2 to 62 or from -2 to -36. An exponent is then printed,
    separated by an `e', or if the base is greater than 10 then by an
    `@'. The exponent is always in decimal. The decimal point follows
    the current locale, on systems providing localeconv. For bases in
    the range 2..36, digits and lower-case letters are used; for
    -2..-36, digits and upper-case letters are used; for 37..62, digits,
    upper-case letters, and lower-case letters (in that significance
    order) are used. Up to $digits will be printed from the mantissa,
    except that no more digits than are accurately representable by $op
    will be printed. $digits can be 0 to select that accurate maximum.
    The optional last argument ($suffix) is a string (eg "\n") that
    will be appended to the output. The optional first argument
    ($prefix) is a string that will be prepended to the output. Note
    that either none, one, or both, of $prefix and $suffix may be
    supplied. ($bytes_written does not include the number of bytes in
    $suffix and $prefix.)

   $bytes_written = TRmpf_out_str([$prefix,] $stream, $base, $digits, $op, [, $suffix]);
    As for Rmpf_out_str, except that there's the capability to print
    to somewhere other than STDOUT. Note that the order of the args
    is different (to match the order of the mpf_out_str args).
    To print to STDERR:
       TRmpf_out_str(*stderr, $base, $digits, $op);
    To print to an open filehandle (let's call it FH):
       TRmpf_out_str(\*FH, $base, $digits, $op);

   #######################

   MISCELLANEOUS FUNCTIONS

   Rmpf_ceil($rop, $op);
   Rmpf_floor($rop, $op);
   Rmpf_trunc($rop, $op);
    Set $rop to $op rounded to an integer.  `Rmpf_ceil' rounds to the
    next higher integer, `mpf_floor' to the next lower, and
    `Rmpf_trunc' to the integer towards zero.

   $bool = Rmpf_integer_p($op);
    Return non-zero if $op is an integer.

   $bool = Rmpf_fits_ulong_p($op);
   $bool = Rmpf_fits_slong_p($op);
   $bool = Rmpf_fits_uint_p($op);
   $bool = Rmpf_fits_sint_p($op);
   $bool = Rmpf_fits_ushort_p($op);
   $bool = Rmpf_fits_sshort_p($op);
   $bool = Rmpf_fits_UV_p($op);    # fits into a perl UV
   $bool = Rmpf_fits_IV_p($op);    # fits into a perl IV
    Return non-zero if OP would fit in the respective type, when
    truncated to an integer.

   $iv = Math::GMPf::nok_pokflag(); # not exported
    Returns the value of the nok_pok flag. This flag is
    initialized to zero, but incemented by 1 whenever a
    scalar that is both a float (NOK) and string (POK) is passed
    to new() or to an overloaded operator. The value of the flag
    therefore tells us how many times such events occurred . The
    flag can be reset to 0 by running clear_nok_pok().

   Math::GMPf::set_nok_pok($iv); # not exported
    Resets the nok_pok flag to the value specified by $iv.

   Math::GMPf::clear_nok_pok(); # not exported
    Resets the nok_pok flag to 0.(Essentially the same
    as running set_nok_pok(0).)

   #######################

   RANDOM NUMBER FUNCTIONS

   In the random number functions, @r is an array of
   Math::GMPf objects (one for each random number that is
   required). $how_many is the number of random numbers you
   want and must be equal to scalar(@r). $bits is simply the
   number of random bits required. Before calling the random
   number functions, $state must be initialised and seeded.

   $state = Math::GMPz::rand_init($op); # $op is the seed.
    Without Math::GMPz, you can't use this function. (There are
    better alternatives listed immediately below, anyway.)
    Initialises and seeds $state, ready for use with the random
    number functions. However, $state has not been blessed into
    any package, and therefore does not get cleaned up when it
    goes out of scope. To avoid memory leaks you therefore need
    to call 'Math::GMPz::rand_clear($state);' once you have
    finished with it and before it goes out of scope. Also, it
    uses the default algorithm. Consider using the following
    initialisation and seeding routines - they provide a choice of
    algorithm, and there's no need to call rand_clear() when
    you've finished with them.

   $state = fgmp_randinit_default();
    This is the Math::GMPf interface to the gmp library function
   'gmp_randinit_default'.
    $state is blessed into package Math::GMPf::Random and will be
    automatically cleaned up when it goes out of scope.
    Initialize $state with a default algorithm. This will be a
    compromise between speed and randomness, and is recommended for
    applications with no special requirements. Currently this is
    the gmp_randinit_mt function (Mersenne Twister algorithm).

   $state = fgmp_randinit_mt();
    This is the Math::GMPf interface to the gmp library function
   'gmp_randinit_mt'.
    Currently identical to fgmp_randinit_default().

   $state = fgmp_randinit_lc_2exp($mpz, $ui, $m2exp);
    This is the Math::GMPf interface to the gmp library function
    'gmp_randinit_lc_2exp'. $mpz is a Math::GMP or Math::GMPz object,
    so one of those modules is required in order to make use of this
    function.
    $state is blessed into package Math::GMPf::Random and will be
    automatically cleaned up when it goes out of scope.
    Initialize $state with a linear congruential algorithm
    X = ($mpz*X + $ui) mod (2 ** $m2exp). The low bits of X in this
    algorithm are not very random. The least significant bit will have a
    period no more than 2, and the second bit no more than 4, etc. For
    this reason only the high half of each X is actually used.
    When a random number of more than m2exp/2 bits is to be generated,
    multiple iterations of the recurrence are used and the results
    concatenated.

   $state = fgmp_randinit_lc_2exp_size($ui);
    This is the Math::GMPf interface to the gmp library function
   'gmp_randinit_lc_2exp_size'.
    $state is blessed into package Math::GMPf::Random and will be
    automatically cleaned up when it goes out of scope.
    Initialize state for a linear congruential algorithm as per
    gmp_randinit_lc_2exp. a, c and m2exp are selected from a table,
    chosen so that $ui bits (or more) of each X will be used,
    ie. m2exp/2 >= $ui.
    If $ui is bigger than the table data provides then the function fails
    and dies with an appropriate error message. The maximum value for $ui
    currently supported is 128.

   $state2 = fgmp_randinit_set($state1);
    This is the Math::GMPf interface to the gmp library function
   'gmp_randinit_set'.
    $state2 is blessed into package Math::GMPf::Random and will be
    automatically cleaned up when it goes out of scope.
    Initialize $state2 with a copy of the algorithm and state from
    $state1.

   $state = fgmp_randinit_default_nobless();
   $state = fgmp_randinit_mt_nobless();
   $state = fgmp_randinit_lc_2exp_nobless($mpz, $ui, $m2exp);
   $state2 = fgmp_randinit_set_nobless($state1);
    As for the above comparable function, but $state is not blessed into
    any package. (Generally not useful - but they're available if you
    want them.)

   fgmp_randseed($state, $mpz); # $mpz is a Math::GMPz or Math::GMP object
   fgmp_randseed_ui($state, $ui);
    These are the Math::GMPz interfaces to the gmp library functions
    'gmp_randseed' and 'gmp_randseed_ui'.
    Seed an initialised (but not yet seeded) $state with $mpz/$ui.
    Either Math::GMP or Math::GMPz is required for 'gmp_randseed'.

   Rmpf_urandomb(@r, $state, $bits, $how_many);
     Generate uniformly distributed random floats, all
     between 0 and 1, with $bits significant bits in the mantissa.

   Rmpf_random2(@r, $limbs, $exp, $how_many);
    Generate random floats of at most $limbs limbs, with long
    strings of zeros and ones in the binary representation.
    The exponent of the number is in the interval -$exp to $exp.
    This function is useful for testing functions and algorithms,
    since this kind of random numbers have proven to be more
    likely to trigger corner-case bugs.  Negative random
    numbers are generated when $limbs is negative.

   $ui = fgmp_urandomb_ui($state, $bits);
    This is the Math::GMPf interface to the gmp library function
    'gmp_urandomb_ui'.
    Return a uniformly distributed random number of $bits bits, ie. in
    the range 0 to 2 ** ($bits - 1) inclusive. $bits must be less than or
    equal to the number of bits in an unsigned long.

   $ui2 = fgmp_urandomm_ui($state, $ui1);
    This is the Math::GMPf interface to the gmp library function
    'gmp_urandomm_ui'.
    Return a uniformly distributed random number in the range 0 to
    $ui1 - 1, inclusive.

   fgmp_randclear($state);
   Math::GMPz::rand_clear($state);
    Destroys $state, as also does Math::GMPf::Random::DESTROY - three
    identical functions.
    Use only if $state is an unblessed object - ie if it was initialised
    using Math::GMPz::rand_init() or one of the fgmp_randinit*_nobless
    functions.

    ####################

    OPERATOR OVERLOADING

    Overloading works with numbers, strings (base 10 only),
    Math::GMPf objects and, to a limited extent, Math::MPFR
    objects (iff version 3.13 or later of Math::MPFR has been
    installed). Strings are coerced into Math::GMPf objects
    (with default precision).

    The following operators are overloaded:
     + - * / ** sqrt (Return values have default precision)
     += -= *= /= **= ++ --(Precision remains unchanged)
     < <= > >= == != <=>
     !
     abs (Return value has default precision)
     int (on perl 5.8 only, NA on perl 5.6.
          Return value has default precision.)
     = (The copy that gets modified will have default precision.
       The other copy retains the precision of the original)
     ""

    Atempting to use the overloaded operators with objects that
    have been blessed into some package other than 'Math::GMPf'
    or 'Math::MPFR' (limited applications) will not work.
    Math::MPFR objects can be used only with '+', '-', '*', '/'
    and '**' operators, and will work only if Math::MPFR is at
    version 3.13 or later - in which case the operation will
    return a Math::MPFR object.

    In those situations where the overload subroutine operates on 2
    perl variables, then obviously one of those perl variables is
    a Math::GMPf object. To determine the value of the other variable
    the subroutine works through the following steps (in order),
    using the first value it finds, or croaking if it gets
    to step 6:

    1. If the variable is an unsigned long then that value is used.
       The variable is considered to be an unsigned long if
       (perl 5.8) the UOK flag is set or if (perl 5.6) SvIsUV()
       returns true.

    2. If the variable is a signed long int, then that value is used.
       The variable is considered to be a signed long int if the
       IOK flag is set. (In the case of perls built with
       -Duse64bitint, the variable is treated as a signed long long
       int if the IOK flag is set.)

    3. If the variable is a string (ie the POK flag is set) then the
       base 10 value of that string is used. If the POK flag is set,
       but the string is not a valid base 10 number, the subroutine
       croaks with an appropriate error message.

    4. If the variable is a double, then that value is used. The
       variable is considered to be a double if the NOK flag is set.

    5. If the variable is a Math::GMPf object (or, for operators
       specified above, a Math::MPFR object) then the value of that
       object is used.

    6. If none of the above is true, then the second variable is
       deemed to be of an invalid type. The subroutine croaks with
       an appropriate error message.

   #####

   OTHER

   $GMP_version = Math::GMPf::gmp_v;
    Returns the version of the GMP library (eg 4.1.3) being used by
    Math::GMPf. The function is not exportable.

   $GMP_cc = Math::GMPf::__GMP_CC;
   $GMP_cflags = Math::GMPf::__GMP_CFLAGS;
    If Math::GMPf has been built against gmp-4.2.3 or later,
    returns respectively the CC and CFLAGS settings that were used
    to compile the gmp library against which Math::GMPf was built.
    (Values are as specified in the gmp.h that was used to build
    Math::GMPf.)
    Returns undef if Math::GMPf has been built against an earlier
    version of the gmp library.
    (These functions are in @EXPORT_OK and are therefore exportable
    by request. They are not listed under the ":mpf" tag.)

   $major = Math::GMPf::__GNU_MP_VERSION;
   $minor = Math::GMPf::__GNU_MP_VERSION_MINOR;
   $patchlevel = Math::GMPf::__GNU_MP_VERSION_PATCHLEVEL;
    Returns respectively the major, minor, and patchlevel numbers
    for the GMP library version used to build Math::GMPf. Values are
    as specified in the gmp.h that was used to build Math::GMPf.
    (These functions are in @EXPORT_OK and are therefore exportable
    by request. They are not listed under the ":mpf" tag.)

   ################

   FORMATTED OUTPUT

   NOTE: The format specification can be found at:
   http://gmplib.org/manual/Formatted-Output-Strings.html#Formatted-Output-Strings
   However, the use of '*' to take an extra variable for width and
   precision is not allowed in this implementation. Instead, it is
   necessary to interpolate the variable into the format string - ie,
   instead of:
     Rmpf_printf("%*Zd\n", $width, $mpz);
   we need:
     Rmpf_printf("%${width}Zd\n", $mpz);

   $si = Rmpf_printf($format_string, $var);

    This function changed with the release of Math-GMPz-0.27.
    Now (unlike the GMP counterpart), it is limited to taking 2
    arguments - the format string, and the variable to be formatted.
    That is, you can format only one variable at a time.
    If there is no variable to be formatted, then the final arg
    can be omitted - a suitable dummy arg will be passed to the XS
    code for you. ie the following will work:
     Rmpf_printf("hello world\n");
    Returns the number of characters written, or -1 if an error
    occurred.

   $si = Rmpf_fprintf($fh, $format_string, $var);

    This function (unlike the GMP counterpart) is limited to taking
    3 arguments - the filehandle, the format string, and the variable
    to be formatted. That is, you can format only one variable at a time.
    If there is no variable to be formatted, then the final arg
    can be omitted - a suitable dummy arg will be passed to the XS
    code for you. ie the following will work:
     Rmpf_fprintf($fh, "hello world\n");
    Other than that, the rules outlined above wrt Rmpf_printf apply.
    Returns the number of characters written, or -1 if an error
    occurred.

   $si = Rmpf_sprintf($buffer, $format_string, $var, $buflen);

    This function (unlike the GMP counterpart) is limited to taking
    4 arguments - the buffer, the format string,  the variable to be
    formatted and the size of the buffer. If there is no variable to
    be formatted, then the third arg can be omitted - a suitable
    dummy arg will be passed to the XS code for you. ie the following
    will work:
     Rmpf_sprintf($buffer, "hello world", 12);
    $buffer must be large enough to accommodate the formatted string.
    The formatted string is placed in $buffer.
    Returns the number of characters written, or -1 if an error
    occurred.

   $si = Rmpf_snprintf($buffer, $bytes, $format_string, $var, $buflen);

    Form a null-terminated string in $buffer. No more than $bytes
    bytes will be written. To get the full output, $bytes must be
    enough for the string and null-terminator. $buffer must be large
    enough to accommodate the string and null-terminator, and is
    truncated to the length of that string (and null-terminator).
    The return value is the total number of characters which ought
    to have been produced, excluding the terminating null.
    If $si >= $bytes then the actual output has been truncated to
    the first $bytes-1 characters, and a null appended.
    This function (unlike the GMP counterpart) is limited to taking
    5 arguments - the buffer, the maximum number of bytes to be
    returned, the format string, the variable to be formatted and
    the size of the buffer.
    If there is no variable to be formatted, then the 4th arg can
    be omitted - a suitable dummy arg will be passed to the XS code
    for you. ie the following will work:
     Rmpf_snprintf($buffer, 6, "hello world", 12);

   ###############################
   ###############################

=head1 BUGS

   You can get segfaults if you pass the wrong type of
   argument to the functions - so if you get a segfault, the
   first thing to do is to check that the argument types
   you have supplied are appropriate.

=head1 LICENSE

   This program is free software; you may redistribute it and/or
   modify it under the same terms as Perl itself.
   Copyright 2006-2016 Sisyphus

=head1 AUTHOR

   Sisyphus <sisyphus at(@) cpan dot (.) org>


=cut
