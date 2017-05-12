#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <avcall.h>
#include <callback.h>

typedef union
{
    signed char sc;
    unsigned char uc;
    signed short ss;
    unsigned short us;    
    signed int si;
    unsigned int ui;
    signed long sl;
    unsigned long ul;
    float f;
    double d;
    char *p;
}
general;

typedef struct
{
    SV *code;
    char sig[1];
}
callback_data;

static void callback_fn (void *data, va_alist av)
{
    dSP;
    char *arg_p;
    general arg;
    int i = 0;
    int flags = G_SCALAR;
    callback_data *cb = data;

    switch (cb->sig[1])
    {
    case 'v': va_start_void(av); flags = G_VOID; break;
    case 'c': va_start_schar(av);      break;
    case 'C': va_start_uchar(av);      break;
    case 's': va_start_short(av);      break;
    case 'S': va_start_ushort(av);     break;
    case 'i': va_start_int(av);        break;
    case 'I': va_start_uint(av);       break;
    case 'l': va_start_long(av);       break;
    case 'L': va_start_ulong(av);      break;
    case 'f': va_start_float(av);      break;
    case 'd': va_start_double(av);     break;
    case 'p': va_start_ptr(av, char*); break;
    }

    #ifdef WIN32 /* Set in Makefile.PL */
    if (cb->sig[0] == 's')
        av->flags |= __VA_STDCALL_CLEANUP;
    #endif

    ENTER;
    SAVETMPS;

    PUSHMARK(SP);

    arg_p = &cb->sig[2];
    while (*arg_p)
    {
        switch (*arg_p)
        {
        case 'c':
            arg.sc = va_arg_schar(av);
            XPUSHs(sv_2mortal(newSViv(arg.sc)));
            break;
        case 'C':
            arg.uc = va_arg_uchar(av);
            XPUSHs(sv_2mortal(newSViv(arg.uc)));
            break;
        case 's':
            arg.ss = va_arg_short(av);
            XPUSHs(sv_2mortal(newSViv(arg.ss)));
            break;
        case 'S':
            arg.us = va_arg_ushort(av);
            XPUSHs(sv_2mortal(newSViv(arg.us)));
            break;
        case 'i':
            arg.si = va_arg_int(av);
            XPUSHs(sv_2mortal(newSViv(arg.si)));
            break;
        case 'I':
            arg.ui = va_arg_uint(av);
            XPUSHs(sv_2mortal(newSViv(arg.ui)));
            break;
        case 'l':
            arg.sl = va_arg_long(av);
            XPUSHs(sv_2mortal(newSViv(arg.sl)));
            break;
        case 'L':
            arg.ul = va_arg_ulong(av);
            XPUSHs(sv_2mortal(newSViv(arg.ul)));
            break;
        case 'f':
            arg.f = va_arg_float(av);
            XPUSHs(sv_2mortal(newSVnv(arg.f)));
            break;
        case 'd':
            arg.d = va_arg_double(av);
            XPUSHs(sv_2mortal(newSVnv(arg.d)));
            break;
        case 'p':
            arg.p = va_arg_ptr(av, char*);
            XPUSHs(sv_2mortal(newSVpv(arg.p, 0)));
            break;
        }
        ++arg_p;
    }

    PUTBACK;

    /* G_EVAL??? */
    i = perl_call_sv(cb->code, flags);

    SPAGAIN;

    switch (cb->sig[1])
    {
    case 'v': va_return_void(av); break;
    case 'c': arg.sc = POPi; va_return_schar(av, arg.sc);     break;
    case 'C': arg.uc = POPi; va_return_uchar(av, arg.uc);     break;
    case 's': arg.ss = POPi; va_return_short(av, arg.ss);     break;
    case 'S': arg.us = POPi; va_return_ushort(av, arg.us);    break;
    case 'i': arg.si = POPi; va_return_int(av, arg.si);       break;
    case 'I': arg.ui = POPi; va_return_uint(av, arg.ui);      break;
    case 'l': arg.sl = POPi; va_return_long(av, arg.sl);      break;
    case 'L': arg.ul = POPi; va_return_ulong(av, arg.ul);     break;
    case 'f': arg.f  = POPn; va_return_double(av, arg.f);     break;
    case 'd': arg.d  = POPn; va_return_double(av, arg.d);     break;
    case 'p': arg.p  = POPp; va_return_ptr(av, char*, arg.p); break;
    }

    PUTBACK;
    FREETMPS;
    LEAVE;
}

static void validate_signature (char *sig)
{
    STRLEN i;
    STRLEN len = strlen(sig);

    if (len < 2)
        croak("Invalid function signature: %s (too short)", sig);

    if (*sig != 'c' && *sig != 's')
        croak("Invalid function signature: '%c' (should be 'c' or 's')", *sig);

    if (strchr("cCsSiIlLfdpv", sig[1]) == NULL)
        croak("Invalid return type: '%c' (should be one of \"cCsSiIlLfdpv\")", sig[1]);

    i = strspn(sig+2, "cCsSiIlLfdp");
    if (i != len-2)
        croak("Invalid argument type (arg %lu): '%c' (should be one of \"cCsSiIlLfdp\")",
              i+1, sig[i+2]);
}

