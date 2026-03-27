#include "horus.h"

/* ── Helper: create an SV from a UUID in the given format ──────── */

static SV * horus_uuid_to_sv(pTHX_ const unsigned char *uuid, int fmt) {
    int len = horus_format_length((horus_format_t)fmt);
    SV *sv = newSV(len + 1);
    char *buf = SvPVX(sv);
    horus_format_uuid(buf, uuid, (horus_format_t)fmt);
    buf[len] = '\0';
    SvCUR_set(sv, len);
    SvPOK_on(sv);
    return sv;
}

/* ── Helper: parse namespace UUID string to binary ─────────────── */

static int horus_parse_ns(pTHX_ SV *ns_sv, unsigned char *ns_out) {
    STRLEN ns_len;
    const char *ns_str = SvPV(ns_sv, ns_len);
    return horus_parse_uuid(ns_out, ns_str, ns_len);
}

/* ══════════════════════════════════════════════════════════════════
 * Custom ops - bypass XS subroutine dispatch overhead (5.14+)
 * ══════════════════════════════════════════════════════════════════ */

#if PERL_VERSION >= 14

/* ── Macro: generate ck_* check function ─────────────────────────
 * Each ck function replaces the entersub op_ppaddr with our pp_*  */

#define HORUS_CK(name) \
static OP *horus_ck_##name(pTHX_ OP *o, GV *namegv, SV *protosv) { \
    PERL_UNUSED_ARG(namegv); PERL_UNUSED_ARG(protosv); \
    o->op_ppaddr = pp_horus_##name; return o; \
}

/* ── XOP descriptors (forward declarations) ──────────────────── */

/* Format constants */
static XOP horus_xop_fmt_str, horus_xop_fmt_hex, horus_xop_fmt_braces,
           horus_xop_fmt_urn, horus_xop_fmt_base64, horus_xop_fmt_base32,
           horus_xop_fmt_crockford, horus_xop_fmt_binary,
           horus_xop_fmt_upper_str, horus_xop_fmt_upper_hex;

/* Namespace constants */
static XOP horus_xop_ns_dns, horus_xop_ns_url, horus_xop_ns_oid, horus_xop_ns_x500;

/* Generators */
static XOP horus_xop_uuid_v1, horus_xop_uuid_v2, horus_xop_uuid_v3,
           horus_xop_uuid_v4, horus_xop_uuid_v5, horus_xop_uuid_v6,
           horus_xop_uuid_v7, horus_xop_uuid_v8,
           horus_xop_uuid_nil, horus_xop_uuid_max;

/* Batch */
static XOP horus_xop_uuid_v4_bulk;

/* Utilities */
static XOP horus_xop_uuid_parse, horus_xop_uuid_validate,
           horus_xop_uuid_version, horus_xop_uuid_variant,
           horus_xop_uuid_cmp, horus_xop_uuid_convert,
           horus_xop_uuid_time, horus_xop_uuid_is_nil, horus_xop_uuid_is_max;

/* ── pp_* : Format constant ops ──────────────────────────────── */

#define PP_CONST_IV(name, val) \
static OP *pp_horus_##name(pTHX) { \
    dSP; I32 markix = POPMARK; SP = PL_stack_base + markix; \
    XPUSHs(sv_2mortal(newSViv(val))); PUTBACK; return NORMAL; \
} \
HORUS_CK(name)

PP_CONST_IV(fmt_str,       HORUS_FMT_STR)
PP_CONST_IV(fmt_hex,       HORUS_FMT_HEX)
PP_CONST_IV(fmt_braces,    HORUS_FMT_BRACES)
PP_CONST_IV(fmt_urn,       HORUS_FMT_URN)
PP_CONST_IV(fmt_base64,    HORUS_FMT_BASE64)
PP_CONST_IV(fmt_base32,    HORUS_FMT_BASE32)
PP_CONST_IV(fmt_crockford, HORUS_FMT_CROCKFORD)
PP_CONST_IV(fmt_binary,    HORUS_FMT_BINARY)
PP_CONST_IV(fmt_upper_str, HORUS_FMT_UPPER_STR)
PP_CONST_IV(fmt_upper_hex, HORUS_FMT_UPPER_HEX)

/* ── pp_* : Namespace constant ops ───────────────────────────── */

#define PP_CONST_PV(name, str, slen) \
static OP *pp_horus_##name(pTHX) { \
    dSP; I32 markix = POPMARK; SP = PL_stack_base + markix; \
    XPUSHs(sv_2mortal(newSVpvn(str, slen))); PUTBACK; return NORMAL; \
} \
HORUS_CK(name)

PP_CONST_PV(ns_dns,  "6ba7b810-9dad-11d1-80b4-00c04fd430c8", 36)
PP_CONST_PV(ns_url,  "6ba7b811-9dad-11d1-80b4-00c04fd430c8", 36)
PP_CONST_PV(ns_oid,  "6ba7b812-9dad-11d1-80b4-00c04fd430c8", 36)
PP_CONST_PV(ns_x500, "6ba7b814-9dad-11d1-80b4-00c04fd430c8", 36)

/* ── pp_* : Generator ops (optional format arg) ──────────────── */

/* uuid_v4 - hottest path, no state needed */
static OP *pp_horus_uuid_v4(pTHX) {
    dSP;
    I32 markix = POPMARK;
    I32 ax = markix + 1;
    I32 items = SP - PL_stack_base - markix - 1;
    int fmt = HORUS_FMT_STR;
    unsigned char uuid[16];

    if (items > 0) fmt = SvIV(PL_stack_base[ax]);

    horus_uuid_v4(uuid);

    SP = PL_stack_base + markix;
    XPUSHs(sv_2mortal(horus_uuid_to_sv(aTHX_ uuid, fmt)));
    PUTBACK;
    return NORMAL;
}
HORUS_CK(uuid_v4)

