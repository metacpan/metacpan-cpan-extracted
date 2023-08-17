/*
 * Copyright (c) 2017--2023 by Jeffrey Ratcliffe <jffry@posteo.net>
 *
 * This library is free software; you can redistribute it and/or modify
 * it under the same terms as Perl itself, either Perl version 5.8.5 or,
 * at your option, any later version of Perl 5 you may have available.
 */

#ifndef TIFFPERL_H_
#define TIFFPERL_H_

// Include all of libtiff's headers for internal consistency
#include <tiffio.h>

/*
 * *_t types aren't defined by msvcrt which ming64 (used by Strawberry Perl)
 * uses instead of glibc
 */
#ifdef __MINGW32__
typedef uint8 uint8_t;
typedef uint16 uint16_t;
typedef uint32 uint32_t;
typedef uint64 uint64_t;
#endif

#endif  // TIFFPERL_H_
