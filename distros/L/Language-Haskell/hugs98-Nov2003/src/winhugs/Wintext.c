/* --------------------------------------------------------------------------
 * WinText.c:	José Enrique Gallardo Ruiz, Feb 1999
 *		With very minor modifications by mpj/adr for Hugs, 1995-97
 *
 * The Hugs 98 system is Copyright (c) José Enrique Gallardo, Mark P Jones,
 * Alastair Reid, the Yale Haskell Group, and the OGI School of
 * Science & Engineering at OHSU, 1994-2003, All rights reserved.  It is
 * distributed as free software under the license in the file "License",
 * which is included in the distribution.
 *
 * Functions to define a windows class that emulates MS-DOS text
 * windows. These windows support ANSI control.
 * ------------------------------------------------------------------------*/

#include "..\Prelude.h"

#if HUGS_FOR_WINDOWS
#define STRICT 1

#include "winText.h"
#include "winMenu.h"
#include <malloc.h>
#include <stdlib.h>
#include <stdio.h>
#include <ctype.h>
#include <stdarg.h>
#include <signal.h>

/* --------------------------------------------------------------------------
 * Text Window Structure:
 * ------------------------------------------------------------------------*/

typedef struct TagTextWindowInfo {
  INT      Left, Top; 			/* Position in parent Window              */
  LOGFONT  LogFont;			/* Logical font used 			  */
  HFONT	   hFont;		      	/* Text Font used            	          */
  UINT 	   CharWidth, CharHeight;  	/* Width and Height of used font          */
  UINT	   Rows, Cols;			/* Number of rows and columns of window   */
  UINT 	   RowsShowed, ColsShowed;	/* Nº of cols and rows currently showed   */
  UINT 	   PosX, PosY;			/* Cursor current position  	          */
  INT      TextAttr, TextBackAttr;	/* Current attributes  	           	  */
  BOOL     Bright;			/* Bright ON/OFF               		  */
  HGLOBAL  ScrBuffer;			/* Screen buffer		          */
  BOOL     CursorStatus;		/* Cursor ON/OFF		          */
  BOOL     InsertStatus;		/* Edit capability Insert(ON/OFF)         */
  BOOL	   IsFocused;			/* TRUE if window has Focus               */
  HGLOBAL  KbdBuffer;			/* Keyboard buffer   		          */
  INT      KbdInx;			/* Next free position in keyboard buffer  */
  HACCEL   hAccelTable;			/* Accelerators to use in Window          */
  HGLOBAL  hBufferEd;			/* Edit buffer for edit capability        */
  HGLOBAL  hBufferEdPrev;           	/* Previous edit buffers   	          */
  INT      IoInx;	                /* Points to last char readed with WinGetc*/
  CHAR     AnsiStr[200];		/* Used to implement ANSI support	  */
  INT      AnsiPtr;
  BOOL     InAnsi;
  UINT 	   AnsiSavex, AnsiSavey;
  UINT 	   VScroll, HScroll;		/* Offsets for scroll implementation       */
  BOOL	   Selecting;			/* TRUE if selecting text with mouse       */
  BOOL     Selected;			/* TRUE if there is selected text 	   */
  RECT     rSelected;			/* Selected Rectangle 			   */
  POINT    pBaseSel;
  BOOL     InEdit;			/* TRUE if executing buffered edit function*/
  UINT 	   EdLeft, EdTop;	       	/* Pos where buffered edit begins          */
  FPOINTER EdStr;			/* Points to string being edited           */
  INT	   EdPos;		       	/* Cursor offset in edited string          */
  UINT 	   EdLength;			/* Current Length of edited string	   */
  BOOL	   Control, Shift;		/* TRUE if those keys are pressed	   */
  BOOL     LButtonDown;			/* TRUE if left button is Down 		   */
  BOOL     svCursorStatus;		/* saves Cursor status 		           */
  TEXTMETRIC TextMetric;		/* Window text metrics			   */
#if USE_THREADS
  HANDLE   eventKeyboardNotEmpty;	/* Use to syncronize threads               */
#endif
} TEXTWINDOWINFO ;


/* holds a key in keyoard buffer */
typedef struct tagOneBufferKey {
 TCHAR KeyCode;     /* The key code 		    */
 BOOL  IsExtended;  /* TRUE, if it is a control key */
} ONE_BUFFER_KEY;



/* --------------------------------------------------------------------------
 * Local functions protoypes:
 * ------------------------------------------------------------------------*/

LRESULT CALLBACK TextWndProc (HWND, UINT, WPARAM, LPARAM);

static ONE_BUFFER_KEY   GetOneBufferKey         (HWND);
static VOID 		GetSysColors		(VOID);
static VOID 		MoveCursor 		(HWND, INT);
static VOID		UnSelect		(HWND);
static VOID		MyMemMove		(FPOINTER, FPOINTER, ULONG);
static VOID		MyMemSet		(FPOINTER, CHAR, ULONG);
static VOID             PutTextSelectedRegion	(HWND, RECT);
static VOID 		PutTextRect 		(BOOL, HWND, RECT);
static VOID 		PutTextRegion 		(BOOL, HWND, RECT);
static CHAR 	       *Ansi			(HWND, CHAR*);
static VOID		MyScrollWindow		(HWND, INT, INT);
static VOID 		TextBeginPaint 		(BOOL, HWND, HDC*, PAINTSTRUCT*, HFONT*);
static VOID 		TextEndPaint 		(BOOL, HWND, HDC*, PAINTSTRUCT*, HFONT*);
static VOID 		TextOutput 		(HWND, HDC, UINT, UINT, LPSTR, INT, UCHAR);

static INT 		DoCreate		(HWND, UINT, WPARAM, LPARAM);
static VOID 		DoDestroy		(HWND, UINT, WPARAM, LPARAM);
static VOID 		DoGotoxy         	(HWND, UINT, WPARAM, LPARAM);
static VOID 		DoPaint         	(HWND, UINT, WPARAM, LPARAM);
static BOOL 		DoSetCursorStatus 	(HWND, UINT, WPARAM, LPARAM);
static VOID 		DoSetFocus 		(HWND, UINT, WPARAM, LPARAM);
static VOID 		DoSetInputBuffer	(HWND, UINT, WPARAM, LPARAM);
static VOID 		DoGetInputBuffer	(HWND, UINT, WPARAM, LPARAM);
static INT 		DoGetBufferPos		(HWND, UINT, WPARAM, LPARAM);
static LOGFONT 	       *DoGetLogFont		(HWND, UINT, WPARAM, LPARAM);
static TEXTMETRIC      *DoGetTextMetric		(HWND, UINT, WPARAM, LPARAM);
static VOID 		DoSetBufferPos		(HWND, UINT, WPARAM, LPARAM);
static VOID 		DoKillFocus		(HWND, UINT, WPARAM, LPARAM);
static INT 		DoKeyDown		(HWND, UINT, WPARAM, LPARAM);
static INT 		DoKeyUp 		(HWND, UINT, WPARAM, LPARAM);
static INT 		DoChar			(HWND, UINT, WPARAM, LPARAM);
static VOID 		DoSize			(HWND, UINT, WPARAM, LPARAM);
static VOID 		DoHScroll		(HWND, UINT, WPARAM, LPARAM);
static VOID 		DoVScroll		(HWND, UINT, WPARAM, LPARAM);
static VOID 		DoLButtonDown		(HWND, UINT, WPARAM, LPARAM);
static VOID 		DoMouseMove 		(HWND, UINT, WPARAM, LPARAM);
static VOID 		DoLButtonUp 		(HWND, UINT, WPARAM, LPARAM);
static VOID 		DoRButtonDown 		(HWND, UINT, WPARAM, LPARAM);
static VOID 		DoCopy			(HWND, UINT, WPARAM, LPARAM);
static VOID 		DoPaste 		(HWND, UINT, WPARAM, LPARAM);
static VOID 		DoCutClear 		(HWND, UINT, WPARAM, LPARAM);
static BOOL 		DoCanCut 		(HWND, UINT, WPARAM, LPARAM);
static BOOL 		DoCanCopy 		(HWND, UINT, WPARAM, LPARAM);
static BOOL 		DoCanPaste 		(HWND, UINT, WPARAM, LPARAM);
static BOOL 		DoCanClear 		(HWND, UINT, WPARAM, LPARAM);


static VOID  	 	ForceMoveCaret 		(HWND, UINT, UINT);
static VOID 	 	ForceShowCaret		(HWND);
static VOID 	 	ForceDestroyCaret	(HWND);
static VOID 	 	ForceHideCaret		(HWND);



/* --------------------------------------------------------------------------
 * Some defined values:
 * ------------------------------------------------------------------------*/


#define TAB_SIZE		     8  /* Number of spaces for a Tab       */

#define EDIT_BUFFER_MAX_LENGTH 	  80*2 	/* Edit Buffer max length           */
#define NUM_EDIT_BUFFERS	    25  /* Number of Previous saved buffers */

#define KEYBOARD_BUFFER_MAX_LENGTH 1024 /* Keyboard buffer size             */

#define NUM_WINDOW_PAGES	    25	/* Number of pages in the Window    */

#define FIRST_ROW		     1  /* rows are in [1..twi->Rows]	    */
#define FIRST_COL		     1  /* cols are in [1..twi->Cols]	    */


/* --------------------------------------------------------------------------
 * The color palette:
 * -------------------------------------------------------------------------*/

#define BACKGROUND      16
#define BRIGHT	       128
#define SELECTED       	 8
#define MAXCOLORS        8

static COLORREF thePalette[(MAXCOLORS+1)*2] = {
	 RGB(0,0,0),
	 RGB(0,0,175),
	 RGB(0,135,0),
	 RGB(0,175,175),
	 RGB(175,0,0),
	 RGB(150,0,150),
	 RGB(175,175,0),
	 RGB(255,255,255),
	 RGB(0,0,0),
	 RGB(0,0,255),
	 RGB(0,255,0),
	 RGB(0,255,255),
	 RGB(255,0,0),
	 RGB(255,0,255),
	 RGB(255,255,0),
	 RGB(255,255,255),
	 RGB(0,0,0),
	 RGB(0,0,0)
};


static VOID GetSysColors(VOID)
{
  thePalette[WHITE]         = GetSysColor(COLOR_WINDOW);
  thePalette[BLACK]         = GetSysColor(COLOR_WINDOWTEXT);
  thePalette[HIGHLIGHT]     = GetSysColor(COLOR_HIGHLIGHT);
  thePalette[HIGHLIGHTTEXT] = GetSysColor(COLOR_HIGHLIGHTTEXT);
}

/*---------------------------------------------------------------------------
 * Register text window class:
 *-------------------------------------------------------------------------*/

BOOL RegisterTextClass(HINSTANCE hInstance)
{
  WNDCLASS  wc;

  wc.style       	= CS_HREDRAW | CS_VREDRAW;
  wc.lpfnWndProc 	= TextWndProc;
  wc.cbWndExtra  	= (INT) sizeof(TEXTWINDOWINFO *);
  wc.cbClsExtra	 	= 0;
  wc.hInstance   	= hInstance;
  wc.hIcon       	= NULL;
  wc.hCursor 		= LoadCursor(NULL, IDC_IBEAM);
  wc.hbrBackground 	= (HBRUSH)(COLOR_WINDOW+1);
  wc.lpszMenuName 	= NULL;
  wc.lpszClassName 	= "TextWindow";

  return RegisterClass(&wc);
}



/*---------------------------------------------------------------------------
 * Screen structure in memory:
 *
 *  The screen is represented by an array of Rows*Columns where the ASCII
 * codes of every screen position are saved. There is another array to save
 * chars attributes. This represenatation makes possible a faster way
 * of painting the screen.
 *
 * How PAINT is done (See WM_PAINT):
 *
 *  First obtain invalidated rect. Then, for every row to paint, we count
 * consecutives chars with the same attribute and output them all together
 * with a call to TextOut function. This makes the PAINT function faster.
 *-------------------------------------------------------------------------*/


/*---------------------------------------------------------------------------
 * Create a text window:
 *-------------------------------------------------------------------------*/

