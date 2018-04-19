#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "gmp.h"

typedef mpz_t mpz_t_ornull;

/* for Perl prior to v5.7.1 */
#ifndef SvUOK
#  define SvUOK(sv) SvIOK_UV(sv)
#endif

#ifndef PERL_UNUSED_ARG
#  define PERL_UNUSED_ARG(x) ((void)x)
#endif

#ifndef gv_stashpvs
#  define gv_stashpvs(name, create) gv_stashpvn(name, sizeof(name) - 1, create)
#endif

#ifndef PERL_MAGIC_ext
#  define PERL_MAGIC_ext '~'
#endif

#if defined(USE_ITHREADS) && defined(MGf_DUP)
#  define GMP_THREADSAFE 1
#else
#  define GMP_THREADSAFE 0
#endif

#ifdef sv_magicext
#  define GMP_HAS_MAGICEXT 1
#else
#  define GMP_HAS_MAGICEXT 0
#endif

#define NEW_GMP_MPZ_T      RETVAL = malloc (sizeof(mpz_t));
#define NEW_GMP_MPZ_T_INIT RETVAL = malloc (sizeof(mpz_t)); mpz_init(*RETVAL);
#define GMP_GET_ARG_0      TEMP = mpz_from_sv(x);
#define GMP_GET_ARG_1      TEMP_1 = mpz_from_sv(y);
#define GMP_GET_ARGS_0_1   GMP_GET_ARG_0; GMP_GET_ARG_1;

#if GMP_THREADSAFE
STATIC int
dup_gmp_mpz (pTHX_ MAGIC *mg, CLONE_PARAMS *params)
{
  mpz_t *RETVAL;
  PERL_UNUSED_ARG(params);
  NEW_GMP_MPZ_T;
  mpz_init_set(*RETVAL, *((mpz_t *)mg->mg_ptr));
  mg->mg_ptr = (char *)RETVAL;
  return 0;
}
#endif

#if GMP_HAS_MAGICEXT
STATIC MGVTBL vtbl_gmp = {
  NULL, /* get */
  NULL, /* set */
  NULL, /* len */
  NULL, /* clear */
  NULL, /* free */
# ifdef MGf_COPY
  NULL, /* copy */
# endif
# ifdef MGf_DUP
#  if GMP_THREADSAFE
  dup_gmp_mpz,
#  else
  NULL, /* dup */
#  endif
# endif
# ifdef MGf_LOCAL
  NULL, /* local */
# endif
};
#endif

STATIC void
attach_mpz_to_sv (SV *sv, mpz_t *mpz)
{
#if GMP_THREADSAFE
  MAGIC *mg;
#endif
#if !GMP_HAS_MAGICEXT
  SV *refaddr = sv_2mortal(newSViv(PTR2IV(mpz)));
#endif

  sv_bless(sv, gv_stashpvs("Math::BigInt::GMP", 0));

#if GMP_THREADSAFE && GMP_HAS_MAGICEXT
  mg =
#endif
#if GMP_HAS_MAGICEXT
    sv_magicext(SvRV(sv), NULL, PERL_MAGIC_ext, &vtbl_gmp, (void *)mpz, 0);
#else
  sv_magic(SvRV(sv), NULL, PERL_MAGIC_ext, (void *)refaddr, HEf_SVKEY);
#endif

#if GMP_THREADSAFE && GMP_HAS_MAGICEXT
  mg->mg_flags |= MGf_DUP;
#endif
}

STATIC SV *
sv_from_mpz (mpz_t *mpz)
{
  SV *sv = newSV(0);
  SV *obj = newRV_noinc(sv);

  attach_mpz_to_sv(obj, mpz);

  return obj;
}

