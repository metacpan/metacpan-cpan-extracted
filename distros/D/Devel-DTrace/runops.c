
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "plxsdtrace.h"
#include "runops.h"

STATIC CV *
_curcv( pTHX ) {
  PERL_SI *st = PL_curstackinfo;
  I32 ix = st->si_cxix;

  /* It's unclear whether we really need all this given that we call
   * _curcv on the first OP after subroutine entry - so presumably not
   * much can have happened by then. 
   */
  for ( ;; ) {
    const PERL_CONTEXT *const cx = &st->si_cxstack[ix];
    if ( CxTYPE( cx ) == CXt_SUB || CxTYPE( cx ) == CXt_FORMAT )
      return cx->blk_sub.cv;
    else if ( CxTYPE( cx ) == CXt_EVAL && !CxTRYBLOCK( cx ) )
      return PL_compcv;
    else if ( ix == 0 ) {
      if ( st->si_type == PERLSI_MAIN )
        return PL_main_cv;
      if ( st = st->si_prev, NULL == st )
        break;
      ix = st->si_cxix + 1;     /* add one because we always decrement */
    }
    ix--;
  }

  return NULL;
}

STATIC const char *
_sub_name( pTHX ) {
  const CV *const cv = _curcv( aTHX );
  if ( cv ) {
    const GV *const gv = CvGV( cv );
    if ( gv ) {
      return GvENAME( gv );
    }
  }

  return NULL;
}

#undef RUNOPS_FAKE
#include "runops-loop.h"
#define RUNOPS_FAKE
#include "runops-loop.h"

STATIC bool
_should_fake(  ) {
  const char *fake = getenv( FAKE_ENV );
  return fake && atoi( fake );
}

void
runops_hook(  ) {
#if 1
  runops_proc_t runops =
      _should_fake(  )? _runops_dtrace_fake : _runops_dtrace;

  if ( PL_runops != runops ) {
    PL_runops = runops;
  }
#else
  if ( _should_fake(  ) ) {
    _runops_install_fake(  );
  }
  else {
    _runops_install(  );
  }
#endif
}
