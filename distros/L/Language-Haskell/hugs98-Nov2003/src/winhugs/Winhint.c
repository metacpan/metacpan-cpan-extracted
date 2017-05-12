/* --------------------------------------------------------------------------
 * WinHint.c:	José Enrique Gallardo Ruiz, Feb 1999
 *
 * The Hugs 98 system is Copyright (c) José Enrique Gallardo, Mark P Jones,
 * Alastair Reid, the Yale Haskell Group, and the OGI School of
 * Science & Engineering at OHSU, 1994-2003, All rights reserved.  It is
 * distributed as free software under the license in the file "License",
 * which is included in the distribution.
 *
 * This file contains the implementation of hint windows
 * ------------------------------------------------------------------------*/

#include "..\Prelude.h"

#if HUGS_FOR_WINDOWS
#define STRICT 1

#ifndef __WINHINT_H
#include "WinHint.h"
#endif
#ifndef __WINUTILS_H
#include "WinUtils.h"
#endif
#ifndef __ALLOC_H
#include <malloc.h>
#endif

/* --------------------------------------------------------------------------
 * Some defined values:
 * ------------------------------------------------------------------------*/

#define HMARGIN			5
#define VMARGIN			7

#define VSEPARATION		0
#define SEPARATORSPACE		4

#define BACKRGB 		GetSysColor(COLOR_INFOBK)
#define FORERGB			GetSysColor(COLOR_INFOTEXT)

/* Borders of hints */
#define HLP_H_BORDER		3
#define HLP_V_BORDER		2

/* --------------------------------------------------------------------------
 * Local functions protoypes:
 * ------------------------------------------------------------------------*/

LRESULT CALLBACK HINTWndProc (HWND, UINT, WPARAM, LPARAM);


static LRESULT 		      DoCreate	    (HWND, UINT, WPARAM, LPARAM);
static LRESULT 		      DoDestroy	    (HWND, UINT, WPARAM, LPARAM);
static LRESULT 		      DoPaint	    (HWND, UINT, WPARAM, LPARAM);
static LRESULT 		      DoSetText	    (HWND, UINT, WPARAM, LPARAM);


/* --------------------------------------------------------------------------
 * Exported functions:
 * ------------------------------------------------------------------------*/

/* Register Hint window class */
BOOL HintRegisterClass(HINSTANCE hInstance)
{
  WNDCLASS  wc;

  /* Register Hint class */
  wc.style = CS_SAVEBITS;
  wc.lpfnWndProc = HINTWndProc;
  wc.cbWndExtra = (INT) sizeof(HHINT *);
  wc.cbClsExtra	= 0;
  wc.hInstance = hInstance;
  wc.hIcon = NULL;
  wc.hCursor = NULL;
  wc.hbrBackground = CreateSolidBrush(BACKRGB);
  wc.lpszMenuName = NULL;
  wc.lpszClassName = "HintWindow";

  return RegisterClass(&wc);
}


/* Creates a Hint */
HWND HintCreateWindow (HINSTANCE hInstance, HWND hWndParent)
{
  HWND  hWnd;

  hWnd = CreateWindow(
		"HintWindow",
		NULL,
		WS_POPUP | SS_LEFT,
		0,0,0,0,
		hWndParent, //GetDesktopWindow(),
		NULL,
		hInstance,
		NULL
  );

  return hWnd;
}


/* --------------------------------------------------------------------------
 * Local functions:
 * ------------------------------------------------------------------------*/


static LRESULT DoCreate (HWND hWnd, UINT message, WPARAM wParam, LPARAM lParam)
{
  HHINT hHINT;

  /* Get window structure */
  hHINT = (HHINT) malloc(sizeof(HINT));
  if (!hHINT)
    return -1;

  memset(hHINT, 0, sizeof(HINT));
  SetWindowLong(hWnd, 0, (LONG) hHINT);

  return 0;
}


static LRESULT DoDestroy (HWND hWnd, UINT message, WPARAM wParam, LPARAM lParam)
{
  HHINT hHINT;

  hHINT = (HHINT) GetWindowLong(hWnd, 0);

  free(hHINT);

  return 0;
}


