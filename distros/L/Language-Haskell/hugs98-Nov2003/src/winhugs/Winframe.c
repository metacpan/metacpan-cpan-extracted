/* --------------------------------------------------------------------------
 * WinFrame.c:	José Enrique Gallardo Ruiz, Feb 1999
 *
 * The Hugs 98 system is Copyright (c) José Enrique Gallardo, Mark P Jones,
 * Alastair Reid, the Yale Haskell Group, and the OGI School of
 * Science & Engineering at OHSU, 1994-2003, All rights reserved.  It is
 * distributed as free software under the license in the file "License",
 * which is included in the distribution.
 *
 * This file contains the implementation for a frame window definition
 * ------------------------------------------------------------------------*/


#include "..\Prelude.h"

#if HUGS_FOR_WINDOWS
#define STRICT 1

#ifndef __WINFRAME_H
#include "WinFrame.h"
#endif
#ifndef __WINSTLN_H
#include "WinSTLN.h"
#endif
#ifndef __WINTOOLB_H
#include "WinToolB.h"
#endif
#ifndef __WINUTILS_H
#include "WinUtils.h"
#endif
#ifndef __ALLOC_H
#include <malloc.h>
#endif

#include <ctl3d.h>
#include <shellapi.h>

/* --------------------------------------------------------------------------
 * Some defined values:
 * ------------------------------------------------------------------------*/
#define H_INDENT     0    /* Separation between tools bar and child window  */
#define V_INDENT     0    /* Separation between main menu and child window  */
#define RIGHT_BORDER 3    /* Width of right border of frame window 	    */


/* --------------------------------------------------------------------------
 * Local functions protoypes:
 * ------------------------------------------------------------------------*/

LRESULT CALLBACK FRAMEWndProc (HWND, UINT, WPARAM, LPARAM);


static LRESULT 		      DoNCCreate    (HWND, UINT, WPARAM, LPARAM);
static LRESULT 		      DoDestroy	    (HWND, UINT, WPARAM, LPARAM);
static LRESULT 		      DoMenuSelect  (HWND, UINT, WPARAM, LPARAM);
static LRESULT 		      DoPaint	    (HWND, UINT, WPARAM, LPARAM);
static LRESULT 		      DoSize	    (HWND, UINT, WPARAM, LPARAM);
static LRESULT 		      DoSetFocus    (HWND, UINT, WPARAM, LPARAM);
static LRESULT 		      DoKillFocus   (HWND, UINT, WPARAM, LPARAM);
static LRESULT 		      DoKeydown     (HWND, UINT, WPARAM, LPARAM);
static LRESULT 		      DoKeyup       (HWND, UINT, WPARAM, LPARAM);
static LRESULT 		      DoChar	    (HWND, UINT, WPARAM, LPARAM);


/* --------------------------------------------------------------------------
 * Exported functions:
 * ------------------------------------------------------------------------*/

/* Register Frame window class */
BOOL FRAMERegisterClass(HINSTANCE hInstance)
{
  WNDCLASS  wc;

  /* Register tool bar class */
  TBRegisterClass(hInstance);

  /* Register status line class */
  STLNRegisterClass(hInstance);

  /* Register frame window class */
  wc.style		= CS_VREDRAW | CS_HREDRAW;
  wc.lpfnWndProc	= FRAMEWndProc;
  wc.cbClsExtra		= 0;
  wc.cbWndExtra 	= (INT) sizeof(HFRAME *);
  wc.hInstance		= hInstance;
  wc.hIcon		= NULL;
  wc.hCursor		= NULL;
  wc.hbrBackground	= (HBRUSH)(COLOR_BTNFACE+1);
  wc.lpszMenuName	= NULL;
  wc.lpszClassName	= "FrameWindow";

  return RegisterClass(&wc);
}


/* Superclass a Frame Window */
BOOL FRAMESuperclass (HINSTANCE hInstance, LPCSTR SuperclassName,
		      LPCSTR MenuName, LPCSTR IconName)
{
  WNDCLASS wc;

  /* superclass the frame class */
  if (!GetClassInfo(hInstance, "FrameWindow", &wc))
    return FALSE;

  wc.hInstance 		= hInstance;
  wc.lpszClassName	= SuperclassName;
  wc.lpszMenuName	= MenuName;
  wc.hIcon		= LoadIcon(hInstance, IconName);

  if (!RegisterClass (&wc))
    return FALSE;

  return TRUE;
}

