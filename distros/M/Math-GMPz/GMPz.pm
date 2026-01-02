    package Math::GMPz;
    use strict;
    use warnings;
    use Math::GMPz::Random;
    use Math::GMPz::V;
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
    use constant GMPZ_PV_NV_BUG => Math::GMPz::Random::_has_pv_nv_bug();
    use constant GMPZ_WIN32_FMT_BUG => Math::GMPz::V::_buggy();

use subs qw( __GNU_MP_VERSION __GNU_MP_VERSION_MINOR __GNU_MP_VERSION_PATCHLEVEL
             __GNU_MP_RELEASE __GMP_CC __GMP_CFLAGS GMP_LIMB_BITS GMP_NAIL_BITS
             MATH_GMPz_IV_MAX  MATH_GMPz_IV_MIN  MATH_GMPz_UV_MAX);

use overload
    '+'    => \&overload_add,
    '-'    => \&overload_sub,
    '*'    => \&overload_mul,
    '/'    => \&overload_div,
    '+='   => \&overload_add_eq,
    '-='   => \&overload_sub_eq,
    '*='   => \&overload_mul_eq,
    '/='   => \&overload_div_eq,
    '%'    => \&overload_mod,
    '%='   => \&overload_mod_eq,
    '<<'   => \&overload_lshift,
    '<<='  => \&overload_lshift_eq,
    '>>'   => \&overload_rshift,
    '>>='  => \&overload_rshift_eq,
    '&'    => \&overload_and,
    '&='   => \&overload_and_eq,
    '|'    => \&overload_ior,
    '|='   => \&overload_ior_eq,
    '^'    => \&overload_xor,
    '^='   => \&overload_xor_eq,
    '~'    => \&overload_com,
    '**'   => \&overload_pow,
    '**='  => \&overload_pow_eq,
    'sqrt' => \&overload_sqrt,
    '""'   => \&overload_string,
    '++'   => \&overload_inc,
    '--'   => \&overload_dec,
    '>'    => \&overload_gt,
    '>='   => \&overload_gte,
    '<'    => \&overload_lt,
    '<='   => \&overload_lte,
    '<=>'  => \&overload_spaceship,
    '=='   => \&overload_equiv,
    '!='   => \&overload_not_equiv,
    '!'    => \&overload_not,
    '='    => \&overload_copy,
    'abs'  => \&overload_abs;

    my @untagged = qw(
__GNU_MP_VERSION __GNU_MP_VERSION_MINOR __GNU_MP_VERSION_PATCHLEVEL
__GNU_MP_RELEASE __GMP_CC __GMP_CFLAGS IOK_flag NOK_flag POK_flag
    );

    my @tagged = qw(
GMPZ_PV_NV_BUG GMPZ_WIN32_FMT_BUG MATH_GMPz_IV_MAX MATH_GMPz_IV_MIN MATH_GMPz_UV_MAX
Rmpz_abs Rmpz_add Rmpz_add_ui Rmpz_addmul Rmpz_addmul_ui Rmpz_and Rmpz_bin_ui
Rmpz_bin_uiui Rmpz_bin_si Rmpz_cdiv_q Rmpz_cdiv_q_2exp Rmpz_cdiv_q_ui Rmpz_cdiv_qr
Rmpz_cdiv_qr_ui Rmpz_cdiv_r Rmpz_cdiv_r_2exp Rmpz_cdiv_r_ui Rmpz_cdiv_ui
Rmpz_clear Rmpz_clrbit Rmpz_cmp Rmpz_cmp_d Rmpz_cmp_si Rmpz_cmp_ui
Rmpz_cmp_sj Rmpz_cmp_uj Rmpz_cmpabs Rmpz_cmpabs_d Rmpz_cmpabs_ui
Rmpz_com Rmpz_combit Rmpz_congruent_2exp_p
Rmpz_congruent_p Rmpz_congruent_ui_p Rmpz_div Rmpz_divmod Rmpz_div_ui
Rmpz_divmod_ui Rmpz_div_2exp Rmpz_mod_2exp Rmpz_divexact Rmpz_divexact_ui
Rmpz_divisible_2exp_p Rmpz_divisible_p Rmpz_divisible_ui_p Rmpz_even_p
Rmpz_export Rmpz_export_UV
Rmpz_fac_ui Rmpz_2fac_ui Rmpz_mfac_uiui Rmpz_primorial_ui
Rmpz_fdiv_q Rmpz_fdiv_q_2exp Rmpz_fdiv_q_ui
Rmpz_fdiv_qr Rmpz_fdiv_qr_ui Rmpz_fdiv_r Rmpz_fdiv_r_2exp Rmpz_fdiv_r_ui
Rmpz_fdiv_ui Rmpz_fib2_ui Rmpz_fib_ui Rmpz_fits_sint_p Rmpz_fits_slong_p
Rmpz_fits_sshort_p Rmpz_fits_uint_p Rmpz_fits_ulong_p Rmpz_fits_ushort_p
Rmpz_fprintf Rmpz_sprintf Rmpz_snprintf
Rmpz_gcd Rmpz_gcd_ui Rmpz_gcdext Rmpz_get_d_2exp Rmpz_get_si Rmpz_get_str
Rmpz_get_d Rmpz_get_NV
Rmpz_get_ui Rmpz_getlimbn Rmpz_hamdist Rmpz_import Rmpz_import_UV
Rmpz_init Rmpz_init2
Rmpz_init2_nobless Rmpz_init_nobless Rmpz_init_set Rmpz_init_set_d
Rmpz_init_set_IV Rmpz_init_set_IV_nobless Rmpz_init_set_NV Rmpz_init_set_NV_nobless
Rmpz_set_IV Rmpz_set_NV Rmpz_cmp_NV Rmpz_cmp_IV
Rmpz_get_IV Rmpz_fits_IV_p
Rmpz_init_set_d_nobless Rmpz_init_set_nobless Rmpz_init_set_si
Rmpz_init_set_si_nobless Rmpz_init_set_str Rmpz_init_set_str_nobless
Rmpz_init_set_ui Rmpz_init_set_ui_nobless Rmpz_inp_str Rmpz_inp_raw
Rmpz_invert Rmpz_ior new_from_MBI
Rmpz_jacobi Rmpz_kronecker Rmpz_kronecker_si Rmpz_kronecker_ui Rmpz_lcm
Rmpz_lcm_ui Rmpz_legendre Rmpz_lucnum2_ui Rmpz_lucnum_ui Rmpz_mod Rmpz_mod_ui
Rmpz_mul Rmpz_mul_2exp Rmpz_mul_si Rmpz_mul_ui Rmpz_neg
Rmpz_nextprime Rmpz_prevprime
Rmpz_odd_p Rmpz_out_str Rmpz_out_raw
Rmpz_perfect_power_p Rmpz_perfect_square_p
Rmpz_popcount Rmpz_pow_ui Rmpz_powm Rmpz_powm_sec Rmpz_powm_ui Rmpz_printf
Rmpz_probab_prime_p Rmpz_realloc2 Rmpz_remove Rmpz_root Rmpz_rootrem
Rmpz_rrandomb Rmpz_scan0 Rmpz_scan1 Rmpz_set Rmpz_set_d Rmpz_set_f Rmpz_set_q
Rmpz_set_si Rmpz_set_sj Rmpz_set_str Rmpz_set_ui Rmpz_set_uj
Rmpz_setbit Rmpz_sgn Rmpz_si_kronecker
Rmpz_size Rmpz_sizeinbase Rmpz_sqrt Rmpz_sqrtrem Rmpz_sub Rmpz_sub_ui
Rmpz_submul Rmpz_submul_ui Rmpz_swap Rmpz_tdiv_q Rmpz_tdiv_q_2exp
Rmpz_tdiv_q_ui Rmpz_tdiv_qr Rmpz_tdiv_qr_ui Rmpz_tdiv_r Rmpz_tdiv_r_2exp
Rmpz_tdiv_r_ui Rmpz_tdiv_ui Rmpz_tstbit Rmpz_ui_kronecker Rmpz_ui_pow_ui
Rmpz_ui_sub Rmpz_urandomb Rmpz_urandomm Rmpz_xor
rand_init rand_clear
TRmpz_out_str TRmpz_inp_str
zgmp_randseed zgmp_randseed_ui zgmp_randclear
zgmp_randinit_default zgmp_randinit_mt zgmp_randinit_lc_2exp zgmp_randinit_lc_2exp_size
zgmp_randinit_set zgmp_randinit_default_nobless zgmp_randinit_mt_nobless
zgmp_randinit_lc_2exp_nobless zgmp_randinit_lc_2exp_size_nobless zgmp_randinit_set_nobless
zgmp_urandomb_ui zgmp_urandomm_ui
    );

    @Math::GMPz::EXPORT_OK = (@untagged, @tagged);
    our $VERSION = '0.68';
    #$VERSION = eval $VERSION;

    Math::GMPz->DynaLoader::bootstrap($VERSION);

    $Math::GMPz::NULL              = _Rmpz_NULL();
    $Math::GMPz::utf8_no_downgrade = 0; # allow utf8::downgrade of utf8 strings
                                        # passed to Rmpz_import.
    $Math::GMPz::utf8_no_warn      = 0; # warn  if utf8 string is passed to Rmpz_import.
    $Math::GMPz::utf8_no_croak     = 0; # croak if utf8::downgrade fails in Rmpz_import.
    $Math::GMPz::utf8_no_fail      = 0; # warn  if $Math::GMPz::utf8_no_croak is true &&
                                        #          utf8::downgrade fails in Rmpz_import.

    %Math::GMPz::EXPORT_TAGS =(mpz => \@tagged);

