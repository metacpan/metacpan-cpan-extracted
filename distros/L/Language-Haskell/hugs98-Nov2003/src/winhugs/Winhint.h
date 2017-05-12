/* --------------------------------------------------------------------------
 * WinHint.h:	José Enrique Gallardo Ruiz, Feb 1999
 *
 * The Hugs 98 system is Copyright (c) José Enrique Gallardo, Mark P Jones,
 * Alastair Reid, the Yale Haskell Group, and the OGI School of
 * Science & Engineering at OHSU, 1994-2003, All rights reserved.  It is
 * distributed as free software under the license in the file "License",
 * which is included in the distribution.
 *
 * This file contains the Header file for a hint window definition
 * ------------------------------------------------------------------------*/

#define __WINHINT_H

#define MAXLNG	64




typedef struct tagHINT {
  CHAR		HintStr[MAXLNG];	/* The message on the hint */
} HINT;

typedef HINT *HHINT;


/* Functions defined in WinTip.c that are exported */
HWND 	       HintCreateWindow	   	(HINSTANCE, HWND);
BOOL 	       HintRegisterClass   	(HINSTANCE);