static LRESULT DoPaint (HWND hWnd, UINT message, WPARAM wParam, LPARAM lParam)
{

  HHINT hHINT;
  PAINTSTRUCT	Ps;
  HFONT 	hSmall, hOld;
  RECT		aRect;
  INT		OldBkMode;
  HBRUSH	hBrush, hOldBrush;
  HPEN		hPen, hOldPen;
  COLORREF  svColor;

  hHINT = (HHINT) GetWindowLong(hWnd, 0);

  BeginPaint (hWnd, &Ps);

  /* Get a small font and select it */
  hSmall = (HFONT) GetStockObject(ANSI_VAR_FONT);
  if (hSmall)
    hOld = SelectObject (Ps.hdc, hSmall);

  GetClientRect(hWnd, &aRect);

  OldBkMode = SetBkMode (Ps.hdc, TRANSPARENT);

  hBrush = CreateSolidBrush(BACKRGB);
  hOldBrush = SelectObject(Ps.hdc, hBrush);
  hPen = CreatePen(PS_SOLID, 1, FORERGB);
  hOldPen = SelectObject(Ps.hdc, hPen);
  Rectangle (Ps.hdc, aRect.left, aRect.top, aRect.right, aRect.bottom);
  SelectObject(Ps.hdc, hOldBrush);
  DeleteObject (hBrush);
  SelectObject(Ps.hdc, hOldPen);
  DeleteObject (hPen);

  aRect.left   += HLP_H_BORDER;
  aRect.top    += HLP_V_BORDER;
  aRect.right  -= HLP_H_BORDER;
  aRect.bottom -= HLP_V_BORDER;

  svColor = SetTextColor(Ps.hdc, FORERGB);
  DrawText(Ps.hdc, (LPCSTR) hHINT->HintStr, strlen((CHAR *)hHINT->HintStr), &aRect, DT_LEFT|DT_VCENTER|DT_SINGLELINE);
  SetBkMode (Ps.hdc, OldBkMode);
  SetTextColor(Ps.hdc, svColor);

  /* Select old font */
  if (hOld)
    SelectObject (Ps.hdc, hOld);

  EndPaint (hWnd, &Ps);

  return 0;
}


static LRESULT DoSetText (HWND hWnd, UINT message, WPARAM wParam, LPARAM lParam)
{
  HHINT hHINT;
  HDC   hDC;
  RECT  rc;
  HFONT hSmall, hOld;

  hHINT = (HHINT) GetWindowLong(hWnd, 0);

  /* Set hint string */
  strcpy (hHINT->HintStr, (LPSTR)lParam);

  hDC = GetDC (hWnd);

  /* Get a small font and select it */
  hSmall = (HFONT) GetStockObject(ANSI_VAR_FONT);
  if (hSmall)
    hOld = SelectObject (hDC, hSmall);

  /* Set right size to show hint */
  rc.left =  rc.top  = 10;
  DrawText(hDC, (LPCSTR)hHINT->HintStr, strlen((CHAR *)hHINT->HintStr), &rc, DT_CALCRECT);
  rc.left   -= HLP_H_BORDER;
  rc.right  += HLP_H_BORDER;
  rc.top    -= HLP_V_BORDER;
  rc.bottom += HLP_V_BORDER;
  MoveWindow (hWnd, rc.left, rc.top,
	      rc.right-rc.left+1, rc.bottom-rc.top+1, FALSE);

  /* Select old font */
  if (hOld)
    SelectObject (hDC, hOld);

  ReleaseDC (hWnd, hDC);

  return 0;
}


LRESULT CALLBACK HINTWndProc(HWND hWnd, UINT message, WPARAM wParam, LPARAM lParam)
{
  switch (message)
  {
     case WM_CREATE:      return DoCreate 	(hWnd, message, wParam, lParam);

     case WM_DESTROY:     return DoDestroy 	(hWnd, message, wParam, lParam);

     case WM_PAINT:       return DoPaint 	(hWnd, message, wParam, lParam);

     case WM_SETTEXT:     return DoSetText 	(hWnd, message, wParam, lParam);

     default:        	  return (DefWindowProc(hWnd, message, wParam, lParam));
  }

  return FALSE;
}







#endif // HUGS_FOR_WINDOWS