sub dl_load_flags {0} # Prevent DynaLoader from complaining and croaking

sub new {

    # This function caters for 2 possibilities:
    # 1) that 'new' has been called OOP style - in which
    #    case there will be a maximum of 3 args
    # 2) that 'new' has been called as a function - in
    #    which case there will be a maximum of 2 args.
    # If there are no args, then we just want to return an
    # initialized Math::GMPz
    if(!@_) {return Rmpz_init()}
    if(@_ == 1 && ref($_[0]) eq 'Math::GMPz') { return Rmpz_init_set($_[0]) }

    if(@_ > 3) {die "Too many arguments supplied to new()"}

    # If 'new' has been called OOP style, the first arg is the string
    # "Math::GMPz" which we don't need - so let's remove it. However,
    # if the first arg is a Math::GMPz object (which is a possibility),
    # then we'll get a fatal error when we check it for equivalence to
    # the string "Math::GMPz". So we first need to check that it's not
    # an object - which we'll do by using the ref() function.
    # Also first check that the POK flag is set - to avoid setting the
    # POK flag on perl-5.18 and earlier.

    my $called_as_method = 0;

    if(!ref($_[0]) && Math::GMPz::_SvPOK($_[0]) && $_[0] eq "Math::GMPz") {
      shift;
      if(!@_) {return Rmpz_init()}
      $called_as_method = 1;
    }
    # The following elsif block is currently not implemented
    #elsif(ref($_[0]) eq "Math::GMPz") {
    #
    #  # new() was called as $math_gmpz_object->new($val). Apart from $_[0] which
    #  # is (the automatically included $math_gmpz_object), only one argument ($val)
    #  # should have been explicitly provided ... unless, of course, $val is a PV
    #  # (string), in which case a a second ($base) argument is optionally allowed.
    #
    #   shift; # Remove 1st argument
    #
    #  # Allow for possibility of an additional ($base) argument.
    #  # The possibility of there being even more arguments has already been ruled out.
    #
    #   if(@_ > 1 && _itsa($_[0]) != _POK_T ) {die "Too many arguments supplied to new() - expected only one"}
    #   return Math::GMPz->new(@_);
    #} # close elsif

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

    # Create a Math::GMPz object that has $arg1 as its value.
    # Die if there are any additional args (unless $type == _POK_T)
    if($type == _IOK_T || $type == _UOK_T) {
      if(@_ ) {die "Too many arguments supplied to new() - expected only one"}
      return Rmpz_init_set_IV($arg1);
    }

    if($type == _POK_T) { # POK
      if(@_ > 1) {die "Too many arguments supplied to new() - expected no more than two"}
      $base = shift if @_;
      if($base < 0 || $base == 1 || $base > 62) {die "Invalid value for base"}
      $arg1 =~ s/^(\s+)?\+//; # Rmpz_init_set_str() dies if there's a leading '+'.
      return Rmpz_init_set_str($arg1, $base);
    }

    if($type == _NOK_T) {
      if(@_ ) {die "Too many arguments supplied to new() - expected only one"}
      return Rmpz_init_set_NV($arg1);

    }

    if($type == _MATH_GMPq_T) {
      if(@_ ) {die "Too many arguments supplied to new() - expected only one"}
      my $ret = Rmpz_init();
      Rmpz_set_q($ret, $arg1);
      return $ret;
    }

    if($type == _MATH_GMPz_T || $type == _MATH_GMP_T) { # Math::GMPz or Math::GMP object
      if(@_) {die "Too many arguments supplied to new() - expected only one"}
      return Rmpz_init_set($arg1);
    }

    if($type == _MATH_MPFR_T) {
      if(@_ ) {die "Too many arguments supplied to new() - expected only one"}
      die "Cannot assign Inf or NaN to a Math::GMPz object"
        if(Math::MPFR::Rmpfr_nan_p($arg1) || Math::MPFR::Rmpfr_inf_p($arg1));
      my $ret = Rmpz_init();
      Math::MPFR::Rmpfr_get_z($ret, $arg1, 1); # truncate Math::MPFR object $arg1 to an
                                               # integer value, and copy that value to $ret.
      return $ret;
    }

    if($type == -1) { # Math::BigInt
      if(@_) {die "Too many arguments supplied to new() - expected only one"}
      return _new_from_MBI($arg1);
    }

    die "Unrecognised argument provided to new()";
}

