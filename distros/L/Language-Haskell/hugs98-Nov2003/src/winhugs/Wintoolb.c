/* --------------------------------------------------------------------------
 * WinToolB.c:	José Enrique Gallardo Ruiz, Feb 1999
 *
 * The Hugs 98 system is Copyright (c) José Enrique Gallardo, Mark P Jones,
 * Alastair Reid, the Yale Haskell Group, and the OGI School of
 * Science & Engineering at OHSU, 1994-2003, All rights reserved.  It is
 * distributed as free software under the license in the file "License",
 * which is included in the distribution.
 *
 * A tool bar window
 * ------------------------------------------------------------------------*/


#include "..\Prelude.h"

#if HUGS_FOR_WINDOWS
#define STRICT 1

#include "WinToolB.h"
#include "WinHint.h"
#include "WinUtils.h"
#include <malloc.h>



/* --------------------------------------------------------------------------
 * Some defined values:
 * ------------------------------------------------------------------------*/

#define HMARGIN			5
#define VMARGIN			7

#define VSEPARATION		0
#define SEPARATORSPACE		4

#define TIP_TIMER_ID		1
#define KILL_TIP_TIMER_ID       2

#define TIP_TIME		 800
#define TIP_TIME_ON		4000


/* --------------------------------------------------------------------------
 * Local functions protoypes:
 * ------------------------------------------------------------------------*/

LRESULT CALLBACK TBWndProc   (HWND, UINT, WPARAM, LPARAM);

static VOID 		      DrawBt 	   (HDC, UINT, HWND);
static VOID 		      DrawPushedBt (HDC, UINT, HWND);
static INT 		      OnButton 	   (HWND, UINT, UINT);
static VOID 		      DrawHint 	   (HWND, INT);
static VOID 		      RemoveHint   (HWND hWnd);
static VOID		      AbortHint    (HWND hWnd);
static UINT		      HPOS 	   (HWND, UINT);
static UINT		      VPOS 	   (HWND, UINT);


static LRESULT 		      DoCreate	    	(HWND, UINT, WPARAM, LPARAM);
static LRESULT 		      DoDestroy	    	(HWND, UINT, WPARAM, LPARAM);
static LRESULT 		      DoKeyDown	    	(HWND, UINT, WPARAM, LPARAM);
static LRESULT 		      DoLButtonDown 	(HWND, UINT, WPARAM, LPARAM);
static LRESULT 		      DoLButtonUp   	(HWND, UINT, WPARAM, LPARAM);
static LRESULT 		      DoMouseMove   	(HWND, UINT, WPARAM, LPARAM);
static LRESULT 		      DoKillFocus   	(HWND, UINT, WPARAM, LPARAM);
static LRESULT 		      DoPaint	    	(HWND, UINT, WPARAM, LPARAM);
static LRESULT 		      DoSysColorChange 	(HWND, UINT, WPARAM, LPARAM);
static LRESULT 		      DoTimer	    	(HWND, UINT, WPARAM, LPARAM);


/* --------------------------------------------------------------------------
 * Exported functions:
 * ------------------------------------------------------------------------*/

/* Register tool bar window class */
BOOL TBRegisterClass(HINSTANCE hInstance)
{
  WNDCLASS  wc;

  /* Register hint class */
  if (!HintRegisterClass(hInstance))
    return FALSE;

  /* Register tool bar class */
  wc.style = CS_HREDRAW | CS_VREDRAW;
  wc.lpfnWndProc = TBWndProc;
  wc.cbWndExtra = (INT) sizeof(HTOOLBAR *);
  wc.cbClsExtra	= 0;
  wc.hInstance = hInstance;
  wc.hIcon = NULL;
  wc.hCursor = LoadCursor(NULL, IDC_ARROW);
  wc.hbrBackground = (HBRUSH) (COLOR_BTNFACE+1);
  wc.lpszMenuName = NULL;
  wc.lpszClassName = "TBWindow";

  return RegisterClass(&wc);
}


