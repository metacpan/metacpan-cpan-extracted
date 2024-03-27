
/*
 #######################################################
 # Warning: this file has been auto-generated
 # DO NOT EDIT if you can resist it.
 # neither edit typemap not GCC/Buildins.pm
 # make your edits in sbin/build-gcc-builtins-package.pl
 #######################################################
*/
#define PERL_NO_GET_CONTEXT // we'll define thread context if necessary (faster)
#include "EXTERN.h"         // globals/constant import locations
#include "perl.h"           // Perl symbols, structures and constants definition
#include "XSUB.h"           // xsubpp functions and macros
#include <stdlib.h>         // rand()

#ifndef __has_builtin
#error "Your compiler does not support builtin functions, note this is a naive and lame test."
#endif

typedef __int128 int128_t;
typedef unsigned __int128 uint128_t;

MODULE = GCC::Builtins  PACKAGE = GCC::Builtins
PROTOTYPES: ENABLE

 # The following XS code has been automatically generated:


uint16_t
bswap16(uint16_t x)
  CODE:
    RETVAL = __builtin_bswap16(x);
  OUTPUT:
    RETVAL


uint32_t
bswap32(uint32_t x)
  CODE:
    RETVAL = __builtin_bswap32(x);
  OUTPUT:
    RETVAL


uint64_t
bswap64(uint64_t x)
  CODE:
    RETVAL = __builtin_bswap64(x);
  OUTPUT:
    RETVAL


int
clrsb(int x)
  CODE:
    RETVAL = __builtin_clrsb(x);
  OUTPUT:
    RETVAL


int
clrsbl(long aaa)
  CODE:
    RETVAL = __builtin_clrsbl(aaa);
  OUTPUT:
    RETVAL


int
clrsbll(long long aaa)
  CODE:
    RETVAL = __builtin_clrsbll(aaa);
  OUTPUT:
    RETVAL


int
clz(unsigned int x)
  CODE:
    RETVAL = __builtin_clz(x);
  OUTPUT:
    RETVAL


int
clzl(unsigned long aaa)
  CODE:
    RETVAL = __builtin_clzl(aaa);
  OUTPUT:
    RETVAL


int
clzll(unsigned long long aaa)
  CODE:
    RETVAL = __builtin_clzll(aaa);
  OUTPUT:
    RETVAL


int
ctz(unsigned int x)
  CODE:
    RETVAL = __builtin_ctz(x);
  OUTPUT:
    RETVAL


int
ctzl(unsigned long aaa)
  CODE:
    RETVAL = __builtin_ctzl(aaa);
  OUTPUT:
    RETVAL


int
ctzll(unsigned long long aaa)
  CODE:
    RETVAL = __builtin_ctzll(aaa);
  OUTPUT:
    RETVAL


int
ffs(int x)
  CODE:
    RETVAL = __builtin_ffs(x);
  OUTPUT:
    RETVAL


int
ffsl(long aaa)
  CODE:
    RETVAL = __builtin_ffsl(aaa);
  OUTPUT:
    RETVAL


int
ffsll(long long aaa)
  CODE:
    RETVAL = __builtin_ffsll(aaa);
  OUTPUT:
    RETVAL


double
huge_val()
  CODE:
    RETVAL = __builtin_huge_val();
  OUTPUT:
    RETVAL


float
huge_valf()
  CODE:
    RETVAL = __builtin_huge_valf();
  OUTPUT:
    RETVAL


long double
huge_vall()
  CODE:
    RETVAL = __builtin_huge_vall();
  OUTPUT:
    RETVAL


double
inf()
  CODE:
    RETVAL = __builtin_inf();
  OUTPUT:
    RETVAL


_Decimal128
infd128()
  CODE:
    RETVAL = __builtin_infd128();
  OUTPUT:
    RETVAL


_Decimal32
infd32()
  CODE:
    RETVAL = __builtin_infd32();
  OUTPUT:
    RETVAL


_Decimal64
infd64()
  CODE:
    RETVAL = __builtin_infd64();
  OUTPUT:
    RETVAL


float
inff()
  CODE:
    RETVAL = __builtin_inff();
  OUTPUT:
    RETVAL


long double
infl()
  CODE:
    RETVAL = __builtin_infl();
  OUTPUT:
    RETVAL


double
nan(const char * str)
  CODE:
    RETVAL = __builtin_nan(str);
  OUTPUT:
    RETVAL


float
nanf(const char * str)
  CODE:
    RETVAL = __builtin_nanf(str);
  OUTPUT:
    RETVAL


long double
nanl(const char * str)
  CODE:
    RETVAL = __builtin_nanl(str);
  OUTPUT:
    RETVAL


int
parity(unsigned int x)
  CODE:
    RETVAL = __builtin_parity(x);
  OUTPUT:
    RETVAL


int
parityl(unsigned long aaa)
  CODE:
    RETVAL = __builtin_parityl(aaa);
  OUTPUT:
    RETVAL


int
parityll(unsigned long long aaa)
  CODE:
    RETVAL = __builtin_parityll(aaa);
  OUTPUT:
    RETVAL


int
popcount(unsigned int x)
  CODE:
    RETVAL = __builtin_popcount(x);
  OUTPUT:
    RETVAL


int
popcountl(unsigned long aaa)
  CODE:
    RETVAL = __builtin_popcountl(aaa);
  OUTPUT:
    RETVAL


int
popcountll(unsigned long long aaa)
  CODE:
    RETVAL = __builtin_popcountll(aaa);
  OUTPUT:
    RETVAL


double
powi(double aaa,int aab)
  CODE:
    RETVAL = __builtin_powi(aaa,aab);
  OUTPUT:
    RETVAL


float
powif(float aaa,int aab)
  CODE:
    RETVAL = __builtin_powif(aaa,aab);
  OUTPUT:
    RETVAL


long double
powil(long double aaa,int aab)
  CODE:
    RETVAL = __builtin_powil(aaa,aab);
  OUTPUT:
    RETVAL

