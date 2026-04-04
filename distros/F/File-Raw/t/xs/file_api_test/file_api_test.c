/*
 * file_api_test.c - Test module that uses file's C API (file_hooks.h)
 *
 * Demonstrates how other XS modules can:
 * - Register read/write hooks via C API
 * - Use the hook macros for fast path checks
 * - Transform file data in C
 */

#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

/* XS_EXTERNAL compatibility - introduced in 5.16 */
#ifndef XS_EXTERNAL
#  define XS_EXTERNAL(name) XS(name)
#endif

/* PTR2IV compatibility - for older Perls */
#ifndef PTR2IV
#  define PTR2IV(p) ((IV)(p))
#endif

/* Include the file hooks C API */
#include "file_hooks.h"

/* =========================================
 * Test hook functions
 * =========================================
 */

/* Hook that uppercases all content */
static SV* hook_uppercase(pTHX_ FileHookContext *ctx) {
    STRLEN len;
    char *str;
    STRLEN i;
    SV *result;

    if (!ctx->data || !SvOK(ctx->data)) {
        return ctx->data;
    }

    /* Make a copy and uppercase it */
    result = newSVsv(ctx->data);
    str = SvPV(result, len);
    for (i = 0; i < len; i++) {
        if (str[i] >= 'a' && str[i] <= 'z') {
            str[i] = str[i] - 'a' + 'A';
        }
    }

    return result;
}

/* Hook that lowercases all content */
static SV* hook_lowercase(pTHX_ FileHookContext *ctx) {
    STRLEN len;
    char *str;
    STRLEN i;
    SV *result;

    if (!ctx->data || !SvOK(ctx->data)) {
        return ctx->data;
    }

    result = newSVsv(ctx->data);
    str = SvPV(result, len);
    for (i = 0; i < len; i++) {
        if (str[i] >= 'A' && str[i] <= 'Z') {
            str[i] = str[i] - 'A' + 'a';
        }
    }

    return result;
}

/* Hook that adds a prefix */
static SV* hook_add_prefix(pTHX_ FileHookContext *ctx) {
    SV *result;
    const char *prefix = (const char *)ctx->user_data;

    if (!ctx->data || !SvOK(ctx->data)) {
        return ctx->data;
    }

    result = newSVpv(prefix ? prefix : "[PREFIX]", 0);
    sv_catsv(result, ctx->data);

    return result;
}

/* Hook that reverses content (for encoding simulation) */
static SV* hook_reverse(pTHX_ FileHookContext *ctx) {
    STRLEN len;
    const char *src;
    char *dst;
    STRLEN i;
    SV *result;

    if (!ctx->data || !SvOK(ctx->data)) {
        return ctx->data;
    }

    src = SvPV(ctx->data, len);
    result = newSV(len + 1);
    SvPOK_on(result);
    dst = SvPVX(result);

    for (i = 0; i < len; i++) {
        dst[i] = src[len - 1 - i];
    }
    dst[len] = '\0';
    SvCUR_set(result, len);

    return result;
}

/* =========================================
 * XS functions to control hooks from Perl
 * =========================================
 */

/* Install uppercase hook */
static XS(xs_install_uppercase_hook) {
    dXSARGS;
    const char *phase_name;
    FileHookPhase phase;

    if (items != 1) croak("Usage: file_api_test::install_uppercase_hook($phase)");

    phase_name = SvPV_nolen(ST(0));
    if (strcmp(phase_name, "read") == 0) {
        phase = FILE_HOOK_PHASE_READ;
        file_set_read_hook(aTHX_ hook_uppercase, NULL);
    } else if (strcmp(phase_name, "write") == 0) {
        phase = FILE_HOOK_PHASE_WRITE;
        file_set_write_hook(aTHX_ hook_uppercase, NULL);
    } else {
        croak("Unknown phase: %s (use 'read' or 'write')", phase_name);
    }

    XSRETURN_YES;
}

/* Install lowercase hook */
static XS(xs_install_lowercase_hook) {
    dXSARGS;
    const char *phase_name;

    if (items != 1) croak("Usage: file_api_test::install_lowercase_hook($phase)");

    phase_name = SvPV_nolen(ST(0));
    if (strcmp(phase_name, "read") == 0) {
        file_set_read_hook(aTHX_ hook_lowercase, NULL);
    } else if (strcmp(phase_name, "write") == 0) {
        file_set_write_hook(aTHX_ hook_lowercase, NULL);
    } else {
        croak("Unknown phase: %s", phase_name);
    }

    XSRETURN_YES;
}

