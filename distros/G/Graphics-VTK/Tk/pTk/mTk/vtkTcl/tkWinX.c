/*
 * tkWinX.c --
 *
 *	This file contains Windows emulation procedures for X routines.
 *
 * Copyright (c) 1995-1996 Sun Microsystems, Inc.
 * Copyright (c) 1994 Software Research Associates, Inc.
 * Copyright (c) 1998 by Scriptics Corporation.
 *
 * See the file "license.terms" for information on usage and redistribution
 * of this file, and for a DISCLAIMER OF ALL WARRANTIES.
 *
 * RCS: @(#) $Id: tkWinX.c,v 1.1 2002/04/05 03:05:51 A0182636 Exp $
 */

/* This portion of the tkWinX.c file from the Tk distribution is included in the PerlVTK distribution
   because the function TkWinChildProc is not exported by perlTk
*/ 

#include "vtkTkport.h"
extern "C"{
#include "tkInt.h"
#include "tkWinInt.h"
}
#include "tkVMacro.h"

/*
 * The zmouse.h file includes the definition for WM_MOUSEWHEEL.
 */

#ifndef __BORLANDC__
#include <zmouse.h>
#endif
#ifndef WM_MOUSEWHEEL
#define WM_MOUSEWHEEL (WM_MOUSELAST+1)  // message that will be supported
                                        // by the OS
#endif


/*
 * Definitions of extern variables supplied by this file.
 */


/*
 * Declarations of static variables used in this file.
 */

static HINSTANCE tkInstance = (HINSTANCE) NULL;
				/* Global application instance handle. */
static TkDisplay *winDisplay;	/* Display that represents Windows screen. */
static char winScreenName[] = ":0";
				/* Default name of windows display. */
static WNDCLASS childClass;	/* Window class for child windows. */
static int childClassInitialized = 0; /* Registered child class? */

/*
 * Forward declarations of procedures used in this file.
 */

#ifdef __CYGWIN__
static void		DisplayFileProc _ANSI_ARGS_((ClientData clientData,
			    int flags));
#endif
static void		GenerateXEvent _ANSI_ARGS_((HWND hwnd, UINT message,
			    WPARAM wParam, LPARAM lParam));
static unsigned int	GetState _ANSI_ARGS_((UINT message, WPARAM wParam,
			    LPARAM lParam));
static void 		GetTranslatedKey _ANSI_ARGS_((XKeyEvent *xkey));


/*
 *----------------------------------------------------------------------
 *
 * Tk_GetHINSTANCE --
 *
 *	Retrieves the global instance handle used by the Tk library.
 *
 * Results:
 *	Returns the global instance handle.
 *
 * Side effects:
 *	None.
 *
 *----------------------------------------------------------------------
 */

static BOOL CALLBACK
FindMyConsole( HWND win, LPARAM arg )
{
 DWORD mypid = *((DWORD *) arg);
 DWORD pid;
 GetWindowThreadProcessId(win,&pid);
 if (pid == mypid)
  {
   ShowWindow(win,SW_SHOWMINNOACTIVE);
  }
 return TRUE;
}

/*
 *----------------------------------------------------------------------
/*
 *----------------------------------------------------------------------
 *
 * TkWinChildProc --
 *
 *	Callback from Windows whenever an event occurs on a child
 *	window.
 *
 * Results:
 *	Standard Windows return value.
 *
 * Side effects:
 *	May process events off the Tk event queue.
 *
 *----------------------------------------------------------------------
 */