STATIC mpz_t *
mpz_from_sv_nofail (SV *sv)
{
  MAGIC *mg;

  if (!sv_derived_from(sv, "Math::BigInt::GMP"))
    croak("not of type Math::BigInt::GMP");

  for (mg = SvMAGIC(SvRV(sv)); mg; mg = mg->mg_moremagic) {
    if (mg->mg_type == PERL_MAGIC_ext
#if GMP_HAS_MAGICEXT
        && mg->mg_virtual == &vtbl_gmp
#endif
        ) {
#if GMP_HAS_MAGICEXT
      return (mpz_t *)mg->mg_ptr;
#else
      return INT2PTR(mpz_t *, SvIV((SV *)mg->mg_ptr));
#endif
    }
  }

  return (mpz_t *)NULL;
}

STATIC mpz_t *
mpz_from_sv (SV *sv)
{
  mpz_t *mpz;

  if (!(mpz = mpz_from_sv_nofail(sv)))
    croak("failed to fetch mpz pointer");

  return mpz;
}

/*
Math::BigInt::GMP XS code, loosely based on Math::GMP, a Perl module for
high-speed arbitrary size integer calculations (C) 2000 James H. Turner
*/

MODULE = Math::BigInt::GMP              PACKAGE = Math::BigInt::GMP
PROTOTYPES: ENABLE

##############################################################################
# _new()

mpz_t *
_new(Class,x)
        SV*     x

  CODE:
    NEW_GMP_MPZ_T;
    /* using the IV directly is a bit faster */
    if ((SvUOK(x) || SvIOK(x)) && (sizeof(UV) <= sizeof(unsigned long) || SvUV(x) == (unsigned long)SvUV(x)))
      {
      mpz_init_set_ui(*RETVAL, (unsigned long)SvUV(x));
      }
    else
      {
      mpz_init_set_str(*RETVAL, SvPV_nolen(x), 10);
      }
  OUTPUT:
    RETVAL

##############################################################################
# _new_attach()

void
_new_attach(Class,sv,x)
    SV *sv
    SV *x
  PREINIT:
    mpz_t *mpz;
  CODE:
    mpz = malloc (sizeof(mpz_t));
    if ((SvUOK(x) || SvIOK(x)) && (sizeof(UV) <= sizeof(unsigned long) || SvUV(x) == (unsigned long)SvUV(x))) {
      mpz_init_set_ui(*mpz, (unsigned long)SvUV(x));
    }
    else {
      mpz_init_set_str(*mpz, SvPV_nolen(x), 10);
    }
    attach_mpz_to_sv(sv, mpz);

##############################################################################
# _from_bin()

mpz_t *
_from_bin(Class,x)
        SV*     x

  CODE:
    NEW_GMP_MPZ_T;
    mpz_init_set_str(*RETVAL, SvPV_nolen(x), 0);
  OUTPUT:
    RETVAL

##############################################################################
# _from_hex()

mpz_t *
_from_hex(Class,x)
        SV*     x

  CODE:
    NEW_GMP_MPZ_T;
    mpz_init_set_str(*RETVAL, SvPV_nolen(x), 0);
  OUTPUT:
    RETVAL

##############################################################################
# _from_oct()

mpz_t *
_from_oct(Class,x)
        SV*     x

  CODE:
    NEW_GMP_MPZ_T;
    mpz_init_set_str(*RETVAL, SvPV_nolen(x), 0);
  OUTPUT:
    RETVAL

##############################################################################
# _set() - set an already existing object to the given scalar value

void
_set(Class,n,x)
        mpz_t*  n
        SV*     x

  CODE:
    mpz_init_set_ui(*n, SvIV(x));

##############################################################################
# _zero()

mpz_t *
_zero(Class)

  CODE:
    NEW_GMP_MPZ_T;
    mpz_init_set_ui(*RETVAL, 0);
  OUTPUT:
    RETVAL

##############################################################################
# _one()

mpz_t *
_one(Class)

  CODE:
    NEW_GMP_MPZ_T;
    mpz_init_set_ui(*RETVAL, 1);
  OUTPUT:
    RETVAL

##############################################################################
# _two()

mpz_t *
_two(Class)

  CODE:
    NEW_GMP_MPZ_T;
    mpz_init_set_ui(*RETVAL, 2);
  OUTPUT:
    RETVAL

##############################################################################
# _ten()

