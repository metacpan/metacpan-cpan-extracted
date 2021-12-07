#include "lib/xshelper.h"

// Based on https://github.com/svn2github/dyncall/blob/master/bindings/ruby/rbdc/rbdc.c

#include <dynload.h>
#include <dyncall.h>
#include <dyncall_value.h>
#include <dyncall_callf.h>

#include "lib/types.h"

#define META_ATTR "ATTR_SUB"

typedef struct Call {
    DLLib * lib;
    const char * lib_name;
    const char * name;
    const char * sym_name;
    char * sig;
    size_t sig_len;
    char ret;
    DCCallVM * cvm;
    void * fptr;
    char * perl_sig;
} Call;

typedef struct Delayed {
    const char * library;
    const char * symbol;
    const char * signature;
    const char * name;
    struct Delayed * next;
} Delayed;

Delayed * delayed; // Not thread safe

static
char * clean(char *str) {
    char *end;
    while (isspace(*str) || *str == '"' || *str == '\'') str = str + 1;
    end = str + strlen(str) - 1;
    while (end > str && (isspace(*end) || *end == ')' || *end == '"' || *end == '\'')) end = end - 1;
    *(end+1) = '\0';
    return str;
}

#define _call_ \
    /*warn("items == %d", items);*/\
    /*warn("[%d] %s", ix, name );*/ \
    if (call != NULL) { \
        dcReset(call->cvm);\
        const char * sig_ptr = call->sig;\
        int sig_len = call->sig_len;\
        char ch;\
        for (ch = *sig_ptr; pos < /*sig_len;*/ items; ch = *++sig_ptr) {\
            /*warn("pos == %d", pos);*/\
            switch(ch) {\
                case DC_SIGCHAR_VOID:\
                    break;\
                case DC_SIGCHAR_BOOL:\
                    dcArgBool(call->cvm, SvTRUE(ST(pos))); break;\
                case DC_SIGCHAR_UCHAR:\
                    dcArgChar(call->cvm, (unsigned char) SvIV(ST(pos))); break;\
                case DC_SIGCHAR_CHAR:\
                    dcArgChar(call->cvm, (char) SvIV(ST(pos))); break;\
                case DC_SIGCHAR_FLOAT:\
                    /*warn(" float ==> %f", SvNV(ST(pos)));*/ \
                    dcArgFloat(call->cvm, (float) SvNV(ST(pos))); break;\
                case DC_SIGCHAR_USHORT:\
                    dcArgShort(call->cvm, (unsigned short) SvUV(ST(pos))); break;\
                case DC_SIGCHAR_SHORT:\
                    dcArgShort(call->cvm, (short) SvIV(ST(pos))); break;\
                case DC_SIGCHAR_UINT:\
                    dcArgInt(call->cvm, (unsigned int) SvUV(ST(pos))); break;\
                case DC_SIGCHAR_INT:\
                    dcArgInt(call->cvm, (int) SvIV(ST(pos))); break;\
                case DC_SIGCHAR_ULONG:\
                    dcArgLong(call->cvm, (unsigned long) SvNV(ST(pos))); break;\
                case DC_SIGCHAR_LONG:\
                    dcArgLong(call->cvm, (long) SvNV(ST(pos))); break;\
                /*case DC_SIGCHAR_POINTER:\
                //  dcArgPointer(call->cvm, SvIV(ST(pos))); break;*/\
                case DC_SIGCHAR_ULONGLONG:\
                    dcArgLongLong(call->cvm, (unsigned long long) SvNV(ST(pos))); break;\
                case DC_SIGCHAR_LONGLONG:\
                    dcArgLongLong(call->cvm, (long long) SvNV(ST(pos))); break;\
                case DC_SIGCHAR_DOUBLE:\
                    dcArgDouble(call->cvm, (double) SvNV(ST(pos))); break;\
                case DC_SIGCHAR_STRING:\
                    dcArgPointer(call->cvm, SvPV_nolen(ST(pos))); break;\
                case DC_SIGCHAR_STRUCT: /* XXX: dyncall structs aren't ready yet*/\
                    break;\
                default:\
                    break;\
            }\
            ++pos;\
        }\
        /*warn("ret == %c", call->ret);*/\
        switch (call->ret) {\
            case DC_SIGCHAR_FLOAT:\
                ST(0) = newSVnv(dcCallFloat(call->cvm, call->fptr)); XSRETURN(1); \
                break;\
            case DC_SIGCHAR_DOUBLE:\
                ST(0) = sv_2mortal(newSVnv(dcCallDouble(call->cvm, call->fptr))); XSRETURN(1); \
                break;\
            case DC_SIGCHAR_BOOL:\
                ST(0) = newSViv(dcCallBool(call->cvm, call->fptr)); XSRETURN(1); \
                break;\
            case DC_SIGCHAR_CHAR:\
                ST(0) = newSVnv(dcCallChar(call->cvm, call->fptr)); XSRETURN(1); \
                break;\
            case DC_SIGCHAR_SHORT:\
                ST(0) = newSViv(dcCallShort(call->cvm, call->fptr)); XSRETURN(1); \
                break;\
            case DC_SIGCHAR_INT:\
                ST(0) = newSViv(dcCallInt(call->cvm, call->fptr)); XSRETURN(1); \
                break;\
            case DC_SIGCHAR_LONG:\
                ST(0) = newSViv(dcCallLong(call->cvm, call->fptr)); XSRETURN(1); \
                break;\
            case DC_SIGCHAR_LONGLONG:\
                ST(0) = newSViv(dcCallLongLong(call->cvm, call->fptr)); XSRETURN(1); \
                break;\
            case DC_SIGCHAR_POINTER:\
                ST(0) = newSVnv(dcCallDouble(call->cvm, call->fptr)); XSRETURN(1); \
                break;\
            case DC_SIGCHAR_UCHAR:\
            case DC_SIGCHAR_USHORT:\
            case DC_SIGCHAR_UINT:\
            case DC_SIGCHAR_ULONG:\
            case DC_SIGCHAR_ULONGLONG:\
                ST(0) = newSVuv(dcCallLongLong(call->cvm, call->fptr)); XSRETURN(1); \
                break;\
            case DC_SIGCHAR_STRING:\
                ST(0) = newSVpvn_flags((const char *) dcCallPointer(call->cvm, call->fptr), 0, SVs_TEMP); XSRETURN(1); \
                break;\
            case DC_SIGCHAR_VOID:\
                dcCallVoid(call->cvm, call->fptr); XSRETURN_EMPTY; \
                break;\
            case DC_SIGCHAR_STRUCT: /* TODO: dyncall structs aren't ready upstream yet*/\
                break;\
            default:\
                /*croak("Help: %c", call->ret);*/\
                break;\
        }\
        /*warn("here at %s line %d", __FILE__, __LINE__);*/\
    }\
    else\
        croak("Function is not attached! This is a serious bug!");\
    /*warn("here at %s line %d", __FILE__, __LINE__);*/\

