/*
 * termcap variables
 */

#ifdef MAIN2
# define EXTERN2 /* nothing */
#else
# define EXTERN2 extern
#endif

#ifndef NOCURSES
#include <ncurses.h>
#include <term.h>
#endif

#define CLEFT  256
#define CRIGHT 257
#define CUP    258
#define CDOWN  259
#define PGUP   260
#define PGDOWN 261
#define HOME   262
#define END_   263
#define INS    264
#define DEL    265
#define BACKSPACE 300

int jjfilter(int ch);

extern  char *  BC;        /* backspace if not ^H */
EXTERN2 char *  cd;        /* clear to end of display */
EXTERN2 char *  ce;        /* clear to end of line */
EXTERN2 char *  cl;        /* clear display */
EXTERN2 char *  cm;        /* cursor movement */
EXTERN2 char *  ho;        /* home */
EXTERN2 char *  le;        /* cursor left one char */
EXTERN2 char *  nd;        /* cursor right one char */
EXTERN2 char *  so;        /* standout */
EXTERN2 char *  se;        /* standout end */

EXTERN2 char *  kl;        /* cursor left key */
EXTERN2 char *  kr;        /* cursor right key */
EXTERN2 char *  ku;        /* cursor up key */
EXTERN2 char *  kd;        /* cursor down key */
EXTERN2 char *  kP;        /* cursor pgup key */
EXTERN2 char *  kN;        /* cursor pgdown key */
EXTERN2 char *  kh;        /* cursor home key */
EXTERN2 char *  kH;        /* cursor end key */
EXTERN2 char *  kI;        /* cursor ins key */
EXTERN2 char *  kD;        /* cursor del key */

EXTERN2 int     sg;        /* space taken by so/se */
EXTERN2 char *  ti;        /* terminal initialization sequence */
EXTERN2 char *  te;        /* terminal termination sequence */
EXTERN2 int     li;        /* lines */
EXTERN2 int     co;        /* columns */

EXTERN2 int     jerasechar;           /* User's erase character, from stty */
/*EXTERN2 int     killchar; */           /* User's kill character */

EXTERN2 char    termcap[2048];        /* termcap entry */
EXTERN2 char    termstr[2048];        /* for string values */
EXTERN2 char *  termptr;              /* pointer into termcap, used by tgetstr */


void erase_EOL(void);
void init_filt(void);
void curs_right(void);
int jfilter(int ch);
