/*
 * sample.xs - This file is in the public domain
 * Author: Salvador Fandino <sfandino@yahoo.com>, Dave Rolsky <autarch@urth.org>
 *
 * Generated on: 2024-01-21 22:00:15
 * Math::Int64 version: 0.56
 */

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"
#include "perl_math_int64.h"

MODULE = Math::Int64::C_API::Sample         PACKAGE = Math::Int64::C_API::Sample

BOOT:
    PERL_MATH_INT64_LOAD;

