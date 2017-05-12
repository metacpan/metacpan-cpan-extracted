#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include "plconfig.h"
#include "Low.h"
#include "argv.h"

int PL_argc;
char **PL_argv=NULL;

void args2argv(void) {
    int i;
    AV *args=get_av(PKG "::args", 1);
    free_PL_argv();
    PL_argc=av_len(args)+1;
    Newz(0, PL_argv, PL_argc+1, char *);
    if (!PL_argv) {
	die ("out of memory");
    }
    for (i=0; i<PL_argc; i++) {
	SV **item;
	size_t len;
	char *arg;
	item=av_fetch(args, i, 0);
	if (item) {
	    arg=SvPV(*item, len);
	}
	else {
	    len=0;
	    arg="";
	}
	New(0, PL_argv[i], len+1, char);
	if (!PL_argv[i]) {
	    free_PL_argv();
	    die ("out of memory");
	}
	Copy(arg, PL_argv[i], len, char);
	PL_argv[i][len]='\0';
    }
    /*
    for (i=0; i<PL_argc; i++) {
	fprintf(stderr, "arg %i: '%s'\n", i, PL_argv[i]);
    }
    fprintf(stderr, "PLEXE=%s (len=%i)\n",
	    PL_exe, strlen(PL_exe));
    */
}


void free_PL_argv(void) {
    if (PL_argv) {
	int i;
	for(i=0; PL_argv[i]; i++) {
	    Safefree(PL_argv[i]);
	}
	Safefree(PL_argv);
    }
}