/* uuid_v1 - time-based, needs MY_CXT */
static OP *pp_horus_uuid_v1(pTHX) {
    dSP;
    dMY_CXT;
    I32 markix = POPMARK;
    I32 ax = markix + 1;
    I32 items = SP - PL_stack_base - markix - 1;
    int fmt = HORUS_FMT_STR;
    unsigned char uuid[16];

    if (items > 0) fmt = SvIV(PL_stack_base[ax]);

    horus_uuid_v1(uuid, &MY_CXT.v1_state);

    SP = PL_stack_base + markix;
    XPUSHs(sv_2mortal(horus_uuid_to_sv(aTHX_ uuid, fmt)));
    PUTBACK;
    return NORMAL;
}
HORUS_CK(uuid_v1)

/* uuid_v6 - reordered time, needs MY_CXT */
static OP *pp_horus_uuid_v6(pTHX) {
    dSP;
    dMY_CXT;
    I32 markix = POPMARK;
    I32 ax = markix + 1;
    I32 items = SP - PL_stack_base - markix - 1;
    int fmt = HORUS_FMT_STR;
    unsigned char uuid[16];

    if (items > 0) fmt = SvIV(PL_stack_base[ax]);

    horus_uuid_v6(uuid, &MY_CXT.v1_state, &MY_CXT.v6_state);

    SP = PL_stack_base + markix;
    XPUSHs(sv_2mortal(horus_uuid_to_sv(aTHX_ uuid, fmt)));
    PUTBACK;
    return NORMAL;
}
HORUS_CK(uuid_v6)

/* uuid_v7 - unix epoch, needs MY_CXT */
static OP *pp_horus_uuid_v7(pTHX) {
    dSP;
    dMY_CXT;
    I32 markix = POPMARK;
    I32 ax = markix + 1;
    I32 items = SP - PL_stack_base - markix - 1;
    int fmt = HORUS_FMT_STR;
    unsigned char uuid[16];

    if (items > 0) fmt = SvIV(PL_stack_base[ax]);

    horus_uuid_v7(uuid, &MY_CXT.v7_state);

    SP = PL_stack_base + markix;
    XPUSHs(sv_2mortal(horus_uuid_to_sv(aTHX_ uuid, fmt)));
    PUTBACK;
    return NORMAL;
}
HORUS_CK(uuid_v7)

/* uuid_nil */
static OP *pp_horus_uuid_nil(pTHX) {
    dSP;
    I32 markix = POPMARK;
    I32 ax = markix + 1;
    I32 items = SP - PL_stack_base - markix - 1;
    int fmt = HORUS_FMT_STR;
    unsigned char uuid[16];

    if (items > 0) fmt = SvIV(PL_stack_base[ax]);

    horus_uuid_nil(uuid);

    SP = PL_stack_base + markix;
    XPUSHs(sv_2mortal(horus_uuid_to_sv(aTHX_ uuid, fmt)));
    PUTBACK;
    return NORMAL;
}
HORUS_CK(uuid_nil)

/* uuid_max */
static OP *pp_horus_uuid_max(pTHX) {
    dSP;
    I32 markix = POPMARK;
    I32 ax = markix + 1;
    I32 items = SP - PL_stack_base - markix - 1;
    int fmt = HORUS_FMT_STR;
    unsigned char uuid[16];

    if (items > 0) fmt = SvIV(PL_stack_base[ax]);

    horus_uuid_max(uuid);

    SP = PL_stack_base + markix;
    XPUSHs(sv_2mortal(horus_uuid_to_sv(aTHX_ uuid, fmt)));
    PUTBACK;
    return NORMAL;
}
HORUS_CK(uuid_max)

/* ── pp_* : Multi-arg generator ops ──────────────────────────── */

/* uuid_v2(domain, id?, fmt?) */
static OP *pp_horus_uuid_v2(pTHX) {
    dSP;
    dMY_CXT;
    I32 markix = POPMARK;
    I32 ax = markix + 1;
    I32 items = SP - PL_stack_base - markix - 1;
    int fmt = HORUS_FMT_STR;
    int domain;
    uint32_t local_id;
    unsigned char uuid[16];

    if (items < 1) croak("uuid_v2 requires at least a domain argument");

    domain = SvIV(PL_stack_base[ax]);

    if (items >= 2 && SvOK(PL_stack_base[ax + 1])) {
        local_id = (uint32_t)SvUV(PL_stack_base[ax + 1]);
    } else {
        if (domain == 0)      local_id = (uint32_t)getuid();
        else if (domain == 1) local_id = (uint32_t)getgid();
        else                  local_id = 0;
    }

    if (items >= 3) fmt = SvIV(PL_stack_base[ax + 2]);

    horus_uuid_v2(uuid, &MY_CXT.v1_state, domain, local_id);

    SP = PL_stack_base + markix;
    XPUSHs(sv_2mortal(horus_uuid_to_sv(aTHX_ uuid, fmt)));
    PUTBACK;
    return NORMAL;
}
HORUS_CK(uuid_v2)

/* uuid_v3(ns, name, fmt?) */
static OP *pp_horus_uuid_v3(pTHX) {
    dSP;
    I32 markix = POPMARK;
    I32 ax = markix + 1;
    I32 items = SP - PL_stack_base - markix - 1;
    int fmt = HORUS_FMT_STR;
    unsigned char ns_bytes[16], uuid[16];
    STRLEN name_len;
    const char *name_str;

    if (items < 2) croak("uuid_v3 requires namespace and name arguments");
    if (items > 2) fmt = SvIV(PL_stack_base[ax + 2]);

    if (!horus_parse_ns(aTHX_ PL_stack_base[ax], ns_bytes))
        croak("Horus: invalid namespace UUID");

    name_str = SvPV(PL_stack_base[ax + 1], name_len);
    horus_uuid_v3(uuid, ns_bytes, (const unsigned char *)name_str, name_len);

    SP = PL_stack_base + markix;
    XPUSHs(sv_2mortal(horus_uuid_to_sv(aTHX_ uuid, fmt)));
    PUTBACK;
    return NORMAL;
}
HORUS_CK(uuid_v3)

