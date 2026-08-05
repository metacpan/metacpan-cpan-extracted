#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "jsf.h"
#include "jsf_abi.h"   /* the C ABI table consumers (e.g. OpenAPI::Fast) call */

/* ---- Compiled object plumbing ------------------------------------------- */

static jsf_compiled_t *jsf_compiled_of(pTHX_ SV *self) {
    if (!SvROK(self)) croak("JSON::Schema::Fast: not a compiled schema");
    return (jsf_compiled_t *)INT2PTR(void *, SvIV(SvRV(self)));
}

/* Decode JSON schema text via File::Raw::JSON's C ABI (jsf_frj.h; required by
 * Fast.pm). Croaks (byte-offset message) on malformed JSON. */
static SV *jsf_json_decode(pTHX_ SV *text) {
    SV *v = jsf_frj_decode(aTHX_ text);
    if (!v)
        croak("JSON::Schema::Fast: File::Raw::JSON with a compatible C ABI "
              "(FRJ_ABI_VERSION %d) is required to decode a JSON schema",
              FRJ_ABI_VERSION);
    return v;
}

/* Compile a schema into a blessed JSON::Schema::Fast::Compiled SV. Shared by
 * the XS compile() and the C ABI (jsf_abi.h): `schema` is a hashref/arrayref/
 * boolean or JSON-text scalar; `resolver` is an optional coderef (NULL/undef
 * => auto-fetch remote $ref via Fetch's ABI). Returns a +1-owned blessed SV. */
static SV *jsf_compile_api(pTHX_ SV *schema, SV *resolver, int coerce,
                           int apply_defaults) {
    SV *actual = schema;
    int auto_fetch = (resolver && SvOK(resolver)) ? 0 : 1;
    jsf_compiled_t *C;
    if (SvOK(schema) && !SvROK(schema) && SvPOK(schema))
        actual = jsf_json_decode(aTHX_ schema);
    C = jsf_compile_sv(aTHX_ actual, auto_fetch ? NULL : resolver, auto_fetch);
    C->coerce         = coerce ? 1 : 0;
    C->apply_defaults = apply_defaults ? 1 : 0;
    C->schema_sv      = newSVsv(actual);
    return sv_bless(newRV_noinc(newSViv(PTR2IV(C))),
                    gv_stashpv("JSON::Schema::Fast::Compiled", GV_ADD));
}

/* ---- IR dump (debug shim for the phase-02 tests) ------------------------ */

static const struct { U64 bit; const char *name; } jsf_bitnames[] = {
    { JSF_HAS_TYPE,"type" },{ JSF_HAS_ENUM,"enum" },{ JSF_HAS_CONST,"const" },
    { JSF_HAS_MIN,"minimum" },{ JSF_HAS_MAX,"maximum" },
    { JSF_HAS_EXMIN,"exclusiveMinimum" },{ JSF_HAS_EXMAX,"exclusiveMaximum" },
    { JSF_HAS_MULOF,"multipleOf" },{ JSF_HAS_MINLEN,"minLength" },
    { JSF_HAS_MAXLEN,"maxLength" },{ JSF_HAS_PATTERN,"pattern" },
    { JSF_HAS_FORMAT,"format" },{ JSF_HAS_ITEMS,"items" },
    { JSF_HAS_PREFIX,"prefixItems" },{ JSF_HAS_MINITEMS,"minItems" },
    { JSF_HAS_MAXITEMS,"maxItems" },{ JSF_HAS_UNIQUE,"uniqueItems" },
    { JSF_HAS_CONTAINS,"contains" },{ JSF_HAS_MINCONT,"minContains" },
    { JSF_HAS_MAXCONT,"maxContains" },{ JSF_HAS_PROPS,"properties" },
    { JSF_HAS_PATPROPS,"patternProperties" },{ JSF_HAS_ADDPROPS,"additionalProperties" },
    { JSF_HAS_REQUIRED,"required" },{ JSF_HAS_MINPROPS,"minProperties" },
    { JSF_HAS_MAXPROPS,"maxProperties" },{ JSF_HAS_PROPNAMES,"propertyNames" },
    { JSF_HAS_DEPREQ,"dependentRequired" },{ JSF_HAS_ALLOF,"allOf" },
    { JSF_HAS_ANYOF,"anyOf" },{ JSF_HAS_ONEOF,"oneOf" },{ JSF_HAS_NOT,"not" },
    { JSF_HAS_IF,"if" },{ JSF_HAS_REF,"$ref" },{ 0, NULL }
};

