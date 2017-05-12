#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <pty.h>
#include <utmp.h>


MODULE = IO::Tty::Util		PACKAGE = IO::Tty::Util	

PROTOTYPES: DISABLE



# int openpty(int *amaster, int *aslave, char *name, struct termios *termp, struct winsize *winp);
void _openpty(rows, cols)
	int rows
	int cols 

	PREINIT:
	int amaster ;
	int aslave ;
	int rc ;
	struct winsize win ;

	PPCODE:
	win.ws_row = rows ;
	win.ws_col = cols ;
	rc = openpty(&amaster, &aslave, NULL, NULL, &win) ;
	if (rc == -1){
		XPUSHs(&PL_sv_undef) ;
	}
	else {
		XPUSHs(sv_2mortal(newSVnv(amaster))) ;
		XPUSHs(sv_2mortal(newSVnv(aslave))) ;
	}



# int login_tty(int fd); 
void _login_tty(fd)
	int fd

	PPCODE:
	XPUSHs(sv_2mortal(newSVnv(login_tty(fd)))) ;

