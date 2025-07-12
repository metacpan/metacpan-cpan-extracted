/*  You may distribute under the terms of either the GNU General Public License
 *  or the Artistic License (the same terms as Perl itself)
 *
 *  (C) Paul Evans, 2022 -- leonerd@leonerd.org.uk
 */
#define PERL_NO_GET_CONTEXT

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "future.h"

#include "perl-backcompat.c.inc"

#include "av-utils.c.inc"
#include "croak_from_caller.c.inc"

#define warn_void_context(func)  S_warn_void_context(aTHX_ func)
static void S_warn_void_context(pTHX_ const char *func)
{
  if(GIMME_V == G_VOID)
    warn("Calling ->%s in void context", func);
}

#define CHECK_INSTANCE(self)  \
  if(!SvROK(self) || !SvOBJECT(SvRV(self)) ||       \
      !sv_derived_from(self, "Future::XS")) {       \
    GV *gv = CvGV(cv); HV *stash = GvSTASH(gv);     \
    croak("Expected a Future instance for %s::%s",  \
      HvNAME(stash), GvNAME(gv));                   \
  }

MODULE = Future::XS    PACKAGE = Future::XS

SV *
new(SV *proto)
  CODE:
    if(SvROK(proto) && SvOBJECT(SvRV(proto))) {
      HV *protostash = SvSTASH(SvRV(proto));
      RETVAL = future_new(HvNAME(protostash));
    }
    else
      RETVAL = future_new(SvPV_nolen(proto));
  OUTPUT:
    RETVAL

void
DESTROY(SV *self)
  CODE:
    future_destroy(self);

bool
is_ready(SV *self)
  CODE:
    CHECK_INSTANCE(self);
    RETVAL = future_is_ready(self);
  OUTPUT:
    RETVAL

bool
is_done(SV *self)
  CODE:
    CHECK_INSTANCE(self);
    RETVAL = future_is_done(self);
  OUTPUT:
    RETVAL

bool
is_failed(SV *self)
  CODE:
    CHECK_INSTANCE(self);
    RETVAL = future_is_failed(self);
  OUTPUT:
    RETVAL

bool
is_cancelled(SV *self)
  CODE:
    CHECK_INSTANCE(self);
    RETVAL = future_is_cancelled(self);
  OUTPUT:
    RETVAL

char *
state(SV *self)
  CODE:
    CHECK_INSTANCE(self);
    // TODO: We can do this more efficiently sometime
    if(!future_is_ready(self))
      RETVAL = "pending";
    else if(future_is_failed(self))
      RETVAL = "failed";
    else if(future_is_cancelled(self))
      RETVAL = "cancelled";
    else
      RETVAL = "done";
  OUTPUT:
    RETVAL

SV *
done(SV *self, ...)
  CODE:
    if(sv_is_future(self))
      RETVAL = SvREFCNT_inc(ST(0));
    else
      RETVAL = future_new(SvPV_nolen(ST(0)));

    future_donev(RETVAL, &ST(1), items - 1);
  OUTPUT:
    RETVAL

SV *
fail(SV *self, ...)
  ALIAS:
    fail = 0
    die  = 1
  CODE:
    SV *exception = ST(1);

    if(ix == 1 && /* ->die */
      !SvROK(exception) && SvPV_nolen(exception)[SvCUR(exception)-1] != '\n') {
      ST(1) = exception = newSVsv(exception);
      sv_catpvf(exception, " at %s line %d\n", CopFILE(PL_curcop), CopLINE(PL_curcop));
    }

    // TODO: mess about with Future::Exception

    if(sv_is_future(self))
      RETVAL = SvREFCNT_inc(ST(0));
    else
      RETVAL = future_new(SvPV_nolen(ST(0)));

    future_failv(RETVAL, &ST(1), items - 1);
  OUTPUT:
    RETVAL

SV *
on_cancel(SV *self, SV *code)
  CODE:
    CHECK_INSTANCE(self);
    RETVAL = newSVsv(self);
    future_on_cancel(self, code);
  OUTPUT:
    RETVAL

