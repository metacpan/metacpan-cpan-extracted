/* --------------------------------------------------------------------------
 * WinSTLN.c:	José Enrique Gallardo Ruiz, Feb 1999
 *
 * The Hugs 98 system is Copyright (c) José Enrique Gallardo, Mark P Jones,
 * Alastair Reid, the Yale Haskell Group, and the OGI School of
 * Science & Engineering at OHSU, 1994-2003, All rights reserved.  It is
 * distributed as free software under the license in the file "License",
 * which is included in the distribution.
 *
 * This file contains the implementation of a status line
 * ------------------------------------------------------------------------*/

#include "..\Prelude.h"

#if HUGS_FOR_WINDOWS
#define STRICT 1

#ifndef __WINSTLN_H
#include "WinSTLN.h"
#endif
#ifndef __WINUTILS_H
#include "WinUtils.h"
#endif
#ifndef __ALLOC_H
#include <malloc.h>
#endif


/* --------------------------------------------------------------------------
 * Local functions protoypes:
 * ------------------------------------------------------------------------*/

LRESULT CALLBACK STLNWndProc (HWND, UINT, WPARAM, LPARAM);

static VOID		      UpdateText    (HDC, HWND);

static LRESULT 		      DoCreate	    (HWND, UINT, WPARAM, LPARAM);
static LRESULT 		      DoDestroy	    (HWND, UINT, WPARAM, LPARAM);
static LRESULT 		      DoPaint	    (HWND, UINT, WPARAM, LPARAM);
static LRESULT 		      DoSetText	    (HWND, UINT, WPARAM, LPARAM);


/* --------------------------------------------------------------------------
 * Exported functions:
 * ------------------------------------------------------------------------*/

/* Register Status Line window class */
BOOL STLNRegisterClass(HINSTANCE hInstance)
{
  WNDCLASS  wc;

  wc.style = CS_HREDRAW | CS_VREDRAW;
  wc.lpfnWndProc = STLNWndProc;
  wc.cbWndExtra = (INT) sizeof(HSTLN *);
  wc.cbClsExtra	= 0;
  wc.hInstance = hInstance;
  wc.hIcon = NULL;
  wc.hCursor = LoadCursor(NULL, IDC_ARROW);
  wc.hbrBackground = (HBRUSH)(COLOR_BTNFACE+1);
  wc.lpszMenuName = NULL;
  wc.lpszClassName = "STLNWindow";

  return RegisterClass(&wc);
}


/* Creates a Status Line */
HWND STLNCreateWindow (HINSTANCE hInstance, HWND hWndParent, LPCSTR ResizeBitmapName)
{
  HSTLN 	hSTLN;
  HWND 		hWnd;
  HFONT		hSmall, hOldFont;
  HDC		hDC;
  RECT		aRect, rParent;
  UINT		Height;

  /* Get height of tool bar */
  hDC = GetDC(hWndParent);
  hSmall = (HFONT) GetStockObject(ANSI_VAR_FONT);
  hOldFont = SelectObject (hDC, hSmall);
  aRect.top = aRect.left = 0;
  DrawText(hDC, (LPCSTR) "X", strlen((CHAR *)"X"), &aRect, DT_CALCRECT);
  SelectObject (hDC, hOldFont);
  ReleaseDC (hWndParent, hDC);
  Height = aRect.bottom+2;

  /* Get position in parent window */
  GetClientRect (hWndParent, &rParent);

  hWnd = CreateWindow(
		"STLNWindow",
		NULL,
		WS_CHILD | WS_VISIBLE,
		0,
		rParent.bottom-Height,
		rParent.right,
		Height,
		hWndParent,
		NULL,
		hInstance,
		NULL
  );

  if(!hWnd)
    return NULL;

  hSTLN = (HSTLN) GetWindowLong(hWnd, 0);

  hSTLN->LeftText[0] = (CHAR)0;
  strcpy(hSTLN->ResizeBitmap, ResizeBitmapName);
  hSTLN->hInstance = hInstance;

  return hWnd;
}


/* --------------------------------------------------------------------------
 * Local functions:
 * ------------------------------------------------------------------------*/

