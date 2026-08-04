#ifndef JSF_TYPES_H
#define JSF_TYPES_H

/* The seven JSON types as a bitmask. `integer` is a subset of `number`
 * (draft 2020-12), so an integral value sets both bits and a `type` check is a
 * single `&` against the classified bit (principle 5). Needs perl.h (SV etc.)
 * which the .xs includes before jsf.h. */

enum {
    JSF_T_NULL    = 1u << 0,
    JSF_T_OBJECT  = 1u << 1,
    JSF_T_ARRAY   = 1u << 2,
    JSF_T_STRING  = 1u << 3,
    JSF_T_NUMBER  = 1u << 4,
    JSF_T_INTEGER = 1u << 5,
    JSF_T_BOOLEAN = 1u << 6
};

/* Is this blessed ref one of the known JSON boolean wrappers? */
static int jsf__is_bool_class(pTHX_ SV *sv) {
    static const char *const cls[] = {
        "JSON::PP::Boolean",
        "Cpanel::JSON::XS::Boolean",
        "JSON::XS::Boolean",
        "Types::Serialiser::Boolean",
        "File::Raw::JSON::Boolean",
        NULL
    };
    int i;
    for (i = 0; cls[i]; i++)
        if (sv_isa(sv, cls[i])) return 1;
    return 0;
}

/* Classify a live SV into one JSON type bit (integer also sets number). Called
 * once per value; the result is reused by the interpreter. JSON Schema types
 * follow the JSON value's type, not Perl's DWIM - a numeric-looking string is
 * a string here; `coerce` (phase 04) is the explicit opt-in. */
static unsigned jsf_classify_type(pTHX_ SV *sv) {
    if (!sv || !SvOK(sv)) return JSF_T_NULL;

    if (SvROK(sv)) {
        SV *rv = SvRV(sv);
        if (SvOBJECT(rv) && jsf__is_bool_class(aTHX_ sv)) return JSF_T_BOOLEAN;
        if (SvTYPE(rv) == SVt_PVHV) return JSF_T_OBJECT;
        if (SvTYPE(rv) == SVt_PVAV) return JSF_T_ARRAY;
        return 0;                        /* other refs are not JSON values */
    }

    /* Non-ref scalar: trust the numeric flags a JSON decoder set. */
    if (SvIOK(sv) && !SvPOK(sv)) return JSF_T_NUMBER | JSF_T_INTEGER;
    if (SvNOK(sv) && !SvPOK(sv)) {
        NV nv = SvNVX(sv);
        NV iv = (NV)(IV)nv;
        return (nv == iv) ? (unsigned)(JSF_T_NUMBER | JSF_T_INTEGER)
                          : (unsigned)JSF_T_NUMBER;
    }
    return JSF_T_STRING;
}

#endif /* JSF_TYPES_H */
