#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <fcntl.h>
#include <unistd.h>

typedef CV *B__CV;

static OP *(*old_entersub)(pTHX);

// this is, of course, a slower entersub
static OP *
faster_entersub (pTHX)
{
  static int in_perl;

  if (!PL_compcv || in_perl) // only when not compiling, reduces recompiling due to op-address-shift
    {
      dSP;
      dTOPss;

      ++in_perl;

      if (SvTYPE (sv) == SVt_PVGV)
        sv = (SV *)GvCV (sv);

      if (sv)
        {
          // only once for now
          PL_op->op_ppaddr = old_entersub;

          // only simple cv calls for now
          if (!PL_perldb && !PL_tainting
              && SvTYPE (sv) == SVt_PVCV && !CvISXSUB (sv)
              && CvSTART (sv) // must exist
              && CvSTART (sv)->op_type != OP_NULL) // shield against compiling an already-compiled op
            {
              SV *bsv = newSViv (PTR2IV (sv));

              ENTER;
              SAVETMPS;
              PUSHMARK (SP);
              // emulate B::CV typemap entry we don't have
              XPUSHs (sv_2mortal (sv_bless (newRV_noinc (bsv), gv_stashpv ("B::CV", 1))));
              PUTBACK;
              call_pv ("Faster::entersub", G_VOID|G_DISCARD|G_EVAL);
              SPAGAIN;
              FREETMPS;
              LEAVE;
            }
        }

      --in_perl;
    }

  return old_entersub (aTHX);
}

MODULE = Faster		PACKAGE = Faster

PROTOTYPES: ENABLE

IV
ppaddr (int optype)
	CODE:
        RETVAL = optype == OP_ENTERSUB
                 ? (IV)old_entersub
                 : (IV)PL_ppaddr [optype];
	OUTPUT:
        RETVAL

void
hook_entersub ()
	CODE:
	old_entersub = PL_ppaddr [OP_ENTERSUB];
        PL_ppaddr [OP_ENTERSUB] = faster_entersub;

void
patch_cv (B::CV cv, void *ptr)
	CODE:
{
	OP *op;

        if (!ptr)
          croak ("NULL not allowed as code address for patch_cv");

	NewOp (0, op, 1, OP);

        op->op_sibling = CvSTART (cv);
        op->op_type = OP_NULL;
        op->op_ppaddr = ptr;

        CvSTART (cv) = op;
}

bool
fcntl_lock (int fd)
	CODE:
{
	struct flock lck;
        lck.l_type   = F_WRLCK;
        lck.l_whence = SEEK_SET;
        lck.l_start  = 0;
        lck.l_len    = 0;

        RETVAL = fcntl (fd, F_SETLKW, &lck) == 0;
}
	OUTPUT:
        RETVAL



