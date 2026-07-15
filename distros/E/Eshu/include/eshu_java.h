/*
 * eshu_java.h — Java language indentation scanner
 *
 * Tracks {} nesting depth while skipping strings, text blocks,
 * char literals, and comments. Handles switch case labels (both
 * classic 'case X:' and arrow 'case X ->').
 *
 * Pure C, no Perl dependencies, header-only.
 */

#ifndef ESHU_JAVA_H
#define ESHU_JAVA_H

#include "eshu.h"

/* ══════════════════════════════════════════════════════════════════
 *  Helpers — line classification
 * ══════════════════════════════════════════════════════════════════ */

static int eshu_java_is_closing(char c) {
    return c == '}';
}

/* Returns 1 if the trimmed content is a switch case label.
 * Recognises both  "case X:"  and  "case X ->"  (arrow switch),
 * as well as  "default:"  and  "default ->".               */
static int eshu_java_is_case_label(const char *content, int len) {
    const char *p, *end;
    int saw_arrow = 0;
    int is_case   = 0;

    if (len < 2) return 0;

    if (len >= 5 && strncmp(content, "case ", 5) == 0)
        is_case = 1;
    else if (len >= 7 && strncmp(content, "default", 7) == 0 &&
             (len == 7 || content[7] == ':' || content[7] == ' ' ||
              content[7] == '\t' || content[7] == '-' || content[7] == '/'))
        is_case = 1;

    if (!is_case) return 0;

    p   = content;
    end = content + len;

    while (p < end) {
        if (*p == '/' && p + 1 < end && *(p + 1) == '/') {
            end = p; break;
        }
        if (*p == '"') {
            p++;
            while (p < end && *p != '"') {
                if (*p == '\\') p++;
                p++;
            }
        } else if (*p == '\'') {
            p++;
            while (p < end && *p != '\'') {
                if (*p == '\\') p++;
                p++;
            }
        } else if (*p == '-' && p + 1 < end && *(p + 1) == '>') {
            saw_arrow = 1;
        }
        p++;
    }

    while (end > content && (*(end - 1) == ' ' || *(end - 1) == '\t')) end--;
    if (end <= content) return 0;

    if (*(end - 1) == ':') return 1;
    if (saw_arrow)         return 1;

    return 0;
}

/* ══════════════════════════════════════════════════════════════════
 *  Scan a line — update ctx state and depth for the next line
 *
 *  Called AFTER the line has been emitted.
 * ══════════════════════════════════════════════════════════════════ */

static void eshu_java_scan_line(eshu_java_ctx_t *ctx,
                                const char *p, const char *end) {
    while (p < end) {
        char c = *p;

        switch (ctx->state) {
        case ESHU_CODE:
            if (c == '{') {
                ctx->depth++;
            } else if (c == '}') {
                ctx->depth--;
                if (ctx->depth < 0) ctx->depth = 0;
            } else if (c == '(') {
                ctx->paren_depth++;
            } else if (c == ')') {
                if (ctx->paren_depth > 0) ctx->paren_depth--;
            } else if (c == '[') {
                ctx->bracket_depth++;
            } else if (c == ']') {
                if (ctx->bracket_depth > 0) ctx->bracket_depth--;
            } else if (c == '"') {
                if (p + 2 < end && *(p + 1) == '"' && *(p + 2) == '"') {
                    ctx->state = ESHU_JAVA_TEXT_BLOCK;
                    p += 2;
                } else {
                    ctx->state = ESHU_STRING_DQ;
                }
            } else if (c == '\'') {
                ctx->state = ESHU_JAVA_CHAR;
            } else if (c == '/' && p + 1 < end && *(p + 1) == '/') {
                return; /* line comment — skip rest */
            } else if (c == '/' && p + 1 < end && *(p + 1) == '*') {
                ctx->state = ESHU_COMMENT_BLOCK;
                p++;
            }
            break;

        case ESHU_STRING_DQ:
            if (c == '\\' && p + 1 < end) {
                p++;
            } else if (c == '"') {
                ctx->state = ESHU_CODE;
            }
            break;

        case ESHU_JAVA_CHAR:
            if (c == '\\' && p + 1 < end) {
                p++;
            } else if (c == '\'') {
                ctx->state = ESHU_CODE;
            }
            break;

        case ESHU_JAVA_TEXT_BLOCK:
            if (c == '"' && p + 2 <= end &&
                p + 1 < end && *(p + 1) == '"' &&
                p + 2 < end && *(p + 2) == '"') {
                ctx->state = ESHU_CODE;
                p += 2;
            }
            break;

        case ESHU_COMMENT_BLOCK:
            if (c == '*' && p + 1 < end && *(p + 1) == '/') {
                ctx->state = ESHU_CODE;
                p++;
            }
            break;

        default:
            break;
        }
        p++;
    }
}