/* Creates a tool bar */
HWND TBCreateWindow (HINSTANCE hInstance, HWND hWndParent, LPCSTR BtName, LPCSTR PushedBtName)
{
  HTOOLBAR 	hTB;
  HWND 		hWnd;

  hWnd = CreateWindow(
		"TBWindow",
		NULL,
		WS_CHILD | WS_VISIBLE,
		0,
		0,
		CW_USEDEFAULT,
		CW_USEDEFAULT,
		hWndParent,
		NULL,
		hInstance,
		NULL
  );

  if(!hWnd)
    return NULL;

  hTB = (HTOOLBAR) GetWindowLong(hWnd, 0);

  strcpy(hTB->BtBitmap, BtName);
  strcpy(hTB->PushedBtBitmap, PushedBtName);

  hTB->hInstance = hInstance;
  hTB->nBts = 0;
  hTB->ButtonPushed = -1;
  hTB->LastButton = -1;
  hTB->hHintWnd = NULL;

  /* Get buttons size */
  {
    HBITMAP 	hBitmap;
    BITMAP	bm;

    hBitmap = LoadBitmap(hInstance, hTB->BtBitmap);
    GetObject(hBitmap, sizeof(BITMAP), &bm);
    hTB->BtWidth  = bm.bmWidth;
    hTB->BtHeight = bm.bmHeight;
    DeleteObject(hBitmap);
  }

  /* Set toolbar window size */
  MoveWindow (hWnd, 0, 0,
		    hTB->BtWidth+2*HMARGIN, hTB->BtHeight+2*VMARGIN, TRUE);

  return hWnd;
}

/* Adds a button to a toolbar */
BOOL TBAppendButton  (HWND hWnd, WPARAM Command, LPCSTR BitmapName, UINT IdHelpLine, BOOL IsEnabled)
{
  HTOOLBAR hTB;

  hTB = (HTOOLBAR) GetWindowLong(hWnd, 0);

  if (hTB->nBts >= MAXBTS) {
    MessageBox (hWnd, "Too many buttons in TBAddButton", "Error", MB_ICONSTOP);
    return FALSE;
  }
  else if (Command == MF_SEPARATOR) {
    hTB->Bts[hTB->nBts].Command    = Command;
    hTB->nBts++;
    return TRUE;
  }
  else {
   hTB->Bts[hTB->nBts].Command    = Command;
   strcpy (hTB->Bts[hTB->nBts].BitmapName, BitmapName);
   hTB->Bts[hTB->nBts].hBitmap    = LoadMappedBitmap(hTB->hInstance, BitmapName);
   hTB->Bts[hTB->nBts].IdHelpLine = IdHelpLine;
   hTB->Bts[hTB->nBts].IsEnabled  = IsEnabled;
   hTB->nBts++;

   return TRUE;
  }
}


/* --------------------------------------------------------------------------
 * Local functions:
 * ------------------------------------------------------------------------*/


/* Draws the nBt-th button of a tool bar window */
static VOID DrawBt (HDC hDC, UINT nBt, HWND hTBWnd)
{
  HTOOLBAR 	hTB;
  HBITMAP       hBitmap;

  hTB = (HTOOLBAR) GetWindowLong(hTBWnd, 0);

  if (hTB->Bts[nBt].Command != MF_SEPARATOR) {
    hBitmap = LoadMappedBitmap(hTB->hInstance, hTB->BtBitmap);
    DrawBitmap(hDC, hBitmap, HPOS(hTBWnd, nBt), VPOS(hTBWnd, nBt));
    DeleteObject(hBitmap);
    DrawBitmap(hDC, hTB->Bts[nBt].hBitmap, HPOS(hTBWnd, nBt)+2, VPOS(hTBWnd, nBt)+2);
  }
}


/* Draws the nBt-th button of a tool bar window as pushed */
static VOID DrawPushedBt (HDC hDC, UINT nBt, HWND hTBWnd)
{
  HTOOLBAR 	hTB;
  HBITMAP       hBitmap;

  hTB = (HTOOLBAR) GetWindowLong(hTBWnd, 0);

  hBitmap = LoadMappedBitmap(hTB->hInstance, hTB->PushedBtBitmap);
  DrawBitmap(hDC, hBitmap, HPOS(hTBWnd, nBt), VPOS(hTBWnd, nBt));
  DeleteObject(hBitmap);
  DrawBitmap(hDC, hTB->Bts[nBt].hBitmap, HPOS(hTBWnd, nBt)+3, VPOS(hTBWnd, nBt)+2);
}


