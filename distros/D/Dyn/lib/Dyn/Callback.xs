#include "lib/xshelper.h"

#include <dynload.h>
#include <dyncall.h>
#include <dyncall_value.h>
#include <dyncall_callf.h>
#include <dyncall_signature.h>
#include <dyncall_callback.h>

#include "lib/types.h"

#ifdef USE_ITHREADS
static PerlInterpreter *my_perl; /***    The Perl interpreter    ***/
#endif

static char callback_handler(DCCallback * cb, DCArgs * args, DCValue * result, void * userdata) {
    dTHX;
#ifdef USE_ITHREADS
    PERL_SET_CONTEXT(my_perl);
#endif
    char ret_type;
    {
    dSP;
    int count;

    _callback * container = ((_callback*) userdata);
    //int * ud = (int*) container->userdata;

    SV * cb_sv = container->cb;

    ENTER;
    SAVETMPS;
    //warn("here at %s line %d.", __FILE__, __LINE__);
    PUSHMARK(SP);
    {   const char * signature = container->signature;
        //warn("signature == %s at %s line %d.", container->signature, __FILE__, __LINE__);
        int done, okay;
        int i;
        //warn("signature: %s at %s line %d.", signature, __FILE__, __LINE__);
        for (i = 0; signature[i+1] != '\0'; ++i ) {
            done = okay = 0;
            //warn("here at %s line %d.", __FILE__, __LINE__);
            //warn("signature[%d] == %c at %s line %d.", i, signature[i], __FILE__, __LINE__);
            switch (signature[i]) {
                case DC_SIGCHAR_VOID:
                    //warn("Unhandled callback argument '%c' at %s line %d.", signature[i], __FILE__, __LINE__);
                    break;
                case DC_SIGCHAR_BOOL:
                    XPUSHs(newSViv(dcbArgBool(args))); break;
                case DC_SIGCHAR_CHAR:
                case DC_SIGCHAR_UCHAR:
                    XPUSHs(newSViv(dcbArgChar(args))); break;
                case DC_SIGCHAR_SHORT:
                case DC_SIGCHAR_USHORT:
                    XPUSHs(newSViv(dcbArgShort(args))); break;
                case DC_SIGCHAR_INT:
                    XPUSHs(newSViv(dcbArgInt(args))); break;
                case DC_SIGCHAR_UINT:
                    XPUSHs(newSVuv(dcbArgInt(args))); break;
                case DC_SIGCHAR_LONG:
                    XPUSHs(newSVnv(dcbArgLong(args))); break;
                case DC_SIGCHAR_ULONG:
                    XPUSHs(newSVuv(dcbArgLong(args))); break;
                case DC_SIGCHAR_LONGLONG:
                    XPUSHs(newSVnv(dcbArgLongLong(args))); break;
                case DC_SIGCHAR_ULONGLONG:
                    XPUSHs(newSVuv(dcbArgLongLong(args))); break;
                case DC_SIGCHAR_FLOAT:
                    XPUSHs(newSVnv(dcbArgFloat(args))); break;
                case DC_SIGCHAR_DOUBLE:
                    XPUSHs(newSVnv(dcbArgDouble(args))); break;
                case DC_SIGCHAR_POINTER:
                case DC_SIGCHAR_STRING:
                    XPUSHs(newSVpv((const char *) dcbArgPointer(args), 0) ); break;
                case DC_SIGCHAR_STRUCT:
                    warn("Unhandled callback argument '%c' at %s line %d.", signature[i], __FILE__, __LINE__);
                    break;
                case DC_SIGCHAR_ENDARG:
                    ret_type = signature[i + 1];
                    done++;
                    break;
                default:
                    warn("Unhandled callback argument '%c' at %s line %d.", signature[i], __FILE__, __LINE__);
                    break;
            };
            if (done) break;
  /*
                  int       arg1 = dcbArgInt     (args);
  float     arg2 = dcbArgFloat   (args);
  short     arg3 = dcbArgShort   (args);
  double    arg4 = dcbArgDouble  (args);
  long long arg5 = dcbArgLongLong(args);
    */
        }
        //warn("here at %s line %d.", __FILE__, __LINE__);
    }
    //warn("here at %s line %d.", __FILE__, __LINE__);

    // XXX: Does anyone expect this?
    //XPUSHs(container->userdata);

    PUTBACK;

    //warn("here at %s line %d.", __FILE__, __LINE__);
    //SV ** signature = hv_fetch(container, "f_signature", 11, 0);
    //warn("here at %s line %d.", __FILE__, __LINE__);
    //warn("signature was %s", signature);

    count = call_sv(cb_sv, ret_type == DC_SIGCHAR_VOID ? G_VOID : G_SCALAR );

    SPAGAIN;

        //warn("return type: %c at %s line %d.", ret_type, __FILE__, __LINE__);


    switch(ret_type)     {
        case DC_SIGCHAR_VOID:
            break;
        case DC_SIGCHAR_BOOL:
            if (count != 1)
                croak("Unexpected return values");
            result->B = (bool) POPi;
            break;
        case DC_SIGCHAR_CHAR:
            if (count != 1)
                croak("Unexpected return values");
            result->c = (char) POPi;
            break;
        case DC_SIGCHAR_UCHAR:
            if (count != 1)
                croak("Unexpected return values");
            result->C = (u_char) POPi;
            break;
        case DC_SIGCHAR_SHORT:
            if (count != 1)
                croak("Unexpected return values");
            result->s = (short) POPi;
            break;
        case DC_SIGCHAR_USHORT:
            if (count != 1)
                croak("Unexpected return values");
            result->S = (u_short) POPi;
            break;
        case DC_SIGCHAR_INT:
            if (count != 1)
                croak("Unexpected return values");
            result->i = (int) POPi;
            break;
        case DC_SIGCHAR_UINT:
            if (count != 1)
                croak("Unexpected return values");
            result->I = (u_int) POPi;
            break;
        case DC_SIGCHAR_LONG:
            if (count != 1)
                croak("Unexpected return values");
            result->j = POPl;
            break;
        case DC_SIGCHAR_ULONG:
            if (count != 1)
                croak("Unexpected return values");
            result->J = POPul;
            break;
        case DC_SIGCHAR_LONGLONG:
            if (count != 1)
                croak("Unexpected return values");
            result->l = (long long) POPl;
            break;
        case DC_SIGCHAR_ULONGLONG:
            if (count != 1)
                croak("Unexpected return values");
            result->L = POPul;
            break;
        case DC_SIGCHAR_FLOAT: // double
            if (count != 1)
                croak("Unexpected return values");
            result->f = (float) POPn;
            break;
        case DC_SIGCHAR_DOUBLE: // double
            if (count != 1)
                croak("Unexpected return values");
            result->d = (double) POPn;
            break;
        case DC_SIGCHAR_POINTER: // string
            if (count != 1)
                croak("Unexpected return values");
            result->p = (DCpointer *) POPl;
            break;
        case DC_SIGCHAR_STRING: // string
            if (count != 1)
                croak("Unexpected return values");
            result->Z = POPpx;
            break;
        case DC_SIGCHAR_STRUCT: // string
            if (count != 1)
                croak("Unexpected return values");
            warn("Unhandled return type at %s line %d.", __FILE__, __LINE__);
            //result->l = POPl;            break;
            break;
    }

    PUTBACK;
    FREETMPS;
    LEAVE;
}

    return ret_type;
}

