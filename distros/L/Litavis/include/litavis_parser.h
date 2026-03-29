#ifndef LITAVIS_PARSER_H
#define LITAVIS_PARSER_H

#include <stdio.h>
#include <dirent.h>
#include <sys/stat.h>

/* ── Parser context ───────────────────────────────────────── */

typedef struct {
    LitavisTokenList *tokens;
    int            pos;         /* current token index */
    const char    *source_file; /* for error messages */
} LitavisParserCtx;

/* ── Forward declarations ─────────────────────────────────── */

static void litavis_parse_stylesheet(LitavisParserCtx *pctx, LitavisAST *ast, LitavisRule *parent);
static void litavis_parse_rule(LitavisParserCtx *pctx, LitavisAST *ast, LitavisRule *parent);
static void litavis_parse_at_rule(LitavisParserCtx *pctx, LitavisAST *ast, LitavisRule *parent);

/* ── Token helpers ────────────────────────────────────────── */

static LitavisToken* litavis_parser_peek(LitavisParserCtx *pctx) {
    if (pctx->pos < pctx->tokens->count)
        return &pctx->tokens->tokens[pctx->pos];
    return &pctx->tokens->tokens[pctx->tokens->count - 1]; /* EOF */
}

static LitavisToken* litavis_parser_advance(LitavisParserCtx *pctx) {
    LitavisToken *t = litavis_parser_peek(pctx);
    if (t->type != LITAVIS_T_EOF)
        pctx->pos++;
    return t;
}

static int litavis_parser_at(LitavisParserCtx *pctx, LitavisTokenType type) {
    return litavis_parser_peek(pctx)->type == type;
}

static int litavis_parser_match(LitavisParserCtx *pctx, LitavisTokenType type) {
    if (litavis_parser_at(pctx, type)) {
        litavis_parser_advance(pctx);
        return 1;
    }
    return 0;
}

/* Extract a null-terminated string from a token (caller must free) */
static char* litavis_token_str(LitavisToken *t) {
    char *s = (char*)malloc((size_t)t->length + 1);
    if (!s) LITAVIS_FATAL("out of memory");
    memcpy(s, t->start, (size_t)t->length);
    s[t->length] = '\0';
    return s;
}

/* ── Parse a single declaration: property ':' value ';' ───── */

static void litavis_parse_declaration(LitavisParserCtx *pctx, LitavisRule *rule) {
    LitavisToken *prop_tok = litavis_parser_advance(pctx); /* PROPERTY or CSS_VAR_DEF */
    char *key = litavis_token_str(prop_tok);

    /* Expect colon */
    litavis_parser_match(pctx, LITAVIS_T_COLON);

    /* Expect value */
    char *value = NULL;
    if (litavis_parser_at(pctx, LITAVIS_T_VALUE)) {
        LitavisToken *val_tok = litavis_parser_advance(pctx);
        value = litavis_token_str(val_tok);
    } else {
        value = litavis_strdup("");
    }

    litavis_rule_add_prop(rule, key, value);
    free(key);
    free(value);

    /* Consume optional semicolon */
    litavis_parser_match(pctx, LITAVIS_T_SEMICOLON);
}

/* ── Parse declarations inside a block ────────────────────── */

