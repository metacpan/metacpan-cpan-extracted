/*
 * eshu_php.h — PHP language indentation scanner
 *
 * Handles brace-based blocks, alternative control syntax (if(): endif;),
 * heredocs/nowdocs, PHP/HTML mixed mode, and switch case labels.
 *
 * Pure C, no Perl dependencies, header-only.
 */

#ifndef ESHU_PHP_H
#define ESHU_PHP_H

#include "eshu.h"

/* ══════════════════════════════════════════════════════════════════
 *  Line classifiers
 * ══════════════════════════════════════════════════════════════════ */

static int eshu_php_is_closing(char c) {
    return c == '}';
}

/* Returns 1 if line is a PHP switch case/default label. */
static int eshu_php_is_case_label(const char *content, int len) {
    const char *p, *end;
    int is_case = 0;

    if (len < 2) return 0;
    if (len >= 5 && strncmp(content, "case ", 5) == 0)
        is_case = 1;
    else if (len >= 7 && strncmp(content, "default", 7) == 0 &&
             (len == 7 || content[7] == ':' || content[7] == ' ' ||
              content[7] == '\t' || content[7] == ';' || content[7] == '/'))
        is_case = 1;

    if (!is_case) return 0;

    p   = content;
    end = content + len;
    while (p < end) {
        if (*p == '/' && p + 1 < end && *(p + 1) == '/') { end = p; break; }
        if (*p == '#') { end = p; break; }
        if (*p == '"') {
            p++;
            while (p < end && *p != '"') { if (*p == '\\') p++; p++; }
        } else if (*p == '\'') {
            p++;
            while (p < end && *p != '\'') { if (*p == '\\') p++; p++; }
        }
        p++;
    }
    while (end > content && (*(end - 1) == ' ' || *(end - 1) == '\t')) end--;
    return end > content && *(end - 1) == ':';
}

/* Returns 1 if line ends an alternative control block: endif; endfor; etc. */
static int eshu_php_is_alt_close(const char *content, int len) {
    if (len < 5) return 0;
    if (strncmp(content, "endif",   5) == 0)  return 1;
    if (len >= 6  && strncmp(content, "endfor",    6)  == 0 &&
        strncmp(content, "endforeach", 10) != 0) return 1;
    if (len >= 10 && strncmp(content, "endforeach", 10) == 0) return 1;
    if (len >= 8  && strncmp(content, "endwhile",  8)  == 0) return 1;
    if (len >= 9  && strncmp(content, "endswitch", 9)  == 0) return 1;
    if (len >= 10 && strncmp(content, "enddeclare",10) == 0) return 1;
    return 0;
}

/* Returns 1 if line is else: or elseif (...): — closes previous alt block
 * and opens another at the same depth. */
static int eshu_php_is_alt_middle(const char *content, int len) {
    const char *end, *p;

    if (len < 4) return 0;
    if (strncmp(content, "else", 4) != 0) return 0;

    /* else: */
    p = content + 4;
    while (*p == ' ' || *p == '\t') p++;
    if (*p == ':') return 1;

    /* elseif (...): */
    if (strncmp(p, "if", 2) == 0) {
        end = content + len;
        p   = content;
        while (p < end) {
            if (*p == '/' && p + 1 < end && *(p + 1) == '/') { end = p; break; }
            if (*p == '#') { end = p; break; }
            p++;
        }
        while (end > content && (*(end - 1) == ' ' || *(end - 1) == '\t')) end--;
        return end > content && *(end - 1) == ':';
    }
    return 0;
}