MODULE = Dyn::Callback PACKAGE = Dyn::Callback

BOOT:
#ifdef USE_ITHREADS
    my_perl = (PerlInterpreter *) PERL_GET_CONTEXT;
#endif

DCCallback *
dcbNewCallback(const char * signature, SV * funcptr, ...);
PREINIT:
    dTHX;
    _callback * container;
#ifdef USE_ITHREADS
    PERL_SET_CONTEXT(my_perl);
#endif
CODE:
    container = (_callback *) malloc(sizeof(_callback));
    if (!container) // OOM
        XSRETURN_UNDEF;
    container->cvm = dcNewCallVM(1024);
    dcMode(container->cvm, 0); // TODO: Use correct value according to signature
    dcReset(container->cvm);
    container->signature = signature;
    container->cb = SvREFCNT_inc(funcptr);
    container->userdata = items > 2 ? newRV_inc(ST(2)): &PL_sv_undef;
    int i;
    for (i = 0; container->signature[i+1] != '\0'; ++i ) {
        //warn("here at %s line %d.", __FILE__, __LINE__);
        if (container->signature[i] == ')') {
            container->ret_type = container->signature[i+1];
            break;
        }
    }
    //warn("signature: %s at %s line %d.", signature, __FILE__, __LINE__);
    RETVAL = dcbNewCallback(signature, callback_handler, (void *) container);
