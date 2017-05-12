/* --------------------------------------------------------------------------
 * WinHugs.c:	José Enrique Gallardo Ruiz, Feb 1999
 *		With modifications by mpj/adr for Hugs, 1995-97
 *
 * The Hugs 98 system is Copyright (c) José Enrique Gallardo, Mark P Jones,
 * Alastair Reid, the Yale Haskell Group, and the OGI School of
 * Science & Engineering at OHSU, 1994-2003, All rights reserved.  It is
 * distributed as free software under the license in the file "License",
 * which is included in the distribution.
 *
 * This file contains functions for the MS-Windows GUI to Hugs
 * ------------------------------------------------------------------------*/

#define STRICT 1

#include <windows.h>
#include <shellapi.h>
#include <commdlg.h>
#include <time.h>
#include <stdio.h>
#include <stdlib.h>
#include <stdarg.h>
#include <setjmp.h>
#include <direct.h>
#include <ctype.h>
#include <signal.h>

#include "prelude.h"
#include "storage.h"
#include "connect.h"
#include "errors.h"
#include "machdep.h"
#include "strutil.h"
#include "script.h"
#include "opts.h"
#include "evaluator.h"

/* Hack and slash */
struct options {                        /* command line option toggles     */
    char   c;                           /* table defined in main app.      */
#if !HASKELL_98_ONLY
    int    h98;                         /* set in Haskell'98 mode?         */
#endif
    String description;
    Bool   *flag;
};

extern struct options toggle[];

#include "WinFrame.h"
#include "WinToolB.h"
#include "WinSTLN.h"
#include "WinUtils.h"


/* --------------------------------------------------------------------------
 * Local functions prototypes
 * ------------------------------------------------------------------------*/

#ifndef __WINHUGS_H
#include "WinHugs.h"
#endif


/* --------------------------------------------------------------------------
 * Nonlocal functions prototypes
 * ------------------------------------------------------------------------*/

INT APIENTRY	WinMain 		(HINSTANCE, HINSTANCE, LPSTR, INT);


/* --------------------------------------------------------------------------
 * CALLBACK functions prototypes:
 * ------------------------------------------------------------------------*/

LRESULT CALLBACK		AboutDlgProc		(HWND, UINT, WPARAM, LPARAM);
LRESULT CALLBACK		BrowseClassesDlgProc	(HWND, UINT, WPARAM, LPARAM);
LRESULT CALLBACK		BrowseTyconsDlgProc	(HWND, UINT, WPARAM, LPARAM);
LRESULT CALLBACK		BrowseNamesDlgProc	(HWND, UINT, WPARAM, LPARAM);
LRESULT CALLBACK		MainGUIWndProc		(HWND, UINT, WPARAM, LPARAM);
LRESULT CALLBACK		OptionsDlgProc		(HWND, UINT, WPARAM, LPARAM);
LRESULT CALLBACK		ClassesWndProc		(HWND, UINT, WPARAM, LPARAM);
LRESULT CALLBACK		ScriptManDlgProc	(HWND, UINT, WPARAM, LPARAM);


/* --------------------------------------------------------------------------
 * Default interpreter options
 * ------------------------------------------------------------------------*/
#define DEFAULT_ROWS		25
#define DEFAULT_COLS		80
#define DEFAULT_FONT		"Courier New"
#define DEFAULT_FONT_SIZE	9
#define DEFAULT_FONT_WEIGHT	FW_NORMAL
#define DEFAULT_DIALOGFONT	"MS Sans Serif"
#define DEFAULT_DIALOGFONT_SIZE 8
#define DEFAULT_PROMPT		"%s> "
#define DEFAULT_REPEATSTR	"$$"
#define DEFAULT_PREPROCESSOR	""
#define DEFAULT_DOC_DIR 	"{Hugs}\\docs"
#define HASKELL_REPORT		"report\\index.html"
#define HASKELL_LIBS		"library\\index.html"
#define HASKELL_GENTLE		"tutorial\\index.html"
#define HUGS_EXTS		"libs\\libs.html"
#define HUGS_DOCS		"hugsman\\index.html"
#define HASKELL_ORG		"http:\\\\haskell.org"
#define HUGS_HELP_FILE          "hugs.hlp"

/* --------------------------------------------------------------------------
 * Local Macros:
 * ------------------------------------------------------------------------*/

#define DlgSendMessage(h,c,w,l)  SendMessage((h),(c),MAKEWPARAM(w,(HIWORD(l))),(LOWORD(l)))
#define AbortInterpreter	 input(BREAK); WinPuts(hWndText, "\n")
#define GotoInterpreter 	 longjmp(catch_error, 1);

/* --------------------------------------------------------------------------
 * Local Variables:
 * ------------------------------------------------------------------------*/
#if DOS
	String appName = "Hugs for Windows";	/* Text for application name		*/
#else
	String appName = "Hugs for Windows 32"; /* Text for application name		*/
#endif

	HANDLE		hThisInstance;		/* Windows instance for the application */
	HWND		hWndMain    = NULL;	/* Main Window handle			*/
	HWND		hWndText    = NULL;	/* Hugs Text Window handle		*/
	HWND		hWndClasses = NULL;	/* Classes Hierarchy Window handle	*/

static	HANDLE		hAccelTable;		/* Accelerators table			*/
	HCURSOR 	GarbageCursor  = NULL;	/* GC mouse cursor			*/
	HCURSOR 	SaveCursor     = NULL;	/* Used to save current cursor		*/
static	INT		FrameWinWidth  = 0,
			FrameWinHeight = 0;	/* Size of Main Window			*/
static	INT		FrameWinX, FrameWinY;	/* Pos of Main Window in Screen 	*/
static	INT		ScreenRows     = 0,
			ScreenCols     = 0;	/* Text Window size in chars		*/
static	WNDPROC 	PrevWndProc;		/* Window Proc of Frame class		*/
static	CHAR		**hugs_argv;		/* Command line args			*/
static	INT		hugs_argc;
static	HFONT		hDialogFont = NULL;	/* Font to use in Dialogs		*/

#include "menusbm.c"

/* --------------------------------------------------------------------------
 * Browse dialogs and classes hierarchy:
 * ------------------------------------------------------------------------*/

#include "WinBrows.c"


/* --------------------------------------------------------------------------
 * Responses to messages:
 * ------------------------------------------------------------------------*/


/* About Hugs ... */
static VOID local DoAbout(HWND hWnd, UINT msg, WPARAM wParam, LPARAM lParam)
{
  ExecDialog(hThisInstance, ABOUTDLGBOX, AboutDlgProc);
}


/* Browse Classes ... */
static VOID local DoBrowseClasses(HWND hWnd, UINT msg, WPARAM wParam, LPARAM lParam)
{
  ExecDialog(hThisInstance, BROWSECLASSESDLGBOX, BrowseClassesDlgProc);
}

static VOID local 
SelectFont(HWND hWnd)
{
    CHOOSEFONT cf;
    LOGFONT* pLF;
    
    pLF = (LOGFONT*) SendMessage (hWndText, WM_GETLOGFONT, 0, 0L);

    ZeroMemory(&cf,sizeof(CHOOSEFONT));
    cf.lStructSize = sizeof(CHOOSEFONT);
    cf.hwndOwner   = hWnd;
    cf.lpLogFont   = pLF;
    cf.Flags       = CF_SCREENFONTS |
	             CF_FIXEDPITCHONLY |
 	             CF_INITTOLOGFONTSTRUCT;
    if (ChooseFont(&cf)) {
	SendMessage(hWndText, WM_SETTEXTFONT,
		    (WPARAM)pLF,
		    (LPARAM)(cf.iPointSize/10));
    }
}



/* Browse Type Constructors ... */
static VOID local DoBrowseTycons(HWND hWnd, UINT msg, WPARAM wParam, LPARAM lParam)
{
  ExecDialog(hThisInstance, BROWSETYCONSDLGBOX, BrowseTyconsDlgProc);
}


/* Browse Names ... */
static VOID local DoBrowseNames(HWND hWnd, UINT msg, WPARAM wParam, LPARAM lParam)
{
  ExecDialog(hThisInstance, BROWSENAMESDLGBOX, BrowseNamesDlgProc);
}


/* Response to Windows WM_CLOSE message */
static VOID local DoClose(HWND hWnd, UINT msg, WPARAM wParam, LPARAM lParam)
{
  SendMessage (hWnd, WM_COMMAND, ID_EXIT, 0L);
}

