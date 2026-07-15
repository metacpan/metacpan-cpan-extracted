/*
 * eshu_py.h — Python indentation normaliser
 *
 * Python uses significant whitespace: the indentation level IS the block
 * structure. This pass cannot recompute depth from tokens the way C does
 * (no braces to count). Instead it:
 *
 *   1. Reads the logical depth from existing leading whitespace via a
 *      depth stack (one entry per indent level, recording the column count
 *      at that level).
 *   2. Re-emits each line with the configured indent_char / indent_width,
 *      preserving the relative nesting the author wrote.
 *
 * String states (single/double/triple, f-strings) are tracked so that
 * leading whitespace inside multi-line strings is left untouched.
 *
 * Continuation lines (backslash at EOL, or inside unclosed brackets)
 * are emitted at their source depth — they are not re-indented.
 */

#ifndef ESHU_PY_H
#define ESHU_PY_H

#include "eshu.h"

/* ══════════════════════════════════════════════════════════════════
 *  Measure leading whitespace, normalising tabs to 8-space stops
 * ══════════════════════════════════════════════════════════════════ */

static int eshu_py_measure_indent(const char *p, const char *eol) {
    int col = 0;
    while (p < eol && (*p == ' ' || *p == '\t')) {
        if (*p == '\t')
            col = (col + 8) & ~7; /* next 8-column tab stop */
        else
            col++;
        p++;
    }
    return col;
}

/* ══════════════════════════════════════════════════════════════════
 *  Context init
 * ══════════════════════════════════════════════════════════════════ */

static void eshu_py_ctx_init(eshu_py_ctx_t *ctx, const eshu_config_t *cfg) {
    ctx->depth           = 0;
    ctx->depth_stack[0]  = 0;
    ctx->depth_top       = 1; /* level 0 = 0 spaces */
    ctx->bracket_depth   = 0;
    ctx->in_continuation = 0;
    ctx->state           = ESHU_CODE;
    ctx->cfg             = *cfg;
}

/* ══════════════════════════════════════════════════════════════════
 *  Scan a line's content to update bracket depth, detect
 *  continuation, and track string states.
 *  Returns 1 if the line ends with a backslash continuation.
 * ══════════════════════════════════════════════════════════════════ */

static int eshu_py_scan_line(eshu_py_ctx_t *ctx,
                             const char *p, const char *eol) {
    int backslash_cont = 0;

    while (p < eol) {
        char c = *p;

        /* ── inside triple-double-quote ── */
        if (ctx->state == ESHU_PY_STRING_DQ3) {
            if (c == '"' && (eol - p) >= 3 &&
                p[1] == '"' && p[2] == '"') {
                ctx->state = ESHU_CODE;
                p += 3; continue;
            }
            if (c == '\\') { p++; } /* skip escaped char */
            p++; continue;
        }

        /* ── inside triple-single-quote ── */
        if (ctx->state == ESHU_PY_STRING_SQ3) {
            if (c == '\'' && (eol - p) >= 3 &&
                p[1] == '\'' && p[2] == '\'') {
                ctx->state = ESHU_CODE;
                p += 3; continue;
            }
            if (c == '\\') { p++; }
            p++; continue;
        }

        /* ── inside single double-quote ── */
        if (ctx->state == ESHU_PY_STRING_DQ ||
            ctx->state == ESHU_PY_FSTRING_DQ) {
            if (c == '"')  { ctx->state = ESHU_CODE; p++; continue; }
            if (c == '\\') { p++; }
            p++; continue;
        }

        /* ── inside single single-quote ── */
        if (ctx->state == ESHU_PY_STRING_SQ ||
            ctx->state == ESHU_PY_FSTRING_SQ) {
            if (c == '\'') { ctx->state = ESHU_CODE; p++; continue; }
            if (c == '\\') { p++; }
            p++; continue;
        }

        /* ── normal code ── */

        /* comment: rest of line is irrelevant */
        if (c == '#') break;

        /* f-string / b-string / r-string prefixes */
        if ((c == 'f' || c == 'F' || c == 'b' || c == 'B' ||
             c == 'r' || c == 'R' || c == 'u' || c == 'U') &&
            (p[1] == '"' || p[1] == '\'')) {
            int is_f = (c == 'f' || c == 'F');
            p++;
            c = *p;
            /* check for triple */
            if ((eol - p) >= 3 && p[1] == c && p[2] == c) {
                ctx->state = (c == '"') ? ESHU_PY_STRING_DQ3
                                        : ESHU_PY_STRING_SQ3;
                p += 3; continue;
            }
            ctx->state = is_f
                ? (c == '"' ? ESHU_PY_FSTRING_DQ : ESHU_PY_FSTRING_SQ)
                : (c == '"' ? ESHU_PY_STRING_DQ  : ESHU_PY_STRING_SQ);
            p++; continue;
        }

        /* two-char prefix rb / br */
        if ((c == 'r' || c == 'R') &&
            (p[1] == 'b' || p[1] == 'B') &&
            (p[2] == '"' || p[2] == '\'')) {
            p += 2;
            c = *p;
            if ((eol - p) >= 3 && p[1] == c && p[2] == c) {
                ctx->state = (c == '"') ? ESHU_PY_STRING_DQ3
                                        : ESHU_PY_STRING_SQ3;
                p += 3; continue;
            }
            ctx->state = (c == '"') ? ESHU_PY_STRING_DQ : ESHU_PY_STRING_SQ;
            p++; continue;
        }

        /* triple-quote open */
        if ((c == '"' || c == '\'') &&
            (eol - p) >= 3 && p[1] == c && p[2] == c) {
            ctx->state = (c == '"') ? ESHU_PY_STRING_DQ3
                                    : ESHU_PY_STRING_SQ3;
            p += 3; continue;
        }

        /* single-quote open */
        if (c == '"') { ctx->state = ESHU_PY_STRING_DQ; p++; continue; }
        if (c == '\'') { ctx->state = ESHU_PY_STRING_SQ; p++; continue; }

        /* brackets */
        if (c == '(' || c == '[' || c == '{') { ctx->bracket_depth++; }
        if (c == ')' || c == ']' || c == '}') {
            if (ctx->bracket_depth > 0) ctx->bracket_depth--;
        }

        p++;
    }

    /* eol points to '\n' or NUL; the char immediately before is the
     * last content character on the line. A trailing '\' means the
     * logical line continues on the next physical line. */
    backslash_cont = (eol > p && *(eol - 1) == '\\') ? 1 : 0;
    return backslash_cont;
}

