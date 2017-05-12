/*
 * term.c - deal with termcap, and unix terminal mode settings
 *
 * Pace Willisson, 1983
 *
 * Copyright 1987, 1988, 1989, 1992, 1993, Geoff Kuenning, Granada Hills, CA
 * All rights reserved.
 *
 * see COPYRIGHT file for more information.
 */



/* new */
#ifndef TCSETAW
#define TCSETAW               0x5407
#endif

/* new */
#ifndef TCGETA
#define TCGETA                0x5405
#endif

#include <string.h>
#include <stdlib.h>
#include <unistd.h>


#include "jsconfig.h"
#include "jspell.h"
#include "proto.h"
#include "msgs.h"
#include "myterm.h"

#ifndef NOCURSES
#include <termios.h>
#include <curses.h>
#include <sys/ioctl.h>
#endif

#include <signal.h>


static int          putch(int c);
SIGNAL_TYPE        done(int signo);
#ifdef SIGTSTP
static SIGNAL_TYPE onstop(int signo);
#endif /* SIGTSTP */
int shellescape(char * buf);


/*---------------------------------------------------------------------------*/

void inverse(void)
{
#ifndef NOCURSES
    tputs(so, 10, putch);
#endif
}

/*---------------------------------------------------------------------------*/

void normal(void)
{
#ifndef NOCURSES
    tputs(se, 10, putch);
#endif
}

/*---------------------------------------------------------------------------*/

void erase_EOL(void)
{
#ifndef NOCURSES
    tputs(ce, 10, putch);
#endif
}

/*---------------------------------------------------------------------------*/

void curs_left(void)
{
#ifndef NOCURSES
    tputs(le, 10, putch);
#endif
}

/*---------------------------------------------------------------------------*/

void curs_right(void)
{
#ifndef NOCURSES
    tputs(nd, 10, putch);
#endif
}

/*---------------------------------------------------------------------------*/

void backup(void)
{
#ifndef NOCURSES
    if (BC)
	tputs(BC, 1, putch);
    else
	putchar('\b');
#endif
}

/*---------------------------------------------------------------------------*/

static int putch(int c)
{
#ifndef NOCURSES
   return putchar(c);
#endif
}

/*---------------------------------------------------------------------------*/

#ifndef NOCURSES
static struct termios      sbuf;
static struct termios      osbuf;
#endif

static int                termchanged = 0;
static SIGNAL_TYPE        (*oldint) ();
static SIGNAL_TYPE        (*oldterm) ();
#ifdef SIGTSTP
static SIGNAL_TYPE        (*oldttin) ();
static SIGNAL_TYPE        (*oldttou) ();
static SIGNAL_TYPE        (*oldtstp) ();
#endif

/*---------------------------------------------------------------------------*/