/* Creates a frame window */
HWND FRAMECreateWindow (HINSTANCE hInstance,
			LPCSTR WindowName,
			WNDPROC NewWndProc,
			WNDPROC* OldWndProc,
			HWND hWndChild,
			LPCSTR ClassName,
			LPCSTR ResizeBitmapName,
			LPCSTR ButtonName,
			LPCSTR PushedButtonName)
{
  HWND 		hWnd;
  HFRAME        hFRAME;
  CREATESTRUCT	cs;

  /* Create frame window */
  hWnd = CreateWindow(ClassName,
		      WindowName,
		      WS_OVERLAPPEDWINDOW,
		      CW_USEDEFAULT,
		      CW_USEDEFAULT,
		      CW_USEDEFAULT,
		      CW_USEDEFAULT,
		      (HWND) NULL,
		      (HMENU) NULL,
		      hInstance,
		      (LPSTR) NULL);

  if (!hWnd)
    return NULL;

  /* set new window procedure */
  *OldWndProc = (WNDPROC)GetClassLong(hWnd, GCL_WNDPROC);

  //*OldWndProc = (WNDPROC)SetWindowLong(hWnd,GWL_WNDPROC,
  //			 (LONG) NewWndProc);
  SetWindowLong(hWnd,GWL_WNDPROC,
			 (LONG) NewWndProc);

  /* send WM_CREATE to new procedure */
  cs.lpCreateParams 	= NULL;
  cs.hInstance          = hInstance;
  cs.hMenu		= NULL;
  cs.hwndParent         = NULL;
  cs.cx			= CW_USEDEFAULT;
  cs.cy			= CW_USEDEFAULT;
  cs.x			= CW_USEDEFAULT;
  cs.y			= CW_USEDEFAULT;
  cs.style		= WS_OVERLAPPEDWINDOW;
  cs.lpszName		= WindowName;
  cs.lpszClass		= ClassName;
  cs.dwExStyle		= 0;

  if (SendMessage (hWnd, WM_CREATE, 0, (LPARAM) &cs) != 0)
    return NULL;

  hFRAME = (HFRAME) GetWindowLong(hWnd, 0);

  /* atach child window to frame */
  SetParent (hWndChild, hWnd);
  hFRAME->hWndChild = hWndChild;

  /* Create its status line */
  hFRAME->hWndSTLN = STLNCreateWindow(hInstance, hWnd, ResizeBitmapName);
  if (!hFRAME->hWndSTLN)
    return NULL;

  /* Create its tool bar */
  hFRAME->hWndTB = TBCreateWindow (hInstance, hWnd, ButtonName, PushedButtonName);
  if (!hFRAME->hWndTB)
    return NULL;

  return hWnd;
}


/* sets the child window of a frame */
VOID FRAMESetChild (HWND hFrameWnd, HWND hWndChild)
{
  HFRAME        hFRAME;

  hFRAME = (HFRAME) GetWindowLong(hFrameWnd, 0);

  hFRAME->hWndChild = hWndChild;
}

/* return the Tool bar window in a frame */
HWND FRAMEGetTB	(HWND hFrameWnd)
{
  HFRAME        hFRAME;

  hFRAME = (HFRAME) GetWindowLong(hFrameWnd, 0);

  return hFRAME->hWndTB;
}

/* return the Status line window in a frame */
HWND FRAMEGetSTLN	(HWND hFrameWnd)
{
  HFRAME        hFRAME;

  hFRAME = (HFRAME) GetWindowLong(hFrameWnd, 0);

  return hFRAME->hWndSTLN;
}

/* Get size of frame window right border */
INT FRAMEGetRightBorderSize(HWND hWndFrame)
{
  return RIGHT_BORDER;
}

/* --------------------------------------------------------------------------
 * Local functions:
 * ------------------------------------------------------------------------*/


