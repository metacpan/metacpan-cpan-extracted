/*
 * eshu_xml.h — XML/HTML indentation scanner
 *
 * Tracks tag nesting depth. Self-closing tags and void elements
 * don't affect depth. Preserves content inside <pre>, <script>,
 * <style>, CDATA sections, and comments verbatim.
 */

#ifndef ESHU_XML_H
#define ESHU_XML_H

#include "eshu.h"

/* ══════════════════════════════════════════════════════════════════
 *  Scanner context
 * ══════════════════════════════════════════════════════════════════ */

typedef struct {
	int             depth;
	enum eshu_state state;
	enum eshu_state saved_state; /* state before entering attr string */
	int             in_tag;      /* inside < ... > spanning lines     */
	int             tag_is_close;/* current multi-line tag is </...   */
	int             in_script;   /* collecting <script> content       */
	int             script_depth;/* HTML depth for script base indent */
	eshu_buf_t      script_buf;  /* collected script content          */
	eshu_config_t   cfg;
} eshu_xml_ctx_t;

static void eshu_xml_ctx_init(eshu_xml_ctx_t *ctx, const eshu_config_t *cfg) {
	ctx->depth        = 0;
	ctx->state        = ESHU_CODE;
	ctx->saved_state  = ESHU_CODE;
	ctx->in_tag       = 0;
	ctx->tag_is_close = 0;
	ctx->in_script    = 0;
	ctx->script_depth = 0;
	ctx->script_buf.data = NULL;
	ctx->script_buf.len  = 0;
	ctx->script_buf.cap  = 0;
	ctx->cfg          = *cfg;
}

/* ══════════════════════════════════════════════════════════════════
 *  Case-insensitive prefix match
 * ══════════════════════════════════════════════════════════════════ */

static int eshu_xml_ci_prefix(const char *str, const char *prefix, size_t plen) {
	size_t i;
	for (i = 0; i < plen; i++) {
		if (!str[i]) return 0;
		if (tolower((unsigned char)str[i]) != tolower((unsigned char)prefix[i]))
			return 0;
	}
	return 1;
}

/* ══════════════════════════════════════════════════════════════════
 *  Extract tag name from position after '<' or '</'
 *  Returns length of tag name (0 if none found)
 * ══════════════════════════════════════════════════════════════════ */

static int eshu_xml_tag_name_len(const char *p) {
	int n = 0;
	/* tag names: [a-zA-Z][a-zA-Z0-9:_-]* */
	if (!isalpha((unsigned char)*p)) return 0;
	while (isalnum((unsigned char)p[n]) || p[n] == ':' || p[n] == '_' || p[n] == '-')
		n++;
	return n;
}

/* ══════════════════════════════════════════════════════════════════
 *  HTML void elements (no closing tag needed)
 * ══════════════════════════════════════════════════════════════════ */

static const char *eshu_html_void_elements[] = {
	"area", "base", "br", "col", "embed", "hr", "img", "input",
	"link", "meta", "param", "source", "track", "wbr", NULL
};

static int eshu_xml_is_void(const char *name, int name_len) {
	int i;
	for (i = 0; eshu_html_void_elements[i]; i++) {
		const char *ve = eshu_html_void_elements[i];
		int ve_len = (int)strlen(ve);
		if (ve_len == name_len) {
			int match = 1, j;
			for (j = 0; j < name_len; j++) {
				if (tolower((unsigned char)name[j]) != ve[j]) {
					match = 0;
					break;
				}
			}
			if (match) return 1;
		}
	}
	return 0;
}

/* ══════════════════════════════════════════════════════════════════
 *  HTML verbatim elements (<pre>, <script>, <style>)
 * ══════════════════════════════════════════════════════════════════ */

static const char *eshu_html_verbatim_elements[] = {
	"pre", "script", "style", NULL
};

