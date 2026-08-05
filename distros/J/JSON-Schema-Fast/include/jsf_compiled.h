#ifndef JSF_COMPILED_H
#define JSF_COMPILED_H

/* The top-level compiled object: the arena IR, the root node offset, and a
 * keepalive AV holding deep copies of const/enum value SVs. Complex JSON values
 * (enum arrays, const objects) are copied into `keep` rather than re-encoded
 * into the arena - the schema hashref can still be GC'd afterwards (principle 2
 * for the schema document; the specific literal values live on in `keep`).
 *
 * A JSON::Schema::Fast::Compiled is a blessed IV pointing at this struct.
 * Needs jsf_arena.h and the Perl API (perl.h, included by the .xs). */

/* lazily-compiled `pattern` regex, cached by the interned pattern offset so a
 * schema's pattern is compiled at most once (not per validate). */
typedef struct jsf_rxent { uint32_t pat_off; REGEXP *rx; } jsf_rxent;

typedef struct jsf_compiled {
    jsf_arena_t *arena;
    uint32_t     root;         /* root node offset */
    AV          *keep;         /* Perl-owned const/enum values */
    int          unsupported;  /* count of out-of-matrix keywords seen */
    jsf_rxent   *rx;           /* compiled-pattern cache */
    int          rxn, rxcap;
    int          coerce;         /* string<->number/boolean coercion (opt-in) */
    int          apply_defaults; /* fill missing props from `default` (opt-in) */
    int          has_unevaluated;/* schema uses unevaluatedProperties/Items */
    int          has_dynamic;    /* schema uses $dynamicRef/$dynamicAnchor */
    int          no_validation_vocab; /* $schema metaschema disables validation vocab */
    HV          *dynmap;         /* "base#anchor" -> IV node offset (dynamic anchors) */
    SV          *schema_sv;      /* keepalive of the (decoded) schema, for schema() */
} jsf_compiled_t;

static jsf_compiled_t *jsf_compiled_new(pTHX) {
    jsf_compiled_t *c = (jsf_compiled_t *)malloc(sizeof *c);
    if (!c) return NULL;
    c->arena = jsf_arena_new(1024);
    if (!c->arena) { free(c); return NULL; }
    c->root        = JSF_NULL_OFF;
    c->keep        = newAV();
    c->unsupported = 0;
    c->rx          = NULL;
    c->rxn = c->rxcap = 0;
    c->coerce          = 0;
    c->apply_defaults  = 0;
    c->has_unevaluated = 0;
    c->has_dynamic     = 0;
    c->no_validation_vocab = 0;
    c->dynmap          = newHV();
    c->schema_sv       = NULL;
    return c;
}

static void jsf_compiled_free(pTHX_ jsf_compiled_t *c) {
    int i;
    if (!c) return;
    for (i = 0; i < c->rxn; i++) if (c->rx[i].rx) ReREFCNT_dec(c->rx[i].rx);
    free(c->rx);
    jsf_arena_free(c->arena);
    if (c->keep) SvREFCNT_dec((SV *)c->keep);
    if (c->dynmap) SvREFCNT_dec((SV *)c->dynmap);
    if (c->schema_sv) SvREFCNT_dec(c->schema_sv);
    free(c);
}

/* Deep-copy a value SV into the keepalive; returns its index. */
static uint32_t jsf_keep_push(pTHX_ jsf_compiled_t *c, SV *v) {
    av_push(c->keep, newSVsv(v));
    return (uint32_t)av_len(c->keep);   /* index of the element just pushed */
}

#endif /* JSF_COMPILED_H */