LRESULT CALLBACK
TkWinChildProc(HWND hwnd, UINT message,WPARAM wParam,LPARAM lParam)
{
    LRESULT result;

    switch (message) {
	case WM_SETCURSOR:
	    /*
	     * Short circuit the WM_SETCURSOR message since we set
	     * the cursor elsewhere.
	     */

	    result = TRUE;
	    break;

	case WM_CREATE:
	case WM_ERASEBKGND:
	case WM_WINDOWPOSCHANGED:
	    result = 0;
	    break;

	case WM_PAINT:
	    GenerateXEvent(hwnd, message, wParam, lParam);
	    result = DefWindowProc(hwnd, message, wParam, lParam);
	    break;

        case TK_CLAIMFOCUS:
	case TK_GEOMETRYREQ:
	case TK_ATTACHWINDOW:
	case TK_DETACHWINDOW:
	    result =  TkWinEmbeddedEventProc(hwnd, message, wParam, lParam);
	    break;

	default:
	    if (!Tk_TranslateWinEvent(hwnd, message, wParam, lParam,
		    &result)) {
		result = DefWindowProc(hwnd, message, wParam, lParam);
	    }
	    break;
    }

    /*
     * Handle any newly queued events before returning control to Windows.
     */

    Tcl_ServiceAll();
    return result;
}

/*
 *----------------------------------------------------------------------
 *
 * GenerateXEvent --
 *
 *	This routine generates an X event from the corresponding
 * 	Windows event.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	Queues one or more X events.
 *
 *----------------------------------------------------------------------
 */