sub new_from_MBI {
    return _new_from_MBI($_[0]) if _itsa($_[0]) == -1;
    die "Inappropriate arg supplied to new_from_MBI function";
}

sub Rmpz_out_str {
    if(@_ == 2) {
       die "Inappropriate 1st arg supplied to Rmpz_out_str" if _itsa($_[0]) != _MATH_GMPz_T && _itsa($_[0]) != _MATH_GMP_T;
       return _Rmpz_out_str($_[0], $_[1]);
    }
    if(@_ == 3) {
      if(_itsa($_[0]) == _MATH_GMPz_T || _itsa($_[0]) == _MATH_GMP_T) {return _Rmpz_out_strS($_[0], $_[1], $_[2])}
      die "Incorrect args supplied to Rmpz_out_str" if _itsa($_[1]) != _MATH_GMPz_T && _itsa($_[1]) != _MATH_GMP_T;
      return _Rmpz_out_strP($_[0], $_[1], $_[2]);
    }
    if(@_ == 4) {
      die "Inappropriate 2nd arg supplied to Rmpz_out_str" if _itsa($_[1]) != _MATH_GMPz_T && _itsa($_[1]) != _MATH_GMP_T;
      return _Rmpz_out_strPS($_[0], $_[1], $_[2], $_[3]);
    }
    die "Wrong number of arguments supplied to Rmpz_out_str()";
}