SV *
on_ready(SV *self, SV *code)
  CODE:
    CHECK_INSTANCE(self);
    /* Need to copy the return value first in case on_ready destroys it
     *   RT145168 */
    RETVAL = newSVsv(self);
    future_on_ready(self, code);
  OUTPUT:
    RETVAL

SV *
await(SV *self)
  CODE:
    CHECK_INSTANCE(self);
    if(future_is_ready(self)) {
      RETVAL = newSVsv(ST(0));
      XSRETURN(1);
    }
    croak_from_caller("%" SVf " is not yet complete and does not provide an ->await method",
      SVfARG(self));
  OUTPUT:
    RETVAL

void
result(SV *self)
  ALIAS:
    result = FALSE
    get    = TRUE
  PPCODE:
    CHECK_INSTANCE(self);
    /* This PUTBACK + SPAGAIN pair is required in case future_get_result_av()
     * causes the arguments stack to be reällocated. It works fine on perls
     * 5.24+ but causes older perls to crash. For now we just depend on 5.24
     *   https://rt.cpan.org/Ticket/Display.html?id=145597
     */
    PUTBACK;
    AV *result = future_get_result_av(self, ix);
    SPAGAIN;
    if(GIMME_V == G_LIST) {
      XPUSHs_from_AV(result);
      XSRETURN(av_count(result));
    }
    else {
      if(av_count(result))
        XPUSHs(AvARRAY(result)[0]);
      else
        XPUSHs(&PL_sv_undef);
      XSRETURN(1);
    }

SV *
on_done(SV *self, SV *code)
  CODE:
    CHECK_INSTANCE(self);
    RETVAL = newSVsv(self);
    future_on_done(self, code);
  OUTPUT:
    RETVAL

void
failure(SV *self)
  PPCODE:
    CHECK_INSTANCE(self);
    PUTBACK;
    AV *failure = future_get_failure_av(self);
    SPAGAIN;
    if(!failure)
      XSRETURN(0);

    if(GIMME_V == G_LIST) {
      XPUSHs_from_AV(failure);
      XSRETURN(av_count(failure));
    }
    else {
      if(av_count(failure))
        XPUSHs(AvARRAY(failure)[0]);
      else
        XPUSHs(&PL_sv_undef);
      XSRETURN(1);
    }

SV *
on_fail(SV *self, SV *code)
  CODE:
    CHECK_INSTANCE(self);
    RETVAL = newSVsv(self);
    future_on_fail(self, code);
  OUTPUT:
    RETVAL

SV *
cancel(SV *self)
  CODE:
    CHECK_INSTANCE(self);
    RETVAL = SvREFCNT_inc(self);
    future_cancel(self);
  OUTPUT:
    RETVAL

SV *
without_cancel(SV *self)
  CODE:
    RETVAL = future_without_cancel(self);
  OUTPUT:
    RETVAL

SV *
then(SV *self, ...)
  ALIAS:
    then        = 0
    then_with_f = FUTURE_THEN_WITH_F
  CODE:
    CHECK_INSTANCE(self);
    if(GIMME_V == G_VOID) {
      // Need to ensure we print the ->transform message right
      const PERL_CONTEXT *cx = caller_cx(0, NULL);
      if(CxTYPE(cx) == CXt_SUB &&
        strEQ(GvNAME(CvGV(cx->blk_sub.cv)), "transform")) {
        warn_void_context("transform");
      }
      else {
        warn_void_context(ix ? "then_with_f" : "then");
      }
    }

    items--; /* account for self */

    SV *thencode = &PL_sv_undef;
    if(items) {
      thencode = newSVsv(ST(1));
      items--;
    }

    SV *elsecode = &PL_sv_undef;
    if(items % 2) {
      elsecode = newSVsv(ST(1 + items));
      items--;
    }

    if(items) {
      HV *catches = newHV();

      for(int i = 0; i < items/2; i++)
        hv_store_ent(catches, ST(2 + i*2), newSVsv(ST(2 + i*2 + 1)), 0);

      RETVAL = future_thencatch(self, ix, thencode, catches, elsecode);
    }
    else {
      RETVAL = future_then(self, ix, thencode, elsecode);
    }
  OUTPUT:
    RETVAL