/* Returns 1 if line is a control-structure line opening an alt block (if():). */
static int eshu_php_is_alt_open(const char *content, int len) {
    const char *end, *p;

    if (len < 3) return 0;

    /* exclude else/elseif — handled by alt_middle */
    if (strncmp(content, "else", 4) == 0) return 0;

    /* control keywords */
    if (strncmp(content, "if",      2) != 0 &&
        strncmp(content, "for",     3) != 0 &&
        strncmp(content, "foreach", 7) != 0 &&
        strncmp(content, "while",   5) != 0 &&
        strncmp(content, "switch",  6) != 0 &&
        strncmp(content, "declare", 7) != 0)
        return 0;

    /* must end with ':' (ignoring comments) */
    end = content + len;
    p   = content;
    while (p < end) {
        if (*p == '/' && p + 1 < end && *(p + 1) == '/') { end = p; break; }
        if (*p == '#') { end = p; break; }
        if (*p == '"') {
            p++;
            while (p < end && *p != '"') { if (*p == '\\') p++; p++; }
        } else if (*p == '\'') {
            p++;
            while (p < end && *p != '\'') { if (*p == '\\') p++; p++; }
        }
        p++;
    }
    while (end > content && (*(end - 1) == ' ' || *(end - 1) == '\t')) end--;
    if (end <= content || *(end - 1) != ':') return 0;

    /* Must NOT be a case label (case X:) */
    if (strncmp(content, "case ", 5) == 0) return 0;

    return 1;
}

/* Parse <<<TAG or <<<'TAG' at p[0..]. Stores tag in buf (max 63 chars).
 * Sets *nowdoc=1 for <<<'TAG'. Returns pointer past the <<<TAG line. */
static const char *eshu_php_heredoc_parse(const char *p, const char *end,
                                          char *buf, int *nowdoc) {
    int nowdoc_q = 0;
    int i = 0;
    *nowdoc = 0;

    /* p points at first char of tag name (or ' for nowdoc) */
    if (p < end && *p == '\'') { nowdoc_q = 1; p++; }
    else if (p < end && *p == '"') { p++; } /* optional double-quote delim */

    while (p < end && *p != '\n' && *p != '\r' && *p != '\'' && *p != '"'
           && (isalnum((unsigned char)*p) || *p == '_')) {
        if (i < 63) buf[i++] = *p;
        p++;
    }
    buf[i] = '\0';

    if (nowdoc_q) { *nowdoc = 1; if (p < end && *p == '\'') p++; }
    else if (p < end && *p == '"') p++;

    /* advance to EOL */
    while (p < end && *p != '\n') p++;

    return p;
}

/* Returns 1 if content (stripped) starts with heredoc_tag and is a valid end. */
static int eshu_php_heredoc_ends(const char *content, int len,
                                 const char *tag) {
    size_t tlen = strlen(tag);
    if ((size_t)len < tlen) return 0;
    if (strncmp(content, tag, tlen) != 0) return 0;
    /* after tag: optional ; or , or end of trimmed content */
    size_t rest = (size_t)len - tlen;
    if (rest == 0) return 1;
    char c = content[tlen];
    return c == ';' || c == ',' || c == ' ' || c == '\t';
}

/* ══════════════════════════════════════════════════════════════════
 *  Scan a line — update ctx state and depth for the next line
 * ══════════════════════════════════════════════════════════════════ */

static void eshu_php_scan_line(eshu_php_ctx_t *ctx,
                               const char *p, const char *end) {
    while (p < end) {
        char c = *p;

        switch (ctx->state) {
        case ESHU_CODE:
            if (!ctx->in_php) {
                /* HTML mode: look for <?php or <?= */
                if (c == '<' && p + 1 < end && *(p + 1) == '?') {
                    p += 2;
                    if (p + 2 < end && *(p) == 'p' && *(p+1) == 'h' && *(p+2) == 'p')
                        { p += 3; ctx->in_php = 1; }
                    else if (p < end && *p == '=')
                        { p++; ctx->in_php = 1; }
                    continue;
                }
                p++;
                continue;
            }
            /* PHP mode */
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
                ctx->state = ESHU_PHP_STRING_DQ;
            } else if (c == '\'') {
                ctx->state = ESHU_PHP_STRING_SQ;
            } else if (c == '/' && p + 1 < end && *(p + 1) == '/') {
                return; /* line comment */
            } else if (c == '#') {
                return; /* line comment */
            } else if (c == '/' && p + 1 < end && *(p + 1) == '*') {
                ctx->state = ESHU_COMMENT_BLOCK;
                p++;
            } else if (c == '<' && p + 2 < end && *(p+1) == '<' && *(p+2) == '<') {
                /* heredoc/nowdoc */
                int nowdoc = 0;
                p = eshu_php_heredoc_parse(p + 3, end,
                                           ctx->heredoc_tag, &nowdoc);
                ctx->state = nowdoc ? ESHU_PHP_NOWDOC : ESHU_PHP_HEREDOC;
                return; /* rest of line is <<<TAG\n */
            } else if (c == '?' && p + 1 < end && *(p + 1) == '>') {
                ctx->in_php = 0;
                p++;
            }
            break;

        case ESHU_PHP_STRING_DQ:
            if (c == '\\' && p + 1 < end) {
                p++; /* skip escaped char */
            } else if (c == '"') {
                ctx->state = ESHU_CODE;
            }
            /* $var inside DQ string: ignore, no depth change */
            break;

        case ESHU_PHP_STRING_SQ:
            if (c == '\\' && p + 1 < end) {
                p++;
            } else if (c == '\'') {
                ctx->state = ESHU_CODE;
            }
            break;

        case ESHU_COMMENT_BLOCK:
            if (c == '*' && p + 1 < end && *(p + 1) == '/') {
                ctx->state = ESHU_CODE;
                p++;
            }
            break;

        case ESHU_PHP_HEREDOC:
        case ESHU_PHP_NOWDOC:
            /* end detection is handled in process_line */
            return;

        default:
            break;
        }
        p++;
    }
}

