#ifndef LITAVIS_EMITTER_H
#define LITAVIS_EMITTER_H

/* ── Growable output buffer ──────────────────────────────── */

typedef struct {
    char *data;
    int   length;
    int   capacity;
} LitavisBuffer;

static LitavisBuffer* litavis_buffer_new(int initial_capacity) {
    LitavisBuffer *buf = (LitavisBuffer*)malloc(sizeof(LitavisBuffer));
    if (!buf) LITAVIS_FATAL("out of memory");
    buf->data = (char*)malloc((size_t)initial_capacity);
    if (!buf->data) LITAVIS_FATAL("out of memory");
    buf->length = 0;
    buf->capacity = initial_capacity;
    buf->data[0] = '\0';
    return buf;
}

static void litavis_buffer_ensure(LitavisBuffer *buf, int extra) {
    if (buf->length + extra + 1 > buf->capacity) {
        int new_cap = (buf->length + extra + 1) * 2;
        char *nd = (char*)realloc(buf->data, (size_t)new_cap);
        if (!nd) LITAVIS_FATAL("out of memory");
        buf->data = nd;
        buf->capacity = new_cap;
    }
}

static void litavis_buffer_append(LitavisBuffer *buf, const char *str, int len) {
    if (len <= 0) return;
    litavis_buffer_ensure(buf, len);
    memcpy(buf->data + buf->length, str, (size_t)len);
    buf->length += len;
    buf->data[buf->length] = '\0';
}

static void litavis_buffer_append_char(LitavisBuffer *buf, char c) {
    litavis_buffer_ensure(buf, 1);
    buf->data[buf->length++] = c;
    buf->data[buf->length] = '\0';
}

static void litavis_buffer_append_str(LitavisBuffer *buf, const char *str) {
    litavis_buffer_append(buf, str, (int)strlen(str));
}

/* Returns owned string, frees the buffer struct (but not the data) */
static char* litavis_buffer_to_string(LitavisBuffer *buf) {
    char *result = buf->data;
    free(buf);
    return result;
}

static void litavis_buffer_free(LitavisBuffer *buf) {
    if (!buf) return;
    if (buf->data) free(buf->data);
    free(buf);
}

/* ── Emitter configuration ───────────────────────────────── */

typedef struct {
    int   pretty;          /* 0 = minified, 1 = pretty-printed */
    char *indent;          /* indent string (default: "  ") */
    int   shorthand_hex;   /* 1 = #fff not #ffffff */
    int   sort_props;      /* 1 = alphabetise props */
} LitavisEmitConfig;

/* ── Hex shorthand optimisation ──────────────────────────── */

static void litavis_emit_hex_value(const char *value, LitavisBuffer *buf, int shorthand) {
    int len = (int)strlen(value);
    if (shorthand && value[0] == '#' && len == 7) {
        if (value[1] == value[2] && value[3] == value[4] && value[5] == value[6]) {
            char short_hex[5];
            short_hex[0] = '#';
            short_hex[1] = value[1];
            short_hex[2] = value[3];
            short_hex[3] = value[5];
            short_hex[4] = '\0';
            litavis_buffer_append(buf, short_hex, 4);
            return;
        }
    }
    litavis_buffer_append(buf, value, len);
}

/* ── Property sorting ────────────────────────────────────── */

static int litavis_prop_cmp(const void *a, const void *b) {
    const LitavisProp *pa = (const LitavisProp*)a;
    const LitavisProp *pb = (const LitavisProp*)b;
    return strcmp(pa->key, pb->key);
}

static void litavis_sort_props(LitavisProp *props, int count) {
    if (count > 1)
        qsort(props, (size_t)count, sizeof(LitavisProp), litavis_prop_cmp);
}

/* ── Indent helper ───────────────────────────────────────── */

static void litavis_emit_indent(LitavisBuffer *buf, const char *indent, int depth) {
    int i;
    for (i = 0; i < depth; i++)
        litavis_buffer_append_str(buf, indent);
}

/* ── Emit-first detection (@charset, @import) ───────────── */

static int litavis_is_emit_first(LitavisRule *rule) {
    if (!rule->is_at_rule) return 0;
    if (strncmp(rule->selector, "@charset", 8) == 0) return 1;
    if (strncmp(rule->selector, "@import", 7) == 0) return 1;
    return 0;
}

/* ── Forward declarations ────────────────────────────────── */

static void litavis_emit_rule(LitavisRule *rule, LitavisEmitConfig *config,
                           LitavisBuffer *buf, int depth);
static void litavis_emit_at_rule(LitavisRule *rule, LitavisEmitConfig *config,
                              LitavisBuffer *buf, int depth);

/* ── Emit declarations (properties) ──────────────────────── */

static void litavis_emit_declarations(LitavisRule *rule, LitavisEmitConfig *config,
                                   LitavisBuffer *buf, int depth) {
    int i;
    if (config->sort_props)
        litavis_sort_props(rule->props, rule->prop_count);

    for (i = 0; i < rule->prop_count; i++) {
        if (config->pretty)
            litavis_emit_indent(buf, config->indent, depth);

        litavis_buffer_append_str(buf, rule->props[i].key);

        if (config->pretty)
            litavis_buffer_append_str(buf, ": ");
        else
            litavis_buffer_append_char(buf, ':');

        if (config->shorthand_hex)
            litavis_emit_hex_value(rule->props[i].value, buf, 1);
        else
            litavis_buffer_append_str(buf, rule->props[i].value);

        /* Semicolon: always emit (including trailing) */
        litavis_buffer_append_char(buf, ';');

        if (config->pretty)
            litavis_buffer_append_char(buf, '\n');
    }
}

/* ── Emit a regular rule ─────────────────────────────────── */

