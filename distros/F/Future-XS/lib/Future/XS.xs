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

MODULE = Future::XS    PACKAGE = Future::XS

SV *
new(char *class)
  CODE:
    RETVAL = future_new();
  OUTPUT:
    RETVAL

void
DESTROY(SV *self)
  CODE:
    future_destroy(self);

bool
is_ready(SV *self)
  CODE:
    RETVAL = future_is_ready(self);
  OUTPUT:
    RETVAL

bool
is_done(SV *self)
  CODE:
    RETVAL = future_is_done(self);
  OUTPUT:
    RETVAL

bool
is_failed(SV *self)
  CODE:
    RETVAL = future_is_failed(self);
  OUTPUT:
    RETVAL

bool
is_cancelled(SV *self)
  CODE:
    RETVAL = future_is_cancelled(self);
  OUTPUT:
    RETVAL

char *
state(SV *self)
  CODE:
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
      RETVAL = future_new();

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
      RETVAL = future_new();

    future_failv(RETVAL, &ST(1), items - 1);
  OUTPUT:
    RETVAL

SV *
on_cancel(SV *self, SV *code)
  CODE:
    future_on_cancel(self, code);
    RETVAL = SvREFCNT_inc(self);
  OUTPUT:
    RETVAL

SV *
on_ready(SV *self, SV *code)
  CODE:
    future_on_ready(self, code);
    RETVAL = SvREFCNT_inc(self);
  OUTPUT:
    RETVAL

void
result(SV *self)
  PPCODE:
    AV *result = future_get_result_av(self);
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
    future_on_done(self, code);
    RETVAL = SvREFCNT_inc(self);
  OUTPUT:
    RETVAL

void
failure(SV *self)
  PPCODE:
    AV *failure = future_get_failure_av(self);
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
    future_on_fail(self, code);
    RETVAL = SvREFCNT_inc(self);
  OUTPUT:
    RETVAL

SV *
cancel(SV *self)
  CODE:
    future_cancel(self);
    RETVAL = SvREFCNT_inc(self);
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
  CODE:
    items--; /* account for self */

    SV *thencode = &PL_sv_undef;
    if(items) {
      thencode = ST(1);
      items--;
    }

    SV *elsecode = &PL_sv_undef;
    if(items % 2) {
      elsecode = ST(1 + items);
      items--;
    }

    if(items) {
      HV *catches = newHV();

      for(int i = 0; i < items/2; i++)
        hv_store_ent(catches, ST(2 + i*2), newSVsv(ST(2 + i*2 + 1)), 0);

      RETVAL = future_thencatch(self, thencode, catches, elsecode);
    }
    else {
      RETVAL = future_then(self, thencode, elsecode);
    }
  OUTPUT:
    RETVAL

SV *
else(SV *self, SV *code)
  CODE:
    RETVAL = future_then(self, NULL, code);
  OUTPUT:
    RETVAL

SV *
catch(SV *self, ...)
  CODE:
    items--; /* account for self */

    SV *elsecode = &PL_sv_undef;
    if(items % 2) {
      elsecode = ST(items);
      items--;
    }

    HV *catches = newHV();

    for(int i = 0; i < items/2; i++)
      hv_store_ent(catches, ST(1 + i*2), newSVsv(ST(1 + i*2 + 1)), 0);

    RETVAL = future_thencatch(self, NULL, catches, elsecode);
  OUTPUT:
    RETVAL

SV *
followed_by(SV *self, SV *code)
  CODE:
    RETVAL = future_followed_by(self, code);
  OUTPUT:
    RETVAL

SV *
wait_all(SV *self, ...)
  CODE:
    RETVAL = future_new_waitallv(&ST(1), items - 1);
  OUTPUT:
    RETVAL

SV *
wait_any(SV *self, ...)
  CODE:
    RETVAL = future_new_waitanyv(&ST(1), items - 1);
  OUTPUT:
    RETVAL

SV *
needs_all(SV *self, ...)
  CODE:
    RETVAL = future_new_needsallv(&ST(1), items - 1);
  OUTPUT:
    RETVAL

SV *
needs_any(SV *self, ...)
  CODE:
    RETVAL = future_new_needsanyv(&ST(1), items - 1);
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
    PUTBACK;
    Size_t count = future_mPUSH_subs(self, ix);
    SPAGAIN;
    XSRETURN(count);

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
    RETVAL = future_get_label(self);
  OUTPUT:
    RETVAL

BOOT:
  future_boot();