mpz_t *
_ten(Class)

  CODE:
    NEW_GMP_MPZ_T;
    mpz_init_set_ui(*RETVAL, 10);
  OUTPUT:
    RETVAL

##############################################################################
# _1ex()

mpz_t *
_1ex(Class,x)
    int x;

  CODE:
    NEW_GMP_MPZ_T;
    mpz_init_set_ui(*RETVAL, 10);
    mpz_pow_ui(*RETVAL, *RETVAL, x);
  OUTPUT:
    RETVAL

##############################################################################
# DESTROY() - free memory of a GMP number

void
DESTROY(n)
        mpz_t_ornull*   n

  PPCODE:
    if (n) {
        mpz_clear(*n);
        free(n);
    }

##############################################################################
# _str() - return string so that atof() and atoi() can use it

SV *
_str(Class, n)
        mpz_t*  n
  PREINIT:
    int len;
    char *buf;
    char *buf_end;

  CODE:
    /* len is always >= 1, and might be off (greater) by one than real len */
    len = mpz_sizeinbase(*n, 10);
    RETVAL = newSV(len);                /* alloc len +1 bytes */
    SvPOK_on(RETVAL);
    buf = SvPVX(RETVAL);                /* get ptr to storage */
    buf_end = buf + len - 1;            /* end of storage (-1)*/
    mpz_get_str(buf, 10, *n);           /* convert to decimal string */
    if (*buf_end == 0)
      {
      len --;                           /* got one shorter than expected */
      }
    SvCUR_set(RETVAL, len);             /* so set real length */
   OUTPUT:
     RETVAL

##############################################################################
# _len() - return the length of the number in base 10 (costly)

int
_len(Class, n)
        mpz_t*  n
  PREINIT:
    char *buf;
    char *buf_end;

  CODE:
    /* len is always >= 1, and might be off (greater) by one than real len */
    RETVAL = mpz_sizeinbase(*n, 10);
    if (RETVAL > 1)                     /* is at least 10? */
      {
      New(0, buf, RETVAL + 1, I8);      /* alloc scratch buffer (len+1) bytes */
      buf_end = buf + RETVAL - 1;       /* end of storage (-1)*/
      mpz_get_str(buf, 10, *n);         /* convert to decimal string */
      if (*buf_end == 0)
        {
        RETVAL --;                      /* got one shorter than expected */
        }
      Safefree(buf);                    /* free the scratch buffer */
      }
   OUTPUT:
     RETVAL

##############################################################################
# _alen() - return the approx. length of the number in base 10 (fast)

int
_alen(Class, n)
        mpz_t*  n

  CODE:
    /* len is always >= 1, and might be off (greater) by one than real len */
    RETVAL = mpz_sizeinbase(*n, 10);
   OUTPUT:
     RETVAL

##############################################################################
# _zeros() - return number of trailing zeros (in decimal form)
# This is costly, since it needs O(N*N) to convert the number to decimal,
# even though for most cases the number does not have many trailing zeros.
# For numbers longer than X digits (10?) we could divide repeatable by 1e5
# or something and see if we get zeros.

int
_zeros(Class,n)
        mpz_t*  n

  PREINIT:
    int len;
    char *buf;
    char *buf_end;

  CODE:
    /* odd numbers can not have trailing zeros */
    RETVAL = 1 - mpz_tstbit(*n,0);

    if (RETVAL != 0)                    /* was even */
      {
      /* len is always >= 1, and might be off (greater) by one than real len */
      RETVAL = 0;
      len = mpz_sizeinbase(*n, 10);
      if (len > 1)                      /* '0' has no trailing zeros! */
        {
        New(0, buf, len + 1, I8);
        mpz_get_str(buf, 10, *n);       /* convert to decimal string */
        buf_end = buf + len - 1;
        if (*buf_end == 0)              /* points to terminating zero? */
          {
          buf_end--;                    /* ptr to last real digit */
          len--;                        /* got one shorter than expected */
          }
        while (len-- > 0)               /* actually, we should hit a non-zero before the end */
          {
          if (*buf_end-- != '0')
            {
            break;
            }
          RETVAL++;
          }
        Safefree(buf);                  /* free the scratch buffer */
        }
      } /* end if n was even */
  OUTPUT:
    RETVAL