/* ══════════════════════════════════════════════════════════════════
 *  Resolve logical depth for a line given its leading-space count.
 *  Pushes/pops the depth stack as needed.
 * ══════════════════════════════════════════════════════════════════ */

static int eshu_py_resolve_depth(eshu_py_ctx_t *ctx, int col) {
    int top;

    /* Increase: new indent level */
    if (ctx->depth_top < 64 &&
        col > ctx->depth_stack[ctx->depth_top - 1]) {
        ctx->depth_stack[ctx->depth_top++] = col;
        ctx->depth = ctx->depth_top - 1;
        return ctx->depth;
    }

    /* Decrease or same: pop until we find a matching level */
    top = ctx->depth_top;
    while (top > 1 && col < ctx->depth_stack[top - 1])
        top--;
    ctx->depth_top = top;

    /* If col matches the current top exactly, depth = top-1.
     * If it doesn't match any known level (dedent to unknown),
     * treat as matching the closest lower level. */
    ctx->depth = top - 1;
    return ctx->depth;
}

/* ══════════════════════════════════════════════════════════════════
 *  Process one line
 * ══════════════════════════════════════════════════════════════════ */

static void eshu_py_process_line(eshu_py_ctx_t *ctx, eshu_buf_t *out,
                                 const char *line_start, const char *eol) {
    const char *p    = line_start;
    const char *end  = eol;
    int         col  = 0;
    int         depth;
    int         in_ml_string;
    int         backslash_cont;

    in_ml_string = (ctx->state == ESHU_PY_STRING_DQ3 ||
                    ctx->state == ESHU_PY_STRING_SQ3);

    /* ── Multi-line string body: emit verbatim ── */
    if (in_ml_string) {
        /* scan for closing triple quote; emit the raw line unchanged */
        eshu_py_scan_line(ctx, p, end);
        eshu_buf_write(out, line_start, (size_t)(eol - line_start));
        eshu_buf_putc(out, '\n');
        return;
    }

    /* ── Blank line: emit as-is (just a newline) ── */
    {
        const char *nc = eshu_skip_leading_ws(p);
        if (nc >= end) {
            eshu_buf_putc(out, '\n');
            return;
        }
    }

    /* ── Continuation line: preserve source indentation ── */
    if (ctx->in_continuation || ctx->bracket_depth > 0) {
        backslash_cont = eshu_py_scan_line(ctx, p, end);
        ctx->in_continuation = backslash_cont;
        eshu_buf_write(out, line_start, (size_t)(eol - line_start));
        eshu_buf_putc(out, '\n');
        return;
    }

    /* ── Normal line: measure indent, resolve depth, re-emit ── */
    col   = eshu_py_measure_indent(p, end);
    depth = eshu_py_resolve_depth(ctx, col);

    /* Skip past leading whitespace to the content */
    while (p < end && (*p == ' ' || *p == '\t')) p++;

    /* Emit re-indented line */
    eshu_emit_indent(out, depth, &ctx->cfg);
    eshu_buf_write_trimmed(out, p, (int)(end - p));
    eshu_buf_putc(out, '\n');

    /* Scan content to update bracket_depth and string state */
    backslash_cont = eshu_py_scan_line(ctx, p, end);
    ctx->in_continuation = backslash_cont;
}

