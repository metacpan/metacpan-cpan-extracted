#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"


#include "callback.h"

SV *call_method__sv(pTHX_ SV *object, char *method) {
    dSP;
    SV *result;
    
    /* sv_dump(object); */

    ENTER;
    SAVETMPS;
    PUSHMARK(SP);
    XPUSHs(object);
    PUTBACK;
    call_method(method, G_SCALAR);
    SPAGAIN;
    result=POPs;
    SvREFCNT_inc(result);
    PUTBACK;
    FREETMPS;
    LEAVE;
    return sv_2mortal(result);
}

int call_method__int(pTHX_ SV *object, char *method) {
    dSP;
    int result;
    
    ENTER;
    SAVETMPS;
    PUSHMARK(SP);
    XPUSHs(object);
    PUTBACK;
    call_method(method, G_SCALAR);
    SPAGAIN;
    result=POPi;
    PUTBACK;
    FREETMPS;
    LEAVE;
    return result;
}

SV *call_method_int__sv(pTHX_ SV *object, char *method, int i) {
    dSP;
    SV *result;
    
    ENTER;
    SAVETMPS;
    PUSHMARK(SP);
    XPUSHs(object);
    XPUSHs(sv_2mortal(newSViv(i)));
    PUTBACK;
    call_method(method, G_SCALAR);
    SPAGAIN;
    result=POPs;
    SvREFCNT_inc(result);
    PUTBACK;
    FREETMPS;
    LEAVE;
    return sv_2mortal(result);
}

SV *call_method_sv__sv(pTHX_ SV *object, char *method, SV *arg) {
    dSP;
    SV *result;
    
    ENTER;
    SAVETMPS;
    PUSHMARK(SP);
    XPUSHs(object);
    XPUSHs(arg);
    PUTBACK;
    call_method(method, G_SCALAR);
    SPAGAIN;
    result=POPs;
    SvREFCNT_inc(result);
    PUTBACK;
    FREETMPS;
    LEAVE;
    return sv_2mortal(result);
}

SV *call_sub_sv__sv(pTHX_ char *name, SV *arg) {
    dSP;
    SV *result;

    ENTER;
    SAVETMPS;
    PUSHMARK(SP);
    XPUSHs(arg);
    PUTBACK;
    call_pv(name, G_SCALAR);
    SPAGAIN;
    result=POPs;
    SvREFCNT_inc(result);
    PUTBACK;
    FREETMPS;
    LEAVE;
    return sv_2mortal(result);
}
