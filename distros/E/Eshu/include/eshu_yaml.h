/*
 * eshu_yaml.h — YAML indentation normaliser
 *
 * YAML uses indentation-significant structure. This pass normalises
 * the indent style (tabs→spaces or vice-versa, adjusting indent_width)
 * while preserving logical depth inferred from existing leading whitespace.
 *
 * Depth model: same stack-based approach as Python.  Each new indent
 * level is pushed onto depth_stack; dedents pop until a match is found.
 *
 * Block scalars (| and >): after a line ending in | or >, subsequent
 * deeper-indented lines belong to the scalar body.  The body is
 * re-emitted at (key_depth+1) plus any relative indentation within
 * the block, so that the block remains valid YAML after normalisation.
 *
 * Flow collections ({ } and [ ]): content that spans lines inside a
 * flow collection is emitted verbatim — flow collections carry their
 * own comma-separated syntax and not structural indentation.
 *
 * Directives (%YAML, %TAG) and document markers (--- / ...) are
 * emitted at depth 0; markers also reset the depth stack.
 */

#ifndef ESHU_YAML_H
#define ESHU_YAML_H

#include "eshu.h"
#include <string.h>
#include <ctype.h>

/* ══════════════════════════════════════════════════════════════════
 *  Context
 * ══════════════════════════════════════════════════════════════════ */

typedef struct {
    int             depth;
    int             depth_stack[64];  /* source leading-space count per level */
    int             depth_top;
    int             in_block_scalar;  /* 0=no, 1=literal(|), 2=folded(>) */
    int             scalar_src_base;  /* source leading spaces of first body line */
    int             scalar_norm_depth;/* logical depth for body = key depth + 1  */
    int             flow_depth;       /* unclosed { or [ */
    enum eshu_state state;
    eshu_config_t   cfg;
} eshu_yaml_ctx_t;

static void eshu_yaml_ctx_init(eshu_yaml_ctx_t *ctx, const eshu_config_t *cfg) {
    memset(ctx, 0, sizeof(*ctx));
    ctx->depth_stack[0]  = 0;
    ctx->depth_top       = 1;
    ctx->scalar_src_base = -1;
    ctx->state           = ESHU_CODE;
    ctx->cfg             = *cfg;
}

/* ══════════════════════════════════════════════════════════════════
 *  Measure leading whitespace (spaces; tabs treated as 1 column)
 * ══════════════════════════════════════════════════════════════════ */

static int eshu_yaml_measure_indent(const char *p, const char *eol) {
    int col = 0;
    while (p < eol && (*p == ' ' || *p == '\t')) { col++; p++; }
    return col;
}

/* ══════════════════════════════════════════════════════════════════
 *  Resolve logical depth from leading-space count (depth stack)
 * ══════════════════════════════════════════════════════════════════ */

static int eshu_yaml_resolve_depth(eshu_yaml_ctx_t *ctx, int col) {
    int top;
    if (ctx->depth_top < 64 && col > ctx->depth_stack[ctx->depth_top - 1]) {
        ctx->depth_stack[ctx->depth_top++] = col;
        ctx->depth = ctx->depth_top - 1;
        return ctx->depth;
    }
    top = ctx->depth_top;
    while (top > 1 && col < ctx->depth_stack[top - 1])
        top--;
    ctx->depth_top = top;
    ctx->depth     = top - 1;
    return ctx->depth;
}

/* ══════════════════════════════════════════════════════════════════
 *  Detect block scalar opener at end of line.
 *  Scans backwards, stripping trailing whitespace then
 *  chomp/indent indicators (-/+/1-9), then checks for | or >.
 *  The char before the indicator must be whitespace or ':'.
 *  Returns 1 (literal |), 2 (folded >), or 0.
 * ══════════════════════════════════════════════════════════════════ */