OUTPUT:
    RETVAL

void
dcbInitCallback(DCCallback * pcb, const char * signature, DCCallbackHandler * funcptr, ...);
PREINIT:
    dTHX;
    _callback * container;
#ifdef USE_ITHREADS
    PERL_SET_CONTEXT(my_perl);
#endif
CODE:
    container = (_callback*) dcbGetUserData(pcb);
    container->signature = signature;
    container->cb = SvREFCNT_inc((SV *) funcptr);
    container->userdata = items > 3 ? newRV_inc(ST(3)): &PL_sv_undef;
    int i;
    for (i = 0; container->signature[i+1] != '\0'; ++i ) {
        //warn("here at %s line %d.", __FILE__, __LINE__);
        if (container->signature[i] == ')') {
            container->ret_type = container->signature[i+1];
            break;
        }
    }
    dcbInitCallback(pcb, signature, callback_handler, (void *) container);

void
dcbFreeCallback(DCCallback * pcb);
PREINIT:
    dTHX;
#ifdef USE_ITHREADS
    PERL_SET_CONTEXT(my_perl);
#endif
CODE:
    _callback * container = ((_callback*) dcbGetUserData(pcb));
    dcFree(container->cvm);
    dcbFreeCallback( pcb );
    // TODO: Free SVs

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
    _callback * container = ((_callback*) dcbGetUserData(pcb));
    if (SvOK(container->userdata))
        RETVAL = //SvRV(container->userdata);
            SvREFCNT_inc(SvRV(container->userdata));
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
    //AV * args = newAV();
