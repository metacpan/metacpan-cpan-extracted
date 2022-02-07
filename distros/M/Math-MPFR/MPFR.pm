    package Math::MPFR;
    use strict;
    use warnings;
    use POSIX;
    use Config;
    use Math::MPFR::Prec;
    use Math::MPFR::Random; # Needs to be loaded before Math::MPFR

    use constant  GMP_RNDN              => 0;
    use constant  GMP_RNDZ              => 1;
    use constant  GMP_RNDU              => 2;
    use constant  GMP_RNDD              => 3;
    use constant  MPFR_RNDN             => 0;
    use constant  MPFR_RNDZ             => 1;
    use constant  MPFR_RNDU             => 2;
    use constant  MPFR_RNDD             => 3;
    use constant  MPFR_RNDA             => 4;
    use constant  MPFR_RNDF             => 5;
    use constant  _UOK_T                => 1;
    use constant  _IOK_T                => 2;
    use constant  _NOK_T                => 3;
    use constant  _POK_T                => 4;
    use constant  _MATH_MPFR_T          => 5;
    use constant  _MATH_GMPf_T          => 6;
    use constant  _MATH_GMPq_T          => 7;
    use constant  _MATH_GMPz_T          => 8;
    use constant  _MATH_GMP_T           => 9;
    use constant  _MATH_MPC_T           => 10;
    use constant MPFR_FLAGS_UNDERFLOW   => 1;
    use constant MPFR_FLAGS_OVERFLOW    => 2;
    use constant MPFR_FLAGS_NAN         => 4;
    use constant MPFR_FLAGS_INEXACT     => 8;
    use constant MPFR_FLAGS_ERANGE      => 16;
    use constant MPFR_FLAGS_DIVBY0      => 32;
    use constant MPFR_FLAGS_ALL         => 63;
    use constant MPFR_FREE_LOCAL_CACHE  => 1;
    use constant MPFR_FREE_GLOBAL_CACHE => 2;
    use constant LITTLE_ENDIAN          => $Config{byteorder} =~ /^1/ ? 1 : 0;
    use constant MM_HP                  => LITTLE_ENDIAN ? 'h*' : 'H*';
    use constant MPFR_3_1_6_OR_LATER    => Math::MPFR::Random::_MPFR_VERSION() > 196869 ? 1 : 0;

    use subs qw(MPFR_VERSION MPFR_VERSION_MAJOR MPFR_VERSION_MINOR
                MPFR_VERSION_PATCHLEVEL MPFR_VERSION_STRING
                RMPFR_PREC_MIN RMPFR_PREC_MAX
                MPFR_DBL_DIG MPFR_LDBL_DIG MPFR_FLT128_DIG
                GMP_LIMB_BITS GMP_NAIL_BITS
                );

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
    'bool' => \&overload_true,
    '='    => \&overload_copy,
    'abs'  => \&overload_abs,
    '**'   => \&overload_pow,
    '**='  => \&overload_pow_eq,
    'atan2'=> \&overload_atan2,
    'cos'  => \&overload_cos,
    'sin'  => \&overload_sin,
    'log'  => \&overload_log,
    'exp'  => \&overload_exp,
    'int'  => \&overload_int,
    'sqrt' => \&overload_sqrt;

    require Exporter;
    *import = \&Exporter::import;
    require DynaLoader;

    @Math::MPFR::EXPORT_OK = qw(
GMP_RNDD GMP_RNDN GMP_RNDU GMP_RNDZ
IOK_flag NOK_flag POK_flag
MPFR_DBL_DIG MPFR_FLT128_DIG MPFR_LDBL_DIG
MPFR_FLAGS_ALL MPFR_FLAGS_DIVBY0 MPFR_FLAGS_ERANGE MPFR_FLAGS_INEXACT MPFR_FLAGS_NAN
MPFR_FLAGS_OVERFLOW MPFR_FLAGS_UNDERFLOW
MPFR_FREE_LOCAL_CACHE MPFR_FREE_GLOBAL_CACHE
MPFR_RNDA MPFR_RNDD MPFR_RNDF MPFR_RNDN MPFR_RNDU MPFR_RNDZ
MPFR_VERSION MPFR_VERSION_MAJOR MPFR_VERSION_MINOR MPFR_VERSION_PATCHLEVEL MPFR_VERSION_STRING
RMPFR_PREC_MAX RMPFR_PREC_MIN RMPFR_VERSION_NUM

Rmpfr_abs Rmpfr_acos Rmpfr_acosh Rmpfr_acospi Rmpfr_acosu
Rmpfr_add Rmpfr_add_d Rmpfr_add_q Rmpfr_add_si Rmpfr_add_ui Rmpfr_add_z
Rmpfr_agm Rmpfr_ai
Rmpfr_asin Rmpfr_asinh Rmpfr_asinpi Rmpfr_asinu
Rmpfr_atan Rmpfr_atan2 Rmpfr_atan2pi Rmpfr_atan2u Rmpfr_atanh Rmpfr_atanpi Rmpfr_atanu
Rmpfr_beta
Rmpfr_buildopt_decimal_p Rmpfr_buildopt_float128_p Rmpfr_buildopt_gmpinternals_p
Rmpfr_buildopt_sharedcache_p Rmpfr_buildopt_tls_p Rmpfr_buildopt_tune_case
Rmpfr_can_round Rmpfr_cbrt Rmpfr_ceil Rmpfr_check_range
Rmpfr_clear Rmpfr_clear_divby0 Rmpfr_clear_erangeflag Rmpfr_clear_flags Rmpfr_clear_inexflag
Rmpfr_clear_nanflag Rmpfr_clear_overflow Rmpfr_clear_underflow Rmpfr_clears
Rmpfr_cmp Rmpfr_cmp_IV Rmpfr_cmp_NV Rmpfr_cmp_d Rmpfr_cmp_f Rmpfr_cmp_float128 Rmpfr_cmp_ld
Rmpfr_cmp_q Rmpfr_cmp_si Rmpfr_cmp_si_2exp Rmpfr_cmp_sj Rmpfr_cmp_ui Rmpfr_cmp_ui_2exp
Rmpfr_cmp_uj Rmpfr_cmp_z Rmpfr_cmpabs Rmpfr_cmpabs_ui
Rmpfr_compound_si
Rmpfr_const_catalan Rmpfr_const_euler Rmpfr_const_log2 Rmpfr_const_pi
Rmpfr_copysign
Rmpfr_cos Rmpfr_cosh Rmpfr_cospi Rmpfr_cosu Rmpfr_cot Rmpfr_coth
Rmpfr_csc Rmpfr_csch
Rmpfr_d_div Rmpfr_d_sub Rmpfr_deref2 Rmpfr_digamma Rmpfr_dim
Rmpfr_div Rmpfr_div_2exp Rmpfr_div_2si Rmpfr_div_2ui Rmpfr_div_d Rmpfr_div_q Rmpfr_div_si
Rmpfr_div_ui Rmpfr_div_z Rmpfr_divby0_p
Rmpfr_dot Rmpfr_dump Rmpfr_eint Rmpfr_eq Rmpfr_equal_p Rmpfr_erandom Rmpfr_erangeflag_p
Rmpfr_erf Rmpfr_erfc Rmpfr_exp Rmpfr_exp10 Rmpfr_exp10m1 Rmpfr_exp2 Rmpfr_exp2m1 Rmpfr_expm1
Rmpfr_fac_ui
Rmpfr_fits_IV_p Rmpfr_fits_intmax_p Rmpfr_fits_sint_p Rmpfr_fits_slong_p Rmpfr_fits_sshort_p
Rmpfr_fits_uint_p Rmpfr_fits_uintmax_p Rmpfr_fits_ulong_p Rmpfr_fits_ushort_p
Rmpfr_flags_clear Rmpfr_flags_restore Rmpfr_flags_save Rmpfr_flags_set Rmpfr_flags_test
Rmpfr_floor
Rmpfr_fma Rmpfr_fmma Rmpfr_fmms Rmpfr_fmod Rmpfr_fmod_ui Rmpfr_fmodquo Rmpfr_fms
Rmpfr_fpif_export Rmpfr_fpif_import Rmpfr_fprintf Rmpfr_frac
Rmpfr_free_cache Rmpfr_free_cache2 Rmpfr_free_pool Rmpfr_frexp Rmpfr_gamma Rmpfr_gamma_inc
Rmpfr_get_DECIMAL128 Rmpfr_get_DECIMAL64 Rmpfr_get_FLOAT128 Rmpfr_get_IV Rmpfr_get_LD Rmpfr_get_NV
Rmpfr_get_d Rmpfr_get_d1 Rmpfr_get_d_2exp Rmpfr_get_default_prec Rmpfr_get_default_rounding_mode
Rmpfr_get_emax Rmpfr_get_emax_max Rmpfr_get_emax_min Rmpfr_get_emin Rmpfr_get_emin_max
Rmpfr_get_emin_min Rmpfr_get_exp Rmpfr_get_f Rmpfr_get_float128 Rmpfr_get_flt Rmpfr_get_ld
Rmpfr_get_ld_2exp Rmpfr_get_patches Rmpfr_get_prec Rmpfr_get_q Rmpfr_get_si Rmpfr_get_sj
Rmpfr_get_str Rmpfr_get_str_ndigits Rmpfr_get_str_ndigits_alt Rmpfr_get_ui Rmpfr_get_uj
Rmpfr_get_version Rmpfr_get_z Rmpfr_get_z_2exp Rmpfr_get_z_exp
Rmpfr_grandom Rmpfr_greater_p Rmpfr_greaterequal_p Rmpfr_hypot Rmpfr_inexflag_p Rmpfr_inf_p
Rmpfr_init Rmpfr_init2 Rmpfr_init2_nobless Rmpfr_init_nobless Rmpfr_init_set Rmpfr_init_set_IV
Rmpfr_init_set_IV_nobless Rmpfr_init_set_NV Rmpfr_init_set_NV_nobless Rmpfr_init_set_d
Rmpfr_init_set_d_nobless Rmpfr_init_set_f Rmpfr_init_set_f_nobless Rmpfr_init_set_float128
Rmpfr_init_set_float128_nobless Rmpfr_init_set_ld Rmpfr_init_set_nobless Rmpfr_init_set_q
Rmpfr_init_set_q_nobless Rmpfr_init_set_si Rmpfr_init_set_si_nobless Rmpfr_init_set_str
Rmpfr_init_set_str_nobless Rmpfr_init_set_ui Rmpfr_init_set_ui_nobless Rmpfr_init_set_z
Rmpfr_init_set_z_nobless Rmpfr_inits Rmpfr_inits2 Rmpfr_inits2_nobless Rmpfr_inits_nobless
Rmpfr_inp_str Rmpfr_integer_p Rmpfr_integer_string Rmpfr_j0 Rmpfr_j1 Rmpfr_jn Rmpfr_less_p
Rmpfr_lessequal_p Rmpfr_lessgreater_p Rmpfr_lgamma Rmpfr_li2 Rmpfr_lngamma
Rmpfr_log Rmpfr_log10 Rmpfr_log10p1 Rmpfr_log1p Rmpfr_log2 Rmpfr_log2p1 Rmpfr_log_ui
Rmpfr_max Rmpfr_min Rmpfr_min_prec Rmpfr_modf
Rmpfr_mul Rmpfr_mul_2exp Rmpfr_mul_2si Rmpfr_mul_2ui Rmpfr_mul_d Rmpfr_mul_q Rmpfr_mul_si
Rmpfr_mul_ui Rmpfr_mul_z
Rmpfr_nan_p Rmpfr_nanflag_p Rmpfr_neg Rmpfr_nextabove Rmpfr_nextbelow Rmpfr_nexttoward
Rmpfr_nrandom Rmpfr_number_p Rmpfr_out_str Rmpfr_overflow_p
Rmpfr_pow Rmpfr_pow_IV Rmpfr_pow_si Rmpfr_pow_sj Rmpfr_pow_ui Rmpfr_pow_uj Rmpfr_pow_z
Rmpfr_pown Rmpfr_powr Rmpfr_prec_round Rmpfr_print_rnd_mode Rmpfr_printf Rmpfr_q_div
Rmpfr_randclear Rmpfr_randinit_default Rmpfr_randinit_lc_2exp Rmpfr_randinit_lc_2exp_size
Rmpfr_randinit_mt Rmpfr_random2 Rmpfr_randseed Rmpfr_randseed_ui Rmpfr_rec_root Rmpfr_rec_sqrt
Rmpfr_regular_p Rmpfr_reldiff Rmpfr_remainder Rmpfr_remquo
Rmpfr_rint Rmpfr_rint_ceil Rmpfr_rint_floor Rmpfr_rint_round Rmpfr_rint_roundeven Rmpfr_rint_trunc
Rmpfr_root Rmpfr_rootn_ui Rmpfr_round Rmpfr_round_nearest_away Rmpfr_roundeven
Rmpfr_sec Rmpfr_sech Rmpfr_set Rmpfr_set_DECIMAL128 Rmpfr_set_DECIMAL64 Rmpfr_set_FLOAT128
Rmpfr_set_IV Rmpfr_set_LD Rmpfr_set_NV Rmpfr_set_d Rmpfr_set_default_prec
Rmpfr_set_default_rounding_mode Rmpfr_set_divby0 Rmpfr_set_emax Rmpfr_set_emin Rmpfr_set_erangeflag
Rmpfr_set_exp Rmpfr_set_f Rmpfr_set_float128 Rmpfr_set_flt Rmpfr_set_inexflag Rmpfr_set_inf
Rmpfr_set_ld Rmpfr_set_nan Rmpfr_set_nanflag Rmpfr_set_overflow Rmpfr_set_prec Rmpfr_set_prec_raw
Rmpfr_set_q Rmpfr_set_si Rmpfr_set_si_2exp Rmpfr_set_sj Rmpfr_set_sj_2exp Rmpfr_set_str Rmpfr_set_ui
Rmpfr_set_ui_2exp Rmpfr_set_uj Rmpfr_set_uj_2exp Rmpfr_set_underflow Rmpfr_set_z Rmpfr_set_z_2exp
Rmpfr_set_zero Rmpfr_setsign Rmpfr_sgn Rmpfr_si_div Rmpfr_si_sub Rmpfr_signbit
Rmpfr_sin Rmpfr_sin_cos Rmpfr_sinh Rmpfr_sinh_cosh Rmpfr_sinpi Rmpfr_sinu
Rmpfr_snprintf Rmpfr_sprintf Rmpfr_sqr Rmpfr_sqrt Rmpfr_sqrt_ui Rmpfr_strtofr
Rmpfr_sub Rmpfr_sub_d Rmpfr_sub_q Rmpfr_sub_si Rmpfr_sub_ui Rmpfr_sub_z Rmpfr_subnormalize
Rmpfr_sum Rmpfr_swap
Rmpfr_tan Rmpfr_tanh Rmpfr_tanpi Rmpfr_tanu
Rmpfr_total_order_p Rmpfr_trunc
Rmpfr_ui_div Rmpfr_ui_pow Rmpfr_ui_pow_ui Rmpfr_ui_sub Rmpfr_underflow_p Rmpfr_unordered_p
Rmpfr_urandom Rmpfr_urandomb Rmpfr_y0 Rmpfr_y1 Rmpfr_yn
Rmpfr_z_div Rmpfr_z_sub Rmpfr_zero_p Rmpfr_zeta Rmpfr_zeta_ui
TRmpfr_inp_str TRmpfr_out_str
anytoa atodouble atonum atonv
bytes
check_exact_decimal decimalize doubletoa
fr_cmp_q_rounded mpfr_max_orig_len mpfr_min_inter_prec mpfrtoa numtoa nvtoa prec_cast
q_add_fr q_cmp_fr q_div_fr q_mul_fr q_sub_fr rndna
);

    our $VERSION = '4.19';
    #$VERSION = eval $VERSION;

    Math::MPFR->DynaLoader::bootstrap($VERSION);

    # The ':mpfr' tag (below) is the same as @EXPORT_OK,
    # except that the ':mpfr' tag does not include 'bytes'.

    %Math::MPFR::EXPORT_TAGS =(mpfr => [qw(
GMP_RNDD GMP_RNDN GMP_RNDU GMP_RNDZ
MPFR_DBL_DIG MPFR_FLT128_DIG MPFR_LDBL_DIG
MPFR_FLAGS_ALL MPFR_FLAGS_DIVBY0 MPFR_FLAGS_ERANGE MPFR_FLAGS_INEXACT MPFR_FLAGS_NAN
MPFR_FLAGS_OVERFLOW MPFR_FLAGS_UNDERFLOW
MPFR_FREE_LOCAL_CACHE MPFR_FREE_GLOBAL_CACHE
MPFR_RNDA MPFR_RNDD MPFR_RNDF MPFR_RNDN MPFR_RNDU MPFR_RNDZ
MPFR_VERSION MPFR_VERSION_MAJOR MPFR_VERSION_MINOR MPFR_VERSION_PATCHLEVEL MPFR_VERSION_STRING
RMPFR_PREC_MAX RMPFR_PREC_MIN RMPFR_VERSION_NUM

Rmpfr_abs Rmpfr_acos Rmpfr_acosh Rmpfr_acospi Rmpfr_acosu
Rmpfr_add Rmpfr_add_d Rmpfr_add_q Rmpfr_add_si Rmpfr_add_ui Rmpfr_add_z
Rmpfr_agm Rmpfr_ai
Rmpfr_asin Rmpfr_asinh Rmpfr_asinpi Rmpfr_asinu
Rmpfr_atan Rmpfr_atan2 Rmpfr_atan2pi Rmpfr_atan2u Rmpfr_atanh Rmpfr_atanpi Rmpfr_atanu
Rmpfr_beta
Rmpfr_buildopt_decimal_p Rmpfr_buildopt_float128_p Rmpfr_buildopt_gmpinternals_p
Rmpfr_buildopt_sharedcache_p Rmpfr_buildopt_tls_p Rmpfr_buildopt_tune_case
Rmpfr_can_round Rmpfr_cbrt Rmpfr_ceil Rmpfr_check_range
Rmpfr_clear Rmpfr_clear_divby0 Rmpfr_clear_erangeflag Rmpfr_clear_flags Rmpfr_clear_inexflag
Rmpfr_clear_nanflag Rmpfr_clear_overflow Rmpfr_clear_underflow Rmpfr_clears
Rmpfr_cmp Rmpfr_cmp_IV Rmpfr_cmp_NV Rmpfr_cmp_d Rmpfr_cmp_f Rmpfr_cmp_float128 Rmpfr_cmp_ld
Rmpfr_cmp_q Rmpfr_cmp_si Rmpfr_cmp_si_2exp Rmpfr_cmp_sj Rmpfr_cmp_ui Rmpfr_cmp_ui_2exp
Rmpfr_cmp_uj Rmpfr_cmp_z Rmpfr_cmpabs Rmpfr_cmpabs_ui
Rmpfr_compound_si
Rmpfr_const_catalan Rmpfr_const_euler Rmpfr_const_log2 Rmpfr_const_pi
Rmpfr_copysign
Rmpfr_cos Rmpfr_cosh Rmpfr_cospi Rmpfr_cosu Rmpfr_cot Rmpfr_coth
Rmpfr_csc Rmpfr_csch
Rmpfr_d_div Rmpfr_d_sub Rmpfr_deref2 Rmpfr_digamma Rmpfr_dim
Rmpfr_div Rmpfr_div_2exp Rmpfr_div_2si Rmpfr_div_2ui Rmpfr_div_d Rmpfr_div_q Rmpfr_div_si
Rmpfr_div_ui Rmpfr_div_z Rmpfr_divby0_p
Rmpfr_dot Rmpfr_dump Rmpfr_eint Rmpfr_eq Rmpfr_equal_p Rmpfr_erandom Rmpfr_erangeflag_p
Rmpfr_erf Rmpfr_erfc Rmpfr_exp Rmpfr_exp10 Rmpfr_exp10m1 Rmpfr_exp2 Rmpfr_exp2m1 Rmpfr_expm1
Rmpfr_fac_ui
Rmpfr_fits_IV_p Rmpfr_fits_intmax_p Rmpfr_fits_sint_p Rmpfr_fits_slong_p Rmpfr_fits_sshort_p
Rmpfr_fits_uint_p Rmpfr_fits_uintmax_p Rmpfr_fits_ulong_p Rmpfr_fits_ushort_p
Rmpfr_flags_clear Rmpfr_flags_restore Rmpfr_flags_save Rmpfr_flags_set Rmpfr_flags_test
Rmpfr_floor
Rmpfr_fma Rmpfr_fmma Rmpfr_fmms Rmpfr_fmod Rmpfr_fmod_ui Rmpfr_fmodquo Rmpfr_fms
Rmpfr_fpif_export Rmpfr_fpif_import Rmpfr_fprintf Rmpfr_frac
Rmpfr_free_cache Rmpfr_free_cache2 Rmpfr_free_pool Rmpfr_frexp Rmpfr_gamma Rmpfr_gamma_inc
Rmpfr_get_DECIMAL128 Rmpfr_get_DECIMAL64 Rmpfr_get_FLOAT128 Rmpfr_get_IV Rmpfr_get_LD Rmpfr_get_NV
Rmpfr_get_d Rmpfr_get_d1 Rmpfr_get_d_2exp Rmpfr_get_default_prec Rmpfr_get_default_rounding_mode
Rmpfr_get_emax Rmpfr_get_emax_max Rmpfr_get_emax_min Rmpfr_get_emin Rmpfr_get_emin_max
Rmpfr_get_emin_min Rmpfr_get_exp Rmpfr_get_f Rmpfr_get_float128 Rmpfr_get_flt Rmpfr_get_ld
Rmpfr_get_ld_2exp Rmpfr_get_patches Rmpfr_get_prec Rmpfr_get_q Rmpfr_get_si Rmpfr_get_sj
Rmpfr_get_str Rmpfr_get_str_ndigits Rmpfr_get_str_ndigits_alt Rmpfr_get_ui Rmpfr_get_uj
Rmpfr_get_version Rmpfr_get_z Rmpfr_get_z_2exp Rmpfr_get_z_exp
Rmpfr_grandom Rmpfr_greater_p Rmpfr_greaterequal_p Rmpfr_hypot Rmpfr_inexflag_p Rmpfr_inf_p
Rmpfr_init Rmpfr_init2 Rmpfr_init2_nobless Rmpfr_init_nobless Rmpfr_init_set Rmpfr_init_set_IV
Rmpfr_init_set_IV_nobless Rmpfr_init_set_NV Rmpfr_init_set_NV_nobless Rmpfr_init_set_d
Rmpfr_init_set_d_nobless Rmpfr_init_set_f Rmpfr_init_set_f_nobless Rmpfr_init_set_float128
Rmpfr_init_set_float128_nobless Rmpfr_init_set_ld Rmpfr_init_set_nobless Rmpfr_init_set_q
Rmpfr_init_set_q_nobless Rmpfr_init_set_si Rmpfr_init_set_si_nobless Rmpfr_init_set_str
Rmpfr_init_set_str_nobless Rmpfr_init_set_ui Rmpfr_init_set_ui_nobless Rmpfr_init_set_z
Rmpfr_init_set_z_nobless Rmpfr_inits Rmpfr_inits2 Rmpfr_inits2_nobless Rmpfr_inits_nobless
Rmpfr_inp_str Rmpfr_integer_p Rmpfr_integer_string Rmpfr_j0 Rmpfr_j1 Rmpfr_jn Rmpfr_less_p
Rmpfr_lessequal_p Rmpfr_lessgreater_p Rmpfr_lgamma Rmpfr_li2 Rmpfr_lngamma
Rmpfr_log Rmpfr_log10 Rmpfr_log10p1 Rmpfr_log1p Rmpfr_log2 Rmpfr_log2p1 Rmpfr_log_ui
Rmpfr_max Rmpfr_min Rmpfr_min_prec Rmpfr_modf
Rmpfr_mul Rmpfr_mul_2exp Rmpfr_mul_2si Rmpfr_mul_2ui Rmpfr_mul_d Rmpfr_mul_q Rmpfr_mul_si
Rmpfr_mul_ui Rmpfr_mul_z
Rmpfr_nan_p Rmpfr_nanflag_p Rmpfr_neg Rmpfr_nextabove Rmpfr_nextbelow Rmpfr_nexttoward
Rmpfr_nrandom Rmpfr_number_p Rmpfr_out_str Rmpfr_overflow_p
Rmpfr_pow Rmpfr_pow_IV Rmpfr_pow_si Rmpfr_pow_sj Rmpfr_pow_ui Rmpfr_pow_uj Rmpfr_pow_z
Rmpfr_pown Rmpfr_powr Rmpfr_prec_round Rmpfr_print_rnd_mode Rmpfr_printf Rmpfr_q_div
Rmpfr_randclear Rmpfr_randinit_default Rmpfr_randinit_lc_2exp Rmpfr_randinit_lc_2exp_size
Rmpfr_randinit_mt Rmpfr_random2 Rmpfr_randseed Rmpfr_randseed_ui Rmpfr_rec_root Rmpfr_rec_sqrt
Rmpfr_regular_p Rmpfr_reldiff Rmpfr_remainder Rmpfr_remquo
Rmpfr_rint Rmpfr_rint_ceil Rmpfr_rint_floor Rmpfr_rint_round Rmpfr_rint_roundeven Rmpfr_rint_trunc
Rmpfr_root Rmpfr_rootn_ui Rmpfr_round Rmpfr_round_nearest_away Rmpfr_roundeven
Rmpfr_sec Rmpfr_sech Rmpfr_set Rmpfr_set_DECIMAL128 Rmpfr_set_DECIMAL64 Rmpfr_set_FLOAT128
Rmpfr_set_IV Rmpfr_set_LD Rmpfr_set_NV Rmpfr_set_d Rmpfr_set_default_prec
Rmpfr_set_default_rounding_mode Rmpfr_set_divby0 Rmpfr_set_emax Rmpfr_set_emin Rmpfr_set_erangeflag
Rmpfr_set_exp Rmpfr_set_f Rmpfr_set_float128 Rmpfr_set_flt Rmpfr_set_inexflag Rmpfr_set_inf
Rmpfr_set_ld Rmpfr_set_nan Rmpfr_set_nanflag Rmpfr_set_overflow Rmpfr_set_prec Rmpfr_set_prec_raw
Rmpfr_set_q Rmpfr_set_si Rmpfr_set_si_2exp Rmpfr_set_sj Rmpfr_set_sj_2exp Rmpfr_set_str Rmpfr_set_ui
Rmpfr_set_ui_2exp Rmpfr_set_uj Rmpfr_set_uj_2exp Rmpfr_set_underflow Rmpfr_set_z Rmpfr_set_z_2exp
Rmpfr_set_zero Rmpfr_setsign Rmpfr_sgn Rmpfr_si_div Rmpfr_si_sub Rmpfr_signbit
Rmpfr_sin Rmpfr_sin_cos Rmpfr_sinh Rmpfr_sinh_cosh Rmpfr_sinpi Rmpfr_sinu
Rmpfr_snprintf Rmpfr_sprintf Rmpfr_sqr Rmpfr_sqrt Rmpfr_sqrt_ui Rmpfr_strtofr
Rmpfr_sub Rmpfr_sub_d Rmpfr_sub_q Rmpfr_sub_si Rmpfr_sub_ui Rmpfr_sub_z Rmpfr_subnormalize
Rmpfr_sum Rmpfr_swap
Rmpfr_tan Rmpfr_tanh Rmpfr_tanpi Rmpfr_tanu
Rmpfr_total_order_p Rmpfr_trunc
Rmpfr_ui_div Rmpfr_ui_pow Rmpfr_ui_pow_ui Rmpfr_ui_sub Rmpfr_underflow_p Rmpfr_unordered_p
Rmpfr_urandom Rmpfr_urandomb Rmpfr_y0 Rmpfr_y1 Rmpfr_yn
Rmpfr_z_div Rmpfr_z_sub Rmpfr_zero_p Rmpfr_zeta Rmpfr_zeta_ui
TRmpfr_inp_str TRmpfr_out_str
anytoa atodouble atonum atonv
check_exact_decimal decimalize doubletoa
fr_cmp_q_rounded mpfr_max_orig_len mpfr_min_inter_prec mpfrtoa numtoa nvtoa prec_cast
q_add_fr q_cmp_fr q_div_fr q_mul_fr q_sub_fr rndna
)]);


