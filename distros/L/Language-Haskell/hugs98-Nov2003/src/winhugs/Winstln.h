/* --------------------------------------------------------------------------
 * WinSTLN.h:	José Enrique Gallardo Ruiz, Feb 1999
 *
 * The Hugs 98 system is Copyright (c) José Enrique Gallardo, Mark P Jones,
 * Alastair Reid, the Yale Haskell Group, and the OGI School of
 * Science & Engineering at OHSU, 1994-2003, All rights reserved.  It is
 * distributed as free software under the license in the file "License",
 * which is included in the distribution.
 *
 * This file contains the Header file for a status line definition
 * ------------------------------------------------------------------------*/

#define __WINSTLN_H

typedef struct TagSTLN {
   CHAR 	LeftText[256];
   CHAR 	ResizeBitmap[128];
   HINSTANCE 	hInstance;
} STLN;


typedef STLN 	*HSTLN;


/* Functions defined in WinSTLN.c that are exported */
HWND 	       STLNCreateWindow	   	(HINSTANCE, HWND, LPCSTR);
BOOL 	       STLNRegisterClass   	(HINSTANCE);