static VOID UpdateText (HDC hDC, HWND hWnd)
{
  HSTLN 	hSTLN;
  RECT    	aRect;
  HFONT		hOldFont, hSmall;
  INT		OldBkMode;
  HBRUSH	hBrush;

  hSTLN = (HSTLN) GetWindowLong(hWnd, 0);

  GetClientRect(hWnd, &aRect);
  hSmall = (HFONT) GetStockObject(ANSI_VAR_FONT);
  hOldFont = SelectObject (hDC, hSmall);

  OldBkMode = SetBkMode (hDC, TRANSPARENT);

  aRect.right -= 20;
  aRect.left += 5;
  hBrush = CreateSolidBrush(GetSysColor(COLOR_BTNFACE));
  FillRect(hDC, &aRect, hBrush);
  DeleteObject (hBrush);
  DrawText(hDC, (LPCSTR) hSTLN->LeftText, strlen((CHAR *)hSTLN->LeftText), &aRect, DT_LEFT|DT_VCENTER|DT_SINGLELINE);

  aRect.left -= 5;
  aRect.right += 20;

  SetBkMode (hDC, OldBkMode);
  SelectObject (hDC, hOldFont);

}

static LRESULT DoCreate (HWND hWnd, UINT message, WPARAM wParam, LPARAM lParam)
{
  HSTLN hSTLN;

  /* Get window structure */
  hSTLN = (HSTLN) malloc(sizeof(STLN));
  if (!hSTLN)
    return -1;

  memset(hSTLN, 0, sizeof(STLN));
  SetWindowLong(hWnd, 0, (LONG) hSTLN);

  return 0;
}


static LRESULT DoDestroy (HWND hWnd, UINT message, WPARAM wParam, LPARAM lParam)
{
  HSTLN hSTLN;

  hSTLN = (HSTLN) GetWindowLong(hWnd, 0);

  free(hSTLN);

  return 0;
}


static LRESULT DoPaint (HWND hWnd, UINT message, WPARAM wParam, LPARAM lParam)
{
  HSTLN 	hSTLN;
  HDC     	hDC;
  PAINTSTRUCT	Ps;
  RECT		aRect;
  HBITMAP 	hBitmap;
  BITMAP	bm;

  hSTLN = (HSTLN) GetWindowLong(hWnd, 0);

  BeginPaint (hWnd, &Ps);
  hDC = Ps.hdc;

  GetClientRect(hWnd, &aRect);

  UpdateText (hDC, hWnd);

  hBitmap = LoadMappedBitmap(hSTLN->hInstance, hSTLN->ResizeBitmap);
  GetObject(hBitmap, sizeof(BITMAP), &bm);
  DrawBitmap(hDC, hBitmap, aRect.right-bm.bmWidth+1, aRect.bottom-bm.bmHeight+1);
  DeleteObject(hBitmap);

  EndPaint (hWnd, &Ps);

  return 0;
}

static LRESULT DoSetText (HWND hWnd, UINT message, WPARAM wParam, LPARAM lParam)
{
  HSTLN 	hSTLN;
  HDC		hDC;

  hSTLN = (HSTLN) GetWindowLong(hWnd, 0);

  strcpy (hSTLN->LeftText, (LPSTR)lParam);

  hDC = GetDC (hWnd);
  UpdateText (hDC, hWnd);
  ReleaseDC (hWnd, hDC);

  return 0;
}


LRESULT CALLBACK STLNWndProc(HWND hWnd, UINT message, WPARAM wParam, LPARAM lParam)
{
  switch (message)
  {
     case WM_CREATE:      return DoCreate 	(hWnd, message, wParam, lParam);

     case WM_DESTROY:     return DoDestroy 	(hWnd, message, wParam, lParam);

     case WM_PAINT:       return DoPaint 	(hWnd, message, wParam, lParam);

     case WM_SETTEXT:     return DoSetText 	(hWnd, message, wParam, lParam);

     default:        	  return DefWindowProc(hWnd, message, wParam, lParam);
  }
}

#endif // HUGS_FOR_WINDOWS