VOID
CreateTextFont(HWND hWnd,
	       LOGFONT* pLF,
	       INT fontsize)
{
  HDC        hDC;
  TEXTWINDOWINFO* twi;
  TEXTMETRIC tm;
  HFONT      hSaveFont;
  INT	     CharHeight, CharWidth;
  RECT       rect;

  /* Get memory for text window structure */
  twi = (TEXTWINDOWINFO*) GetWindowLong(hWnd, 0);

  /* Create the font */
  hDC = GetDC(hWnd);

  twi->LogFont.lfHeight         = pLF->lfHeight;
  twi->LogFont.lfWidth        	= 0;
  twi->LogFont.lfEscapement   	= 0;
  twi->LogFont.lfOrientation  	= 0;
  twi->LogFont.lfWeight       	= pLF->lfWeight;
  twi->LogFont.lfItalic     	= FALSE;
  twi->LogFont.lfUnderline  	= FALSE;
  twi->LogFont.lfStrikeOut  	= FALSE;
  twi->LogFont.lfCharSet  	= ANSI_CHARSET;
  twi->LogFont.lfOutPrecision 	= OUT_TT_PRECIS;
  twi->LogFont.lfClipPrecision 	= CLIP_TT_ALWAYS;
  twi->LogFont.lfQuality 	= DEFAULT_QUALITY;
  twi->LogFont.lfPitchAndFamily = FIXED_PITCH | FF_MODERN;
  strcpy(twi->LogFont.lfFaceName, pLF->lfFaceName);

  twi->hFont = CreateFontIndirect(&(twi->LogFont));
  if (!twi->hFont) {
    MessageBox(GetFocus(), "Out of memory creating text font", "Wintext",
	       MB_ICONHAND | MB_SYSTEMMODAL | MB_OK);
    return;
  }

  /* Get font dimmensions */
  hSaveFont = SelectObject(hDC, twi->hFont);

  GetTextMetrics(hDC, &tm);

  CharHeight = tm.tmHeight+tm.tmExternalLeading;
  CharWidth  = tm.tmAveCharWidth;

  SelectObject(hDC, hSaveFont);
  ReleaseDC(hWnd, hDC);

  /* Fill in window structure */
  twi->CharWidth    	= CharWidth;
  twi->CharHeight   	= CharHeight;

  /* reset scroll bars and redisplay window */
  twi->VScroll 	   	= 0;
  twi->HScroll       	= 0;
  SetScrollPos(hWnd, SB_HORZ, twi->HScroll, TRUE);
  SetScrollPos(hWnd, SB_VERT, twi->VScroll, TRUE);
  InvalidateRect(hWnd, NULL, TRUE);

  /* force recomputation of RowsShowed/ColsShowed fields */
  GetClientRect(hWnd, &rect);
  DoSize(hWnd, WM_SIZE, 0, MAKELPARAM(rect.right-rect.left,rect.bottom-rect.top));

  WinClrscr(hWnd);
  WinGotoxy(hWnd, 1, 1);
  SendMessage(hWnd, WM_CHAR, (WPARAM) VK_RETURN, 0L);
}

HWND CreateTextWindow(HINSTANCE hInstance, HWND hParent, INT Left, INT Top,
				UINT Columns, UINT Rows, LPCSTR Fontname, 
				INT Fontsize, INT FontWeight, HACCEL hAccelTable)
{
  HWND 		 hWnd;
  HDC		 hDC;
  HFONT		 hSaveFont;
  TEXTMETRIC 	 tm;
  INT		 CharHeight, CharWidth;
  TEXTWINDOWINFO *twi;
  HGLOBAL	 hScreen, hKbd, hBufferEd, hBufferEdPrev;
  FPOINTER	 Screen;

  hWnd = CreateWindowEx(
	      WS_EX_CLIENTEDGE,
	      "TextWindow",
	      NULL,
	      WS_CHILD | WS_VISIBLE | WS_HSCROLL | WS_VSCROLL,
	      CW_USEDEFAULT,
	      CW_USEDEFAULT,
	      CW_USEDEFAULT,
	      CW_USEDEFAULT,
	      hParent,
	      NULL,
	      hInstance,
	      (LPSTR) NULL);

  Rows *= NUM_WINDOW_PAGES;

  if(!hWnd)
    return NULL;

  /* Get memory for text window structure */
  twi = (TEXTWINDOWINFO*) GetWindowLong(hWnd, 0);

  /* Get memory for screen buffer */ 
  hScreen = GlobalAlloc(GMEM_MOVEABLE, (DWORD) sizeof(CHAR)*Rows*Columns*2);

  if(!hScreen)
    return NULL;

  /* Fill with spaces */
  Screen = (FPOINTER) GlobalLock(hScreen);
  MyMemSet(Screen, ' ', (ULONG)Rows*(ULONG)Columns);
  MyMemSet(Screen+(ULONG)Rows*(ULONG)Columns, BACKGROUND*WHITE+BLACK, (ULONG)Rows*(ULONG)Columns);
  GlobalUnlock(hScreen);

  /* Get memory for keyboard buffer */
  hKbd = GlobalAlloc(GMEM_MOVEABLE, (DWORD)(KEYBOARD_BUFFER_MAX_LENGTH*sizeof(ONE_BUFFER_KEY)));

  if(!hKbd)
    return NULL;

  /* Get memory for buffered Input */ 
  hBufferEd = GlobalAlloc(GMEM_MOVEABLE|GMEM_ZEROINIT,
			 (DWORD) (sizeof(CHAR)*(EDIT_BUFFER_MAX_LENGTH+1)));
  hBufferEdPrev = GlobalAlloc(GMEM_MOVEABLE|GMEM_ZEROINIT,
			     (DWORD) (sizeof(CHAR)*(EDIT_BUFFER_MAX_LENGTH+1)*NUM_EDIT_BUFFERS));

  if (!hBufferEd || !hBufferEdPrev)
    return NULL;

  /* Create the font */
  hDC = GetDC(hWnd);

  twi->LogFont.lfHeight         = -MulDiv(Fontsize, GetDeviceCaps(hDC, LOGPIXELSY), 72);
  twi->LogFont.lfWidth        	= 0;
  twi->LogFont.lfEscapement   	= 0;
  twi->LogFont.lfOrientation  	= 0;
  twi->LogFont.lfWeight       	= FontWeight;
  twi->LogFont.lfItalic     	= FALSE;
  twi->LogFont.lfUnderline  	= FALSE;
  twi->LogFont.lfStrikeOut  	= FALSE;
  twi->LogFont.lfCharSet  	= ANSI_CHARSET;
  twi->LogFont.lfOutPrecision 	= OUT_TT_PRECIS;
  twi->LogFont.lfClipPrecision 	= CLIP_TT_ALWAYS;
  twi->LogFont.lfQuality 	= DEFAULT_QUALITY;
  twi->LogFont.lfPitchAndFamily = FIXED_PITCH | FF_MODERN;
  strcpy(twi->LogFont.lfFaceName, Fontname);

  twi->hFont = CreateFontIndirect(&(twi->LogFont));
  if (!twi->hFont) {
    MessageBox(GetFocus(), "Out of memory creating text font", "Wintext",
	       MB_ICONHAND | MB_SYSTEMMODAL | MB_OK);
    return NULL;
  }

  /* Get font dimmensions */
  hSaveFont = SelectObject(hDC, twi->hFont);

  GetTextMetrics(hDC, &tm);

  CharHeight = tm.tmHeight+tm.tmExternalLeading;
  CharWidth  = tm.tmAveCharWidth;

  SelectObject(hDC, hSaveFont);
  ReleaseDC(hWnd, hDC);

  /* Fill in window structure */
  twi->Left         	= Left;
  twi->Top          	= Top;
  twi->CharWidth    	= CharWidth;
  twi->CharHeight   	= CharHeight;
  twi->Rows         	= Rows;
  twi->Cols         	= Columns;
  twi->RowsShowed	= 0;  /* Computed in WM_SIZE */
  twi->ColsShowed	= 0;  /* Computed in WM_SIZE */
  twi->PosX	    	= FIRST_COL;
  twi->PosY	    	= FIRST_ROW;
  twi->ScrBuffer    	= hScreen;
  twi->CursorStatus 	= TRUE;
  twi->svCursorStatus 	= TRUE;
  twi->InsertStatus 	= TRUE;
  twi->IsFocused    	= FALSE;
  twi->TextAttr      	= BLACK;
  twi->TextBackAttr 	= WHITE;
  twi->Bright	      	= FALSE;
  twi->KbdBuffer     	= hKbd;
  twi->KbdInx	      	= 0;
  twi->hAccelTable   	= hAccelTable;
  twi->hBufferEd     	= hBufferEd;
  twi->hBufferEdPrev 	= hBufferEdPrev;
  twi->IoInx	      	= -1;
  twi->AnsiPtr	      	= 0;
  twi->InAnsi	      	= FALSE;
  twi->VScroll 	   	= 0;
  twi->HScroll       	= 0;
  twi->Selecting     	= FALSE;
  twi->Selected	   	= FALSE;
  twi->rSelected.top 	= twi->rSelected.left
			= twi->rSelected.bottom
			= twi->rSelected.right
			= twi->pBaseSel.x
			= twi->pBaseSel.y 
                        = 0;
  twi->InEdit	      	= FALSE;
  twi->EdStr	      	= NULL;
  twi->Control 		= FALSE;
  twi->Shift 		= FALSE;
  twi->LButtonDown	= FALSE;
#if USE_THREADS
  twi->eventKeyboardNotEmpty   
                        = CreateEvent(NULL,  /* default security  */
                                      FALSE, /* auto reset object */
                                      FALSE, /* nonsignaled       */
                                      NULL); /* no name           */
#endif
  twi->TextMetric	= tm;

  /* Resize window */
  #define HINDENT	2
  #define VINDENT	2
  #define X3D		2
  #define Y3D		2


  MoveWindow(hWnd, Left+X3D, Top+Y3D,
		   CharWidth*Columns+2*HINDENT+2*X3D,
		   CharHeight*Rows/NUM_WINDOW_PAGES+2*VINDENT+2*Y3D,
		   FALSE);

  ShowWindow(hWnd, SW_SHOW);
  UpdateWindow(hWnd);

  return hWnd;
}


/*---------------------------------------------------------------------------
 * Functions to get pointers to screen buffer:
 *-------------------------------------------------------------------------*/

#define GetScreenPos(ptr, col, row) GetScreenPos1(twi, ptr, col, row)
#define GetAttrPos(ptr, col, row)   GetAttrPos1(twi, ptr, col, row)

static FPOINTER GetScreenPos1(TEXTWINDOWINFO *twi, FPOINTER ptr, INT col, INT row)
{
  return ((ptr)+(ULONG)((ULONG)(twi->Cols)*(ULONG)(row-1)+((ULONG)(col-1))));
}

static FPOINTER GetAttrPos1(TEXTWINDOWINFO *twi, FPOINTER ptr, INT col, INT row)
{
  return (((ptr)+(ULONG)((ULONG)(twi->Cols)*(ULONG)(row-1)+((ULONG)(col-1))))+
	 ((ULONG)twi->Cols*(ULONG)twi->Rows));
}



/*---------------------------------------------------------------------------
 * Functions to ouput strings on the text window:
 *-------------------------------------------------------------------------*/


#define IN_WM_PAINT 		1

/* Get DC and set font */
static VOID TextBeginPaint (BOOL InPaint, HWND hWnd, HDC *hDC, PAINTSTRUCT *ps, HFONT *hSaveFont)
{
  TEXTWINDOWINFO  *twi;

  twi = (TEXTWINDOWINFO*) GetWindowLong(hWnd, 0);

  if (InPaint)
    *hDC = BeginPaint(hWnd, ps);
  else
    *hDC = GetDC(hWnd);

  *hSaveFont = SelectObject(*hDC, twi->hFont);
}


/* Restore old font and release DC */
static VOID TextEndPaint (BOOL InPaint, HWND hWnd, HDC *hDC, PAINTSTRUCT *ps, HFONT *hSaveFont)
{
  SelectObject(*hDC, *hSaveFont);

  if (InPaint)
    EndPaint(hWnd, ps);
  else
    ReleaseDC(hWnd, *hDC);
}


/* Outputs a string of length n with atribute Attr on the Window */
static VOID TextOutput (HWND hWnd, HDC hDC, UINT Col, UINT Row, LPSTR Str, INT n, UCHAR Attr)
{
  TEXTWINDOWINFO  *twi;

  twi = (TEXTWINDOWINFO*) GetWindowLong(hWnd, 0);

  /* Set attributes */
  if (Attr & BRIGHT) {
    SetTextColor(hDC, thePalette[(Attr&0x07)+MAXCOLORS]);
    SetBkColor(hDC, thePalette[((Attr>>4)&0x07)+MAXCOLORS]);
  }
  else if (Attr & SELECTED) {
    SetTextColor(hDC, thePalette[HIGHLIGHTTEXT]);
    SetBkColor(hDC, thePalette[HIGHLIGHT]);
  }
  else {
    SetTextColor(hDC, thePalette[Attr&0x07]);
    SetBkColor(hDC, thePalette[(Attr>>4)&0x07]);
  }

  TextOut(hDC,
	  twi->CharWidth*(Col-FIRST_COL)+HINDENT,
	  twi->CharHeight*(Row-FIRST_ROW)+VINDENT,
	  (LPCSTR) Str, n);
  /* Commented out; no use was made of the extra features
     that ExtTextOut() offers, so revert back to the simpler API function.
  ExtTextOut(hDC,
	  twi->CharWidth*(Col-FIRST_COL)+HINDENT,
	  twi->CharHeight*(Row-FIRST_ROW)+VINDENT,
	  0, NULL,
	  (LPCSTR) Str, n,
	  NULL);
  */
}

/* Print a region in the selected color. A region is a set of lines, specified
   with a RECT, and correspondes to a set of lines that is not really a rectangle */
VOID PutTextSelectedRegion (HWND hWnd, RECT aRect)
{
  HDC hDC;
  INT i;
  TEXTWINDOWINFO  *twi;
  FPOINTER BaseScreen;
  HFONT hSaveFont;
  PAINTSTRUCT ps;

  twi = (TEXTWINDOWINFO*) GetWindowLong(hWnd, 0);

  /* Check for limits */
  aRect.top    = max (FIRST_ROW, aRect.top);
  aRect.left   = max (FIRST_COL, aRect.left);
  aRect.bottom = min ((INT)twi->Rows, aRect.bottom);
  aRect.right  = min ((INT)twi->Cols, aRect.right);

  TextBeginPaint (!IN_WM_PAINT, hWnd, &hDC, &ps, &hSaveFont);

  BaseScreen = (FPOINTER) GlobalLock(twi->ScrBuffer);

  #define PRINT(Col, Row, Str, n)   TextOutput(hWnd, hDC,      \
				    Col-twi->HScroll,          \
					 Row-twi->VScroll,          \
				    ((LPSTR) (Str)),  	       \
					 (n),		       \
				    BACKGROUND*BLACK+WHITE+SELECTED);

  /* Print first line of region */
  PRINT(aRect.left, aRect.top,
	GetScreenPos(BaseScreen, aRect.left, aRect.top),
	(aRect.bottom > aRect.top) ? twi->Cols-aRect.left+FIRST_COL : aRect.right-aRect.left+FIRST_COL);

  /* Print middle lines */
  for (i=aRect.top+1; i<aRect.bottom; i++) {

     PRINT(FIRST_COL, i,
	   (LPCSTR)GetScreenPos(BaseScreen, FIRST_COL, i),
	   twi->Cols);
  }

  /* Print last line */
  if (aRect.bottom > aRect.top) {
    PRINT(FIRST_COL, aRect.bottom,
	  (LPCSTR)GetScreenPos(BaseScreen, FIRST_COL, aRect.bottom),
	  aRect.right);
  }

  GlobalUnlock (twi->ScrBuffer);

  TextEndPaint (!IN_WM_PAINT, hWnd, &hDC, &ps, &hSaveFont);

}