static void litavis_parse_declarations(LitavisParserCtx *pctx, LitavisAST *ast, LitavisRule *rule) {
    while (!litavis_parser_at(pctx, LITAVIS_T_RBRACE) && !litavis_parser_at(pctx, LITAVIS_T_EOF)) {
        LitavisTokenType type = litavis_parser_peek(pctx)->type;

        if (type == LITAVIS_T_PROPERTY || type == LITAVIS_T_CSS_VAR_DEF) {
            litavis_parse_declaration(pctx, rule);
        } else if (type == LITAVIS_T_SELECTOR || type == LITAVIS_T_AMPERSAND) {
            /* Nested rule */
            litavis_parse_rule(pctx, ast, rule);
        } else if (type == LITAVIS_T_AT_KEYWORD) {
            litavis_parse_at_rule(pctx, ast, rule);
        } else if (type == LITAVIS_T_PREPROC_VAR_DEF) {
            /* $var: value; inside a block — store as property */
            LitavisToken *var_tok = litavis_parser_advance(pctx);
            char *var_name = litavis_token_str(var_tok);
            char *value = NULL;
            if (litavis_parser_at(pctx, LITAVIS_T_VALUE)) {
                LitavisToken *val_tok = litavis_parser_advance(pctx);
                value = litavis_token_str(val_tok);
            } else {
                value = litavis_strdup("");
            }
            litavis_rule_add_prop(rule, var_name, value);
            free(var_name);
            free(value);
            litavis_parser_match(pctx, LITAVIS_T_SEMICOLON);
        } else if (type == LITAVIS_T_MIXIN_REF) {
            /* %name; — store as a property for later resolution */
            LitavisToken *mixin_tok = litavis_parser_advance(pctx);
            char *mixin_name = litavis_token_str(mixin_tok);
            litavis_rule_add_prop(rule, mixin_name, "");
            free(mixin_name);
            litavis_parser_match(pctx, LITAVIS_T_SEMICOLON);
        } else if (type == LITAVIS_T_SEMICOLON) {
            litavis_parser_advance(pctx); /* skip stray semicolons */
        } else if (type == LITAVIS_T_COMMA) {
            litavis_parser_advance(pctx); /* skip stray commas */
        } else {
            /* Unknown token inside declarations — skip */
            litavis_parser_advance(pctx);
        }
    }
}

/* ── Build selector string (may include & and commas) ─────── */

static char* litavis_parse_selector_text(LitavisParserCtx *pctx) {
    /* Collect selector tokens until LBRACE */
    char buf[4096];
    int buf_pos = 0;
    buf[0] = '\0';

    while (!litavis_parser_at(pctx, LITAVIS_T_LBRACE) && !litavis_parser_at(pctx, LITAVIS_T_EOF)) {
        LitavisToken *t = litavis_parser_peek(pctx);

        if (t->type == LITAVIS_T_SELECTOR || t->type == LITAVIS_T_AMPERSAND) {
            if (buf_pos > 0 && buf[buf_pos - 1] != ' ' && buf[buf_pos - 1] != ',') {
                /* add space between parts if needed */
            }
            int copy_len = t->length;
            if (buf_pos + copy_len + 1 < 4096) {
                memcpy(buf + buf_pos, t->start, (size_t)copy_len);
                buf_pos += copy_len;
                buf[buf_pos] = '\0';
            }
            litavis_parser_advance(pctx);
        } else if (t->type == LITAVIS_T_COMMA) {
            if (buf_pos + 2 < 4096) {
                buf[buf_pos++] = ',';
                buf[buf_pos++] = ' ';
                buf[buf_pos] = '\0';
            }
            litavis_parser_advance(pctx);
        } else if (t->type == LITAVIS_T_STRING) {
            int copy_len = t->length;
            if (buf_pos + copy_len + 1 < 4096) {
                memcpy(buf + buf_pos, t->start, (size_t)copy_len);
                buf_pos += copy_len;
                buf[buf_pos] = '\0';
            }
            litavis_parser_advance(pctx);
        } else {
            break;
        }
    }

    /* Trim trailing whitespace */
    while (buf_pos > 0 && (buf[buf_pos - 1] == ' ' || buf[buf_pos - 1] == '\t'))
        buf_pos--;
    buf[buf_pos] = '\0';

    return litavis_strdup(buf);
}

/* ── Parse a rule: selector(s) '{' declarations '}' ──────── */

