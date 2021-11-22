#include "lib/xshelper.h"

//#include <dyncall.h>
//#include <dynload.h>

// Based on https://github.com/svn2github/dyncall/blob/master/bindings/ruby/rbdc/rbdc.c

#include <dynload.h>
#include <dyncall.h>
#include <dyncall_value.h>
#include <dyncall_callf.h>
//#include <dyncall_signature.h>
//#include <dyncall_callback.h>

#include "lib/types.h"

char *
get_string(char * input) {
    return "Testing!";
}

MODULE = Dyn PACKAGE = Dyn::SubX

void
new(class, ...)
    SV* class;
PREINIT:
    unsigned int iStack;
    HV * hash;
    SV * obj;
    const char* classname;
PPCODE:
    if (sv_isobject(class)) {
        classname = sv_reftype(SvRV(class), 1);
    }
    else {
        if (!SvPOK(class))
            croak("Need an object or class name as first argument to the constructor.");
        classname = SvPV_nolen(class);
    }

    hash = (HV *)sv_2mortal((SV *)newHV());
    obj = sv_bless( newRV((SV*)hash), gv_stashpv(classname, 1) );

    if (items > 1) {
        if (!(items % 2))
            croak("Uneven number of argument to constructor.");
        for (iStack = 1; iStack < items; iStack += 2)
            hv_store_ent(hash, ST(iStack), newSVsv(ST(iStack+1)), 0);
    }
    XPUSHs(sv_2mortal(obj));

MODULE = Dyn  PACKAGE = Dyn::DynXSub

void
call(self, ...)
    DynXSub * self
CODE:
    int siglen = strlen(self->sig);
    //croak("here! items == %d; len == %d", items, siglen);
    if ( (items - 1) != siglen)
       croak_xs_usage(cv,  "self, ..."); // TODO: Get the correct number of arguments from signature
    size_t length = strlen(self->sig);
    size_t i;
    for (i = 0; i < length; i++) {
        printf("%c\n", self->sig[i]);    /* Print each character of the string. */
        switch (self->sig[i]) {
            case 'Z': dcArgPointer(self->lib->cvm, SvPV_nolen(ST(i + 1))); break;  // string
            default : croak("no idea what to pass...");                break;
        }
    }
    switch(self->ret[0]) {
        case 'v': dcCallVoid(self->lib->cvm, self->fptr); break;
        default : croak("no idea what to return...");     break;
    }

void
DESTROY(sub)
    DynXSub * sub
CODE:
    warn("Now in Dyncall::DynXSub::DESTROY");
    //if(sub->fptr  != NULL) free(sub->fptr);
    //if(sub->lib != NULL)   free(sub->syms);
    //dcFree(sub->syms);
    free( sub );

MODULE = Dyn::XSub  PACKAGE = Dyn::XSub

DynXSub *
new()
CODE:
    RETVAL = malloc(sizeof(DynXSub));
    RETVAL->name = NULL;
    RETVAL->sig  = NULL;
    RETVAL->fptr = NULL;
    RETVAL->lib  = NULL;
OUTPUT:
    RETVAL

void
DESTROY(sub)
    DynXSub * sub
CODE:
    warn("Now in Dyncall::XSub::DESTROY");
    //if(sub->fptr  != NULL) free(sub->fptr);
    //if(sub->lib != NULL)   free(sub->syms);
    //dcFree(sub->syms);
    free( sub );

MODULE = Dyn  PACKAGE = Dyn

Dyncall *
new(class, ...)
    SV* class;
CODE:
    RETVAL = malloc(sizeof(Dyncall));
    RETVAL->lib  = NULL;
    RETVAL->syms = NULL;
    RETVAL->cvm  = dcNewCallVM(4096/*@@@*/);
OUTPUT:
    RETVAL

MODULE = Dyn  PACKAGE = Dyn::DyncallPtr

void
DESTROY(lib)
    Dyncall * lib
CODE:
    printf("Now in NetconfigPtr::DESTROY\n");
    if(lib->lib  != NULL) dlFreeLibrary(lib->lib);
    if(lib->syms != NULL) dlSymsCleanup(lib->syms);
    dcFree(lib->cvm);
    free( lib );

DCCallVM *
cvm(self)
    Dyncall * self
CODE:
    RETVAL = self->cvm;
OUTPUT:
    RETVAL

