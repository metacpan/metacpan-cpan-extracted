/* --------------------------------------------------------------------------
 * Error handling support functions
 *
 * The Hugs 98 system is Copyright (c) Mark P Jones, Alastair Reid, the
 * Yale Haskell Group, and the OGI School of Science & Engineering at OHSU,
 * 1994-2003, All rights reserved.  It is distributed as free software under
 * the license in the file "License", which is included in the distribution.
 *
 * ------------------------------------------------------------------------*/
#include "prelude.h"
#include "storage.h"
#include "connect.h"
#include "errors.h"
#include "output.h"
#include "opts.h"
#include "goal.h"
#include "evaluator.h" /* everybody() proto only */
#include <setjmp.h>

jmp_buf catch_error;          /* jump buffer for error trapping  */

/* --------------------------------------------------------------------------
 * Error handling:
 * ------------------------------------------------------------------------*/

Void stopAnyPrinting() {  /* terminate printing of expression,*/
    if (printing) {       /* after successful termination or  */
	printing = FALSE; /* runtime error (e.g. interrupt)   */
	Putchar('\n');
	if (showStats) {
#define plural(v)   v, (v==1?"":"s")
#if HUGS_FOR_WINDOWS
	    { INT svColor = SetForeColor(BLUE);
#endif
	    Printf("(%lu reduction%s, ",plural(numReductions));
	    Printf("%lu cell%s",plural(numCells));
	    if (numGcs>0)
		Printf(", %u garbage collection%s",plural(numGcs));
	    Printf(")\n");
#if HUGS_FOR_WINDOWS
	    SetForeColor(svColor); }
#endif
#undef plural
	}
#if OBSERVATIONS
        printObserve(ALLTAGS);
        if (obsCount) {
            ERRMSG(0) "Internal: observation sanity counter > 0\n"
	    EEND;
        }
        if (showStats){
            Int n = countObserve();
            if (n > 0)
                Printf("%d observations recorded\n", n);
        }
#endif
	FlushStdout();
	garbageCollect();
    }
}

Void errHead(l)                        /* print start of error message     */
Int l; {
    failed();                          /* failed to reach target ...       */
    stopAnyPrinting();
    FPrintf(errorStream,"ERROR");

    /*
     * Encapsulating the filename portion inside of d-quotes makes it
     * a tad easier for an Emacs-mode to decipher the location of the error.
     * -- sof 9/01.
     */
    if (scriptFile) {
 	FPrintf(errorStream," \"%s\"",scriptFile);
	setLastEdit(scriptFile,l);
 	if (l) FPrintf(errorStream,":%d",l);
	scriptFile = 0;
    }
    FPrintf(errorStream," - ");
    FFlush(errorStream);
}

Void errFail() {                        /* terminate error message and     */
    Putc('\n',errorStream);             /* produce exception to return to  */
    FFlush(errorStream);                /* main command loop               */
#if USE_THREADS
    stopEvaluatorThread();
#endif /* USE_THREADS */
    longjmp(catch_error,1);
}

Void errAbort() {                       /* altern. form of error handling  */
    failed();                           /* used when suitable error message*/
    stopAnyPrinting();                  /* has already been printed        */
    errFail();
}

Void internal(msg)                      /* handle internal error           */
String msg; {
#if HUGS_FOR_WINDOWS
    char buf[300];
    wsprintf(buf,"INTERNAL ERROR: %s",msg);
    MessageBox(hWndMain, buf, appName, MB_ICONHAND | MB_OK);
#endif
    failed();
    stopAnyPrinting();
    Printf("INTERNAL ERROR: %s\n",msg);
    FlushStdout();
#if USE_THREADS
    stopEvaluatorThread();
#endif /* USE_THREADS */
    longjmp(catch_error,1);
}

Void fatal(msg)                         /* handle fatal error              */
String msg; {
#if HUGS_FOR_WINDOWS
    char buf[300];
    wsprintf(buf,"FATAL ERROR: %s",msg);
    MessageBox(hWndMain, buf, appName, MB_ICONHAND | MB_OK);
#endif
    FlushStdout();
    Printf("\nFATAL ERROR: %s\n",msg);
    everybody(EXIT);
    exit(1);
}

/* --------------------------------------------------------------------------
 * Break interrupt handler:
 * ------------------------------------------------------------------------*/
sigHandler(breakHandler) {              /* respond to break interrupt      */
#if HUGS_FOR_WINDOWS
#if USE_THREADS
    MessageBox(hWndMain, "Interrupted!", appName, MB_ICONSTOP | MB_OK);
#else
    MessageBox(GetFocus(), "Interrupted!", appName, MB_ICONSTOP | MB_OK);
#endif
#endif
#if HUGS_FOR_WINDOWS
    FPrintf(errorStream,"{Interrupted!}\n");
#else
    Hilite();
    Printf("{Interrupted!}\n");
    Lolite();
#endif
    breakOn(TRUE);  /* reinstall signal handler - redundant on BSD systems */
		    /* but essential on POSIX (and other?) systems         */
    everybody(BREAK);
    failed();
    stopAnyPrinting();
    FlushStdout();
    clearerr(stdin);
#if USE_THREADS
    stopEvaluatorThread();
#endif /* USE_THREADS */
    longjmp(catch_error,1);
    sigResume;/*NOTREACHED*/
}