sub TRmpz_out_str {
    if(@_ == 3) {
      die "Inappropriate 3rd arg supplied to TRmpz_out_str" if _itsa($_[2]) != _MATH_GMPz_T && _itsa($_[2]) != _MATH_GMP_T;
      return _TRmpz_out_str($_[0], $_[1], $_[2]);
    }
    if(@_ == 4) {
      if(_itsa($_[2]) == _MATH_GMPz_T || _itsa($_[2]) == _MATH_GMP_T) {return _TRmpz_out_strS($_[0], $_[1], $_[2], $_[3])}
      die "Incorrect args supplied to TRmpz_out_str" if _itsa($_[3]) != _MATH_GMPz_T && _itsa($_[3]) != _MATH_GMP_T;
      return _TRmpz_out_strP($_[0], $_[1], $_[2], $_[3]);
    }
    if(@_ == 5) {
      die "Inappropriate 4th arg supplied to TRmpz_out_str" if _itsa($_[3]) != _MATH_GMPz_T && _itsa($_[3]) != _MATH_GMP_T;
      return _TRmpz_out_strPS($_[0], $_[1], $_[2], $_[3], $_[4]);
    }
    die "Wrong number of arguments supplied to TRmpz_out_str()";
}

# _Rmpz_get_IV may have returned a "string" - in which case we want to coerce it
# to an IV. It would be more efficient to do this in XS space (TODO), but in the
# meantime I've taken the soft option of having perl perform the coercion:

sub Rmpz_get_IV {
   my $ret = _Rmpz_get_IV(shift);
   $ret += 0 unless _SvIOK($ret); # Set the IV flag
   return $ret;
}

sub Rpi_x {
  Rmpz_set_ui($_[0], 1);
  Rmpz_mul_2exp($_[0], $_[0], $_[1]);
  Rmpz_tdiv_q_ui($_[0], $_[0], int(0.693147180559945 * $_[1]));
  }

sub prime_ratio {
    return int($_[0] * 0.3465735902799726);
    }

