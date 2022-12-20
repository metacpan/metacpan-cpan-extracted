#include "lib/clutter.h"

typedef struct
{
    SV *cb;
    const char *signature;
    char ret_type;
    char mode;
    SV *userdata;
    DCCallVM *cvm;
} Callback;

static char callback_handler(DCCallback *cb, DCArgs *args, DCValue *result, void *userdata) {
    dTHX;
#ifdef USE_ITHREADS
    PERL_SET_CONTEXT(my_perl);
#endif
    char ret_type;
    {
        dSP;
        int count;

        Callback *container = ((Callback *)userdata);
        SV *cb_sv = container->cb;
        ENTER;
        SAVETMPS;
        PUSHMARK(SP);

        mXPUSHs(sv_setref_pv(newSV(0), "Dyn::Callback", (DCpointer)cb));
        mXPUSHs(sv_setref_pv(newSV(0), "Dyn::Callback::Args", (DCpointer)args));
        mXPUSHs(sv_setref_pv(newSV(0), "Dyn::Callback::Value", (DCpointer)result));
        if (SvOK(container->userdata))
            mXPUSHs(SvREFCNT_inc(SvRV(container->userdata)));
        else
            mXPUSHs(newSV(0));

        PUTBACK;
        count = call_sv(cb_sv, ret_type == DC_SIGCHAR_VOID ? G_VOID : G_SCALAR);
        SPAGAIN;

        if (count != 1) croak("Expected a single return value to callback");

        ret_type = (char)*POPp;

        PUTBACK;
        FREETMPS;
        LEAVE;
    }
    return ret_type;
}

// clang-format off

MODULE = Dyn::Callback PACKAGE = Dyn::Callback

BOOT:
// clang-format on
#ifdef USE_ITHREADS
    my_perl = (PerlInterpreter *)PERL_GET_CONTEXT;
#endif
// clang-format off

DCCallback *
dcbNewCallback(const char * signature, SV * funcptr, userdata)
PREINIT:
#ifdef USE_ITHREADS
    PERL_SET_CONTEXT(my_perl);
#endif
    dTHX;
INIT:
    Callback * container;
CODE:
// clang-format on
{
    container = (Callback *)safemalloc(sizeof(Callback));
    if (!container) // OOM
        XSRETURN_UNDEF;
    container->cvm = dcNewCallVM(1024);
    dcMode(container->cvm, DC_CALL_C_DEFAULT); // TODO: Use correct value according to signature
    dcReset(container->cvm);
    container->signature = signature;
    container->cb = SvREFCNT_inc(funcptr);
    container->userdata = newRV_inc(items > 2 ? ST(2) : newSV(0));
    for (int i = 0; container->signature[i + 1] != '\0'; ++i) {
        // warn("here at %s line %d.", __FILE__, __LINE__);
        if (container->signature[i] == ')') {
            container->ret_type = container->signature[i + 1];
            break;
        }
    }
    // warn("signature: %s at %s line %d.", signature, __FILE__, __LINE__);
    RETVAL = dcbNewCallback(signature, callback_handler, (DCpointer)container);
}
// clang-format off
OUTPUT:
    RETVAL

void
dcbInitCallback(DCCallback * pcb, const char * signature, DCCallbackHandler * funcptr, userdata)
PREINIT:
    dTHX;
    Callback * container;
#ifdef USE_ITHREADS
    PERL_SET_CONTEXT(my_perl);
#endif
CODE:
// clang-format on
{
    container = (Callback *)dcbGetUserData(pcb);
    container->signature = signature;
    container->cb = SvREFCNT_inc((SV *)funcptr);
    container->userdata = items > 3 ? newRV_inc(ST(3)) : &PL_sv_undef;
    for (int i = 0; container->signature[i + 1] != '\0'; ++i) {
        // warn("here at %s line %d.", __FILE__, __LINE__);
        if (container->signature[i] == ')') {
            container->ret_type = container->signature[i + 1];
            break;
        }
    }
    dcbInitCallback(pcb, signature, callback_handler, (void *)container);
}
// clang-format off

void
dcbFreeCallback(DCCallback * pcb)
PREINIT:
    dTHX;
#ifdef USE_ITHREADS
    PERL_SET_CONTEXT(my_perl);