##############################################################################
# _as_hex() - return ref to hexadecimal string (prefixed with 0x)

SV *
_as_hex(Class,n)
        mpz_t * n

  PREINIT:
    int len;
    char *buf;

  CODE:
    /* len is always >= 1, and accurate (unlike in decimal) */
    len = mpz_sizeinbase(*n, 16) + 2;
    RETVAL = newSV(len);                /* alloc len +1 (+2 for '0x') bytes */
    SvPOK_on(RETVAL);
    buf = SvPVX(RETVAL);                /* get ptr to storage */
    *buf++ = '0'; *buf++ = 'x';         /* prepend '0x' */
    mpz_get_str(buf, 16, *n);           /* convert to hexadecimal string */
    SvCUR_set(RETVAL, len);             /* so set real length */
  OUTPUT:
    RETVAL

##############################################################################
# _as_bin() - return ref to binary string (prefixed with 0b)

SV *
_as_bin(Class,n)
        mpz_t * n

  PREINIT:
    int len;
    char *buf;

  CODE:
    /* len is always >= 1, and accurate (unlike in decimal) */
    len = mpz_sizeinbase(*n, 2) + 2;
    RETVAL = newSV(len);                /* alloc len +1 (+2 for '0b') bytes */
    SvPOK_on(RETVAL);
    buf = SvPVX(RETVAL);                /* get ptr to storage */
    *buf++ = '0'; *buf++ = 'b';         /* prepend '0b' */
    mpz_get_str(buf, 2, *n);            /* convert to binary string */
    SvCUR_set(RETVAL, len);             /* so set real length */
  OUTPUT:
    RETVAL

##############################################################################
# _as_oct() - return ref to octal string (prefixed with 0)

SV *
_as_oct(Class,n)
        mpz_t * n

  PREINIT:
    int len;
    char *buf;

  CODE:
    /* len is always >= 1, and accurate (unlike in decimal) */
    len = mpz_sizeinbase(*n, 8) + 1;
    RETVAL = newSV(len);                /* alloc len +1 (+1 for '0') bytes */
    SvPOK_on(RETVAL);
    buf = SvPVX(RETVAL);                /* get ptr to storage */
    *buf++ = '0';                       /* prepend '0' */
    mpz_get_str(buf, 8, *n);            /* convert to binary string */
    SvCUR_set(RETVAL, len);             /* so set real length */
  OUTPUT:
    RETVAL

##############################################################################
# _modpow() - ($n ** $exp) % $mod

mpz_t *
_modpow(Class, n, exp, mod)
       mpz_t*   n
       mpz_t*   exp
       mpz_t*   mod

  CODE:
    NEW_GMP_MPZ_T_INIT;
    mpz_powm(*RETVAL, *n, *exp, *mod);
  OUTPUT:
    RETVAL

##############################################################################
# _modinv() - compute the inverse of x % y
#
# int mpz_invert (mpz_t rop, mpz_t op1, mpz_t op2)      Function
# Compute the inverse of op1 modulo op2 and put the result in rop. If the
# inverse exists, the return value is non-zero and rop will satisfy
# 0 <= rop < op2. If an inverse doesn't exist the return value is zero and rop
# is undefined.

void
_modinv(Class,x,y)
        mpz_t*  x
        mpz_t*  y

  PREINIT:
    int rc, sign;
    SV* s;
    mpz_t* RETVAL;
  PPCODE:
    NEW_GMP_MPZ_T_INIT;
    rc = mpz_invert(*RETVAL, *x, *y);
    EXTEND(SP, 2);      /* we return two values */
    if (rc == 0)
      {
      /* Inverse doesn't exist. Return both values undefined. */
      PUSHs ( &PL_sv_undef );
      PUSHs ( &PL_sv_undef );
      mpz_clear(*RETVAL);
      free(RETVAL);
      }
    else
      {
      /* Inverse exists. When the modulus to mpz_invert() is positive,
       * the returned value is also positive. */
      PUSHs(sv_2mortal(sv_from_mpz(RETVAL)));
        s = sv_newmortal();
        sv_setpvn (s, "+", 1);
      PUSHs ( s );
      }