/* Return the number of the button where the mouse is placed, -1 if */
/* mouse isn´t placed on a button				    */
static INT OnButton (HWND hTBWnd, UINT MouseX, UINT MouseY)
{
  INT 		i;
  HTOOLBAR 	hTB;
  RECT		aRect;

  hTB = (HTOOLBAR) GetWindowLong(hTBWnd, 0);

  GetClientRect (hTBWnd, &aRect);

  if (MouseX >= HPOS(hTBWnd, 0) &&
      MouseX <= HPOS(hTBWnd, 0)+hTB->BtWidth &&
      MouseY >= (UINT)aRect.top &&
      MouseY <= (UINT)aRect.bottom)
    for(i=0; i<(INT)hTB->nBts; i++)
      if(hTB->Bts[i].Command != MF_SEPARATOR &&
	 MouseY >= VPOS(hTBWnd, i) &&
	 MouseY <= VPOS(hTBWnd, i)+hTB->BtHeight)
	return i;

  return -1;
}


/* Print a hint on Screen about a button        */
/* saves screen contens in hHintWnd 		*/
static VOID DrawHint (HWND hWnd, INT nButton)
{
  HTOOLBAR 	hTB;
  CHAR 		szMsg[256];
  POINT 	pt;

  hTB = (HTOOLBAR) GetWindowLong(hWnd, 0);

  if (nButton == -1)
    return;

  /* Get help string */
  LoadString(hTB->hInstance, hTB->Bts[nButton].IdHelpLine, (LPSTR)szMsg, sizeof(szMsg));

  /* Get position to display hint */
  pt.x = HPOS(hWnd, nButton)+hTB->BtWidth+4;
  pt.y = VPOS(hWnd, nButton)+2;
  ClientToScreen (hWnd, &pt);

  /* Create a hint window and set the hint text */
  hTB->hHintWnd = HintCreateWindow (hTB->hInstance, hWnd);
  SendMessage(hTB->hHintWnd, WM_SETTEXT, 0, (LPARAM)(LPSTR)szMsg);

  /* Set hint position and show it */
  SetWindowPos (hTB->hHintWnd, HWND_TOPMOST, pt.x, pt.y, 0, 0,
		SWP_SHOWWINDOW | SWP_NOSIZE | SWP_NOACTIVATE);
}


/* Remove a hint on Screen about a button */
static VOID RemoveHint (HWND hWnd)
{
  HTOOLBAR 	hTB;

  hTB = (HTOOLBAR) GetWindowLong(hWnd, 0);

  /* If there is a tip currently showed */
  if (hTB->hHintWnd) {

    /* Remove timer to remove hint */
    KillTimer(hWnd, KILL_TIP_TIMER_ID);

    ShowWindow(hTB->hHintWnd, SW_HIDE);
    DestroyWindow(hTB->hHintWnd);
    hTB->hHintWnd = NULL;

    /* if a tip is currently showed, the mouse is captured */
    ReleaseCapture ();
   }
}

static VOID AbortHint(HWND hWnd)
{
  /* If there was a timer thrown, remove it*/
  if (KillTimer(hWnd, TIP_TIMER_ID)){
    ReleaseCapture();
  }
  else { /* remove hint, if there was one */
    RemoveHint(hWnd);
  }
}


/* Get horizontal postion on nBt-th button */
static UINT HPOS (HWND hWnd, UINT nBt)
{
  return HMARGIN;
}


/* Get vertical postion on nBt-th button */
static UINT VPOS (HWND hWnd, UINT nBt)
{
  HTOOLBAR hTB;
  UINT	   i, vpos;

  hTB = (HTOOLBAR) GetWindowLong(hWnd, 0);

  vpos = VMARGIN;
  for (i=0; i<nBt; i++)
    if (hTB->Bts[i].Command == MF_SEPARATOR)
      vpos += SEPARATORSPACE+VSEPARATION;
    else
      vpos += hTB->BtHeight+VSEPARATION;

  return vpos;
}


static LRESULT DoCreate (HWND hWnd, UINT message, WPARAM wParam, LPARAM lParam)
{
  HTOOLBAR hTB;

  /* Get window structure */
  hTB = (HTOOLBAR) malloc(sizeof(TOOLBAR));
  if (!hTB)
    return -1;

  memset(hTB, 0, sizeof(TOOLBAR));
  SetWindowLong(hWnd, 0, (LONG) hTB);

  return 0;
}