/* uuid_v5(ns, name, fmt?) */
static OP *pp_horus_uuid_v5(pTHX) {
    dSP;
    I32 markix = POPMARK;
    I32 ax = markix + 1;
    I32 items = SP - PL_stack_base - markix - 1;
    int fmt = HORUS_FMT_STR;
    unsigned char ns_bytes[16], uuid[16];
    STRLEN name_len;
    const char *name_str;

    if (items < 2) croak("uuid_v5 requires namespace and name arguments");
    if (items > 2) fmt = SvIV(PL_stack_base[ax + 2]);

    if (!horus_parse_ns(aTHX_ PL_stack_base[ax], ns_bytes))
        croak("Horus: invalid namespace UUID");

    name_str = SvPV(PL_stack_base[ax + 1], name_len);
    horus_uuid_v5(uuid, ns_bytes, (const unsigned char *)name_str, name_len);

    SP = PL_stack_base + markix;
    XPUSHs(sv_2mortal(horus_uuid_to_sv(aTHX_ uuid, fmt)));
    PUTBACK;
    return NORMAL;
}
HORUS_CK(uuid_v5)

/* uuid_v8(custom_data, fmt?) */
static OP *pp_horus_uuid_v8(pTHX) {
    dSP;
    I32 markix = POPMARK;
    I32 ax = markix + 1;
    I32 items = SP - PL_stack_base - markix - 1;
    int fmt = HORUS_FMT_STR;
    unsigned char uuid[16];
    STRLEN data_len;
    const char *data_str;

    if (items < 1) croak("uuid_v8 requires custom data argument");
    if (items > 1) fmt = SvIV(PL_stack_base[ax + 1]);

    data_str = SvPV(PL_stack_base[ax], data_len);
    if (data_len < 16) croak("Horus: uuid_v8 requires 16 bytes of custom data");

    horus_uuid_v8(uuid, (const unsigned char *)data_str);

    SP = PL_stack_base + markix;
    XPUSHs(sv_2mortal(horus_uuid_to_sv(aTHX_ uuid, fmt)));
    PUTBACK;
    return NORMAL;
}
HORUS_CK(uuid_v8)

/* ── pp_* : Batch op ─────────────────────────────────────────── */

/* uuid_v4_bulk(count, fmt?) - returns list */
static OP *pp_horus_uuid_v4_bulk(pTHX) {
    dSP;
    I32 markix = POPMARK;
    I32 ax = markix + 1;
    I32 items = SP - PL_stack_base - markix - 1;
    int fmt = HORUS_FMT_STR;
    int count, i;

    if (items < 1) croak("uuid_v4_bulk requires count argument");

    count = SvIV(PL_stack_base[ax]);
    if (items > 1) fmt = SvIV(PL_stack_base[ax + 1]);

    SP = PL_stack_base + markix;

    if (count <= 0) {
        PUTBACK;
        return NORMAL;
    }

    EXTEND(SP, count);

    if (count <= 256) {
        for (i = 0; i < count; i++) {
            unsigned char uuid[16];
            horus_uuid_v4(uuid);
            PUSHs(sv_2mortal(horus_uuid_to_sv(aTHX_ uuid, fmt)));
        }
    } else {
        unsigned char *buf;
        Newx(buf, (STRLEN)count * 16, unsigned char);
        horus_random_bulk(buf, (size_t)count * 16);
        for (i = 0; i < count; i++) {
            unsigned char *uuid = buf + i * 16;
            horus_stamp_version_variant(uuid, 4);
            PUSHs(sv_2mortal(horus_uuid_to_sv(aTHX_ uuid, fmt)));
        }
        Safefree(buf);
    }

    PUTBACK;
    return NORMAL;
}
HORUS_CK(uuid_v4_bulk)

/* ── pp_* : Utility ops ──────────────────────────────────────── */

/* uuid_parse(input) -> binary SV */
static OP *pp_horus_uuid_parse(pTHX) {
    dSP;
    I32 markix = POPMARK;
    I32 ax = markix + 1;
    I32 items = SP - PL_stack_base - markix - 1;
    unsigned char uuid[16];
    STRLEN in_len;
    const char *in_str;

    if (items < 1) croak("uuid_parse requires 1 argument");

    in_str = SvPV(PL_stack_base[ax], in_len);
    if (horus_parse_uuid(uuid, in_str, in_len) != HORUS_PARSE_OK)
        croak("Horus: cannot parse UUID string");

    SP = PL_stack_base + markix;
    XPUSHs(sv_2mortal(newSVpvn((const char *)uuid, 16)));
    PUTBACK;
    return NORMAL;
}
HORUS_CK(uuid_parse)

/* uuid_validate(input) -> 1/0 */
static OP *pp_horus_uuid_validate(pTHX) {
    dSP;
    I32 markix = POPMARK;
    I32 ax = markix + 1;
    I32 items = SP - PL_stack_base - markix - 1;
    STRLEN in_len;
    const char *in_str;

    if (items < 1) croak("uuid_validate requires 1 argument");

    in_str = SvPV(PL_stack_base[ax], in_len);

    SP = PL_stack_base + markix;
    XPUSHs(sv_2mortal(newSViv(horus_uuid_validate(in_str, in_len))));
    PUTBACK;
    return NORMAL;
}
HORUS_CK(uuid_validate)

/* uuid_version(input) -> int */
static OP *pp_horus_uuid_version(pTHX) {
    dSP;
    I32 markix = POPMARK;
    I32 ax = markix + 1;
    I32 items = SP - PL_stack_base - markix - 1;
    unsigned char uuid[16];
    STRLEN in_len;
    const char *in_str;

    if (items < 1) croak("uuid_version requires 1 argument");

    in_str = SvPV(PL_stack_base[ax], in_len);
    if (horus_parse_uuid(uuid, in_str, in_len) != HORUS_PARSE_OK)
        croak("Horus: cannot parse UUID string");

    SP = PL_stack_base + markix;
    XPUSHs(sv_2mortal(newSViv(horus_uuid_version_bin(uuid))));
    PUTBACK;
    return NORMAL;
}
HORUS_CK(uuid_version)