/* Response to Menu Commands */
static VOID local DoCommand(HWND hWnd, UINT msg, WPARAM wParam, LPARAM lParam)
{
  switch (LOWORD(wParam)) {
    /* Open text editor for new file */
    case ID_NEW:		AbortInterpreter;
				SetInterpreterCommand(":l\n:e\n");
				GotoInterpreter;
				break;
				
    /* Load a sript file from disk */
    case ID_OPEN:		{ CHAR *ScriptName;
				  CHAR Command[2048];

				  if ((ScriptName = GetaFileName(GetFocus(), IDS_FILTERFILE)) != NULL) {
				    wsprintf(Command, ":l %s\n", ExpandFileName((String)ScriptName));
				    AbortInterpreter;
				    SetInterpreterCommand(Command);
				    GotoInterpreter;
				  }
				}
				break;

    /* Enter Script Manager */
    case ID_SCRIPTMAN:		DoScriptMan(hWnd, msg, wParam, lParam);
				break;

    /* Load a sript file from disk (the name of the script is currently selected) */
    case ID_OPENSELECTED:	{ CHAR *ScriptName;
				  CHAR Command[2048];

				  ScriptName = GetSelectedText(hWndText);
				  wsprintf(Command, ":l %s\n", ExpandFileName((String)ScriptName));
				  AbortInterpreter;
				  SetInterpreterCommand(Command);
				  GotoInterpreter;
				}
				break;

    /* Exit Hugs interpreter */
    case ID_EXIT:		AbortInterpreter;
				SetInterpreterCommand(":q\n");
				GotoInterpreter;
				break;

    /* Load one of the last 10 open files */
    case ID_EXIT+1:
    case ID_EXIT+2:
    case ID_EXIT+3:
    case ID_EXIT+4:
    case ID_EXIT+5:
    case ID_EXIT+6:
    case ID_EXIT+7:
    case ID_EXIT+8:
    case ID_EXIT+9:
    case ID_EXIT+10:		{ CHAR ScriptName[_MAX_PATH];
				  CHAR Command[2048];

				  strcpy(ScriptName, GetFileNameFromFileNamesMenu(&FilesMenu, wParam-ID_EXIT-1));
				  wsprintf(Command, ":l %s\n", ExpandFileName((String)ScriptName));
				  AbortInterpreter;
				  SetInterpreterCommand(Command);
				  GotoInterpreter;
				}
				break;

    /* Clipboard copy */
    case ID_COPY:		SendMessage(hWndText, WM_COPY, 0, 0L);
				break;


    /* Clipboard paste */
    case ID_PASTE:		SendMessage(hWndText, WM_PASTE, 0, 0L);
				break;


    /* Clipboard cut */
    case ID_CUT:		SendMessage(hWndText, WM_CUT, 0, 0L);
				break;


    /* Clipboard clear */
    case ID_CLEAR:		SendMessage(hWndText, WM_CLEAR, 0, 0L);
				break;


    /* Edit previous line */
    case ID_GOPREVIOUS: 	SendMessage(hWndText, WM_KEYDOWN, (WPARAM) VK_UP, 0x1000000L);
				SendMessage(hWndText, WM_KEYUP,   (WPARAM) VK_UP, 0x1000000L);
				break;

    /* Edit next line */
    case ID_GONEXT:		SendMessage(hWndText, WM_KEYDOWN, (WPARAM) VK_DOWN, 0x1000000L);
				SendMessage(hWndText, WM_KEYUP,   (WPARAM) VK_DOWN, 0x1000000L);
				break;

    /* Change text window font */
    case ID_FONT:
        SelectFont(hWnd);
	break;
	

    /* Open text editor */
    case ID_GOEDIT:		AbortInterpreter;
				SetInterpreterCommand(":e\n");
				GotoInterpreter;
				break;


    case ID_EDITSELECTED+1:
    case ID_EDITSELECTED+2:
    case ID_EDITSELECTED+3:
    case ID_EDITSELECTED+4:
    case ID_EDITSELECTED+5:
    case ID_EDITSELECTED+6:
    case ID_EDITSELECTED+7:
    case ID_EDITSELECTED+8:
    case ID_EDITSELECTED+9:
    case ID_EDITSELECTED+10:	{ CHAR ScriptName[_MAX_PATH];
				  CHAR Command[2048];

				  strcpy(ScriptName, GetFileNameFromFileNamesMenu(&EditMenu, wParam-ID_EDITSELECTED-1));
				  wsprintf(Command, ":e %s\n", ExpandFileName((String)ScriptName));
				  AbortInterpreter;
				  SetInterpreterCommand(Command);
				  GotoInterpreter;
				}
				break;


    /* Open text editor for selected text */
    case ID_EDITSELECTED:	{ CHAR Command[2048];
				 
				  wsprintf(Command, ":e %s\n", ExpandFileName((String)GetSelectedText(hWndText)));
				  AbortInterpreter;
				  SetInterpreterCommand(Command);
				  GotoInterpreter;
				}
				break;

    /* Find definition of selected text */
    case ID_FIND:		{ String SelectedText;

				  SelectedText = GetSelectedText(hWndText);
				  AbortInterpreter;
				  SetInterpreterCommand(":f %s\n",(LPSTR)SelectedText);
				  GotoInterpreter;
				}
				break;

    /* Show type of selected text */
    case ID_TYPE:		{ String SelectedText;
				  SelectedText = GetSelectedText(hWndText);
				  AbortInterpreter;
				  SetInterpreterCommand(":t %s\n",(LPSTR)SelectedText);
				  GotoInterpreter;
				}
				break;

    /* Show info on selected text */
    case ID_INFO:		{ String SelectedText;
				  SelectedText = GetSelectedText(hWndText);
				  AbortInterpreter;
				  SetInterpreterCommand(":i %s\n",(LPSTR)SelectedText);
				  GotoInterpreter;
				}
				break;

    /* Eval selected text */
    case ID_EVAL:		{ String SelectedText;
				  SelectedText = GetSelectedText(hWndText);
				  AbortInterpreter;
				  SetInterpreterCommand("%s\n",(LPSTR)SelectedText);
				  GotoInterpreter;
				}
				break;

    /* Stop program execution */
    case ID_STOP:		MessageBeep(0xFFFFFFFF);
				raise(SIGINT);
				break;
				
    /* Evaluate main expression */
    case ID_RUN:		AbortInterpreter;
				SetInterpreterCommand("main\n");
				GotoInterpreter;
				break;

    /* Set interpreter options using dialog box */
    case ID_SETOPTIONS: 	DoOptions (hWnd, msg, wParam, lParam);
				break;


    /* Reload script files */
    case ID_COMPILE:
    case ID_MAKE:		AbortInterpreter;
				SetInterpreterCommand(":r\n");
				GotoInterpreter;
				break;

    
    /* Clear all files loaded but Prelude */
    case ID_CLEARALL:		AbortInterpreter;
				SetInterpreterCommand(":l\n");
				GotoInterpreter;
				break;

    /* Show classes hierarchy */
    case ID_BROWSEHIERARCHY:	DrawClassesHierarchy();
				break;

    /* Browse classes defined */
    case ID_BROWSECLASSES:	DoBrowseClasses(hWnd, msg, wParam, lParam);
				break;

    /* Browse names defined */
    case ID_BROWSENAMES:	DoBrowseNames(hWnd, msg, wParam, lParam);
				break;

    /* Browse type constructors defined */
    case ID_BROWSETYCONS:	DoBrowseTycons(hWnd, msg, wParam, lParam);
				break;

    
    /* Display help about using windows help */
    case ID_HELPUSE:		WinHelp(hWnd, "Winhelp.Hlp", HELP_CONTENTS, 0L);
				break;

    /* Display help about Hugs */
    case ID_HELPINDEX:		{ char  DocFullPath[_MAX_PATH];
                                  char *HelpFullPath = NULL;

				  if ( GetFromRegistryDocPath(DocFullPath, _MAX_PATH) ) {
				      HelpFullPath = alloca(strlen(DocFullPath) + strlen(HUGS_HELP_FILE) + 5);
				      if (HelpFullPath) {
					  wsprintf(HelpFullPath, "%s\\%s", DocFullPath, HUGS_HELP_FILE);
					  WinHelp(hWnd, HelpFullPath, HELP_CONTENTS, 0L);
				      }
				  }
				}
				break;

    /* Display the Haskell report */
    case ID_HELPREPORT: 	OpenHtmlFromDocs(HASKELL_REPORT);
				break;

    /* Display the Haskell lib report */
    case ID_HELPLIBS:		OpenHtmlFromDocs(HASKELL_LIBS);
				break;

    /* Display the Gentle intro */
    case ID_HELPGENTLE: 	OpenHtmlFromDocs(HASKELL_GENTLE);
				break;

    /* Go to haskell home */
    case ID_HELPHASKELLORG:	OpenHtml(HASKELL_ORG);
				break;
 
   /* Display the hugs and ghc exts */
    case ID_HELPEXTS:		OpenHtmlFromDocs(HUGS_EXTS);
				break;

    /* Display the hugs doc */
    case ID_HELPDOCS:		OpenHtmlFromDocs(HUGS_DOCS);
				break;

    /* Show hugs commands */
    case ID_HELPCOMMANDS:	AbortInterpreter;
				SetInterpreterCommand(":?\n");
				GotoInterpreter;
				break;

    /* Show Hugs copyright */
    case ID_ABOUT:		DoAbout (hWnd, msg, wParam, lParam);
				break;
  }
}


/* Response to Windows WM_CREATE message */
static INT local DoCreate(HWND hWnd, UINT msg, WPARAM wParam, LPARAM lParam)
{

  INT		DialogFontSize;
  CHAR		DialogFontName[256];

  GetFromRegistryDialogFont(DialogFontName, 256, &DialogFontSize);

  hDialogFont = CreateFont(DialogFontSize*15/9,0,0,0,
		       FW_NORMAL,
		       FALSE,
		       FALSE,
		       FALSE,
		       ANSI_CHARSET,
		       OUT_TT_PRECIS,
		       CLIP_TT_ALWAYS,
		       DEFAULT_QUALITY,
		       FIXED_PITCH | FF_MODERN,
		       DialogFontName);
  if (!hDialogFont){
    MessageBox(GetFocus(), "Out of memory creating font", appName,
	       MB_ICONHAND | MB_SYSTEMMODAL | MB_OK);
    DoDestroy(hWnd, msg, wParam, lParam);
    return -1;
  }
  
  /* Load Garbage Collection cursor */
  GarbageCursor = LoadCursor(hThisInstance, "GARBAGECURSOR");

  if (!GarbageCursor){
    MessageBox(GetFocus(), "Out of memory loading cursors", appName,
	       MB_ICONHAND | MB_SYSTEMMODAL | MB_OK);
    DoDestroy(hWnd, msg, wParam, lParam);
    return -1;
  }

  InitMenus(); /* initialize menus */

  SetMenuBitmaps(hWnd);

  return 0;
}