/* ══════════════════════════════════════════════════════════════════
 *  Public API
 * ══════════════════════════════════════════════════════════════════ */

static char *eshu_indent_python(const char *src, size_t src_len,
                                const eshu_config_t *cfg, size_t *out_len) {
    eshu_py_ctx_t ctx;
    eshu_buf_t    out;
    const char   *p   = src;
    const char   *end = src + src_len;
    char         *result;

    eshu_py_ctx_init(&ctx, cfg);
    eshu_buf_init(&out, src_len + 256);

    while (p < end) {
        const char *eol = eshu_find_eol(p);
        eshu_py_process_line(&ctx, &out, p, eol);
        p = (*eol == '\n') ? eol + 1 : eol;
        if (p > end) p = end;
    }

    eshu_buf_putc(&out, '\0');
    out.len--;

    *out_len = out.len;
    result   = out.data;
    return result;
}


#include "eshu_hl_util.h"

/* ══════════════════════════════════════════════════════════════════
 *  Python keyword and builtin lists
 * ══════════════════════════════════════════════════════════════════ */

static const char * const eshu_hl_py_kw[] = {
    "False", "None", "True",
    "and", "as", "assert", "async", "await",
    "break", "class", "continue", "def", "del",
    "elif", "else", "except", "finally", "for",
    "from", "global", "if", "import", "in",
    "is", "lambda", "match", "case",
    "nonlocal", "not", "or", "pass", "raise",
    "return", "try", "while", "with", "yield",
    NULL
};

static const char * const eshu_hl_py_bi[] = {
    "abs", "all", "any", "ascii", "bin", "bool", "breakpoint",
    "bytearray", "bytes", "callable", "chr", "classmethod",
    "compile", "complex", "delattr", "dict", "dir", "divmod",
    "enumerate", "eval", "exec", "filter", "float", "format",
    "frozenset", "getattr", "globals", "hasattr", "hash",
    "help", "hex", "id", "input", "int", "isinstance",
    "issubclass", "iter", "len", "list", "locals", "map",
    "max", "memoryview", "min", "next", "object", "oct",
    "open", "ord", "pow", "print", "property", "range",
    "repr", "reversed", "round", "set", "setattr", "slice",
    "sorted", "staticmethod", "str", "sum", "super", "tuple",
    "type", "vars", "zip",
    NULL
};

/* ══════════════════════════════════════════════════════════════════
 *  Python highlighter
 * ══════════════════════════════════════════════════════════════════ */

/* Scan a Python string body starting at *pp, emitting into out.
 * q1 = opening quote char, triple = 1 for triple-quoted.
 * Advances *pp past the closing delimiter. */
static void eshu_hl_py_string(eshu_buf_t *out, const char **pp,
                               const char *end, char q1, int triple) {
    const char *p   = *pp;
    const char *ts  = p - (triple ? 3 : 1) - 1; /* include opening quote(s) and any prefix */
    /* We were called after the opening quote(s) were consumed.
     * Back up to find the true start (prefix + quotes already emitted as plain).
     * Instead: span starts at ts passed by caller — here we just scan the body
     * and emit the whole span from the already-remembered start. */
    /* Actually the caller handles span emission; we just need to find the end. */
    (void)ts;

    while (p < end) {
        if (*p == '\\') { p += 2; continue; } /* skip escaped char */
        if (triple) {
            if (*p == q1 && (end - p) >= 3 && p[1] == q1 && p[2] == q1) {
                p += 3; break;
            }
        } else {
            if (*p == q1) { p++; break; }
            if (*p == '\n') break; /* unterminated single-line string */
        }
        p++;
    }
    *pp = p;
}