DLLib *
load(self, path)
    Dyncall * self
    char * path
CODE:
    //Data_Get_Struct(self, rb_dcLibHandle, h);
    warn("%s", path);
    RETVAL = dlLoadLibrary(path);
    warn("A");
    if(self->lib) {
        warn("B");
        dlFreeLibrary(self->lib);
        warn("C");
        warn("D");
    }
    if (RETVAL)
        self->lib = RETVAL;
    else
        RETVAL = NULL;//sv_newmortal();
OUTPUT:
    RETVAL

bool
exists(self, sym)
    Dyncall * self
    char * sym
CODE:
    RETVAL = dlFindSymbol(self->lib, sym) ? 1 : 0;
OUTPUT:
    RETVAL

DLSyms *
init(self, path)
    Dyncall * self
    char * path
CODE:
    RETVAL = dlSymsInit(path);
    if(self->lib)
        dlSymsCleanup(self->syms);
    if (RETVAL)
        self->syms = RETVAL;
    else
        RETVAL = NULL;//sv_newmortal();
OUTPUT:
    RETVAL

long
symsCount(self)
    Dyncall * self
CODE:
    RETVAL = dlSymsCount(self->syms);
OUTPUT:
    RETVAL

AV *
symbols(self)
    Dyncall * self
CODE:
    size_t i, c;
    RETVAL = newAV();
    sv_2mortal((SV*)RETVAL);
    c = dlSymsCount(self->syms);
    for (i = 0; i < c; ++i) {
        const char * name = dlSymsName(self->syms, i);
        SV * tmp = newSV(0);
        sv_setpv(tmp, name);
        av_push(RETVAL, tmp);
    }
OUTPUT:
    RETVAL

DynXSub *
sub(self, name, sig, ret)
    Dyncall * self
    const char * name;
    const char * sig;
    const char * ret;
CODE:
    warn("... at %s line %d", __FILE__, __LINE__);
    DCpointer  * fptr;
    warn("... at %s line %d", __FILE__, __LINE__);
    DCCallVM   * cvm = self->cvm;
    warn("... at %s line %d", __FILE__, __LINE__);
    dcReset(cvm);
    warn("... at %s line %d", __FILE__, __LINE__);
    RETVAL = malloc(sizeof(DynXSub));
    RETVAL->name = name;
    warn("... at %s line %d", __FILE__, __LINE__);
    RETVAL->sig  = sig;
    warn("... at %s line %d", __FILE__, __LINE__);
    /* Get a pointer to the function and start pushing. */
    RETVAL->fptr = /*(DCpointer)*/ dlFindSymbol(self->lib, name );
    warn("... at %s line %d", __FILE__, __LINE__);
    RETVAL->lib  = self;
    warn("... at %s line %d", __FILE__, __LINE__);
    RETVAL->ret  = ret;
    warn("... at %s line %d", __FILE__, __LINE__);
OUTPUT:
    RETVAL


void
TestCall( DCCallVM * vm, DCpointer funcptr );
CODE:
    {dcMode ( vm , DC_CALL_C_DEFAULT );dcReset ( vm );
        //funcptr = &get_string;
        DCValue out;
        dcCallF(vm, &out, funcptr, "Z)v", "Hi");
        //printf("%c", out);
        //DCCallVM * vm, DCValue * result, DCpointer funcptr, const DCsigchar * signature
    }

MODULE = Dyn PACKAGE = Dyn