static void litavis_parse_rule(LitavisParserCtx *pctx, LitavisAST *ast, LitavisRule *parent) {
    char *selector = litavis_parse_selector_text(pctx);

    if (!litavis_parser_match(pctx, LITAVIS_T_LBRACE)) {
        free(selector);
        return; /* malformed — skip */
    }

    if (parent) {
        /* Nested rule — add as child of parent */
        LitavisRule *child = litavis_rule_add_child(parent, selector);
        child->source_file = pctx->source_file ? litavis_strdup(pctx->source_file) : NULL;
        child->source_line = litavis_parser_peek(pctx)->line;
        litavis_parse_declarations(pctx, ast, child);
    } else {
        /* Top-level rule */
        LitavisRule *rule = litavis_ast_add_rule(ast, selector);
        rule->source_file = pctx->source_file ? litavis_strdup(pctx->source_file) : NULL;
        rule->source_line = litavis_parser_peek(pctx)->line;
        litavis_parse_declarations(pctx, ast, rule);
    }

    free(selector);
    litavis_parser_match(pctx, LITAVIS_T_RBRACE);
}

/* ── Parse @-rule ─────────────────────────────────────────── */

static void litavis_parse_at_rule(LitavisParserCtx *pctx, LitavisAST *ast, LitavisRule *parent) {
    LitavisToken *kw_tok = litavis_parser_advance(pctx); /* AT_KEYWORD */
    char *keyword = litavis_token_str(kw_tok);

    char *prelude = NULL;
    if (litavis_parser_at(pctx, LITAVIS_T_AT_PRELUDE)) {
        LitavisToken *pl_tok = litavis_parser_advance(pctx);
        prelude = litavis_token_str(pl_tok);
    }

    /* Build selector for the at-rule: "@media (prelude)" */
    char at_sel[4096];
    if (prelude)
        snprintf(at_sel, sizeof(at_sel), "%s %s", keyword, prelude);
    else
        snprintf(at_sel, sizeof(at_sel), "%s", keyword);

    if (litavis_parser_at(pctx, LITAVIS_T_LBRACE)) {
        /* Block @-rule: @media { ... } */
        litavis_parser_advance(pctx); /* consume { */

        LitavisRule *at_rule;
        if (parent) {
            at_rule = litavis_rule_add_child(parent, at_sel);
        } else {
            at_rule = litavis_ast_add_rule(ast, at_sel);
        }
        at_rule->is_at_rule = 1;
        at_rule->at_prelude = prelude ? litavis_strdup(prelude) : NULL;
        at_rule->source_file = pctx->source_file ? litavis_strdup(pctx->source_file) : NULL;
        at_rule->source_line = kw_tok->line;

        /* Parse contents — can be rules or declarations (e.g. @font-face) */
        litavis_parse_declarations(pctx, ast, at_rule);

        litavis_parser_match(pctx, LITAVIS_T_RBRACE);
    } else {
        /* Statement @-rule: @import ...; */
        LitavisRule *at_rule;
        if (parent) {
            at_rule = litavis_rule_add_child(parent, at_sel);
        } else {
            at_rule = litavis_ast_add_rule(ast, at_sel);
        }
        at_rule->is_at_rule = 1;
        at_rule->at_prelude = prelude ? litavis_strdup(prelude) : NULL;
        at_rule->source_file = pctx->source_file ? litavis_strdup(pctx->source_file) : NULL;
        at_rule->source_line = kw_tok->line;

        litavis_parser_match(pctx, LITAVIS_T_SEMICOLON);
    }

    free(keyword);
    if (prelude) free(prelude);
}

/* ── Parse stylesheet (top-level or inside @-rule) ────────── */