/* uuid_variant(input) -> int */
static OP *pp_horus_uuid_variant(pTHX) {
    dSP;
    I32 markix = POPMARK;
    I32 ax = markix + 1;
    I32 items = SP - PL_stack_base - markix - 1;
    unsigned char uuid[16];
    STRLEN in_len;
    const char *in_str;

    if (items < 1) croak("uuid_variant requires 1 argument");

    in_str = SvPV(PL_stack_base[ax], in_len);
    if (horus_parse_uuid(uuid, in_str, in_len) != HORUS_PARSE_OK)
        croak("Horus: cannot parse UUID string");

    SP = PL_stack_base + markix;
    XPUSHs(sv_2mortal(newSViv(horus_uuid_variant_bin(uuid))));
    PUTBACK;
    return NORMAL;
}
HORUS_CK(uuid_variant)

/* uuid_cmp(a, b) -> -1/0/1 */
static OP *pp_horus_uuid_cmp(pTHX) {
    dSP;
    I32 markix = POPMARK;
    I32 ax = markix + 1;
    I32 items = SP - PL_stack_base - markix - 1;
    unsigned char a[16], b[16];
    STRLEN a_len, b_len;
    const char *a_str, *b_str;
    int cmp;

    if (items < 2) croak("uuid_cmp requires 2 arguments");

    a_str = SvPV(PL_stack_base[ax], a_len);
    b_str = SvPV(PL_stack_base[ax + 1], b_len);

    if (horus_parse_uuid(a, a_str, a_len) != HORUS_PARSE_OK)
        croak("Horus: cannot parse first UUID");
    if (horus_parse_uuid(b, b_str, b_len) != HORUS_PARSE_OK)
        croak("Horus: cannot parse second UUID");

    cmp = horus_uuid_cmp_bin(a, b);

    SP = PL_stack_base + markix;
    XPUSHs(sv_2mortal(newSViv((cmp < 0) ? -1 : (cmp > 0) ? 1 : 0)));
    PUTBACK;
    return NORMAL;
}
HORUS_CK(uuid_cmp)

/* uuid_convert(input, fmt) -> formatted string */
static OP *pp_horus_uuid_convert(pTHX) {
    dSP;
    I32 markix = POPMARK;
    I32 ax = markix + 1;
    I32 items = SP - PL_stack_base - markix - 1;
    unsigned char uuid[16];
    STRLEN in_len;
    const char *in_str;
    int fmt;

    if (items < 2) croak("uuid_convert requires input and format arguments");

    in_str = SvPV(PL_stack_base[ax], in_len);
    fmt = SvIV(PL_stack_base[ax + 1]);

    if (horus_parse_uuid(uuid, in_str, in_len) != HORUS_PARSE_OK)
        croak("Horus: cannot parse UUID string");

    SP = PL_stack_base + markix;
    XPUSHs(sv_2mortal(horus_uuid_to_sv(aTHX_ uuid, fmt)));
    PUTBACK;
    return NORMAL;
}
HORUS_CK(uuid_convert)

/* uuid_time(input) -> NV epoch seconds */
static OP *pp_horus_uuid_time(pTHX) {
    dSP;
    I32 markix = POPMARK;
    I32 ax = markix + 1;
    I32 items = SP - PL_stack_base - markix - 1;
    unsigned char uuid[16];
    STRLEN in_len;
    const char *in_str;

    if (items < 1) croak("uuid_time requires 1 argument");

    in_str = SvPV(PL_stack_base[ax], in_len);
    if (horus_parse_uuid(uuid, in_str, in_len) != HORUS_PARSE_OK)
        croak("Horus: cannot parse UUID string");

    SP = PL_stack_base + markix;
    XPUSHs(sv_2mortal(newSVnv(horus_uuid_extract_time(uuid))));
    PUTBACK;
    return NORMAL;
}
HORUS_CK(uuid_time)

/* uuid_is_nil(input) -> 1/0 */
static OP *pp_horus_uuid_is_nil(pTHX) {
    dSP;
    I32 markix = POPMARK;
    I32 ax = markix + 1;
    I32 items = SP - PL_stack_base - markix - 1;
    unsigned char uuid[16];
    STRLEN in_len;
    const char *in_str;
    int result = 0;

    if (items < 1) croak("uuid_is_nil requires 1 argument");

    in_str = SvPV(PL_stack_base[ax], in_len);
    if (horus_parse_uuid(uuid, in_str, in_len) == HORUS_PARSE_OK)
        result = horus_uuid_is_nil_bin(uuid);

    SP = PL_stack_base + markix;
    XPUSHs(sv_2mortal(newSViv(result)));
    PUTBACK;
    return NORMAL;
}
HORUS_CK(uuid_is_nil)

/* uuid_is_max(input) -> 1/0 */
static OP *pp_horus_uuid_is_max(pTHX) {
    dSP;
    I32 markix = POPMARK;
    I32 ax = markix + 1;
    I32 items = SP - PL_stack_base - markix - 1;
    unsigned char uuid[16];
    STRLEN in_len;
    const char *in_str;
    int result = 0;

    if (items < 1) croak("uuid_is_max requires 1 argument");

    in_str = SvPV(PL_stack_base[ax], in_len);
    if (horus_parse_uuid(uuid, in_str, in_len) == HORUS_PARSE_OK)
        result = horus_uuid_is_max_bin(uuid);

    SP = PL_stack_base + markix;
    XPUSHs(sv_2mortal(newSViv(result)));
    PUTBACK;
    return NORMAL;
}
HORUS_CK(uuid_is_max)