static void
GenerateXEvent(HWND hwnd, UINT message,WPARAM wParam,LPARAM lParam)
{
    XEvent event;
    TkWindow *winPtr = (TkWindow *)Tk_HWNDToWindow(hwnd);
    if (!winPtr || winPtr->window == None) {
	return;
    }

    event.xany.serial = winPtr->display->request++;
    event.xany.send_event = False;
    event.xany.display = winPtr->display;
    event.xany.window = winPtr->window;

    switch (message) {
	case WM_PAINT: {
	    PAINTSTRUCT ps;

	    event.type = Expose;
	    BeginPaint(hwnd, &ps);
	    event.xexpose.x = ps.rcPaint.left;
	    event.xexpose.y = ps.rcPaint.top;
#ifdef __OPEN32__
	    event.xexpose.width = max(ps.rcPaint.right - ps.rcPaint.left,0);
	    event.xexpose.height = max(ps.rcPaint.bottom - ps.rcPaint.top,0);
#else
	    event.xexpose.width = ps.rcPaint.right - ps.rcPaint.left;
	    event.xexpose.height = ps.rcPaint.bottom - ps.rcPaint.top;
#endif
	    EndPaint(hwnd, &ps);
	    event.xexpose.count = 0;
	    break;
	}

	case WM_CLOSE:
	    event.type = ClientMessage;
	    event.xclient.message_type =
		Tk_InternAtom((Tk_Window) winPtr, "WM_PROTOCOLS");
	    event.xclient.format = 32;
	    event.xclient.data.l[0] =
		Tk_InternAtom((Tk_Window) winPtr, "WM_DELETE_WINDOW");
	    break;

	case WM_SETFOCUS:
	case WM_KILLFOCUS: {
	    TkWindow *otherWinPtr = (TkWindow *)Tk_HWNDToWindow((HWND) wParam);
	
	    /*
	     * Compare toplevel windows to avoid reporting focus
	     * changes within the same toplevel.
	     */

	    while (!(winPtr->flags & TK_TOP_LEVEL)) {
		winPtr = winPtr->parentPtr;
		if (winPtr == NULL) {
		    return;
		}
	    }
	    while (otherWinPtr && !(otherWinPtr->flags & TK_TOP_LEVEL)) {
		otherWinPtr = otherWinPtr->parentPtr;
	    }
	    if (otherWinPtr == winPtr) {
		return;
	    }

	    event.xany.window = winPtr->window;
	    event.type = (message == WM_SETFOCUS) ? FocusIn : FocusOut;
	    event.xfocus.mode = NotifyNormal;
	    event.xfocus.detail = NotifyNonlinear;
	    break;
	}

	case WM_DESTROYCLIPBOARD:
	    event.type = SelectionClear;
	    event.xselectionclear.selection =
		Tk_InternAtom((Tk_Window)winPtr, "CLIPBOARD");
	    event.xselectionclear.time = TkpGetMS();
	    break;
	
	case WM_MOUSEWHEEL:
	    /*
	     * The mouse wheel event is closer to a key event than a
	     * mouse event in that the message is sent to the window
	     * that has focus.
	     */
	
	case WM_CHAR:
	case WM_SYSKEYDOWN:
	case WM_SYSKEYUP:
	case WM_KEYDOWN:
	case WM_KEYUP: {
	    unsigned int state = GetState(message, wParam, lParam);
	    Time time = TkpGetMS();
	    POINT clientPoint;
	    POINTS rootPoint;	/* Note: POINT and POINTS are different */
	    DWORD msgPos;

	    /*
	     * Compute the screen and window coordinates of the event.
	     */
	
	    msgPos = GetMessagePos();
	    rootPoint = MAKEPOINTS(msgPos);
	    clientPoint.x = rootPoint.x;
	    clientPoint.y = rootPoint.y;
	    ScreenToClient(hwnd, &clientPoint);

	    /*
	     * Set up the common event fields.
	     */

	    event.xbutton.root = RootWindow(winPtr->display,
		    winPtr->screenNum);
	    event.xbutton.subwindow = None;
	    event.xbutton.x = clientPoint.x;
	    event.xbutton.y = clientPoint.y;
	    event.xbutton.x_root = rootPoint.x;
	    event.xbutton.y_root = rootPoint.y;
	    event.xbutton.state = state;
	    event.xbutton.time = time;
	    event.xbutton.same_screen = True;

	    /*
	     * Now set up event specific fields.
	     */

	    switch (message) {
		case WM_MOUSEWHEEL:
		    /*
		     * We have invented a new X event type to handle
		     * this event.  It still uses the KeyPress struct.
		     * However, the keycode field has been overloaded
		     * to hold the zDelta of the wheel.
		     */
		
		    event.type = MouseWheelEvent;
		    event.xany.send_event = -1;
		    event.xkey.keycode = (short) HIWORD(wParam);
		    break;
		case WM_SYSKEYDOWN:
		case WM_KEYDOWN:
		    /*
		     * Check for translated characters in the event queue.
		     * Setting xany.send_event to -1 indicates to the
		     * Windows implementation of XLookupString that this
		     * event was generated by windows and that the Windows
		     * extension xkey.trans_chars is filled with the
		     * characters that came from the TranslateMessage
		     * call.  If it is not -1, xkey.keycode is the
		     * virtual key being sent programmatically by generic
		     * code.
		     */

#ifdef __OPEN32__
		    StashedKey = 0;
#endif
		    event.type = KeyPress;
		    event.xany.send_event = -1;
		    event.xkey.keycode = wParam;
		    GetTranslatedKey(&event.xkey);
		    break;

		case WM_SYSKEYUP:
		case WM_KEYUP:
		    /*
		     * We don't check for translated characters on keyup
		     * because Tk won't know what to do with them.  Instead, we
		     * wait for the WM_CHAR messages which will follow.
		     */
#ifdef __OPEN32__
		    StashedKey = 0;
#endif
		    event.type = KeyRelease;
		    event.xkey.keycode = wParam;
		    event.xkey.nchars = 0;
		    break;

		case WM_CHAR:
		    /*
		     * Synthesize both a KeyPress and a KeyRelease.
		     */

#ifdef __OPEN32__
		    StashedKey = (char) lParam;
#endif
		    event.type = KeyPress;
		    event.xany.send_event = -1;
		    event.xkey.keycode = 0;
		    event.xkey.nchars = 1;
		    event.xkey.trans_chars[0] = (char) wParam;
		    Tk_QueueWindowEvent(&event, TCL_QUEUE_TAIL);
		    event.type = KeyRelease;
		    break;
	    }
	    break;
	}

	default:
	    return;
    }
    Tk_QueueWindowEvent(&event, TCL_QUEUE_TAIL);
}

/*
 *----------------------------------------------------------------------
 *
 * GetState --
 *
 *	This function constructs a state mask for the mouse buttons
 *	and modifier keys as they were before the event occured.
 *
 * Results:
 *	Returns a composite value of all the modifier and button state
 *	flags that were set at the time the event occurred.
 *
 * Side effects:
 *	None.
 *
 *----------------------------------------------------------------------
 */