/* Print a rectangle using the colors in the screen buffer */
static VOID PutTextRect (BOOL In_WM_PAINT, HWND hWnd, RECT aRect)
{
  TEXTWINDOWINFO *twi;
  HDC hDC;
  HFONT hSaveFont;
  PAINTSTRUCT ps;
  FPOINTER	  Screen, BaseScreen, ScreenAttr;
  LONG		  i;
  UINT	          nChars;
  LONG	          currX, currCol;
  UCHAR	          Attr;

  twi = (TEXTWINDOWINFO*) GetWindowLong(hWnd, 0);

  /* Check for limits */
  aRect.top    = max (FIRST_ROW, aRect.top);
  aRect.left   = max (FIRST_COL, aRect.left);
  aRect.bottom = min (twi->Rows, (UINT)aRect.bottom);
  aRect.right  = min (twi->Cols, (UINT)aRect.right);

  TextBeginPaint (In_WM_PAINT, hWnd, &hDC, &ps, &hSaveFont);

  BaseScreen = (FPOINTER) GlobalLock(twi->ScrBuffer);

  for(i=aRect.top; i<=aRect.bottom; i++) {

    currCol = aRect.left;
    ScreenAttr = GetAttrPos(BaseScreen, aRect.left, i);
    Screen = GetScreenPos(BaseScreen, aRect.left, i);

    while (currCol <= aRect.right) {

	currX = currCol;

	Attr = *ScreenAttr;

	/* Count consecutive chars with same attribute */
	for(nChars=0; (currCol<=aRect.right)&&(*ScreenAttr==Attr); nChars++, currCol++, ScreenAttr++);

	TextOutput (hWnd, hDC, currX-twi->HScroll, i-twi->VScroll, (LPSTR) Screen, nChars, Attr);

	/* Go to next sequence of consecutive attributes chars */
	Screen += nChars;
    }
  }
  GlobalUnlock(twi->ScrBuffer);

  TextEndPaint (In_WM_PAINT, hWnd, &hDC, &ps, &hSaveFont);
}

/* Print a region using the colors in the screen buffer */
static VOID PutTextRegion (BOOL In_WM_PAINT, HWND hWnd, RECT aRect)
{
  RECT theRect;
  TEXTWINDOWINFO *twi;

  twi = (TEXTWINDOWINFO*) GetWindowLong(hWnd, 0);

  /* Print first line */
  theRect.top    = aRect.top;
  theRect.bottom = aRect.top;
  theRect.left = aRect.left;
  if (aRect.bottom > aRect.top) {
    theRect.right = twi->Cols;
  }
  else {
    theRect.right = aRect.right;
  }
  PutTextRect (In_WM_PAINT, hWnd, theRect);

  /* Print middle lines */
  if (aRect.bottom > aRect.top) {
	 theRect.top    = aRect.top+1;
    theRect.bottom = aRect.bottom-1;
    theRect.left = FIRST_COL;
    theRect.right = twi->Cols;
    PutTextRect (In_WM_PAINT, hWnd, theRect);

	 /* Print last line */
    theRect.top    = aRect.bottom;
    theRect.bottom = aRect.bottom;
    theRect.left = FIRST_COL;
    theRect.right = aRect.right;
    PutTextRect (In_WM_PAINT, hWnd, theRect);

  }
}



/*---------------------------------------------------------------------------
 * Caret handling:
 *-------------------------------------------------------------------------*/

/* These functions can only be executed by the thread that
   owns the caret. Other threads should use

     WinGotoxy, WinSetcursor and WinSetinsert
*/

/* Set caret position */
static VOID ForceMoveCaret (HWND hWnd, UINT x, UINT y)
{
 TEXTWINDOWINFO  *twi;

 twi = (TEXTWINDOWINFO*) GetWindowLong(hWnd, 0);

 twi->PosX = x;
 twi->PosY = y;

 if (!twi->InsertStatus) 
   SetCaretPos((INT)(twi->CharWidth*(x-1-twi->HScroll)+HINDENT), (INT)(twi->CharHeight*(y-1-twi->VScroll)+(twi->CharHeight/2)+VINDENT));
 else 
   SetCaretPos((INT)(twi->CharWidth*(x-1-twi->HScroll)+HINDENT), (INT)(twi->CharHeight*(y-1-twi->VScroll)+VINDENT));
}

/* Shows caret. Caret shape depends on InsertStatus */
static VOID ForceShowCaret(HWND hWnd)
{
  TEXTWINDOWINFO  *twi;

  twi = (TEXTWINDOWINFO*) GetWindowLong(hWnd, 0);

  if (twi->InsertStatus) {
      CreateCaret(hWnd, NULL, twi->CharWidth, twi->CharHeight);
  }
  else {
      CreateCaret(hWnd, NULL, twi->CharWidth, (twi->CharHeight)/2);
  }
  ForceMoveCaret(hWnd, twi->PosX, twi->PosY);
  ShowCaret(hWnd);
}


static VOID ForceDestroyCaret(HWND hWnd)
{
  DestroyCaret();
}

static VOID ForceHideCaret(HWND hWnd)
{
  HideCaret(hWnd);
}


/*---------------------------------------------------------------------------
 * Text class window WinProc:
 *-------------------------------------------------------------------------*/

static INT DoCreate (HWND hWnd, UINT message, WPARAM wParam, LPARAM lParam)
{
  TEXTWINDOWINFO *twi;

  /* Get window structure */
  twi = (TEXTWINDOWINFO *) malloc(sizeof(TEXTWINDOWINFO));
  if (!twi)
    return -1;

  memset(twi, 0, sizeof(TEXTWINDOWINFO));
  SetWindowLong(hWnd, 0, (LONG) twi);

  GetSysColors();

  return 1;
}

static VOID DoDestroy (HWND hWnd, UINT message, WPARAM wParam, LPARAM lParam)
{
  TEXTWINDOWINFO *twi;

  twi = (TEXTWINDOWINFO*) GetWindowLong(hWnd, 0);

  /* Free screen buffer */
  GlobalFree(twi->ScrBuffer);

  /* Free keyboard buffer */
  GlobalFree(twi->KbdBuffer);

  /* Free buffered input buffers */
  GlobalFree(twi->hBufferEd);
  GlobalFree(twi->hBufferEdPrev);

  /* Delete font, if created */
  if (twi->hFont)
    DeleteObject(twi->hFont);

  /* Free window information structure */
  free(twi);

}

static VOID DoPaint (HWND hWnd, UINT message, WPARAM wParam, LPARAM lParam)
{
  HDC	          hDC;
  PAINTSTRUCT     ps;
  TEXTWINDOWINFO *twi;
  HFONT		  hSaveFont;
  RECT         	  aRect;

  twi = (TEXTWINDOWINFO*) GetWindowLong(hWnd, 0);

  TextBeginPaint (IN_WM_PAINT, hWnd, &hDC, &ps, &hSaveFont);

  /* Get rectangle to repaint */
  aRect.top = min((UINT)((ps.rcPaint.top-VINDENT)/(INT)twi->CharHeight)+FIRST_ROW+(INT)twi->VScroll,
				twi->Rows);
  aRect.bottom  = min((UINT)((ps.rcPaint.bottom-VINDENT-1)/(INT)twi->CharHeight)+FIRST_ROW+(INT)twi->VScroll,
			  twi->Rows);

  aRect.left    = min((UINT)((ps.rcPaint.left-HINDENT)/(INT)twi->CharWidth)+FIRST_COL+(INT)twi->HScroll,
			  twi->Cols);
  aRect.right   = min((UINT)((ps.rcPaint.right-HINDENT-1)/(INT)twi->CharWidth)+FIRST_COL+(INT)twi->HScroll,
			  twi->Cols);

  PutTextRect (!IN_WM_PAINT, hWnd, aRect);

  TextEndPaint (IN_WM_PAINT, hWnd, &hDC, &ps, &hSaveFont);
}


static VOID DoSetFocus (HWND hWnd, UINT message, WPARAM wParam, LPARAM lParam)
{
  TEXTWINDOWINFO  *twi;

  twi = (TEXTWINDOWINFO*) GetWindowLong(hWnd, 0);
  twi->IsFocused = TRUE;
   
  ForceShowCaret(hWnd);
  UnSelect(hWnd);
}

static VOID DoKillFocus (HWND hWnd, UINT message, WPARAM wParam, LPARAM lParam)
{
  TEXTWINDOWINFO  *twi;

  twi = (TEXTWINDOWINFO*) GetWindowLong(hWnd, 0);
  twi->IsFocused = FALSE;

  ForceDestroyCaret(hWnd);
  UnSelect(hWnd);
}

static INT DoKeyDown (HWND hWnd, UINT message, WPARAM wParam, LPARAM lParam)
{
  UINT		  i;
  static WPARAM	  ControlKeys[] = {VK_UP, VK_DOWN,  VK_LEFT, VK_RIGHT,
				   VK_DELETE, VK_INSERT, VK_HOME, VK_END,
				   VK_PRIOR, VK_NEXT, 0};
  WPARAM           VirtKey;
  TEXTWINDOWINFO  *twi;
  INT              retCode = 1;

  twi = (TEXTWINDOWINFO*) GetWindowLong(hWnd, 0);
  VirtKey = (WPARAM) wParam;

/*{char buff[300];
 wsprintf(buff,"%u  %d",VirtKey, (HIWORD(lParam) & KF_EXTENDED));
 MessageBox(GetFocus(), buff, "DoKeyDown", MB_ICONEXCLAMATION | MB_OK);}*/

  switch(VirtKey) {
    case VK_CANCEL:  if (HIWORD(lParam) & KF_EXTENDED) {
//			PostMessage(GetParent(hWnd), WM_COMMAND, ID_STOP, 0L);
    			twi->Control = FALSE;
    			MessageBeep(0xFFFFFFFF);
			raise(SIGINT);
    			retCode = 0;
		     }
		     break;

    case VK_CONTROL: twi->Control = TRUE;
		     retCode = 0;
                     break;

    case VK_SHIFT:   twi->Shift = TRUE;
		     retCode = 0;
                     break;
    
    default:         for(i=0; ControlKeys[i]; i++)
                       if (VirtKey == ControlKeys[i]) {
                         PostMessage(hWnd, WM_CHAR, VirtKey, MAKELONG(LOWORD(lParam),HIWORD(lParam)|KF_EXTENDED));
 		           retCode = 0;
                           break;
                     }
  
  }

  //printf("\nWM_KEYDOWN VirtKey %u   control %d    shift %d  isExtended %d ", VirtKey, twi->Control, twi->Shift, (HIWORD(lParam) & KF_EXTENDED));

  return retCode;
}

static INT DoKeyUp (HWND hWnd, UINT message, WPARAM wParam, LPARAM lParam)
{
  TEXTWINDOWINFO  *twi;
  WPARAM           VirtKey;
  INT              retCode;

  twi     = (TEXTWINDOWINFO*) GetWindowLong(hWnd, 0);
  VirtKey = (WPARAM) wParam;

  
/*
{char buff[300];
 wsprintf(buff,"%u  %d",VirtKey, (HIWORD(lParam) & KF_EXTENDED));
  MessageBox(GetFocus(), buff, "DoKeyUp", MB_ICONEXCLAMATION | MB_OK);}
*/

  switch(VirtKey) {
    case VK_MENU:
    case VK_CONTROL:  twi->Control = FALSE;
		      retCode = 0;
                      break;

    case VK_SHIFT:    twi->Shift = FALSE;
		      retCode = 0;
                      break;

    default:          retCode = 1;
                      break;
  }

  //printf("\nWM_KEYUP   VirtKey %u   control %d    shift %d  isExtended %d ", VirtKey, twi->Control, twi->Shift, (HIWORD(lParam) & KF_EXTENDED));

  return retCode;
}

