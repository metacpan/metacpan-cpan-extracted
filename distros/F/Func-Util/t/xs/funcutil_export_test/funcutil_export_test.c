/*
 * funcutil_export_test.c - Test module that uses Func::Util's export registry C API
 *
 * Demonstrates how other XS modules can register functions with Func::Util
 * using funcutil_register_export_xs(), allowing users to import them via:
 *   use Func::Util qw(their_functions);
 */

#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

/* Perl version compatibility (XS_INTERNAL, XS_EXTERNAL fallbacks for pre-5.16) */
#include "funcutil_compat.h"

/* Include the Func::Util export registry API */
#include "funcutil_export.h"

/* =========================================
 * XS functions to register with Func::Util
 * =========================================
 */

/* xs_double - multiply by 2 */
XS_INTERNAL(xs_double) {
    dXSARGS;
    if (items != 1) croak("Usage: xs_double($n)");

    NV n = SvNV(ST(0));
    ST(0) = sv_2mortal(newSVnv(n * 2));
    XSRETURN(1);
}

/* xs_triple - multiply by 3 */
XS_INTERNAL(xs_triple) {
    dXSARGS;
    if (items != 1) croak("Usage: xs_triple($n)");

    NV n = SvNV(ST(0));
    ST(0) = sv_2mortal(newSVnv(n * 3));
    XSRETURN(1);
}

/* xs_square - square a number */
XS_INTERNAL(xs_square) {
    dXSARGS;
    if (items != 1) croak("Usage: xs_square($n)");

    NV n = SvNV(ST(0));
    ST(0) = sv_2mortal(newSVnv(n * n));
    XSRETURN(1);
}

/* xs_sum_args - sum all arguments */
XS_INTERNAL(xs_sum_args) {
    dXSARGS;
    NV sum = 0;
    IV i;

    for (i = 0; i < items; i++) {
        sum += SvNV(ST(i));
    }

    ST(0) = sv_2mortal(newSVnv(sum));
    XSRETURN(1);
}

/* xs_concat_args - concatenate all string arguments */
XS_INTERNAL(xs_concat_args) {
    dXSARGS;
    SV *result = newSVpvn("", 0);
    IV i;

    for (i = 0; i < items; i++) {
        STRLEN len;
        const char *str = SvPV(ST(i), len);
        sv_catpvn(result, str, len);
    }

    ST(0) = sv_2mortal(result);
    XSRETURN(1);
}

/* xs_is_lucky - returns true if number is 7 */
XS_INTERNAL(xs_is_lucky) {
    dXSARGS;
    if (items != 1) croak("Usage: xs_is_lucky($n)");

    IV n = SvIV(ST(0));
    ST(0) = (n == 7) ? &PL_sv_yes : &PL_sv_no;
    XSRETURN(1);
}

/* xs_make_pair - returns two values */
XS_INTERNAL(xs_make_pair) {
    dXSARGS;
    if (items != 2) croak("Usage: xs_make_pair($a, $b)");

    /* Return both arguments as a pair (list context) */
    ST(0) = sv_2mortal(newSVsv(ST(0)));
    ST(1) = sv_2mortal(newSVsv(ST(1)));
    XSRETURN(2);
}

/* =========================================
 * Functions accessible directly from the test module
 * (not registered with Func::Util, for comparison)
 * =========================================
 */

XS_INTERNAL(xs_direct_quadruple) {
    dXSARGS;
    if (items != 1) croak("Usage: funcutil_export_test::direct_quadruple($n)");

    NV n = SvNV(ST(0));
    ST(0) = sv_2mortal(newSVnv(n * 4));
    XSRETURN(1);
}

/* Boot function */
XS_EXTERNAL(boot_funcutil_export_test);
XS_EXTERNAL(boot_funcutil_export_test) {
    dXSARGS;
    PERL_UNUSED_VAR(items);

    /* Register XS functions directly on this package (for comparison) */
    newXS("funcutil_export_test::direct_quadruple", xs_direct_quadruple, __FILE__);

    /* Register XS functions with Func::Util's export registry
     * After this, users can do: use Func::Util qw(xs_double xs_triple ...);
     */
    funcutil_register_export_xs(aTHX_ "xs_double", xs_double);
    funcutil_register_export_xs(aTHX_ "xs_triple", xs_triple);
    funcutil_register_export_xs(aTHX_ "xs_square", xs_square);
    funcutil_register_export_xs(aTHX_ "xs_sum_args", xs_sum_args);
    funcutil_register_export_xs(aTHX_ "xs_concat_args", xs_concat_args);
    funcutil_register_export_xs(aTHX_ "xs_is_lucky", xs_is_lucky);
    funcutil_register_export_xs(aTHX_ "xs_make_pair", xs_make_pair);

    XSRETURN_YES;
}
