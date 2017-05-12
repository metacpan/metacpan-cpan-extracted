/* Filename: Mcrypt.xs
 * Author:   Theo Schlossnagle <jesus@omniti.com>
 * Created:  17th January 2001
 * Version:  2.5.7.0
 *
 * Copyright (c) 1999 Theo Schlossnagle. All rights reserved.
 *   This program is free software; you can redistribute it and/or
 *   modify it under the same terms as Perl itself.
 *
 */

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <mcrypt.h>

#ifndef PERL_VERSION
#include "patchlevel.h"
#define PERL_REVISION   5
#define PERL_VERSION    PATCHLEVEL
#define PERL_SUBVERSION SUBVERSION
#endif

#if PERL_REVISION == 5 && (PERL_VERSION < 4 || (PERL_VERSION == 4 && PERL_SUBVERSION <= 75 ))

#    define PL_sv_undef         sv_undef
#    define PL_na               na
#    define PL_curcop           curcop
#    define PL_compiling        compiling

#endif

SV *sv_NULL ;

static int
not_here(s)
char *s;
{
    croak("%s not implemented on this architecture", s);
    return -1;
}

static SV *
constant(name, arg)
char *name;
int arg;
{
  errno = 0;
  switch (*name) {
	case '3':
	if(strEQ(name, "3DES"))
#ifdef MCRYPT_3DES
		return newSVpv(MCRYPT_3DES, 0);
#else
		goto not_there;
#endif
	break;
	case 'A':
	if(strEQ(name, "ARCFOUR"))
#ifdef MCRYPT_ARCFOUR
		return newSVpv(MCRYPT_ARCFOUR, 0);
#else
		goto not_there;
#endif
	break;
	case 'B':
	if(strEQ(name, "BLOWFISH"))
#ifdef MCRYPT_BLOWFISH
		return newSVpv(MCRYPT_BLOWFISH, 0);
#else
		goto not_there;
#endif
	break;
	case 'C':
	if(strEQ(name, "CAST_128"))
#ifdef MCRYPT_CAST_128
		return newSVpv(MCRYPT_CAST_128, 0);
#else
		goto not_there;
#endif
	if(strEQ(name, "CAST_256"))
#ifdef MCRYPT_CAST_256
		return newSVpv(MCRYPT_CAST_256, 0);
#else
		goto not_there;
#endif
	if(strEQ(name, "CBC"))
#ifdef MCRYPT_CBC
		return newSVpv(MCRYPT_CBC, 0);
#else
		goto not_there;
#endif
	if(strEQ(name, "CFB"))
#ifdef MCRYPT_CFB
		return newSVpv(MCRYPT_CFB, 0);
#else
		goto not_there;
#endif
	break;
	case 'D':
	if(strEQ(name, "DES"))
#ifdef MCRYPT_DES
		return newSVpv(MCRYPT_DES, 0);
#else
		goto not_there;
#endif
	break;
	case 'E':
	if(strEQ(name, "ECB"))
#ifdef MCRYPT_ECB
		return newSVpv(MCRYPT_ECB, 0);
#else
		goto not_there;
#endif
	if(strEQ(name, "ENIGMA"))
#ifdef MCRYPT_ENIGMA
		return newSVpv(MCRYPT_ENIGMA, 0);
#else
		goto not_there;
#endif
	break;
	case 'G':
	if(strEQ(name, "GOST"))
#ifdef MCRYPT_GOST
		return newSVpv(MCRYPT_GOST, 0);
#else
		goto not_there;
#endif
	break;
	case 'L':
	if(strEQ(name, "LOKI97"))
#ifdef MCRYPT_LOKI97
		return newSVpv(MCRYPT_LOKI97, 0);
#else
		goto not_there;
#endif
	break;
	case 'n':
	if(strEQ(name, "nOFB"))
#ifdef MCRYPT_nOFB
		return newSVpv(MCRYPT_nOFB, 0);
#else
		goto not_there;
#endif
	break;
	case 'O':
	if(strEQ(name, "OFB"))
#ifdef MCRYPT_OFB
		return newSVpv(MCRYPT_OFB, 0);
#else
		goto not_there;
#endif
	break;
	case 'R':
	if(strEQ(name, "RC2"))
#ifdef MCRYPT_RC2
		return newSVpv(MCRYPT_RC2, 0);
#else
		goto not_there;
#endif
	if(strEQ(name, "RIJNDAEL_128"))
#ifdef MCRYPT_RIJNDAEL_128
		return newSVpv(MCRYPT_RIJNDAEL_128, 0);
#else
		goto not_there;
#endif
	if(strEQ(name, "RIJNDAEL_192"))
#ifdef MCRYPT_RIJNDAEL_192
		return newSVpv(MCRYPT_RIJNDAEL_192, 0);
#else
		goto not_there;
#endif
	if(strEQ(name, "RIJNDAEL_256"))
#ifdef MCRYPT_RIJNDAEL_256
		return newSVpv(MCRYPT_RIJNDAEL_256, 0);
#else
		goto not_there;
#endif
	break;
	case 'S':
	if(strEQ(name, "SAFERPLUS"))
#ifdef MCRYPT_SAFERPLUS
		return newSVpv(MCRYPT_SAFERPLUS, 0);
#else
		goto not_there;
#endif
	if(strEQ(name, "SERPENT"))
#ifdef MCRYPT_SERPENT
		return newSVpv(MCRYPT_SERPENT, 0);
#else
		goto not_there;
#endif
	if(strEQ(name, "STREAM"))
#ifdef MCRYPT_STREAM
		return newSVpv(MCRYPT_STREAM, 0);
#else
		goto not_there;
#endif
	break;
	case 'T':
	if(strEQ(name, "TWOFISH"))
#ifdef MCRYPT_TWOFISH
		return newSVpv(MCRYPT_TWOFISH, 0);
#else
		goto not_there;
#endif
	break;
	case 'W':
	if(strEQ(name, "WAKE"))
#ifdef MCRYPT_WAKE
		return newSVpv(MCRYPT_WAKE, 0);
#else
		goto not_there;
#endif
	break;
	case 'X':
	if(strEQ(name, "XTEA"))
#ifdef MCRYPT_XTEA
		return newSVpv(MCRYPT_XTEA, 0);
#else
		goto not_there;
#endif
	break;
      default:
	goto not_there;
    }
    errno = EINVAL;
    return 0;
not_there:
    errno = ENOENT;
    return 0;
}