static int eshu_yaml_block_scalar_type(const char *content, const char *eol) {
    const char *p = eol;
    char last;
    while (p > content && (*(p-1) == ' ' || *(p-1) == '\t')) p--;
    while (p > content && (*(p-1) == '-' || *(p-1) == '+' ||
                           (*(p-1) >= '1' && *(p-1) <= '9'))) p--;
    if (p <= content) return 0;
    last = *(p-1);
    if (last != '|' && last != '>') return 0;
    if (p - 1 > content && *(p-2) != ' ' && *(p-2) != '\t' && *(p-2) != ':')
        return 0;
    return (last == '|') ? 1 : 2;
}

/* ══════════════════════════════════════════════════════════════════
 *  Scan a line for { [ ] } and string transitions (updates flow_depth
 *  and ctx->state).  Comments (# after whitespace) stop the scan.
 * ══════════════════════════════════════════════════════════════════ */

static void eshu_yaml_scan_flow(eshu_yaml_ctx_t *ctx,
                                const char *p, const char *end)
{
    char prev = ' ';
    while (p < end) {
        char c = *p;
        if (ctx->state == ESHU_YAML_STRING_DQ) {
            if (c == '\\' && p+1 < end) { p++; }
            else if (c == '"') ctx->state = ESHU_CODE;
            prev = c; p++; continue;
        }
        if (ctx->state == ESHU_YAML_STRING_SQ) {
            if (c == '\'' && p+1 < end && *(p+1) == '\'') { p += 2; prev = '\''; continue; }
            if (c == '\'') ctx->state = ESHU_CODE;
            prev = c; p++; continue;
        }
        /* code */
        if (c == '#' && (prev == ' ' || prev == '\t' || p == end - (int)(end-end)))
            break; /* comment */
        if (c == '"')  { ctx->state = ESHU_YAML_STRING_DQ; prev = c; p++; continue; }
        if (c == '\'') { ctx->state = ESHU_YAML_STRING_SQ; prev = c; p++; continue; }
        if (c == '{' || c == '[') ctx->flow_depth++;
        if (c == '}' || c == ']') { if (ctx->flow_depth > 0) ctx->flow_depth--; }
        prev = c; p++;
    }
}

/* ══════════════════════════════════════════════════════════════════
 *  Process one line
 * ══════════════════════════════════════════════════════════════════ */

static void eshu_yaml_process_line(eshu_yaml_ctx_t *ctx, eshu_buf_t *out,
                                   const char *line_start, const char *eol,
                                   int lineno)
{
    const char *p       = line_start;
    const char *end     = eol;
    const char *content = eshu_skip_leading_ws(p);
    int         src_leading;
    int         depth;
    int         bs_type;

    /* ── Empty line ── */
    if (content >= end) {
        /* blank lines inside a block scalar are part of the body */
        eshu_buf_putc(out, '\n');
        return;
    }

    src_leading = eshu_yaml_measure_indent(line_start, eol);

    /* ── Inside block scalar body ── */
    if (ctx->in_block_scalar) {
        if (ctx->scalar_src_base < 0) {
            /* First non-empty body line: establish base */
            ctx->scalar_src_base = src_leading;
        }
        if (src_leading >= ctx->scalar_src_base) {
            /* Body line: re-emit at (scalar_norm_depth) + relative spaces */
            int relative = src_leading - ctx->scalar_src_base;
            int i;
            if (eshu_in_range(&ctx->cfg, lineno)) {
                eshu_emit_indent(out, ctx->scalar_norm_depth, &ctx->cfg);
                for (i = 0; i < relative; i++) eshu_buf_putc(out, ' ');
                eshu_buf_write_trimmed(out, content, (int)(end - content));
            } else {
                eshu_buf_write(out, line_start, (size_t)(eol - line_start));
            }
            eshu_buf_putc(out, '\n');
            return;
        }
        /* Indentation less than scalar base → scalar ended */
        ctx->in_block_scalar = 0;
        ctx->scalar_src_base = -1;
    }

    /* ── Directive line (%YAML, %TAG) ── */
    if (*content == '%') {
        if (eshu_in_range(&ctx->cfg, lineno)) {
            eshu_buf_write_trimmed(out, content, (int)(end - content));
        } else {
            eshu_buf_write(out, line_start, (size_t)(end - line_start));
        }
        eshu_buf_putc(out, '\n');
        return;
    }

    /* ── Document markers (--- / ...) — reset depth stack ── */
    if ((end - content) >= 3 &&
        ((content[0] == '-' && content[1] == '-' && content[2] == '-') ||
         (content[0] == '.' && content[1] == '.' && content[2] == '.'))) {
        ctx->depth_top       = 1;
        ctx->depth_stack[0]  = 0;
        ctx->depth           = 0;
        ctx->in_block_scalar = 0;
        ctx->scalar_src_base = -1;
        ctx->flow_depth      = 0;
        if (eshu_in_range(&ctx->cfg, lineno)) {
            eshu_buf_write_trimmed(out, content, (int)(end - content));
        } else {
            eshu_buf_write(out, line_start, (size_t)(end - line_start));
        }
        eshu_buf_putc(out, '\n');
        return;
    }

    /* ── Inside flow collection: emit verbatim, update flow depth ── */
    if (ctx->flow_depth > 0) {
        eshu_yaml_scan_flow(ctx, content, end);
        eshu_buf_write(out, line_start, (size_t)(eol - line_start));
        eshu_buf_putc(out, '\n');
        return;
    }

    /* ── Normal structural line: measure depth, re-emit ── */
    depth = eshu_yaml_resolve_depth(ctx, src_leading);

    if (eshu_in_range(&ctx->cfg, lineno)) {
        eshu_emit_indent(out, depth, &ctx->cfg);
        eshu_buf_write_trimmed(out, content, (int)(end - content));
    } else {
        eshu_buf_write(out, line_start, (size_t)(eol - line_start));
    }
    eshu_buf_putc(out, '\n');

    /* Check for block scalar opener on this line */
    bs_type = eshu_yaml_block_scalar_type(content, end);
    if (bs_type) {
        ctx->in_block_scalar   = bs_type;
        ctx->scalar_src_base   = -1;  /* determined by first body line */
        ctx->scalar_norm_depth = depth + 1;
    } else {
        eshu_yaml_scan_flow(ctx, content, end);
    }
}