/* ══════════════════════════════════════════════════════════════════
 *  Process a single line — decide indent, emit, scan
 * ══════════════════════════════════════════════════════════════════ */

static void eshu_java_process_line(eshu_java_ctx_t *ctx, eshu_buf_t *out,
                                   const char *line_start, const char *eol) {
    const char *content = eshu_skip_leading_ws(line_start);
    int line_len;
    int indent_depth;

    /* empty line — preserve */
    if (content >= eol) {
        eshu_buf_putc(out, '\n');
        return;
    }

    line_len = (int)(eol - content);

    /* block comment continuation: indent at current depth */
    if (ctx->state == ESHU_COMMENT_BLOCK) {
        eshu_emit_indent(out, ctx->depth, &ctx->cfg);
        eshu_buf_write_trimmed(out, content, line_len);
        eshu_buf_putc(out, '\n');
        eshu_java_scan_line(ctx, content, eol);
        return;
    }

    /* text block content: emit verbatim (significant whitespace) */
    if (ctx->state == ESHU_JAVA_TEXT_BLOCK) {
        eshu_buf_write(out, line_start, (size_t)(eol - line_start));
        eshu_buf_putc(out, '\n');
        eshu_java_scan_line(ctx, content, eol);
        return;
    }

    /* normal code */
    indent_depth = ctx->depth;

    /* clear case_extra once depth drops below case_depth */
    if (ctx->case_extra && ctx->depth < ctx->case_depth)
        ctx->case_extra = 0;

    if (eshu_java_is_closing(*content)) {
        indent_depth--;
        if (indent_depth < 0) indent_depth = 0;
        if (ctx->case_extra && ctx->depth > ctx->case_depth)
            indent_depth++;
    } else if (eshu_java_is_case_label(content, line_len)) {
        ctx->case_depth = ctx->depth;
        ctx->case_extra = 1;
    } else if (ctx->case_extra && ctx->depth >= ctx->case_depth) {
        indent_depth++;
    }

    eshu_emit_indent(out, indent_depth, &ctx->cfg);
    eshu_buf_write_trimmed(out, content, line_len);
    eshu_buf_putc(out, '\n');

    eshu_java_scan_line(ctx, content, eol);
}

/* ══════════════════════════════════════════════════════════════════
 *  Public API — indent a Java source string
 * ══════════════════════════════════════════════════════════════════ */

static char *eshu_indent_java(const char *src, size_t src_len,
                              const eshu_config_t *cfg, size_t *out_len) {
    eshu_java_ctx_t ctx;
    eshu_buf_t      out;
    const char     *p   = src;
    const char     *end = src + src_len;
    char           *result;

    memset(&ctx, 0, sizeof(ctx));
    ctx.state = ESHU_CODE;
    ctx.cfg   = *cfg;

    eshu_buf_init(&out, src_len + 256);

    {
        int line_num = 1;
        while (p < end) {
            const char *eol = eshu_find_eol(p);

            if (eshu_in_range(cfg, line_num)) {
                eshu_java_process_line(&ctx, &out, p, eol);
            } else {
                size_t saved = out.len;
                eshu_java_process_line(&ctx, &out, p, eol);
                out.len = saved;
                eshu_buf_write_trimmed(&out, p, (int)(eol - p));
                eshu_buf_putc(&out, '\n');
            }

            p = eol;
            if (*p == '\n') p++;
            line_num++;
        }
    }

    eshu_buf_putc(&out, '\0');
    out.len--;
    *out_len = out.len;
    result   = out.data;
    return result;
}


#include "eshu_hl_util.h"

/* ══════════════════════════════════════════════════════════════════
 *  Java keyword and builtin lists
 * ══════════════════════════════════════════════════════════════════ */

static const char * const eshu_hl_java_kw[] = {
    "abstract", "assert", "boolean", "break", "byte",
    "case", "catch", "char", "class", "const",
    "continue", "default", "do", "double", "else",
    "enum", "extends", "final", "finally", "float",
    "for", "goto", "if", "implements", "import",
    "instanceof", "int", "interface", "long", "native",
    "new", "package", "private", "protected", "public",
    "record", "return", "sealed", "short", "static",
    "strictfp", "super", "switch", "synchronized",
    "this", "throw", "throws", "transient", "try",
    "var", "void", "volatile", "while", "yield",
    "false", "null", "true",
    "permits", "when",
    NULL
};

static const char * const eshu_hl_java_bi[] = {
    "Object", "String", "Integer", "Long", "Double", "Float",
    "Boolean", "Character", "Byte", "Short",
    "System", "Math", "StringBuilder", "StringBuffer",
    "Exception", "RuntimeException", "Error", "Throwable",
    "Iterable", "Iterator", "Comparable", "Cloneable",
    "Class", "ClassLoader",
    "Thread", "Runnable",
    "Override", "Deprecated", "SuppressWarnings", "FunctionalInterface",
    NULL
};

