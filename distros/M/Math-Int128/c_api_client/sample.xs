/*
 * sample.xs - This file is in the public domain
 * Author: "Salvador Fandino <sfandino@yahoo.com>, Dave Rolsky <autarch@urth.org>"
 *
 * Generated on: 2015-04-07 16:08:19
 * Math::Int128 version: 0.22
 */

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"
#include "perl_math_int128.h"

MODULE = Math::Int128::C_API::Sample         PACKAGE = Math::Int128::C_API::Sample

BOOT:
    PERL_MATH_INT128_LOAD;

