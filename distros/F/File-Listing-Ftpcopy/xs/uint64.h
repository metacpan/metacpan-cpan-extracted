/* Reimplementation of Daniel J. Bernsteins uint library.
 * (C) 2001 Uwe Ohse, <uwe@ohse.de>.
 *   Report any bugs to <uwe@ohse.de>.
 * Placed in the public domain.
 */
#ifndef UINT64_H
#define UINT64_H
#include "typesize.h"
#ifndef HAVE_UINT64
#error No 64bit unisgned integer type found.
#endif
#define uint64 uo_uint64_t
extern unsigned int scan_xint64(const char *,uint64 *); /* uo extension */ 
#endif
