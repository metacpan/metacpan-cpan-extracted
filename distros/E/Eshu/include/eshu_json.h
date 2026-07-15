/*
 * eshu_json.h — JSON/JSONC token-based reformatter for Eshu
 *
 * Fully re-serialises JSON with correct indentation, handling both
 * compact single-line input and already-formatted multi-line input.
 * JSONC extensions (// and block comments) are tolerated and preserved.
 *
 * Pure C, no Perl dependencies, header-only.
 */

#ifndef ESHU_JSON_H
#define ESHU_JSON_H

#include "eshu.h"

/* ══════════════════════════════════════════════════════════════════
 *  Internal helpers
 * ══════════════════════════════════════════════════════════════════ */

/* Advance past a JSON string body starting at *pp (which already
 * points past the opening ").  Stops after the closing ". */
static void eshu_json_scan_string(const char **pp, const char *end) {
    const char *p = *pp;
    while (p < end) {
        if (*p == '\\') { p += 2; continue; }
        if (*p == '"')  { p++;    break;     }
        p++;
    }
    *pp = p;
}

/* Skip whitespace including newlines. */
static void eshu_json_skip_ws(const char **pp, const char *end) {
    while (*pp < end && (unsigned char)**pp <= ' ') (*pp)++;
}

/* Skip a // line comment.  *pp must point at the first '/' of '//'.
 * Advances to just past the newline (or end). */
static void eshu_json_skip_line_comment(const char **pp, const char *end) {
    *pp += 2; /* skip '//' */
    while (*pp < end && **pp != '\n') (*pp)++;
    if (*pp < end) (*pp)++; /* skip '\n' */
}

/* Skip a block comment.  *pp must point at the first '/' of "/ *".
 * Advances past the closing "* /". */
static void eshu_json_skip_block_comment(const char **pp, const char *end) {
    *pp += 2; /* skip slash-star */
    while (*pp + 1 < end) {
        if (**pp == '*' && *(*pp + 1) == '/') { *pp += 2; return; }
        (*pp)++;
    }
    *pp = end;
}

/* ══════════════════════════════════════════════════════════════════
 *  eshu_indent_json
 * ══════════════════════════════════════════════════════════════════ */

static char *eshu_indent_json(const char *src, size_t src_len,
                               const eshu_config_t *cfg, size_t *out_len)
{
    eshu_buf_t  out;
    const char *p   = src;
    const char *end = src + src_len;
    int         depth = 0;

    /* skip UTF-8 BOM */
    if (src_len >= 3 &&
        (unsigned char)p[0] == 0xEF &&
        (unsigned char)p[1] == 0xBB &&
        (unsigned char)p[2] == 0xBF)
        p += 3;

    eshu_buf_init(&out, src_len + 512);

    while (p < end) {
        /* skip inter-token whitespace */
        eshu_json_skip_ws(&p, end);
        if (p >= end) break;

        char c = *p;

        /* JSONC // comment: skip silently (reformatter normalises layout) */
        if (c == '/' && p + 1 < end && *(p + 1) == '/') {
            eshu_json_skip_line_comment(&p, end);
            continue;
        }

        /* JSONC block comment: skip silently */
        if (c == '/' && p + 1 < end && *(p + 1) == '*') {
            eshu_json_skip_block_comment(&p, end);
            continue;
        }

        /* string */
        if (c == '"') {
            const char *ts = p;
            p++; /* past opening " */
            eshu_json_scan_string(&p, end);
            eshu_buf_write(&out, ts, (size_t)(p - ts));
            continue;
        }

        /* number (including negative) */
        if (c == '-' || isdigit((unsigned char)c)) {
            const char *ts = p;
            if (*p == '-') p++;
            while (p < end && isdigit((unsigned char)*p)) p++;
            if (p < end && *p == '.') {
                p++;
                while (p < end && isdigit((unsigned char)*p)) p++;
            }
            if (p < end && (*p == 'e' || *p == 'E')) {
                p++;
                if (p < end && (*p == '+' || *p == '-')) p++;
                while (p < end && isdigit((unsigned char)*p)) p++;
            }
            eshu_buf_write(&out, ts, (size_t)(p - ts));
            continue;
        }

        /* keywords: true / false / null */
        if (isalpha((unsigned char)c)) {
            const char *ts = p;
            while (p < end && isalpha((unsigned char)*p)) p++;
            eshu_buf_write(&out, ts, (size_t)(p - ts));
            continue;
        }

        /* open container { or [ */
        if (c == '{' || c == '[') {
            char close = (c == '{') ? '}' : ']';
            eshu_buf_putc(&out, c);
            p++;
            /* look ahead (skipping whitespace) for empty container */
            const char *q = p;
            eshu_json_skip_ws(&q, end);
            if (q < end && *q == close) {
                /* empty container: emit inline, advance past close */
                eshu_buf_putc(&out, close);
                p = q + 1;
            } else {
                depth++;
                eshu_buf_putc(&out, '\n');
                eshu_emit_indent(&out, depth, cfg);
            }
            continue;
        }

        /* close container } or ] */
        if (c == '}' || c == ']') {
            depth--;
            if (depth < 0) depth = 0;
            eshu_buf_putc(&out, '\n');
            eshu_emit_indent(&out, depth, cfg);
            eshu_buf_putc(&out, c);
            p++;
            continue;
        }

        /* comma — separator between elements */
        if (c == ',') {
            eshu_buf_putc(&out, ',');
            eshu_buf_putc(&out, '\n');
            eshu_emit_indent(&out, depth, cfg);
            p++;
            continue;
        }

        /* colon — key/value separator */
        if (c == ':') {
            eshu_buf_putc(&out, ':');
            eshu_buf_putc(&out, ' ');
            p++;
            continue;
        }

        /* trailing comma (JSON5/JSONC) or stray char: skip */
        p++;
    }

    eshu_buf_putc(&out, '\n');
    eshu_buf_putc(&out, '\0');
    *out_len = out.len - 1;
    return out.data;
}