static int eshu_xml_is_verbatim(const char *name, int name_len) {
	int i;
	for (i = 0; eshu_html_verbatim_elements[i]; i++) {
		const char *ve = eshu_html_verbatim_elements[i];
		int ve_len = (int)strlen(ve);
		if (ve_len == name_len) {
			int match = 1, j;
			for (j = 0; j < name_len; j++) {
				if (tolower((unsigned char)name[j]) != ve[j]) {
					match = 0;
					break;
				}
			}
			if (match) return 1;
		}
	}
	return 0;
}

/* verbatim_tag stores the tag we're waiting to close */
static char eshu_xml_verbatim_tag[32];
static int  eshu_xml_verbatim_tag_len;

/* Check if line contains the closing tag for current verbatim section */
static int eshu_xml_verbatim_end(const char *line, const char *eol) {
	const char *p = line;
	while (p < eol) {
		if (p[0] == '<' && p[1] == '/') {
			p += 2;
			if (eshu_xml_ci_prefix(p, eshu_xml_verbatim_tag,
			                       (size_t)eshu_xml_verbatim_tag_len)) {
				const char *after = p + eshu_xml_verbatim_tag_len;
				while (after < eol && (*after == ' ' || *after == '\t'))
					after++;
				if (after < eol && *after == '>')
					return 1;
			}
		} else {
			p++;
		}
	}
	return 0;
}

/* ══════════════════════════════════════════════════════════════════
 *  Scan a line for tag opens/closes to compute depth changes
 *
 *  Returns pre_adjust (depth change to apply BEFORE indenting)
 *  and sets *post_adjust (depth change to apply AFTER indenting).
 *
 *  Also handles state transitions for comments, CDATA, PI, DOCTYPE,
 *  and attribute strings.
 * ══════════════════════════════════════════════════════════════════ */