MODULE = FFI            PACKAGE = FFI           

void
call(addr, sig, ...)
    void *addr;
    char *sig;

    PREINIT:
    int i;
    av_alist av;
    general rv;

    PPCODE:
    validate_signature(sig);

    switch (sig[1])
    {
    case 'v': av_start_void(av, addr);              break;
    case 'c': av_start_schar(av, addr, &rv.sc);     break;
    case 'C': av_start_uchar(av, addr, &rv.uc);     break;
    case 's': av_start_short(av, addr, &rv.ss);     break;
    case 'S': av_start_ushort(av, addr, &rv.us);    break;
    case 'i': av_start_int(av, addr, &rv.si);       break;
    case 'I': av_start_uint(av, addr, &rv.ui);      break;
    case 'l': av_start_long(av, addr, &rv.sl);      break;
    case 'L': av_start_ulong(av, addr, &rv.ul);     break;
    case 'f': av_start_float(av, addr, &rv.f);      break;
    case 'd': av_start_double(av, addr, &rv.d);     break;
    case 'p': av_start_ptr(av, addr, char*, &rv.p); break;
    }

    #ifdef WIN32 /* Set via Makefile.PL */
    if (sig[0] == 's')
        av.flags |= __AV_STDCALL_CLEANUP;
    #endif

    for (i = 2; i < items; ++i)
    {
        STRLEN l;
        general arg;
        char type = sig[i];

        if (type == 0)
            croak("FFI::call - too many args (%d expected)", i - 2);

        switch(type)
        {
        case 'c': arg.sc = SvIV(ST(i)); av_schar(av, arg.sc);        break;
        case 'C': arg.uc = SvIV(ST(i)); av_uchar(av, arg.uc);        break;
        case 's': arg.ss = SvIV(ST(i)); av_short(av, arg.ss);        break;
        case 'S': arg.us = SvIV(ST(i)); av_ushort(av, arg.us);       break;
        case 'i': arg.si = SvIV(ST(i)); av_int(av, arg.si);          break;
        case 'I': arg.ui = SvIV(ST(i)); av_uint(av, arg.ui);         break;
        case 'l': arg.sl = SvIV(ST(i)); av_long(av, arg.sl);         break;
        case 'L': arg.ul = SvIV(ST(i)); av_ulong(av, arg.ul);        break;
        case 'f': arg.f  = SvNV(ST(i)); av_float(av, arg.f);         break;
        case 'd': arg.d  = SvNV(ST(i)); av_double(av, arg.d);        break;
        case 'p': arg.p  = SvPV(ST(i), l); av_ptr(av, char*, arg.p); break;
        }
    }

    if (av_call(av) != 0)
        croak("FFI::call - call failed (internal error)");

    switch (sig[1])
    {
    case 'v': break;
    case 'c': XPUSHs(newSViv(rv.sc));   break;
    case 'C': XPUSHs(newSViv(rv.uc));   break;
    case 's': XPUSHs(newSViv(rv.ss));   break;
    case 'S': XPUSHs(newSViv(rv.us));   break;
    case 'i': XPUSHs(newSViv(rv.si));   break;
    case 'I': XPUSHs(newSViv(rv.ui));   break;
    case 'l': XPUSHs(newSViv(rv.sl));   break;
    case 'L': XPUSHs(newSViv(rv.ul));   break;
    case 'f': XPUSHs(newSVnv(rv.f));    break;
    case 'd': XPUSHs(newSVnv(rv.d));    break;
    case 'p': XPUSHs(newSVpv(rv.p, 0)); break;
    }


void
callback (sig, fn)
    char *sig;
    SV *fn;
    PREINIT:
    int cb;
    callback_data *data;
    SV *ret;
    HV *stash;
    PPCODE:
    validate_signature(sig);
    Newc(0, data, sizeof(callback_data) + strlen(sig), char, callback_data);
    data->code = newSVsv(fn);
    strcpy(data->sig, sig); 
    cb = (int)alloc_callback(callback_fn, data);
    ret = newSViv((IV)(cb));
    stash = gv_stashpv("FFI::Callback", 0);
    ST(0) = sv_2mortal(sv_bless(newRV_noinc(ret), stash));
    XSRETURN(1);

MODULE = FFI::Callback          PACKAGE = FFI::Callback

int
addr(self)
    SV *self;
PPCODE:
    XPUSHs(newSViv(SvIV(SvRV(self))));

void
DESTROY(self)
    SV *self;
PREINIT:
    IV cb;
    callback_data *data;
PPCODE:
    cb = SvIV(SvRV(self));
    data = (callback_data*)callback_data((void*)cb);
    SvREFCNT_dec(data->code);
    Safefree(data);
    free_callback((void*)cb);

MODULE = FFI            PACKAGE = FFI