/* ══════════════════════════════════════════════════════════════════
 *  Public API
 * ══════════════════════════════════════════════════════════════════ */

static char *eshu_indent_yaml(const char *src, size_t src_len,
                              const eshu_config_t *cfg, size_t *out_len)
{
    eshu_yaml_ctx_t ctx;
    eshu_buf_t      out;
    const char     *p   = src;
    const char     *end = src + src_len;
    int             lineno = 1;

    eshu_yaml_ctx_init(&ctx, cfg);
    eshu_buf_init(&out, src_len + 256);

    while (p < end) {
        const char *eol = eshu_find_eol(p);
        eshu_yaml_process_line(&ctx, &out, p, eol, lineno);
        p = eol;
        if (*p == '\n') p++;
        lineno++;
    }

    eshu_buf_putc(&out, '\0');
    out.len--;
    *out_len = out.len;
    return out.data;
}


#include "eshu_hl_util.h"

/* ══════════════════════════════════════════════════════════════════
 *  YAML highlighter
 *
 *  Token classes:
 *   esh-a  mapping key (word before ':')
 *   esh-v  anchor (&name) and alias (*name)
 *   esh-p  tag (!tag, !!type) and directive (%YAML, %TAG)
 *   esh-k  document markers (--- ...), booleans, null, sequence '-'
 *   esh-s  quoted strings ("..." and '...') and bare scalar values
 *   esh-n  numbers
 *   esh-h  block scalar body (lines after | or >)
 *   esh-c  comments (# to EOL)
 * ══════════════════════════════════════════════════════════════════ */

static const char * const eshu_hl_yaml_bool[] = {
    "true", "false", "null", "yes", "no", "on", "off",
    "True", "False", "Null", "Yes", "No", "On", "Off",
    "TRUE", "FALSE", "NULL", "YES", "NO", "ON", "OFF",
    NULL
};