static INT DoChar (HWND hWnd, UINT message, WPARAM wParam, LPARAM lParam)
{
  TEXTWINDOWINFO  *twi;
  ONE_BUFFER_KEY   far   *KeyboardBuffer;
  TCHAR		   CharCode;
  UINT		   i;

  twi = (TEXTWINDOWINFO*) GetWindowLong(hWnd, 0);
  CharCode = (TCHAR) wParam;


/*{char buff[300];
 wsprintf(buff,"%d  %d control %d  ",CharCode, (HIWORD(lParam) & KF_EXTENDED), twi->Control);
 MessageBox(GetFocus(), buff, "DoChar", MB_ICONEXCLAMATION | MB_OK);}
*/
  //printf("\nWM_CHAR    CharCode %d   control %d    shift %d  isExtended %d ", CharCode, twi->Control, twi->Shift, (HIWORD(lParam) & KF_EXTENDED));

  #define MY_VK_C      3
  #define MY_VK_V     22
  #define MY_VK_X     24
  #define MY_VK_Z     26

  switch(CharCode) {
    /*
    case VK_TAB:      * expand into spaces *
                      for(i=0;i<TAB_SIZE;i++)
      			PostMessage(hWnd, WM_CHAR, VK_SPACE, lParam);
    		      return 0;
*/
    case VK_INSERT:   if (twi->Control) {
                        PostMessage(hWnd, WM_COPY, 0, 0L);
			return 0;
                      }
                      else if (twi->Shift) {
                        PostMessage(hWnd, WM_PASTE, 0, 0L);
			return 0;
                      }
		      else
                        break;

    case VK_DELETE:   if (twi->Control) {
                        PostMessage(hWnd, WM_CLEAR, 0, 0L);
			return 0;
                      }
                      else if (twi->Shift) {
                        PostMessage(hWnd, WM_CUT, 0, 0L);
			return 0;
                      }
		      else
                        break;

    case MY_VK_C:     if (twi->Control) {
                        PostMessage(hWnd, WM_COPY, 0, 0L);
			return 0;
                      }
		      else
                        break;

    case MY_VK_V:     if (twi->Control) {
                        PostMessage(hWnd, WM_PASTE, 0, 0L);
			return 0;
                      }
		      else
                        break;

    case MY_VK_X:     if (twi->Control) {
                        PostMessage(hWnd, WM_CUT, 0, 0L);
			return 0;
                      }
		      else
                        break;

    case VK_RETURN:   /* set off KF_EXTENDED for numeric pad ENTER key */
                      lParam = MAKELONG(LOWORD(lParam),HIWORD(lParam)&(~KF_EXTENDED));
                      break;
  }


  UnSelect(hWnd);

  if (twi->KbdInx >= KEYBOARD_BUFFER_MAX_LENGTH-1)
    MessageBox(GetFocus(), "Keyboard buffer full", NULL, MB_ICONEXCLAMATION | MB_OK);
  else {
    KeyboardBuffer = (ONE_BUFFER_KEY *) GlobalLock(twi->KbdBuffer);

    if (CharCode == MY_VK_Z && twi->Control) /* End of file */
      wParam = (WPARAM)EOF;

    KeyboardBuffer[(twi->KbdInx)].KeyCode = (INT) wParam;
    /* Control keys */
    KeyboardBuffer[(twi->KbdInx)++].IsExtended = (HIWORD(lParam) & KF_EXTENDED);

    GlobalUnlock(twi->KbdBuffer);
#if USE_THREADS
    PulseEvent(twi->eventKeyboardNotEmpty);
#endif
  }

  return 0;
}

static VOID DoSize (HWND hWnd, UINT message, WPARAM wParam, LPARAM lParam)
{
  TEXTWINDOWINFO  *twi;

  twi = (TEXTWINDOWINFO*) GetWindowLong(hWnd, 0);

  /* Get number of rows and columns currently showed */
  if (twi->CharHeight)
    twi->RowsShowed = (HIWORD(lParam)-VINDENT)/twi->CharHeight;

  if (twi->CharWidth)
    twi->ColsShowed = (LOWORD(lParam)-HINDENT)/twi->CharWidth;

  /* Hide or show HSCROLL BAR */
  if (twi->ColsShowed < twi->Cols) {
    /* Small window */
    SetScrollRange(hWnd, SB_HORZ, 0, twi->Cols-twi->ColsShowed, TRUE);
	 SetScrollPos(hWnd, SB_HORZ, twi->HScroll, TRUE);
  }
  else {
	 /* Hide scroll bar */
    SetScrollRange(hWnd, SB_HORZ, 0, 0, TRUE);
    twi->HScroll = 0;
	 SetScrollPos(hWnd, SB_HORZ, twi->HScroll, TRUE);
    WinGotoxy(hWnd, twi->PosX, twi->PosY);
  }

  /* Set Range for VSCROLL BAR */
  SetScrollRange(hWnd, SB_VERT, 0, twi->Rows-twi->RowsShowed, TRUE);
  if (twi->VScroll > twi->Rows-twi->RowsShowed) {
    twi->VScroll = twi->Rows-twi->RowsShowed;
    WinGotoxy(hWnd, twi->PosX, twi->PosY);
  }
  SetScrollPos(hWnd, SB_VERT, twi->VScroll, TRUE);
}


static VOID	MyScrollWindow(HWND hWnd, INT x, INT y)
{
	/*RECT wRect;

	GetClientRect (hWnd, &wRect);
	wRect.left   += HINDENT;
	wRect.right  -= HINDENT;
	wRect.top    += VINDENT;
	wRect.bottom -= VINDENT;

	ScrollWindow(hWnd, x, y, NULL, &wRect);
	*/
	ScrollWindow(hWnd, x, y, NULL, NULL);

}


static VOID DoHScroll (HWND hWnd, UINT message, WPARAM wParam, LPARAM lParam)
{
  TEXTWINDOWINFO  *twi;
  UINT 		   SbMin, SbMax;


  twi = (TEXTWINDOWINFO*) GetWindowLong(hWnd, 0);

  switch(LOWORD(wParam)) {

    case SB_PAGEDOWN:
    case SB_LINEDOWN: {

      GetScrollRange(hWnd, SB_HORZ, &SbMin, &SbMax);

      if (twi->HScroll < SbMax) {
	twi->HScroll ++;
	SetScrollPos(hWnd, SB_HORZ, twi->HScroll, TRUE);
	MyScrollWindow(hWnd, -(INT)twi->CharWidth, 0);

	UpdateWindow(hWnd);
	WinGotoxy(hWnd, twi->PosX, twi->PosY);
		}
    }
    break;

    case SB_PAGEUP:
    case SB_LINEUP: {

      RECT aRect;

      GetScrollRange(hWnd, SB_HORZ, &SbMin, &SbMax);

      if (twi->HScroll > SbMin) {
	twi->HScroll --;
	SetScrollPos(hWnd, SB_HORZ, twi->HScroll, TRUE);
	MyScrollWindow(hWnd, twi->CharWidth, 0);

	GetClientRect(hWnd, &aRect);
	aRect.left = 0;
	aRect.right = twi->CharWidth+HINDENT;
	InvalidateRect(hWnd, &aRect, FALSE);

	UpdateWindow(hWnd);
	WinGotoxy(hWnd, twi->PosX, twi->PosY);

      }
    }
	 break;

    case SB_THUMBPOSITION:{

      GetScrollRange(hWnd, SB_HORZ, &SbMin, &SbMax);

      twi->HScroll = HIWORD(wParam);

      SetScrollPos(hWnd, SB_HORZ, twi->HScroll, TRUE);
      InvalidateRect(hWnd,NULL,TRUE);

      UpdateWindow(hWnd);
      WinGotoxy(hWnd, twi->PosX, twi->PosY);

    }
    break;
  }
}

static VOID DoVScroll (HWND hWnd, UINT message, WPARAM wParam, LPARAM lParam)
{
  TEXTWINDOWINFO  *twi;
  UINT 		   SbMin, SbMax;

  twi = (TEXTWINDOWINFO*) GetWindowLong(hWnd, 0);

  switch(LOWORD(wParam)) {

    case SB_PAGEDOWN:
	 case SB_LINEDOWN: {

      GetScrollRange(hWnd, SB_VERT, &SbMin, &SbMax);

      if (twi->VScroll < SbMax) {
	twi->VScroll ++;
	SetScrollPos(hWnd, SB_VERT, twi->VScroll, TRUE);
	MyScrollWindow(hWnd, 0, -(INT)twi->CharHeight);
	UpdateWindow(hWnd);
	WinGotoxy(hWnd, twi->PosX, twi->PosY);
      }
    }
    break;

    case SB_PAGEUP:
    case SB_LINEUP: {

      RECT aRect;

      GetScrollRange(hWnd, SB_VERT, &SbMin, &SbMax);

      if (twi->VScroll > SbMin) {
	twi->VScroll --;
	SetScrollPos(hWnd, SB_VERT, twi->VScroll, TRUE);
	MyScrollWindow(hWnd, 0, twi->CharHeight);

	GetClientRect(hWnd, &aRect);
	aRect.top = 0;
	aRect.bottom = twi->CharHeight+VINDENT;
	InvalidateRect(hWnd, &aRect, FALSE);

	UpdateWindow(hWnd);
	WinGotoxy(hWnd, twi->PosX, twi->PosY);
      }
    }
    break;

    case SB_THUMBPOSITION:{

      GetScrollRange(hWnd, SB_VERT, &SbMin, &SbMax);

      twi->VScroll = HIWORD(wParam);

      SetScrollPos(hWnd, SB_VERT, twi->VScroll, TRUE);
      InvalidateRect(hWnd,NULL,TRUE);
      UpdateWindow(hWnd);
      WinGotoxy(hWnd, twi->PosX, twi->PosY);
    }
    break;
  }
}

static VOID DoLButtonDown (HWND hWnd, UINT message, WPARAM wParam, LPARAM lParam)
{
  INT		  xPos, yPos;
  TEXTWINDOWINFO *twi;

  twi = (TEXTWINDOWINFO*) GetWindowLong(hWnd, 0);

  UnSelect(hWnd);

  xPos = LOWORD(lParam);
  yPos = HIWORD(lParam);

  /* Capture cursor */
  SetCapture(hWnd);

  twi->svCursorStatus = WinSetcursor(hWnd, FALSE);
  twi->Selecting = TRUE;

  #define AsCol(xPos)   min((INT)twi->Cols, (((xPos)-HINDENT)/(INT)twi->CharWidth)+(INT)twi->HScroll+1)
  #define AsRow(yPos)   min((INT)twi->Rows, (((yPos)-VINDENT)/(INT)twi->CharHeight)+(INT)twi->VScroll+1)

  twi->pBaseSel.x = twi->rSelected.right = twi->rSelected.left = AsCol(xPos);
  twi->pBaseSel.y = twi->rSelected.bottom = twi->rSelected.top = AsRow(yPos);

  twi->LButtonDown = TRUE;
}

static VOID DoMouseMove (HWND hWnd, UINT message, WPARAM wParam, LPARAM lParam)
{
  INT		   xPos, yPos, Row, Col;
  TEXTWINDOWINFO  *twi;
  RECT	     	   rClient, aRect;
  POINT            aPoint;
  FPOINTER         ScreenPosIni, ScreenPosEnd, BaseScreen;

  twi = (TEXTWINDOWINFO*) GetWindowLong(hWnd, 0);

  if (twi->Selecting) {

    xPos = (INT)(SHORT)LOWORD(lParam);
    yPos = (INT)(SHORT)HIWORD(lParam);

    GetClientRect(hWnd, &rClient);

    /* Don't let xPos get out of client window */
    xPos = min((INT)rClient.right-2*HINDENT, xPos);
    xPos = max((INT)rClient.left, xPos);

    /* If yPos is out of client window Scroll selection */
    if (yPos < (INT)rClient.top) {
      yPos = 1;

      SendMessage(hWnd, WM_VSCROLL, SB_LINEUP, 0L);

      GetCursorPos(&aPoint); ScreenToClient(hWnd, &aPoint);
      if (twi->LButtonDown && (INT)aPoint.y < (INT)rClient.top) {
	MSG msg;
	if (!PeekMessage(&msg,hWnd,0,0,PM_NOREMOVE))
	  PostMessage(hWnd, WM_MOUSEMOVE, MK_LBUTTON, MAKELPARAM((WORD)aPoint.x,(WORD)aPoint.y));
      }
    }
    else if (yPos > (INT)rClient.bottom-2*VINDENT) {
      yPos = (INT)rClient.bottom-2*VINDENT-1;

		SendMessage(hWnd, WM_VSCROLL, SB_LINEDOWN, 0L);

      GetCursorPos(&aPoint); ScreenToClient(hWnd, &aPoint);
      if (twi->LButtonDown && (INT)aPoint.y > (INT)rClient.bottom-2*VINDENT) {
	MSG msg;
	if (!PeekMessage(&msg,hWnd,0,0,PM_NOREMOVE))
	  PostMessage(hWnd, WM_MOUSEMOVE, MK_LBUTTON, MAKELPARAM((WORD)aPoint.x,(WORD)aPoint.y));
      }
    }


    Col = AsCol(xPos);
    Row = AsRow(yPos);
    BaseScreen = (FPOINTER) GlobalLock(twi->ScrBuffer);

    ScreenPosIni = GetScreenPos(BaseScreen, twi->pBaseSel.x, twi->pBaseSel.y);
    ScreenPosEnd = GetScreenPos(BaseScreen, Col, Row);

    if (ScreenPosIni < ScreenPosEnd) {

      ScreenPosIni = GetScreenPos(BaseScreen, twi->rSelected.right, twi->rSelected.bottom);
      ScreenPosEnd = GetScreenPos(BaseScreen, Col, Row);

      if (ScreenPosIni < ScreenPosEnd) {
	/* Selected rectangle has grown downwards */
	aRect.top  = twi->rSelected.top;
	aRect.left = twi->rSelected.left;
	aRect.bottom  = twi->pBaseSel.y;
	aRect.right = twi->pBaseSel.x-1;

	PutTextRegion(!IN_WM_PAINT, hWnd, aRect);

	aRect.top  = twi->rSelected.bottom;
	aRect.left = twi->rSelected.right;
	aRect.bottom  = Row;
	aRect.right = Col;
	PutTextSelectedRegion(hWnd, aRect);

	twi->rSelected.top = twi->pBaseSel.y;
	twi->rSelected.left = twi->pBaseSel.x;
	twi->rSelected.bottom  = Row;
	twi->rSelected.right = Col;
		}
      else if (ScreenPosIni > ScreenPosEnd) {
	/* Selected rectangle has shrinked upwards */
	aRect.top  = Row;
	aRect.left = Col;
	aRect.bottom  = twi->rSelected.bottom;
	aRect.right = twi->rSelected.right;
	PutTextRegion(!IN_WM_PAINT, hWnd, aRect);

	twi->rSelected.bottom  = Row;
	twi->rSelected.right = Col;
	twi->rSelected.top = twi->pBaseSel.y;
	twi->rSelected.left = twi->pBaseSel.x;
      }
	 }
    else {
      ScreenPosIni = GetScreenPos(BaseScreen, twi->rSelected.left, twi->rSelected.top);
      ScreenPosEnd = GetScreenPos(BaseScreen, Col, Row);

      if (ScreenPosIni < ScreenPosEnd) {
	/* Selected rectangle has shrinked upwards */
	aRect.top  = twi->rSelected.top;
	aRect.left = twi->rSelected.left;
	aRect.bottom  = Row;
	aRect.right = Col;

	twi->rSelected.top  = Row;
	twi->rSelected.left = Col;
	twi->rSelected.bottom = twi->pBaseSel.y;
	twi->rSelected.right = twi->pBaseSel.x;

	PutTextRegion(!IN_WM_PAINT, hWnd, aRect);
      }
      else if (ScreenPosIni > ScreenPosEnd) {

	/* Selected rectangle has grown upwards */
	if (twi->pBaseSel.x == (LONG)twi->Cols) {
	  aRect.top  = twi->pBaseSel.y+1;
	  aRect.left = 1;
	}
	else {
	  aRect.top  = twi->pBaseSel.y;
	  aRect.left = twi->pBaseSel.x+1;
	}
	aRect.bottom  = twi->rSelected.bottom;
	aRect.right = twi->rSelected.right;
	PutTextRegion (!IN_WM_PAINT, hWnd, aRect);

	aRect.top  = Row;
	aRect.left = Col;
	aRect.bottom  = twi->rSelected.top;
	aRect.right = twi->rSelected.left;
	PutTextSelectedRegion(hWnd, aRect);

	twi->rSelected.top  = Row;
	twi->rSelected.left = Col;
	twi->rSelected.bottom = twi->pBaseSel.y;
	twi->rSelected.right = twi->pBaseSel.x;
      }
    }
  }
}