/* Response to Windows WM_DESTROY message */
static VOID local DoDestroy(HWND hWnd, UINT msg, WPARAM wParam, LPARAM lParam)
{
  /* Close Help Windows, if opened */
  WinHelp(hWnd, "WINHELP.HLP", HELP_QUIT, 0L);
  WinHelp(hWnd, "Hugs.HLP",   HELP_QUIT, 0L);

  /* Free space used by Fonts and cursors */
  if (GarbageCursor) DestroyCursor(GarbageCursor);
  if (hDialogFont) DeleteObject(hDialogFont);
}


/* Response to Windows WM_DROPFILES message */
static VOID local DoDropFiles(HWND hWnd, UINT msg, WPARAM wParam, LPARAM lParam)
{
  UINT cFiles, a;
  CHAR lpszFile[_MAX_PATH];

  forgetScriptsFrom(1);
  cFiles = DragQueryFile((HANDLE) wParam, (UINT) 0xFFFFFFFF, (LPSTR) NULL, 0);
  for(a = 0; a < cFiles; a++) {
    DragQueryFile((HANDLE) wParam, a, (LPSTR)lpszFile, (UINT)sizeof(lpszFile));
    /* Add file to scripts list */
    addScriptName(lpszFile, TRUE);
    SetWorkingDir(lpszFile);
  }
  DragFinish((HANDLE) wParam);

  /* set focus to frame window */
  SetForegroundWindow(hWnd);

  /* reload scripts */
  AbortInterpreter;
  readScripts(1);
  GotoInterpreter;
}

#if 0
/* Response to Windows WM_GETMINMAXINFO message */
static VOID local DoGetMinMaxInfo(HWND hWnd, UINT msg, WPARAM wParam, LPARAM lParam)
{
  MINMAXINFO FAR* lpmmi;
  RECT		  rWind;

  GetWindowRect(hWnd, &rWind);

  lpmmi = (MINMAXINFO FAR*) lParam;

  lpmmi->ptMaxPosition.x = rWind.left;
  lpmmi->ptMaxPosition.y = rWind.top;

  lpmmi->ptMaxTrackSize.x = FrameWinWidth;
  lpmmi->ptMaxTrackSize.y = FrameWinHeight;

  lpmmi->ptMaxSize.x = FrameWinWidth;
  lpmmi->ptMaxSize.y = FrameWinHeight;
}
#else
/*
A very minor quibble though is that it wasn't possible to
resize the main window (maybe that's really intentional..)
In any case, I've changed the handler for WM_MINMAXINFO to
let me	do this - code appended.

--sigbjorn
*/

/* Response to Windows WM_GETMINMAXINFO message */
static VOID local DoGetMinMaxInfo(HWND hWnd, UINT msg, WPARAM wParam, LPARAM
lParam)
{
  MINMAXINFO FAR* lpmmi;
  RECT		  rWind;
  RECT		  rDeskTop;

  GetWindowRect(GetDesktopWindow(), &rDeskTop);
  GetWindowRect(hWnd, &rWind);

  lpmmi = (MINMAXINFO FAR*) lParam;

  lpmmi->ptMaxPosition.x = 0;
  lpmmi->ptMaxPosition.y = 0;

  lpmmi->ptMinTrackSize.x = 10; // a random small non-neg number, really.
  lpmmi->ptMinTrackSize.y = 10;

  lpmmi->ptMaxTrackSize.x = rDeskTop.right - rDeskTop.left;
  lpmmi->ptMaxTrackSize.y = rDeskTop.bottom - rDeskTop.top;

  lpmmi->ptMaxSize.x = lpmmi->ptMaxTrackSize.x;
  lpmmi->ptMaxSize.y = lpmmi->ptMaxTrackSize.y;

}
#endif


static VOID local DoMove(HWND hWnd, UINT msg, WPARAM wParam, LPARAM lParam)
{
  if (!IsIconic(hWnd)) {
    /* We must substract as it gets client position */
    FrameWinX = (INT) LOWORD(lParam) - GetSystemMetrics(SM_CXFRAME);
    FrameWinY = (INT) HIWORD(lParam) - GetSystemMetrics(SM_CYCAPTION)
				     - GetSystemMetrics(SM_CYFRAME)
				     - GetSystemMetrics(SM_CYMENU);
  }
}



/* Load and execute Options dialog box */
static VOID local DoOptions(HWND hWnd, UINT msg, WPARAM wParam, LPARAM lParam)
{
  ExecDialog (hThisInstance, OPTIONSDLGBOX, OptionsDlgProc);
  AbortInterpreter;
  SetInterpreterCommand(":s\n");
  GotoInterpreter;
}


static VOID local DoScriptMan(HWND hWnd, UINT msg, WPARAM wParam, LPARAM lParam)
{
  ExecDialog(hThisInstance, SCRIPTMANDLGBOX, ScriptManDlgProc);
}



/* Executed before a menu is opened */
static VOID local DoInitMenu (HWND hWnd, UINT message, WPARAM wParam, LPARAM lParam)
{
  BOOL CanCopy, CanPaste, CanClear, CanCut;

  CanCopy  = (BOOL) SendMessage (hWndText, WM_CANCOPY,	0, 0L);
  CanCut   = (BOOL) SendMessage (hWndText, WM_CANCUT,	0, 0L);
  CanPaste = (BOOL) SendMessage (hWndText, WM_CANPASTE, 0, 0L);
  CanClear = (BOOL) SendMessage (hWndText, WM_CANCLEAR, 0, 0L);

  EnableMenuItem((HMENU)wParam, ID_COPY,  (CanCopy  ? MF_ENABLED : MF_GRAYED)|MF_BYCOMMAND);
  EnableMenuItem((HMENU)wParam, ID_PASTE, (CanPaste ? MF_ENABLED : MF_GRAYED)|MF_BYCOMMAND);
  EnableMenuItem((HMENU)wParam, ID_CUT,   (CanCut   ? MF_ENABLED : MF_GRAYED)|MF_BYCOMMAND);
  EnableMenuItem((HMENU)wParam, ID_CLEAR, (CanClear ? MF_ENABLED : MF_GRAYED)|MF_BYCOMMAND);
  EnableMenuItem((HMENU)wParam, ID_EVAL,  (CanCopy  ? MF_ENABLED : MF_GRAYED)|MF_BYCOMMAND);
  EnableMenuItem((HMENU)wParam, ID_TYPE,  (CanCopy  ? MF_ENABLED : MF_GRAYED)|MF_BYCOMMAND);
  EnableMenuItem((HMENU)wParam, ID_INFO,  (CanCopy  ? MF_ENABLED : MF_GRAYED)|MF_BYCOMMAND);
  EnableMenuItem((HMENU)wParam, ID_FIND,  (CanCopy  ? MF_ENABLED : MF_GRAYED)|MF_BYCOMMAND);
  EnableMenuItem((HMENU)wParam, ID_OPENSELECTED,  (CanCopy  ? MF_ENABLED : MF_GRAYED)|MF_BYCOMMAND);
  EnableMenuItem((HMENU)wParam, ID_EDITSELECTED,  (CanCopy  ? MF_ENABLED : MF_GRAYED)|MF_BYCOMMAND);

  EnableMenuItem((HMENU)wParam, ID_MAKE,	MF_ENABLED|MF_BYCOMMAND);

  EnableMenuItem((HMENU)wParam, ID_CLEARALL,	((getScriptHwMark() > 1)
						 ? MF_ENABLED : MF_GRAYED)|MF_BYCOMMAND);

  EnableMenuItem((HMENU)wParam, ID_COMPILE,	((getScriptHwMark() > 1)
						  ? MF_ENABLED : MF_GRAYED)|MF_BYCOMMAND);
}


/* --------------------------------------------------------------------------
 * Other functions for Windows GUI:
 * ------------------------------------------------------------------------*/

static
UINT FAR APIENTRY 
  FileOpenHookProc(HWND hdlg, UINT msg, WPARAM wParam, LPARAM lParam)
{
    switch (msg) {

    case WM_INITDIALOG: {
      HWND hWnd;
      hWnd = GetParent(hdlg);

      CenterDialogInParent(hWnd);
      SetDialogFont(hWnd, hDialogFont);
		
      return TRUE;
    }

  }
  return FALSE;
}