static void eshu_xml_scan_line(eshu_xml_ctx_t *ctx,
                               const char *content, const char *eol,
                               int *pre_adj, int *post_adj) {
	const char *p = content;
	int is_html = (ctx->cfg.lang == ESHU_LANG_HTML);
	*pre_adj  = 0;
	*post_adj = 0;

	/* If inside a multi-line tag, continue scanning for > or /> */
	if (ctx->in_tag) {
		while (p < eol) {
			if (ctx->state == ESHU_XML_ATTR_DQ) {
				if (*p == '"') ctx->state = ESHU_XML_TAG;
				p++;
				continue;
			}
			if (ctx->state == ESHU_XML_ATTR_SQ) {
				if (*p == '\'') ctx->state = ESHU_XML_TAG;
				p++;
				continue;
			}
			if (*p == '"') {
				ctx->state = ESHU_XML_ATTR_DQ;
				p++;
				continue;
			}
			if (*p == '\'') {
				ctx->state = ESHU_XML_ATTR_SQ;
				p++;
				continue;
			}
			if (p + 1 < eol && p[0] == '/' && p[1] == '>') {
				/* self-closing end of multi-line tag */
				ctx->in_tag = 0;
				ctx->state = ESHU_CODE;
				p += 2;
				break;
			}
			if (*p == '>') {
				ctx->in_tag = 0;
				ctx->state = ESHU_CODE;
				if (!ctx->tag_is_close) {
					/* opening tag completed — depth++ */
					*post_adj += 1;
				}
				p++;
				break;
			}
			p++;
		}
		if (ctx->in_tag) return; /* still inside tag */
	}

	while (p < eol) {
		/* ── Comment state ── */
		if (ctx->state == ESHU_XML_COMMENT) {
			if (p + 2 < eol && p[0] == '-' && p[1] == '-' && p[2] == '>') {
				ctx->state = ESHU_CODE;
				p += 3;
				continue;
			}
			p++;
			continue;
		}

		/* ── CDATA state ── */
		if (ctx->state == ESHU_XML_CDATA) {
			if (p + 2 < eol && p[0] == ']' && p[1] == ']' && p[2] == '>') {
				ctx->state = ESHU_CODE;
				p += 3;
				continue;
			}
			p++;
			continue;
		}

		/* ── Processing instruction state ── */
		if (ctx->state == ESHU_XML_PI) {
			if (p + 1 < eol && p[0] == '?' && p[1] == '>') {
				ctx->state = ESHU_CODE;
				p += 2;
				continue;
			}
			p++;
			continue;
		}

		/* ── DOCTYPE state ── */
		if (ctx->state == ESHU_XML_DOCTYPE) {
			if (*p == '>') {
				ctx->state = ESHU_CODE;
				p++;
				continue;
			}
			p++;
			continue;
		}

		/* ── Normal CODE state ── */
		if (*p != '<') {
			p++;
			continue;
		}

		/* We have '<' */
		/* Comment: <!-- */
		if (p + 3 < eol && p[1] == '!' && p[2] == '-' && p[3] == '-') {
			ctx->state = ESHU_XML_COMMENT;
			p += 4;
			continue;
		}

		/* CDATA: <![CDATA[ */
		if (p + 8 < eol && eshu_xml_ci_prefix(p, "<![CDATA[", 9)) {
			ctx->state = ESHU_XML_CDATA;
			p += 9;
			continue;
		}

		/* DOCTYPE: <!DOCTYPE */
		if (p + 9 < eol && eshu_xml_ci_prefix(p, "<!DOCTYPE", 9)) {
			ctx->state = ESHU_XML_DOCTYPE;
			p += 9;
			continue;
		}

		/* Processing instruction: <? */
		if (p + 1 < eol && p[1] == '?') {
			ctx->state = ESHU_XML_PI;
			p += 2;
			continue;
		}

		/* Closing tag: </ */
		if (p + 1 < eol && p[1] == '/') {
			p += 2;
			int nlen = eshu_xml_tag_name_len(p);
			if (nlen > 0) {
				p += nlen;
				/* Skip to > */
				while (p < eol && *p != '>') p++;
				if (p < eol) p++; /* skip > */
				/* This closing tag was already depth-- if it was
				   first on the line (pre_adj). Otherwise depth-- now. */
				*post_adj -= 1;
			}
			continue;
		}

		/* Opening tag: <tagname */
		{
			const char *tag_start = p + 1;
			int nlen = eshu_xml_tag_name_len(tag_start);
			if (nlen > 0) {
				/* Check for void element in HTML mode */
				int is_void_el = is_html && eshu_xml_is_void(tag_start, nlen);
				int is_verbatim_el = is_html && eshu_xml_is_verbatim(tag_start, nlen);

				p = tag_start + nlen;

				/* Scan to end of tag (> or />) handling attr strings */
				int self_closing = 0;
				int tag_complete = 0;
				while (p < eol) {
					if (*p == '"') {
						p++;
						while (p < eol && *p != '"') p++;
						if (p < eol) p++;
						continue;
					}
					if (*p == '\'') {
						p++;
						while (p < eol && *p != '\'') p++;
						if (p < eol) p++;
						continue;
					}
					if (p + 1 < eol && p[0] == '/' && p[1] == '>') {
						self_closing = 1;
						tag_complete = 1;
						p += 2;
						break;
					}
					if (*p == '>') {
						tag_complete = 1;
						p++;
						break;
					}
					p++;
				}

				if (!tag_complete) {
					/* Tag spans multiple lines */
					ctx->in_tag = 1;
					ctx->tag_is_close = 0;
					ctx->state = ESHU_XML_TAG;
					/* Don't increment depth yet — wait for > */
					return;
				}

				if (!self_closing && !is_void_el) {
					if (is_verbatim_el) {
						/* Enter verbatim — depth++ for the open tag */
						*post_adj += 1;
						ctx->state = ESHU_XML_VERBATIM;
						/* Store verbatim tag name */
						eshu_xml_verbatim_tag_len = nlen > 31 ? 31 : nlen;
						memcpy(eshu_xml_verbatim_tag, tag_start,
						       (size_t)eshu_xml_verbatim_tag_len);
						eshu_xml_verbatim_tag[eshu_xml_verbatim_tag_len] = '\0';
						/* If HTML <script>, set up JS collection */
						if (is_html && nlen == 6 &&
						    eshu_xml_ci_prefix(tag_start, "script", 6)) {
							ctx->in_script    = 1;
							ctx->script_depth = ctx->depth + *post_adj;
							eshu_buf_init(&ctx->script_buf, 1024);
						} else {
							ctx->in_script = 0;
						}
						return;
					}
					*post_adj += 1;
				}
				continue;
			}
		}

		p++;
	}
}