static VOID DoLButtonUp (HWND hWnd, UINT message, WPARAM wParam, LPARAM lParam)
{
  TEXTWINDOWINFO  *twi;
  INT		   xPos, yPos, Col, Row;

  twi = (TEXTWINDOWINFO*) GetWindowLong(hWnd, 0);

  twi->LButtonDown = FALSE;

  xPos = LOWORD(lParam);
  yPos = HIWORD(lParam);

  Col = AsCol(xPos);
  Row = AsRow(yPos);

  /* End selection */
  if (twi->Selecting) {

    twi->Selecting = FALSE;
    twi->Selected = TRUE;

    ReleaseCapture();

    /* Restore caret */
    WinSetcursor(hWnd, twi->svCursorStatus);
    
  }

  /* Let change cursor position by clicking with cursor in Edit line */
  if (twi->InEdit) {

    FPOINTER InitPos, Pos;

    InitPos = (FPOINTER) GetScreenPos(0, twi->EdLeft, twi->EdTop);
    Pos = (FPOINTER) GetScreenPos(0, Col, Row);

    if (Pos >= InitPos && Pos-InitPos<=strlen((const char *)twi->EdStr)) {
      MoveCursor(hWnd, (INT)(Pos-InitPos-twi->EdPos));
      twi->EdPos = (INT) (Pos-InitPos);
    }
  }
}

static VOID DoRButtonDown (HWND hWnd, UINT message, WPARAM wParam, LPARAM lParam)
{
  POINT		 ptCurrent;
  HMENU		 hMenu;

  ptCurrent.x = LOWORD(lParam);
  ptCurrent.y = HIWORD(lParam);
  ClientToScreen (hWnd, &ptCurrent);

  hMenu = CreatePopupMenu();
  AppendMenu (hMenu, MF_ENABLED|MF_STRING, ID_EVAL,  "&Evaluate");
  AppendMenu (hMenu, MF_ENABLED|MF_STRING, ID_INFO,  "&Info");
  AppendMenu (hMenu, MF_ENABLED|MF_STRING, ID_FIND,  "&Find");
  AppendMenu (hMenu, MF_ENABLED|MF_STRING, ID_TYPE,  "&Type");
  AppendMenu (hMenu, MF_SEPARATOR,         0, NULL);
  AppendMenu (hMenu, MF_ENABLED|MF_STRING, ID_CUT,   "Cu&t");
  AppendMenu (hMenu, MF_ENABLED|MF_STRING, ID_COPY,  "&Copy");
  AppendMenu (hMenu, MF_ENABLED|MF_STRING, ID_PASTE, "&Paste");
  AppendMenu (hMenu, MF_ENABLED|MF_STRING, ID_CLEAR, "C&lear");
  AppendMenu (hMenu, MF_SEPARATOR,         0, NULL);
  AppendMenu (hMenu, MF_ENABLED|MF_STRING, ID_OPENSELECTED, "&Load file");
  AppendMenu (hMenu, MF_ENABLED|MF_STRING, ID_EDITSELECTED, "E&dit file");

  TrackPopupMenu (hMenu, TPM_LEFTALIGN|TPM_LEFTBUTTON|TPM_RIGHTBUTTON,
		  ptCurrent.x, ptCurrent.y, 0, GetParent(hWnd), NULL);

  DestroyMenu(hMenu);
}


static VOID DoCopy (HWND hWnd, UINT message, WPARAM wParam, LPARAM lParam)
{
  TEXTWINDOWINFO *twi;
  HGLOBAL	hData;
  INT		Size, i;
  UINT		Col;
  FPOINTER	BaseScreen, Screen, Data;

  twi = (TEXTWINDOWINFO*) GetWindowLong(hWnd, 0);

  if (twi->Selected) {
    if (!(BaseScreen = (FPOINTER)GlobalLock(twi->ScrBuffer)))
      return;

    Size = (INT) (GetScreenPos(BaseScreen, twi->rSelected.right, twi->rSelected.bottom) -
		  GetScreenPos(BaseScreen, twi->rSelected.left, twi->rSelected.top))
		  +1;

    if (!(hData = GlobalAlloc(GMEM_MOVEABLE, Size+1+2*(twi->rSelected.bottom-twi->rSelected.top)))) {
      GlobalUnlock(twi->ScrBuffer);
      return;
    }

    Screen = GetScreenPos(BaseScreen, twi->rSelected.left, twi->rSelected.top);

    if (!(Data = (FPOINTER)GlobalLock(hData))) {
      GlobalUnlock(twi->ScrBuffer);
      return;
    }

    for(i=0, Col=twi->rSelected.left; i<Size; i++, Col++) {
      if (Col > twi->Cols) {

	/* Erase final white spaces in line */
	while (Data[-1] == ' ')
	  Data--;

	*Data = '\r';
	Data++;
	*Data = '\n';
	Data++;
	Col = 1;
		}
      *Data = *Screen;
      Data++;
      Screen++;
    }
    *Data = '\0';

    GlobalUnlock(hData);
    GlobalUnlock(twi->ScrBuffer);

    if (OpenClipboard(hWnd)) {
      EmptyClipboard();
      SetClipboardData(CF_TEXT, hData);
      CloseClipboard();

      UnSelect(hWnd);
    }
  }
}

static VOID DoPaste (HWND hWnd, UINT message, WPARAM wParam, LPARAM lParam)
{
  TEXTWINDOWINFO *twi;

  twi = (TEXTWINDOWINFO*) GetWindowLong(hWnd, 0);

  if (OpenClipboard(hWnd) && twi->InEdit) {

    HGLOBAL	hClipData;
    FPOINTER    ClipData, p, BufferEd;
    INT		SizeClip, dest;
    INT		i, j;

	 BufferEd = twi->EdStr;

    if (!(hClipData = GetClipboardData(CF_TEXT))) {
      CloseClipboard();
      return;
    }

    if (!(ClipData = (unsigned char HUGE *)GlobalLock(hClipData))) {
      CloseClipboard();
      return;
    }

    /* Lenght of string to insert */
    for(p=ClipData, SizeClip=0; *p; p++) {
      if (*p != '\n')
	SizeClip++;
    }

    /* Shift from cursor to end before inserting */
    dest = twi->EdPos+SizeClip;
	 if (dest < EDIT_BUFFER_MAX_LENGTH) {
      i = min(twi->EdLength+SizeClip, EDIT_BUFFER_MAX_LENGTH-1);
      BufferEd[i+1] = '\0';
      while(i-SizeClip >= twi->EdPos) {
	BufferEd[i] = BufferEd[i-SizeClip];
	i--;
		}
    }
    else {
      BufferEd[EDIT_BUFFER_MAX_LENGTH] = '\0';
    }

    /* Insert string */
    for(i=twi->EdPos, j=0; i<EDIT_BUFFER_MAX_LENGTH && ClipData[j]; i++, j++) {
      if (ClipData[j] == '\r') {
	j++;
	BufferEd[i] = ' ';
      }
      else {
	BufferEd[i] = ClipData[j];
		}
    }

    /* Print edit line and place cursor */
    MoveCursor (hWnd, -twi->EdPos);
    WinPuts(hWnd, (CHAR *)BufferEd);

    twi->EdLength = strlen((const char *)BufferEd);
    MoveCursor(hWnd, -(INT)twi->EdLength+twi->EdPos);

    GlobalUnlock(hClipData);
    CloseClipboard();
  }
}


static VOID DoCutClear (HWND hWnd, UINT message, WPARAM wParam, LPARAM lParam)
{
  TEXTWINDOWINFO *twi;
  FPOINTER        InitEdPos, FinalEdPos, InitSelPos, FinalSelPos;
  INT	          FirstCharToDelete, LastCharToDelete, i;
  FPOINTER        BufferEd;

  twi = (TEXTWINDOWINFO*) GetWindowLong(hWnd, 0);

  if (twi->Selected && twi->InEdit) {

    InitEdPos = (FPOINTER) GetScreenPos(0, twi->EdLeft, twi->EdTop);
    FinalEdPos = (FPOINTER) InitEdPos+twi->EdLength-1;

    InitSelPos = (FPOINTER) GetScreenPos(0, twi->rSelected.left, twi->rSelected.top);
    FinalSelPos = (FPOINTER) GetScreenPos(0, twi->rSelected.right, twi->rSelected.bottom);

    /* Check if selected text is in edit line */
    if (InitSelPos >= InitEdPos && FinalSelPos <= FinalEdPos) {

      if (message == WM_CUT) {
	SendMessage(hWnd, WM_COPY, 0, 0L);
      }

      /* Cut selected text from edit line */
      FirstCharToDelete = (INT) (InitSelPos-InitEdPos);
      LastCharToDelete = (INT) (FinalSelPos-InitEdPos);

      BufferEd = twi->EdStr;

      for(i=LastCharToDelete+1; BufferEd[i-1]; i++)
	BufferEd[i-(LastCharToDelete-FirstCharToDelete+1)] = BufferEd[i];

      MoveCursor(hWnd, -twi->EdPos);
      WinPuts(hWnd, (CHAR *)BufferEd);

      for(i=FirstCharToDelete; i<=LastCharToDelete; i++)
	WinPutchar(hWnd, ' ');

      /* Place cursor */
      if (twi->EdPos > FirstCharToDelete) {
	twi->EdPos -= (LastCharToDelete-FirstCharToDelete);
      }

      MoveCursor(hWnd, -(INT)twi->EdLength+twi->EdPos);

      twi->EdLength = strlen((const char *)BufferEd);

      UnSelect(hWnd);
	 }
  }
}

static BOOL DoCanCopy (HWND hWnd, UINT message, WPARAM wParam, LPARAM lParam)
{
  TEXTWINDOWINFO *twi;

  twi = (TEXTWINDOWINFO*) GetWindowLong(hWnd, 0);

  return twi->Selected;

}

static BOOL DoCanCut (HWND hWnd, UINT message, WPARAM wParam, LPARAM lParam)
{
  TEXTWINDOWINFO *twi;

  twi = (TEXTWINDOWINFO*) GetWindowLong(hWnd, 0);

  if (twi->Selected && twi->InEdit) {
    FPOINTER  InitEdPos, FinalEdPos, InitSelPos, FinalSelPos;

    InitEdPos = (FPOINTER) GetScreenPos(0, twi->EdLeft, twi->EdTop);
    FinalEdPos = (FPOINTER) InitEdPos+twi->EdLength-1;

    InitSelPos = (FPOINTER) GetScreenPos(0, twi->rSelected.left, twi->rSelected.top);
    FinalSelPos = (FPOINTER) GetScreenPos(0, twi->rSelected.right, twi->rSelected.bottom);

    /* Check if selected text is in edit line */
    return (InitSelPos >= InitEdPos && FinalSelPos <= FinalEdPos);

  }
  else {
    return FALSE;
  }
}

static BOOL DoCanPaste (HWND hWnd, UINT message, WPARAM wParam, LPARAM lParam)
{
  BOOL		 CanPaste;

  if (OpenClipboard(hWnd)) {
    CanPaste = IsClipboardFormatAvailable(CF_TEXT) ||
	       IsClipboardFormatAvailable(CF_OEMTEXT);
    CloseClipboard();
  }

  return CanPaste;
}