/* ══════════════════════════════════════════════════════════════════
 *  Java highlighter
 * ══════════════════════════════════════════════════════════════════ */

static char *eshu_highlight_java(const char *src, size_t src_len, size_t *out_len) {
    eshu_buf_t  out;
    const char *p     = src;
    const char *end   = src + src_len;
    const char *plain = p;
    int in_text_block = 0;

    eshu_buf_init(&out, src_len * 2 + 64);

#define JAVA_SPAN(cls, ts, te) do { \
    eshu_hl_flush(&out, plain, (ts)); \
    eshu_hl_span(&out, (cls), (ts), (te)); \
    p = (te); plain = p; \
} while(0)

    while (p < end) {
        char c = *p;

        /* text block content: pass through until closing """ */
        if (in_text_block) {
            if (c == '"' && p + 2 < end && *(p+1) == '"' && *(p+2) == '"') {
                const char *te = p + 3;
                JAVA_SPAN("esh-s", plain, te);
                in_text_block = 0;
            } else {
                p++;
            }
            continue;
        }

        /* annotation @Name */
        if (c == '@') {
            const char *ts = p++;
            while (p < end && (isalnum((unsigned char)*p) || *p == '_')) p++;
            JAVA_SPAN("esh-p", ts, p);
            continue;
        }

        /* line comment */
        if (c == '/' && p + 1 < end && *(p + 1) == '/') {
            const char *ts = p;
            p += 2;
            while (p < end && *p != '\n') p++;
            JAVA_SPAN("esh-c", ts, p);
            continue;
        }

        /* block comment (including javadoc) */
        if (c == '/' && p + 1 < end && *(p + 1) == '*') {
            const char *ts = p;
            p += 2;
            while (p + 1 < end && !(*p == '*' && *(p + 1) == '/')) p++;
            if (p + 1 < end) p += 2;
            JAVA_SPAN("esh-c", ts, p);
            continue;
        }

        /* text block """ */
        if (c == '"' && p + 2 < end && *(p+1) == '"' && *(p+2) == '"') {
            eshu_hl_flush(&out, plain, p);
            plain = p;
            in_text_block = 1;
            p += 3;
            continue;
        }

        /* string "..." */
        if (c == '"') {
            const char *ts = p++;
            while (p < end && *p != '"') {
                if (*p == '\\') { p++; if (p < end) p++; continue; }
                if (*p == '\n') break;
                p++;
            }
            if (p < end && *p == '"') p++;
            JAVA_SPAN("esh-s", ts, p);
            continue;
        }

        /* char literal '.' */
        if (c == '\'') {
            const char *ts = p++;
            while (p < end && *p != '\'') {
                if (*p == '\\') { p++; if (p < end) p++; continue; }
                if (*p == '\n') break;
                p++;
            }
            if (p < end && *p == '\'') p++;
            JAVA_SPAN("esh-s", ts, p);
            continue;
        }

        /* number: 0x hex, 0b binary, decimal, float */
        if (isdigit((unsigned char)c)) {
            const char *ts = p;
            if (c == '0' && p + 1 < end) {
                char nx = *(p + 1);
                if (nx == 'x' || nx == 'X') {
                    p += 2;
                    while (p < end && (isxdigit((unsigned char)*p) || *p == '_')) p++;
                } else if (nx == 'b' || nx == 'B') {
                    p += 2;
                    while (p < end && (*p == '0' || *p == '1' || *p == '_')) p++;
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
                }
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
            }
            /* long / float / double suffix */
            if (p < end && (*p == 'L' || *p == 'l' || *p == 'f' || *p == 'F' ||
                            *p == 'd' || *p == 'D')) p++;
            JAVA_SPAN("esh-n", ts, p);
            continue;
        }

        /* identifier / keyword / builtin */
        if (eshu_hl_isalpha_(c)) {
            const char *ts = p;
            while (p < end && eshu_hl_isalnum_(*p)) p++;
            eshu_hl_flush(&out, plain, ts);
            plain = p;
            if (eshu_hl_kw(ts, (size_t)(p - ts), eshu_hl_java_kw)) {
                eshu_hl_span(&out, "esh-k", ts, p);
            } else if (eshu_hl_kw(ts, (size_t)(p - ts), eshu_hl_java_bi)) {
                eshu_hl_span(&out, "esh-b", ts, p);
            } else {
                eshu_hl_write_html(&out, ts, (size_t)(p - ts));
            }
            continue;
        }

        p++;
    }

    /* flush any pending text block that wasn't closed */
    eshu_hl_flush(&out, plain, end);
    eshu_buf_putc(&out, '\0');
    *out_len = out.len - 1;
    return out.data;

#undef JAVA_SPAN
}

#endif /* ESHU_JAVA_H */