/* ── Macro: XOP + call checker registration ──────────────────── */

#define HORUS_REG_XOP(c_name, desc) \
    XopENTRY_set(&horus_xop_##c_name, xop_name, "horus_" #c_name); \
    XopENTRY_set(&horus_xop_##c_name, xop_desc, desc); \
    Perl_custom_op_register(aTHX_ pp_horus_##c_name, &horus_xop_##c_name);

#define HORUS_REG_CK(perl_name, c_name) { \
    CV *cv = get_cv("Horus::" perl_name, 0); \
    if (cv) cv_set_call_checker(cv, horus_ck_##c_name, (SV *)cv); \
}

static void horus_register_custom_ops(pTHX) {
    /* Register XOP descriptors */
    HORUS_REG_XOP(fmt_str,       "UUID format: hyphenated")
    HORUS_REG_XOP(fmt_hex,       "UUID format: hex")
    HORUS_REG_XOP(fmt_braces,    "UUID format: braces")
    HORUS_REG_XOP(fmt_urn,       "UUID format: URN")
    HORUS_REG_XOP(fmt_base64,    "UUID format: base64")
    HORUS_REG_XOP(fmt_base32,    "UUID format: base32")
    HORUS_REG_XOP(fmt_crockford, "UUID format: Crockford")
    HORUS_REG_XOP(fmt_binary,    "UUID format: binary")
    HORUS_REG_XOP(fmt_upper_str, "UUID format: upper hyphenated")
    HORUS_REG_XOP(fmt_upper_hex, "UUID format: upper hex")

    HORUS_REG_XOP(ns_dns,  "UUID namespace: DNS")
    HORUS_REG_XOP(ns_url,  "UUID namespace: URL")
    HORUS_REG_XOP(ns_oid,  "UUID namespace: OID")
    HORUS_REG_XOP(ns_x500, "UUID namespace: X500")

    HORUS_REG_XOP(uuid_v1,  "generate UUID v1")
    HORUS_REG_XOP(uuid_v2,  "generate UUID v2")
    HORUS_REG_XOP(uuid_v3,  "generate UUID v3")
    HORUS_REG_XOP(uuid_v4,  "generate UUID v4")
    HORUS_REG_XOP(uuid_v5,  "generate UUID v5")
    HORUS_REG_XOP(uuid_v6,  "generate UUID v6")
    HORUS_REG_XOP(uuid_v7,  "generate UUID v7")
    HORUS_REG_XOP(uuid_v8,  "generate UUID v8")
    HORUS_REG_XOP(uuid_nil, "generate NIL UUID")
    HORUS_REG_XOP(uuid_max, "generate MAX UUID")

    HORUS_REG_XOP(uuid_v4_bulk, "generate UUID v4 batch")

    HORUS_REG_XOP(uuid_parse,    "parse UUID string")
    HORUS_REG_XOP(uuid_validate, "validate UUID string")
    HORUS_REG_XOP(uuid_version,  "extract UUID version")
    HORUS_REG_XOP(uuid_variant,  "extract UUID variant")
    HORUS_REG_XOP(uuid_cmp,      "compare two UUIDs")
    HORUS_REG_XOP(uuid_convert,  "convert UUID format")
    HORUS_REG_XOP(uuid_time,     "extract UUID timestamp")
    HORUS_REG_XOP(uuid_is_nil,   "check UUID is NIL")
    HORUS_REG_XOP(uuid_is_max,   "check UUID is MAX")

    /* Wire call checkers to intercept at compile time */
    HORUS_REG_CK("UUID_FMT_STR",       fmt_str)
    HORUS_REG_CK("UUID_FMT_HEX",       fmt_hex)
    HORUS_REG_CK("UUID_FMT_BRACES",    fmt_braces)
    HORUS_REG_CK("UUID_FMT_URN",       fmt_urn)
    HORUS_REG_CK("UUID_FMT_BASE64",    fmt_base64)
    HORUS_REG_CK("UUID_FMT_BASE32",    fmt_base32)
    HORUS_REG_CK("UUID_FMT_CROCKFORD", fmt_crockford)
    HORUS_REG_CK("UUID_FMT_BINARY",    fmt_binary)
    HORUS_REG_CK("UUID_FMT_UPPER_STR", fmt_upper_str)
    HORUS_REG_CK("UUID_FMT_UPPER_HEX", fmt_upper_hex)

    HORUS_REG_CK("UUID_NS_DNS",  ns_dns)
    HORUS_REG_CK("UUID_NS_URL",  ns_url)
    HORUS_REG_CK("UUID_NS_OID",  ns_oid)
    HORUS_REG_CK("UUID_NS_X500", ns_x500)

    HORUS_REG_CK("uuid_v1",  uuid_v1)
    HORUS_REG_CK("uuid_v2",  uuid_v2)
    HORUS_REG_CK("uuid_v3",  uuid_v3)
    HORUS_REG_CK("uuid_v4",  uuid_v4)
    HORUS_REG_CK("uuid_v5",  uuid_v5)
    HORUS_REG_CK("uuid_v6",  uuid_v6)
    HORUS_REG_CK("uuid_v7",  uuid_v7)
    HORUS_REG_CK("uuid_v8",  uuid_v8)
    HORUS_REG_CK("uuid_nil", uuid_nil)
    HORUS_REG_CK("uuid_max", uuid_max)

    HORUS_REG_CK("uuid_v4_bulk", uuid_v4_bulk)

    HORUS_REG_CK("uuid_parse",    uuid_parse)
    HORUS_REG_CK("uuid_validate", uuid_validate)
    HORUS_REG_CK("uuid_version",  uuid_version)
    HORUS_REG_CK("uuid_variant",  uuid_variant)
    HORUS_REG_CK("uuid_cmp",      uuid_cmp)
    HORUS_REG_CK("uuid_convert",  uuid_convert)
    HORUS_REG_CK("uuid_time",     uuid_time)
    HORUS_REG_CK("uuid_is_nil",   uuid_is_nil)
    HORUS_REG_CK("uuid_is_max",   uuid_is_max)
}

#endif /* PERL_VERSION >= 14 */

/* ══════════════════════════════════════════════════════════════════
 * XS module definition - XSUBs serve as fallbacks for Perl < 5.14
 * ══════════════════════════════════════════════════════════════════ */

MODULE = Horus  PACKAGE = Horus

BOOT:
{
    MY_CXT_INIT;
    memset(&MY_CXT.v1_state, 0, sizeof(horus_v1_state_t));
    memset(&MY_CXT.v6_state, 0, sizeof(horus_v6_state_t));
    memset(&MY_CXT.v7_state, 0, sizeof(horus_v7_state_t));
    horus_pool_refill();
#if PERL_VERSION >= 14
    horus_register_custom_ops(aTHX);
#endif
}

#ifdef USE_ITHREADS

void
CLONE(...)
    CODE:
        MY_CXT_CLONE;
        memset(&MY_CXT.v1_state, 0, sizeof(horus_v1_state_t));
        memset(&MY_CXT.v6_state, 0, sizeof(horus_v6_state_t));
        memset(&MY_CXT.v7_state, 0, sizeof(horus_v7_state_t));

#endif

int
UUID_FMT_STR()
    CODE:
        RETVAL = HORUS_FMT_STR;
    OUTPUT:
        RETVAL

int
UUID_FMT_HEX()
    CODE:
        RETVAL = HORUS_FMT_HEX;
    OUTPUT:
        RETVAL

int
UUID_FMT_BRACES()
    CODE:
        RETVAL = HORUS_FMT_BRACES;
    OUTPUT:
        RETVAL

int
UUID_FMT_URN()
    CODE:
        RETVAL = HORUS_FMT_URN;
    OUTPUT:
        RETVAL

int
UUID_FMT_BASE64()
    CODE:
        RETVAL = HORUS_FMT_BASE64;
    OUTPUT:
        RETVAL

int
UUID_FMT_BASE32()
    CODE:
        RETVAL = HORUS_FMT_BASE32;
    OUTPUT:
        RETVAL

int
UUID_FMT_CROCKFORD()
    CODE:
        RETVAL = HORUS_FMT_CROCKFORD;
    OUTPUT:
        RETVAL

int
UUID_FMT_BINARY()
    CODE:
        RETVAL = HORUS_FMT_BINARY;
    OUTPUT:
        RETVAL

int
UUID_FMT_UPPER_STR()
    CODE:
        RETVAL = HORUS_FMT_UPPER_STR;
    OUTPUT:
        RETVAL

int
UUID_FMT_UPPER_HEX()
    CODE:
        RETVAL = HORUS_FMT_UPPER_HEX;
    OUTPUT:
        RETVAL


SV *
UUID_NS_DNS()
    CODE:
        RETVAL = newSVpvn("6ba7b810-9dad-11d1-80b4-00c04fd430c8", 36);
    OUTPUT:
        RETVAL

SV *
UUID_NS_URL()
    CODE:
        RETVAL = newSVpvn("6ba7b811-9dad-11d1-80b4-00c04fd430c8", 36);
    OUTPUT:
        RETVAL

SV *
UUID_NS_OID()
    CODE:
        RETVAL = newSVpvn("6ba7b812-9dad-11d1-80b4-00c04fd430c8", 36);
    OUTPUT:
        RETVAL

SV *
UUID_NS_X500()
    CODE:
        RETVAL = newSVpvn("6ba7b814-9dad-11d1-80b4-00c04fd430c8", 36);
    OUTPUT:
        RETVAL


SV *
uuid_v1(fmt = HORUS_FMT_STR)
        int fmt
    CODE:
    {
        dMY_CXT;
        unsigned char uuid[16];
        horus_uuid_v1(uuid, &MY_CXT.v1_state);
        RETVAL = horus_uuid_to_sv(aTHX_ uuid, fmt);
    }
    OUTPUT:
        RETVAL

SV *
uuid_v2(domain, id = 0, fmt = HORUS_FMT_STR)
        int domain
        unsigned int id
        int fmt
    CODE:
    {
        dMY_CXT;
        unsigned char uuid[16];
        uint32_t local_id;
        if (items < 2 || !SvOK(ST(1))) {
            if (domain == 0)
                local_id = (uint32_t)getuid();
            else if (domain == 1)
                local_id = (uint32_t)getgid();
            else
                local_id = 0;
        } else {
            local_id = (uint32_t)id;
        }
        horus_uuid_v2(uuid, &MY_CXT.v1_state, domain, local_id);
        RETVAL = horus_uuid_to_sv(aTHX_ uuid, fmt);
    }
    OUTPUT:
        RETVAL

SV *
uuid_v3(ns_uuid, name, fmt = HORUS_FMT_STR)
        SV *ns_uuid
        SV *name
        int fmt
    CODE:
    {
        unsigned char ns_bytes[16];
        unsigned char uuid[16];
        STRLEN name_len;
        const char *name_str;

        if (!horus_parse_ns(aTHX_ ns_uuid, ns_bytes))
            croak("Horus: invalid namespace UUID");

        name_str = SvPV(name, name_len);
        horus_uuid_v3(uuid, ns_bytes, (const unsigned char *)name_str, name_len);
        RETVAL = horus_uuid_to_sv(aTHX_ uuid, fmt);
    }
    OUTPUT:
        RETVAL

SV *
uuid_v4(fmt = HORUS_FMT_STR)
        int fmt
    CODE:
    {
        unsigned char uuid[16];
        horus_uuid_v4(uuid);
        RETVAL = horus_uuid_to_sv(aTHX_ uuid, fmt);
    }
    OUTPUT:
        RETVAL

SV *
uuid_v5(ns_uuid, name, fmt = HORUS_FMT_STR)
        SV *ns_uuid
        SV *name
        int fmt
    CODE:
    {
        unsigned char ns_bytes[16];
        unsigned char uuid[16];
        STRLEN name_len;
        const char *name_str;

        if (!horus_parse_ns(aTHX_ ns_uuid, ns_bytes))
            croak("Horus: invalid namespace UUID");

        name_str = SvPV(name, name_len);
        horus_uuid_v5(uuid, ns_bytes, (const unsigned char *)name_str, name_len);
        RETVAL = horus_uuid_to_sv(aTHX_ uuid, fmt);
    }
    OUTPUT:
        RETVAL

SV *
uuid_v6(fmt = HORUS_FMT_STR)
        int fmt
    CODE:
    {
        dMY_CXT;
        unsigned char uuid[16];
        horus_uuid_v6(uuid, &MY_CXT.v1_state, &MY_CXT.v6_state);
        RETVAL = horus_uuid_to_sv(aTHX_ uuid, fmt);
    }
    OUTPUT:
        RETVAL

SV *
uuid_v7(fmt = HORUS_FMT_STR)
        int fmt
    CODE:
    {
        dMY_CXT;
        unsigned char uuid[16];
        horus_uuid_v7(uuid, &MY_CXT.v7_state);
        RETVAL = horus_uuid_to_sv(aTHX_ uuid, fmt);
    }
    OUTPUT:
        RETVAL

SV *
uuid_v8(custom_data, fmt = HORUS_FMT_STR)
        SV *custom_data
        int fmt
    CODE:
    {
        unsigned char uuid[16];
        STRLEN data_len;
        const char *data_str = SvPV(custom_data, data_len);

        if (data_len < 16)
            croak("Horus: uuid_v8 requires 16 bytes of custom data");

        horus_uuid_v8(uuid, (const unsigned char *)data_str);
        RETVAL = horus_uuid_to_sv(aTHX_ uuid, fmt);
    }
    OUTPUT:
        RETVAL

SV *
uuid_nil(fmt = HORUS_FMT_STR)
        int fmt
    CODE:
    {
        unsigned char uuid[16];
        horus_uuid_nil(uuid);
        RETVAL = horus_uuid_to_sv(aTHX_ uuid, fmt);
    }
    OUTPUT:
        RETVAL

SV *
uuid_max(fmt = HORUS_FMT_STR)
        int fmt
    CODE:
    {
        unsigned char uuid[16];
        horus_uuid_max(uuid);
        RETVAL = horus_uuid_to_sv(aTHX_ uuid, fmt);
    }
    OUTPUT:
        RETVAL

void
uuid_v4_bulk(count, fmt = HORUS_FMT_STR)
        int count
        int fmt
    PPCODE:
    {
        int i;
        if (count <= 0)
            XSRETURN_EMPTY;

        if (count <= 256) {
            for (i = 0; i < count; i++) {
                unsigned char uuid[16];
                horus_uuid_v4(uuid);
                mXPUSHs(horus_uuid_to_sv(aTHX_ uuid, fmt));
            }
        } else {
            unsigned char *buf;
            Newx(buf, (STRLEN)count * 16, unsigned char);
            horus_random_bulk(buf, (size_t)count * 16);

            for (i = 0; i < count; i++) {
                unsigned char *uuid = buf + i * 16;
                horus_stamp_version_variant(uuid, 4);
                mXPUSHs(horus_uuid_to_sv(aTHX_ uuid, fmt));
            }

            Safefree(buf);
        }
        XSRETURN(count);
    }

SV *
uuid_parse(input)
        SV *input
    CODE:
    {
        unsigned char uuid[16];
        STRLEN in_len;
        const char *in_str = SvPV(input, in_len);

        if (horus_parse_uuid(uuid, in_str, in_len) != HORUS_PARSE_OK)
            croak("Horus: cannot parse UUID string");

        RETVAL = newSVpvn((const char *)uuid, 16);
    }
    OUTPUT:
        RETVAL

int
uuid_validate(input)
        SV *input
    CODE:
    {
        STRLEN in_len;
        const char *in_str = SvPV(input, in_len);
        RETVAL = horus_uuid_validate(in_str, in_len);
    }
    OUTPUT:
        RETVAL

int
uuid_version(input)
        SV *input
    CODE:
    {
        unsigned char uuid[16];
        STRLEN in_len;
        const char *in_str = SvPV(input, in_len);

        if (horus_parse_uuid(uuid, in_str, in_len) != HORUS_PARSE_OK)
            croak("Horus: cannot parse UUID string");

        RETVAL = horus_uuid_version_bin(uuid);
    }
    OUTPUT:
        RETVAL

int
uuid_variant(input)
        SV *input
    CODE:
    {
        unsigned char uuid[16];
        STRLEN in_len;
        const char *in_str = SvPV(input, in_len);

        if (horus_parse_uuid(uuid, in_str, in_len) != HORUS_PARSE_OK)
            croak("Horus: cannot parse UUID string");

        RETVAL = horus_uuid_variant_bin(uuid);
    }
    OUTPUT:
        RETVAL

int
uuid_cmp(uuid_a, uuid_b)
        SV *uuid_a
        SV *uuid_b
    CODE:
    {
        unsigned char a[16], b[16];
        STRLEN a_len, b_len;
        const char *a_str = SvPV(uuid_a, a_len);
        const char *b_str = SvPV(uuid_b, b_len);
        int cmp;

        if (horus_parse_uuid(a, a_str, a_len) != HORUS_PARSE_OK)
            croak("Horus: cannot parse first UUID");
        if (horus_parse_uuid(b, b_str, b_len) != HORUS_PARSE_OK)
            croak("Horus: cannot parse second UUID");

        cmp = horus_uuid_cmp_bin(a, b);
        RETVAL = (cmp < 0) ? -1 : (cmp > 0) ? 1 : 0;
    }
    OUTPUT:
        RETVAL

SV *
uuid_convert(input, fmt)
        SV *input
        int fmt
    CODE:
    {
        unsigned char uuid[16];
        STRLEN in_len;
        const char *in_str = SvPV(input, in_len);

        if (horus_parse_uuid(uuid, in_str, in_len) != HORUS_PARSE_OK)
            croak("Horus: cannot parse UUID string");

        RETVAL = horus_uuid_to_sv(aTHX_ uuid, fmt);
    }
    OUTPUT:
        RETVAL

NV
uuid_time(input)
        SV *input
    CODE:
    {
        unsigned char uuid[16];
        STRLEN in_len;
        const char *in_str = SvPV(input, in_len);

        if (horus_parse_uuid(uuid, in_str, in_len) != HORUS_PARSE_OK)
            croak("Horus: cannot parse UUID string");

        RETVAL = horus_uuid_extract_time(uuid);
    }
    OUTPUT:
        RETVAL

int
uuid_is_nil(input)
        SV *input
    CODE:
    {
        unsigned char uuid[16];
        STRLEN in_len;
        const char *in_str = SvPV(input, in_len);

        if (horus_parse_uuid(uuid, in_str, in_len) != HORUS_PARSE_OK)
            RETVAL = 0;
        else
            RETVAL = horus_uuid_is_nil_bin(uuid);
    }
    OUTPUT:
        RETVAL

int
uuid_is_max(input)
        SV *input
    CODE:
    {
        unsigned char uuid[16];
        STRLEN in_len;
        const char *in_str = SvPV(input, in_len);

        if (horus_parse_uuid(uuid, in_str, in_len) != HORUS_PARSE_OK)
            RETVAL = 0;
        else
            RETVAL = horus_uuid_is_max_bin(uuid);
    }
    OUTPUT:
        RETVAL


SV *
new(class, ...)
        const char *class
    CODE:
    {
        HV *self = newHV();
        int i;
        int default_fmt = HORUS_FMT_STR;
        int default_ver = 4;

        for (i = 1; i + 1 < items; i += 2) {
            STRLEN klen;
            const char *key = SvPV(ST(i), klen);
            SV *val = ST(i + 1);

            if (klen == 6 && memcmp(key, "format", 6) == 0)
                default_fmt = SvIV(val);
            else if (klen == 7 && memcmp(key, "version", 7) == 0)
                default_ver = SvIV(val);
        }

        (void)hv_store(self, "format", 6, newSViv(default_fmt), 0);
        (void)hv_store(self, "version", 7, newSViv(default_ver), 0);

        RETVAL = sv_bless(newRV_noinc((SV *)self), gv_stashpv(class, GV_ADD));
    }
    OUTPUT:
        RETVAL

SV *
generate(self)
        SV *self
    CODE:
    {
        dMY_CXT;
        HV *hv;
        SV **svp;
        int fmt, ver;
        unsigned char uuid[16];

        if (!SvROK(self) || SvTYPE(SvRV(self)) != SVt_PVHV)
            croak("Horus: generate called on non-object");
        hv = (HV *)SvRV(self);

        svp = hv_fetch(hv, "format", 6, 0);
        fmt = svp ? SvIV(*svp) : HORUS_FMT_STR;

        svp = hv_fetch(hv, "version", 7, 0);
        ver = svp ? SvIV(*svp) : 4;

        switch (ver) {
            case 1:  horus_uuid_v1(uuid, &MY_CXT.v1_state); break;
            case 4:  horus_uuid_v4(uuid); break;
            case 6:  horus_uuid_v6(uuid, &MY_CXT.v1_state, &MY_CXT.v6_state); break;
            case 7:  horus_uuid_v7(uuid, &MY_CXT.v7_state); break;
            default:
                croak("Horus: generate() supports versions 1, 4, 6, 7 (use functional API for v2/v3/v5/v8)");
        }

        RETVAL = horus_uuid_to_sv(aTHX_ uuid, fmt);
    }
    OUTPUT:
        RETVAL

void
bulk(self, count)
        SV *self
        int count
    PPCODE:
    {
        dMY_CXT;
        HV *hv;
        SV **svp;
        int fmt, ver, i;

        if (!SvROK(self) || SvTYPE(SvRV(self)) != SVt_PVHV)
            croak("Horus: bulk called on non-object");
        hv = (HV *)SvRV(self);

        svp = hv_fetch(hv, "format", 6, 0);
        fmt = svp ? SvIV(*svp) : HORUS_FMT_STR;

        svp = hv_fetch(hv, "version", 7, 0);
        ver = svp ? SvIV(*svp) : 4;

        if (count <= 0)
            XSRETURN_EMPTY;

        EXTEND(SP, count);

        if (ver == 4 && count > 256) {
            unsigned char *buf;
            Newx(buf, (STRLEN)count * 16, unsigned char);
            horus_random_bulk(buf, (size_t)count * 16);
            for (i = 0; i < count; i++) {
                unsigned char *uuid = buf + i * 16;
                horus_stamp_version_variant(uuid, 4);
                mXPUSHs(horus_uuid_to_sv(aTHX_ uuid, fmt));
            }
            Safefree(buf);
        } else {
            for (i = 0; i < count; i++) {
                unsigned char uuid[16];
                switch (ver) {
                    case 1:  horus_uuid_v1(uuid, &MY_CXT.v1_state); break;
                    case 4:  horus_uuid_v4(uuid); break;
                    case 6:  horus_uuid_v6(uuid, &MY_CXT.v1_state, &MY_CXT.v6_state); break;
                    case 7:  horus_uuid_v7(uuid, &MY_CXT.v7_state); break;
                    default:
                        croak("Horus: bulk() supports versions 1, 4, 6, 7");
                }
                mXPUSHs(horus_uuid_to_sv(aTHX_ uuid, fmt));
            }
        }

        XSRETURN(count);
    }