/* --------------------------------------------------------------------------
 * Compiler output
 * We can redirect compiler output (prompts, error messages, etc) by
 * tweaking these functions.
 * ------------------------------------------------------------------------*/

#if REDIRECT_OUTPUT && !HUGS_FOR_WINDOWS
static Bool disableOutput = FALSE;      /* redirect output to buffer?      */

#if HAVE_STDARG_H
#include <stdarg.h>
#else
#include <varargs.h>
#endif

/* ----------------------------------------------------------------------- */

#define BufferSize 10000	      /* size of redirected output buffer  */

typedef struct _HugsStream {
    char buffer[BufferSize];          /* buffer for redirected output      */
    Int  next;                        /* next space in buffer              */
} HugsStream;

static Void   local vBufferedPrintf  Args((HugsStream*, const char*, va_list));
static Void   local bufferedPutchar  Args((HugsStream*, Char));
static String local bufferClear      Args((HugsStream *stream));

static Void local vBufferedPrintf(stream, fmt, ap)
HugsStream* stream;
const char* fmt;
va_list     ap; {
    Int spaceLeft = BufferSize - stream->next;
    char* p = &stream->buffer[stream->next];
    Int charsAdded = vsnprintf(p, spaceLeft, fmt, ap);
    if (0 <= charsAdded && charsAdded < spaceLeft)
	stream->next += charsAdded;
#if 1 /* we can either buffer the first n chars or buffer the last n chars */
    else
	stream->next = 0;
#endif
}

static Void local bufferedPutchar(stream, c)
HugsStream *stream;
Char        c; {
    if (BufferSize - stream->next >= 2) {
	stream->buffer[stream->next++] = c;
	stream->buffer[stream->next] = '\0';
    }
}

static String local bufferClear(stream)
HugsStream *stream; {
    if (stream->next == 0) {
	return "";
    } else {
	stream->next = 0;
	return stream->buffer;
    }
}

/* ----------------------------------------------------------------------- */

static HugsStream outputStream;
/* ADR note:
 * We rely on standard C semantics to initialise outputStream.next to 0.
 */

Void hugsEnableOutput(f)
Bool f; {
    disableOutput = !f;
}

String hugsClearOutputBuffer() {
    return bufferClear(&outputStream);
}

#if HAVE_STDARG_H
Void hugsPrintf(const char *fmt, ...) {
    va_list ap;                    /* pointer into argument list           */
    va_start(ap, fmt);             /* make ap point to first arg after fmt */
    if (!disableOutput) {
	vprintf(fmt, ap);
    } else {
	vBufferedPrintf(&outputStream, fmt, ap);
    }
    va_end(ap);                    /* clean up                             */
}
#else
Void hugsPrintf(fmt, va_alist)
const char *fmt;
va_dcl {
    va_list ap;                    /* pointer into argument list           */
    va_start(ap);                  /* make ap point to first arg after fmt */
    if (!disableOutput) {
	vprintf(fmt, ap);
    } else {
	vBufferedPrintf(&outputStream, fmt, ap);
    }
    va_end(ap);                    /* clean up                             */
}
#endif

Void hugsPutchar(c)
int c; {
    if (!disableOutput) {
	putchar(c);
    } else {
	bufferedPutchar(&outputStream, c);
    }
}

Void hugsFlushStdout() {
    if (!disableOutput) {
	fflush(stdout);
    }
}

Void hugsFFlush(fp)
FILE* fp; {
    if (!disableOutput) {
	fflush(fp);
    }
}

#if HAVE_STDARG_H
Void hugsFPrintf(FILE *fp, const char* fmt, ...) {
    va_list ap;
    va_start(ap, fmt);
    if (!disableOutput) {
	vfprintf(fp, fmt, ap);
    } else {
	vBufferedPrintf(&outputStream, fmt, ap);
    }
    va_end(ap);
}
#else
Void hugsFPrintf(FILE *fp, const char* fmt, va_list)
FILE* fp;
const char* fmt;
va_dcl {
    va_list ap;
    va_start(ap);
    if (!disableOutput) {
	vfprintf(fp, fmt, ap);
    } else {
	vBufferedPrintf(&outputStream, fmt, ap);
    }
    va_end(ap);
}
#endif

Void hugsPutc(c, fp)
int   c;
FILE* fp; {
    if (!disableOutput) {
	putc(c,fp);
    } else {
	bufferedPutchar(&outputStream, c);
    }
}

#endif /* REDIRECT_OUTPUT && !HUGS_FOR_WINDOWS */
