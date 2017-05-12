/* --------------------------------------------------------------------------
 * WinFrame.h:	José Enrique Gallardo Ruiz, Feb 1999
 *
 * The Hugs 98 system is Copyright (c) José Enrique Gallardo, Mark P Jones,
 * Alastair Reid, the Yale Haskell Group, and the OGI School of
 * Science & Engineering at OHSU, 1994-2003, All rights reserved.  It is
 * distributed as free software under the license in the file "License",
 * which is included in the distribution.
 *
 * This file contains the Header file for a frame window definition
 * ------------------------------------------------------------------------*/


#define __WINFRAME_H

typedef struct TagFRAME {
   HWND		hWndSTLN;
   HWND		hWndTB;
   HWND		hWndChild;
   HINSTANCE	hInstance;
} FRAME;


typedef FRAME 	*HFRAME;


/* Functions defined in WinFrame.c that are exported */
HWND 	       FRAMECreateWindow	(HINSTANCE, LPCSTR, WNDPROC, WNDPROC*, HWND, LPCSTR, LPCSTR, LPCSTR, LPCSTR);
BOOL 	       FRAMERegisterClass	(HINSTANCE);
HWND	       FRAMEGetTB		(HWND);
HWND	       FRAMEGetSTLN		(HWND);
INT 	       FRAMEGetRightBorderSize	(HWND);
VOID	       FRAMESetChild		(HWND, HWND);
BOOL	       FRAMESuperclass 		(HINSTANCE, LPCSTR, LPCSTR, LPCSTR);

