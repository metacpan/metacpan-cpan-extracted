#include "litavis.h"

/* Store C context pointer inside Perl object */
typedef LitavisCtx* Litavis;

MODULE = Litavis  PACKAGE = Litavis

Litavis
new(class, ...)
    const char *class
PREINIT:
    LitavisCtx *ctx;
    int i;
CODE:
    ctx = litavis_ctx_new();
    /* Parse optional hash-style args from Perl stack */
    if (items > 1 && (items - 1) % 2 == 0) {
        for (i = 1; i < items; i += 2) {
            const char *key = SvPV_nolen(ST(i));
            if (strcmp(key, "pretty") == 0) {
                ctx->pretty = SvIV(ST(i + 1));
            } else if (strcmp(key, "dedupe") == 0) {
                ctx->dedupe = SvIV(ST(i + 1));
            } else if (strcmp(key, "indent") == 0) {
                if (ctx->indent) free(ctx->indent);
                ctx->indent = litavis_strdup(SvPV_nolen(ST(i + 1)));
            } else if (strcmp(key, "shorthand_hex") == 0) {
                ctx->shorthand_hex = SvIV(ST(i + 1));
            } else if (strcmp(key, "sort_props") == 0) {
                ctx->sort_props = SvIV(ST(i + 1));
            }
        }
    }
    RETVAL = ctx;
OUTPUT:
    RETVAL

void
DESTROY(self)
    Litavis self
CODE:
    litavis_ctx_free(self);

SV*
parse(self, input)
    Litavis self
    const char *input
CODE:
    litavis_parse_string(self, input);
    /* return self for chaining */
    RETVAL = SvREFCNT_inc(ST(0));
OUTPUT:
    RETVAL

SV*
parse_file(self, filename)
    Litavis self
    const char *filename
CODE:
    litavis_parse_file(self, filename);
    RETVAL = SvREFCNT_inc(ST(0));
OUTPUT:
    RETVAL

SV*
parse_dir(self, dirname)
    Litavis self
    const char *dirname
CODE:
    litavis_parse_dir(self, dirname);
    RETVAL = SvREFCNT_inc(ST(0));
OUTPUT:
    RETVAL

SV*
compile(self)
    Litavis self
CODE:
    char *css = litavis_emit(self);
    RETVAL = newSVpv(css, 0);
    free(css);
OUTPUT:
    RETVAL

void
compile_file(self, filename)
    Litavis self
    const char *filename
CODE:
    litavis_emit_file(self, filename);

void
reset(self)
    Litavis self
CODE:
    litavis_ctx_reset(self);

int
pretty(self, ...)
    Litavis self
CODE:
    if (items > 1)
        self->pretty = SvIV(ST(1));
    RETVAL = self->pretty;
OUTPUT:
    RETVAL

int
dedupe(self, ...)
    Litavis self
CODE:
    if (items > 1)
        self->dedupe = SvIV(ST(1));
    RETVAL = self->dedupe;
OUTPUT:
    RETVAL

 # ── AST introspection (for testing and debugging) ──────────

void
_ast_add_rule(self, selector)
    Litavis self
    const char *selector
CODE:
    litavis_ast_add_rule(self->ast, selector);

int
_ast_has_rule(self, selector)
    Litavis self
    const char *selector
CODE:
    RETVAL = litavis_ast_has_rule(self->ast, selector);
OUTPUT:
    RETVAL

int
_ast_rule_count(self)
    Litavis self
CODE:
    RETVAL = self->ast->count;
OUTPUT:
    RETVAL

SV*
_ast_rule_selector(self, index)
    Litavis self
    int index
CODE:
    if (index < 0 || index >= self->ast->count)
        XSRETURN_UNDEF;
    RETVAL = newSVpv(self->ast->rules[index].selector, 0);
OUTPUT:
    RETVAL

void
_ast_remove_rule(self, index)
    Litavis self
    int index
CODE:
    litavis_ast_remove_rule(self->ast, index);

void
_ast_rename_rule(self, index, new_selector)
    Litavis self
    int index
    const char *new_selector
CODE:
    litavis_ast_rename_rule(self->ast, index, new_selector);

void
_ast_add_prop(self, selector, key, value)
    Litavis self
    const char *selector
    const char *key
    const char *value
CODE:
    LitavisRule *rule = litavis_ast_get_rule(self->ast, selector);
    if (!rule)
        croak("litavis: no rule with selector '%s'", selector);
    litavis_rule_add_prop(rule, key, value);

SV*
_ast_get_prop(self, selector, key)
    Litavis self
    const char *selector
    const char *key
CODE:
    LitavisRule *rule = litavis_ast_get_rule(self->ast, selector);
    if (!rule)
        XSRETURN_UNDEF;
    char *val = litavis_rule_get_prop(rule, key);
    if (!val)
        XSRETURN_UNDEF;
    RETVAL = newSVpv(val, 0);
OUTPUT:
    RETVAL

int
_ast_has_prop(self, selector, key)
    Litavis self
    const char *selector
    const char *key
CODE:
    LitavisRule *rule = litavis_ast_get_rule(self->ast, selector);
    if (!rule)
        RETVAL = 0;
    else
        RETVAL = litavis_rule_has_prop(rule, key);
OUTPUT:
    RETVAL

int
_ast_prop_count(self, selector)
    Litavis self
    const char *selector
CODE:
    LitavisRule *rule = litavis_ast_get_rule(self->ast, selector);
    if (!rule)
        RETVAL = 0;
    else
        RETVAL = rule->prop_count;
OUTPUT:
    RETVAL

int
_ast_rules_props_equal(self, sel_a, sel_b)
    Litavis self
    const char *sel_a
    const char *sel_b
CODE:
    LitavisRule *a = litavis_ast_get_rule(self->ast, sel_a);
    LitavisRule *b = litavis_ast_get_rule(self->ast, sel_b);
    if (!a || !b)
        RETVAL = 0;
    else
        RETVAL = litavis_rules_props_equal(a, b);
OUTPUT:
    RETVAL

void
_ast_merge_props(self, dst_sel, src_sel)
    Litavis self
    const char *dst_sel
    const char *src_sel
CODE:
    LitavisRule *dst = litavis_ast_get_rule(self->ast, dst_sel);
    LitavisRule *src = litavis_ast_get_rule(self->ast, src_sel);
    if (!dst || !src)
        croak("litavis: rule not found for merge");
    litavis_rule_merge_props(dst, src);

void
_dedupe(self, strategy)
    Litavis self
    int strategy
CODE:
    litavis_dedupe(self->ast, (LitavisDedupeStrategy)strategy);

void
_resolve_vars(self)
    Litavis self
CODE:
    litavis_resolve_vars(self->ast, self->global_scope, self->mixins, self->maps);

void
_resolve_colours(self)
    Litavis self
CODE:
    litavis_resolve_colours(self->ast);