/* Install reverse hook (for encoding simulation) */
static XS(xs_install_reverse_hook) {
    dXSARGS;
    const char *phase_name;

    if (items != 1) croak("Usage: file_api_test::install_reverse_hook($phase)");

    phase_name = SvPV_nolen(ST(0));
    if (strcmp(phase_name, "read") == 0) {
        file_set_read_hook(aTHX_ hook_reverse, NULL);
    } else if (strcmp(phase_name, "write") == 0) {
        file_set_write_hook(aTHX_ hook_reverse, NULL);
    } else {
        croak("Unknown phase: %s", phase_name);
    }

    XSRETURN_YES;
}

/* Clear hooks */
static XS(xs_clear_hook) {
    dXSARGS;
    const char *phase_name;

    if (items != 1) croak("Usage: file_api_test::clear_hook($phase)");

    phase_name = SvPV_nolen(ST(0));
    if (strcmp(phase_name, "read") == 0) {
        file_set_read_hook(aTHX_ NULL, NULL);
    } else if (strcmp(phase_name, "write") == 0) {
        file_set_write_hook(aTHX_ NULL, NULL);
    } else {
        croak("Unknown phase: %s", phase_name);
    }

    XSRETURN_YES;
}

/* Check if hook is set using C macro */
static XS(xs_has_hook) {
    dXSARGS;
    const char *phase_name;
    int has;

    if (items != 1) croak("Usage: file_api_test::has_hook($phase)");

    phase_name = SvPV_nolen(ST(0));
    if (strcmp(phase_name, "read") == 0) {
        has = FILE_HAS_READ_HOOK();
    } else if (strcmp(phase_name, "write") == 0) {
        has = FILE_HAS_WRITE_HOOK();
    } else {
        croak("Unknown phase: %s", phase_name);
    }

    ST(0) = has ? &PL_sv_yes : &PL_sv_no;
    XSRETURN(1);
}

/* Get hook function pointer (for testing) */
static XS(xs_get_hook_ptr) {
    dXSARGS;
    const char *phase_name;
    file_hook_func func = NULL;

    if (items != 1) croak("Usage: file_api_test::get_hook_ptr($phase)");

    phase_name = SvPV_nolen(ST(0));
    if (strcmp(phase_name, "read") == 0) {
        func = file_get_read_hook();
    } else if (strcmp(phase_name, "write") == 0) {
        func = file_get_write_hook();
    }

    if (func) {
        ST(0) = sv_2mortal(newSViv(PTR2IV(func)));
    } else {
        ST(0) = &PL_sv_undef;
    }
    XSRETURN(1);
}

/* Test direct hook invocation from C */
static XS(xs_transform_string) {
    dXSARGS;
    const char *transform;
    SV *input;
    FileHookContext ctx;
    SV *result;

    if (items != 2) croak("Usage: file_api_test::transform_string($transform, $string)");

    transform = SvPV_nolen(ST(0));
    input = ST(1);

    ctx.path = "test";
    ctx.data = input;
    ctx.phase = FILE_HOOK_PHASE_READ;
    ctx.user_data = NULL;
    ctx.cancel = 0;

    if (strcmp(transform, "uppercase") == 0) {
        result = hook_uppercase(aTHX_ &ctx);
    } else if (strcmp(transform, "lowercase") == 0) {
        result = hook_lowercase(aTHX_ &ctx);
    } else if (strcmp(transform, "reverse") == 0) {
        result = hook_reverse(aTHX_ &ctx);
    } else {
        croak("Unknown transform: %s", transform);
    }

    ST(0) = sv_2mortal(result);
    XSRETURN(1);
}

/* Boot function */
XS_EXTERNAL(boot_file_api_test);
XS_EXTERNAL(boot_file_api_test) {
    dXSARGS;
    PERL_UNUSED_VAR(items);

    newXS("file_api_test::install_uppercase_hook", xs_install_uppercase_hook, __FILE__);
    newXS("file_api_test::install_lowercase_hook", xs_install_lowercase_hook, __FILE__);
    newXS("file_api_test::install_reverse_hook", xs_install_reverse_hook, __FILE__);
    newXS("file_api_test::clear_hook", xs_clear_hook, __FILE__);
    newXS("file_api_test::has_hook", xs_has_hook, __FILE__);
    newXS("file_api_test::get_hook_ptr", xs_get_hook_ptr, __FILE__);
    newXS("file_api_test::transform_string", xs_transform_string, __FILE__);

    XSRETURN_YES;
}