/* brief view of a node: { tag, type_mask, present(UV) }, or undef for off 0 */
static SV *jsf_node_brief(pTHX_ jsf_compiled_t *C, uint32_t off) {
    jsf_node_t *n; HV *h;
    if (off == JSF_NULL_OFF) return &PL_sv_undef;
    n = (jsf_node_t *)jsf_arena_ptr(C->arena, off);
    h = newHV();
    (void)hv_stores(h, "tag",       newSViv(n->tag));
    (void)hv_stores(h, "type_mask", newSVuv(n->type_mask));
    (void)hv_stores(h, "present",   newSVuv((UV)n->present));
    return newRV_noinc((SV *)h);
}

static SV *jsf_dump_node(pTHX_ jsf_compiled_t *C, uint32_t off) {
    jsf_arena_t *a = C->arena;
    jsf_node_t *n = (jsf_node_t *)jsf_arena_ptr(a, off);
    HV *h = newHV();
    HV *present = newHV();
    int i;

    (void)hv_stores(h, "tag",       newSViv(n->tag));
    (void)hv_stores(h, "type_mask", newSVuv(n->type_mask));
    (void)hv_stores(h, "enum_n",    newSVuv(n->enum_n));
    (void)hv_stores(h, "has_const", newSViv((n->present & JSF_HAS_CONST) ? 1 : 0));

    for (i = 0; jsf_bitnames[i].name; i++)
        if (n->present & jsf_bitnames[i].bit)
            (void)hv_store(present, jsf_bitnames[i].name,
                           (I32)strlen(jsf_bitnames[i].name), newSViv(1), 0);
    (void)hv_stores(h, "present", newRV_noinc((SV *)present));

    if (n->present & JSF_HAS_PROPS) {
        jsf_proptab *pt = (jsf_proptab *)jsf_arena_ptr(a, n->props_off);
        jsf_propent *en = (jsf_propent *)((char *)pt + sizeof(jsf_proptab));
        AV *pa = newAV(); uint32_t p;
        for (p = 0; p < pt->n; p++) {
            uint32_t len; const char *nm = jsf_str_bytes(a, en[p].name_off, &len);
            HV *pe = newHV();
            (void)hv_stores(pe, "name",  newSVpvn(nm, len));
            (void)hv_stores(pe, "hash",  newSVuv((UV)en[p].hash));
            (void)hv_stores(pe, "child", jsf_node_brief(aTHX_ C, en[p].child_off));
            av_push(pa, newRV_noinc((SV *)pe));
        }
        (void)hv_stores(h, "properties", newRV_noinc((SV *)pa));
    }

    if (n->present & JSF_HAS_REQUIRED) {
        jsf_reqset *rs = (jsf_reqset *)jsf_arena_ptr(a, n->required_off);
        jsf_reqent *re = (jsf_reqent *)((char *)rs + sizeof(jsf_reqset));
        AV *ra = newAV(); uint32_t r;
        for (r = 0; r < rs->n; r++) {
            uint32_t len; const char *nm = jsf_str_bytes(a, re[r].name_off, &len);
            HV *re2 = newHV();
            (void)hv_stores(re2, "name", newSVpvn(nm, len));
            (void)hv_stores(re2, "idx",
                re[r].prop_idx == JSF_NO_IDX ? newSViv(-1) : newSVuv(re[r].prop_idx));
            av_push(ra, newRV_noinc((SV *)re2));
        }
        (void)hv_stores(h, "required", newRV_noinc((SV *)ra));
    }

    if (n->present & JSF_HAS_ITEMS)
        (void)hv_stores(h, "items", jsf_node_brief(aTHX_ C, n->items_off));
    if (n->present & JSF_HAS_REF) {
        (void)hv_stores(h, "ref_resolved", newSViv(n->ref_off != JSF_NULL_OFF ? 1 : 0));
        (void)hv_stores(h, "ref_target",   jsf_node_brief(aTHX_ C, n->ref_off));
    }
    if (n->present & JSF_HAS_ADDPROPS)
        (void)hv_stores(h, "addprops_false", newSViv(n->addprops_off == JSF_NULL_OFF ? 1 : 0));

    return newRV_noinc((SV *)h);
}