static LRESULT DoNCCreate (HWND hWnd, UINT message, WPARAM wParam, LPARAM lParam)
{
  HFRAME        	hFRAME;
  LPCREATESTRUCT        lpcs;

  /* get create structure */
  lpcs = (LPCREATESTRUCT) lParam;

  /* Get memory for window structure */
  hFRAME = (HFRAME) malloc(sizeof(FRAME));
  if (!hFRAME)
    return FALSE;

  memset(hFRAME, 0, sizeof(FRAME));
  SetWindowLong(hWnd, 0, (LONG) hFRAME);

  /* keep instance */
  hFRAME->hInstance = lpcs->hInstance;


  /* Accept Drag and drop */
  DragAcceptFiles(hWnd, TRUE);

  return TRUE;
}


static LRESULT DoDestroy (HWND hWnd, UINT message, WPARAM wParam, LPARAM lParam)
{
  HFRAME        hFRAME;

  hFRAME = (HFRAME) GetWindowLong(hWnd, 0);


  /* No more Drag and drop */
  DragAcceptFiles(hWnd, FALSE);

  free(hFRAME);

  PostQuitMessage(0);

  return 0;
}


static LRESULT DoMenuSelect(HWND hWnd, UINT msg, WPARAM wParam, LPARAM lParam)
{
  UINT   	Item, Flags;
  INT		idMenu;
  HMENU	 	hMenu;
  CHAR   	szMsg[256];
  HFRAME        hFRAME;

  hFRAME = (HFRAME) GetWindowLong(hWnd, 0);

  Item  = (UINT)LOWORD(wParam);
  Flags = (UINT)HIWORD(wParam);
  hMenu = (HMENU)lParam;

  if (!Item && !hMenu && Flags == 0xffff) {
    /* Menu Closing */
    idMenu = 0;
  }
  else if (Flags & MF_POPUP) {
    /* It is a pop up like files */
    for (idMenu=0; idMenu<GetMenuItemCount(GetMenu(hWnd)) && GetSubMenu(hMenu,Item)!=GetSubMenu(GetMenu(hWnd),idMenu); idMenu++);

    if (!(idMenu<GetMenuItemCount(GetMenu(hWnd))))
      idMenu=0;
    else
      idMenu++; /* First menu has help number one */
  }
  else if (Flags & 0x0080) {
    /* It is a item in a submenu */
    idMenu = Item;
  }
  else {
    idMenu = 0;
  }

  if (!LoadString(hFRAME->hInstance, idMenu, (LPSTR) szMsg, sizeof(szMsg))) {
    szMsg[0] = (CHAR)0;
  }
  SendMessage(hFRAME->hWndSTLN, WM_SETTEXT, 0, (LPARAM)(LPSTR)szMsg);

  return 0;
}


static LRESULT DoSize (HWND hWnd, UINT message, WPARAM wParam, LPARAM lParam)
{
  RECT 		rMain, rSTLN, rTB;
  HFRAME        hFRAME;

  hFRAME = (HFRAME) GetWindowLong(hWnd, 0);

  GetClientRect(hWnd,     	  &rMain);
  GetClientRect(hFRAME->hWndTB,   &rTB);
  GetClientRect(hFRAME->hWndSTLN, &rSTLN);

  /* Set Tools Bar position */
  MoveWindow(hFRAME->hWndTB, rMain.left, rMain.top,
	     rTB.right, rMain.bottom-rSTLN.bottom-1,
	     TRUE);

  /* Resize status line */
  MoveWindow(hFRAME->hWndSTLN, rMain.left, rMain.bottom-rSTLN.bottom,
	     rMain.right, rSTLN.bottom,
	     TRUE);

  /* Resize Child Window */
  MoveWindow(hFRAME->hWndChild, rTB.right+H_INDENT+1, V_INDENT,
	     rMain.right-rTB.right-H_INDENT*2-RIGHT_BORDER,
	     rMain.bottom-rSTLN.bottom-1-V_INDENT*2,
	     TRUE);
  return 0;
}

