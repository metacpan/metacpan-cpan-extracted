#ifndef ESHU_HL_UTIL_H
#define ESHU_HL_UTIL_H

#include "eshu.h"

/* ══════════════════════════════════════════════════════════════════
 *  HTML-escaping output helpers
 * ══════════════════════════════════════════════════════════════════ */

static void eshu_hl_putc_html(eshu_buf_t *b, char c) {
    switch (c) {
    case '<':  eshu_buf_write(b, "&lt;",  4); break;
    case '>':  eshu_buf_write(b, "&gt;",  4); break;
    case '&':  eshu_buf_write(b, "&amp;", 5); break;
    case '"':  eshu_buf_write(b, "&quot;",6); break;
    default:   eshu_buf_putc(b, c);           break;
    }
}

static void eshu_hl_write_html(eshu_buf_t *b, const char *s, size_t n) {
    size_t i;
    for (i = 0; i < n; i++)
        eshu_hl_putc_html(b, s[i]);
}

/* Emit a span around [tok_start, tok_end) — content is HTML-escaped */
static void eshu_hl_span(eshu_buf_t *b, const char *cls,
                         const char *tok_start, const char *tok_end) {
    eshu_buf_write(b, "<span class=\"", 13);
    eshu_buf_write(b, cls, strlen(cls));
    eshu_buf_putc(b, '"');
    eshu_buf_putc(b, '>');
    eshu_hl_write_html(b, tok_start, (size_t)(tok_end - tok_start));
    eshu_buf_write(b, "</span>", 7);
}

/* Flush accumulated plain text from [plain, upto) HTML-escaped */
static void eshu_hl_flush(eshu_buf_t *b, const char *plain, const char *upto) {
    if (upto > plain)
        eshu_hl_write_html(b, plain, (size_t)(upto - plain));
}

/* ══════════════════════════════════════════════════════════════════
 *  Keyword lookup  (NULL-terminated sorted word list)
 * ══════════════════════════════════════════════════════════════════ */

static int eshu_hl_kw(const char *s, size_t n, const char * const *list) {
    size_t i;
    for (i = 0; list[i]; i++) {
        size_t klen = strlen(list[i]);
        if (klen == n && memcmp(list[i], s, n) == 0)
            return 1;
    }
    return 0;
}

/* ══════════════════════════════════════════════════════════════════
 *  Generic character helpers
 * ══════════════════════════════════════════════════════════════════ */

static int eshu_hl_isalnum_(char c) {
    return isalnum((unsigned char)c) || c == '_';
}
static int eshu_hl_isalpha_(char c) {
    return isalpha((unsigned char)c) || c == '_';
}


#endif /* ESHU_HL_UTIL_H */