void terminit(void)
{
#ifndef NOCURSES
#ifdef TIOCPGRP
    int tpgrp;
#else
#ifdef TIOCGPGRP
    int tpgrp;
#endif
#endif
#ifdef TIOCGWINSZ
    struct winsize      wsize;
#endif /* TIOCGWINSZ */

    tgetent(termcap, getenv("TERM"));
    termptr = termstr;
    BC = tgetstr("bc", &termptr);
    cd = tgetstr("cd", &termptr);        /* clear to end of screen */
    ce = tgetstr("ce", &termptr);        /* clear to end of line */
    cl = tgetstr("cl", &termptr);        /* clear screen and cursor home */
    cm = tgetstr("cm", &termptr);        /* cursor move */
    ho = tgetstr("ho", &termptr);        /* cursor home */
    le = tgetstr("nd", &termptr);        /* cursor left one character */
    nd = tgetstr("nd", &termptr);        /* cursor right one character */
    so = tgetstr("so", &termptr);        /* inverse video on */
    se = tgetstr("se", &termptr);        /* inverse video off */

    kl = tgetstr("kl", &termptr);        /* cursor left key */
    kr = tgetstr("kr", &termptr);        /* cursor right key */
    ku = tgetstr("ku", &termptr);        /* cursor up key */
    kd = tgetstr("kd", &termptr);        /* cursor down key */
    kP = tgetstr("kP", &termptr);        /* cursor pgup key */
    kN = tgetstr("kN", &termptr);        /* cursor pgdown key */
    kh = tgetstr("kh", &termptr);        /* cursor home key */
    kH = tgetstr("kH", &termptr);        /* cursor end key */
    kI = tgetstr("kI", &termptr);        /* insert key */  /* NOT STANDARD */
    kD = tgetstr("kD", &termptr);        /* delete key */

    if ((sg = tgetnum("sg")) < 0)        /* space taken by so/se */
       sg = 0;
    ti = tgetstr("ti", &termptr);        /* terminal initialization */
    te = tgetstr("te", &termptr);        /* terminal termination */
    co = tgetnum("co");                  /* Number of columns */
    li = tgetnum("li");                  /* Number of lines */
#ifdef TIOCGWINSZ
    if (ioctl(0, TIOCGWINSZ, (char *) &wsize) >= 0) {
       if (wsize.ws_col != 0)
          co = wsize.ws_col;
       if (wsize.ws_row != 0)
          li = wsize.ws_row;
    }
#endif /* TIOCGWINSZ */
    /*
     * Let the variables "LINES" and "COLUMNS" override the termcap
     * entry.  Technically, this is a terminfo-ism, but I think the
     * vast majority of users will find it pretty handy.
     */
    if (getenv("COLUMNS") != NULL)
       co = atoi (getenv ("COLUMNS"));
    if (getenv("LINES") != NULL)
       li = atoi(getenv("LINES"));
#if MAX_SCREEN_SIZE > 0
    if (li > MAX_SCREEN_SIZE)
       li = MAX_SCREEN_SIZE;
#endif /* MAX_SCREEN_SIZE > 0 */
#if MAXCONTEXT == MINCONTEXT
    contextsize = MINCONTEXT;
#else /* MAXCONTEXT == MINCONTEXT */
    if (contextsize == 0)
#ifdef CONTEXTROUNDUP
       contextsize = (li * CONTEXTPCT + 99) / 100;
#else /* CONTEXTROUNDUP */
       contextsize = (li * CONTEXTPCT) / 100;
#endif /* CONTEXTROUNDUP */
    if (contextsize > MAXCONTEXT)
       contextsize = MAXCONTEXT;
    else if (contextsize < MINCONTEXT)
        contextsize = MINCONTEXT;
#endif /* MAX_CONTEXT == MIN_CONTEXT */
    /*
     * Insist on 2 lines for the screen header, 2 for blank lines
     * separating areas of the screen, 2 for word choices, and 2 for
     * the minimenu, plus however many are needed for context.  If
     * possible, make the context smaller to fit on the screen.
     */
    if (li < contextsize + 8  &&  contextsize > MINCONTEXT) {
        contextsize = li - 8;
        if (contextsize < MINCONTEXT)
            contextsize = MINCONTEXT;
    }
    if (li < MINCONTEXT + 8)
       fprintf(stderr, TERM_C_SMALL_SCREEN, MINCONTEXT + 8);

#ifdef SIGTSTP
#ifdef TIOCPGRP
retry:
#endif /* SIGTSTP */
#endif /* TIOCPGRP */

    if (!isatty(0)) {
       fprintf(stderr, TERM_C_NO_BATCH);
       exit(1);
    }
    ioctl(0, TCGETA, (char *) &osbuf);
    termchanged = 1;

    sbuf = osbuf;
    sbuf.c_lflag &= ~(ECHO | ECHOK | ECHONL | ICANON);
    sbuf.c_oflag &= ~(OPOST);
    sbuf.c_iflag &= ~(INLCR | IGNCR | ICRNL);
    sbuf.c_cc[VMIN] = 1;
    sbuf.c_cc[VTIME] = 1;
    ioctl(0, TCSETAW, (char *) &sbuf);

    jerasechar = osbuf.c_cc[VERASE];
/*
    killchar = osbuf.c_cc[VKILL];
*/


#ifdef SIGTSTP
    sigsetmask (1<<(SIGTSTP-1) | 1<<(SIGTTIN-1) | 1<<(SIGTTOU-1));
#endif

#ifdef TIOCGPGRP
    if (ioctl(0, TIOCGPGRP, (char *) &tpgrp) != 0) {
       fprintf(stderr, TERM_C_NO_BATCH);
       exit(1);
    }
#endif
#ifdef SIGTSTP
#ifdef TIOCPGRP
    if (tpgrp != getpgrp(0)) {  /* not in foreground */
        signal(SIGTTOU, SIG_DFL);
        kill(0, SIGTTOU);
        /* job stops here waiting for SIGCONT */
        goto retry;
    }
#endif
#endif

    if ((oldint = signal (SIGINT, SIG_IGN)) != SIG_IGN)
        signal (SIGINT, done);
    if ((oldterm = signal (SIGTERM, SIG_IGN)) != SIG_IGN)
        signal (SIGTERM, done);

#ifdef SIGTSTP
    if ((oldttin = signal(SIGTTIN, SIG_IGN)) != SIG_IGN)
        signal(SIGTTIN, onstop);
    if ((oldttou = signal(SIGTTOU, SIG_IGN)) != SIG_IGN)
        signal(SIGTTOU, onstop);
    if ((oldtstp = signal(SIGTSTP, SIG_IGN)) != SIG_IGN)
        signal(SIGTSTP, onstop);
#endif
    if (ti)
        tputs(ti, 1, putch);
    init_filt();
#endif
}