/* Used to get a file name using a common dialog box. Returns a pointer to    */
/* a static string where the file name is, or NULL if cancel button is pushed */
/* Mask is the identificator of a string defined in Hugs.Rc where the type    */
/* of files and their masks are 					      */
static CHAR* local GetaFileName(HWND hWnd, UINT Mask)
{
  #define MAXEXTENSIONS 15

  static CHAR		Extensions[MAXEXTENSIONS][_MAX_EXT+1];
  static OPENFILENAME	ofn;
  static CHAR		szFileName[_MAX_PATH];
  CHAR			szFile[_MAX_PATH], szFileTitle[_MAX_PATH];
  UINT			i, j, cbString, n;
  CHAR			chReplace;    /* Separator between different filters in szFilter */
  CHAR			szFilter[300];
  char			currentDir[_MAX_PATH];

  szFile[0] = '\0';

  if ((cbString = LoadString(hThisInstance, Mask,
       szFilter, sizeof(szFilter))) == 0) {
    /* Error */
    return NULL;
  }
  chReplace = szFilter[cbString - 1]; /* Get separator */

  /* Get valid extensions for files */
  for (n=0, i=0;szFilter[i];) {
    while (szFilter[i] != chReplace) i++;
    i++;
    do {
      while (szFilter[i] != '.') i++;
      i++;
      j=0;
      while ((szFilter[i] != ';')&&(szFilter[i] != chReplace)){
	Extensions[n][j++] = szFilter[i++];
      }
      Extensions[n++][j] = (CHAR) 0;
    } while (szFilter[i] == ';');
    i++;
  }
  for (;n<MAXEXTENSIONS;n++)
    Extensions[n][0] = (CHAR)0;


  /* Replace separator with NULL */
  for (i = 0; szFilter[i] != '\0'; i++) {
    if (szFilter[i] == chReplace)
      szFilter[i] = '\0';
  }

  memset(&ofn, 0, sizeof(OPENFILENAME));

  ofn.lStructSize = sizeof(OPENFILENAME);
  ofn.hInstance = hThisInstance;
  ofn.hwndOwner = hWnd;
  ofn.lpstrFilter = szFilter;
  ofn.nFilterIndex = 1;
  ofn.lpstrFile= szFile;
  ofn.nMaxFile = sizeof(szFile);
  ofn.lpstrFileTitle = szFileTitle;
  ofn.nMaxFileTitle = sizeof(szFileTitle);
  ofn.Flags = OFN_PATHMUSTEXIST | OFN_FILEMUSTEXIST | OFN_HIDEREADONLY | OFN_ENABLEHOOK | OFN_EXPLORER;;
  ofn.lpfnHook = FileOpenHookProc;
  GetCurrentDirectory(_MAX_PATH,currentDir);
  ofn.lpstrInitialDir = currentDir;


  if (GetOpenFileName(&ofn)) {
    strcpy(szFileName, ofn.lpstrFile);
    return szFileName;
  }
  else {
    return NULL;
  }
}


/* Construct hugs_argc and hugs_argv from lpszCmdLine */
static Void local copyArgs(LPSTR lpszCmdLine) {

  INT	i, currentArg, beginOfArg;
  CHAR	svChar;

  /* First, get number of args					     */
  /* Rules:							     */
  /* 1) arguments are separates by spaces			     */
  /* 2) A single argument may contain spaces if surrounded by quotes */
  /*								     */
  /* For example, a valid command line with two args is 	     */
  /*  c:> winhugs -98 "c:\program files\test.hs"		     */
  
  hugs_argc = 0;
  for(i=0;lpszCmdLine[i];) {
    if(lpszCmdLine[i]=='"')  { /* a "... " argument */
      i++;
      hugs_argc++;
      while (lpszCmdLine[i] && lpszCmdLine[i] != '"') i++;
      if (lpszCmdLine[i] != '"') {
	MessageBox(GetFocus(), "Invalid command line", appName, MB_OK);
	hugs_argc = 0;
      }
    }
    else if(lpszCmdLine[i]!=' ') {
      i++;    
      hugs_argc++;
      while (lpszCmdLine[i] && lpszCmdLine[i] != ' ') i++;	    
    }
    
    if(lpszCmdLine[i]) i++;
  }

 
  hugs_argc++; /* One more for program name */
  
  /* Allocate arguments */
  hugs_argv = malloc(hugs_argc*sizeof(CHAR *));
  if (!hugs_argv) {
	ERRMSG(0) "String storage space exhausted"
	EEND;
  }
 
  /* First argument must be program name */
  hugs_argv[0] = strCopy("winhugs.exe");

#define copyCurrentArg {					      \
	  svChar = lpszCmdLine[i];				      \
	  lpszCmdLine[i] = '\0';				      \
	  hugs_argv[currentArg++] = strCopy(&lpszCmdLine[beginOfArg]);\
	  lpszCmdLine[i] = svChar;				      \
	}	   

  if (hugs_argc > 1) {
    currentArg = 1;
    for(i=0;lpszCmdLine[i];) {
    
      if(lpszCmdLine[i]=='"')  { /* a "... " argument */
	beginOfArg = ++i;	 
	while (lpszCmdLine[i] != '"') i++;
	copyCurrentArg;
      }
      else if(lpszCmdLine[i]!=' ') {
	beginOfArg = i;
	while (lpszCmdLine[i] && lpszCmdLine[i] != ' ') i++;	      
	copyCurrentArg;
      }
    
      if(lpszCmdLine[i]) i++;
    }
  }  
#undef copyCurrentArg
}


/* Program entry point */
INT APIENTRY WinMain(HINSTANCE hInstance, HINSTANCE hPrevInstance, LPSTR lpszCmdLine, INT nCmdShow)
{
  INT i;

  /* Save application instance */
  hThisInstance = hInstance;

  if (!hPrevInstance) {
    if (!InitApplication()) {
      MessageBeep(0);
      {  DWORD Error;
	 CHAR  Buffer[256];

	 Error = GetLastError();
	 sprintf(Buffer, "Error number %u",Error);
	 MessageBox(NULL, Buffer, "Error", MB_OK);
      }
      return FALSE;
    }
  }


  if (!InitInstance(lpszCmdLine, nCmdShow))
    return FALSE;


  /* Call hugs main function */
  copyArgs(lpszCmdLine);
  main(hugs_argc, hugs_argv);
  
  /* Leaving hugs ... */
  /* hWndMain is already destroyed */

  /* Free allocated memory for command line */
  for (i=0; i<hugs_argc; i++)
   if (hugs_argv[i])
     free(hugs_argv[i]);
  free(hugs_argv);

  return 0;
}


/* Init application */
static BOOL local InitApplication(VOID)
{
  WNDCLASS wc;

  /* register frame window class */
  if (!FRAMERegisterClass(hThisInstance))
    return FALSE;

  /* superclass the frame class */
  if (!FRAMESuperclass (hThisInstance,
			"HugsFrameWindow",
			"HugsMenu",
			"Hugs"))
    return FALSE;

  /* register classes hierarchy window */
  wc.style		= CS_VREDRAW | CS_HREDRAW;
  wc.lpfnWndProc	= ClassesWndProc;
  wc.cbClsExtra 	= 0;
  wc.cbWndExtra 	= 0;
  wc.hInstance		= hThisInstance;
  wc.hIcon		= NULL;
  wc.hCursor		= NULL;
  wc.hbrBackground	= GetStockObject(LTGRAY_BRUSH);
  wc.lpszMenuName	= NULL;
  wc.lpszClassName	= "HugsClassesWindow";

  if (!RegisterClass(&wc))
    return FALSE;

  /* register text class */
  if (!RegisterTextClass(hThisInstance))
    return FALSE;

  return TRUE;
}