sub Rprovable_small {
     my $lim = 341550071728321;
     my $last = 0;
     if(Rmpz_cmp_ui($_[0], 2) < 0 || Rmpz_cmp_d($_[0], $lim) >= 0)
       {die "Argument to provable_small (= ", Rmpz_get_str($_[0], 10), " must be in range [2..341550071728321]"}
     if(Rmpz_cmp_ui($_[0], 18) < 0) {
       if(Rmpz_cmp_ui($_[0], 2) <= 0) {Rmpz_set_ui($_[0], 2)}
       if(!Rmpz_cmp_ui($_[0], 3)) {Rmpz_set_ui($_[0], 3)}
       if(Rmpz_cmp_ui($_[0], 5) <= 0) {Rmpz_set_ui($_[0], 5)}
       if(Rmpz_cmp_ui($_[0], 7) <= 0) {Rmpz_set_ui($_[0], 7)}
       if(Rmpz_cmp_ui($_[0], 11) <= 0) {Rmpz_set_ui($_[0], 11)}
       if(Rmpz_cmp_ui($_[0], 13) <= 0) {Rmpz_set_ui($_[0], 13)}
       Rmpz_set_ui($_[0], 17);
       }

     else {
       if(!Rmpz_tstbit($_[0], 0)) {Rmpz_add_ui($_[0], $_[0], 1)};
       while(Rmpz_cmp_d($_[0], $lim) < 0) {
            if(Rrm_gmp($_[0], 2) && Rrm_gmp($_[0], 3) && Rrm_gmp($_[0], 5) && Rrm_gmp($_[0], 7)
               && Rrm_gmp($_[0], 11) && Rrm_gmp($_[0], 13) && Rrm_gmp($_[0], 17))
               {$last = 1;
                last;
               }
            Rmpz_add_ui($_[0], $_[0], 2);
            }
       if(!$last) {Rmpz_set_ui($_[0], 0)}
       }

     }

sub Rprime_test {
    my $ul = $_[1] + 1;
    for(2..$ul) {
       if(!Rrm_gmp($_[0], $_)) {return 0}
       }
    return 1;
    }

sub Rnext_germaine_prime {
    my $last = 0;
    my @range = Rsieve_gmp($_[4], $_[5], $_[2]);
    Rmpz_set($_[0], $_[2]);
    my $sub = 0;
    my $mod;
    for(@range) {
        Rmpz_add_ui($_[0], $_[0], $_ - $sub);
        $sub = $_;
        $mod = Rmpz_tdiv_ui($_[0], 3);
        if($mod == 2) {
           if(Rprime_test($_[0], $_[3])) {
              Rmpz_mul_2exp($_[1], $_[0], 1);
              Rmpz_add_ui($_[1], $_[1], 1);
              if(Rprime_test($_[1], $_[3])) {
                 $last = 1;
                 last;
                 }
              }
           }
         }
    if(!$last) {
       Rmpz_set_ui($_[0], 0);
       Rmpz_set_ui($_[1], 0);
       }
    }

sub merten {
    my $gamma = 0.57721566490153286; # Euler's constant
    return 1 / exp($gamma) / log($_[0]);
    }

sub Rgenerator_zp {
    my $s = Rmpz_sizeinbase($_[1], 2);
    my $order = Rmpz_init2($s);
    my $temp = Rmpz_init2($s);
    my $check = Rmpz_init2($s);
    Rmpz_set($order, $_[1]);
    Rmpz_sub_ui($order, $order, 1);
    Rmpz_set($check, $order);

    my $nok = (1,0);
    for(@{$_[2]}) {
       if(!Rmpz_divisible_ui_p($order, $_)) {$nok = 1}
       Rmpz_set_ui($temp, $_);
       Rmpz_remove($check, $check, $temp);
       }

    if($nok) {die "Incorrect factors supplied to 3rd argument to Rgenerator_zp() function"}

    if(defined($_[3])) {
       $nok = 0;
       for(@{$_[3]}) {
          if(!Rmpz_divisible_p($order, $_)) {$nok = 1}
          Rmpz_remove($check, $check, $_);
          }
     if($nok) {die "Incorrect factors supplied to 4th argument to Rgenerator_zp function"}
       }

     if(Rmpz_cmp_ui($check, 1)) {die "Incomplete factorisation supplied to Rgenerator_zp function"};

    while(1) {
         my $flag = 1;
         if(Rmpz_cmp($_[0], $order) > 0){warn "Generator greater than order. Re-setting generator %= order and continuing....";
            Rmpz_tdiv_r($_[0], $_[0], $order);
            }
         for(@{$_[2]}) {
            Rmpz_divexact_ui($temp, $order, $_);
            Rmpz_powm($check, $_[0], $temp, $_[1]);
            if(!Rmpz_cmp_ui($check, 1)) {
              $flag = 0;
              last;
              }
            }

          if($flag && defined($_[3])) {
            for(@{$_[3]}) {
               Rmpz_divexact($temp, $order, $_);
               Rmpz_powm($check, $_[0], $temp, $_[1]);
               if(!Rmpz_cmp_ui($check, 1)) {
                 $flag = 0;
                 last;
                 }
               }
            }

         if($flag) {last}
         Rmpz_add_ui($_[0], $_[0], 1);
         }

}

