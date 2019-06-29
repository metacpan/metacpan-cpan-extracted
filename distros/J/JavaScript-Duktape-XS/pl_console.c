#include <stdarg.h>
#include "duk_console.h"
#include "pl_util.h"
#include "pl_console.h"

#define NEED_newRV_noinc_GLOBAL
#include "ppport.h"

#if !defined(va_copy)
#define va_copy(dest, src)  __va_copy(dest, src)
#endif

static int print_console_messages(duk_uint_t flags, void* data,
                                  const char* fmt, va_list ap)
{
    dTHX;
    PerlIO* fp = (flags & DUK_CONSOLE_TO_STDERR) ? PerlIO_stderr() : PerlIO_stdout();
    int ret = PerlIO_vprintf(fp, fmt, ap);

    UNUSED_ARG(data);
    if (flags & DUK_CONSOLE_FLUSH) {
        PerlIO_flush(fp);
    }
    return ret;
}


static void save_msg(pTHX_ Duk* duk, const char* target, SV* message)
{
    STRLEN tlen = strlen(target);
    AV* data = 0;
    int top = 0;
    SV* pvalue = 0;
    SV** found = hv_fetch(duk->msgs, target, tlen, 0);
    if (found) {
        SV* ref = SvRV(*found);
        /* value not a valid arrayref? bail out */
        if (SvTYPE(ref) != SVt_PVAV) {
            return;
        }
        data = (AV*) ref;
        top = av_len(data);
    } else {
        SV* ref = 0;
        data = newAV();
        ref = newRV_noinc((SV*) data);
        if (hv_store(duk->msgs, target, tlen, ref, 0)) {
            SvREFCNT_inc(ref);
        }
        top = -1;
    }

    pvalue = sv_2mortal(message);
    if (av_store(data, ++top, pvalue)) {
        SvREFCNT_inc(pvalue);
    }
    else {
        croak("Could not store message in target %*.*s\n", (int) tlen, (int) tlen, target);
    }
}

static int save_console_messages(duk_uint_t flags, void* data,
                                 const char* fmt, va_list ap)
{
    dTHX;
    Duk* duk = (Duk*) data;
    const char* target = (flags & DUK_CONSOLE_TO_STDERR) ? "stderr" : "stdout";
    SV* message = newSVpvs("");
    va_list args_copy;
    va_copy(args_copy, ap);
    sv_vcatpvf(message, fmt, &args_copy);
    save_msg(aTHX_ duk, target, message);
    return SvCUR(message);
}

int pl_console_init(Duk* duk)
{
    /* initialize console object */
    duk_console_init(duk->ctx, DUK_CONSOLE_PROXY_WRAPPER | DUK_CONSOLE_FLUSH);

    if (duk->flags & DUK_OPT_FLAG_SAVE_MESSAGES) {
        duk_console_register_handler(save_console_messages, duk);
    }
    else {
        duk_console_register_handler(print_console_messages, duk);
    }

    return 0;
}