/* Init one instance of the application */
static BOOL local InitInstance(LPSTR lpCmdLine, INT nCmdShow)
{
  RECT		rText, rTB, rSTLN;
  HWND		hWndTB, hWndSTLN;
  INT		FontSize, FontWeight;
  CHAR		FontName[256];

  /* Create frame window */
  hWndMain = FRAMECreateWindow (hThisInstance,
				appName,
				MainGUIWndProc,
				&PrevWndProc,
				NULL,
				"HugsFrameWindow",
				"RESIZECORNER",
				"BUTTON", "PUSHEDBUTTON");
  if (!hWndMain)
    return FALSE;

  /* Configure tools bar */
  hWndTB = FRAMEGetTB (hWndMain);
  GetClientRect(hWndTB, &rTB);
  TBAppendButton(hWndTB, ID_OPEN,	     "OPENFILEBUTTON",	  ID_OPEN,	TRUE);
  TBAppendButton(hWndTB, ID_SCRIPTMAN,	     "SCRIPTMANBUTTON",   ID_SCRIPTMAN, TRUE);
  TBAppendButton(hWndTB, MF_SEPARATOR,	     NULL,		  0,		0);
  TBAppendButton(hWndTB, ID_CUT,	     "CUTBUTTON",	  ID_CUT,	TRUE);
  TBAppendButton(hWndTB, ID_COPY,	     "COPYBUTTON",	  ID_COPY,	TRUE);
  TBAppendButton(hWndTB, ID_PASTE,	     "PASTEBUTTON",	  ID_PASTE,	TRUE);
  TBAppendButton(hWndTB, ID_CLEAR,	     "DELETEBUTTON",	  ID_CLEAR,	TRUE);
  TBAppendButton(hWndTB, ID_GOEDIT,	     "EDITBUTTON",	  ID_GOEDIT,	TRUE);
  TBAppendButton(hWndTB, MF_SEPARATOR,	     NULL,		  0,		0);
  TBAppendButton(hWndTB, ID_RUN,	     "RUNBUTTON",	  ID_RUN,	TRUE);
  TBAppendButton(hWndTB, ID_STOP,	     "STOPBUTTON",	  ID_STOP,	TRUE);
  TBAppendButton(hWndTB, ID_MAKE,	     "MAKEBUTTON",	  ID_MAKE,	TRUE);
  TBAppendButton(hWndTB, ID_SETOPTIONS,      "OPTIONSBUTTON",	  ID_SETOPTIONS,TRUE);
  TBAppendButton(hWndTB, MF_SEPARATOR,	     NULL,		  0,		0);
  TBAppendButton(hWndTB, ID_BROWSEHIERARCHY, "HIERARCHYBUTTON",   ID_BROWSEHIERARCHY, TRUE);
  TBAppendButton(hWndTB, MF_SEPARATOR,	     NULL,		  0,		0);
  TBAppendButton(hWndTB, ID_HELPINDEX,	     "HELPBUTTON",	  ID_HELPINDEX, TRUE);
  TBAppendButton(hWndTB, MF_SEPARATOR,	     NULL,		  0,		0);
  TBAppendButton(hWndTB, ID_EXIT,	     "EXITBUTTON",	  ID_EXIT,	TRUE);

  /* get status line */
  hWndSTLN = FRAMEGetSTLN(hWndMain);
  GetClientRect(hWndSTLN, &rSTLN);

  /* Load accelerators */
  hAccelTable = LoadAccelerators(hThisInstance, (LPSTR) "HugsAccelerators");

  /* create text window */
  GetFromRegistryFont(FontName, 256, &FontSize, &FontWeight);
  GetFromRegistryScreenSize(&ScreenRows, &ScreenCols);
  hWndText = CreateTextWindow(hThisInstance,
			      hWndMain,
			      rTB.right+2,
			      0 /*V_INDENT*/,
			      ScreenCols, ScreenRows,
			      FontName, FontSize, FontWeight,
			      hAccelTable);
  if (!hWndText)
    return FALSE;
  GetWindowRect (hWndText, &rText);

  /* Atach text window to frame */
  FRAMESetChild(hWndMain, hWndText);

  /* Set main window size */
  FrameWinWidth =  (rText.right-rText.left)+
		    GetSystemMetrics(SM_CXFRAME)*2+
		    GetSystemMetrics(SM_CXVSCROLL)+
		    rTB.right+FRAMEGetRightBorderSize(hWndMain);

  FrameWinHeight = (rText.bottom-rText.top+1)+
		    GetSystemMetrics(SM_CYFRAME)*2+
		    GetSystemMetrics(SM_CYCAPTION)+
		    GetSystemMetrics(SM_CYMENU)+
		    rSTLN.bottom;

  GetFromRegistryScreenPosition(&FrameWinX, &FrameWinY);
  MoveWindow(hWndMain, FrameWinX, FrameWinY, FrameWinWidth, FrameWinHeight, FALSE);

  /* Show the Window */
  ShowWindow(hWndMain, nCmdShow);
  UpdateWindow(hWndMain);

  return TRUE;
}


/* --------------------------------------------------------------------------
 * Main Window WinProc:
 * ------------------------------------------------------------------------*/

#define CALLPARENTCLASS ((LRESULT)CallWindowProc(PrevWndProc, hWnd, msg, wParam, lParam))

LRESULT CALLBACK MainGUIWndProc(HWND hWnd, UINT msg, WPARAM wParam, LPARAM lParam)
{

  /* Check rest of messages */
  switch (msg) {

    case WM_CLOSE:		DoClose(hWnd, msg, wParam, lParam);
				break;

    case WM_COMMAND:		DoCommand(hWnd, msg, wParam, lParam);
				break;

    case WM_CREATE:		return ((LRESULT) DoCreate(hWnd, msg, wParam, lParam));

    case WM_DESTROY:		DoDestroy(hWnd, msg, wParam, lParam);
				break;

    case WM_DROPFILES:		DoDropFiles(hWnd, msg, wParam, lParam);
				break;

    case WM_GETMINMAXINFO:	DoGetMinMaxInfo(hWnd, msg, wParam, lParam);
				break;

    case WM_INITMENU:		DoInitMenu(hWnd, msg, wParam, lParam);
				break;

    case WM_MOVE:		DoMove(hWnd, msg, wParam, lParam);
				break;

    default:			return CALLPARENTCLASS;

  }
  return CALLPARENTCLASS;
}
#undef CALLPARENTCLASS


/* --------------------------------------------------------------------------
 * Dialogs procedures:
 * ------------------------------------------------------------------------*/


LRESULT CALLBACK AboutDlgProc(HWND hDlg, UINT msg, WPARAM wParam, LPARAM lParam)
{
  HBITMAP hBitmap;

  switch (msg) {

    case WM_INITDIALOG: {
      CHAR Buffer[256];

      CenterDialogInParent(hDlg);
      SetDialogFont (hDlg, hDialogFont);

      {
	MEMORYSTATUS ms;

	ms.dwLength = sizeof(MEMORYSTATUS);
	GlobalMemoryStatus (&ms);

	wsprintf (Buffer, "Unkown");
	SetDlgItemText(hDlg, ID_FREERESOURCES, (LPCSTR)Buffer);

	wsprintf (Buffer, "%u KB",((UINT)ms.dwTotalPhys)/1024U);
	SetDlgItemText(hDlg, ID_TOTALMEMORY, (LPCSTR)Buffer);

      }
    }
    return TRUE;

    case WM_PAINT: {
      HDC	   hDC;
      PAINTSTRUCT  Ps;

      BeginPaint(hDlg, &Ps);
      hDC = Ps.hdc;

      hBitmap = LoadMappedBitmap(hThisInstance, "LOGOBMP");
      DrawBitmap(hDC, hBitmap, 25, 40);
      DeleteObject(hBitmap);
      EndPaint(hDlg, &Ps);
    }
    break;

    case WM_COMMAND:
      switch (wParam) {
	case IDOK:
	  EndDialog(hDlg, TRUE);
	  return TRUE;
	default:
	  return TRUE;
    }
  }
  return FALSE;
}


/* Handle options dialog box */
LRESULT CALLBACK OptionsDlgProc(HWND hDlg, UINT msg, WPARAM wParam, LPARAM lParam)
{
  INT  i;

  switch (msg) {

    case WM_INITDIALOG: {
      CHAR Buffer[300];

      CenterDialogInParent(hDlg);
      SetDialogFont (hDlg, hDialogFont);
      SetDlgItemText(hDlg, ID_PROMPT,	    (LPCSTR) prompt);
      SetDlgItemText(hDlg, ID_LASTEXPR,     (LPCSTR) repeatStr);
      SetDlgItemText(hDlg, ID_PATH,	    (LPCSTR) hugsPath);
      SetDlgItemText(hDlg, ID_EDITOR,	    (LPCSTR) hugsEdit);
#if SUPPORT_PREPROCESSOR
      SetDlgItemText(hDlg, ID_PREPROCESSOR, (LPCSTR) preprocessor);
#endif
      sprintf(Buffer, "%d", cutoff);
      SetDlgItemText(hDlg, ID_CUTOFF,	    (LPCSTR) Buffer);

      sprintf(Buffer, "%d", heapSize);
      SetDlgItemText(hDlg, ID_HEAPSIZE,     (LPCSTR) Buffer);

      for(i=0; toggle[i].c; i++) {
	  int j = 0;
	  while (1) { /* look for DlgItem corresponding to flag */
	    GetDlgItemText(hDlg, ID_OP+j, (LPSTR) Buffer, 1024);

	    if (!(*Buffer))
	      break;

	    if (Buffer[1] == toggle[i].c) {
	      if (!toggle[i].h98 && haskell98)
		EnableWindow(GetDlgItem(hDlg, ID_OP+j), FALSE);
	      else
		CheckDlgButton(hDlg, ID_OP+j, *toggle[i].flag);
	      break;
	    }

	    j++;
	  }
      }


/*
      for(i=0; toggle[i].c; i++)
	if (!toggle[i].h98 && haskell98)
	  EnableWindow(GetDlgItem(hDlg, ID_OP+i), FALSE);
	else
	  CheckDlgButton(hDlg, ID_OP+i, *toggle[i].flag);

*/

      return TRUE;
    }

    case WM_PAINT: {
	  HDC		hDC;
	  PAINTSTRUCT	Ps;
	  HBITMAP	hBitmap;
	  RECT		aRect, DlgRect;

	  BeginPaint(hDlg, &Ps);
	  hDC = Ps.hdc;

	  /* Paint classes Bitmap */
	  GetWindowRect(hDlg, &DlgRect);
	  GetWindowRect(GetDlgItem(hDlg, ID_PLACEBITMAP), &aRect);

	  hBitmap = LoadMappedBitmap(hThisInstance, "OPTIONSDLGBMP");
	  DrawBitmap(hDC, hBitmap,
		     aRect.left-DlgRect.left-GetSystemMetrics(SM_CXDLGFRAME),
		     aRect.top-DlgRect.top-GetSystemMetrics(SM_CYDLGFRAME)-GetSystemMetrics(SM_CYCAPTION));
	  DeleteObject(hBitmap);
	  EndPaint(hDlg, &Ps);
    }
    break;

    case WM_COMMAND:
      switch (wParam) {

	case IDCANCEL:
	  EndDialog(hDlg, TRUE);
	  return FALSE;

	case IDOK: {
	  CHAR Buffer[1024];

	  GetDlgItemText(hDlg, ID_PROMPT, (LPSTR) Buffer, 1024);
	  if (prompt) free(prompt);
	  prompt = strCopy(Buffer);

	  GetDlgItemText(hDlg, ID_LASTEXPR, (LPSTR) Buffer, 1024);
	  if (repeatStr) free(repeatStr);
	  repeatStr = strCopy(Buffer);

	  GetDlgItemText(hDlg, ID_PATH, (LPSTR) Buffer, 1024);
	  if (hugsPath) free(hugsPath);
	  hugsPath = strCopy(Buffer);

	  GetDlgItemText(hDlg, ID_EDITOR, (LPSTR) Buffer, 1024);
	  if (hugsEdit) free(hugsEdit);
	  hugsEdit = strCopy(Buffer);

#if SUPPORT_PREPROCESSOR
	  GetDlgItemText(hDlg, ID_PREPROCESSOR, (LPSTR) Buffer, 1024);
	  if (preprocessor) free(preprocessor);
	  preprocessor = strCopy(Buffer);
#endif

	  GetDlgItemText(hDlg, ID_CUTOFF, (LPSTR) Buffer, 1024);
	  cutoff = argToInt(Buffer);

	  GetDlgItemText(hDlg, ID_HEAPSIZE, (LPSTR) Buffer, 1024);
	  setHeapSize(Buffer);


      for(i=0; toggle[i].c; i++) {
	  int j = 0;
	  while (1) { /* look for DlgItem corresponding to flag */
	    GetDlgItemText(hDlg, ID_OP+j, (LPSTR) Buffer, 1024);

	    if (!(*Buffer))
	      break;

	    if ((Buffer[1] == toggle[i].c) && (toggle[i].h98 || !haskell98)) {
	      *toggle[i].flag = (Bool) IsDlgButtonChecked(hDlg, ID_OP+j);
	      break;
	    }

	    j++;
	  }
      }

/*
	  for(i=0; toggle[i].c; i++)
	    if (toggle[i].h98 || !haskell98)
	      *toggle[i].flag = (Bool) IsDlgButtonChecked(hDlg, ID_OP+i);
*/
	  writeRegString("Options", optionsToStr());

	  EndDialog(hDlg, TRUE);
	  return TRUE;
	}

	default:
	  return TRUE;
      }
  }
  return FALSE;
}


