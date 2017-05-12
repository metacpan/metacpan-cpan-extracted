/* --------------------------------------------------------------------------
 * WinUtils.h:	José Enrique Gallardo Ruiz, Feb 1999
 *
 * The Hugs 98 system is Copyright (c) José Enrique Gallardo, Mark P Jones,
 * Alastair Reid, the Yale Haskell Group, and the OGI School of
 * Science & Engineering at OHSU, 1994-2003, All rights reserved.  It is
 * distributed as free software under the license in the file "License",
 * which is included in the distribution.
 *
 * This file contains the Header file for some common functions
 * ------------------------------------------------------------------------*/

#define __WINUTILS_H

VOID 	CenterDialogInParent 	(HWND);
VOID	SetDialogFont		(HWND, HFONT);
BOOL 	CheckExt 		(LPCSTR, LPCSTR);
VOID 	DrawTransparentBitmap	(HDC, HBITMAP, UINT, UINT, COLORREF);
VOID 	DrawBitmap 		(HDC, HBITMAP, UINT, UINT);
VOID 	ExecDialog 		(HINSTANCE, WORD, WNDPROC);
VOID	FullPath		(LPSTR, LPCSTR);
VOID	MapBitmap 		(HBITMAP, COLORREF, COLORREF);
HBITMAP LoadMappedBitmap	(HINSTANCE, LPCSTR);
HBITMAP ResizeBitmap            (HBITMAP, UINT, UINT);
INT 	SetWorkingDir 		(LPCSTR);
VOID 	StrReplace		(CHAR*, CHAR*, CHAR*, CHAR*);
VOID    ShortFileName           (CHAR *, CHAR *);