static LRESULT DoDestroy (HWND hWnd, UINT message, WPARAM wParam, LPARAM lParam)
{
  HTOOLBAR hTB;
  UINT i;

  hTB = (HTOOLBAR) GetWindowLong(hWnd, 0);

  /* Delete bitmaps */
  for (i=0; i<hTB->nBts; i++)
    if (hTB->Bts[i].Command != MF_SEPARATOR)
      DeleteObject(hTB->Bts[i].hBitmap);

  /* free window extra bytes */
  free(hTB);

  return 0;
}

static LRESULT DoKillFocus (HWND hWnd, UINT message, WPARAM wParam, LPARAM lParam)
{
  AbortHint(hWnd);
  return 0;
}


static LRESULT DoKeyDown (HWND hWnd, UINT msg, WPARAM wParam, LPARAM lParam)
{
  AbortHint(hWnd);
  return 0;
}


static LRESULT DoLButtonDown (HWND hWnd, UINT msg, WPARAM wParam, LPARAM lParam)
{
  HTOOLBAR hTB;
  UINT     xPos = LOWORD(lParam);
  UINT     yPos = HIWORD(lParam);
  INT      nButton;
  HDC	   hDC;

  hTB = (HTOOLBAR) GetWindowLong(hWnd, 0);

  /* Check if a button on the Tools bar is pushed */
  if ((nButton = OnButton(hWnd, xPos, yPos)) != -1){

    if (hTB->Bts[nButton].IsEnabled) {
      /* If there was a timer thrown, remove it*/
      AbortHint(hWnd);
      /* capture mouse */
      SetCapture(hWnd);
      /* remember number of button */
      hTB->ButtonPushed = nButton;
      /* draw the button as pushed */
      hDC = GetDC(hWnd);
      DrawPushedBt(hDC, nButton, hWnd);
      ReleaseDC (hWnd, hDC);
    }
    else {
      MessageBeep(MB_ICONHAND);
    }
  }

  return 0;
}


static LRESULT DoLButtonUp (HWND hWnd, UINT msg, WPARAM wParam, LPARAM lParam)
{
  HTOOLBAR hTB;
  UINT     xPos = LOWORD(lParam);
  UINT     yPos = HIWORD(lParam);
  INT      nButton;
  HDC	   hDC;

  hTB = (HTOOLBAR) GetWindowLong(hWnd, 0);


  if (hTB->ButtonPushed != -1) { /* There was a button pushed */
    /* Paint button as not pushed */
    hDC = GetDC(hWnd);
    DrawBt(hDC, hTB->ButtonPushed, hWnd);
    ReleaseDC (hWnd, hDC);

    /* Release capture of mouse */
    ReleaseCapture();

     /* if mouse still on same button send command to parent window */
    if ((nButton = OnButton(hWnd, xPos, yPos)) == hTB->ButtonPushed) {
      PostMessage(GetParent(hWnd), WM_COMMAND, hTB->Bts[nButton].Command, 0L);
    }
    else {
      MessageBeep(MB_ICONASTERISK);
    }

    /* Clear button currently pushed */
    hTB->ButtonPushed = -1;
  }

  return 0;
}


static LRESULT DoMouseMove (HWND hWnd, UINT msg, WPARAM wParam, LPARAM lParam)
{
  HTOOLBAR hTB;
  UINT     xPos = LOWORD(lParam);
  UINT     yPos = HIWORD(lParam);
  INT      nButton;

  hTB = (HTOOLBAR) GetWindowLong(hWnd, 0);

  /* Show help if cursor on a button of the tools bar */

  if (hTB->ButtonPushed == -1) { /* If there is no button pushed */
    if ((nButton = OnButton(hWnd, xPos, yPos)) == -1) { /* If mouse isn't on a button */
      /* If there was a timer thrown, remove it and release mouse */
      AbortHint(hWnd);
      hTB->LastButton = nButton;
    }
    else {
      if (hTB->LastButton != nButton) { /* if Mouse on another button */
	AbortHint(hWnd);
	if (GetParent(hWnd) == GetActiveWindow()) {
	  SetTimer (hWnd, TIP_TIMER_ID, TIP_TIME, NULL);
	  SetCapture(hWnd);
	  hTB->LastButton = nButton;
	}
      }
    }
  }
  return 0;
}