static void litavis_parse_stylesheet(LitavisParserCtx *pctx, LitavisAST *ast, LitavisRule *parent) {
    while (!litavis_parser_at(pctx, LITAVIS_T_EOF) && !litavis_parser_at(pctx, LITAVIS_T_RBRACE)) {
        LitavisTokenType type = litavis_parser_peek(pctx)->type;

        if (type == LITAVIS_T_SELECTOR || type == LITAVIS_T_AMPERSAND) {
            litavis_parse_rule(pctx, ast, parent);
        } else if (type == LITAVIS_T_AT_KEYWORD) {
            litavis_parse_at_rule(pctx, ast, parent);
        } else if (type == LITAVIS_T_PREPROC_VAR_DEF) {
            /* Top-level $var: value; — store as a rule */
            LitavisToken *var_tok = litavis_parser_advance(pctx);
            char *var_name = litavis_token_str(var_tok);
            char *value = NULL;
            if (litavis_parser_at(pctx, LITAVIS_T_VALUE)) {
                LitavisToken *val_tok = litavis_parser_advance(pctx);
                value = litavis_token_str(val_tok);
            } else {
                value = litavis_strdup("");
            }
            /* Store in AST as a special rule */
            LitavisRule *vr = litavis_ast_add_rule(ast, var_name);
            litavis_rule_add_prop(vr, var_name, value);
            free(var_name);
            free(value);
            litavis_parser_match(pctx, LITAVIS_T_SEMICOLON);
        } else if (type == LITAVIS_T_MIXIN_DEF) {
            /* Top-level %name: (...); */
            LitavisToken *mixin_tok = litavis_parser_advance(pctx);
            char *mixin_name = litavis_token_str(mixin_tok);
            char *body = NULL;
            if (litavis_parser_at(pctx, LITAVIS_T_VALUE)) {
                LitavisToken *val_tok = litavis_parser_advance(pctx);
                body = litavis_token_str(val_tok);
            } else {
                body = litavis_strdup("");
            }
            LitavisRule *mr = litavis_ast_add_rule(ast, mixin_name);
            mr->is_at_rule = 1; /* mark as non-output */
            litavis_rule_add_prop(mr, mixin_name, body);
            free(mixin_name);
            free(body);
            litavis_parser_match(pctx, LITAVIS_T_SEMICOLON);
        } else if (type == LITAVIS_T_SEMICOLON || type == LITAVIS_T_COMMA) {
            litavis_parser_advance(pctx); /* skip stray */
        } else {
            litavis_parser_advance(pctx); /* skip unknown */
        }
    }
}

/* ── Selector flattening ──────────────────────────────────── */

static void litavis_flatten_rule(LitavisRule *rule, const char *parent_sel, LitavisAST *flat);

/* Combine parent + child selector, handling & */
static char* litavis_combine_selectors(const char *parent, const char *child) {
    if (!parent || !*parent)
        return litavis_strdup(child);

    /* Check if child contains '&' */
    const char *amp = strchr(child, '&');
    if (amp) {
        /* Replace all & with parent selector */
        char buf[8192];
        int buf_pos = 0;
        const char *p = child;
        while (*p) {
            if (*p == '&') {
                int plen = (int)strlen(parent);
                if (buf_pos + plen < 8192) {
                    memcpy(buf + buf_pos, parent, (size_t)plen);
                    buf_pos += plen;
                }
                p++;
            } else {
                if (buf_pos < 8191)
                    buf[buf_pos++] = *p;
                p++;
            }
        }
        buf[buf_pos] = '\0';
        return litavis_strdup(buf);
    }

    /* No & — descendant combinator (space) */
    int plen = (int)strlen(parent);
    int clen = (int)strlen(child);
    char *combined = (char*)malloc((size_t)(plen + 1 + clen + 1));
    if (!combined) LITAVIS_FATAL("out of memory");
    memcpy(combined, parent, (size_t)plen);
    combined[plen] = ' ';
    memcpy(combined + plen + 1, child, (size_t)clen);
    combined[plen + 1 + clen] = '\0';
    return combined;
}