/* ---- C ABI (jsf_abi.h) --------------------------------------------------- *
 * The table consumers reach through JSON::Schema::Fast::_abi_ptr: compile once
 * from C, then validate per call with no Perl method dispatch. compile is the
 * shared jsf_compile_api above; is_valid/validate wrap the interpreter. */
static int jsf_abi_is_valid(pTHX_ SV *compiled, SV *data) {
    return jsf_is_valid(aTHX_ jsf_compiled_of(aTHX_ compiled), data);
}
static int jsf_abi_validate(pTHX_ SV *compiled, SV *data, AV *errors) {
    return jsf_run(aTHX_ jsf_compiled_of(aTHX_ compiled), data, errors);
}
static const jsf_abi JSF_ABI = {
    JSF_ABI_VERSION,
    jsf_compile_api,
    jsf_abi_is_valid,
    jsf_abi_validate,
};

MODULE = JSON::Schema::Fast        PACKAGE = JSON::Schema::Fast

PROTOTYPES: DISABLE

# Compile a schema (Perl hashref/boolean, or JSON text) into a compiled object.
# Options: coerce, apply_defaults, resolver. Remote references without a resolver
# are fetched via Fetch's C ABI (see include/jsf_fetch.h).
SV *
compile(class, schema, ...)
        SV *class
        SV *schema
    CODE:
    {
        SV *resolver = NULL;
        int i, coerce = 0, apply_defaults = 0;
        for (i = 2; i + 1 < items; i += 2) {
            STRLEN kl; const char *k = SvPV_const(ST(i), kl);
            if      (kl == 6  && memEQ(k, "coerce", 6))          coerce = SvTRUE(ST(i + 1)) ? 1 : 0;
            else if (kl == 14 && memEQ(k, "apply_defaults", 14)) apply_defaults = SvTRUE(ST(i + 1)) ? 1 : 0;
            else if (kl == 8  && memEQ(k, "resolver", 8))        resolver = ST(i + 1);
        }
        RETVAL = jsf_compile_api(aTHX_ schema, resolver, coerce, apply_defaults);
        PERL_UNUSED_VAR(class);
    }
    OUTPUT:
        RETVAL

# Address of the C ABI table (jsf_abi.h). A consumer XS module (OpenAPI::Fast)
# fetches this once at boot, INT2PTRs it to a `const jsf_abi *`, and checks
# ->abi_version before use. Not part of the public Perl API.
IV
_abi_ptr()
    CODE:
        RETVAL = PTR2IV(&JSF_ABI);
    OUTPUT:
        RETVAL

# ---- debug / self-test shims ------------------------------------------------

UV
_classify(sv)
        SV *sv
    CODE:
        RETVAL = (UV) jsf_classify_type(aTHX_ sv);
    OUTPUT:
        RETVAL

UV
_prehash(sv)
        SV *sv
    CODE:
    {
        STRLEN l; const char *p = SvPV_const(sv, l);
        U32 hh; PERL_HASH(hh, p, l);
        RETVAL = (UV) hh;
    }
    OUTPUT:
        RETVAL

SV *
_arena_selftest()
    CODE:
    {
        jsf_arena_t *a;
        uint32_t o1, o2, o3, blk, len;
        const char *b;
        int dedup_ok, bytes_ok;
        a = jsf_arena_new(16);
        if (!a) croak("oom");
        o1  = jsf_arena_intern(a, "hello", 5);
        o2  = jsf_arena_intern(a, "hello", 5);
        o3  = jsf_arena_intern(a, "world", 5);
        blk = jsf_arena_alloc(a, 1000, 8);
        b   = jsf_str_bytes(a, o1, &len);
        dedup_ok = (o1 == o2) && (o1 != o3) && (o1 != JSF_NULL_OFF);
        bytes_ok = (len == 5) && (memcmp(b, "hello", 5) == 0) && (blk != JSF_NULL_OFF);
        jsf_arena_free(a);
        RETVAL = newSVpvf("%d:%d", dedup_ok, bytes_ok);
    }
    OUTPUT:
        RETVAL