/*---------------------------------------------------------------------------*/

/* ARGSUSED */
SIGNAL_TYPE done(int signo)
{
#ifndef NOCURSES
   if (tempfile[0] != '\0')
      unlink(tempfile);
   if (termchanged) {
      if (te)
         tputs(te, 1, putch);
      ioctl(0, TCSETAW, (char *) &osbuf);
    }

   /* WAS: ((nothing)) */
   endwin();
#endif
   exit(0);

}

/*---------------------------------------------------------------------------*/

#ifdef SIGTSTP
static SIGNAL_TYPE onstop(int signo)
{
#ifndef NOCURSES
    ioctl(0, TCSETAW, (char *) &osbuf);
    signal(signo, SIG_DFL);
    kill(0, signo);
    /* stop here until continued */
    signal(signo, onstop);
    ioctl(0, TCSETAW, (char *) &sbuf);
#endif
}
#endif

/*---------------------------------------------------------------------------*/

void stop(void)
{
#ifndef NOCURSES
#ifdef SIGTSTP
    onstop(SIGTSTP);
#else
    /* for System V */
    move(li - 1, 0);
    fflush(stdout);
    if (getenv("SHELL"))
        shellescape(getenv("SHELL"));
    else
        shellescape("sh");
#endif
#endif
}

/*---------------------------------------------------------------------------*/
/* Fork and exec a process.  Returns NZ if command found, regardless of
** command's return status.  Returns zero if command was not found.
** Doesn't use a shell.
*/

#define NEED_SHELLESCAPE