static BOOL DoCanClear (HWND hWnd, UINT message, WPARAM wParam, LPARAM lParam)
{
  return DoCanCut (hWnd, message, wParam, lParam);
}

static VOID DoGetInputBuffer (HWND hWnd, UINT message, WPARAM wParam, LPARAM lParam)
{
  UINT  i, nMaxChars;
  LPSTR src, dest;
  TEXTWINDOWINFO *twi;

  twi = (TEXTWINDOWINFO*) GetWindowLong(hWnd, 0);
  nMaxChars = (UINT) wParam;
  dest = (LPSTR) lParam;


  src = (FPOINTER)GlobalLock(twi->hBufferEd);
  for (i=0; i<EDIT_BUFFER_MAX_LENGTH && i<nMaxChars-1 && src[i]; i++)
    dest[i] = src[i];

  dest[i] = (CHAR) 0;

  GlobalUnlock(twi->hBufferEd);
}

static VOID DoSetInputBuffer (HWND hWnd, UINT message, WPARAM wParam, LPARAM lParam)
{
  UINT  i;
  LPSTR dest, src = (LPSTR) lParam;
  TEXTWINDOWINFO *twi;

  twi = (TEXTWINDOWINFO*) GetWindowLong(hWnd, 0);

  dest = (FPOINTER)GlobalLock(twi->hBufferEd);
  for (i=0; i<EDIT_BUFFER_MAX_LENGTH && src[i]; i++)
    dest[i] = src[i];

  dest[i] = (CHAR) 0;

  GlobalUnlock(twi->hBufferEd);
  twi->IoInx = 0;
}

static VOID DoSetBufferPos (HWND hWnd, UINT message, WPARAM wParam, LPARAM lParam)
{
  TEXTWINDOWINFO *twi;

  twi = (TEXTWINDOWINFO*) GetWindowLong(hWnd, 0);
  twi->IoInx = (INT) lParam;
}

static INT DoGetBufferPos (HWND hWnd, UINT message, WPARAM wParam, LPARAM lParam)
{
  TEXTWINDOWINFO *twi;

  twi = (TEXTWINDOWINFO*) GetWindowLong(hWnd, 0);
  return twi->IoInx;
}

static LOGFONT *DoGetLogFont (HWND hWnd, UINT message, WPARAM wParam, LPARAM lParam)
{
  TEXTWINDOWINFO *twi;

  twi = (TEXTWINDOWINFO*) GetWindowLong(hWnd, 0);
  return &(twi->LogFont);
}


static TEXTMETRIC *DoGetTextMetric (HWND hWnd, UINT message, WPARAM wParam, LPARAM lParam)
{
  TEXTWINDOWINFO *twi;

  twi = (TEXTWINDOWINFO*) GetWindowLong(hWnd, 0);
  return &(twi->TextMetric);
}


static BOOL DoSetCursorStatus (HWND hWnd, UINT message, WPARAM wParam, LPARAM lParam)
{
  TEXTWINDOWINFO  *twi;
  BOOL OldState, NewState;

  NewState = (BOOL) wParam;

  twi = (TEXTWINDOWINFO*) GetWindowLong(hWnd, 0);

  OldState          = twi->CursorStatus;
  twi->CursorStatus = NewState;

  if (NewState) {
    ForceShowCaret(hWnd);
  }
  else {
    ForceHideCaret(hWnd);
  }

  return OldState;
}


static VOID DoGotoxy (HWND hWnd, UINT message, WPARAM wParam, LPARAM lParam)
{
 TEXTWINDOWINFO  *twi;
 POINT *p;
 UINT x, y;

 twi = (TEXTWINDOWINFO*) GetWindowLong(hWnd, 0);
 p   = (POINT*) wParam;
 x = (UINT) p->x;
 y = (UINT) p->y;

 ForceMoveCaret(hWnd, x, y);

}

LRESULT CALLBACK TextWndProc(HWND hWnd, UINT message, WPARAM wParam, LPARAM lParam)
{
  switch (message)
  {
     case WM_SYSCOLORCHANGE:
			  GetSysColors();
			  return 0;

     case WM_CREATE:      return DoCreate (hWnd, message, wParam, lParam);

     case WM_DESTROY:     DoDestroy (hWnd, message, wParam, lParam);
			  break;

     case WM_PAINT:       DoPaint (hWnd, message, wParam, lParam);
			  break;

     case WM_SETFOCUS:    DoSetFocus (hWnd, message, wParam, lParam);
			  break;

     case WM_KILLFOCUS:   DoKillFocus (hWnd, message, wParam, lParam);
			  break;

     case WM_KEYDOWN:     return DoKeyDown (hWnd, message, wParam, lParam);

     case WM_KEYUP:       return DoKeyUp (hWnd, message, wParam, lParam);

     case WM_CHAR:	  return DoChar (hWnd, message, wParam, lParam);

     case WM_SIZE:        DoSize (hWnd, message, wParam, lParam);
			  break;

     case WM_HSCROLL:     DoHScroll (hWnd, message, wParam, lParam);
			  break;

     case WM_VSCROLL:     DoVScroll (hWnd, message, wParam, lParam);
			  break;

     case WM_LBUTTONDOWN: DoLButtonDown (hWnd, message, wParam, lParam);
			  break;

     case WM_MOUSEMOVE:   DoMouseMove (hWnd, message, wParam, lParam);
			  break;

     case WM_LBUTTONUP:   DoLButtonUp (hWnd, message, wParam, lParam);
			  break;

     case WM_RBUTTONDOWN: DoRButtonDown (hWnd, message, wParam, lParam);
			  break;

     case WM_COPY:        DoCopy (hWnd, message, wParam, lParam);
			  break;

     case WM_PASTE:       DoPaste (hWnd, message, wParam, lParam);
			  break;

     case WM_CUT:
     case WM_CLEAR:       DoCutClear (hWnd, message, wParam, lParam);
			  break;

     case WM_CANCOPY:     return DoCanCopy (hWnd, message, wParam, lParam);


     case WM_CANPASTE:    return DoCanPaste (hWnd, message, wParam, lParam);


     case WM_CANCLEAR:    return DoCanClear (hWnd, message, wParam, lParam);

     case WM_CANCUT:      return DoCanCut (hWnd, message, wParam, lParam);

     case WM_GETINPUTBUFFER:
			  DoGetInputBuffer (hWnd, message, wParam, lParam);
			  break;

     case WM_SETINPUTBUFFER:
			  DoSetInputBuffer (hWnd, message, wParam, lParam);
			  break;

     case WM_SETBUFFERPOS:
			  DoSetBufferPos (hWnd, message, wParam, lParam);
			  break;

     case WM_GETBUFFERPOS:
			  return (LRESULT) DoGetBufferPos (hWnd, message, wParam, lParam);

     case WM_GETLOGFONT:
			  return (LRESULT) DoGetLogFont (hWnd, message, wParam, lParam);

     case WM_SETTEXTFONT:
			  CreateTextFont(hWnd, (LOGFONT*)wParam,(INT)lParam);
			  break;

     case WM_SETCURSORSTATUS:
			  return (LRESULT) DoSetCursorStatus (hWnd, message, wParam, lParam);

     case WM_GOTOXY:      DoGotoxy (hWnd, message, wParam, lParam);
			  break;

     case WM_GETTEXTMETRIC:
			  return (LRESULT) DoGetTextMetric (hWnd, message, wParam, lParam);

     default:	       	  return(DefWindowProc(hWnd, message, wParam, lParam));
  }
  return(1L);
}


/* Returns a pointer to the text currently selected in the Window */
CHAR *GetSelectedText (HWND hWnd)
{
  #define  MAXSIZE	(10*1024)
  static UCHAR    Buffer[MAXSIZE];
  FPOINTER        InitSelPos, FinalSelPos, BaseScreen;
  INT             i;
  TEXTWINDOWINFO *twi;

  twi = (TEXTWINDOWINFO*) GetWindowLong(hWnd, 0);

  if (!DoCanCopy(hWnd, 0, 0, 0L))
    return NULL;

  /* Copy selected text to buffer */
  BaseScreen = (FPOINTER) GlobalLock(twi->ScrBuffer);
  InitSelPos = (FPOINTER) GetScreenPos(BaseScreen, twi->rSelected.left, twi->rSelected.top);
  FinalSelPos = (FPOINTER) GetScreenPos(BaseScreen, twi->rSelected.right, twi->rSelected.bottom);

  for (i=0; i<MAXSIZE-1 && &InitSelPos[i]<=FinalSelPos; ++i) {
    Buffer[i] = InitSelPos[i];
  }
  Buffer[i] = (UCHAR) 0;
  GlobalUnlock(twi->ScrBuffer);

  return (CHAR *) Buffer;
}


static VOID UnSelect(HWND hWnd)
{
  TEXTWINDOWINFO  *twi;
  RECT		  rInvalidate;

  twi = (TEXTWINDOWINFO*) GetWindowLong(hWnd, 0);

  if (twi->Selected) {

   rInvalidate.top = 0;
   rInvalidate.bottom = VINDENT;
   rInvalidate.left = 0;
   rInvalidate.right = 2*HINDENT+(INT)twi->CharWidth*(INT)twi->Cols;
   InvalidateRect(hWnd, &rInvalidate, TRUE);

   rInvalidate.top = (INT)twi->CharHeight*(twi->rSelected.top-1-(INT)twi->VScroll)+VINDENT;
   rInvalidate.left = (INT)twi->CharWidth*(-(INT)twi->HScroll)+HINDENT;
   rInvalidate.bottom = (INT)twi->CharHeight*(twi->rSelected.bottom-(INT)twi->VScroll)+VINDENT;
   rInvalidate.right = (INT)twi->CharWidth*((INT)twi->Cols-(INT)twi->HScroll)+HINDENT;

   InvalidateRect(hWnd, &rInvalidate, FALSE);
   UpdateWindow(hWnd);

   twi->Selected = FALSE;

  }
}


/*---------------------------------------------------------------------------
 * Interprete an ANSI sequence:
 *-------------------------------------------------------------------------*/
#define ESCAPE  27
static CHAR *Ansi(HWND hWnd, CHAR *str)
{
  CHAR 	         *p = str;
  INT 		  nums[20], numscnt=0;
  TEXTWINDOWINFO *twi;

  /* Check if it is an ANSI sequence */
  if (*p != '[') {
    WinPutchar(hWnd, '\27');
    return str;
  }

  twi = (TEXTWINDOWINFO*) GetWindowLong(hWnd, 0);

  p++; /* pass '[' */

  if (isdigit(*p)) {
    another:
      sscanf (p, "%d", &nums[numscnt++]);
      while(isdigit(*p)) p++; /* pass number readed */
      if (*p == ';') {
	p++;
	goto another;
      }
  }
  else {
    nums[0] = 1;
    nums[1] = 1;
  }


  switch (*p) {
    case 'A': WinGotoxy(hWnd, WinWherex(hWnd), WinWherey(hWnd)-nums[0]);
	      break;

    case 'B': WinGotoxy(hWnd, WinWherex(hWnd), WinWherey(hWnd)+nums[0]);
	      break;

    case 'C': WinGotoxy(hWnd, WinWherex(hWnd)+nums[0], WinWherey(hWnd)+nums[0]);
	      break;

    case 'D': WinGotoxy(hWnd, WinWherex(hWnd)-nums[0], WinWherey(hWnd)+nums[0]);
	      break;

    case 'f':
    case 'H': WinGotoxy(hWnd, nums[1], nums[0]);
	      break;

    case 'J': if (nums[0] == 2) {
		WinClrscr(hWnd);
		WinGotoxy(hWnd, 1, 1);
	      }
	      break;


   case 'K':  WinClreol(hWnd);
	      break;


   case 'R': WinGotoxy(hWnd, nums[1], nums[0]);
	     twi->AnsiSavex = WinWherex(hWnd);
	     twi->AnsiSavey = WinWherey(hWnd);
	     break;

   case 's': twi->AnsiSavex = WinWherex(hWnd);
	     twi->AnsiSavey = WinWherey(hWnd);
	     break;

   case 'u': WinGotoxy(hWnd, twi->AnsiSavex, twi->AnsiSavey);
	     break;

   case 'm': {
	       int i;

	       if (!numscnt) {
		 nums[0] = 0;
		 numscnt++;
	       }

	       for(i=0; i<numscnt; i++) {
		 switch (nums[i]) {
		   case 0: WinTextcolor(hWnd, BLACK);
			   WinTextbackground(hWnd, WHITE);
			   WinTextbright(hWnd, FALSE);
			   break;

		   case 1:
		   case 2: WinTextbright(hWnd, FALSE);
			   break;

		   case 5:
		   case 6: WinTextbright(hWnd, TRUE);
			   break;

		   case 7: {
			     int back, fore;

			     back = twi->TextBackAttr;
			     fore  = twi->TextAttr;

			     twi->TextBackAttr = fore;
			     twi->TextAttr = back;

			   }
			   break;

		   case 30: WinTextcolor(hWnd,BLACK);
			    break;
		   case 31: WinTextcolor(hWnd,RED);
			    break;
		   case 32: WinTextcolor(hWnd,GREEN);
			    break;
		   case 33: WinTextcolor(hWnd,YELLOW);
			    break;
		   case 34: WinTextcolor(hWnd,BLUE);
			    break;
		   case 35: WinTextcolor(hWnd,MAGENTA);
			    break;
		   case 36: WinTextcolor(hWnd,CYAN);
			    break;
		   case 37: WinTextcolor(hWnd,WHITE);
			    break;
		   case 40: WinTextbackground(hWnd,BLACK);
			    break;
		   case 41: WinTextbackground(hWnd,RED);
			    break;
		   case 42: WinTextbackground(hWnd,GREEN);
			    break;
		   case 43: WinTextbackground(hWnd,YELLOW);
			    break;
		   case 44: WinTextbackground(hWnd,BLUE);
			    break;
		   case 45: WinTextbackground(hWnd,MAGENTA);
			    break;
		   case 46: WinTextbackground(hWnd,CYAN);
			    break;
		   case 47: WinTextbackground(hWnd,WHITE);
			    break;
		 }
	       }
	       break;
	     }
  }
  return p;
}



