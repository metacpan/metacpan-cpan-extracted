/*
 * Copyright (c) 2017--2021 by Jeffrey Ratcliffe <jffry@posteo.net>
 *
 * This library is free software; you can redistribute it and/or modify
 * it under the same terms as Perl itself, either Perl version 5.8.5 or,
 * at your option, any later version of Perl 5 you may have available.
 */

#ifndef TIFFPERL_H_
#define TIFFPERL_H_

// Include all of libtiff's headers for internal consistency
#include <tiffio.h>

// *_t types introduced in C99 and are therefore not available older compilers
#ifndef _BITS_STDINT_UINTN_H
#define _BITS_STDINT_UINTN_H 1
typedef uint16 uint16_t;
typedef uint32 uint32_t;
typedef uint64 uint64_t;
#endif  // _BITS_STDINT_UINTN_H

#endif  // TIFFPERL_H_