/* ══════════════════════════════════════════════════════════════════
 *  Process a single line
 * ══════════════════════════════════════════════════════════════════ */

static void eshu_php_process_line(eshu_php_ctx_t *ctx, eshu_buf_t *out,
                                  const char *line_start, const char *eol) {
    const char *content = eshu_skip_leading_ws(line_start);
    int line_len;
    int indent_depth;

    /* empty line */
    if (content >= eol) {
        eshu_buf_putc(out, '\n');
        return;
    }

    line_len = (int)(eol - content);

    /* HTML mode: emit verbatim */
    if (!ctx->in_php && ctx->state == ESHU_CODE) {
        /* Check if this line re-enters PHP mode (<?php / <?=) */
        const char *p = content;
        while (p < eol) {
            if (*p == '<' && p + 1 < eol && *(p + 1) == '?') {
                /* entering PHP mode on this line — but still emit verbatim */
                break;
            }
            p++;
        }
        eshu_buf_write(out, line_start, (size_t)(eol - line_start));
        eshu_buf_putc(out, '\n');
        eshu_php_scan_line(ctx, content, eol);
        return;
    }

    /* Heredoc/nowdoc body */
    if (ctx->state == ESHU_PHP_HEREDOC || ctx->state == ESHU_PHP_NOWDOC) {
        if (*ctx->heredoc_tag && eshu_php_heredoc_ends(content, line_len, ctx->heredoc_tag)) {
            /* end marker: emit at depth 0 (traditional) */
            eshu_buf_write_trimmed(out, content, line_len);
            eshu_buf_putc(out, '\n');
            ctx->state = ESHU_CODE;
        } else {
            /* body: verbatim */
            eshu_buf_write(out, line_start, (size_t)(eol - line_start));
            eshu_buf_putc(out, '\n');
        }
        return;
    }

    /* Block comment continuation */
    if (ctx->state == ESHU_COMMENT_BLOCK) {
        eshu_emit_indent(out, ctx->depth, &ctx->cfg);
        eshu_buf_write_trimmed(out, line_start, (int)(eol - line_start));
        eshu_buf_putc(out, '\n');
        eshu_php_scan_line(ctx, content, eol);
        return;
    }

    /* Normal PHP code */
    indent_depth = ctx->depth;

    /* Clear case_extra if depth dropped below case_depth */
    if (ctx->case_extra && ctx->depth < ctx->case_depth)
        ctx->case_extra = 0;

    int is_close     = eshu_php_is_closing(*content);
    int is_alt_close = eshu_php_is_alt_close(content, line_len);
    int is_alt_mid   = eshu_php_is_alt_middle(content, line_len);
    int is_alt_op    = eshu_php_is_alt_open(content, line_len);

    if (is_close) {
        indent_depth--;
        if (indent_depth < 0) indent_depth = 0;
        if (ctx->case_extra && ctx->depth > ctx->case_depth)
            indent_depth++;
    } else if (is_alt_close || is_alt_mid) {
        indent_depth--;
        if (indent_depth < 0) indent_depth = 0;
    } else if (eshu_php_is_case_label(content, line_len)) {
        ctx->case_depth = ctx->depth;
        ctx->case_extra = 1;
    } else if (ctx->case_extra && ctx->depth >= ctx->case_depth) {
        indent_depth++;
    }

    eshu_emit_indent(out, indent_depth, &ctx->cfg);
    eshu_buf_write_trimmed(out, content, line_len);
    eshu_buf_putc(out, '\n');

    eshu_php_scan_line(ctx, content, eol);

    /* Alt-syntax depth adjustments (no { } involved) */
    if (is_alt_close) {
        ctx->depth--;
        if (ctx->depth < 0) ctx->depth = 0;
        /* also clear case_extra if it was inside the alt block */
        if (ctx->case_extra && ctx->depth <= ctx->case_depth)
            ctx->case_extra = 0;
    } else if (is_alt_op) {
        ctx->depth++;
    }
    /* is_alt_mid: depth already adjusted? No — previous alt block stays open.
     * We just emitted `else:` at depth-1. Depth remains at its current value
     * so the next body lines get the correct indent. */
}