$Math::MPFR::NNW = 0; # Set to 1 to allow "non-numeric" warnings for operations involving
                      # strings that contain non-numeric characters.

$Math::MPFR::NOK_POK = 0; # Set to 1 to allow warnings in new() and overloaded operations when
                          # a scalar that has set both NOK (NV) and POK (PV) flags is encountered

$Math::MPFR::doubletoa_fallback = 0; # If FALLBACK_NOTIFY is defined, this scalar Will be automatically
                                     # incremented whenever the grisu3 algorithm (used by doubletoa) fails
                                     # to produce correct result, and thus falls back to its designated
                                     # fallback routine. (See the doubletoa documentation for details.)

%Math::MPFR::NV_properties = _get_NV_properties();

my %bytes = (53   =>  \&_d_bytes,
             64   =>  \&_ld_bytes,
             2098 => \&_dd_bytes,
             113  => \&_f128_bytes,
            );

my %fmt = (53   =>  'a8',
           64   =>  'a10',
           2098 => 'a16',
           113  => 'a16',
          );

sub dl_load_flags {0} # Prevent DynaLoader from complaining and croaking

sub Rmpfr_out_str {
    if(@_ == 4) {
       die "Inappropriate 1st arg supplied to Rmpfr_out_str" if _itsa($_[0]) != _MATH_MPFR_T;
       return _Rmpfr_out_str($_[0], $_[1], $_[2], $_[3]);
    }
    if(@_ == 5) {
      if(_itsa($_[0]) == _MATH_MPFR_T) {return _Rmpfr_out_strS($_[0], $_[1], $_[2], $_[3], $_[4])}
      die "Incorrect args supplied to Rmpfr_out_str" if _itsa($_[1]) != _MATH_MPFR_T;
      return _Rmpfr_out_strP($_[0], $_[1], $_[2], $_[3], $_[4]);
    }
    if(@_ == 6) {
      die "Inappropriate 2nd arg supplied to Rmpfr_out_str" if _itsa($_[1]) != _MATH_MPFR_T;
      return _Rmpfr_out_strPS($_[0], $_[1], $_[2], $_[3], $_[4], $_[5]);
    }
    die "Wrong number of arguments supplied to Rmpfr_out_str()";
}