#ifndef REGEX_LOOKUP
#define NEED_SHELLESCAPE
#endif /* REGEX_LOOKUP */
#ifdef NEED_SHELLESCAPE
int shellescape(char *buf)
{
#ifndef NOCURSES
    char *argv[100];
    char *cp = buf;
    int i = 0;
    int termstat;

    /* parse buf to args (destroying it in the process) */
    while (*cp != '\0') {
        while (*cp == ' '  ||  *cp == '\t')
            ++cp;
        if (*cp == '\0')
            break;
        argv[i++] = cp;
        while (*cp != ' '  &&  *cp != '\t'  &&  *cp != '\0')
            ++cp;
        if (*cp != '\0')
            *cp++ = '\0';
    }
    argv[i] = NULL;

    ioctl(0, TCSETAW, (char *) &osbuf);
    signal(SIGINT, oldint);
    signal(SIGTERM, oldterm);
#ifdef SIGTSTP
    signal(SIGTTIN, oldttin);
    signal(SIGTTOU, oldttou);
    signal(SIGTSTP, oldtstp);
#endif
    if ((i = fork()) == 0) {
        execvp(argv[0], (char **) argv);
        _exit(123);                /* Command not found */
    }
    else if (i > 0) {
        while (wait (&termstat) != i)
            ;
        termstat = (termstat == (123 << 8)) ? 0 : -1;
        }
    else {
       printf(TERM_C_CANT_FORK);
       termstat = -1;                /* Couldn't fork */
    }

    if (oldint != SIG_IGN)
       signal(SIGINT, done);
    if (oldterm != SIG_IGN)
       signal(SIGTERM, done);

#ifdef SIGTSTP
    if (oldttin != SIG_IGN)
       signal(SIGTTIN, onstop);
    if (oldttou != SIG_IGN)
       signal(SIGTTOU, onstop);
    if (oldtstp != SIG_IGN)
       signal(SIGTSTP, onstop);
#endif

    ioctl(0, TCSETAW, (char *) &sbuf);
    if (termstat) {
       printf(TERM_C_TYPE_SPACE);
       fflush(stdout);
#ifdef COMMANDFORSPACE
       i = GETKEYSTROKE();
       if (i != ' ' && i != '\n' && i != '\r')
          ungetc(i, stdin);
#else
       while (GETKEYSTROKE() != ' ')
          ;
#endif
    }
    return termstat;
#endif
}
#endif /* NEED_SHELLESCAPE */

/*---------------------------------------------------------------------------*/

#define NFILTS 12

struct sfilter {
   char st[20];
   int cont;
   int key;
} filt[NFILTS];


void put_key(int pos, char *st, int key)
{
   if (st)
      strcpy(filt[pos].st, st);
   else
      strcpy(filt[pos].st, "////");  /* dummy value */

   filt[pos].key = key;


}

void init_filt(void)
{
#ifndef NOCURSES
   put_key(0, kl, CLEFT);
   put_key(1, kr, CRIGHT);
   put_key(2, kh, HOME);
   put_key(3, kH, END_);
   put_key(4, kI, INS);
   put_key(5, kD, DEL);
   /* put also ANSI definitions */
   strcpy(filt[6].st, "\E[D");  filt[6].key = CLEFT;
   strcpy(filt[7].st, "\E[C");  filt[7].key = CRIGHT;
   strcpy(filt[8].st, "\E[1~"); filt[8].key = HOME;
   strcpy(filt[9].st, "\E[4~"); filt[9].key = END_;
   strcpy(filt[10].st, "\E[2~"); filt[10].key = INS;
   strcpy(filt[11].st, "\E[B");  filt[11].key = DEL;
#endif
}

int verify_cond(char ch, int i)
{
   int j, suc;

   j = 0;
   suc = 0;
   while (j < NFILTS && !suc)
      if (filt[j].st[i+1] != '\0' && ch == filt[j].st[i] && filt[j].cont == i)
         suc = 1;
       else
          j++;
   return suc;
}

int jfilter(int ch)
{
#ifndef NOCURSES
   int i, j, suc;
   char old_ch;

   if (ch == jerasechar) return BACKSPACE;
   if (ch == 8) return BACKSPACE;          /* CTRL-H used in ANSI and XTERM */
   i = 0;

   for (j = 0; j < NFILTS; j++)
      filt[j].cont = 0;
/*   printf("ch=%c, kh[0]=%c ", ch, kh[0]); fflush(stdout); */
   while (verify_cond(ch, i)) {

      /* increment counter */
      for (j = 0; j < NFILTS; j++)
         if (ch == filt[j].st[i]) filt[j].cont++;

      old_ch = ch;
      ch = (GETKEYSTROKE() & NOPARITY);
      i++;
/*      printf("ch=%c,kh[%d]=%c; ", ch, i, kh[i]); fflush(stdout); */
   }
   j = 0;
   suc = 0;
   while (j < NFILTS && !suc) {
      if (filt[j].st[i+1] == '\0' && ch == filt[j].st[i] && filt[j].cont == i) /* conseguiu ler toda a string kl */
         suc = 1;
      else
         j++;
   }
   if (suc)
      return filt[j].key;
   else
      return ch;
#endif
}