/* Split a comma-separated selector list */
static int litavis_split_selectors(const char *sel, char **out, int max_out) {
    int count = 0;
    const char *p = sel;
    while (*p && count < max_out) {
        /* Skip leading ws */
        while (*p == ' ' || *p == '\t') p++;
        const char *start = p;
        int paren_d = 0;
        while (*p) {
            if (*p == '(') paren_d++;
            else if (*p == ')') paren_d--;
            else if (*p == ',' && paren_d == 0) break;
            p++;
        }
        /* Trim trailing ws */
        const char *end = p;
        while (end > start && (end[-1] == ' ' || end[-1] == '\t'))
            end--;
        if (end > start) {
            int slen = (int)(end - start);
            char *s = (char*)malloc((size_t)(slen + 1));
            if (!s) LITAVIS_FATAL("out of memory");
            memcpy(s, start, (size_t)slen);
            s[slen] = '\0';
            out[count++] = s;
        }
        if (*p == ',') p++;
    }
    return count;
}

static void litavis_flatten_rule(LitavisRule *rule, const char *parent_sel, LitavisAST *flat) {
    int i, j, k;

    /* Split this rule's selector on commas */
    char *selectors[128];
    int sel_count = litavis_split_selectors(rule->selector, selectors, 128);

    /* For each selector part, combine with parent */
    char *combined[128];
    int combined_count = 0;

    if (!parent_sel || !*parent_sel) {
        for (i = 0; i < sel_count; i++)
            combined[combined_count++] = selectors[i];
    } else {
        /* Split parent too for combinatorial expansion */
        char *parent_parts[128];
        int parent_count = litavis_split_selectors(parent_sel, parent_parts, 128);

        for (i = 0; i < parent_count; i++) {
            for (j = 0; j < sel_count; j++) {
                combined[combined_count++] = litavis_combine_selectors(parent_parts[i], selectors[j]);
            }
        }
        for (i = 0; i < parent_count; i++) free(parent_parts[i]);
        for (i = 0; i < sel_count; i++) free(selectors[i]);
    }

    /* Build the combined selector string */
    if (rule->prop_count > 0 && !rule->is_at_rule) {
        /* Rejoin combined selectors with ", " */
        char joined[8192];
        int jpos = 0;
        for (i = 0; i < combined_count && jpos < 8100; i++) {
            if (i > 0) {
                joined[jpos++] = ',';
                joined[jpos++] = ' ';
            }
            int slen = (int)strlen(combined[i]);
            memcpy(joined + jpos, combined[i], (size_t)slen);
            jpos += slen;
        }
        joined[jpos] = '\0';

        LitavisRule *flat_rule = litavis_ast_add_rule(flat, joined);
        /* Copy properties */
        for (i = 0; i < rule->prop_count; i++) {
            litavis_rule_add_prop(flat_rule, rule->props[i].key, rule->props[i].value);
        }
        flat_rule->source_file = rule->source_file ? litavis_strdup(rule->source_file) : NULL;
        flat_rule->source_line = rule->source_line;
    }

    /* Handle @-rules with children (e.g. @media) */
    if (rule->is_at_rule && rule->child_count > 0) {
        LitavisRule *flat_at = litavis_ast_add_rule(flat, rule->selector);
        flat_at->is_at_rule = 1;
        flat_at->at_prelude = rule->at_prelude ? litavis_strdup(rule->at_prelude) : NULL;
        flat_at->source_file = rule->source_file ? litavis_strdup(rule->source_file) : NULL;
        flat_at->source_line = rule->source_line;
        /* Copy own props */
        for (i = 0; i < rule->prop_count; i++) {
            litavis_rule_add_prop(flat_at, rule->props[i].key, rule->props[i].value);
        }
        /* Flatten children into the @-rule's child list */
        for (i = 0; i < rule->child_count; i++) {
            LitavisAST *child_flat = litavis_ast_new(4);
            litavis_flatten_rule(&rule->children[i], NULL, child_flat);
            int ci;
            for (ci = 0; ci < child_flat->count; ci++) {
                LitavisRule *src = &child_flat->rules[ci];
                LitavisRule *child = litavis_rule_add_child(flat_at, src->selector);
                litavis_rule_merge_props(child, src);
                child->is_at_rule = src->is_at_rule;
                if (src->source_file)
                    child->source_file = litavis_strdup(src->source_file);
                child->source_line = src->source_line;
            }
            litavis_ast_free(child_flat);
        }
    } else if (rule->is_at_rule) {
        /* Statement @-rule or @-rule with only props (like @font-face) */
        LitavisRule *flat_at = litavis_ast_add_rule(flat, rule->selector);
        flat_at->is_at_rule = 1;
        flat_at->at_prelude = rule->at_prelude ? litavis_strdup(rule->at_prelude) : NULL;
        flat_at->source_file = rule->source_file ? litavis_strdup(rule->source_file) : NULL;
        flat_at->source_line = rule->source_line;
        for (i = 0; i < rule->prop_count; i++) {
            litavis_rule_add_prop(flat_at, rule->props[i].key, rule->props[i].value);
        }
    }

    /* Recurse into children (non-at-rule) */
    if (!rule->is_at_rule) {
        for (i = 0; i < rule->child_count; i++) {
            /* Build parent selector string for children */
            char parent_joined[8192];
            int pjpos = 0;
            for (j = 0; j < combined_count && pjpos < 8100; j++) {
                if (j > 0) {
                    parent_joined[pjpos++] = ',';
                    parent_joined[pjpos++] = ' ';
                }
                int slen = (int)strlen(combined[j]);
                memcpy(parent_joined + pjpos, combined[j], (size_t)slen);
                pjpos += slen;
            }
            parent_joined[pjpos] = '\0';
            litavis_flatten_rule(&rule->children[i], parent_joined, flat);
        }
    }

    /* Free combined if we allocated them (parent_sel was non-null) */
    if (parent_sel && *parent_sel) {
        for (i = 0; i < combined_count; i++)
            free(combined[i]);
    }
}

