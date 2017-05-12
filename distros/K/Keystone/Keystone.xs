/****************************************************************************/
/* perl-keystone - A Perl wrapper for the keystone-engine library           */
/*                                                                          */
/* Copyright 2015, -TOSH-                                                   */
/* File coded by -TOSH-                                                     */
/*                                                                          */
/* This file is part of perl-keystone.                                      */
/*                                                                          */
/* perl-keystone is free software: you can redistribute it and/or modify    */
/* it under the terms of the GNU General Public License as published by     */
/* the Free Software Foundation, either version 3 of the License, or        */
/* (at your option) any later version.                                      */
/*                                                                          */
/* perl-keystone is distributed in the hope that it will be useful,         */
/* but WITHOUT ANY WARRANTY; without even the implied warranty of           */
/* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the            */
/* GNU General Public License for more details.                             */
/*                                                                          */
/* You should have received a copy of the GNU General Public License        */
/* along with perl-keystone.  If not, see <http://www.gnu.org/licenses/>    */
/****************************************************************************/

/* Perl XS wrapper for keystone-engine */

#ifdef KEYSTONE_FROM_PKGCONFIG
#include <keystone.h>
#else
#include <keystone/keystone.h>
#endif

#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"


MODULE = Keystone   PACKAGE = ks_enginePtr  PREFIX = ksh_engine_

# ksh_engine object destructor
void
ksh_engine_DESTROY(handle)
    ks_engine *handle

    CODE:
        ks_close(handle);



MODULE = Keystone   PACKAGE = Keystone


# Wrapper to ks_version()
SV*
ks_version()

    PREINIT:
        int major, minor;

    PPCODE:
        ks_version(&major, &minor);

        EXTEND(SP, 2);
        XST_mIV(0, major);
        XST_mIV(1, minor);
        XSRETURN(2);

# Wrapper to ks_arch_supported
int
ks_arch_supported(arch)
    ks_arch arch

    CODE:
        RETVAL = ks_arch_supported(arch);

    OUTPUT:
        RETVAL


# Wrapper to ks_open()
ks_engine*
ks_open(arch,mode)
    ks_arch arch
    ks_mode mode

    PREINIT:
        ks_err err;

    CODE:

        err = ks_open(arch, mode, &RETVAL);

        if(err != KS_ERR_OK) {
            XSRETURN_UNDEF;
        }

    OUTPUT:
        RETVAL


# Wrapper to ks_asm()
SV*
ks_asm(handle,code,address)
    ks_engine *handle
    SV *code
    UV address

    PREINIT:
        size_t size, i, count;
        unsigned char *opcodes;
        int ret;

    PPCODE:

        if(SvTYPE(code) != SVt_PV) {
            croak("<code> argument not an array scalar");
        }

        ret = ks_asm(handle, SvPVbyte(code, SvCUR(code)), address, &opcodes, &size, &count);
        if(!ret) {
            for(i = 0; i < size; i++) {
                PUSHs(newSViv(opcodes[i]));
            }
        }

        ks_free(opcodes);


# Wrapper to ks_errno
ks_err
ks_errno(handle)
    ks_engine *handle

    CODE:
        RETVAL = ks_errno(handle);

    OUTPUT:
        RETVAL


# Wrapper to ks_strerror
const char *
ks_strerror(err)
    ks_err err

    CODE:
        RETVAL = ks_strerror(err);

    OUTPUT:
        RETVAL


# Wrapper to ks_option
ks_err
ks_option(handle, type, value)
    ks_engine *handle
    int type
    int value

    CODE:
        RETVAL = ks_option(handle, type, value);

    OUTPUT:
        RETVAL
