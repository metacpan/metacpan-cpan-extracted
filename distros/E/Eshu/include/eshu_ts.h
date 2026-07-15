/*
 * eshu_ts.h — TypeScript indentation scanner
 *
 * TypeScript is a strict superset of JavaScript.  The indentation model is
 * identical to eshu_js.h — all JS scanner states, template literal tracking,
 * and regex detection carry over unchanged.  This file provides a thin
 * eshu_ts_ctx_t typedef and a dedicated eshu_indent_ts() entry-point.
 */

#ifndef ESHU_TS_H
#define ESHU_TS_H

#include "eshu.h"
#include "eshu_js.h"

/* TypeScript is JS + type annotations; reuse JS context verbatim. */
typedef eshu_js_ctx_t eshu_ts_ctx_t;

static void eshu_ts_ctx_init(eshu_ts_ctx_t *ctx, const eshu_config_t *cfg) {
    eshu_js_ctx_init(ctx, cfg);
}

static char *eshu_indent_ts(const char *src, size_t src_len,
                             const eshu_config_t *cfg, size_t *out_len) {
    eshu_ts_ctx_t  ctx;
    eshu_buf_t     out;
    const char    *p   = src;
    const char    *end = src + src_len;
    int            line_num = 1;

    eshu_ts_ctx_init(&ctx, cfg);
    ctx.cfg.lang = ESHU_LANG_TS;
    eshu_buf_init(&out, src_len + 256);

    while (p < end) {
        const char *eol = eshu_find_eol(p);
        if (eshu_in_range(cfg, line_num)) {
            eshu_js_process_line((eshu_js_ctx_t *)&ctx, &out, p, eol);
        } else {
            size_t saved = out.len;
            eshu_js_process_line((eshu_js_ctx_t *)&ctx, &out, p, eol);
            out.len = saved;
            eshu_buf_write_trimmed(&out, p, (int)(eol - p));
            eshu_buf_putc(&out, '\n');
        }
        p = eol;
        if (*p == '\n') p++;
        line_num++;
    }

    eshu_buf_putc(&out, '\0');
    out.len--;
    *out_len = out.len;
    return out.data;
}


#include "eshu_hl_util.h"

/* ══════════════════════════════════════════════════════════════════
 *  TypeScript highlighter
 * ══════════════════════════════════════════════════════════════════ */

static const char * const eshu_hl_ts_kw[] = {
    /* JS keywords */
    "async", "await",
    "break",
    "case", "catch", "class", "const", "continue",
    "debugger", "default", "delete", "do",
    "else", "export", "extends",
    "false", "finally", "for", "function",
    "get",
    "if", "import", "in", "instanceof",
    "let",
    "new", "null",
    "of",
    "return",
    "set", "static", "super", "switch",
    "this", "throw", "true", "try", "typeof",
    "undefined",
    "var", "void",
    "while", "with",
    "yield",
    "Infinity", "NaN",
    /* TS-only keywords */
    "abstract", "any", "as", "asserts", "bigint", "boolean",
    "declare", "enum", "from", "implements", "infer", "interface",
    "is", "keyof", "module", "namespace", "never", "number", "object",
    "override", "private", "protected", "public", "readonly",
    "satisfies", "string", "symbol", "type", "unique", "unknown",
    "defined?",
    NULL
};

static const char * const eshu_hl_ts_bi[] = {
    /* JS builtins */
    "Array", "ArrayBuffer", "Boolean", "DataView", "Date", "Error",
    "Float32Array", "Float64Array", "Function", "Generator",
    "Int8Array", "Int16Array", "Int32Array",
    "Map", "Math", "Number", "Object", "Promise", "Proxy",
    "RangeError", "ReferenceError", "RegExp", "Set", "String",
    "Symbol", "SyntaxError", "TypeError", "Uint8Array",
    "Uint16Array", "Uint32Array", "URIError", "WeakMap", "WeakSet",
    "JSON", "console", "document", "window", "globalThis",
    /* TS utility types */
    "Partial", "Required", "Readonly", "Record", "Pick", "Omit",
    "Exclude", "Extract", "NonNullable", "ReturnType", "InstanceType",
    "Parameters", "ConstructorParameters", "Awaited",
    NULL
};