sub TRmpfr_out_str {
    if(@_ == 5) {
      die "Inappropriate 4th arg supplied to TRmpfr_out_str"
         if _itsa($_[3]) != _MATH_MPFR_T;
      return _TRmpfr_out_str($_[0], $_[1], $_[2], $_[3], $_[4]);
    }
    if(@_ == 6) {
      if(_itsa($_[3]) == _MATH_MPFR_T) {return _TRmpfr_out_strS($_[0], $_[1], $_[2], $_[3], $_[4], $_[5])}
      die "Incorrect args supplied to TRmpfr_out_str"
         if _itsa($_[4]) != _MATH_MPFR_T;
      return _TRmpfr_out_strP($_[0], $_[1], $_[2], $_[3], $_[4], $_[5]);
    }
    if(@_ == 7) {
      die "Inappropriate 5th arg supplied to TRmpfr_out_str"
         if _itsa($_[4]) != _MATH_MPFR_T;
      return _TRmpfr_out_strPS($_[0], $_[1], $_[2], $_[3], $_[4], $_[5], $_[6]);
    }
    die "Wrong number of arguments supplied to TRmpfr_out_str()";
}

sub Rmpfr_get_str {
    my ($mantissa, $exponent) = Rmpfr_deref2($_[0], $_[1], $_[2], $_[3]);

    if($mantissa =~ s/@//g) { return $mantissa }
    if($mantissa =~ /\-/ && $mantissa !~ /[^0,\-]/) {return '-0'}
    if($mantissa !~ /[^0]/ ) {return '0'}

    my $len = substr($mantissa, 0, 1) eq '-' ? 2 : 1;

    if(!$_[2]) {
      while(length($mantissa) > $len && substr($mantissa, -1, 1) eq '0') {
           substr($mantissa, -1, 1, '');
      }
    }

    $exponent--;

    my $sep = $_[1] <= 10 ? 'e' : '@';

    if(length($mantissa) == $len) {
      if($exponent) {return $mantissa . $sep . $exponent}
      return $mantissa;
    }

    substr($mantissa, $len, 0, '.');
    if($exponent) {return $mantissa . $sep . $exponent}
    return $mantissa;
}

sub overload_string {
    return Rmpfr_get_str($_[0], 10, 0, Rmpfr_get_default_rounding_mode());
}

sub Rmpfr_integer_string {
    if($_[1] < 2 || $_[1] > 36) {die("Second argument supplied to Rmpfr_integer_string() is not in acceptable range")}
    my($mantissa, $exponent) = Rmpfr_deref2($_[0], $_[1], 0, $_[2]);
    if($mantissa =~ s/@//g) { return $mantissa }
    if($mantissa =~ /\-/ && $mantissa !~ /[^0,\-]/) {return '-0'}
    return 0 if $exponent < 1;
    my $sign = substr($mantissa, 0, 1) eq '-' ? 1 : 0;
    $mantissa = substr($mantissa, 0, $exponent + $sign);
    return $mantissa;
}


sub new {

    # This function caters for 2 possibilities:
    # 1) that 'new' has been called OOP style - in which
    #    case there will be a maximum of 3 args
    # 2) that 'new' has been called as a function - in
    #    which case there will be a maximum of 2 args.
    # If there are no args, then we just want to return an
    # initialized Math::MPFR object
    if(!@_) {return Rmpfr_init()}

    if(@_ > 3) {die "Too many arguments supplied to new()"}

    # If 'new' has been called OOP style, the first arg is the string
    # "Math::MPFR" which we don't need - so let's remove it. However,
    # if the first arg is a Math::MPFR object (which is a possibility),
    # then we'll get a fatal error when we check it for equivalence to
    # the string "Math::MPFR". So we first need to check that it's not
    # an object - which we'll do by using the ref() function:
    if(!ref($_[0]) && $_[0] eq "Math::MPFR") {
      shift;
      if(!@_) {return Rmpfr_init()}
      }

    # @_ can now contain a maximum of 2 args - the value, and if the value is
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

    # Create a Math::MPFR object that has $arg1 as its value.
    # Die if there are any additional args (unless $type == 4)
    if($type == _UOK_T) {
      if(@_ ) {die "Too many arguments supplied to new() - expected only one"}
      if(Math::MPFR::_has_longlong()) {
        my $ret = Rmpfr_init();
	Rmpfr_set_uj($ret, $arg1, Rmpfr_get_default_rounding_mode());
	return $ret;
      }
      else {
        @ret = Rmpfr_init_set_ui($arg1, Rmpfr_get_default_rounding_mode());
        return $ret[0];
      }
    }

    if($type == _IOK_T) {
      if(@_ ) {die "Too many arguments supplied to new() - expected only one"}
      if(Math::MPFR::_has_longlong()) {
        my $ret = Rmpfr_init();
	Rmpfr_set_sj($ret, $arg1, Rmpfr_get_default_rounding_mode());
	return $ret;
      }
      else {
        @ret = Rmpfr_init_set_si($arg1, Rmpfr_get_default_rounding_mode());
        return $ret[0];
      }
    }

    if($type == _NOK_T) {
      if(@_ ) {die "Too many arguments supplied to new() - expected only one"}
      my $ret = Rmpfr_init();
      Rmpfr_set_NV($ret, $arg1, Rmpfr_get_default_rounding_mode());
      return $ret;
    }

    if($type == _POK_T) {
      if(@_ > 1) {die "Too many arguments supplied to new() - expected no more than two"}
      if(_SvNOK($arg1)) {
        set_nok_pok(nok_pokflag() + 1);
        if($Math::MPFR::NOK_POK) {
          warn "Scalar passed to new() is both NV and PV. Using PV (string) value";
        }
      }
      $base = shift if @_;
      @ret = Rmpfr_init_set_str($arg1, $base, Rmpfr_get_default_rounding_mode());
      return $ret[0];
    }

    if($type == _MATH_MPFR_T) {
      if(@_) {die "Too many arguments supplied to new() - expected only one"}
      @ret = Rmpfr_init_set($arg1, Rmpfr_get_default_rounding_mode());
      return $ret[0];
    }

    if($type == _MATH_GMPf_T) {
      if(@_) {die "Too many arguments supplied to new() - expected only one"}
      @ret = Rmpfr_init_set_f($arg1, Rmpfr_get_default_rounding_mode());
      return $ret[0];
    }

    if($type == _MATH_GMPq_T) {
      if(@_) {die "Too many arguments supplied to new() - expected only one"}
      @ret = Rmpfr_init_set_q($arg1, Rmpfr_get_default_rounding_mode());
      return $ret[0];
    }

    if($type == _MATH_GMPz_T || $type == _MATH_GMP_T) {
      if(@_) {die "Too many arguments supplied to new() - expected only one"}
      @ret = Rmpfr_init_set_z($arg1, Rmpfr_get_default_rounding_mode());
      return $ret[0];
    }
}

sub Rmpfr_printf {
    if(@_ == 3){wrap_mpfr_printf_rnd(@_)}
    else {die "Rmpfr_printf must take 2 or 3 arguments: format string, [rounding,], and variable" if @_ != 2;
    wrap_mpfr_printf(@_)}
}

sub Rmpfr_fprintf {
    if(@_ == 4){wrap_mpfr_fprintf_rnd(@_)}
    else {die "Rmpfr_fprintf must take 3 or 4 arguments: filehandle, format string, [rounding,], and variable" if @_ != 3;
    wrap_mpfr_fprintf(@_)}
}

sub Rmpfr_sprintf {
    my $len;
    if(@_ == 5){
      $len = wrap_mpfr_sprintf_rnd(@_);
      return $len;
    }
    die "Rmpfr_sprintf must take 4 or 5 arguments: buffer, format string, [rounding,], variable and buffer size" if @_ != 4;
    $len = wrap_mpfr_sprintf(@_);
    return $len;
}

sub Rmpfr_snprintf {
    my $len;
    if(@_ == 6){
      $len = wrap_mpfr_snprintf_rnd(@_);
      return $len;
    }
    die "Rmpfr_snprintf must take 5 or 6 arguments: buffer, bytes written, format string, [rounding,], variable and buffer size" if @_ != 5;
    $len = wrap_mpfr_snprintf(@_);
    return $len;
}


sub Rmpfr_inits {
    my @ret;
    for(1 .. $_[0]) {
       $ret[$_ - 1] = Rmpfr_init();
    }
    return @ret;
}

sub Rmpfr_inits2 {
    my @ret;
    for(1 .. $_[1]) {
       $ret[$_ - 1] = Rmpfr_init2($_[0]);
    }
    return @ret;
}

sub Rmpfr_inits_nobless {
    my @ret;
    for(1 .. $_[0]) {
       $ret[$_ - 1] = Rmpfr_init_nobless();
    }
    return @ret;
}

sub Rmpfr_inits2_nobless {
    my @ret;
    for(1 .. $_[1]) {
       $ret[$_ - 1] = Rmpfr_init2_nobless($_[0]);
    }
    return @ret;
}

sub MPFR_VERSION            () {return _MPFR_VERSION()}
sub MPFR_VERSION_MAJOR      () {return _MPFR_VERSION_MAJOR()}
sub MPFR_VERSION_MINOR      () {return _MPFR_VERSION_MINOR()}
sub MPFR_VERSION_PATCHLEVEL () {return _MPFR_VERSION_PATCHLEVEL()}
sub MPFR_VERSION_STRING     () {return _MPFR_VERSION_STRING()}
sub MPFR_DBL_DIG            () {return _DBL_DIG()}
sub MPFR_LDBL_DIG           () {return _LDBL_DIG()}
sub MPFR_FLT128_DIG         () {return _FLT128_DIG()}
sub GMP_LIMB_BITS           () {return _GMP_LIMB_BITS()}
sub GMP_NAIL_BITS           () {return _GMP_NAIL_BITS()}

sub atonum {
    if(MPFR_3_1_6_OR_LATER) {
      return atonv($_[0])
        if $_[0] =~ /^[\-\+]?inf|^[\-\+]?nan/i; # buggy perls can numify infnan strings to 0.
      my $copy = $_[0];               # Don't mess with $_[0] flags
      my $ret = "$copy" + 0;
      return $ret if _itsa($ret) < 3; # IV
      return atonv($_[0]);            # NV
    }
    die("atonum needs atonv, but atonv is not available with this version (", MPFR_VERSION_STRING, ") of the mpfr library");
}

sub check_exact_decimal {
  unless( MPFR_3_1_6_OR_LATER ) {
    warn "check_exact_decimal() requires mpfr-3.1.6 or later\n";
    die "Math::MPFR was built against mpfr-", MPFR_VERSION_STRING;
  }
  my($str, $op) = (shift, shift);

  if( !Rmpfr_regular_p($op) ) {  # $op is either zero, inf, or nan.
    if( Rmpfr_nan_p($op)    && $str =~ /^nan$/i )  { return 1 }
    if( Rmpfr_signbit($op) ) {
      if( Rmpfr_zero_p($op) && $str eq '-0' )     { return 1 }
      if( Rmpfr_inf_p($op)  && $str =~ /^\-inf$/i ) { return 1 }
    }
    else {
      if( Rmpfr_zero_p($op) && $str eq '0' )      { return 1 }
      if( Rmpfr_inf_p($op)  && $str =~ '^inf$/i' )  { return 1 }
    }

    return 0;
  }

  my $check = Rmpfr_init2(Rmpfr_get_prec($op));

  my $inex = Rmpfr_strtofr($check, $str, 10, MPFR_RNDN);

  if($inex == 0 && $op == $check) { return 1 }
  return 0;
}

sub mpfr_min_inter_prec {
    die "Wrong number of args to mpfr_min_inter_prec()" unless @_ == 3;
    my $ob = shift; # base of original representation
    my $op = shift; # precision (no. of base $ob digits in mantissa) of original representation
    my $nb = shift; # base of new representation
    my $np;         # min required precision (no. of base $nb digits in mantissa) of new representation

    my %h = (2 => 1, 4 => 2, 8 => 3, 16 => 4, 32 => 5, 64 => 6,
             3 => 1, 9 => 2, 27 => 3,
             5 => 1, 25 => 2,
             6 => 1, 36 => 2,
             7 => 1, 49 => 2);

    return $op
      if $ob == $nb;

    if(_bases_are_power_of_same_integer($ob, $nb)) {
      $np = POSIX::ceil($op * $h{$ob} / $h{$nb});
      return $np;
    }

    $np = POSIX::ceil(1 + ($op * log($ob) / log($nb)));
    return $np;
}

sub mpfr_max_orig_len {
    die "Wrong number of args to maximum_orig_length()" if @_ != 3;
    my $ob = shift; # base of original representation
    my $nb = shift; # base of new representation
    my $np = shift; # precision (no. of base $nb digits in mantissa) of new representation
    my $op;         # max precision (no. of base $ob digits in mantissa) of original representation

    my %h = (2 => 1, 4 => 2, 8 => 3, 16 => 4, 32 => 5, 64 => 6,
             3 => 1, 9 => 2, 27 => 3,
             5 => 1, 25 => 2,
             6 => 1, 36 => 2,
             7 => 1, 49 => 2);

    return $np
      if $ob == $nb;

    if(_bases_are_power_of_same_integer($ob, $nb)) {
      $op = POSIX::floor($np * $h{$nb} / $h{$ob});
      return $op;
    }

    $op = POSIX::floor(($np - 1) * log($nb) / log($ob));
    return $op;
}

sub _bases_are_power_of_same_integer {

  # This function currently doesn't get called if $_[0] == $_[1]
  # Return true if:
  # 1) Both $_[0] and $_[1] are in the range 2..64 (inclusive)
  #    &&
  # 2) Both $_[0] and $_[1] are powers of the same integer - eg 8 & 32, or 9 & 27, or 7 & 49, ....
  # Else return false.

  return 1
    if( ($_[0] == 2 || $_[0] == 16 || $_[0] == 8 || $_[0] == 64 || $_[0] == 32 || $_[0] == 4)
           &&
        ($_[1] == 2 || $_[1] == 16 || $_[1] == 8 || $_[1] == 64 || $_[1] == 32 || $_[1] == 4) );

  return 1
    if( ($_[0] == 3 || $_[0] == 9 || $_[0] == 27)
           &&
        ($_[1] == 3 || $_[1] == 9 || $_[1] == 27) );

  return 1
    if( ($_[0] == 5 || $_[0] == 25)
           &&
        ($_[1] == 5 || $_[1] == 25) );

  return 1
    if( ($_[0] == 6 || $_[0] == 36)
           &&
        ($_[1] == 6 || $_[1] == 36) );

  return 1
    if( ($_[0] == 7 || $_[0] == 49)
           &&
        ($_[1] == 7 || $_[1] == 49) );

  return 0;
}

sub bytes {
  my($val, $bits, $ret) = (shift, shift);
  my $itsa = _itsa($val);

  # $itsa == 4 implies that $val's POK flag is set && IOK flag is unset.
  # $itsa == 5 implies that $val is a Math::MPFR::object.
  # We now croak if neither of those cases is satisfied.

  die "1st arg to Math::MPFR::bytes must be either a string or a Math::MPFR object"
    if($itsa != 4 && $itsa != 5);

  die "2nd argument given to Math::MPFR::bytes is neither 53 nor 64 nor 2098 nor 113"
    unless($bits == 53 || $bits == 64 || $bits == 2098 || $bits == 113);

  $ret = $itsa == 4 ? unpack MM_HP, pack $fmt{$bits}, $bytes   {$bits} -> ($val)
                    : unpack MM_HP, pack $fmt{$bits}, _bytes_fr($val, $bits);
  return scalar reverse $ret if LITTLE_ENDIAN;
  return $ret;
}

sub rndna {
  my $coderef = shift;
  my $rop = shift;
  my $big_prec = Rmpfr_get_prec($rop) + 1;
  my $ret;

  if($coderef == \&Rmpfr_prec_round) {
    my $temp = Rmpfr_init2($big_prec); # need a temp object
    Rmpfr_set($temp, $rop, MPFR_RNDN);
    $ret = Rmpfr_prec_round($temp, $_[0] + 1, MPFR_RNDN);

    if(!$ret) {return Rmpfr_prec_round($rop, $_[0], MPFR_RNDA)}
    return Rmpfr_prec_round($rop, $_[0], MPFR_RNDN);
  }

  Rmpfr_prec_round($rop, $big_prec, MPFR_RNDN);
  $ret =  $coderef->($rop, @_, MPFR_RNDN);

  if($ret) { # not a midpoint value
    Rmpfr_prec_round($rop, $big_prec - 1, $ret < 0 ? MPFR_RNDA : MPFR_RNDZ);
    return $ret;
  }

  if(_lsb($rop) == 0) {
    Rmpfr_prec_round($rop, $big_prec - 1, MPFR_RNDZ);
    return 0;
  }

  return Rmpfr_prec_round($rop, $big_prec - 1, MPFR_RNDA);
}

sub Rmpfr_round_nearest_away {
  my $coderef = shift;
  my $rop = shift;
  my $big_prec = Rmpfr_get_prec($rop) + 1;
  my $ret;

  my $emin = Rmpfr_get_emin();

  if($emin <= Rmpfr_get_emin_min()) {
    warn "\n Rmpfr_round_nearest_away requires that emin ($emin)\n",
         " be greater than or equal to emin_min (", Rmpfr_get_emin_min(), ")\n";
    die " You need to set emin (using Rmpfr_set_emin()) accordingly";
  }

  Rmpfr_set_emin($emin - 1);

  if($coderef == \&Rmpfr_prec_round) {
    my $temp = Rmpfr_init2($big_prec); # need a temp object
    Rmpfr_set($temp, $rop, MPFR_RNDN);
    $ret = Rmpfr_prec_round($temp, $_[0] + 1, MPFR_RNDN);

    if(!$ret) {
      $ret = Rmpfr_prec_round($rop, $_[0], MPFR_RNDA);
      Rmpfr_set_emin($emin);
      return $ret;
    }
    $ret = Rmpfr_prec_round($rop, $_[0], MPFR_RNDN);
    Rmpfr_set_emin($emin);
    return $ret;
  }

  Rmpfr_prec_round($rop, $big_prec, MPFR_RNDN);
  $ret =  $coderef->($rop, @_, MPFR_RNDN);

  if($ret) { # not a midpoint value
    Rmpfr_prec_round($rop, $big_prec - 1, $ret < 0 ? MPFR_RNDA : MPFR_RNDZ);
    Rmpfr_set_emin($emin);
    return $ret;
  }

  my $nuisance = Rmpfr_init();
  Rmpfr_set_ui ($nuisance, 2, MPFR_RNDD);
  Rmpfr_pow_si ($nuisance, $nuisance, Rmpfr_get_emin(), MPFR_RNDD);
  Rmpfr_div_2ui($nuisance, $nuisance, 1, MPFR_RNDD);

  if(abs($rop) == $nuisance) {
    Rmpfr_mul_ui($rop, $rop, 2, MPFR_RNDD);
    Rmpfr_set_emin($emin);
    return (Rmpfr_signbit($rop) ? -1 : 1);
  }

  if(_lsb($rop) == 0) {
    Rmpfr_prec_round($rop, $big_prec - 1, MPFR_RNDZ);
    Rmpfr_set_emin($emin);
    return 0;
  }

  $ret = Rmpfr_prec_round($rop, $big_prec - 1, MPFR_RNDA);
  Rmpfr_set_emin($emin);
  return $ret;
}

sub _get_NV_properties {

  my($bits, $PREC, $max_dig, $min_pow, $normal_min, $NV_MAX, $nvtype, $emax, $emin);

  if   ($Config{nvtype} eq 'double')     {
    $bits = 53;  $PREC = 64;  $max_dig = 17; $min_pow = -1074;
    $normal_min = 2 ** -1022; $NV_MAX = POSIX::DBL_MAX; $emin = -1073; $emax = 1024;
  }

  elsif($Config{nvtype} eq '__float128') {
    $bits = 113; $PREC = 128; $max_dig = 36; $min_pow = -16494; $normal_min = 2 ** -16382;
    $NV_MAX = 1.18973149535723176508575932662800702e+4932; $emin = -16493; $emax = 16384;
  }

  elsif($Config{nvtype} eq 'long double') {

    if(_required_ldbl_mant_dig() == 53)      {
      $bits = 53;  $PREC = 64;  $max_dig = 17; $min_pow = -1074;
      $normal_min = 2 ** -1022; $NV_MAX = POSIX::DBL_MAX; $emin = -1073; $emax = 1024;
    }

    elsif(_required_ldbl_mant_dig() == 113)  {
      $bits = 113; $PREC = 128; $max_dig = 36; $min_pow = -16494;
      $normal_min = 2 ** -16382; $NV_MAX = POSIX::LDBL_MAX; $emin = -16493; $emax = 16384;
    }

    elsif(_required_ldbl_mant_dig() == 64)   {
      $bits = 64;  $PREC = 80;  $max_dig = 21; $min_pow = -16445;
      $normal_min = 2 ** -16382; $NV_MAX = POSIX::LDBL_MAX; $emin = -16444; $emax = 16384;
    }

    elsif(_required_ldbl_mant_dig() == 2098) {
      $bits = 2098;  $PREC = 2104;  $max_dig = 33; $min_pow = -1074;
      $normal_min = 2 ** -1022; $NV_MAX = POSIX::LDBL_MAX; $emin = -1073; $emax = 1024;
    }

    else {
      my %properties = ('type' => 'unknown long double type');
      return %properties;
    }
  }
  else {
      my %properties = ('type' => 'unknown nv type');
      return %properties;
  }

  my %properties = (
    'bits'       => $bits,
    'PREC'       => $PREC,
    'max_dig'    => $max_dig,
    'min_pow'    => $min_pow,
    'normal_min' => $normal_min,
    'NV_MAX'     => $NV_MAX,
    'emin'       => $emin,
    'emax'       => $emax,
                   );

  return %properties;
}

sub perl_set_fallback_flag {
  $Math::MPFR::doubletoa_fallback++;
}

sub anytoa {

  die "1st argument given to anytoa() must be a Math::MPFR object"
    unless Math::MPFR::_itsa($_[0]) == 5;

  my $v = shift;
  my $bits;

  if($_[0]) {
    $bits = shift;
    die "2nd argument given to anytoa() must be 0 or 53 or 64 or 113 or 2098"
    unless ($bits == 53 || $bits == 64 || $bits == 113 || $bits == 2098);
  }
  else {
    $bits = Rmpfr_get_prec($v);
    die "Precision of arg given to anytoa() must be 53 or 64 or 113 or 2098"
    unless ($bits == 53 || $bits == 64 || $bits == 113 || $bits == 2098);
  }

  my $emax = Rmpfr_get_emax();                # Save original value
  my $emin = Rmpfr_get_emin();                # Save original value

  my $f_init = Rmpfr_init2($bits);

  my %emax_emin = (53   => [1024,  -1073,  -1022 ],
                   64   => [16384, -16444, -16382],
                   2098 => [1024,  -1073,  -1022 ],
                   113  => [16384, -16493, -16382],
                  );

  Rmpfr_set_emax($emax_emin{$bits}->[0]);
  Rmpfr_set_emin($emax_emin{$bits}->[1]);

  # DoubleDouble
  if($bits == 2098) {

    Rmpfr_strtofr($f_init, "$v", 0, MPFR_RNDN);

    if(!Rmpfr_regular_p($f_init)) {
      Rmpfr_set_emax($emax);                  # Revert to original value
      Rmpfr_set_emin($emin);                  # Revert to original value
      return mpfrtoa($f_init);
    }

    # Obtain the pair of doubles pertinent to $f_init.
    # $msd is the "more siginificant double" and $lsd
    # is the "less significant double".

    my($msd, $lsd) = _mpfr2dd($f_init);
    if($lsd == 0 ) {
      my $f = Rmpfr_init2(53);
      Rmpfr_set_d($f, $msd, MPFR_RNDN);
      Rmpfr_set_emax($emax);                  # Revert to original value
      Rmpfr_set_emin($emin);                  # Revert to original value
      return anytoa($f, 53);
    }

    # Determine the no. of implied (intermediate)
    # bits that lie between the end of $msd and
    # and the start of $lsd

    my $intermediates = _intermediate_bits($msd, $lsd);

    my $f_final = Rmpfr_init2(106 + $intermediates);
    Rmpfr_set_d($f_final, $msd, MPFR_RNDN);
    Rmpfr_add_d($f_final, $f_final, $lsd, MPFR_RNDN);

    Rmpfr_set_emax($emax);                    # Revert to original value
    Rmpfr_set_emin($emin);                    # Revert to original value
    return mpfrtoa($f_final);

  } # End DoubleDouble

  # The next 4 lines cater for the possibility that
  # the value is either subnormal or infinite or
  # zero for the floating point type specified by
  # the value of $bits.

  my $inex = Rmpfr_strtofr($f_init, "$v", 0, MPFR_RNDN);

  if(Rmpfr_regular_p($f_init) && Rmpfr_get_exp($f_init) < $emax_emin{$bits}->[2]) {
    # The value is subnormal, and therefore requires further treatment.

    Rmpfr_subnormalize($f_init, $inex, MPFR_RNDN);
    my ($significand, $exponent) = Rmpfr_deref2($f_init, 2, 0, MPFR_RNDN);

    my $f_final = Rmpfr_init2(1 + $exponent - $emax_emin{$bits}->[1]);

    if($significand =~ s/^\-/-0./) {          # The value is -ve.
      Rmpfr_strtofr($f_final, "${significand}p$exponent", 2, MPFR_RNDN);
    }
    else {                                    # The value is positive
      Rmpfr_strtofr($f_final, "0.${significand}p$exponent", 2, MPFR_RNDN);
    }
    Rmpfr_set_emax($emax);                    # Revert to original value
    Rmpfr_set_emin($emin);                    # Revert to original value
    return mpfrtoa($f_final);
  }

  Rmpfr_set_emax($emax);                      # Revert to original value
  Rmpfr_set_emin($emin);                      # Revert to original value
  return mpfrtoa($f_init);
}

sub _mpfr2dd {
  # Can be called from anytoa()
  my $obj = shift;
  my $msd = Rmpfr_get_d($obj, MPFR_RNDN);
  $obj -= $msd;
  return ($msd, Rmpfr_get_d($obj, MPFR_RNDN));
}

sub _intermediate_bits {
  # Can be called from anytoa()
  my($exp1, $exp2) = (_get_exp(shift), _get_exp(shift));
  return $exp1 - 53 - $exp2;
}

sub _get_exp {
  # Can be called from anytoa(), via _intermediate_bits().
  # For as long as we support perl-5.8, we cannot use
  # the "d<" and "d>" templates.
  my $hex;
  if(LITTLE_ENDIAN) {
    $hex = scalar reverse unpack "h*", pack "d", $_[0];
  }
  else {
    $hex = unpack "H*", pack "d", $_[0];
  }
  my $exp = hex(substr($hex, 0, 3));
  $exp -= 2048 if $exp > 2047; # Remove sign bit
  $exp++ unless $exp; # increment if 0
  return ($exp - 1023);
}

*Rmpfr_get_z_exp             = \&Rmpfr_get_z_2exp;
*prec_cast                   = \&Math::MPFR::Prec::prec_cast;
*Rmpfr_randinit_default      = \&Math::MPFR::Random::Rmpfr_randinit_default;
*Rmpfr_randinit_mt           = \&Math::MPFR::Random::Rmpfr_randinit_mt;
*Rmpfr_randinit_lc_2exp      = \&Math::MPFR::Random::Rmpfr_randinit_lc_2exp;
*Rmpfr_randinit_lc_2exp_size = \&Math::MPFR::Random::Rmpfr_randinit_lc_2exp_size;

1;

__END__