void
call(DLLib * lib, const char * name, const char * sig, ...)
CODE:
    DCpointer    fptr;
    DCCallVM   * cvm = dcNewCallVM( 1024 );
    dcReset(cvm);
    /* Get a pointer to the function and start pushing. */
    fptr = (DCpointer) dlFindSymbol(lib, name );
    //warn("%s", cvm);
    //warn("%s", fptr);
    bool err = 0;
    Size_t i;
    char ret;
    for(i = 3; i <= items; ++i) {
        char t = sig[i - 3];
        // TODO: add support for calling convention mode(s)
        switch(t) {
            case DC_SIGCHAR_CC_PREFIX:
                ++i; char t = sig[i - 3];
                switch (t) {
                    case DC_SIGCHAR_CC_DEFAULT:
                        dcMode(cvm, DC_CALL_C_DEFAULT); break;
                    case DC_SIGCHAR_CC_ELLIPSIS:
                        dcMode(cvm, DC_CALL_C_ELLIPSIS); break;
                    case DC_SIGCHAR_CC_ELLIPSIS_VARARGS:
                        dcMode(cvm, DC_CALL_C_ELLIPSIS_VARARGS); break;
                    case DC_SIGCHAR_CC_CDECL:
                        dcMode(cvm, DC_CALL_C_X86_CDECL); break;
                    case DC_SIGCHAR_CC_STDCALL:
                        dcMode(cvm, DC_CALL_C_X86_WIN32_STD); break;
                    case DC_SIGCHAR_CC_FASTCALL_MS:
                        dcMode(cvm, DC_CALL_C_X86_WIN32_FAST_MS); break;
                    case DC_SIGCHAR_CC_FASTCALL_GNU:
                        dcMode(cvm, DC_CALL_C_X86_WIN32_FAST_GNU); break;
                    case DC_SIGCHAR_CC_THISCALL_MS:
                        dcMode(cvm, DC_CALL_C_X86_WIN32_THIS_MS); break;
                    case DC_SIGCHAR_CC_THISCALL_GNU:
                        dcMode(cvm, DC_CALL_C_X86_WIN32_FAST_GNU); break;
                    case DC_SIGCHAR_CC_ARM_ARM:
                        dcMode(cvm, DC_CALL_C_ARM_ARM); break;
                    case DC_SIGCHAR_CC_ARM_THUMB:
                        dcMode(cvm, DC_CALL_C_ARM_THUMB); break;
                    case DC_SIGCHAR_CC_SYSCALL:
                        dcMode(cvm, DC_CALL_SYS_DEFAULT); break;
                }
                break;
            case DC_SIGCHAR_ENDARG:
                // TODO: set next char as retval type
                ret = sig[ i - 2 ];
                break;
            case DC_SIGCHAR_VOID:
                dcArgPointer(cvm, NULL); break;
            case DC_SIGCHAR_BOOL:
                dcArgBool(cvm, SvNV(ST(i)) ? 1 : 0); break;
            case DC_SIGCHAR_UCHAR:
            case DC_SIGCHAR_CHAR:
                dcArgChar(cvm, SvNV(ST(i))); break;

            case DC_SIGCHAR_FLOAT:
                dcArgFloat(cvm, SvNV(ST(i))); break;
            case DC_SIGCHAR_USHORT:
            case DC_SIGCHAR_SHORT:
                dcArgShort(cvm, SvNV(ST(i))); break;
            case DC_SIGCHAR_UINT:
            case DC_SIGCHAR_INT:
                dcArgInt(cvm, SvNV(ST(i))); break;
            case DC_SIGCHAR_ULONG:
            case DC_SIGCHAR_LONG:
                dcArgLong(cvm, SvNV(ST(i))); break;
            //case DC_SIGCHAR_POINTER:
            //    dcArgPointer(cvm, SvIV(ST(i))); break;
            case DC_SIGCHAR_ULONGLONG:
            case DC_SIGCHAR_LONGLONG:
                dcArgLongLong(cvm, SvNV(ST(i))); break;
            case DC_SIGCHAR_DOUBLE:
                dcArgDouble(cvm, SvNV(ST(i))); break;
            case DC_SIGCHAR_STRING:
                dcArgPointer(cvm, SvPV_nolen(ST(i)));
                break;
            case DC_SIGCHAR_STRUCT: // XXX: dyncall structs aren't ready yet
            default:
                break;
        }
        /*
        switch (SvTYPE(itm)) {
            case SVt_NULL:
                warn("... at %s line %d", __FILE__, __LINE__);
                break;
            case SVt_IV:
                warn("... at %s line %d", __FILE__, __LINE__);
                dcArgInt(cvm, SvIV(itm));
                break;
            case SVt_NV:
                warn("... at %s line %d", __FILE__, __LINE__);
                break;
            //case SVt_RV:
                //warn ();
            case SVt_PV:
                warn("string at %s line %d", __FILE__, __LINE__);
                switch(t) {
                    case 'Z': dcArgPointer(cvm, SvPV_nolen(itm)); break;  // String.
                    default : err = 1;                         break;
                }
                break;
            case SVt_PVIV:
                warn("... at %s line %d", __FILE__, __LINE__);
                break;
            case SVt_PVNV:
                warn("... at %s line %d", __FILE__, __LINE__);
                break;
            case SVt_PVMG:
                warn("... at %s line %d", __FILE__, __LINE__);
                break;
            //case SVt_INVLIST:
            //   warn("... at %s line %d", __FILE__, __LINE__);
            //   break;
            case SVt_REGEXP:
                warn("... at %s line %d", __FILE__, __LINE__);
                break;
            case SVt_PVGV:
                warn("... at %s line %d", __FILE__, __LINE__);
                break;
            case SVt_PVLV:
                warn("... at %s line %d", __FILE__, __LINE__);
                break;
            case SVt_PVAV:
                warn("... at %s line %d", __FILE__, __LINE__);
                break;
            case SVt_PVHV:
                warn("... at %s line %d", __FILE__, __LINE__);
                break;
            case SVt_PVCV:
                warn("... at %s line %d", __FILE__, __LINE__);
                break;
            case SVt_PVFM:
                warn("... at %s line %d", __FILE__, __LINE__);
                break;
            case SVt_PVIO:
                warn("... at %s line %d", __FILE__, __LINE__);
                break;
            default:
                warn("skip! at %s line %d", __FILE__, __LINE__);
                err = 0;
                break;
        }*/
        if(err)
            croak("syntax error in signature or type mismatch at argument %d", i);
    }
    /* Get the return type and call the function. */
    //switch(sig[i-1]) {
    switch (ret) {
        case DC_SIGCHAR_FLOAT:
            ST(0) = newSVnv(dcCallFloat(cvm, fptr)); XSRETURN(1); break;
        case DC_SIGCHAR_DOUBLE:
            ST(0) = newSVnv(dcCallDouble(cvm, fptr)); XSRETURN(1); break;
        case DC_SIGCHAR_BOOL:
            ST(0) = newSViv(dcCallBool(cvm, fptr)); XSRETURN(1); break;
        case DC_SIGCHAR_CHAR:
            ST(0) = newSVnv(dcCallChar(cvm, fptr)); XSRETURN(1); break;
        case DC_SIGCHAR_SHORT:
                ST(0) = newSViv(dcCallShort(cvm, fptr)); XSRETURN(1); break;
        case DC_SIGCHAR_INT:
            ST(0) = newSViv(dcCallDouble(cvm, fptr)); XSRETURN(1); break;
        case DC_SIGCHAR_LONG:
            ST(0) = newSViv(dcCallLong(cvm, fptr)); XSRETURN(1); break;
        case DC_SIGCHAR_LONGLONG:
            ST(0) = newSViv(dcCallLongLong(cvm, fptr)); XSRETURN(1); break;
        case DC_SIGCHAR_POINTER:
            ST(0) = newSVnv(dcCallDouble(cvm, fptr)); XSRETURN(1); break;
        case DC_SIGCHAR_UCHAR:
        case DC_SIGCHAR_USHORT:
        case DC_SIGCHAR_UINT:
        case DC_SIGCHAR_ULONG:
        case DC_SIGCHAR_ULONGLONG:
            ST(0) = newSVuv(dcCallLongLong(cvm, fptr)); XSRETURN(1); break;
        case DC_SIGCHAR_STRING:
            ST(0) = newSVpv(dcCallPointer(cvm, fptr), 0); XSRETURN(1); break;
        case DC_SIGCHAR_VOID:
            dcCallVoid(cvm, fptr);
            break;
        case DC_SIGCHAR_STRUCT: // TODO: dyncall structs aren't ready upstream yet
            break;
        default:
            break;
    }

=pod

struct work is being done in repo but not yet installed with make

#include <dyncall_struct.h>

void
structTest( )
CODE:
    {
        typedef struct {
            double a, b, c, d;
        } S;

        size_t size;
        DCstruct* s = dcNewStruct(4, DEFAULT_ALIGNMENT);
        dcStructField(s, DC_SIGCHAR_DOUBLE, DEFAULT_ALIGNMENT, 1);
        dcStructField(s, DC_SIGCHAR_DOUBLE, DEFAULT_ALIGNMENT, 1);
        dcStructField(s, DC_SIGCHAR_DOUBLE, DEFAULT_ALIGNMENT, 1);
        dcStructField(s, DC_SIGCHAR_DOUBLE, DEFAULT_ALIGNMENT, 1);
        dcCloseStruct(s);

        //DC_TEST_STRUCT_SIZE(S, s);
        dcFreeStruct(s);
    }

=cut