SV *
else(SV *self, SV *code)
  ALIAS:
    else        = 0
    else_with_f = FUTURE_THEN_WITH_F
  CODE:
    CHECK_INSTANCE(self);
    warn_void_context(ix ? "else_with_f" : "else");
    RETVAL = future_then(self, ix, NULL, newSVsv(code));
  OUTPUT:
    RETVAL

SV *
catch(SV *self, ...)
  ALIAS:
    catch        = 0
    catch_with_f = FUTURE_THEN_WITH_F
  CODE:
    CHECK_INSTANCE(self);
    warn_void_context(ix ? "catch_with_f" : "catch");
    items--; /* account for self */

    SV *elsecode = &PL_sv_undef;
    if(items % 2) {
      elsecode = newSVsv(ST(items));
      items--;
    }

    HV *catches = newHV();

    for(int i = 0; i < items/2; i++)
      hv_store_ent(catches, ST(1 + i*2), newSVsv(ST(1 + i*2 + 1)), 0);

    RETVAL = future_thencatch(self, ix, NULL, catches, elsecode);
  OUTPUT:
    RETVAL

SV *
followed_by(SV *self, SV *code)
  CODE:
    CHECK_INSTANCE(self);
    warn_void_context("followed_by");
    RETVAL = future_followed_by(self, newSVsv(code));
  OUTPUT:
    RETVAL

SV *
wait_all(SV *cls, ...)
  CODE:
    RETVAL = future_new_waitallv(SvPV_nolen(cls), &ST(1), items - 1);
  OUTPUT:
    RETVAL

SV *
wait_any(SV *cls, ...)
  CODE:
    RETVAL = future_new_waitanyv(SvPV_nolen(cls), &ST(1), items - 1);
  OUTPUT:
    RETVAL

SV *
needs_all(SV *cls, ...)
  CODE:
    RETVAL = future_new_needsallv(SvPV_nolen(cls), &ST(1), items - 1);
  OUTPUT:
    RETVAL

SV *
needs_any(SV *cls, ...)
  CODE:
    RETVAL = future_new_needsanyv(SvPV_nolen(cls), &ST(1), items - 1);
  OUTPUT:
    RETVAL

void
pending_futures(SV *self)
  ALIAS:
    pending_futures   = FUTURE_SUBS_PENDING
    ready_futures     = FUTURE_SUBS_READY
    done_futures      = FUTURE_SUBS_DONE
    failed_futures    = FUTURE_SUBS_FAILED
    cancelled_futures = FUTURE_SUBS_CANCELLED
  PPCODE:
    CHECK_INSTANCE(self);
    PUTBACK;
    Size_t count = future_mPUSH_subs(self, ix);
    SPAGAIN;
    XSRETURN(count);

SV *
btime(SV *self)
  ALIAS:
    btime = 0
    rtime = 1
  CODE:
  {
    struct timeval t;
    switch(ix) {
      case 0: t = future_get_btime(self); break;
      case 1: t = future_get_rtime(self); break;
    }

    RETVAL = &PL_sv_undef;

    if(t.tv_sec) {
      AV *retav = newAV();
      av_push(retav, newSViv(t.tv_sec));
      av_push(retav, newSViv(t.tv_usec));

      RETVAL = newRV_noinc((SV *)retav);
    }
  }
  OUTPUT:
    RETVAL

SV *
set_label(SV *self, SV *label)
  CODE:
    future_set_label(self, label);
    RETVAL = SvREFCNT_inc(self);
  OUTPUT:
    RETVAL

SV *
label(SV *self)
  CODE:
    SV *label = future_get_label(self);
    RETVAL = label ? newSVsv(label) : &PL_sv_undef;
  OUTPUT:
    RETVAL

SV *
set_udata(SV *self, SV *name, SV *value)
  CODE:
    future_set_udata(self, name, value);
    RETVAL = SvREFCNT_inc(self);
  OUTPUT:
    RETVAL

SV *
udata(SV *self, SV *name)
  CODE:
    RETVAL = newSVsv(future_get_udata(self, name));
  OUTPUT:
    RETVAL

void
reread_environment()
  CODE:
    Future_reread_environment(aTHX);

BOOT:
  future_boot();