static Call *
_load(pTHX_ DLLib * lib, const char * symbol, const char * sig, const char * name ) {
    if(lib == NULL)
        return NULL;
    if (name == NULL)
        name = symbol;
    //warn("_load(%s, %s, %s, %s)", lib_path, symbol, sig, name);
    Call * RETVAL;
    Newx(RETVAL, 1, Call);
    RETVAL->lib = lib;
    RETVAL->cvm = dcNewCallVM(1024);
    if(RETVAL->cvm == NULL)
        return NULL;
    RETVAL->fptr = dlFindSymbol(RETVAL->lib, symbol );
    if (RETVAL->fptr == NULL) // TODO: throw warning
        return NULL;
    Newxz( RETVAL->sig, strlen(sig), char); // Dumb
    //RETVAL->sig = sig;
    RETVAL->sig_len = strlen(RETVAL->sig);
    Newxz( RETVAL->perl_sig, strlen(sig), char); // Dumb
    int i, sig_pos;
    sig_pos = 0;
    for (i = 0; sig[i + 1] != '\0'; ++i ) {
        switch (sig[i]) {
            case DC_SIGCHAR_CC_PREFIX:
                ++i;
                switch(sig[i]) {
                    case DC_SIGCHAR_CC_DEFAULT:
                        dcMode(RETVAL->cvm, DC_CALL_C_DEFAULT);  break;
                    case DC_SIGCHAR_CC_ELLIPSIS:
                        dcMode(RETVAL->cvm, DC_CALL_C_ELLIPSIS);  break;
                    case DC_SIGCHAR_CC_ELLIPSIS_VARARGS:
                        dcMode(RETVAL->cvm, DC_CALL_C_ELLIPSIS_VARARGS);  break;
                    case DC_SIGCHAR_CC_CDECL:
                        dcMode(RETVAL->cvm, DC_CALL_C_X86_CDECL);  break;
                    case DC_SIGCHAR_CC_STDCALL:
                        dcMode(RETVAL->cvm, DC_CALL_C_X86_WIN32_STD);  break;
                    case DC_SIGCHAR_CC_FASTCALL_MS:
                        dcMode(RETVAL->cvm, DC_CALL_C_X86_WIN32_FAST_MS);  break;
                    case DC_SIGCHAR_CC_FASTCALL_GNU:
                        dcMode(RETVAL->cvm, DC_CALL_C_X86_WIN32_FAST_GNU);  break;
                    case DC_SIGCHAR_CC_THISCALL_MS:
                        dcMode(RETVAL->cvm, DC_CALL_C_X86_WIN32_THIS_MS);  break;
                    case DC_SIGCHAR_CC_THISCALL_GNU:
                        dcMode(RETVAL->cvm, DC_CALL_C_X86_WIN32_FAST_GNU);  break;
                    case DC_SIGCHAR_CC_ARM_ARM:
                        dcMode(RETVAL->cvm, DC_CALL_C_ARM_ARM);  break;
                    case DC_SIGCHAR_CC_ARM_THUMB:
                        dcMode(RETVAL->cvm, DC_CALL_C_ARM_THUMB);  break;
                    case DC_SIGCHAR_CC_SYSCALL:
                        dcMode(RETVAL->cvm, DC_CALL_SYS_DEFAULT);  break;
                    default:
                        break;
                };
                break;
            case DC_SIGCHAR_VOID:
            case DC_SIGCHAR_BOOL:
            case DC_SIGCHAR_CHAR:
            case DC_SIGCHAR_UCHAR:
            case DC_SIGCHAR_SHORT:
            case DC_SIGCHAR_USHORT:
            case DC_SIGCHAR_INT:
            case DC_SIGCHAR_UINT:
            case DC_SIGCHAR_LONG:
            case DC_SIGCHAR_ULONG:
            case DC_SIGCHAR_LONGLONG:
            case DC_SIGCHAR_ULONGLONG:
            case DC_SIGCHAR_FLOAT:
            case DC_SIGCHAR_DOUBLE:
            case DC_SIGCHAR_POINTER:
            case DC_SIGCHAR_STRING:
            case DC_SIGCHAR_STRUCT:
                RETVAL->perl_sig[sig_pos] = '$';
                RETVAL->sig[sig_pos]      = sig[i];
                ++sig_pos;
                break;
            case DC_SIGCHAR_ENDARG:
                RETVAL->ret = sig[i + 1];
                break;
            default:
                break;
        };
    }
    //warn("Now: %s|%s|%c", RETVAL->perl_sig, RETVAL->sig, RETVAL->ret);
    return RETVAL;
}