static LRESULT DoPaint (HWND hWnd, UINT message, WPARAM wParam, LPARAM lParam)
{
  HTOOLBAR 	hTB;
  HDC     	hDC;
  HPEN    	hPen, hOldPen;
  RECT    	aRect;
  PAINTSTRUCT	Ps;
  UINT		i;

  hTB = (HTOOLBAR) GetWindowLong(hWnd, 0);

  BeginPaint (hWnd, &Ps);
  hDC = Ps.hdc;


  /* Draw horizontal delimiters */
  GetClientRect(hWnd, &aRect);

  hPen = CreatePen(PS_SOLID, 1, GetSysColor(COLOR_BTNFACE));
  hOldPen = SelectObject(hDC, hPen);
  MoveToEx(hDC, aRect.left+1,  aRect.top, NULL);
  LineTo(hDC, aRect.right-1, aRect.top);
  MoveToEx(hDC, aRect.left+1,  aRect.bottom-2, NULL);
  LineTo(hDC, aRect.right-1, aRect.bottom-2);
  SelectObject(hDC, hOldPen);
  DeleteObject(hPen);

  hPen = CreatePen(PS_SOLID, 1, GetSysColor(COLOR_BTNHIGHLIGHT));
  hOldPen = SelectObject(hDC, hPen);
  MoveToEx(hDC, aRect.left+1,  aRect.top+1, NULL);
  LineTo(hDC, aRect.right-1, aRect.top+1);
  MoveToEx(hDC, aRect.left+1,  aRect.bottom-1, NULL);
  LineTo(hDC, aRect.right-1, aRect.bottom-1);
  SelectObject(hDC, hOldPen);
  DeleteObject(hPen);

  /* Draw the buttons */
  for (i=0; i<hTB->nBts; i++) {
    DrawBt(hDC, i, hWnd);
  }

  EndPaint (hWnd, &Ps);

  return 0;
}

static LRESULT DoSysColorChange(HWND hWnd, UINT msg, WPARAM wParam, LPARAM lParam)
{
  HTOOLBAR hTB;
  UINT i;

  hTB = (HTOOLBAR) GetWindowLong(hWnd, 0);

  /* Reload bitmaps */
  for (i=0; i<hTB->nBts; i++)
    if (hTB->Bts[i].Command != MF_SEPARATOR) {
      DeleteObject(hTB->Bts[i].hBitmap);
      hTB->Bts[i].hBitmap = LoadMappedBitmap(hTB->hInstance, hTB->Bts[i].BitmapName);
    }

  return 0;
}

static LRESULT DoTimer(HWND hWnd, UINT msg, WPARAM wParam, LPARAM lParam)
{
  UINT idTimer = (UINT) wParam;
  HTOOLBAR 	hTB;

  hTB = (HTOOLBAR) GetWindowLong(hWnd, 0);

  /* Kill the timer received */
  KillTimer(hWnd, idTimer);

  if (idTimer == TIP_TIMER_ID) {
    DrawHint(hWnd, hTB->LastButton);
    SetTimer (hWnd, KILL_TIP_TIMER_ID, TIP_TIME_ON, NULL);
  }
  else {
    RemoveHint(hWnd);
  }

  return 0;
}


LRESULT CALLBACK TBWndProc(HWND hWnd, UINT message, WPARAM wParam, LPARAM lParam)
{
  switch (message)
  {
     case WM_CREATE:      return DoCreate 	(hWnd, message, wParam, lParam);

     case WM_DESTROY:     return DoDestroy 	(hWnd, message, wParam, lParam);

     case WM_KEYDOWN:	  return DoKeyDown 	(hWnd, message, wParam, lParam);

     case WM_KILLFOCUS:   return DoKillFocus 	(hWnd, message, wParam, lParam);

     case WM_LBUTTONDOWN: return DoLButtonDown 	(hWnd, message, wParam, lParam);

     case WM_LBUTTONUP:   return DoLButtonUp 	(hWnd, message, wParam, lParam);

     case WM_MOUSEMOVE:   return DoMouseMove 	(hWnd, message, wParam, lParam);

     case WM_PAINT:       return DoPaint 	(hWnd, message, wParam, lParam);

     case WM_TIMER:       return DoTimer 	(hWnd, message, wParam, lParam);

     case WM_SYSCOLORCHANGE:
			  return DoSysColorChange (hWnd, message, wParam, lParam);

     default:        	  return DefWindowProc(hWnd, message, wParam, lParam);
  }
}


#endif // HUGS_FOR_WINDOWS