/*---------------------------------------------------------------------------
 * Write chars or string to the window:
 *-------------------------------------------------------------------------*/

/* print a string */
INT WinPuts (HWND hWnd, CHAR *str)
{
  INT n;

  for (n=0; str[n]; n++)
    WinPutchar (hWnd, str[n]);

  return n;
}

/* print a character to screen */
INT WinPutchar (HWND hWnd, CHAR c)
{
  TEXTWINDOWINFO  *twi;
  FPOINTER        Screen, BaseScreen, ScreenAttr;
  FPOINTER        dest, source, lastline;
  UINT 		  nLinesScrolled=0, NewPosX, NewPosY;
  UCHAR		  Attr;
  CHAR 		 *p;
  HDC		  hDC;
  HFONT		  hSaveFont;
  PAINTSTRUCT     ps;
  BOOL		  saveCurs;

  #define ScrollUp    { dest = BaseScreen;               				\
											\
			lastline = dest + (twi->Rows-1)*twi->Cols;      		\
											\
			source = dest + twi->Cols;                      		\
			MyMemMove(dest, source, ((ULONG)(twi->Rows-1)*twi->Cols));	\
			MyMemSet(lastline, ' ', (ULONG)twi->Cols);			\
											\
			dest = BaseScreen + (twi->Rows*twi->Cols);			\
			lastline = dest + (twi->Rows-1)*twi->Cols;			\
											\
			source = dest + twi->Cols;                      		\
			MyMemMove(dest, source, ((ULONG)(twi->Rows-1)*twi->Cols));	\
			MyMemSet(lastline, Attr, (ULONG)twi->Cols);			\
											\
			nLinesScrolled++;                               		\
			twi->EdTop--;							\
											\
			MyScrollWindow (hWnd, 0, -(INT)twi->CharHeight);		\
		      }

  saveCurs = WinSetcursor(hWnd, FALSE);
  twi = (TEXTWINDOWINFO*) GetWindowLong(hWnd, 0);

  /* Get current attribute for the window */
  Attr = (UCHAR) (twi->TextAttr+BACKGROUND*twi->TextBackAttr);
  if (twi->Bright)
    Attr += (UCHAR) BRIGHT;

  BaseScreen = (FPOINTER) GlobalLock(twi->ScrBuffer);

  NewPosX = twi->PosX;
  NewPosY = twi->PosY;

  Screen = GetScreenPos(BaseScreen, NewPosX, NewPosY);
  ScreenAttr = GetAttrPos(BaseScreen, NewPosX, NewPosY);

  if (twi->InAnsi) {
     twi->AnsiStr[twi->AnsiPtr++] = c;
     if (isalpha(c)) {
       twi->AnsiStr[twi->AnsiPtr] = (CHAR) 0;
       twi->AnsiPtr = 0;
       p = Ansi(hWnd, twi->AnsiStr);
       p++;
       twi->InAnsi = FALSE;
       if (*p)
	 WinPuts (hWnd, p);
     }
  }
  else if (c == ESCAPE) {
     twi->InAnsi = TRUE;
  }
  else if (c == '\b') {
     if(NewPosX > 1) {
       NewPosX--;
     }
  }
  else if (c == '\n') {
     NewPosX = 1;
     NewPosY++;

     if (NewPosY-twi->VScroll > twi->RowsShowed) {
       SendMessage(hWnd, WM_VSCROLL, SB_LINEDOWN, 0L);
     }

     if (NewPosY > twi->Rows) {
       ScrollUp;
       NewPosY--;
       UpdateWindow(hWnd);
     }
  }
  else if (c == '\t') {
     UINT i;
     for (i=0; i< TAB_SIZE - (NewPosX - 1) % TAB_SIZE; i++)
       WinPutchar(hWnd, ' ');
       
     return c;
  }
  else {
     /* Print the char */
     *ScreenAttr = Attr;
     *Screen = c;

     TextBeginPaint (!IN_WM_PAINT, hWnd, &hDC, &ps, &hSaveFont);

     TextOutput (hWnd, hDC, NewPosX-twi->HScroll, NewPosY-twi->VScroll, &c, 1, Attr);

     TextEndPaint (!IN_WM_PAINT, hWnd, &hDC, &ps, &hSaveFont);

     NewPosX++;

     /* Move cursor */
     if (NewPosX > twi->Cols) {
       NewPosX = 1;
       NewPosY++;

       if (NewPosY-twi->VScroll > twi->RowsShowed) {
	 SendMessage(hWnd, WM_VSCROLL, SB_LINEDOWN, 0L);
       }

       if (NewPosY > twi->Rows) {
	 ScrollUp;
	 NewPosY--;
	 UpdateWindow(hWnd);
       }
     }
  }

  GlobalUnlock(twi->ScrBuffer);

  WinGotoxy(hWnd, NewPosX, NewPosY);

  WinSetcursor(hWnd, saveCurs);

  return c;
}


/*---------------------------------------------------------------------------
 * Change text color:
 *-------------------------------------------------------------------------*/
INT WinTextcolor(HWND hWnd, INT Color)
{
  TEXTWINDOWINFO  *twi;
  INT OldColor; 

  twi = (TEXTWINDOWINFO*) GetWindowLong(hWnd, 0);
  OldColor = twi->TextAttr;

  twi->TextAttr = Color;
  return OldColor;
}


/*---------------------------------------------------------------------------
 * Change Background color:
 *-------------------------------------------------------------------------*/
INT WinTextbackground(HWND hWnd, INT Color)
{
  TEXTWINDOWINFO  *twi;
  INT OldColor; 

  twi = (TEXTWINDOWINFO*) GetWindowLong(hWnd, 0);
  OldColor = twi->TextBackAttr;

  twi->TextBackAttr = Color;
  return OldColor;
}


/*---------------------------------------------------------------------------
 * Set Bright:
 *-------------------------------------------------------------------------*/
BOOL WinTextbright(HWND hWnd, BOOL Status)
{
  TEXTWINDOWINFO  *twi;
  BOOL OldStatus;

  twi = (TEXTWINDOWINFO*) GetWindowLong(hWnd, 0);
  OldStatus = twi->Bright;

  twi->Bright = Status;
  return OldStatus;
}


/*---------------------------------------------------------------------------
 * Move cursor:
 *-------------------------------------------------------------------------*/

/* User threads should use WinGotoxy to move the caret */
/* Only moves the caret if position has changed        */
/* because sending a message to other thread is slow   */
VOID WinGotoxy(HWND hWnd, UINT x, UINT y)
{
  TEXTWINDOWINFO  *twi;
  POINT p;

  twi = (TEXTWINDOWINFO*) GetWindowLong(hWnd, 0);

  if ((twi->PosX != x) || (twi->PosY != y)) {
    p.x = (LONG) x;
    p.y = (LONG) y;
    SendMessage(hWnd, WM_GOTOXY, (WPARAM) &p, (LPARAM) 0);
  }
}

/* Get cursor position */
UINT WinWherex(HWND hWnd)
{
  TEXTWINDOWINFO  *twi;

  twi = (TEXTWINDOWINFO*) GetWindowLong(hWnd, 0);

  return twi->PosX;
}

UINT WinWherey(HWND hWnd)
{
  TEXTWINDOWINFO  *twi;

  twi = (TEXTWINDOWINFO*) GetWindowLong(hWnd, 0);

  return twi->PosY;
}


/* User threads should use WinSetcursor to set cursor ON/OFF */
/* Only changes the caret if state changes                   */
/* because sending a message to other thread is slow         */
BOOL WinSetcursor(HWND hWnd, BOOL NewState)
{
  TEXTWINDOWINFO  *twi;
  BOOL OldState;

  twi = (TEXTWINDOWINFO*) GetWindowLong(hWnd, 0);
  OldState = twi->CursorStatus;

  if (OldState != NewState)
    SendMessage(hWnd, WM_SETCURSORSTATUS, (WPARAM) NewState, (LPARAM) 0);

  return OldState;
}

/* User threads should use WinSetinsert to insert status ON/OFF */
/* Only changes the caret if state changes                      */
/* because sending a message to other thread is slow            */
BOOL WinSetinsert(HWND hWnd, BOOL NewState)
{
  TEXTWINDOWINFO  *twi;
  BOOL OldState;

  twi = (TEXTWINDOWINFO*) GetWindowLong(hWnd, 0);

  OldState = twi->InsertStatus;

  /* Set cursor shape */
  if (OldState != NewState) {
    twi->InsertStatus = NewState;
    SendMessage(hWnd, WM_SETCURSORSTATUS, (WPARAM) twi->CursorStatus, (LPARAM) 0);
  }

  return OldState;
}



/*---------------------------------------------------------------------------
 * True if a key is pushed:
 *-------------------------------------------------------------------------*/
BOOL WinKbhit(HWND hWnd)
{

 MSG 		  msg;
 TEXTWINDOWINFO  *twi;

 twi = (TEXTWINDOWINFO*) GetWindowLong(hWnd, 0);

 if (PeekMessage(&msg, 0, 0, 0, PM_REMOVE)) {
   if (!TranslateAccelerator(GetParent(hWnd), twi->hAccelTable, &msg)) {
     TranslateMessage(&msg);
     DispatchMessage(&msg);
   }
 }
 
 return (twi->KbdInx > 0);
}


static ONE_BUFFER_KEY GetOneBufferKey (HWND hWnd)
{
  MSG                   msg;
  ONE_BUFFER_KEY        readKey;
  TEXTWINDOWINFO       *twi;
  ONE_BUFFER_KEY far   *Kbd;
  INT		   i;

  twi = (TEXTWINDOWINFO*) GetWindowLong(hWnd, 0);


#if USE_THREADS
  otherKey:
  if (GetCurrentThreadId() != GetWindowThreadProcessId(hWnd, NULL)) {
    /* Evaluator is running this code in a different thread */
    while (!(twi->KbdInx)) {
      /* wait until main thread places a key in buffer */
      WaitForSingleObject(twi->eventKeyboardNotEmpty, INFINITE);
    }
  }
  else {
    /* main (GUI) thread is running this code */
    while ( (!(twi->KbdInx)) && GetMessage(&msg, NULL, 0, 0) ) {
      if (!TranslateAccelerator(GetParent(hWnd), twi->hAccelTable, &msg)) {
	TranslateMessage(&msg);
	DispatchMessage(&msg);
      }
    }
  }
#else
    otherKey:
    while ( (!(twi->KbdInx)) && GetMessage(&msg, NULL, 0, 0) ) {
      if (!TranslateAccelerator(GetParent(hWnd), twi->hAccelTable, &msg)) {
	TranslateMessage(&msg);
	DispatchMessage(&msg);
      }
    }
#endif  

  Kbd = (ONE_BUFFER_KEY *) GlobalLock(twi->KbdBuffer);

  readKey = Kbd[0];
  for (i=0; i<twi->KbdInx; i++)
    Kbd[i] = Kbd[i+1];
  twi->KbdInx--;

  GlobalUnlock(twi->KbdBuffer);

  /* Insert key changes cursor but can´t be read */
  if (readKey.IsExtended && readKey.KeyCode == VK_INSERT) {
    WinSetinsert(hWnd, !twi->InsertStatus);
    goto otherKey;
  }

  return readKey;
}

/* Get a key. If no one is available yields control to Windows */
TCHAR WinGetch(HWND hWnd)
{
  ONE_BUFFER_KEY readKey = GetOneBufferKey(hWnd);

  /* We could map control keys here !!! */
  return (TCHAR) readKey.KeyCode;
}


/*---------------------------------------------------------------------------
 * Clear screen with current attribute:
 *-------------------------------------------------------------------------*/
VOID WinClrscr(HWND hWnd)
{
  TEXTWINDOWINFO  	*twi;
  FPOINTER		 Screen;
  UCHAR			 Attr;

  twi = (TEXTWINDOWINFO*) GetWindowLong(hWnd, 0);

  Attr = (UCHAR)(twi->TextAttr+BACKGROUND*twi->TextBackAttr);
  if (twi->Bright)
    Attr += (UCHAR)BRIGHT;

  Screen = (FPOINTER) GlobalLock(twi->ScrBuffer);

  MyMemSet (Screen, ' ', (ULONG)(twi->Rows*twi->Cols));
  MyMemSet (Screen+(ULONG)twi->Rows*twi->Cols, BACKGROUND*WHITE+BLACK, (ULONG)(twi->Rows*twi->Cols));

  GlobalUnlock(twi->ScrBuffer);

  WinGotoxy(hWnd, 1, 1);

  InvalidateRect(hWnd, NULL, FALSE);
  UpdateWindow(hWnd);
}


/*---------------------------------------------------------------------------
 * Clear to end of current line:
 *-------------------------------------------------------------------------*/