/* ══════════════════════════════════════════════════════════════════
 *  Public API
 * ══════════════════════════════════════════════════════════════════ */

static char *eshu_indent_php(const char *src, size_t src_len,
                             const eshu_config_t *cfg, size_t *out_len) {
    eshu_php_ctx_t  ctx;
    eshu_buf_t      out;
    const char     *p   = src;
    const char     *end = src + src_len;
    char           *result;

    memset(&ctx, 0, sizeof(ctx));
    ctx.state  = ESHU_CODE;
    ctx.in_php = 1; /* default: PHP mode (most PHP files start with <?php) */
    ctx.cfg    = *cfg;

    eshu_buf_init(&out, src_len + 256);

    {
        int line_num = 1;
        while (p < end) {
            const char *eol = eshu_find_eol(p);

            if (eshu_in_range(cfg, line_num)) {
                eshu_php_process_line(&ctx, &out, p, eol);
            } else {
                size_t saved = out.len;
                eshu_php_process_line(&ctx, &out, p, eol);
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
 *  PHP highlighting
 * ══════════════════════════════════════════════════════════════════ */

static const char * const eshu_hl_php_kw[] = {
    "abstract", "array", "as", "break", "callable", "case", "catch",
    "class", "clone", "const", "continue", "declare", "default", "do",
    "echo", "else", "elseif", "empty", "enddeclare", "endfor",
    "endforeach", "endif", "endswitch", "endwhile", "enum", "exit",
    "extends", "final", "finally", "fn", "for", "foreach", "function",
    "global", "goto", "if", "implements", "include", "include_once",
    "instanceof", "insteadof", "interface", "isset", "list", "match",
    "namespace", "new", "null", "print", "private", "protected",
    "public", "readonly", "require", "require_once", "return",
    "static", "switch", "throw", "trait", "try", "unset", "use",
    "var", "while", "yield", "false", "true", "NULL", "FALSE", "TRUE",
    NULL
};

static const char * const eshu_hl_php_bi[] = {
    "array_key_exists", "array_keys", "array_map", "array_merge",
    "array_pop", "array_push", "array_shift", "array_slice",
    "array_splice", "array_unshift", "array_values", "ceil",
    "class_exists", "compact", "count", "date", "defined",
    "explode", "file_exists", "file_get_contents", "file_put_contents",
    "floor", "get_class", "header", "htmlentities", "htmlspecialchars",
    "implode", "in_array", "intval", "is_array", "is_int", "is_null",
    "is_numeric", "is_object", "is_string", "json_decode", "json_encode",
    "max", "mb_strlen", "mb_strtolower", "mb_strtoupper", "mb_substr",
    "method_exists", "microtime", "min", "number_format", "ob_end_clean",
    "ob_start", "ord", "preg_match", "preg_replace", "preg_split",
    "print_r", "rtrim", "session_start", "sort", "sprintf", "str_contains",
    "str_pad", "str_repeat", "str_replace", "strlen", "strpos",
    "strtolower", "strtoupper", "substr", "trim", "ucfirst", "var_dump",
    "Exception", "InvalidArgumentException", "RuntimeException",
    "LogicException", "BadMethodCallException", "OutOfRangeException",
    "ArrayAccess", "Countable", "Iterator", "IteratorAggregate",
    "Serializable", "Stringable", "Throwable",
    "DateTime", "DateTimeImmutable", "DateInterval", "DateTimeInterface",
    "PDO", "PDOStatement", "PDOException",
    NULL
};

static char *eshu_highlight_php(const char *src, size_t src_len, size_t *out_len) {
    eshu_buf_t   out;
    const char  *p   = src;
    const char  *end = src + src_len;
    const char  *plain;
    int          in_php = 1; /* assume PHP mode (may start with <?php) */
    int          in_heredoc = 0;
    char         heredoc_tag[64];
    int          heredoc_len = 0;
    /* block comment state */
    int          in_block_comment = 0;

#define PHP_SPAN(cls, ts, te) do { \
    eshu_hl_flush(&out, plain, (ts)); \
    eshu_hl_span(&out, (cls), (ts), (te)); \
    plain = (te); \
} while (0)

    eshu_buf_init(&out, src_len * 2);
    plain = p;

    /* strip leading <?php or <?= to enter PHP mode */
    if (src_len >= 5 && strncmp(src, "<?php", 5) == 0) {
        /* pass through verbatim */
    } else if (src_len >= 2 && strncmp(src, "<?", 2) == 0) {
        /* pass through */
    }

    while (p < end) {
        unsigned char c = (unsigned char)*p;

        /* heredoc body: verbatim until end marker */
        if (in_heredoc) {
            if (*p == '\n' || p == end - 1) {
                /* check if next line starts with heredoc_tag */
                const char *nl = p + (*p == '\n' ? 1 : 1);
                if (nl < end) {
                    const char *line_end = nl;
                    while (line_end < end && *line_end != '\n') line_end++;
                    /* skip leading whitespace (PHP 7.3+ flexible heredoc) */
                    while (nl < line_end && (*nl == ' ' || *nl == '\t')) nl++;
                    if ((int)(line_end - nl) >= heredoc_len &&
                        strncmp(nl, heredoc_tag, (size_t)heredoc_len) == 0 &&
                        (nl + heredoc_len >= line_end ||
                         nl[heredoc_len] == ';' || nl[heredoc_len] == ',' ||
                         nl[heredoc_len] == ' ' || nl[heredoc_len] == '\t')) {
                        /* flush heredoc body as string span */
                        PHP_SPAN("esh-s", plain, p + 1);
                        in_heredoc = 0;
                    }
                }
            }
            p++;
            continue;
        }

        /* block comment */
        if (in_block_comment) {
            if (c == '*' && p + 1 < end && *(p + 1) == '/') {
                PHP_SPAN("esh-c", plain, p + 2);
                p += 2;
                in_block_comment = 0;
            } else {
                p++;
            }
            continue;
        }

        /* HTML mode: look for <?php / <?= */
        if (!in_php) {
            if (c == '<' && p + 1 < end && *(p + 1) == '?') {
                p += 2;
                if (p + 3 <= end && strncmp(p, "php", 3) == 0) {
                    in_php = 1;
                } else {
                    in_php = 1;
                }
                continue;
            }
            p++;
            continue;
        }

        /* PHP mode */

        /* ?> — exit PHP mode */
        if (c == '?' && p + 1 < end && *(p + 1) == '>') {
            in_php = 0;
            p += 2;
            continue;
        }

        /* line comment // */
        if (c == '/' && p + 1 < end && *(p + 1) == '/') {
            const char *ls = p;
            while (p < end && *p != '\n') p++;
            PHP_SPAN("esh-c", ls, p);
            continue;
        }

        /* line comment # */
        if (c == '#' && !(p + 1 < end && *(p + 1) == '[')) {
            const char *ls = p;
            while (p < end && *p != '\n') p++;
            PHP_SPAN("esh-c", ls, p);
            continue;
        }

        /* block comment */
        if (c == '/' && p + 1 < end && *(p + 1) == '*') {
            const char *cs = p;
            p += 2;
            while (p < end) {
                if (*p == '*' && p + 1 < end && *(p + 1) == '/') {
                    p += 2;
                    break;
                }
                p++;
            }
            PHP_SPAN("esh-c", cs, p);
            continue;
        }

        /* double-quoted string */
        if (c == '"') {
            const char *qs = p;
            p++;
            while (p < end && *p != '"') {
                if (*p == '\\' && p + 1 < end) p++;
                p++;
            }
            if (p < end) p++;
            PHP_SPAN("esh-s", qs, p);
            continue;
        }

        /* single-quoted string */
        if (c == '\'') {
            const char *qs = p;
            p++;
            while (p < end && *p != '\'') {
                if (*p == '\\' && p + 1 < end) p++;
                p++;
            }
            if (p < end) p++;
            PHP_SPAN("esh-s", qs, p);
            continue;
        }

        /* heredoc: <<< */
        if (c == '<' && p + 2 < end && *(p+1) == '<' && *(p+2) == '<') {
            const char *hs = p;
            int q = 0;
            p += 3;
            if (p < end && (*p == '\'' || *p == '"')) { q = *p; p++; }
            heredoc_len = 0;
            while (p < end && *p != '\n' && *p != '\r' &&
                   (isalnum((unsigned char)*p) || *p == '_')) {
                if (heredoc_len < 63) heredoc_tag[heredoc_len++] = *p;
                p++;
            }
            heredoc_tag[heredoc_len] = '\0';
            if (q && p < end && *p == (char)q) p++;
            while (p < end && *p != '\n') p++;
            PHP_SPAN("esh-s", hs, p);
            if (heredoc_len > 0) in_heredoc = 1;
            continue;
        }

        /* number */
        if (isdigit(c) || (c == '.' && p + 1 < end && isdigit((unsigned char)*(p+1)))) {
            const char *ns = p;
            if (c == '0' && p + 1 < end && (*(p+1) == 'x' || *(p+1) == 'X')) {
                p += 2;
                while (p < end && (isxdigit((unsigned char)*p) || *p == '_')) p++;
            } else if (c == '0' && p + 1 < end && (*(p+1) == 'b' || *(p+1) == 'B')) {
                p += 2;
                while (p < end && (*p == '0' || *p == '1' || *p == '_')) p++;
            } else if (c == '0' && p + 1 < end && (*(p+1) == 'o' || *(p+1) == 'O')) {
                p += 2;
                while (p < end && ((*p >= '0' && *p <= '7') || *p == '_')) p++;
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
            PHP_SPAN("esh-n", ns, p);
            continue;
        }

        /* variable $name */
        if (c == '$' && p + 1 < end &&
            (isalpha((unsigned char)*(p+1)) || *(p+1) == '_')) {
            const char *vs = p;
            p++;
            while (p < end && (isalnum((unsigned char)*p) || *p == '_')) p++;
            PHP_SPAN("esh-p", vs, p);
            continue;
        }

        /* attribute #[...] */
        if (c == '#' && p + 1 < end && *(p+1) == '[') {
            const char *as = p;
            int depth = 0;
            p++;
            while (p < end) {
                if (*p == '[') { depth++; p++; }
                else if (*p == ']') { depth--; p++; if (depth <= 0) break; }
                else p++;
            }
            PHP_SPAN("esh-p", as, p);
            continue;
        }

        /* keyword / identifier */
        if (isalpha(c) || c == '_') {
            const char *ts = p;
            while (p < end && (isalnum((unsigned char)*p) || *p == '_')) p++;
            if (eshu_hl_kw(ts, (size_t)(p - ts), eshu_hl_php_kw)) {
                PHP_SPAN("esh-k", ts, p);
            } else if (eshu_hl_kw(ts, (size_t)(p - ts), eshu_hl_php_bi)) {
                PHP_SPAN("esh-b", ts, p);
            }
            plain = p;
            continue;
        }

        p++;
    }

    eshu_hl_flush(&out, plain, end);
    eshu_buf_putc(&out, '\0');
    *out_len = out.len - 1;
    return out.data;

#undef PHP_SPAN
}

#endif /* ESHU_PHP_H */