static unsigned int
GetState(UINT message,WPARAM wParam, LPARAM lParam)
 //   UINT message;		/* Win32 message type */
 //   WPARAM wParam;		/* wParam of message, used if key message */
 //   LPARAM lParam;		/* lParam of message, used if key message */
{
    int mask;
    int prevState;		/* 1 if key was previously down */
    unsigned int state = TkWinGetModifierState();

    /*
     * If the event is a key press or release, we check for modifier
     * keys so we can report the state of the world before the event.
     */

    if (message == WM_SYSKEYDOWN || message == WM_KEYDOWN
	    || message == WM_SYSKEYUP || message == WM_KEYUP) {
	mask = 0;
	prevState = HIWORD(lParam) & KF_REPEAT;
	switch(wParam) {
	    case VK_SHIFT:
		mask = ShiftMask;
		break;
	    case VK_CONTROL:
		mask = ControlMask;
		break;
	    case VK_MENU:
		mask = Mod2Mask;
		break;
	    case VK_CAPITAL:
		if (message == WM_SYSKEYDOWN || message == WM_KEYDOWN) {
		    mask = LockMask;
		    prevState = ((state & mask) ^ prevState) ? 0 : 1;
		}
		break;
	    case VK_NUMLOCK:
		if (message == WM_SYSKEYDOWN || message == WM_KEYDOWN) {
		    mask = Mod1Mask;
		    prevState = ((state & mask) ^ prevState) ? 0 : 1;
		}
		break;
	    case VK_SCROLL:
		if (message == WM_SYSKEYDOWN || message == WM_KEYDOWN) {
		    mask = Mod3Mask;
		    prevState = ((state & mask) ^ prevState) ? 0 : 1;
		}
		break;
	}
	if (prevState) {
	    state |= mask;
	} else {
	    state &= ~mask;
	}
    }
    return state;
}

/*
 *----------------------------------------------------------------------
 *
 * GetTranslatedKey --
 *
 *	Retrieves WM_CHAR messages that are placed on the system queue
 *	by the TranslateMessage system call and places them in the
 *	given KeyPress event.
 *
 * Results:
 *	Sets the trans_chars and nchars member of the key event.
 *
 * Side effects:
 *	Removes any WM_CHAR messages waiting on the top of the system
 *	event queue.
 *
 *----------------------------------------------------------------------
 */

static void
GetTranslatedKey(XKeyEvent * xkey)
{
    MSG msg;

    xkey->nchars = 0;

    while (xkey->nchars < XMaxTransChars
	    && PeekMessage(&msg, NULL, 0, 0, PM_NOREMOVE)) {
	if ((msg.message == WM_CHAR) || (msg.message == WM_SYSCHAR)) {
	    xkey->trans_chars[xkey->nchars] = (char) msg.wParam;
#ifdef __OPEN32__
	    StashedKey = (char) msg.wParam;
#endif
	    xkey->nchars++;
	    GetMessage(&msg, NULL, 0, 0);

	    /*
	     * If this is a normal character message, we may need to strip
	     * off the Alt modifier (e.g. Alt-digits).  Note that we don't
	     * want to do this for system messages, because those were
	     * presumably generated as an Alt-char sequence (e.g. accelerator
	     * keys).
	     */

	    if ((msg.message == WM_CHAR) && (msg.lParam & 0x20000000)) {
		xkey->state = 0;
	    }
	} else {
	    break;
	}
    }
}


/*
 *----------------------------------------------------------------------
 *
 * TkpGetMS --
 *
 *	Return a relative time in milliseconds.  It doesn't matter
 *	when the epoch was.
 *
 * Results:
 *	Number of milliseconds.
 *
 * Side effects:
 *	None.
 *
 *----------------------------------------------------------------------
 */

unsigned long
TkpGetMS()
{
    return GetCurrentTime();
}
