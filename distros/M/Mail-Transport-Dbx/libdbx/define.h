/***************************************************************************
                          define.h  -  Contains my debug macros
                             -------------------
    begin                : January 2001
    copyright            : (C) 2001 by David Smith
    email                : Dave.S@Earthcorp.com
 ***************************************************************************/

/***************************************************************************
 *                                                                         *
 *   This program is free software; you can redistribute it and/or modify  *
 *   it under the terms of the GNU General Public License as published by  *
 *   the Free Software Foundation; either version 2 of the License, or     *
 *   (at your option) any later version.                                   *
 *                                                                         *
 ***************************************************************************/

/****************************************************************
 * Heavily patched to make the macro definitions ANSI-C compliant 
 * **************************************************************/

/* #define DEBUG_ALL */

#ifndef DEFINEH_H
#define DEFINEH_H

#include <stdio.h>

/* netinet/in.h makes FreeBSD croak: 
 * fortunately it appears to be superfluous */
/* #include <netinet/in.h> */

/* Not necessarily existing on Win */
#ifdef I_UNISTD
# include <unistd.h>
#endif
#ifdef I_SYS_TYPES
# include <sys/types.h>
#endif

#define RET_ERROR(res, ret_val)\
	if (res) { \
        dbx_errno = ret_val; \
        return -1; \
    }	

#endif /* DEFINEH_H */

