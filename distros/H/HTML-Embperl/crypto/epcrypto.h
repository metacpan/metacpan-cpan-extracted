/*###################################################################################
#
#   Embperl - Copyright (c) 1997-2001 Gerald Richter / ECOS
#
#   You may distribute under the terms of either the GNU General Public
#   License or the Artistic License, as specified in the Perl README file.
#   For use with Apache httpd and mod_perl, see also Apache copyright.
#
#   THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR
#   IMPLIED WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED
#   WARRANTIES OF MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.
#
#   $Id: epcrypto.h,v 1.2 2001/09/08 13:23:22 richter Exp $
#
###################################################################################*/

#include "epcrypto_config.h"

#ifdef EPC_ENABLE

/* ----------------------------------------------------------------------------
*
* File Signature 
*
* -------------------------------------------------------------------------- */

#define EPC_HEADER "\x55\xAA\xFF\x01EPCPRYT\x55\xAA\xFF\x01"

/* ----------------------------------------------------------------------------
*
* Functions
*
* -------------------------------------------------------------------------- */

int do_crypt_file(FILE *    in, 
                  FILE *    out, 
                  char *    output, 
                  int       outsize, 
                  int       do_encrypt, 
                  unsigned char * begin, 
                  unsigned char * header) ;


#endif