##############################################################################
# _add() - add $y to $x in place

void
_add(Class,x,y)
        SV*     x
        SV*     y
  PREINIT:
        mpz_t* TEMP;
        mpz_t* TEMP_1;
  PPCODE:
    GMP_GET_ARGS_0_1;   /* (TEMP, TEMP_1) = (x,y)  */
    mpz_add(*TEMP, *TEMP, *TEMP_1);
    PUSHs( x );


##############################################################################
# _inc() - modify x inline by doing x++

void
_inc(Class,x)
        SV*     x
  PREINIT:
        mpz_t* TEMP;
  PPCODE:
    GMP_GET_ARG_0;      /* TEMP =  mpz_t(x)  */
    mpz_add_ui(*TEMP, *TEMP, 1);
    PUSHs( x );

##############################################################################
# _dec() - modify x inline by doing x--

void
_dec(Class,x)
        SV*     x
  PREINIT:
        mpz_t* TEMP;
  PPCODE:
    GMP_GET_ARG_0;      /* TEMP =  mpz_t(x)  */
    mpz_sub_ui(*TEMP, *TEMP, 1);
    PUSHs( x );

##############################################################################
# _sub() - $x - $y
# $x is always larger than $y! So overflow/underflow can not happen here.
# Formerly this code was:
# # if ($_[3])
#    {
#    $_[2] = Math::BigInt::GMP::sub_two($_[1],$_[2]); return $_[2];
#    }
#  Math::BigInt::GMP::_sub_in_place($_[1],$_[2]);
#  }

void
_sub(Class,x,y, ...)
        SV*     x
        SV*     y
  PREINIT:
        mpz_t* TEMP;
        mpz_t* TEMP_1;
  PPCODE:
    GMP_GET_ARGS_0_1;   /* (TEMP, TEMP_1) = (x,y)  */
    if ( items == 4 && SvTRUE(ST(3)) )
      {
      /* y -= x */
      mpz_sub(*TEMP_1, *TEMP, *TEMP_1);
      PUSHs( y );
      }
    else
      {
      /* x -= y */
      mpz_sub(*TEMP, *TEMP, *TEMP_1);
      PUSHs( x );
      }

##############################################################################
# _rsft()

void
_rsft(Class,x,y,base_sv)
        SV*     x
        SV*     y
        SV*     base_sv
  PREINIT:
        unsigned long   y_ui;
        mpz_t*  TEMP;
        mpz_t*  TEMP_1;
        mpz_t*  BASE;

  PPCODE:
    GMP_GET_ARGS_0_1;   /* (TEMP, TEMP_1) = (x,y)  */

    y_ui = mpz_get_ui(*TEMP_1);
    BASE = malloc (sizeof(mpz_t));
    mpz_init_set_ui(*BASE,SvUV(base_sv));

    mpz_pow_ui(*BASE, *BASE, y_ui); /* ">> 3 in base 4" => "x / (4 ** 3)" */
    mpz_div(*TEMP, *TEMP, *BASE);
    mpz_clear(*BASE);
    free(BASE);
    PUSHs( x );

##############################################################################
# _lsft()

void
_lsft(Class,x,y,base_sv)
        SV*     x
        SV*     y
        SV*     base_sv
  PREINIT:
        unsigned long   y_ui;
        mpz_t*  TEMP;
        mpz_t*  TEMP_1;
        mpz_t*  BASE;

  PPCODE:
    GMP_GET_ARGS_0_1;   /* (TEMP, TEMP_1) = (x,y)  */

    y_ui = mpz_get_ui(*TEMP_1);
    BASE = malloc (sizeof(mpz_t));
    mpz_init_set_ui(*BASE,SvUV(base_sv));

    mpz_pow_ui(*BASE, *BASE, y_ui); /* "<< 3 in base 4" => "x * (4 ** 3)" */
    mpz_mul(*TEMP, *TEMP, *BASE);
    mpz_clear(*BASE);
    free(BASE);
    PUSHs ( x );