/* --------------------------------------------------------------------------
 * Script Manager:
 * ------------------------------------------------------------------------*/

static INT smLoaded, smUpto;
static String smFile[NUM_SCRIPTS];
static INT selScr;

static Void local SmSelScr(HWND hDlg, Int i) {
    selScr = i;
    SendDlgItemMessage(hDlg, LB_SCRIPTS, LB_SETCURSEL, i, 0L);
}

static Void local SmAddScr(HWND hDlg, CHAR *s) {
    smFile[smUpto] = strCopy(s);
    fprintf(stdstr,"%s\n",smFile[smUpto]);
    SendDlgItemMessage(hDlg, LB_SCRIPTS, LB_ADDSTRING, 0,
		       (LONG) (LPSTR) stdstrbuff);
    SmSelScr(hDlg,smUpto);
    smUpto++;
}


LRESULT CALLBACK ScriptManDlgProc(HWND hDlg, UINT msg,
			       WPARAM wParam, LPARAM lParam) {
    switch (msg) {
	case WM_INITDIALOG: {
	    Int i;
	    smLoaded = numLoadedScripts();
	    smUpto   = 0;

	    CenterDialogInParent(hDlg);
	    SetDialogFont (hDlg, hDialogFont);

	    SendDlgItemMessage(hDlg, LB_SCRIPTS, LB_SETHORIZONTALEXTENT, (WPARAM)1000, 0L);

	    SendDlgItemMessage(hDlg, LB_SCRIPTS, WM_SETREDRAW,FALSE,0L);

	    for (i=0; i<getScriptHwMark(); i++)
		SmAddScr(hDlg,getScriptRealName(i));
	    SmSelScr(hDlg,0);
	    SendDlgItemMessage(hDlg,LB_SCRIPTS,LB_SETCURSEL, 0, 0L);
	    SendDlgItemMessage(hDlg,LB_SCRIPTS,WM_SETREDRAW,TRUE,0L);
	    return TRUE;
	}
	case WM_PAINT: {
	      HDC		hDC;
	      PAINTSTRUCT   Ps;
	      HBITMAP		hBitmap;
	      RECT		aRect, DlgRect;

	      BeginPaint(hDlg, &Ps);
	      hDC = Ps.hdc;

	      /* Paint classes Bitmap */
	      GetWindowRect(hDlg, &DlgRect);
	      GetWindowRect(GetDlgItem(hDlg, ID_PLACEBITMAP), &aRect);

	      hBitmap = LoadMappedBitmap(hThisInstance, "SCRIPTMANDLGBMP");
	      DrawBitmap(hDC, hBitmap,
			 aRect.left-DlgRect.left-GetSystemMetrics(SM_CXDLGFRAME),
			 aRect.top-DlgRect.top-GetSystemMetrics(SM_CYDLGFRAME)-GetSystemMetrics(SM_CYCAPTION));
	      DeleteObject(hBitmap);
	      EndPaint(hDlg, &Ps);
	}
	break;

	case WM_COMMAND:
	    switch (CMDitem(wParam,lParam)) {
		case ID_ADDSCRIPT:
		    if (smUpto>=NUM_SCRIPTS)
			MessageBox(hDlg,"Too many script files",
				   "Add script", MB_ICONEXCLAMATION|MB_OK);
		    else {
			String s = GetaFileName(hDlg,IDS_FILTERFILE);
			if (s)
			    SmAddScr(hDlg,s);
		    }
		    return TRUE;

		case ID_DELSCRIPT:
		    if (selScr < 0)
			MessageBox(hDlg,"No script file selected",
				   "Remove script", MB_ICONEXCLAMATION|MB_OK);
		    else if (selScr == 0)
			MessageBox(hDlg,"Cannot remove prelude file",
				   "Remove script", MB_ICONEXCLAMATION|MB_OK);
		    else {
			Int i;
			SendDlgItemMessage(hDlg, LB_SCRIPTS, LB_DELETESTRING,
					   selScr, 0L);
			if (selScr<smLoaded)
			    smLoaded = selScr;
			if (smFile[selScr]) {
			    free(smFile[selScr]);
			    smFile[selScr] = 0;
			}
			for (i=selScr+1; i<smUpto; ++i)
			    smFile[i-1] = smFile[i];
			smUpto--;
			SmSelScr(hDlg,-1);
		    }
		    return TRUE;

		case ID_EDITSCRIPT:
		    if (selScr >= 0)
			DlgSendMessage(hDlg, WM_COMMAND, LB_SCRIPTS, MAKELONG(0, LBN_DBLCLK));
		    else
			MessageBox(hDlg,"No file selected","Edit",
				   MB_ICONEXCLAMATION|MB_OK);
		    return TRUE;

		case ID_CLEARSCRIPTS: {
		    Int i;
		    for (i=1; i<smUpto; ++i)
			if (smFile[i])
			    free(smFile[i]);
		    smUpto = smLoaded = 1;
		    SendDlgItemMessage(hDlg,LB_SCRIPTS,LB_RESETCONTENT,0,0L);
		    fprintf(stdstr,"%s\n",smFile[0]);
		    SendDlgItemMessage(hDlg, LB_SCRIPTS, LB_ADDSTRING, 0,
				       (LONG) (LPSTR) stdstrbuff);
		    SmSelScr(hDlg,-1);
		    return TRUE;
		}

		case LB_SCRIPTS:
		    switch (CMDdata(wParam,lParam)) {
			case LBN_SELCHANGE:
			    SmSelScr(hDlg,(Int)SendDlgItemMessage(hDlg,
								  LB_SCRIPTS,
								  LB_GETCURSEL,
								  0, 0L));
			    return TRUE;

			case LBN_DBLCLK: {
			    char buffer[_MAX_PATH];
			    SendDlgItemMessage(hDlg,
					       LB_SCRIPTS,
					       LB_GETTEXT,
					       selScr,
					       (LPARAM) (LPSTR) buffer);
			    setLastEdit((String)buffer,0);
			    runEditor();
			    return TRUE;
			}
		    }
		    break;

		case IDOK: {
		    Int i;
		    /* Sigh, script stack hackery. */
		    for (i=0; i<getScriptHwMark(); i++)
			if (getScriptName(i)) {
			    free(getScriptName(i));
			    free(getScriptRealName(i));
		    }
		    for (i=0; i<smUpto; i++) {
		      setScriptName(i,smFile[i]);
		      setScriptRealName(i,strCopy(RealPath(smFile[i])));
		      smFile[i]     = 0;
		    }
		    setScriptHwMark(smUpto);
		    setNumLoadedScripts(smLoaded);
		    dropScriptsFrom(smLoaded-1);
		    PostMessage(hWndMain,WM_COMMAND,ID_COMPILE,0L);
		    EndDialog(hDlg,TRUE);
		    return TRUE;
		}

		case IDCANCEL: {
		    Int i;
		    for (i=0; i<smUpto; i++)
			if (smFile[i])
			    free(smFile[i]);
		    EndDialog(hDlg, TRUE);
		    return TRUE;
		}
	    }
	    break;
    }
    return FALSE;
}