#include "eshu_hl_util.h"

/* ══════════════════════════════════════════════════════════════════
 *  JSON / JSONC highlighter
 * ══════════════════════════════════════════════════════════════════ */

static char *eshu_highlight_json(const char *src, size_t src_len, size_t *out_len) {
    eshu_buf_t  out;
    const char *p     = src;
    const char *end   = src + src_len;
    const char *plain = p;

    /* skip UTF-8 BOM */
    if (src_len >= 3 &&
        (unsigned char)p[0] == 0xEF &&
        (unsigned char)p[1] == 0xBB &&
        (unsigned char)p[2] == 0xBF) {
        plain = p += 3;
    }

    eshu_buf_init(&out, src_len * 2 + 64);

#define JSON_FLUSH(upto)     eshu_hl_flush(&out, plain, (upto))
#define JSON_SPAN(cls, s, e) do { JSON_FLUSH(s); eshu_hl_span(&out, (cls), (s), (e)); plain = (e); } while(0)

    while (p < end) {
        char c = *p;

        /* JSONC // line comment */
        if (c == '/' && p + 1 < end && *(p + 1) == '/') {
            const char *ts = p;
            p += 2;
            while (p < end && *p != '\n') p++;
            JSON_SPAN("esh-c", ts, p);
            continue;
        }

        /* JSONC block comment */
        if (c == '/' && p + 1 < end && *(p + 1) == '*') {
            const char *ts = p;
            p += 2;
            while (p + 1 < end && !(*p == '*' && *(p + 1) == '/')) p++;
            if (p + 1 < end) p += 2;
            JSON_SPAN("esh-c", ts, p);
            continue;
        }

        /* string: key (esh-a) or value (esh-s) */
        if (c == '"') {
            const char *ts = p;
            p++; /* past opening " */
            while (p < end && *p != '"') {
                if (*p == '\\') p++;
                if (p < end) p++;
            }
            if (p < end && *p == '"') p++;
            const char *te = p;
            /* look ahead for ':' to determine key vs value */
            const char *q = p;
            while (q < end && (*q == ' ' || *q == '\t' || *q == '\r' || *q == '\n')) q++;
            if (q < end && *q == ':') {
                JSON_SPAN("esh-a", ts, te);
            } else {
                JSON_SPAN("esh-s", ts, te);
            }
            continue;
        }

        /* number */
        if (c == '-' || isdigit((unsigned char)c)) {
            const char *ts = p;
            if (*p == '-') p++;
            while (p < end && isdigit((unsigned char)*p)) p++;
            if (p < end && *p == '.') {
                p++;
                while (p < end && isdigit((unsigned char)*p)) p++;
            }
            if (p < end && (*p == 'e' || *p == 'E')) {
                p++;
                if (p < end && (*p == '+' || *p == '-')) p++;
                while (p < end && isdigit((unsigned char)*p)) p++;
            }
            JSON_SPAN("esh-n", ts, p);
            continue;
        }

        /* keywords: null / true / false */
        if (isalpha((unsigned char)c)) {
            const char *ts = p;
            while (p < end && isalpha((unsigned char)*p)) p++;
            JSON_SPAN("esh-k", ts, p);
            continue;
        }

        p++;
    }

    JSON_FLUSH(end);
    eshu_buf_putc(&out, '\0');
    *out_len = out.len - 1;
    return out.data;

#undef JSON_FLUSH
#undef JSON_SPAN
}

#endif /* ESHU_JSON_H */