CODE:
    RETVAL = newSV(0);
    _callback * container = ((_callback*) dcbGetUserData(self));
    const char * signature = container->signature;
    int done = 0;
    int i;
    dcReset(container->cvm); // Get it ready to call again
    int tally = 0;
    //warn("here at %s line %d.", __FILE__, __LINE__);
    for (i = 1; signature[i] != '\0'; ++i) {
        //warn ("i: %d vs items: %d", i, items);
        //if (i > items - 1) // TODO: Don't do this is signature is var_list, etc.
        //    croak("Incorrect number of arguments for callback. Expected %d but were handed %d.", i, items - 1);
        tally++;
        switch(signature[i - 1]) {
            case DC_SIGCHAR_VOID:
                //dcArgVoid(container->cvm, self);
                tally--;
                break;
            case DC_SIGCHAR_BOOL:
                dcArgBool(container->cvm, SvTRUE(ST(i))); break;
            case DC_SIGCHAR_CHAR:
            case DC_SIGCHAR_UCHAR:
                dcArgChar(container->cvm, SvIV(ST(i)));   break;
            case DC_SIGCHAR_SHORT:
            case DC_SIGCHAR_USHORT:
                dcArgShort(container->cvm, SvIV(ST(i)));   break;
            case DC_SIGCHAR_INT:
            case DC_SIGCHAR_UINT:
                dcArgInt(container->cvm, SvIV(ST(i)));   break;
            case DC_SIGCHAR_LONG:
            case DC_SIGCHAR_ULONG:
                dcArgLong(container->cvm, SvIV(ST(i)));   break;
            case DC_SIGCHAR_LONGLONG:
            case DC_SIGCHAR_ULONGLONG:
                dcArgLongLong(container->cvm, SvIV(ST(i)));   break;
            case DC_SIGCHAR_FLOAT:
                dcArgFloat(container->cvm, SvNV(ST(i)));   break;
            case DC_SIGCHAR_DOUBLE:
                dcArgDouble(container->cvm, SvNV(ST(i)));   break;
            case DC_SIGCHAR_POINTER:
                warn("Unhandled return type [%c] at %s line %d.", container->ret_type, __FILE__, __LINE__);
                break;
            case DC_SIGCHAR_STRING:
                dcArgPointer(container->cvm, SvPV_nolen(ST(i)));   break;
            case DC_SIGCHAR_STRUCT:
                warn("Unhandled return type [%c] at %s line %d.", container->ret_type, __FILE__, __LINE__);
                break;
            case DC_SIGCHAR_ENDARG:
                if (tally > items) // TODO: Don't do this is signature is var_list, etc.
                    croak("Not enough arguments for callback.");
                else if (tally < items)
                    croak("Too many arguments for callback.");
                done++;
                break;
            default:
                warn("Unhandled return type [%c] at %s line %d.", container->ret_type, __FILE__, __LINE__);
                break;
        }
        if (done) break;
    }
    //warn("Return type: %c at %s line %d.", container->ret_type, __FILE__, __LINE__);
    switch(container->ret_type) {
        case DC_SIGCHAR_VOID:
            dcCallVoid(container->cvm, self);
            XSRETURN_UNDEF;
            break;
        case DC_SIGCHAR_BOOL:
            RETVAL = newSViv(dcCallBool(container->cvm, self)); break; // TODO: Make this a real t/f
        case DC_SIGCHAR_CHAR:
            RETVAL = newSViv(dcCallChar(container->cvm, self)); break;
        case DC_SIGCHAR_UCHAR:
            RETVAL = newSVuv(dcCallChar(container->cvm, self)); break;
        case DC_SIGCHAR_SHORT:
            RETVAL = newSViv(dcCallShort(container->cvm, self)); break;
        case DC_SIGCHAR_USHORT:
            RETVAL = newSVuv(dcCallShort(container->cvm, self)); break;
        case DC_SIGCHAR_INT:
            RETVAL = newSViv(dcCallInt(container->cvm, self)); break;
        case DC_SIGCHAR_UINT:
            RETVAL = newSVuv(dcCallInt(container->cvm, self)); break;
        case DC_SIGCHAR_LONG:
            RETVAL = newSViv(dcCallLong(container->cvm, self)); break;
        case DC_SIGCHAR_ULONG:
            RETVAL = newSVuv(dcCallLong(container->cvm, self)); break;
        case DC_SIGCHAR_LONGLONG:
            RETVAL = newSViv(dcCallLongLong(container->cvm, self)); break;
        case DC_SIGCHAR_ULONGLONG:
            RETVAL = newSVuv(dcCallLongLong(container->cvm, self)); break;
        case DC_SIGCHAR_FLOAT:
            RETVAL = newSVnv(dcCallFloat(container->cvm, self)); break;
        case DC_SIGCHAR_DOUBLE:
            RETVAL = newSVnv(dcCallDouble(container->cvm, self)); break;
        case DC_SIGCHAR_POINTER:
            warn("Unhandled return type [%c] at %s line %d.", container->ret_type, __FILE__, __LINE__);
            XSRETURN_UNDEF;
            break;
        case DC_SIGCHAR_STRING:
            RETVAL = newSVpv((const char *) dcCallPointer(container->cvm, self), 0);
            break;
        case DC_SIGCHAR_STRUCT:
            warn("Unhandled return type [%c] at %s line %d.", container->ret_type, __FILE__, __LINE__);
            XSRETURN_UNDEF;
            break;
        default:
            warn("Unhandled return type [%c] at %s line %d.", container->ret_type, __FILE__, __LINE__);
            XSRETURN_UNDEF;
            break;
    }
    //warn("here at %s line %d.", __FILE__, __LINE__);
OUTPUT:
    RETVAL

void
Ximport( const char * package, ... )
CODE:
    const PERL_CONTEXT * cx_caller = caller_cx( 0, NULL );
    char *caller = HvNAME((HV*) CopSTASH(cx_caller->blk_oldcop));

    warn("Import from %s! items == %d", caller, items);

    int item;
    for (item = 1; item < items; ++item)
        warn("  item %d: %s", item, SvPV_nolen(ST(item)));

    //export_sub(ctx_stash, caller_stash, name);