MODULE = Dyn PACKAGE = Dyn

void
DESTROY(...)
CODE:
    IV tmp = SvIV((SV*) SvRV(ST(0)));
    Call * call = INT2PTR(Call *, tmp);
    if (call == NULL)      return;
    if (call->lib != NULL) dlFreeLibrary( call->lib );
    if (call->cvm != NULL) dcFree(call->cvm);
    if (call->sig != NULL)       Safefree( call->sig );
    if (call->perl_sig != NULL ) Safefree( call->perl_sig );
    Safefree(call);

Call *
load(lib, const char * func_name, const char * sig, ...)
CODE:
    DLLib * lib;
    if (SvROK(ST(0)) && sv_derived_from(ST(0), "Dyn::DLLib")) {
        IV tmp = SvIV((SV*)SvRV(ST(0)));
        lib = INT2PTR(DLLib *, tmp);
    }
    else
        lib = dlLoadLibrary( (const char *)SvPV_nolen(ST(0)) );
    RETVAL = _load(aTHX_ lib, func_name, sig, func_name); // TODO: Accept alternate name?
OUTPUT:
    RETVAL

void
call(...)
PREINIT:
    int pos;
PPCODE:
    IV tmp = SvIV((SV*) SvRV(ST(0)));
    Call * call = INT2PTR(Call *, tmp);
    pos = 1;
    //warn("call( ... )");
    _call_

void
call_Dyn(...)
PREINIT:
    int pos;
PPCODE:
    Call * call;
    if (XSANY.any_ptr == NULL) {
        croak("Malformed pointer"); // TODO: Better describe that this is wrong
        XSRETURN_EMPTY;
    }
    call = (Call *) XSANY.any_ptr;
    pos = 0;
    //warn("call_Dyn( ... )");
    _call_

void
call_attach(Call * call, ...)
PREINIT:
    int pos;
PPCODE:
    pos = 0;
    //warn("call_attach( ... )");
    _call_

CV *
attach( ... )
PREINIT:
    const char *  name;
    Call * call;
CODE:
    //warn("ix == %d | items == %d", ix, items);
    name = (const char *) SvPV_nolen(ST(0));

    /* Create a new XSUB instance at runtime and set it's XSANY.any_ptr to contain the
     * necessary user data. name can be NULL => fully anonymous sub!
    **/
    CV * cv;
    STMT_START {
        cv = newXSproto_portable(name, XS_Dyn_call_attach, (char*)__FILE__, "$$");
        if (cv == NULL)
            croak("ARG! Something went really wrong while installing a new XSUB!");
        XSANY.any_ptr = (void *) call;
    } STMT_END;
    RETVAL = cv;