static char *eshu_highlight_yaml(const char *src, size_t src_len, size_t *out_len)
{
    eshu_buf_t  out;
    const char *p     = src;
    const char *end   = src + src_len;
    const char *plain = p;
    int         in_block_scalar = 0; /* 1=literal, 2=folded */
    int         scalar_indent   = -1;
    int         flow_depth      = 0;

    eshu_buf_init(&out, src_len * 2 + 64);

#define YAML_SPAN(cls, ts, te) do { \
    eshu_hl_flush(&out, plain, (ts)); \
    eshu_hl_span(&out, (cls), (ts), (te)); \
    p = (te); plain = p; \
} while(0)

    while (p < end) {
        /* find end of current line */
        const char *ls  = p;
        const char *eol = p;
        while (eol < end && *eol != '\n') eol++;

        /* leading whitespace */
        const char *content = p;
        while (content < eol && (*content == ' ' || *content == '\t')) content++;
        int src_leading = (int)(content - p);

        /* ── Block scalar body ── */
        if (in_block_scalar) {
            if (content >= eol) {
                /* blank line inside block scalar */
                p = eol; if (p < end && *p == '\n') p++;
                eshu_hl_flush(&out, plain, p); plain = p;
                continue;
            }
            if (scalar_indent < 0) scalar_indent = src_leading;
            if (src_leading >= scalar_indent) {
                /* body line */
                YAML_SPAN("esh-h", ls, eol);
                if (p < end && *p == '\n') p++;
                plain = p;
                continue;
            }
            in_block_scalar = 0;
            scalar_indent   = -1;
        }

        /* ── Empty line ── */
        if (content >= eol) {
            p = eol; if (p < end && *p == '\n') p++;
            continue;
        }

        /* advance p past leading ws */
        p = content;

        /* ── Directive: %YAML %TAG ── */
        if (*p == '%') {
            YAML_SPAN("esh-p", p, eol);
            if (p < end && *p == '\n') p++;
            plain = p;
            continue;
        }

        /* ── Document markers: --- / ... ── */
        if ((eol - p) >= 3 &&
            ((p[0]=='-'&&p[1]=='-'&&p[2]=='-') ||
             (p[0]=='.'&&p[1]=='.'&&p[2]=='.'))) {
            const char *te = p + 3;
            YAML_SPAN("esh-k", p, te);
            p = eol; if (p < end && *p == '\n') p++;
            plain = p;
            continue;
        }

        /* ── Sequence indicator: '- ' at start of content ── */
        if (*p == '-' && p+1 < eol && (*(p+1) == ' ' || *(p+1) == '\t')) {
            YAML_SPAN("esh-k", p, p+1);
            p++; /* space after '-' is plain */
        }

        /* ── Scan line content for inline tokens ── */
        /* First, check if this line has a mapping key (word followed by ':') */
        {
            const char *kp = p;
            /* A key is: optional '?' + word chars + ':' + (space or EOL or #) */
            if (*kp == '?') kp++;
            const char *ks = kp;
            while (kp < eol && *kp != ':' && *kp != '\n' && *kp != '#') kp++;
            if (kp < eol && *kp == ':' &&
                (kp+1 >= eol || *(kp+1) == ' ' || *(kp+1) == '\t' ||
                 *(kp+1) == '\n' || *(kp+1) == '#')) {
                /* key found: ks..kp is the key word, kp is ':' */
                if (ks < kp) {
                    /* emit leading '?' if present */
                    if (p < ks) { eshu_hl_flush(&out, plain, p); plain = p; }
                    YAML_SPAN("esh-a", ks, kp);
                    /* ':' emitted as plain */
                    p = kp;
                }
            } else {
                /* not a key line — reset scan */
                kp = p;
            }
        }

        /* scan rest of line char by char */
        while (p < eol) {
            char c = *p;

            /* comment */
            if (c == '#' && (p == ls || *(p-1) == ' ' || *(p-1) == '\t')) {
                YAML_SPAN("esh-c", p, eol);
                break;
            }

            /* anchor &name */
            if (c == '&') {
                const char *ts = p++;
                while (p < eol && (isalnum((unsigned char)*p) || *p=='-' || *p=='_' || *p=='.'))
                    p++;
                YAML_SPAN("esh-v", ts, p);
                continue;
            }

            /* alias *name */
            if (c == '*') {
                const char *ts = p++;
                while (p < eol && (isalnum((unsigned char)*p) || *p=='-' || *p=='_' || *p=='.'))
                    p++;
                YAML_SPAN("esh-v", ts, p);
                continue;
            }

            /* tag !!type or !tag */
            if (c == '!') {
                const char *ts = p++;
                if (p < eol && *p == '!') p++;
                while (p < eol && (isalnum((unsigned char)*p) || *p=='-' || *p=='_'))
                    p++;
                YAML_SPAN("esh-p", ts, p);
                continue;
            }

            /* double-quoted string */
            if (c == '"') {
                const char *ts = p++;
                while (p < eol) {
                    if (*p == '\\' && p+1 < eol) { p += 2; continue; }
                    if (*p == '"') { p++; break; }
                    p++;
                }
                YAML_SPAN("esh-s", ts, p);
                continue;
            }

            /* single-quoted string ('' escapes a single quote) */
            if (c == '\'') {
                const char *ts = p++;
                while (p < eol) {
                    if (*p == '\'' && p+1 < eol && *(p+1) == '\'') { p += 2; continue; }
                    if (*p == '\'') { p++; break; }
                    p++;
                }
                YAML_SPAN("esh-s", ts, p);
                continue;
            }

            /* number (integer, float, hex) */
            if (isdigit((unsigned char)c) ||
                (c == '-' && p+1 < eol && isdigit((unsigned char)*(p+1)))) {
                const char *ts = p;
                if (*p == '-') p++;
                while (p < eol && (isdigit((unsigned char)*p) || *p=='.' ||
                                   *p=='_' || *p=='e' || *p=='E' ||
                                   *p=='+' || *p=='-' || *p=='x' ||
                                   (*p>='a'&&*p<='f') || (*p>='A'&&*p<='F')))
                    p++;
                YAML_SPAN("esh-n", ts, p);
                continue;
            }

            /* flow brackets { [ ] } */
            if (c == '{' || c == '[') { flow_depth++; p++; continue; }
            if (c == '}' || c == ']') { if (flow_depth>0) flow_depth--; p++; continue; }

            /* identifier: check for boolean/null keyword */
            if (isalpha((unsigned char)c) || c == '_') {
                const char *ts = p;
                while (p < eol && (isalnum((unsigned char)*p) || *p=='_')) p++;
                size_t wlen = (size_t)(p - ts);
                int is_bool = 0;
                size_t bi;
                for (bi = 0; eshu_hl_yaml_bool[bi]; bi++) {
                    if (strlen(eshu_hl_yaml_bool[bi]) == wlen &&
                        memcmp(ts, eshu_hl_yaml_bool[bi], wlen) == 0) {
                        is_bool = 1; break;
                    }
                }
                if (is_bool) {
                    YAML_SPAN("esh-k", ts, p);
                } else {
                    /* plain text — flush and write html-escaped */
                    eshu_hl_flush(&out, plain, ts);
                    eshu_hl_write_html(&out, ts, wlen);
                    plain = p;
                }
                continue;
            }

            p++;
        }

        /* detect block scalar opener on this line */
        {
            const char *ep = eol;
            while (ep > content && (*(ep-1) == ' ' || *(ep-1) == '\t')) ep--;
            while (ep > content && (*(ep-1) == '-' || *(ep-1) == '+' ||
                                    (*(ep-1) >= '1' && *(ep-1) <= '9'))) ep--;
            if (ep > content) {
                char last = *(ep-1);
                if ((last == '|' || last == '>') &&
                    (ep-1 == content || *(ep-2) == ' ' || *(ep-2) == '\t' ||
                     *(ep-2) == ':')) {
                    in_block_scalar = (last == '|') ? 1 : 2;
                    scalar_indent   = -1;
                }
            }
        }

        /* advance past EOL */
        if (p < end && *p == '\n') p++;
        plain = p;
    }

    eshu_hl_flush(&out, plain, end);
    eshu_buf_putc(&out, '\0');
    *out_len = out.len - 1;
    return out.data;

#undef YAML_SPAN
}

#endif /* ESHU_YAML_H */