static LitavisAST* litavis_flatten(LitavisAST *nested) {
    int i;
    LitavisAST *flat = litavis_ast_new(nested->count * 2);
    for (i = 0; i < nested->count; i++) {
        litavis_flatten_rule(&nested->rules[i], NULL, flat);
    }
    return flat;
}

/* ── Public API ───────────────────────────────────────────── */

/* Parse a token list into an AST. */
static void litavis_parse(LitavisAST *ast, LitavisTokenList *tokens, const char *source_file) {
    LitavisParserCtx pctx;
    pctx.tokens = tokens;
    pctx.pos = 0;
    pctx.source_file = source_file;
    litavis_parse_stylesheet(&pctx, ast, NULL);
}

/* Parse a raw CSS string into ctx->ast (tokenise + parse + flatten) */
static void litavis_parse_string(LitavisCtx *ctx, const char *input) {
    int len = (int)strlen(input);
    LitavisTokenList *tokens = litavis_tokenise(input, len);

    /* Parse into a temporary nested AST */
    LitavisAST *nested = litavis_ast_new(16);
    litavis_parse(nested, tokens, NULL);

    /* Flatten nested selectors */
    LitavisAST *flat = litavis_flatten(nested);

    /* Merge flattened rules into ctx->ast */
    int i;
    for (i = 0; i < flat->count; i++) {
        LitavisRule *src = &flat->rules[i];
        LitavisRule *dst = litavis_ast_add_rule(ctx->ast, src->selector);
        litavis_rule_merge_props(dst, src);
        dst->is_at_rule = src->is_at_rule;
        if (src->at_prelude && !dst->at_prelude)
            dst->at_prelude = litavis_strdup(src->at_prelude);
        if (src->source_file && !dst->source_file)
            dst->source_file = litavis_strdup(src->source_file);
        if (src->source_line && !dst->source_line)
            dst->source_line = src->source_line;
        /* Copy children for @-rules */
        int j;
        for (j = 0; j < src->child_count; j++) {
            LitavisRule *child = litavis_rule_add_child(dst, src->children[j].selector);
            litavis_rule_merge_props(child, &src->children[j]);
            child->is_at_rule = src->children[j].is_at_rule;
        }
    }

    litavis_ast_free(nested);
    litavis_ast_free(flat);
    litavis_token_list_free(tokens);
}