# Function-call fast path (importable). Hot callers - e.g. OpenAPI::Fast's
# compiled request handlers - call `is_valid($v, $data)` / `validate($v, $data)`
# as functions, bypassing method dispatch. Same semantics as the ::Compiled
# methods; parity is asserted in t/54.
int
is_valid(compiled, data)
        SV *compiled
        SV *data
    CODE:
        RETVAL = jsf_is_valid(aTHX_ jsf_compiled_of(aTHX_ compiled), data);
    OUTPUT:
        RETVAL

void
validate(compiled, data)
        SV *compiled
        SV *data
    PPCODE:
    {
        jsf_compiled_t *C = jsf_compiled_of(aTHX_ compiled);
        AV *errs = (AV *)sv_2mortal((SV *)newAV());
        int ok = jsf_run(aTHX_ C, data, errs);
        if (GIMME_V == G_ARRAY) {
            if (ok) { mXPUSHs(newSViv(1)); }
            else    { mXPUSHs(newSViv(0)); mXPUSHs(newRV_inc((SV *)errs)); }
        } else {
            mXPUSHs(newSViv(ok ? 1 : 0));
        }
    }

MODULE = JSON::Schema::Fast        PACKAGE = JSON::Schema::Fast::Compiled

# Boolean validation (fail-fast). validate()/errors() with the JSON-Pointer
# vocabulary arrive in phase 04.
int
is_valid(self, data)
        SV *self
        SV *data
    CODE:
        RETVAL = jsf_is_valid(aTHX_ jsf_compiled_of(aTHX_ self), data);
    OUTPUT:
        RETVAL

# list context: (1) if valid, else (0, \@errors); scalar context: the boolean.
void
validate(self, data)
        SV *self
        SV *data
    PPCODE:
    {
        jsf_compiled_t *C = jsf_compiled_of(aTHX_ self);
        AV *errs = (AV *)sv_2mortal((SV *)newAV());
        int ok = jsf_run(aTHX_ C, data, errs);
        if (GIMME_V == G_ARRAY) {
            if (ok) { mXPUSHs(newSViv(1)); }
            else    { mXPUSHs(newSViv(0)); mXPUSHs(newRV_inc((SV *)errs)); }
        } else {
            mXPUSHs(newSViv(ok ? 1 : 0));
        }
    }

# always an arrayref (empty when valid)
SV *
errors(self, data)
        SV *self
        SV *data
    CODE:
    {
        AV *errs = newAV();
        (void)jsf_run(aTHX_ jsf_compiled_of(aTHX_ self), data, errs);
        RETVAL = newRV_noinc((SV *)errs);
    }
    OUTPUT:
        RETVAL

SV *
engine(self)
        SV *self
    CODE:
        PERL_UNUSED_VAR(self);
        RETVAL = newSVpvs("interp");
    OUTPUT:
        RETVAL

SV *
schema(self)
        SV *self
    CODE:
    {
        jsf_compiled_t *C = jsf_compiled_of(aTHX_ self);
        RETVAL = C->schema_sv ? newSVsv(C->schema_sv) : &PL_sv_undef;
    }
    OUTPUT:
        RETVAL

# dump the root node's IR as a nested Perl structure (tests only)
SV *
_dump_ir(self)
        SV *self
    CODE:
    {
        jsf_compiled_t *C = jsf_compiled_of(aTHX_ self);
        RETVAL = jsf_dump_node(aTHX_ C, C->root);
    }
    OUTPUT:
        RETVAL

UV
_unsupported(self)
        SV *self
    CODE:
        RETVAL = (UV) jsf_compiled_of(aTHX_ self)->unsupported;
    OUTPUT:
        RETVAL

void
DESTROY(self)
        SV *self
    CODE:
        jsf_compiled_free(aTHX_ jsf_compiled_of(aTHX_ self));
