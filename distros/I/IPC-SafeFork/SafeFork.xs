#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"


MODULE = IPC::SafeFork		PACKAGE = IPC::SafeFork		

PROTOTYPES: DISABLE

SV *
xs_fork()
  PREINIT:
    pid_t pid;
  CODE:
    RETVAL = 0;
    ST(0) = sv_newmortal();
    /*  This is not perfect.  A signal might happen in the child between 
        the fork and it being set to zero.  However sigprocmask() prevents
        waitpid() from working. 
        So we going from to many signals in the child to to little.
        But a "fresh" child is less likely to have a significant signal
        going on.
    */
    PERL_ASYNC_CHECK();
    pid = PerlProc_fork();
    if( pid < 0 ) {  /* error */
        ST(0) = &PL_sv_undef;
    }
    else {
        if( pid == 0 ) { /* child */
            PL_sig_pending = 0;
            memset( PL_psig_pend, 0, SIG_SIZE * sizeof(*PL_psig_pend) );
            /* Note that this means any signal destined for the child that
               arrives between the fork() and here is forever lost. 
            */
        }
        sv_setnv( ST(0), pid );
    }