/* --------------------------------------------------------------------------
 * Manages Adding file names to Menus:
 * ------------------------------------------------------------------------*/

#define SUBMENU(x)		 ((x)-1)



static VOID local InitFileNamesMenu(WORD MenuId, WORD FirstMenuId, FILENAMESMENU* fnm) 
{
  UINT i;

  fnm->MenuId = MenuId;
  fnm->FirstMenuId = FirstMenuId;
  for (i=0;i<FILES_TO_REMEMBER;i++) {
    fnm->FileNames[i][0] = (CHAR) 0;
  }
  fnm->Length = 0;
}



static CHAR local *GetFileNameFromFileNamesMenu (FILENAMESMENU* fnm, UINT i)
{
  if (i<fnm->Length) {
    return fnm->FileNames[i];
  }
  else {
    return NULL;
  }
}

VOID AddFileToFileNamesMenu(FILENAMESMENU* fnm, LPSTR NewFileName)
{
  HMENU 	hMainMenu, hFilesSubMenu;
  CHAR		shortFName[_MAX_PATH], MenuContents[_MAX_PATH];
  UINT		i, Up;

  hMainMenu	= GetMenu(hWndMain);
  hFilesSubMenu = GetSubMenu(hMainMenu, SUBMENU(fnm->MenuId));


  Up = fnm->Length-1;

  /* Check if the file is already added */
  for (i=0; i<fnm->Length; i++) {
    if (!stricmp(NewFileName, fnm->FileNames[i])) {
      /* move it to the first position */
      Up = i;
      goto shift;
    }  
  }


  /* If there are less of FILES_TO_REMEMBER menu items, add one at first position */
  if (fnm->Length < FILES_TO_REMEMBER) {
    fnm->Length++;
    Up++;
    AppendMenu(hFilesSubMenu, MF_ENABLED, fnm->FirstMenuId+fnm->Length, "");
  }


  shift:
  /* Shift file names down */
  for (i=Up; i>0; i--) {
    strcpy(fnm->FileNames[i], fnm->FileNames[i-1]);    
    ShortFileName(fnm->FileNames[i],shortFName); 
    wsprintf (MenuContents, "&%d %s", i, shortFName);
    ModifyMenu(hFilesSubMenu, fnm->FirstMenuId+i+1, MF_BYCOMMAND, fnm->FirstMenuId+i+1, (LPCSTR)MenuContents);
  }

  /* Add new file */
  ShortFileName(NewFileName,shortFName); 
  wsprintf (MenuContents, "&%d %s", 0, shortFName);
  ModifyMenu(hFilesSubMenu, fnm->FirstMenuId+1, MF_BYCOMMAND, fnm->FirstMenuId+1, (LPCSTR)MenuContents);
  strcpy(fnm->FileNames[0], NewFileName);

}


static VOID local SaveToRegistryFileNamesMenu (FILENAMESMENU* fnm, LPSTR Section)
{
  HMENU hMainMenu, hFilesSubMenu;
  CHAR	Buffer[_MAX_PATH], Entry[256];
  UINT	i, Total;

  hMainMenu = GetMenu(hWndMain);
  hFilesSubMenu = GetSubMenu(hMainMenu, SUBMENU(fnm->MenuId));

  for (i=0; i<fnm->Length; i++) {
    wsprintf(Entry, "%s File%d", Section, fnm->Length-i-1);
    writeRegString(Entry, fnm->FileNames[i]);
  }
}


/* loads files added to a menu from the registry */
static VOID local GetFromRegistryFileNamesMenu (FILENAMESMENU* fnm, LPSTR Section)
{
  HMENU hMainMenu, hFilesSubMenu;
  CHAR	Entry[256];
  String Buffer;
  UINT	i, Total;

  hMainMenu = GetMenu(hWndMain);
  hFilesSubMenu = GetSubMenu(hMainMenu, SUBMENU(fnm->MenuId));


  /* Delete current entries, if any */
  for (i=0; i<fnm->Length; i++) {
    DeleteMenu(hFilesSubMenu, fnm->FirstMenuId+i+1, MF_BYCOMMAND);
  }

  for (i=0;;i++) {
    wsprintf(Entry, "%s File%d", Section, i);

    Buffer=readRegString(HKEY_CURRENT_USER,hugsRegRoot,Entry, "");
	
    if ( Buffer[0] ) {
	AddFileToFileNamesMenu(fnm, Buffer);
	free(Buffer);
    } else {
	free(Buffer);
	break;
    }
  }
}



FILENAMESMENU FilesMenu, EditMenu;

static VOID local InitMenus(VOID) {

  InitFileNamesMenu(ID_FILESMENU,   ID_EXIT,	     &FilesMenu);
  InitFileNamesMenu(ID_EDITMENU,    ID_EDITSELECTED, &EditMenu); 
}

/* --------------------------------------------------------------------------
 * Loading and saving options to registry:
 * ------------------------------------------------------------------------*/

#define RKEY_DOCPATH		 "Doc Path"
#define RKEY_SCREENROWS 	 "Screen Rows"
#define RKEY_SCREENCOLS 	 "Screen Cols"
#define RKEY_SCREENFONTNAME	 "Screen Font Name"
#define RKEY_SCREENFONTSIZE	 "Screen Font Size"
#define RKEY_SCREENFONTWEIGHT	 "Screen Font Weight"
#define RKEY_DIALOGSFONTNAME	 "Dialogs Font Name"
#define RKEY_DIALOGSFONTSIZE	 "Dialogs Font Size"
#define RKEY_LASTPATH		 "LastPath"
#define RKEY_POSX		 "Screen PosX"
#define RKEY_POSY		 "Screen PosY"
#define RKEY_FILESMENU		 "Files Menu"
#define RKEY_EDITSMENU		 "Edit Menu"


static int GetFromRegistryDocPath(char *realPath, int pathLen)
{
    String   hugsdir_ = hugsdir(); /* static, not freeable. */
    String   regPath = readRegString(HKEY_CURRENT_USER,hugsRegRoot,RKEY_DOCPATH, DEFAULT_DOC_DIR);
    INT      rlen,hlen;
    INT      flen = sizeof("{Hugs}") - 1;

    if (!regPath) {
	goto NoResult;
    }
    /* Expand "{Hugs}" but only at the beginning of the string, avoiding
     * buffer overflows in the process.
     */
    rlen = strlen(regPath);
    hlen = strlen(hugsdir_);
    
    if ( (rlen > pathLen) ) {
	/* {Hugs} or not, no way the result is going to fit. */
	free(regPath);
	goto NoResult;
    }
    if (strncmp ("{Hugs}", regPath, flen) == 0) {
	if ( ((rlen + (hlen - flen)) > pathLen) ) {
	    free(regPath);
	    goto NoResult;
	}
	strcpy(realPath,hugsdir_);
	strcat(realPath,regPath+flen);
    } else {
	strcpy(realPath,regPath);
    }
    free(regPath);
    return 1;
    
NoResult:
    *realPath = '\0';
    return 0;
}

static VOID local GetFromRegistryFont(CHAR *FontName, INT FontNameLen, INT *FontSize, INT* FontWeight)
{
    String  opt = readRegString(HKEY_CURRENT_USER,hugsRegRoot,RKEY_SCREENFONTNAME, DEFAULT_FONT);
    strncpy(FontName, opt, FontNameLen);
    free(opt);
    *FontSize = readRegInt(RKEY_SCREENFONTSIZE, DEFAULT_FONT_SIZE);
    *FontWeight = readRegInt(RKEY_SCREENFONTWEIGHT, DEFAULT_FONT_WEIGHT);
}

static VOID local GetFromRegistryDialogFont(CHAR *FontName, INT FontNameLen, INT *FontSize)
{
    String opt = readRegString(HKEY_CURRENT_USER,hugsRegRoot,RKEY_DIALOGSFONTNAME, DEFAULT_DIALOGFONT);
    strncpy(FontName, opt, FontNameLen);
    *FontSize = readRegInt(RKEY_DIALOGSFONTSIZE, DEFAULT_DIALOGFONT_SIZE);
    free(opt);
}


static VOID local GetFromRegistryScreenSize(INT *Rows, INT *Cols)
{
  *Rows = readRegInt(RKEY_SCREENROWS, DEFAULT_ROWS);
  *Cols = readRegInt(RKEY_SCREENCOLS, DEFAULT_COLS);
}


static VOID local GetFromRegistryScreenPosition(INT *X, INT *Y)
{
  *X = readRegInt(RKEY_POSX, 0);
  *X = min(GetSystemMetrics(SM_CXFULLSCREEN)-40, *X);
  *Y = readRegInt(RKEY_POSY, 0);
  *Y = min(GetSystemMetrics(SM_CYFULLSCREEN)-40, *Y);
}


VOID ReadGUIOptions(VOID)
{
    /* Get last working dir and set it */
    String opt = readRegString(HKEY_CURRENT_USER,hugsRegRoot,RKEY_LASTPATH, ".\\");
    SetWorkingDir(opt);
    free(opt);

    /* load menus */
    GetFromRegistryFileNamesMenu(&FilesMenu, RKEY_FILESMENU);
    GetFromRegistryFileNamesMenu(&EditMenu, RKEY_EDITSMENU);
}