/* Parse a file into ctx->ast */
static void litavis_parse_file(LitavisCtx *ctx, const char *filename) {
    FILE *f = fopen(filename, "rb");
    if (!f) {
        char err[512];
        snprintf(err, sizeof(err), "cannot open file: %s", filename);
        LITAVIS_FATAL(err);
    }

    fseek(f, 0, SEEK_END);
    long size = ftell(f);
    fseek(f, 0, SEEK_SET);

    char *buf = (char*)malloc((size_t)size + 1);
    if (!buf) { fclose(f); LITAVIS_FATAL("out of memory"); }

    size_t read = fread(buf, 1, (size_t)size, f);
    buf[read] = '\0';
    fclose(f);

    /* Tokenise + parse */
    LitavisTokenList *tokens = litavis_tokenise(buf, (int)read);
    LitavisAST *nested = litavis_ast_new(16);
    LitavisParserCtx pctx;
    pctx.tokens = tokens;
    pctx.pos = 0;
    pctx.source_file = filename;
    litavis_parse_stylesheet(&pctx, nested, NULL);

    LitavisAST *flat = litavis_flatten(nested);

    int i, j;
    for (i = 0; i < flat->count; i++) {
        LitavisRule *src = &flat->rules[i];
        LitavisRule *dst = litavis_ast_add_rule(ctx->ast, src->selector);
        litavis_rule_merge_props(dst, src);
        dst->is_at_rule = src->is_at_rule;
        if (src->at_prelude && !dst->at_prelude)
            dst->at_prelude = litavis_strdup(src->at_prelude);
        if (src->source_file && !dst->source_file)
            dst->source_file = litavis_strdup(src->source_file);
        if (src->source_line && !dst->source_line)
            dst->source_line = src->source_line;
        for (j = 0; j < src->child_count; j++) {
            LitavisRule *child = litavis_rule_add_child(dst, src->children[j].selector);
            litavis_rule_merge_props(child, &src->children[j]);
            child->is_at_rule = src->children[j].is_at_rule;
        }
    }

    litavis_ast_free(nested);
    litavis_ast_free(flat);
    litavis_token_list_free(tokens);
    free(buf);
}

/* qsort comparator for directory entries */
static int litavis_dirent_cmp(const void *a, const void *b) {
    return strcmp(*(const char**)a, *(const char**)b);
}

/* Parse a directory of .css files (sorted, non-recursive) */
static void litavis_parse_dir(LitavisCtx *ctx, const char *dirname) {
    DIR *d = opendir(dirname);
    if (!d) {
        char err[512];
        snprintf(err, sizeof(err), "cannot open directory: %s", dirname);
        LITAVIS_FATAL(err);
    }

    /* Collect .css filenames */
    char *files[1024];
    int file_count = 0;
    struct dirent *ent;

    while ((ent = readdir(d)) != NULL && file_count < 1024) {
        int nlen = (int)strlen(ent->d_name);
        if (nlen > 4 && strcmp(ent->d_name + nlen - 4, ".css") == 0) {
            int dlen = (int)strlen(dirname);
            char *path = (char*)malloc((size_t)(dlen + 1 + nlen + 1));
            if (!path) LITAVIS_FATAL("out of memory");
            memcpy(path, dirname, (size_t)dlen);
            path[dlen] = '/';
            memcpy(path + dlen + 1, ent->d_name, (size_t)(nlen + 1));
            files[file_count++] = path;
        }
    }
    closedir(d);

    /* Sort alphabetically */
    qsort(files, (size_t)file_count, sizeof(char*), litavis_dirent_cmp);

    /* Parse each file */
    int i;
    for (i = 0; i < file_count; i++) {
        litavis_parse_file(ctx, files[i]);
        free(files[i]);
    }
}

#endif /* LITAVIS_PARSER_H */