OUTPUT:
    RETVAL

void
MODIFY_CODE_ATTRIBUTES(char * name, void * code, ...)
PREINIT:
    I32 i;
    STRLEN attrlen;
    dXSTARG;
PPCODE:
    //warn("Here: ix == %d", ix);
    //warn ("GvENAME(CvGV(code)): %s", GvENAME(CvGV((SV *) code)));
    strcat(name, "::");
    strcat(name, GvENAME(CvGV((SV *) code)));
    for (i = 2; i < items; ++i) {
        //warn("A");
        const char * attr = SvPV_const(ST(i), attrlen);
        //warn ("A2: %s", attr);
        //warn("B");
    /*
        AV *match_list;
        I32 num_matches, j;

        const char * m = "m[^(\\w+)\\s*?(.+?)$]";
        warn("B2: %s", attr);

        num_matches = matches(ST(i), m, &match_list);

        warn (" ==> %d matches", num_matches);
        for (j = 0; j < num_matches; j++)
            warn(" => [%d] match: %s", j, SvPV_nolen(*av_fetch(match_list, j, FALSE)));
    */
        char * attr_name = strtok ((char *) attr, "(");
        if (strcmp(attr_name, "Dyn") != 0) { // We only handle :Dyn
            sv_setpv(ST(0), attr_name);
            XSRETURN(1);
        }

        //warn("C");
        char * library = strtok(NULL, ",");
        //warn("Ca");
        char * signature = clean(strtok(NULL, ", ")); // Might have a trailing ')' but who cares...
        //warn("Cb");
        char * symbol = strtok(NULL, ")");
        //warn("D");
        if (symbol == NULL)
            symbol = GvENAME(CvGV(code));
        else
            symbol = clean(symbol);
        //warn("E");
        // named subroutine
        Delayed * _now;
        Newx(_now, 1, Delayed);

        Newx(_now->library, strlen(library) +1, char);
        memcpy((void *) _now->library, library, strlen(library)+1);

        Newx(_now->signature, strlen(signature)+1, char);
        memcpy((void *) _now->signature, signature, strlen(signature)+1);

        Newx(_now->symbol, strlen(symbol) +1, char);
        memcpy((void *) _now->symbol, symbol, strlen(symbol)+1);

        Newx(_now->name, strlen(name)+1, char);
        memcpy((void *) _now->name, name, strlen(name)+1);

        _now->next = delayed;
        delayed = _now;
    }

void
AUTOLOAD( ... )
PPCODE:
    char* autoload = SvPV_nolen( sv_mortalcopy( get_sv( "Dyn::AUTOLOAD", TRUE ) ) );
    //warn("$AUTOLOAD? %s", autoload);
    {   Delayed * _prev = delayed;
        Delayed * _now  = delayed;
        while (_now != NULL) {
            if (strcmp(_now->name, autoload) == 0) {
                //warn(" signature: %s", _now->signature);
                //warn(" name:      %s", _now->name);
                //warn(" symbol:    %s", _now->symbol);
                //warn(" library:   %s", _now->library);
                SV * lib;
                //if (strstr(_now->library, "{")) {
                    char eval[1024]; // idk
                    sprintf(eval, "sub{sub{%s}}->()->()", _now->library); // context magic
                    //warn("eval: %s", eval);
                    lib = eval_pv( eval, FALSE ); // TODO: Cache this?
                //}
                //else
                //    lib = newSVpv(_now->library, strlen(_now->library));
                //SV * lib = get_sv(_now->library, TRUE);
                //warn("     => %s", (const char *) SvPV_nolen(lib));
                char *sig, ret, met;
                DLLib * _lib = dlLoadLibrary(SvPV_nolen(lib));
                Call * call = _load(aTHX_ _lib, _now->symbol, _now->signature, _now->name);
               // warn("Z");
                if (call != NULL) {
                    CV * cv;
                    //warn("Y");
                    STMT_START {
                       // warn("M");
                        cv = newXSproto_portable(autoload, XS_Dyn_call_Dyn, (char*)__FILE__, call->perl_sig);
                        //warn("N");
                        if (cv == NULL)
                            croak("ARG! Something went really wrong while installing a new XSUB!");
                        //warn("Q");
                        XSANY.any_ptr = (void *) call;
                        //warn("O");
                    } STMT_END;
                    //warn("P");
                    int pos = 0;
                    //warn("AUTOLOAD( ... )");
                    _call_
                    _prev->next = _now->next;
                    Safefree(_now);
                }
                else
                    croak("Oops!");
                //warn("A");
                //if (_prev = NULL)
                //    _prev = _now;
                return;
             }
            _prev = _now;
            _now  = _now->next;
        }
    }
    die("Undefined subroutine &%s", autoload);

BOOT:
    delayed = NULL;