##############################################################################
# _mul()

void
_mul(Class,x,y)
        SV*     x
        SV*     y
  PREINIT:
        mpz_t* TEMP;
        mpz_t* TEMP_1;
  PPCODE:
    GMP_GET_ARGS_0_1;   /* (TEMP, TEMP_1) = (x,y)  */
    mpz_mul(*TEMP, *TEMP, *TEMP_1);
    PUSHs( x );

##############################################################################
# _div(): x /= y or (x,rem) = x / y
# was in perl:
#sub _div
#  {
#  i f (wantarray)
#    {
#    # return (a/b,a%b)
#    my $r;
#    ($_[1],$r) = Math::BigInt::GMP::bdiv_two($_[1],$_[2]);
#    return ($_[1], $r);
#    }
#  # return a / b
#  Math::BigInt::GMP::div_two($_[1],$_[2]);
#  }

void
_div(Class,x,y)
        SV*     x
        SV*     y
  PREINIT:
    mpz_t* TEMP;
    mpz_t* TEMP_1;
    mpz_t * rem;
  PPCODE:
    GMP_GET_ARGS_0_1;   /* (TEMP, TEMP_1) = (x,y)  */
    if (GIMME_V == G_ARRAY)
      {
      /* former bdiv_two() routine */
      rem = malloc (sizeof(mpz_t));
      mpz_init(*rem);
      mpz_tdiv_qr(*TEMP, *rem, *TEMP, *TEMP_1);
      EXTEND(SP, 2);
      PUSHs( x );
      PUSHs(sv_2mortal(sv_from_mpz(rem)));
      }
    else
      {
      /* former div_two() routine */
      mpz_div(*TEMP, *TEMP, *TEMP_1);                   /* x /= y */
      PUSHs( x );
      }

##############################################################################
# _mod() - x %= y

void
_mod(Class,x,y)
        SV*     x
        SV*     y
  PREINIT:
        mpz_t* TEMP;
        mpz_t* TEMP_1;
  PPCODE:
    GMP_GET_ARGS_0_1;   /* (TEMP, TEMP_1) = (x,y)  */
    mpz_mod(*TEMP, *TEMP, *TEMP_1);
    PUSHs( x );

##############################################################################
# _acmp() - cmp two numbers

int
_acmp(Class,m,n)
        mpz_t * m
        mpz_t * n

  CODE:
    RETVAL = mpz_cmp(*m, *n);
    if ( RETVAL < 0) { RETVAL = -1; }
    if ( RETVAL > 0) { RETVAL = 1; }
  OUTPUT:
    RETVAL

##############################################################################
# _is_zero()

int
_is_zero(Class,x)
        mpz_t * x

  CODE:
    RETVAL = mpz_cmp_ui(*x, 0);
    if ( RETVAL != 0) { RETVAL = 0; } else { RETVAL = 1; }
  OUTPUT:
    RETVAL

##############################################################################
# _is_one()

int
_is_one(Class,x)
        mpz_t * x

  CODE:
    RETVAL = mpz_cmp_ui(*x, 1);
    if ( RETVAL != 0) { RETVAL = 0; } else { RETVAL = 1; }
  OUTPUT:
    RETVAL

##############################################################################
# _is_two()

int
_is_two(Class,x)
        mpz_t * x

  CODE:
    RETVAL = mpz_cmp_ui(*x, 2);
    if ( RETVAL != 0) { RETVAL = 0; } else { RETVAL = 1; }
  OUTPUT:
    RETVAL

##############################################################################
# _is_ten()

int
_is_ten(Class,x)
        mpz_t * x

  CODE:
    RETVAL = mpz_cmp_ui(*x, 10);
    if ( RETVAL != 0) { RETVAL = 0; } else { RETVAL = 1; }
  OUTPUT:
    RETVAL