#endif
CODE:
    { // clang-format on
    Callback *container = ((Callback *)dcbGetUserData(pcb));
    SvREFCNT_dec(container->cb);
    SvREFCNT_dec(container->userdata);
    dcFree(container->cvm);
    dcbFreeCallback(pcb);
    safefree(container);
    // TODO: Free SVs
    // clang-format off
    }

SV *
dcbGetUserData(DCCallback * pcb);
PREINIT:
    dTHX;
#ifdef USE_ITHREADS
    PERL_SET_CONTEXT(my_perl);
#endif
INIT:
    RETVAL = (SV*) &PL_sv_undef;
CODE:
// clang-format on
{
    Callback *container = ((Callback *)dcbGetUserData(pcb));
    if (SvOK(container->userdata)) RETVAL = SvREFCNT_inc(SvRV(container->userdata));
    // clang-format off
    }
OUTPUT:
    RETVAL

=pod

Less Perl, more C.

=cut

SV *
call(DCCallback * self, ... )
PREINIT:
    dTHX;
#ifdef USE_ITHREADS
    PERL_SET_CONTEXT(my_perl);
#endif
CODE:
// clang-format on
{
    Callback *container = ((Callback *)dcbGetUserData(self));
    const char *signature = container->signature;
    // warn("Callback sig: %s", signature);
    int done = 0;
    dcReset(container->cvm); // Get it ready to call again
    int tally = 0;
    // warn("here at %s line %d.", __FILE__, __LINE__);
    for (int i = 1; signature[i] != '\0'; ++i) {
        // warn ("i: %d vs items: %d", i, items);
        // if (i > items - 1) // TODO: Don't do this is signature is var_list, etc.
        //     croak("Incorrect number of arguments for callback. Expected %d but were handed %d.",
        //     i, items - 1);
        tally++;
        // warn("Checking char: %c", signature[i - 1]);
        // warn("DC_SIGCHAR_CHAR == %c", DC_SIGCHAR_INT);
        // warn("here at %s line %d.", __FILE__, __LINE__);

        switch (signature[i - 1]) {
        case DC_SIGCHAR_VOID:
            // dcArgVoid(container->cvm, self);
            tally--;
            break;
        case DC_SIGCHAR_BOOL:
            dcArgBool(container->cvm, (bool)SvTRUE(ST(i)));
            break;
        case DC_SIGCHAR_CHAR:
            dcArgChar(container->cvm, (char)(SvIOK(ST(i)) ? SvIV(ST(i)) : 0));
            break;
        case DC_SIGCHAR_UCHAR:
            dcArgChar(container->cvm, (unsigned char)(SvUOK(ST(i)) ? SvIV(ST(i)) : 0));
            break;
        case DC_SIGCHAR_SHORT:
            dcArgShort(container->cvm, (short)(SvIOK(ST(i)) ? SvIV(ST(i)) : 0));
            break;
        case DC_SIGCHAR_USHORT:
            dcArgShort(container->cvm, (unsigned short)(SvUOK(ST(i)) ? SvIV(ST(i)) : 0));
            break;
        case DC_SIGCHAR_INT:
            dcArgInt(container->cvm, (int)(SvIOK(ST(i)) ? SvIV(ST(i)) : 0));
            break;
        case DC_SIGCHAR_UINT:
            dcArgInt(container->cvm, (unsigned int)(SvUOK(ST(i)) ? SvIV(ST(i)) : 0));
            break;
        case DC_SIGCHAR_LONG:
            dcArgLong(container->cvm, (long)(SvIOK(ST(i)) ? SvIV(ST(i)) : 0));
            break;
        case DC_SIGCHAR_ULONG:
            dcArgLong(container->cvm, (unsigned long)(SvUOK(ST(i)) ? SvIV(ST(i)) : 0));
            break;
        case DC_SIGCHAR_LONGLONG:
            dcArgLongLong(container->cvm, (long long)(SvIOK(ST(i)) ? SvIV(ST(i)) : 0));
            break;
        case DC_SIGCHAR_ULONGLONG:
            dcArgLongLong(container->cvm, (unsigned long long)(SvUOK(ST(i)) ? SvIV(ST(i)) : 0));
            break;
        case DC_SIGCHAR_FLOAT:
            dcArgFloat(container->cvm, (float)(SvNIOK(ST(i)) ? SvNV(ST(i)) : 0.0f));
            break;
        case DC_SIGCHAR_DOUBLE:
            dcArgDouble(container->cvm, (double)(SvNIOK(ST(i)) ? SvNV(ST(i)) : 0.0f));
            break;
        case DC_SIGCHAR_POINTER:
            warn("Unhandled arg type [%c] at %s line %d.", container->ret_type, __FILE__, __LINE__);
            break;
        case DC_SIGCHAR_STRING:
            dcArgPointer(container->cvm, SvPV_nolen(ST(i)));
            break;
        case DC_SIGCHAR_AGGREGATE:
            warn("Unhandled arg type [%c] at %s line %d.", container->ret_type, __FILE__, __LINE__);
            break;
        case DC_SIGCHAR_ENDARG:
            if (tally > items) // TODO: Don't do this is signature is var_list, etc.
                croak("Not enough arguments for callback");
            else if (tally < items)
                croak("Too many arguments for callback");
            done++;
            break;
        case '(':
            break;
            // skip it for now
        default:
            warn("Unhandled arg type [%c] at %s line %d.", container->ret_type, __FILE__, __LINE__);
            break;
        }
        // warn("Done: %s", (done? "Yes": "No"));
        if (done) break;
    }
    // warn("Return type: %c at %s line %d.", container->ret_type, __FILE__, __LINE__);
    switch (container->ret_type) {
    case DC_SIGCHAR_VOID:
        dcCallVoid(container->cvm, self);
        XSRETURN_UNDEF;
        break;
    case DC_SIGCHAR_BOOL:
        RETVAL = newSViv(dcCallBool(container->cvm, self));
        break; // TODO: Make this a real t/f
    case DC_SIGCHAR_CHAR:
        RETVAL = newSViv(dcCallChar(container->cvm, self));
        break;
    case DC_SIGCHAR_UCHAR:
        RETVAL = newSVuv(dcCallChar(container->cvm, self));
        break;
    case DC_SIGCHAR_SHORT:
        RETVAL = newSViv(dcCallShort(container->cvm, self));
        break;
    case DC_SIGCHAR_USHORT:
        RETVAL = newSVuv(dcCallShort(container->cvm, self));
        break;
    case DC_SIGCHAR_INT:
        RETVAL = newSViv(dcCallInt(container->cvm, self));
        break;
    case DC_SIGCHAR_UINT:
        RETVAL = newSVuv(dcCallInt(container->cvm, self));
        break;
    case DC_SIGCHAR_LONG:
        RETVAL = newSViv(dcCallLong(container->cvm, self));
        break;
    case DC_SIGCHAR_ULONG:
        RETVAL = newSVuv(dcCallLong(container->cvm, self));
        break;
    case DC_SIGCHAR_LONGLONG:
        RETVAL = newSViv(dcCallLongLong(container->cvm, self));
        break;
    case DC_SIGCHAR_ULONGLONG:
        RETVAL = newSVuv(dcCallLongLong(container->cvm, self));
        break;
    case DC_SIGCHAR_FLOAT:
        RETVAL = newSVnv(dcCallFloat(container->cvm, self));
        break;
    case DC_SIGCHAR_DOUBLE:
        RETVAL = newSVnv(dcCallDouble(container->cvm, self));
        break;
    case DC_SIGCHAR_POINTER:
        warn("Unhandled return type [%c] at %s line %d.", container->ret_type, __FILE__, __LINE__);
        XSRETURN_UNDEF;
        break;
    case DC_SIGCHAR_STRING:
        RETVAL = newSVpv((const char *)dcCallPointer(container->cvm, self), 0);
        break;
    case DC_SIGCHAR_AGGREGATE:
        warn("Unhandled return type [%c] at %s line %d.", container->ret_type, __FILE__, __LINE__);
        XSRETURN_UNDEF;
        break;
    default:
        warn("Unhandled return type [%c] at %s line %d.", container->ret_type, __FILE__, __LINE__);
        XSRETURN_UNDEF;
        break;
    }
}
// warn("here at %s line %d.", __FILE__, __LINE__);
// clang-format off
OUTPUT:
    RETVAL

BOOT:
// clang-format on
{
    export_function("Dyn::Callback", "dcbNewCallback", "default");
    export_function("Dyn::Callback", "dcbInitCallback", "default");
    export_function("Dyn::Callback", "dcbFreeCallback", "default");
    export_function("Dyn::Callback", "dcbGetUserData", "default");
}
// clang-format off

INCLUDE: Callback/Args.xsh

INCLUDE: Callback/Value.xsh