MODULE = Mcrypt	PACKAGE = Mcrypt	PREFIX = CR_

REQUIRE:	1.9505
PROTOTYPES:	DISABLE

BOOT:
	sv_NULL = newSVpv("", 0) ;

SV *
constant(name,arg)
        char *          name
        int             arg

SV *
CR_ERROR(mcrypt)
	MCRYPT mcrypt
	CODE:
	  RETVAL = newSVpv((char *)mcrypt_strerror((int)mcrypt), 0);
	OUTPUT:
	  RETVAL

MCRYPT
CR_mcrypt_load(alg, a_path, mode, m_path)
	char *alg
        char *a_path
        char *mode
        char *m_path
        PREINIT:
        MCRYPT td;
	CODE:
	  td = mcrypt_module_open(alg, a_path, mode, m_path);
          RETVAL = td;
	OUTPUT:
	  RETVAL

SV *
CR_mcrypt_unload(mcrypt)
        MCRYPT mcrypt
        CODE:
          mcrypt_module_close(mcrypt);
          RETVAL = &PL_sv_yes;
        OUTPUT:
          RETVAL

SV *
CR_mcrypt_init(mcrypt, key, iv)
        MCRYPT mcrypt
        SV * key
        SV * iv
        PREINIT:
          char *ckey, *civ;
        CODE:
        {
          ckey = SvPV(key, PL_na);
	  if(iv == &PL_sv_undef) civ = NULL;
	  else civ = SvPV(iv, PL_na);
	  if(mcrypt_generic_init(mcrypt, ckey, SvCUR(key), civ) < 0)
	    RETVAL = &PL_sv_no;
	  else RETVAL = &PL_sv_yes;
	}
        OUTPUT:
          RETVAL

SV *
CR_mcrypt_end(mcrypt)
        MCRYPT mcrypt
        CODE:
          mcrypt_generic_end(mcrypt);
          RETVAL = &PL_sv_yes;
        OUTPUT:
          RETVAL

int
CR_mcrypt_get_key_size(mcrypt)
        MCRYPT mcrypt
        CODE:
          RETVAL = mcrypt_enc_get_key_size(mcrypt);
        OUTPUT:
          RETVAL

SV *
CR_mcrypt_is_block_algorithm_mode(mcrypt)
        MCRYPT mcrypt
        CODE:
          RETVAL = (mcrypt_enc_is_block_algorithm_mode(mcrypt))?
		&PL_sv_yes:&PL_sv_no;;
        OUTPUT:
          RETVAL

int
CR_mcrypt_get_block_size(mcrypt)
        MCRYPT mcrypt
        CODE:
          RETVAL = mcrypt_enc_get_block_size(mcrypt);
        OUTPUT:
          RETVAL

int
CR_mcrypt_get_iv_size(mcrypt)
        MCRYPT mcrypt
        CODE:
          RETVAL = mcrypt_enc_get_iv_size(mcrypt);
        OUTPUT:
          RETVAL

SV *
CR_mcrypt_encrypt(mcrypt, input)
        MCRYPT mcrypt
        SV * input
        PREINIT:
          char *coutput;
        CODE:
          {
	    coutput = (char *)malloc(SvCUR(input));
	    memcpy(coutput, SvPV(input, PL_na), SvCUR(input));
	    mcrypt_generic(mcrypt, coutput, SvCUR(input));
	    RETVAL = newSVpv(coutput, SvCUR(input));
	    free(coutput);
	  }
        OUTPUT:
          RETVAL

SV *
CR_mcrypt_decrypt(mcrypt, output)
        MCRYPT mcrypt
        SV * output
        PREINIT:
          char *cinput;
        CODE:
          {
	    cinput = (char *)malloc(SvCUR(output));
	    memcpy(cinput, SvPV(output, PL_na), SvCUR(output));
	    mdecrypt_generic(mcrypt, cinput, SvCUR(output));
	    RETVAL = newSVpv(cinput, SvCUR(output));
	    free(cinput);
	  }
        OUTPUT:
          RETVAL