VOID WinClreol(HWND hWnd)
{
  TEXTWINDOWINFO  	*twi;
  UINT			 i, nChars;

  twi = (TEXTWINDOWINFO*) GetWindowLong(hWnd, 0);

  nChars = twi->Cols-twi->PosX+1;
  for(i=0; i<nChars; i++)
   WinPutchar(hWnd, ' ');
}


/* Moves cursor n positions forward or backwards depending on sign of n */
static VOID MoveCursor (HWND hWnd, INT n)
{
  INT x, y, i, Width;
  TEXTWINDOWINFO  	*twi;

  twi = (TEXTWINDOWINFO*) GetWindowLong(hWnd, 0);

  Width = twi->Cols;

  x = twi->PosX;
  y = twi->PosY;

  if (n<0) {
    for (i=-n; i; i--)
      if (x > 1)
	x--;
      else {
	if (y>1) {
	  x = Width;
	  y--;
	}
      }
  }
  else {
    for (i=0; i<n; i++) {
      if (x < Width)
	x++;
      else {
	x = 1;
	y++;
      }
    }
  }

  WinGotoxy(hWnd, x, y);
}


/* --------------------------------------------------------------------------
 * Emulates Keyboard input with Edit capability
 *
 *  Standard C buffered edition plus
 *
 *  K_UP :    Get previous edit buffer
 *  K_DOWN:   Get next edit buffer
 *  K_LEFT:   Move cursor left
 *  K_RIGHT:  Move cursor right
 *  K_DELETE: Delete a char
 *  K_BACK:   Delete char at left of cursor
 *  K_INSERT: Switch Insert/Overwrite mode
 *  HOME:     Move cursor to begin of edit buffer
 *  END:      Move cursor to end of edit buffer
 *  K_RETURN: Acept current buffer as input
 * ------------------------------------------------------------------------*/

CHAR *WinGets(HWND hWnd, CHAR *s)
{
 UINT   	 j, savex, savey;
 BOOL		 iscursor;
 INT 		 PreviousBuffer = -1, k;
 TCHAR 		 Key;
 TEXTWINDOWINFO *twi;
 CHAR 		(HUGE *BufferEdPrev)[EDIT_BUFFER_MAX_LENGTH+1];
 ONE_BUFFER_KEY BufferKey;


 twi = (TEXTWINDOWINFO*) GetWindowLong(hWnd, 0);

 BufferEdPrev = (FPOINTER*) GlobalLock(twi->hBufferEdPrev);
 iscursor = WinSetcursor(hWnd, TRUE);
 twi->InEdit = TRUE;
 twi->EdStr = (FPOINTER)s;
 twi->EdLeft = WinWherex(hWnd);
 twi->EdTop  = WinWherey(hWnd);

 loop:
 twi->EdPos = 0;
 twi->EdLength = strlen((const CHAR*)s);

 WinPuts(hWnd, s);

 MoveCursor (hWnd, -(INT)twi->EdLength);

 for (;;) {

   BufferKey = GetOneBufferKey(hWnd);

   Key = BufferKey.KeyCode;

   if (BufferKey.IsExtended)

     switch (Key) {

       case VK_UP:    if (PreviousBuffer+1 < NUM_EDIT_BUFFERS) {
			PreviousBuffer++;
			MoveCursor (hWnd, -twi->EdPos);
			for (j=0; j<twi->EdLength; j++) WinPutchar(hWnd, ' ');
			MoveCursor (hWnd, -(INT)twi->EdLength);
			strcpy (s, (const CHAR *)&BufferEdPrev[PreviousBuffer][0]);
			twi->EdLength = strlen (s);
			goto loop;
		      }
		      break;

       case VK_DOWN:  if (PreviousBuffer > 0) {
			PreviousBuffer--;
			MoveCursor (hWnd, -twi->EdPos);
			for (j=0; j<twi->EdLength; j++) WinPutchar(hWnd, ' ');
			MoveCursor (hWnd, -(INT)twi->EdLength);
			strcpy (s, (const CHAR *)&BufferEdPrev[PreviousBuffer][0]);
			twi->EdLength = strlen (s);
			goto loop;
		      }
		      break;


      case VK_DELETE: if (s[twi->EdPos]) {
			for (j=twi->EdPos; j<=twi->EdLength; j++)
			  s[j] = s[j+1];

			savex = WinWherex(hWnd);
			savey = WinWherey(hWnd);

			WinPuts(hWnd, &s[twi->EdPos]);
			WinPutchar(hWnd, ' ');
			WinGotoxy(hWnd, savex, savey);
			twi->EdLength--;
		      }
		      break;

      case VK_LEFT:   if (twi->EdPos > 0) {
			MoveCursor (hWnd, -1);
			twi->EdPos--;
		      }
		      break;

      case VK_RIGHT:  if (s[twi->EdPos] && twi->EdPos < (INT)twi->EdLength) {
			MoveCursor (hWnd, +1);
			twi->EdPos++;
		      }
		      break;

      case VK_HOME:  MoveCursor(hWnd, -twi->EdPos);
		     twi->EdPos=0;
		     break;

      case VK_END:   MoveCursor(hWnd, twi->EdLength-twi->EdPos);
		     twi->EdPos = twi->EdLength;
		     break;

      case VK_PRIOR: DoVScroll (hWnd, 0, SB_PAGEUP, 0);
		     break;

      case VK_NEXT: DoVScroll (hWnd, 0, SB_PAGEDOWN, 0);
		     break;

     }
   else

     switch(Key) {

      case VK_ESCAPE:
		    MessageBeep(0xFFFFFFFF);
		    break;

      case VK_BACK: if (twi->EdLength > 0 && twi->EdPos > 0) {
		      for (j=twi->EdPos; j<=twi->EdLength; j++)
			s[j-1] = s[j];
		      MoveCursor (hWnd, -1);
		      savex = WinWherex(hWnd);
		      savey = WinWherey(hWnd);

		      WinPuts(hWnd, &s[twi->EdPos-1]);
		      WinPutchar(hWnd, ' ');
		      WinGotoxy(hWnd, savex, savey);
		      twi->EdPos--;
		      twi->EdLength--;
		    }
		    break;


      case VK_RETURN:

		    MoveCursor (hWnd, twi->EdLength-twi->EdPos+1);
		    twi->IoInx = 0;
		    GlobalUnlock(twi->hBufferEdPrev);
		    twi->InEdit = FALSE;
		    twi->EdStr = NULL;
		    WinSetcursor (hWnd, iscursor);
		    return s;


      default:      if (((twi->EdLength+1 > EDIT_BUFFER_MAX_LENGTH) && twi->InsertStatus) ||
			 (twi->EdPos == EDIT_BUFFER_MAX_LENGTH)) {
		      break;
		    }

		    if (twi->InsertStatus) {
		      for (k=EDIT_BUFFER_MAX_LENGTH; k>twi->EdPos; k--)
			s[k] = s[k-1];
		      twi->EdLength++;
		    }

		    if (s[twi->EdPos]==0) {
		      s[twi->EdPos] = Key;
		      s[twi->EdPos+1] = 0;
		      if (!(twi->InsertStatus))
			twi->EdLength++;
		    }
		    else {
		      s[twi->EdPos] = Key;
		    }

		    WinPuts(hWnd, &s[twi->EdPos]);

		    MoveCursor (hWnd, -(INT)(twi->EdLength-twi->EdPos)+1);

		    twi->EdPos++;
		    break;
     }
   } /* end for */
}



/* Read a char from a file */
INT WinGetc (HWND hWnd, FILE *fp)
{

  INT		   i, ret;
  TEXTWINDOWINFO  *twi;
  FPOINTER	   BufferEd;
  CHAR 		  (HUGE *BufferEdPrev)[EDIT_BUFFER_MAX_LENGTH+1];


  /* Check if stdin */
  if (fp != stdin)
    return fgetc(fp);

  twi = (TEXTWINDOWINFO*) GetWindowLong(hWnd, 0);

  BufferEd = (FPOINTER)GlobalLock(twi->hBufferEd);
  BufferEdPrev = (FPOINTER*) GlobalLock(twi->hBufferEdPrev);

  while (twi->IoInx < 0) { /* If BufferEd is empty fill it */

    for (i=NUM_EDIT_BUFFERS-1; i > 0; i--)
      strcpy ((CHAR *)&BufferEdPrev[i][0], (const CHAR *)&BufferEdPrev[i-1][0]);

    strcpy ((CHAR *)&BufferEdPrev[0][0], (const CHAR *)BufferEd);

    strcpy ((CHAR *)BufferEd, "");
    WinGets (hWnd, (CHAR *)BufferEd);
    WinPutchar (hWnd, '\n');
  }

  if (BufferEd[twi->IoInx] == 0) {
    twi->IoInx = -1;
    ret = '\n';
  }
  else {
    ret =  (BufferEd[(twi->IoInx)++]);
  }

  GlobalUnlock(twi->hBufferEd);
  GlobalUnlock(twi->hBufferEdPrev);

  return ret;
}


/* I use this to redirect output to stdstrbuff using             */
/* putc(stdstr, ...), fputc (stdstr, ...),  fprintf(stdstr, ...) */
#define MAX_STDSTR 1024
INT     StrInx = 0;
FILE   *stdstr = NULL;
CHAR    stdstrbuff[MAX_STDSTR];

/* print a character to a stream */
INT WinPutc(HWND hWnd, CHAR c, FILE *fp)
{
  /* Output to window */
  if (fp == stdout) {
    WinPutchar (hWnd, c);
  }
  /* Error output to window */
  else if (fp == stderr) {
    INT svColor = WinTextcolor(hWnd,RED);
    WinPutchar (hWnd, c);
    WinTextcolor(hWnd,svColor);
  }
  /* Output to string */
  else if (fp == stdstr) {
    if (c=='\n') {
      stdstrbuff[StrInx] = (CHAR) 0;
      StrInx = 0;
    }
    else
      stdstrbuff[StrInx++] = c;
  }
  /* Output to stream */
  else {
    fputc(c, fp);
  }
  return c;
}


static INT cdecl AuxWinFprintf(HWND hWnd, FILE *fp, const CHAR *format, va_list arg_ptr) {
  CHAR 		buf[2048];
  INT 		cnt, svColor;


  if (fp == stdstr) { /* Output to the string */
    cnt = vsprintf (&stdstrbuff[StrInx], format, arg_ptr);
    if (stdstrbuff[StrInx+cnt-1] == '\n') {
      stdstrbuff[StrInx+cnt-1] = 0;
      StrInx = 0;
    }
    else {
      StrInx += cnt;
    }
  } 
  else if (fp == stdout) { /* Output to the window */
    cnt = vsprintf (buf, format, arg_ptr);
    WinPuts(hWnd, buf);
  } 
  else if (fp == stderr) { /* Error output to the window */
    cnt = vsprintf (buf, format, arg_ptr);
    svColor = WinTextcolor(hWnd, RED);
    WinPuts(hWnd, buf);
    WinTextcolor(hWnd, svColor);
  } 
  else { /* Output to a stream */
    cnt = vfprintf (fp, format, arg_ptr);
  }

  return cnt;
}


/* Like fprintf for DOS, but if fp == stdout or stderr output goes to */
/* the window. If fp == stdstr output goes to the string stdstrbuff    */
INT cdecl WinFprintf(HWND hWnd, FILE *fp, const CHAR *format, ...)
{
  va_list	arg_ptr;
  INT           retVal;

  va_start (arg_ptr, format);
  retVal = AuxWinFprintf(hWnd, fp, format, arg_ptr);
  va_end (arg_ptr);

  return retVal;

}



/* Like WinFprintf but output goes to text window */
INT cdecl hWndTextFprintf (FILE *fp, const CHAR * format, ...)
{

  va_list	arg_ptr;
  INT           retVal;

  va_start (arg_ptr, format);
  retVal = AuxWinFprintf(hWndText, fp, format, arg_ptr);
  va_end (arg_ptr);

  return retVal;

}




/* Like printf for DOS but output goes to window */
INT cdecl WinPrintf(HWND hWnd, const CHAR *format, ...)
{
  CHAR 		buf[2048];
  va_list 	arg_ptr;
  INT 		cnt;

  va_start (arg_ptr, format);
  cnt = vsprintf (buf, format, arg_ptr);
  va_end (arg_ptr);

  WinPuts(hWnd, buf);

  return cnt;
}



/* Like WinPrintf but output goes to text window */
INT cdecl hWndTextPrintf (const CHAR * format, ...)
{
  CHAR 		buf[2048];
  va_list 	arg_ptr;
  INT 		cnt;

  va_start (arg_ptr, format);
  cnt = vsprintf (buf, format, arg_ptr);
  va_end (arg_ptr);

  WinPuts(hWndText, buf);

  return cnt;
}



/* --------------------------------------------------------------------------
 * Some static functions:
 * ------------------------------------------------------------------------*/

/* Move n bytes from src to dest */
static VOID MyMemMove (FPOINTER dest, FPOINTER src, ULONG n)
{
  memmove((void far *) dest, (void far *) src, (size_t) n);
/*  ULONG BytesLeft, nBytes;

  BytesLeft = n;

  do {
    nBytes = min (BytesLeft, 32767U);
    memmove((void far *) dest, (void far *) src, (size_t)nBytes);

    dest += nBytes;
    src  += nBytes;
    BytesLeft -= nBytes;
  } while (BytesLeft);
*/
}

/* Set n bytes to value at dest */
static VOID MyMemSet (FPOINTER dest, CHAR value, ULONG n)
{

 memset((void far *)dest, (int) value, (size_t) n);
/*
  FPOINTER end;

  for (end=dest+n; dest<end; dest++)
    *dest = value;
*/
}



#endif // HUGS_FOR_WINDOWS