static void litavis_emit_rule(LitavisRule *rule, LitavisEmitConfig *config,
                           LitavisBuffer *buf, int depth) {
    /* Skip empty rules */
    if (rule->prop_count == 0 && rule->child_count == 0) return;

    if (config->pretty)
        litavis_emit_indent(buf, config->indent, depth);

    litavis_buffer_append_str(buf, rule->selector);

    if (config->pretty) {
        litavis_buffer_append_str(buf, " {\n");
    } else {
        litavis_buffer_append_char(buf, '{');
    }

    litavis_emit_declarations(rule, config, buf, depth + 1);

    if (config->pretty) {
        litavis_emit_indent(buf, config->indent, depth);
        litavis_buffer_append_str(buf, "}\n");
    } else {
        litavis_buffer_append_char(buf, '}');
    }
}

/* ── Emit an @-rule ──────────────────────────────────────── */

static void litavis_emit_at_rule(LitavisRule *rule, LitavisEmitConfig *config,
                              LitavisBuffer *buf, int depth) {
    if (config->pretty)
        litavis_emit_indent(buf, config->indent, depth);

    /* @keyword + prelude (selector already includes prelude, e.g. "@media (max-width: 768px)") */
    litavis_buffer_append_str(buf, rule->selector);

    if (rule->child_count > 0) {
        /* Block @-rule: @media (...) { ... } */
        if (config->pretty) {
            litavis_buffer_append_str(buf, " {\n");
        } else {
            litavis_buffer_append_char(buf, '{');
        }

        /* Emit children (nested rules) */
        int i;
        for (i = 0; i < rule->child_count; i++) {
            if (rule->children[i].is_at_rule)
                litavis_emit_at_rule(&rule->children[i], config, buf, depth + 1);
            else
                litavis_emit_rule(&rule->children[i], config, buf, depth + 1);
        }

        if (config->pretty) {
            litavis_emit_indent(buf, config->indent, depth);
            litavis_buffer_append_str(buf, "}\n");
        } else {
            litavis_buffer_append_char(buf, '}');
        }
    } else if (rule->prop_count > 0) {
        /* @-rule with own properties (e.g. @font-face) */
        if (config->pretty) {
            litavis_buffer_append_str(buf, " {\n");
        } else {
            litavis_buffer_append_char(buf, '{');
        }

        litavis_emit_declarations(rule, config, buf, depth + 1);

        if (config->pretty) {
            litavis_emit_indent(buf, config->indent, depth);
            litavis_buffer_append_str(buf, "}\n");
        } else {
            litavis_buffer_append_char(buf, '}');
        }
    } else {
        /* Statement @-rule: @import url(...); */
        litavis_buffer_append_char(buf, ';');
        if (config->pretty)
            litavis_buffer_append_char(buf, '\n');
    }
}

/* ── Emit full AST ───────────────────────────────────────── */

static void litavis_emit_ast(LitavisAST *ast, LitavisEmitConfig *config, LitavisBuffer *buf) {
    int i;

    /* Pass 1: emit @charset and @import first */
    for (i = 0; i < ast->count; i++) {
        if (litavis_is_emit_first(&ast->rules[i])) {
            litavis_emit_at_rule(&ast->rules[i], config, buf, 0);
        }
    }

    /* Pass 2: emit everything else in order */
    for (i = 0; i < ast->count; i++) {
        if (litavis_is_emit_first(&ast->rules[i])) continue;

        if (ast->rules[i].is_at_rule) {
            litavis_emit_at_rule(&ast->rules[i], config, buf, 0);
        } else {
            litavis_emit_rule(&ast->rules[i], config, buf, 0);
        }
    }
}

/* ── Main entry point: compile and emit ──────────────────── */

static char* litavis_emit(LitavisCtx *ctx) {
    /* Clone the AST so compile() is non-destructive */
    LitavisAST *work = litavis_ast_clone(ctx->ast);

    /* Create temporary stores for resolution */
    LitavisVarScope   *scope  = litavis_scope_new(NULL);
    LitavisMixinStore *mixins = litavis_mixin_store_new();
    LitavisMapStore   *maps   = litavis_map_store_new();

    /* Pipeline: resolve vars → colours → merge → dedupe */
    litavis_resolve_vars(work, scope, mixins, maps);
    litavis_resolve_colours(work);
    litavis_merge_same_selectors(work);
    if (ctx->dedupe > 0)
        litavis_dedupe(work, (LitavisDedupeStrategy)ctx->dedupe);

    /* Configure emitter */
    LitavisEmitConfig config;
    config.pretty        = ctx->pretty;
    config.indent        = ctx->indent ? ctx->indent : "  ";
    config.shorthand_hex = ctx->shorthand_hex;
    config.sort_props    = ctx->sort_props;

    /* Emit */
    LitavisBuffer *buf = litavis_buffer_new(4096);
    litavis_emit_ast(work, &config, buf);

    /* Cleanup */
    litavis_ast_free(work);
    litavis_scope_free(scope);
    litavis_mixin_store_free(mixins);
    litavis_map_store_free(maps);

    return litavis_buffer_to_string(buf);
}

/* ── Emit to file ────────────────────────────────────────── */

static void litavis_emit_file(LitavisCtx *ctx, const char *filename) {
    char *css = litavis_emit(ctx);
    FILE *f = fopen(filename, "wb");
    if (!f) {
        free(css);
        char err[512];
        snprintf(err, sizeof(err), "cannot open file for writing: %s", filename);
        LITAVIS_FATAL(err);
    }
    fwrite(css, 1, strlen(css), f);
    fclose(f);
    free(css);
}

#endif /* LITAVIS_EMITTER_H */