##############################################################################
# _pow() - x **= y

void
_pow(Class,x,y)
        SV*     x
        SV*     y
  PREINIT:
        mpz_t* TEMP;
        mpz_t* TEMP_1;
  PPCODE:
    GMP_GET_ARGS_0_1;   /* (TEMP, TEMP_1) = (x,y)  */
    mpz_pow_ui(*TEMP, *TEMP, mpz_get_ui( *TEMP_1 ) );
    PUSHs( x );

##############################################################################
# _gcd() - gcd(m,n)

mpz_t *
_gcd(Class,x,y)
        mpz_t*  x
        mpz_t*  y

  CODE:
    NEW_GMP_MPZ_T_INIT;
    mpz_gcd(*RETVAL, *x, *y);
  OUTPUT:
    RETVAL

##############################################################################
# _and() - m &= n

void
_and(Class,x,y)
        SV*     x
        SV*     y
  PREINIT:
        mpz_t* TEMP;
        mpz_t* TEMP_1;
  PPCODE:
    GMP_GET_ARGS_0_1;   /* (TEMP, TEMP_1) = (x,y)  */
    mpz_and(*TEMP, *TEMP, *TEMP_1);
    PUSHs( x );


##############################################################################
# _xor() - m =^ n

void
_xor(Class,x,y)
        SV*     x
        SV*     y
  PREINIT:
        mpz_t* TEMP;
        mpz_t* TEMP_1;
  PPCODE:
    GMP_GET_ARGS_0_1;   /* (TEMP, TEMP_1) = (x,y)  */
    mpz_xor(*TEMP, *TEMP, *TEMP_1);
    PUSHs( x );


##############################################################################
# _or() - m =| n

void
_or(Class,x,y)
        SV*     x
        SV*     y
  PREINIT:
        mpz_t* TEMP;
        mpz_t* TEMP_1;
  PPCODE:
    GMP_GET_ARGS_0_1;   /* (TEMP, TEMP_1) = (x,y)  */
    mpz_ior(*TEMP, *TEMP, *TEMP_1);
    PUSHs( x );


##############################################################################
# _fac() - n! (factorial)

void
_fac(Class,x)
        SV*     x
  PREINIT:
        mpz_t* TEMP;
  PPCODE:
    GMP_GET_ARG_0;   /* TEMP = x */
    mpz_fac_ui(*TEMP, mpz_get_ui(*TEMP));
    PUSHs( x );


##############################################################################
# _copy()

mpz_t *
_copy(Class,m)
        mpz_t*  m

  CODE:
    NEW_GMP_MPZ_T;
    mpz_init_set(*RETVAL, *m);
  OUTPUT:
    RETVAL


##############################################################################
# _is_odd() - test for number being odd

int
_is_odd(Class,n)
        mpz_t*  n

  CODE:
   RETVAL = mpz_tstbit(*n,0);
  OUTPUT:
    RETVAL

##############################################################################
# _is_even() - test for number being even

int
_is_even(Class,n)
        mpz_t*  n

  CODE:
     RETVAL = ! mpz_tstbit(*n,0);
  OUTPUT:
    RETVAL

##############################################################################
# _sqrt() - square root

void
_sqrt(Class,x)
        SV*     x
  PREINIT:
        mpz_t* TEMP;
  PPCODE:
    GMP_GET_ARG_0;   /* TEMP = x */
    mpz_sqrt(*TEMP, *TEMP);
    PUSHs( x );


##############################################################################
# _root() - integer roots

void
_root(Class,x,y)
        SV*     x
        SV*     y
  PREINIT:
        mpz_t* TEMP;
        mpz_t* TEMP_1;
  PPCODE:
    GMP_GET_ARGS_0_1;   /* (TEMP, TEMP_1) = (x,y)  */
    mpz_root(*TEMP, *TEMP, mpz_get_ui(*TEMP_1));
    PUSHs( x );