static LRESULT DoPaint (HWND hWnd, UINT message, WPARAM wParam, LPARAM lParam)
{
  PAINTSTRUCT ps;

  BeginPaint(hWnd, &ps);
  EndPaint(hWnd, &ps);

  return 0;
}


static LRESULT DoSetFocus (HWND hWnd, UINT message, WPARAM wParam, LPARAM lParam)
{
  HFRAME        hFRAME;

  hFRAME = (HFRAME) GetWindowLong(hWnd, 0);

  SetFocus(hWnd);
  SendMessage(hFRAME->hWndChild, message, wParam, lParam);

  return 0;
}


static LRESULT DoKillFocus (HWND hWnd, UINT message, WPARAM wParam, LPARAM lParam)
{
  HFRAME        hFRAME;

  hFRAME = (HFRAME) GetWindowLong(hWnd, 0);
  SendMessage(hFRAME->hWndChild, message, wParam, lParam);
  SendMessage(hFRAME->hWndTB, message, wParam, lParam);

  return 0;
}


static LRESULT DoKeydown (HWND hWnd, UINT message, WPARAM wParam, LPARAM lParam)
{
  HFRAME        hFRAME;

  hFRAME = (HFRAME) GetWindowLong(hWnd, 0);
  SendMessage(hFRAME->hWndChild, message, wParam, lParam);
  SendMessage(hFRAME->hWndTB, message, wParam, lParam);

  return 0;
}


static LRESULT DoKeyup (HWND hWnd, UINT message, WPARAM wParam, LPARAM lParam)
{
  HFRAME        hFRAME;

  hFRAME = (HFRAME) GetWindowLong(hWnd, 0);
  SendMessage(hFRAME->hWndChild, message, wParam, lParam);

  return 0;
}


static LRESULT DoChar (HWND hWnd, UINT message, WPARAM wParam, LPARAM lParam)
{
  HFRAME        hFRAME;

  hFRAME = (HFRAME) GetWindowLong(hWnd, 0);
  SendMessage(hFRAME->hWndChild, message, wParam, lParam);

  return 0;
}


LRESULT CALLBACK FRAMEWndProc(HWND hWnd, UINT message, WPARAM wParam, LPARAM lParam)
{
  HFRAME        hFRAME;

  hFRAME = (HFRAME) GetWindowLong(hWnd, 0);

  switch (message)
  {
     /* 3-D Look */
     case WM_CTLCOLORBTN:
     case WM_CTLCOLORDLG:
     case WM_CTLCOLOREDIT:
     case WM_CTLCOLORLISTBOX:
     case WM_CTLCOLORMSGBOX:
     case WM_CTLCOLORSCROLLBAR:
     case WM_CTLCOLORSTATIC:

     case WM_SYSCOLORCHANGE:
			  SendMessage (hFRAME->hWndChild, message, wParam, lParam);
			  SendMessage (hFRAME->hWndSTLN, message, wParam, lParam);
			  SendMessage (hFRAME->hWndTB, message, wParam, lParam);

			  return 0;

     case WM_NCCREATE:    DoNCCreate 	(hWnd, message, wParam, lParam);
			  break;

     case WM_DESTROY:     return DoDestroy 	(hWnd, message, wParam, lParam);

     case WM_MENUSELECT:  return DoMenuSelect 	(hWnd, message, wParam, lParam);

     case WM_SIZE:  	  return DoSize 	(hWnd, message, wParam, lParam);

     case WM_PAINT:       return DoPaint 	(hWnd, message, wParam, lParam);

     case WM_SETFOCUS:    return DoSetFocus 	(hWnd, message, wParam, lParam);

     case WM_KILLFOCUS:   return DoKillFocus 	(hWnd, message, wParam, lParam);

     case WM_KEYDOWN:     return DoKeydown 	(hWnd, message, wParam, lParam);

     case WM_KEYUP:   	  return DoKeyup 	(hWnd, message, wParam, lParam);

     case WM_CHAR:    	  return DoChar 	(hWnd, message, wParam, lParam);

     default:        	  return (DefWindowProc(hWnd, message, wParam, lParam));
  }
  return DefWindowProc(hWnd, message, wParam, lParam);
}

#endif // HUGS_FOR_WINDOWS
