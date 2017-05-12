package KinoSearch1::Util::MathUtils;
use strict;
use warnings;
use base qw( Exporter );
our @EXPORT_OK = qw( ceil );

1;

__END__


__XS__

MODULE = KinoSearch1    PACKAGE = KinoSearch1::Util::MathUtils

double
ceil(in)
    double in;
CODE:
    RETVAL = ceil(in);
OUTPUT: RETVAL

__H__

#ifndef H_KINOSEARCH_UTIL_MATH_UTILS
#define H_KINOSEARCH_UTIL_MATH_UTILS 1

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "KinoSearch1UtilMemManager.h"

void Kino1_encode_bigend_U32(U32, void*);
void Kino1_encode_bigend_U16(U16, void*);
U32 Kino1_decode_bigend_U32(void*);
U16 Kino1_decode_bigend_U16(void*);

#endif /* include guard */

__C__

#include "KinoSearch1UtilMathUtils.h"

void Kino1_encode_bigend_U32(U32 aU32, void *vbuf) {
    unsigned char *buf;
    
    buf        = (unsigned char*)vbuf;
    * buf      = (aU32 & 0xff000000) >> 24;
    *(buf + 1) = (aU32 & 0x00ff0000) >> 16;
    *(buf + 2) = (aU32 & 0x0000ff00) >> 8;
    *(buf + 3) = (aU32 & 0x000000ff);
}

void Kino1_encode_bigend_U16(U16 aU16, void *vbuf) {
    unsigned char *buf;
    
    buf        = (unsigned char*)vbuf;
    * buf      = (aU16 & 0xff00) >> 8;
    *(buf + 1) = (aU16 & 0x00ff);
}

U32 Kino1_decode_bigend_U32(void *vbuf) {
    unsigned char *buf;
    U32 aU32;
    
    buf  = (unsigned char*)vbuf;
    aU32 = (* buf      << 24) |
           (*(buf + 1) << 16) |
           (*(buf + 2) << 8)  |
            *(buf + 3);
    return aU32;
}

U16 Kino1_decode_bigend_U16(void *vbuf) {
    unsigned char *buf;
    U16 aU16;
    
    buf  = (unsigned char*)vbuf;
    aU16 = (*buf << 8) | *(buf + 1);
    return aU16;
}


__POD__


==begin devdocs

==head1 NAME

KinoSearch1::Util::MathUtils - various math utilities

==head1 DESCRIPTION

Provide various math related utilities, including endcoding/decoding integers
in guaranteed Big-endian byte order.

==head1 COPYRIGHT

Copyright 2005-2010 Marvin Humphrey

==head1 LICENSE, DISCLAIMER, BUGS, etc.

See L<KinoSearch1> version 1.01.

==end devdocs
==cut