sub Rnext_proven {
    my $s = Rmpz_sizeinbase($_[1], 2);
    my $r = Rmpz_init2($s);
    my $c = Rmpz_init2($s);
    my $two = Rmpz_init_set_ui(2);

    if(!defined($_[5])) {
       Rmpz_set($r, $_[1]);
       Rmpz_sub_ui($r, $r, 1);
       }
    else {Rmpz_set($r, $_[5])}

    while(1) {
         if($_[2]) {print STDERR "."}
         if(Rmpz_cmp_si($r, 1) < 0) {die "Failed to find next prime in Rnext_proven function"}
         Rmpz_mul_2exp($_[0], $r, 1);
         Rmpz_mul($_[0], $_[1], $_[0]);
         Rmpz_add_ui($_[0], $_[0], 1);
         if(Math::GMPz::trial_div_ul($_[0], $_[4]) == 1) {
           Rmpz_set($c, $_[0]);
           Rmpz_sub_ui($c, $c, 1);
           Rmpz_powm($c, $two, $c, $_[0]);
           if(!Rmpz_cmp_ui($c, 1)) {
             if($_[2]) {print STDERR "*"}
             Rmpz_mul_2exp($c, $r, 1);
             Rmpz_powm($c, $two, $c, $_[0]);
             Rmpz_sub_ui($c, $c, 1);
             Rmpz_gcd($c, $c, $_[0]);
             if(!Rmpz_cmp_ui($c, 1)) {last}
             }
           }
         Rmpz_sub_ui($r, $r, 1);
         }

    if($_[3]) {
      if(!Rmpz_probab_prime_p($_[0], 10)) {die "Rnext_proven returned a composite"}
      }


    if($_[2]) {print STDERR Rmpz_sizeinbase($_[0], 2), "\n"}

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

sub Rmpz_printf {
    local $| = 1;
    push @_, 0 if @_ == 1; # add a dummy second argument
    die "Rmpz_printf must pass 2 arguments: format string, and variable" if @_ != 2;
    wrap_gmp_printf(@_);
}

sub Rmpz_fprintf {
    push @_, 0 if @_ == 2; # add a dummy third argument
    die "Rmpz_fprintf must pass 3 arguments: filehandle, format string, and variable" if @_ != 3;
    wrap_gmp_fprintf(@_);
}

sub Rmpz_sprintf {

    my $len;

    if(@_ == 3) {      # optional arg wasn't provided
      $len = wrap_gmp_sprintf($_[0], $_[1], 0, $_[2]);  # Set missing arg to 0
    }
    else {
      die "Rmpz_sprintf must pass 4 arguments: buffer, format string, variable, buflen" if @_ != 4;
      $len = wrap_gmp_sprintf(@_);
    }

    return $len;
}

sub Rmpz_snprintf {

    my $len;

    if(@_ == 4) {      # optional arg wasn't provided
      $len = wrap_gmp_sprintf($_[0], $_[1], $_[2], 0, $_[3]);  # Set missing arg to 0
    }
    else {
      die "Rmpz_snprintf must pass 5 arguments: buffer, bytes written, format string, variable and buflen" if @_ != 5;
      $len = wrap_gmp_snprintf(@_);
    }

    return $len;
}

sub overload_lshift {
  if($_[2] || !_looks_like_number($_[1])) {
    die "Math::GMPz: When overloading '<<', the argument that specifies the number of bits to be shifted must be a perl number";
  }
  return _overload_lshift(@_) if $_[1] >= 0;
  return _overload_rshift($_[0], -$_[1], $_[2]);
}

sub overload_lshift_eq {
  if($_[2] || !_looks_like_number($_[1])) {
    die "Math::GMPz: When overloading '<<=', the argument that specifies the number of bits to be shifted must be a perl number";
  }
  return _overload_lshift_eq(@_) if $_[1] >= 0;
  return _overload_rshift_eq($_[0], -$_[1], $_[2]);
}

sub overload_rshift {
  if($_[2] || !_looks_like_number($_[1])) {
    die "Math::GMPz: When overloading '>>', the argument that specifies the number of bits to be shifted must be a perl number";
  }
  return _overload_rshift(@_) if $_[1] >= 0;
  return _overload_lshift($_[0], -$_[1], $_[2]);
}

sub overload_rshift_eq {
  if($_[2] || !_looks_like_number($_[1])) {
    die "Math::GMPz: When overloading '>>=', the argument that specifies the number of bits to be shifted must be a perl number";
  }
  return _overload_rshift_eq(@_) if $_[1] >= 0;
  return _overload_lshift_eq($_[0], -$_[1], $_[2]);
}

sub overload_gt {
  if(_itsa($_[1]) == 5) { # Math::MPFR object
    return 0 if Math::MPFR::Rmpfr_nan_p($_[1]);
    return 1 if Math::MPFR::Rmpfr_cmp_z($_[1], $_[0]) <  0;
    return 0;
  }
  return _overload_gt(@_);
}

sub overload_gte {
  if(_itsa($_[1]) == 5) { # Math::MPFR object
    return 0 if Math::MPFR::Rmpfr_nan_p($_[1]);
    return 1 if Math::MPFR::Rmpfr_cmp_z($_[1], $_[0]) <=  0;
    return 0;
  }
  return _overload_gte(@_);
}

sub overload_lt {
  if(_itsa($_[1]) == 5) { # Math::MPFR object
    return 0 if Math::MPFR::Rmpfr_nan_p($_[1]);
    return 1 if Math::MPFR::Rmpfr_cmp_z($_[1], $_[0]) >  0;
    return 0;
  }
  return _overload_lt(@_);
}

sub overload_lte {
  if(_itsa($_[1]) == 5) { # Math::MPFR object
    return 0 if Math::MPFR::Rmpfr_nan_p($_[1]);
    return 1 if Math::MPFR::Rmpfr_cmp_z($_[1], $_[0]) >=  0;
    return 0;
  }
  return _overload_lte(@_);
}

sub overload_spaceship {
  if(_itsa($_[1]) == 5) { # Math::MPFR object
    return undef if Math::MPFR::Rmpfr_nan_p($_[1]);
    return Math::MPFR::Rmpfr_cmp_z($_[1], $_[0]) * -1;
  }
  return _overload_spaceship(@_);
}

sub overload_equiv {
  if(_itsa($_[1]) == 5) { # Math::MPFR object
    return 0 if Math::MPFR::Rmpfr_nan_p($_[1]);
    return 1 if Math::MPFR::Rmpfr_cmp_z($_[1], $_[0]) ==  0;
    return 0;
  }
  return _overload_equiv(@_);
}

sub overload_not_equiv {
  if(_itsa($_[1]) == 5) { # Math::MPFR object
    return 1 if Math::MPFR::Rmpfr_nan_p($_[1]);
    return 1 if Math::MPFR::Rmpfr_cmp_z($_[1], $_[0]) !=  0;
    return 0;
  }
  return _overload_not_equiv(@_);
}

sub overload_pow  {
  my $itsa = _itsa($_[1]);
  if($itsa == 4 && _looks_like_number($_[1])) { # PV
    # Check that it's an integer string
    die "Non-integer string value ($_[1]) passed to overload_pow()"
      if int("$_[1]") != "$_[1]" + 0;
    my $z = Math::GMPz->new("$_[1]");
    return _overload_pow($z, $_[0], 0) if $_[2];
    return _overload_pow($_[0], $z, 0);
  }
  if($itsa == 3) { # NV
    my $z = Math::GMPz->new($_[1]);
    return _overload_pow($z, $_[0], 0) if $_[2];
    return _overload_pow($_[0], $z, 0);
  }
  return _overload_pow(@_);
}

sub overload_pow_eq {
  my $itsa = _itsa($_[1]);
  if($itsa == 4 && _looks_like_number($_[1])) { # PV
    # Check that it's an integer string
    die "Non-integer string value ($_[1]) passed to overload_pow()"
      if int("$_[1]") != "$_[1]" + 0;
    my $z = Math::GMPz->new("$_[1]");
    return _overload_pow_eq($_[0], $z, 0);
  }
  if($itsa == 3) { # NV
    my $z = Math::GMPz->new($_[1]);
    return _overload_pow_eq($_[0], $z, 0);
  }
  if($itsa == 5) { # Math::MPFR object
    my $mpfr_obj = Math::MPFR::Rmpfr_init2(Rmpz_sizeinbase($_[0], 2));
    Math::MPFR::Rmpfr_set_z($mpfr_obj, $_[0], Math::MPFR::Rmpfr_get_default_rounding_mode());
    my $ret = Math::MPFR::Rmpfr_init2(Math::MPFR::Rmpfr_get_prec($_[1]));
    Math::MPFR::Rmpfr_pow($ret, $mpfr_obj, $_[1], Math::MPFR::Rmpfr_get_default_rounding_mode());
    return $ret;
  }
  return _overload_pow_eq(@_);
}

sub overload_add_eq {
  if(_itsa($_[1]) == 5) { # Math::MPFR object
    my $ret = Math::MPFR::Rmpfr_init2(Math::MPFR::Rmpfr_get_prec($_[1]));
    Math::MPFR::Rmpfr_add_z($ret, $_[1], $_[0], Math::MPFR::Rmpfr_get_default_rounding_mode());
    return $ret;
  }
  return _overload_add_eq(@_);
}

sub overload_mul_eq {
  if(_itsa($_[1]) == 5) { # Math::MPFR object
    my $ret = Math::MPFR::Rmpfr_init2(Math::MPFR::Rmpfr_get_prec($_[1]));
    Math::MPFR::Rmpfr_mul_z($ret, $_[1], $_[0], Math::MPFR::Rmpfr_get_default_rounding_mode());
    return $ret;
  }
  return _overload_mul_eq(@_);
}

sub overload_sub_eq {
  if(_itsa($_[1]) == 5) { # Math::MPFR object
    my $ret = Math::MPFR::Rmpfr_init2(Math::MPFR::Rmpfr_get_prec($_[1]));
    Math::MPFR::Rmpfr_z_sub($ret, $_[0], $_[1], Math::MPFR::Rmpfr_get_default_rounding_mode());
    return $ret;
  }
  return _overload_sub_eq(@_);
}

sub overload_div_eq {
  if(_itsa($_[1]) == 5) { # Math::MPFR object
    my $ret = Math::MPFR::Rmpfr_init2(Math::MPFR::Rmpfr_get_prec($_[1]));
    Math::MPFR::Rmpfr_z_div($ret, $_[0], $_[1], Math::MPFR::Rmpfr_get_default_rounding_mode());
    return $ret;
  }
  return _overload_div_eq(@_);
}

sub overload_mod_eq {
  if(_itsa($_[1]) == 5) { # Math::MPFR object
    my $mpfr_obj = Math::MPFR::Rmpfr_init2(Rmpz_sizeinbase($_[0], 2));
    Math::MPFR::Rmpfr_set_z($mpfr_obj, $_[0], Math::MPFR::Rmpfr_get_default_rounding_mode());
    my $ret = Math::MPFR::Rmpfr_init2(Math::MPFR::Rmpfr_get_prec($_[1]));
    Math::MPFR::Rmpfr_fmod($ret, $mpfr_obj, $_[1], Math::MPFR::Rmpfr_get_default_rounding_mode());
    return $ret;
  }
  return _overload_mod_eq(@_);
}

sub __GNU_MP_VERSION            () {return ___GNU_MP_VERSION()}
sub __GNU_MP_VERSION_MINOR      () {return ___GNU_MP_VERSION_MINOR()}
sub __GNU_MP_VERSION_PATCHLEVEL () {return ___GNU_MP_VERSION_PATCHLEVEL()}
sub __GNU_MP_RELEASE            () {return ___GNU_MP_RELEASE()}
sub __GMP_CC                    () {return ___GMP_CC()}
sub __GMP_CFLAGS                () {return ___GMP_CFLAGS()}
sub GMP_LIMB_BITS               () {return _GMP_LIMB_BITS()}
sub GMP_NAIL_BITS               () {return _GMP_NAIL_BITS()}

*zgmp_randseed =                      \&Math::GMPz::Random::Rgmp_randseed;
*zgmp_randseed_ui =                   \&Math::GMPz::Random::Rgmp_randseed_ui;
*zgmp_randclear =                     \&Math::GMPz::Random::Rgmp_randclear;
*zgmp_randinit_default =              \&Math::GMPz::Random::Rgmp_randinit_default;
*zgmp_randinit_mt =                   \&Math::GMPz::Random::Rgmp_randinit_mt;
*zgmp_randinit_lc_2exp =              \&Math::GMPz::Random::Rgmp_randinit_lc_2exp;
*zgmp_randinit_lc_2exp_size =         \&Math::GMPz::Random::Rgmp_randinit_lc_2exp_size;
*zgmp_randinit_set =                  \&Math::GMPz::Random::Rgmp_randinit_set;
*zgmp_randinit_default_nobless =      \&Math::GMPz::Random::Rgmp_randinit_default_nobless;
*zgmp_randinit_mt_nobless =           \&Math::GMPz::Random::Rgmp_randinit_mt_nobless;
*zgmp_randinit_lc_2exp_nobless =      \&Math::GMPz::Random::Rgmp_randinit_lc_2exp_nobless;
*zgmp_randinit_lc_2exp_size_nobless = \&Math::GMPz::Random::Rgmp_randinit_lc_2exp_size_nobless;
*zgmp_randinit_set_nobless =          \&Math::GMPz::Random::Rgmp_randinit_set_nobless;
*zgmp_urandomb_ui =                   \&Math::GMPz::Random::Rgmp_urandomb_ui;
*zgmp_urandomm_ui =                   \&Math::GMPz::Random::Rgmp_urandomm_ui;

1;

__END__

