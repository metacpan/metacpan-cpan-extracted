#ifdef __cplusplus
extern "C" {
#endif

#define PERL_NO_GET_CONTEXT 1 /* we want efficiency */
#include <EXTERN.h>
#include <perl.h>
#define NO_XSLOCKS /* for exceptions */
#include <XSUB.h>

#ifdef MULTIPLICITY
#define storeTHX(var) (var) = aTHX
#define dTHXfield(var) tTHX var;
#else
#define storeTHX(var) dNOOP
#define dTHXfield(var)
#endif

#ifdef __cplusplus
} /* extern "C" */
#endif

#define dcAllocMem safemalloc
#define dcFreeMem Safefree

//#include "ppport.h"

#ifndef av_count
#define av_count(av) (AvFILL(av) + 1)
#endif

#ifndef aTHX_
#define aTHX_ aTHX,
#endif

#if defined(_WIN32) || defined(_WIN64)
// Handle special Windows stuff
#else
#include <dlfcn.h>
#endif

#include <dyncall.h>
#include <dyncall_callback.h>
#include <dynload.h>

#include <dyncall_value.h>
#include <dyncall_callf.h>

#include <dyncall_signature.h>

#include <dyncall/dyncall/dyncall_aggregate.h>

#define newHV_mortal() (HV *)sv_2mortal((SV *)newHV())

void export_function__(HV *_export, const char *what, const char *_tag) {
    dTHX;
    SV **tag = hv_fetch(_export, _tag, strlen(_tag), TRUE);
    if (tag && SvOK(*tag) && SvROK(*tag) && (SvTYPE(SvRV(*tag))) == SVt_PVAV)
        av_push((AV *)SvRV(*tag), newSVpv(what, 0));
    else {
        SV *av;
        av = (SV *)newAV();
        av_push((AV *)av, newSVpv(what, 0));
        tag = hv_store(_export, _tag, strlen(_tag), newRV_noinc(av), 0);
    }
}
void export_function(const char *package, const char *what, const char *tag) {
    dTHX;
    export_function__(get_hv(form("%s::EXPORT_TAGS", package), GV_ADD), what, tag);
}
void set_isa(const char *klass, const char *parent) {
    dTHX;
    HV *parent_stash = gv_stashpv(parent, GV_ADD | GV_ADDMULTI);
    av_push(get_av(form("%s::ISA", klass), TRUE), newSVpv(parent, 0));
    // TODO: make this spider up the list and make deeper connections?
}