VOID SaveGUIOptions(VOID)
{
    String opt = readRegString(HKEY_CURRENT_USER,hugsRegRoot,RKEY_DOCPATH, DEFAULT_DOC_DIR);
    writeRegString(RKEY_DOCPATH, opt);
    free(opt);

    writeRegString("Options", optionsToStr());

    /* calculate rows and columns */
    if (!IsIconic(hWndMain) && !IsZoomed(hWndMain)) {
	RECT	aRect;
	TEXTMETRIC *tm = (TEXTMETRIC*) SendMessage (hWndText, WM_GETTEXTMETRIC, 0, 0L);
	
	GetClientRect(hWndText, &aRect);

	ScreenRows = (INT) (aRect.bottom-aRect.top) / (tm->tmHeight+tm->tmExternalLeading);
	ScreenCols = (INT) (aRect.right-aRect.left) / (tm->tmAveCharWidth);
    }

    writeRegInt(RKEY_SCREENROWS, ScreenRows);
    writeRegInt(RKEY_SCREENCOLS, ScreenCols);
    
  
    { LOGFONT *LogFontPtr;
      HDC      hDC;
      INT      FontSize;

      LogFontPtr = (LOGFONT*) SendMessage (hWndText, WM_GETLOGFONT, 0, 0L);

      hDC = GetDC(hWndText);
      FontSize = -MulDiv(LogFontPtr->lfHeight, 72, GetDeviceCaps(hDC, LOGPIXELSY));
      ReleaseDC(hWndText, hDC);

      writeRegInt(RKEY_SCREENFONTSIZE, FontSize);
      writeRegInt(RKEY_SCREENFONTWEIGHT, LogFontPtr->lfWeight);
      writeRegString(RKEY_SCREENFONTNAME, LogFontPtr->lfFaceName);
    }

    {
      INT 	DialogFontSize;
      CHAR	DialogFontName[256];

      GetFromRegistryDialogFont(DialogFontName, 256, &DialogFontSize);

      writeRegInt(RKEY_DIALOGSFONTSIZE, DialogFontSize);
      writeRegString(RKEY_DIALOGSFONTNAME, DialogFontName);

    }

  
    SaveToRegistryWinPos();
    SaveToRegistryMenus();
    SaveToRegistryWorkingDir();
}

/* save current working dir */
static VOID local SaveToRegistryWorkingDir(VOID)
{
  CHAR Path[_MAX_PATH];
  CHAR Buffer[_MAX_PATH];

  _getcwd(Path, _MAX_PATH);
  wsprintf(Buffer, "%s\\", Path);
  writeRegString(RKEY_LASTPATH, Buffer);
}

/* Save Windows current position to registry */
static VOID local SaveToRegistryWinPos(VOID)
{
  writeRegInt(RKEY_POSX, FrameWinX);
  writeRegInt(RKEY_POSY, FrameWinY);
}


/* save file names in menus */
static VOID local SaveToRegistryMenus()
{

  SaveToRegistryFileNamesMenu(&FilesMenu, RKEY_FILESMENU);
  SaveToRegistryFileNamesMenu(&EditMenu, RKEY_EDITSMENU);

}


/* --------------------------------------------------------------------------
 * Evaluator code
 * ------------------------------------------------------------------------*/

Bool InAutoReloadFiles = FALSE;	/* TRUE =>loading files before eval*/
Bool autoLoadFiles     = FALSE; /* TRUE => automatically reloaded modified files */

#if USE_THREADS
Void  stopEvaluatorThread Args((Void));
static DWORD local evaluatorThreadBody  Args((LPDWORD));

static HANDLE  evaluatorThread=NULL;
static DWORD   evaluatorThreadId;
static Bool    evaluatorThreadRunning = FALSE;
static jmp_buf goToEvaluator;

Void loopInBackground (Void) { 
    MSG msg;

    /* WaitForSingleObject(evaluatorThread, INFINITE); */
    while ( evaluatorThreadRunning && GetMessage(&msg, NULL, 0, 0) ) {
      if (!TranslateAccelerator(hWndMain, hAccelTable, &msg)) {
         TranslateMessage(&msg);
         DispatchMessage(&msg);
      }
    }
}

Void stopEvaluatorThread(Void) {

    if(evaluatorThreadRunning){

      if(GetCurrentThreadId() != evaluatorThreadId) {
       MessageBox(NULL, "stopEvaluatorThread executed by main thread !!!","Error", MB_OK);
      }

      evaluatorThreadRunning = FALSE;
      SuspendThread(evaluatorThread);
      /* stop here until resumed */
      longjmp(goToEvaluator,1);
    }
}

static DWORD local evaluatorThreadBody(LPDWORD notUsed) {

    Int evaluatorNumber = setjmp(goToEvaluator);

#if defined(_MSC_VER) && !defined(_MANAGED)
    /* Under Win32 (when compiled with MSVC), we specially
     * catch and handle SEH stack overflows.
     */
    __try {
#endif
    evaluator(findEvalModule());
    stopEvaluatorThread();

#if defined(_MSC_VER) && !defined(_MANAGED)
    } __except ( ((GetExceptionCode() == EXCEPTION_STACK_OVERFLOW) ? 
		  EXCEPTION_EXECUTE_HANDLER : 
		  EXCEPTION_CONTINUE_SEARCH) ) {
	/* Closely based on sample code in Nov 1999 Dr GUI MSDN column */
	char* stackPtr;
	static SYSTEM_INFO si;
	static MEMORY_BASIC_INFORMATION mi;
	static DWORD protect;
 
      /* get at the current stack pointer */
      _asm mov stackPtr, esp;

      /* query for page size + VM info for the allocation chunk we're currently in. */
      GetSystemInfo(&si);
      VirtualQuery(stackPtr, &mi, sizeof(mi));

      /* Abandon the C stack and, most importantly, re-insert
         the page guard bit. Do this on the page above the
	 current one, not the one where the exception was raised. */
      stackPtr = (LPBYTE) (mi.BaseAddress) - si.dwPageSize;
      if ( VirtualFree(mi.AllocationBase,
		       (LPBYTE)stackPtr - (LPBYTE) mi.AllocationBase, 
		       MEM_DECOMMIT) &&
	   VirtualProtect(stackPtr, si.dwPageSize, 
			  PAGE_GUARD | PAGE_READWRITE, &protect) ) {

	  /* careful not to do a garbage collection here (as it may have caused the overflow). */
          ERRTEXT "ERROR - C stack overflow"
          /* EEND does a longjmp back to a sane state. */
          EEND;
      } else {
	  fatal("C stack overflow; unable to recover.");
      }
    }
#endif
    /* not reached*/
    return 0;
}

Void startEvaluatorThread(Void) {
  if (!evaluatorThread) {
    /* Note: I'm assuming that the reason why _beginthreadex() isn't
     * used is that there's no need to..?
     */
      evaluatorThread = CreateThread(NULL,
                                   0,
                                   (LPTHREAD_START_ROUTINE)evaluatorThreadBody,
                                   NULL,
                                   CREATE_SUSPENDED,
                                   &evaluatorThreadId);
  }
  evaluatorThreadRunning = TRUE;
  ResumeThread(evaluatorThread);
}

#endif /* USE_THREADS */

/* --------------------------------------------------------------------------
 * Other functions
 * ------------------------------------------------------------------------*/

/* Passes a command to Hugs interpreter */
static Void local SetInterpreterCommand(LPCSTR fmt, ...) {
  va_list ap;			 /* pointer into argument list		 */
  static char msg[1024];
  String s;

  va_start(ap, fmt);		 /* make ap point to first arg after fmt */
  vsprintf(msg, fmt, ap);

  for(s=msg; *s; ++s) {
    if (*s == '\n') {
      SendMessage(hWndText, WM_CHAR, (WPARAM) VK_RETURN, 0L);
    } else {
      SendMessage(hWndText, WM_CHAR, (WPARAM) *s, 0L);
    }
  }

  va_end(ap);	/* clean up */
}

/* Open an html document */
static VOID OpenHtml(LPSTR s)
{
  ShellExecute(hWndMain, NULL, s, NULL, NULL, SW_SHOWNORMAL);
}


/* Open an html document. Search the document in docs dir */
static VOID OpenHtmlFromDocs(LPSTR s) 
{
  CHAR DocsFullPath[_MAX_PATH];
  char* HtmlFullPath = NULL;

  if ( GetFromRegistryDocPath(DocsFullPath, _MAX_PATH) ) {
      HtmlFullPath = alloca(strlen(DocsFullPath) + strlen(s) + 5);
      if (HtmlFullPath) {
	  wsprintf(HtmlFullPath, "%s\\%s", DocsFullPath,s);
	  OpenHtml(HtmlFullPath);
      }
  }
}

/* expands characters like \ to \\ in a file name */
static LPSTR local ExpandFileName(LPSTR what)
{
  static CHAR Expanded[2048];

  if (*what == '\"') {
    strcpy(Expanded, what);
  } 
  else { 
    LPSTR where, t, unlex;

    strcpy(Expanded,"\"");
	
    for(where = &Expanded[1],t=what; *t; ++t) {
      unlex = unlexChar(*t,'"');
      wsprintf(where, "%s", unlexChar(*t,'"'));
      where += strlen(unlex);
    }
    wsprintf(where, "\"%c", '\0');
  }
  return Expanded;
}
