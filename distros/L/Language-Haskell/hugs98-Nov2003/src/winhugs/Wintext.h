/* --------------------------------------------------------------------------
 * WinText.h:	José Enrique Gallardo Ruiz, Feb 1999
 *		With very minor modifications by mpj/adr for Hugs, 1995-97
 *
 * The Hugs 98 system is Copyright (c) José Enrique Gallardo, Mark P Jones,
 * Alastair Reid, the Yale Haskell Group, and the OGI School of
 * Science & Engineering at OHSU, 1994-2003, All rights reserved.  It is
 * distributed as free software under the license in the file "License",
 * which is included in the distribution.
 *
 * This file contains the interface to Text.c module
 * ------------------------------------------------------------------------*/


#define __WINTEXT_H

#ifndef __STDIO_H
#include <stdio.h>
#endif


/* Some colors definitions to make output pretier */
#define BLACK           0
#define BLUE            1
#define GREEN           2
#define CYAN            3
#define RED             4
#define MAGENTA         5
#define YELLOW          6
#define WHITE           7
#define HIGHLIGHT      16
#define HIGHLIGHTTEXT  17

/* Definitions of some types */
typedef UCHAR HUGE*	FPOINTER;
typedef UCHAR* 		POINTER;


/* Functions defined in text.c that are exported */
HWND 	       CreateTextWindow	   (HINSTANCE, HWND, INT, INT, UINT, UINT, LPCSTR, INT, INT, HACCEL);
BOOL 	       RegisterTextClass   (HINSTANCE);
INT cdecl      hWndTextPrintf      (const CHAR *, ...);
INT cdecl      hWndTextFprintf     (FILE *, const CHAR *, ...);
INT            WinTextcolor        (HWND, INT);
INT            WinTextbackground   (HWND, INT);
BOOL           WinTextbright       (HWND, BOOL);
VOID           WinGotoxy           (HWND, UINT, UINT);
UINT           WinWherex           (HWND);
UINT           WinWherey           (HWND);
BOOL           WinSetinsert        (HWND, BOOL);
BOOL           WinSetcursor        (HWND, BOOL);
INT            WinPuts             (HWND, CHAR *);
INT 	       WinPutchar	   (HWND, CHAR);
INT	       WinPutc		   (HWND, CHAR, FILE*);
BOOL           WinKbhit            (HWND);
TCHAR          WinGetch            (HWND);
VOID           WinClrscr           (HWND);
VOID           WinClreol           (HWND);
CHAR 	      *WinGets             (HWND, CHAR *);
INT            WinGetc             (HWND, FILE*);
INT cdecl      WinPrintf           (HWND, const CHAR *, ...);
INT cdecl      WinFprintf          (HWND, FILE *, const CHAR *, ...);
CHAR          *GetSelectedText	   (HWND);
VOID 	       WinSetAllowBreak    (BOOL);
VOID           CreateTextFont      (HWND,LOGFONT*,INT);

/* ---------------------------------------------------------------------------
 * Now we map C standard I/O functions to the ones defined in Text.c
 * ------------------------------------------------------------------------ */

#define         printf          hWndTextPrintf
#define         fprintf         hWndTextFprintf
#undef          getc
#define         getc(x)         WinGetc(hWndText,(x))
#undef          putchar
#define         putchar(x)      WinPutchar(hWndText,(CHAR)(x))
#undef          putc
#define         putc(c,s)       WinPutc(hWndText,(CHAR)c,s)
//#define         fputc(c,s)      WinPutc(hWndText,c,s)
#define         kbhit()         WinKbhit(hWndText)
#undef          getchar
#define         getchar()       WinGetc(hWndText, stdin)
#define         getch()         WinGetch(hWndText)

/* fprintf (stdstr, ...) is used to direct output to the string stdstrbuff  */
extern FILE *stdstr;
extern char stdstrbuff[];

#define WM_CANCOPY 		WM_USER+1
#define WM_CANCUT 		WM_USER+2
#define WM_CANCLEAR 		WM_USER+3
#define WM_CANPASTE 		WM_USER+4
#define WM_GETINPUTBUFFER       WM_USER+5
#define WM_SETINPUTBUFFER       WM_USER+6
#define WM_GETBUFFERPOS       	WM_USER+7
#define WM_SETBUFFERPOS       	WM_USER+8
#define WM_GETLOGFONT       	WM_USER+9
#define WM_SETCURSORSTATUS     	WM_USER+10
#define WM_GOTOXY       	WM_USER+11
#define WM_GETTEXTMETRIC      	WM_USER+12
#define WM_SETTEXTFONT       	WM_USER+13