/* ══════════════════════════════════════════════════════════════════
 *  Determine pre-indent adjustment for closing tags at line start
 * ══════════════════════════════════════════════════════════════════ */

static int eshu_xml_line_pre_adjust(const char *content, const char *eol) {
	if (content < eol && content[0] == '<' && content + 1 < eol && content[1] == '/') {
		return -1;
	}
	return 0;
}

/* Pre-adjust for multi-line tag continuation: '>' or '/>' first */
static int eshu_xml_multiline_tag_closing(eshu_xml_ctx_t *ctx,
                                          const char *content,
                                          const char *eol) {
	(void)eol;
	if (ctx->in_tag) {
		/* continuation lines of multi-line tags indent at depth+1 */
		return 0;
	}
	(void)content;
	return 0;
}

/* ══════════════════════════════════════════════════════════════════
 *  Process a single line
 * ══════════════════════════════════════════════════════════════════ */

static void eshu_xml_process_line(eshu_xml_ctx_t *ctx,
                                  const char *line, const char *eol,
                                  eshu_buf_t *out) {
	const char *content = eshu_skip_leading_ws(line);
	int content_len = (int)(eol - content);
	int is_blank = (content == eol || *content == '\n');

	/* ── Verbatim state: pass through until closing tag ── */
	if (ctx->state == ESHU_XML_VERBATIM) {
		if (eshu_xml_verbatim_end(content, eol)) {
			/* Closing tag of verbatim section */
			if (ctx->in_script && ctx->script_buf.data) {
				/* Run collected script through JS indenter */
				eshu_config_t js_cfg = ctx->cfg;
				js_cfg.lang = ESHU_LANG_JS;
				js_cfg.range_start = 0;
				js_cfg.range_end   = 0;
				{
					size_t js_out_len;
					char *js_result;
					const char *jp;
					const char *je;
					/* NUL-terminate script buffer */
					eshu_buf_putc(&ctx->script_buf, '\0');
					ctx->script_buf.len--;

					js_result = eshu_indent_js(
						ctx->script_buf.data, ctx->script_buf.len,
						&js_cfg, &js_out_len);

					/* Emit each JS output line with base indent */
					jp = js_result;
					je = js_result + js_out_len;
					while (jp < je) {
						const char *jnl = eshu_find_eol(jp);
						const char *jc  = eshu_skip_leading_ws(jp);
						if (jc < jnl) {
							/* Non-empty: base indent + JS line (with JS indent) */
							eshu_emit_indent(out, ctx->script_depth, &ctx->cfg);
							eshu_buf_write_trimmed(out, jp, (int)(jnl - jp));
						}
						eshu_buf_putc(out, '\n');
						jp = (*jnl == '\n') ? jnl + 1 : jnl;
						if (jp > je) jp = je;
					}

					free(js_result);
				}
				eshu_buf_free(&ctx->script_buf);
				ctx->in_script = 0;
			}

			ctx->depth--;
			if (ctx->depth < 0) ctx->depth = 0;
			ctx->state = ESHU_CODE;
			eshu_emit_indent(out, ctx->depth, &ctx->cfg);
			eshu_buf_write_trimmed(out, content, content_len);
			if (*eol == '\n') eshu_buf_putc(out, '\n');
		} else if (ctx->in_script) {
			/* Collect script content for later JS indentation */
			eshu_buf_write(&ctx->script_buf, content, (size_t)content_len);
			eshu_buf_putc(&ctx->script_buf, '\n');
		} else {
			/* Pass through verbatim content unchanged (pre, style) */
			eshu_buf_write_trimmed(out, line, (int)(eol - line));
			if (*eol == '\n') eshu_buf_putc(out, '\n');
		}
		return;
	}

	/* ── Blank line ── */
	if (is_blank) {
		if (*eol == '\n') eshu_buf_putc(out, '\n');
		return;
	}

	/* ── Multi-line comment/CDATA/PI/DOCTYPE: indent and scan for end ── */
	if (ctx->state == ESHU_XML_COMMENT || ctx->state == ESHU_XML_CDATA ||
	    ctx->state == ESHU_XML_PI || ctx->state == ESHU_XML_DOCTYPE) {
		int scan_pre = 0, scan_post = 0;
		eshu_emit_indent(out, ctx->depth, &ctx->cfg);
		eshu_buf_write_trimmed(out, content, content_len);
		if (*eol == '\n') eshu_buf_putc(out, '\n');
		eshu_xml_scan_line(ctx, content, eol, &scan_pre, &scan_post);
		ctx->depth += scan_post;
		if (ctx->depth < 0) ctx->depth = 0;
		return;
	}

	/* ── Multi-line tag continuation ── */
	if (ctx->in_tag) {
		int scan_pre = 0, scan_post = 0;
		eshu_emit_indent(out, ctx->depth + 1, &ctx->cfg);
		eshu_buf_write_trimmed(out, content, content_len);
		if (*eol == '\n') eshu_buf_putc(out, '\n');
		eshu_xml_scan_line(ctx, content, eol, &scan_pre, &scan_post);
		ctx->depth += scan_post;
		if (ctx->depth < 0) ctx->depth = 0;
		return;
	}

	/* ── Normal line ── */
	{
		int line_pre, scan_pre = 0, scan_post = 0;

		/* Check if line starts with closing tag */
		line_pre = eshu_xml_line_pre_adjust(content, eol);

		/* Indent */
		eshu_emit_indent(out, ctx->depth + line_pre, &ctx->cfg);
		eshu_buf_write_trimmed(out, content, content_len);
		if (*eol == '\n') eshu_buf_putc(out, '\n');

		/* Scan line for depth changes */
		eshu_xml_scan_line(ctx, content, eol, &scan_pre, &scan_post);

		/* Cancel double-count: the first closing tag on the line
		 * was already applied via line_pre, but scan_line also
		 * counted it in scan_post. */
		if (line_pre == -1) {
			scan_post += 1;
		}

		ctx->depth += line_pre + scan_post;
		if (ctx->depth < 0) ctx->depth = 0;
	}
}

/* ══════════════════════════════════════════════════════════════════
 *  Public API
 * ══════════════════════════════════════════════════════════════════ */

static char * eshu_indent_xml(const char *src, size_t src_len,
                              const eshu_config_t *cfg, size_t *out_len) {
	eshu_xml_ctx_t ctx;
	eshu_buf_t out;
	const char *p   = src;
	const char *end = src + src_len;
	char *result;

	eshu_xml_ctx_init(&ctx, cfg);
	eshu_buf_init(&out, src_len + 256);

	while (p < end) {
		const char *eol = eshu_find_eol(p);
		eshu_xml_process_line(&ctx, p, eol, &out);
		p = (*eol == '\n') ? eol + 1 : eol;
		if (p > end) p = end;
	}

	/* Clean up script buffer if still allocated (e.g. unclosed <script>) */
	if (ctx.script_buf.data)
		eshu_buf_free(&ctx.script_buf);

	*out_len = out.len;
	result = out.data;
	return result;
}

#endif /* ESHU_XML_H */