static char *eshu_highlight_py(const char *src, size_t src_len, size_t *out_len) {
    eshu_buf_t  out;
    const char *p     = src;
    const char *end   = src + src_len;
    const char *plain = p;

    eshu_buf_init(&out, src_len * 2 + 64);

#define PY_FLUSH(upto)      eshu_hl_flush(&out, plain, (upto))
#define PY_SPAN(cls, s, e)  do { PY_FLUSH(s); eshu_hl_span(&out, (cls), (s), (e)); plain = (e); p = (e); } while(0)

    while (p < end) {
        char c = *p;

        /* ── comment ── */
        if (c == '#') {
            const char *ts = p;
            while (p < end && *p != '\n') p++;
            PY_SPAN("esh-c", ts, p);
            continue;
        }

        /* ── decorator ── */
        if (c == '@' && (p == src || *(p-1) == '\n')) {
            const char *ts = p++;
            while (p < end && (isalnum((unsigned char)*p) || *p == '_' || *p == '.')) p++;
            PY_SPAN("esh-p", ts, p);
            continue;
        }

        /* ── string / bytes / f-string / r-string ── */
        if (c == '"' || c == '\'' ||
            ((c == 'f' || c == 'F' || c == 'b' || c == 'B' ||
              c == 'r' || c == 'R' || c == 'u' || c == 'U') &&
             (p[1] == '"' || p[1] == '\'' ||
              ((p[1] == 'b' || p[1] == 'B' || p[1] == 'r' || p[1] == 'R') &&
               (p+2 < end) && (p[2] == '"' || p[2] == '\''))))) {
            const char *ts  = p;
            int         is_f = (c == 'f' || c == 'F');
            char        q1;
            int         triple;

            /* skip prefix letters */
            while (p < end && (isalpha((unsigned char)*p)) &&
                   *p != '"' && *p != '\'')
                p++;
            if (p >= end) break;
            q1 = *p++;
            triple = (p + 1 < end && *p == q1 && *(p+1) == q1);
            if (triple) p += 2;

            eshu_hl_py_string(&out, &p, end, q1, triple);
            /* emit the whole token as esh-s (f-string exprs get no sub-span
             * in this pass — full f-string interpolation would need a
             * recursive sub-scanner) */
            PY_FLUSH(ts);
            eshu_hl_span(&out, is_f ? "esh-r" : "esh-s", ts, p);
            plain = p;
            continue;
        }

        /* ── number ── */
        if (isdigit((unsigned char)c) ||
            (c == '.' && p+1 < end && isdigit((unsigned char)p[1]))) {
            const char *ts = p;
            /* hex / octal / binary */
            if (c == '0' && p+1 < end &&
                (p[1] == 'x' || p[1] == 'X' ||
                 p[1] == 'o' || p[1] == 'O' ||
                 p[1] == 'b' || p[1] == 'B')) {
                p += 2;
                while (p < end && (isxdigit((unsigned char)*p) || *p == '_')) p++;
            } else {
                while (p < end && (isdigit((unsigned char)*p) || *p == '_')) p++;
                if (p < end && *p == '.') {
                    p++;
                    while (p < end && (isdigit((unsigned char)*p) || *p == '_')) p++;
                }
                if (p < end && (*p == 'e' || *p == 'E')) {
                    p++;
                    if (p < end && (*p == '+' || *p == '-')) p++;
                    while (p < end && isdigit((unsigned char)*p)) p++;
                }
                /* complex suffix j/J */
                if (p < end && (*p == 'j' || *p == 'J')) p++;
            }
            PY_SPAN("esh-n", ts, p);
            continue;
        }

        /* ── identifier: keyword or builtin ── */
        if (isalpha((unsigned char)c) || c == '_') {
            const char *ts = p;
            while (p < end && (isalnum((unsigned char)*p) || *p == '_')) p++;
            if (eshu_hl_kw(ts, (size_t)(p - ts), eshu_hl_py_kw)) {
                PY_SPAN("esh-k", ts, p);
            } else if (eshu_hl_kw(ts, (size_t)(p - ts), eshu_hl_py_bi)) {
                PY_SPAN("esh-b", ts, p);
            }
            /* else: plain identifier, leave in plain buffer */
            continue;
        }

        p++;
    }

    eshu_hl_flush(&out, plain, end);
    eshu_buf_putc(&out, '\0');
    *out_len = out.len - 1;
    return out.data;

#undef PY_FLUSH
#undef PY_SPAN
}

#endif /* ESHU_PY_H */