static char *eshu_highlight_ts(const char *src, size_t src_len, size_t *out_len) {
    eshu_buf_t out;
    const char *p     = src;
    const char *end   = src + src_len;
    const char *plain = p;
    int last_val      = 0;
    int tmpl_depth    = 0;

    eshu_buf_init(&out, src_len * 2 + 64);

#define TS_SPAN(cls, ts, te) do { \
    eshu_hl_flush(&out, plain, (ts)); \
    eshu_hl_span(&out, (cls), (ts), (te)); \
    p = (te); plain = p; \
} while(0)

    while (p < end) {
        char c = *p;

        /* line comment */
        if (c == '/' && p+1 < end && *(p+1) == '/') {
            const char *ts = p;
            while (p < end && *p != '\n') p++;
            TS_SPAN("esh-c", ts, p);
            continue;
        }

        /* block comment */
        if (c == '/' && p+1 < end && *(p+1) == '*') {
            const char *ts = p;
            p += 2;
            while (p+1 < end && !(*p == '*' && *(p+1) == '/')) p++;
            if (p+1 < end) p += 2;
            TS_SPAN("esh-c", ts, p);
            continue;
        }

        /* template literal */
        if (c == '`' || (tmpl_depth > 0 && c == '}')) {
            const char *ts = p++;
            if (c == '}' && tmpl_depth > 0) {
                /* closing ${ interpolation — resume template */
                tmpl_depth--;
            }
            while (p < end) {
                if (*p == '\\' && p+1 < end) { p += 2; continue; }
                if (*p == '$' && p+1 < end && *(p+1) == '{') {
                    p += 2; tmpl_depth++;
                    break;
                }
                if (*p == '`') { p++; break; }
                p++;
            }
            TS_SPAN("esh-s", ts, p);
            last_val = 1;
            continue;
        }

        /* double-quoted string */
        if (c == '"') {
            const char *ts = p++;
            while (p < end && *p != '"' && *p != '\n') {
                if (*p == '\\' && p+1 < end) p++;
                p++;
            }
            if (p < end && *p == '"') p++;
            TS_SPAN("esh-s", ts, p);
            last_val = 1;
            continue;
        }

        /* single-quoted string */
        if (c == '\'') {
            const char *ts = p++;
            while (p < end && *p != '\'' && *p != '\n') {
                if (*p == '\\' && p+1 < end) p++;
                p++;
            }
            if (p < end && *p == '\'') p++;
            TS_SPAN("esh-s", ts, p);
            last_val = 1;
            continue;
        }

        /* regex literal — only when not after a value */
        if (c == '/' && !last_val) {
            const char *ts = p++;
            int in_class = 0;
            while (p < end && *p != '\n') {
                if (*p == '\\' && p+1 < end) { p += 2; continue; }
                if (!in_class && *p == '[') { in_class = 1; p++; continue; }
                if (in_class  && *p == ']') { in_class = 0; p++; continue; }
                if (!in_class && *p == '/') { p++; break; }
                p++;
            }
            while (p < end && isalpha((unsigned char)*p)) p++;
            TS_SPAN("esh-r", ts, p);
            last_val = 1;
            continue;
        }

        /* number */
        if (isdigit((unsigned char)c) ||
            (c == '.' && p+1 < end && isdigit((unsigned char)*(p+1)))) {
            const char *ns = p;
            if (c == '0' && p+1 < end && (*(p+1) == 'x' || *(p+1) == 'X')) {
                p += 2;
                while (p < end && isxdigit((unsigned char)*p)) p++;
            } else if (c == '0' && p+1 < end && (*(p+1) == 'b' || *(p+1) == 'B')) {
                p += 2;
                while (p < end && (*p == '0' || *p == '1')) p++;
            } else {
                while (p < end && (isdigit((unsigned char)*p) || *p == '_')) p++;
                if (p < end && *p == '.') {
                    p++;
                    while (p < end && isdigit((unsigned char)*p)) p++;
                }
                if (p < end && (*p == 'e' || *p == 'E')) {
                    p++;
                    if (p < end && (*p == '+' || *p == '-')) p++;
                    while (p < end && isdigit((unsigned char)*p)) p++;
                }
                if (p < end && (*p == 'n')) p++;
            }
            TS_SPAN("esh-n", ns, p);
            last_val = 1;
            continue;
        }

        /* decorator: @Identifier */
        if (c == '@' && p+1 < end && (isalpha((unsigned char)*(p+1)) || *(p+1) == '_')) {
            const char *ts = p++;
            while (p < end && (isalnum((unsigned char)*p) || *p == '_' || *p == '.')) p++;
            TS_SPAN("esh-p", ts, p);
            last_val = 0;
            continue;
        }

        /* identifier or keyword */
        if (eshu_hl_isalpha_(c)) {
            const char *ts = p;
            while (p < end && eshu_hl_isalnum_(*p)) p++;
            eshu_hl_flush(&out, plain, ts);
            plain = p;
            size_t ilen = (size_t)(p - ts);
            if (eshu_hl_kw(ts, ilen, eshu_hl_ts_kw)) {
                eshu_hl_span(&out, "esh-k", ts, p);
                last_val = 0;
            } else if (eshu_hl_kw(ts, ilen, eshu_hl_ts_bi)) {
                eshu_hl_span(&out, "esh-b", ts, p);
                last_val = 1;
            } else {
                eshu_hl_write_html(&out, ts, ilen);
                last_val = 1;
            }
            continue;
        }

        /* rvalue context tracking */
        if (c == ')' || c == ']') last_val = 1;
        else if (c == '(' || c == '[' || c == ',' || c == ';' ||
                 c == '=' || c == '!' || c == ':' || c == '?' ||
                 c == '{' || c == '&' || c == '|' || c == '^' ||
                 c == '+' || c == '-' || c == '*' || c == '<' || c == '>')
            last_val = 0;
        if (c == '\n') last_val = 0;
        p++;
    }

    eshu_hl_flush(&out, plain, end);
    eshu_buf_putc(&out, '\0');
    *out_len = out.len - 1;
    return out.data;

#undef TS_SPAN
}

#endif /* ESHU_TS_H */
