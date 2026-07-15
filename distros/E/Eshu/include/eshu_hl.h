#ifndef ESHU_HL_H
#define ESHU_HL_H

#include "eshu_hl_util.h"
#include "eshu_c.h"
#include "eshu_pod.h"
#include "eshu_pl.h"
#include "eshu_xs.h"
#include "eshu_js.h"
#include "eshu_xml.h"
#include "eshu_css.h"
#include "eshu_diff.h"
#include "eshu_bash.h"
#include "eshu_go.h"
#include "eshu_py.h"
#include "eshu_json.h"
#include "eshu_java.h"
#include "eshu_lua.h"
#include "eshu_rust.h"
#include "eshu_php.h"
#include "eshu_ruby.h"
#include "eshu_ts.h"
#include "eshu_sql.h"
#include "eshu_yaml.h"

/* ══════════════════════════════════════════════════════════════════
 *  Dispatch: eshu_highlight(src, src_len, lang, out_len)
 * ══════════════════════════════════════════════════════════════════ */

static char *eshu_highlight(const char *src, size_t src_len,
                            const char *lang, size_t *out_len) {
    if (!src || !src_len) {
        char *empty = (char *)malloc(1);
        if (empty) empty[0] = '\0';
        *out_len = 0;
        return empty;
    }

    if (!lang || strcmp(lang, "c") == 0 || strcmp(lang, "h") == 0)
        return eshu_highlight_c(src, src_len, out_len);

    if (strcmp(lang, "xs") == 0)
        return eshu_highlight_c(src, src_len, out_len); /* XS is C-like */

    if (strcmp(lang, "perl") == 0 || strcmp(lang, "pl") == 0 ||
        strcmp(lang, "pm") == 0  || strcmp(lang, "t") == 0)
        return eshu_highlight_pl(src, src_len, out_len);

    if (strcmp(lang, "js") == 0 || strcmp(lang, "javascript") == 0 ||
        strcmp(lang, "jsx") == 0 || strcmp(lang, "mjs") == 0 ||
        strcmp(lang, "cjs") == 0)
        return eshu_highlight_js(src, src_len, out_len);

    if (strcmp(lang, "ts") == 0 || strcmp(lang, "typescript") == 0 ||
        strcmp(lang, "tsx") == 0 || strcmp(lang, "mts") == 0)
        return eshu_highlight_ts(src, src_len, out_len);

    if (strcmp(lang, "css") == 0 || strcmp(lang, "scss") == 0 ||
        strcmp(lang, "less") == 0)
        return eshu_highlight_css(src, src_len, out_len);

    if (strcmp(lang, "xml") == 0 || strcmp(lang, "html") == 0 ||
        strcmp(lang, "htm") == 0  || strcmp(lang, "svg") == 0 ||
        strcmp(lang, "xhtml") == 0)
        return eshu_highlight_xml(src, src_len, out_len);

    if (strcmp(lang, "pod") == 0)
        return eshu_highlight_pod(src, src_len, out_len);

    if (strcmp(lang, "python") == 0 || strcmp(lang, "py") == 0)
        return eshu_highlight_py(src, src_len, out_len);

    if (strcmp(lang, "json") == 0 || strcmp(lang, "jsonc") == 0)
        return eshu_highlight_json(src, src_len, out_len);

    if (strcmp(lang, "bash") == 0 || strcmp(lang, "sh") == 0 ||
        strcmp(lang, "shell") == 0 || strcmp(lang, "zsh") == 0 ||
        strcmp(lang, "ksh") == 0)
        return eshu_highlight_bash(src, src_len, out_len);

    if (strcmp(lang, "go") == 0)
        return eshu_highlight_go(src, src_len, out_len);

    if (strcmp(lang, "rust") == 0 || strcmp(lang, "rs") == 0)
        return eshu_highlight_rust(src, src_len, out_len);

    if (strcmp(lang, "java") == 0)
        return eshu_highlight_java(src, src_len, out_len);

    if (strcmp(lang, "lua") == 0)
        return eshu_highlight_lua(src, src_len, out_len);

    if (strcmp(lang, "php") == 0 || strcmp(lang, "phtml") == 0 ||
        strcmp(lang, "php3") == 0 || strcmp(lang, "php4") == 0 ||
        strcmp(lang, "php5") == 0)
        return eshu_highlight_php(src, src_len, out_len);

    if (strcmp(lang, "ruby") == 0 || strcmp(lang, "rb") == 0 ||
        strcmp(lang, "rake") == 0)
        return eshu_highlight_ruby(src, src_len, out_len);

    if (strcmp(lang, "sql") == 0 || strcmp(lang, "psql") == 0 ||
        strcmp(lang, "ddl") == 0)
        return eshu_highlight_sql(src, src_len, out_len);

    if (strcmp(lang, "yaml") == 0 || strcmp(lang, "yml") == 0)
        return eshu_highlight_yaml(src, src_len, out_len);

    /* unknown language: HTML-escape only, no spans */
    {
        eshu_buf_t out;
        eshu_buf_init(&out, src_len + 16);
        eshu_hl_write_html(&out, src, src_len);
        eshu_buf_putc(&out, '\0');
        *out_len = out.len - 1;
        return out.data;
    }
}

#endif /* ESHU_HL_H */
