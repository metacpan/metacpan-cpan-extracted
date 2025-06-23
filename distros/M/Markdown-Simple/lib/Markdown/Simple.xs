#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

typedef struct {
	int enable_preprocess;
	int enable_headers;
	int enable_bold;
	int enable_italic;
	int enable_links;
	int enable_images;
	int enable_code;
	int enable_tables;
	int enable_tasklist;
	int enable_fenced_code;
	int enable_strikethrough;
	int enable_ordered_lists;
	int enable_unordered_lists;
} MarkdownOptions;

static SV* markdown_to_html(const char* input, MarkdownOptions* opts) {
	SV* out = newSVpv("", 0);
	const char* p = input;

	/* Escape all non-ASCII UTF-8 characters (do not escape HTML) */
	while (*p) {
		unsigned char c = (unsigned char)*p;
		if (c >= 0x80) {
			// Start of a UTF-8 multibyte sequence
			int len = 1;
			if ((c & 0xE0) == 0xC0) len = 2;
			else if ((c & 0xF0) == 0xE0) len = 3;
			else if ((c & 0xF8) == 0xF0) len = 4;
			else { p++; continue; } // Invalid, skip

			UV codepoint = 0;
			if (len == 2 && (p[1] & 0xC0) == 0x80) {
				codepoint = ((p[0] & 0x1F) << 6) | (p[1] & 0x3F);
			} else if (len == 3 && (p[1] & 0xC0) == 0x80 && (p[2] & 0xC0) == 0x80) {
				codepoint = ((p[0] & 0x0F) << 12) | ((p[1] & 0x3F) << 6) | (p[2] & 0x3F);
			} else if (len == 4 && (p[1] & 0xC0) == 0x80 && (p[2] & 0xC0) == 0x80 && (p[3] & 0xC0) == 0x80) {
				codepoint = ((p[0] & 0x07) << 18) | ((p[1] & 0x3F) << 12) | ((p[2] & 0x3F) << 6) | (p[3] & 0x3F);
			} else {
				p++;
				continue;
			}
			sv_catpvf(out, "&#x%X;", (unsigned int)codepoint);
			p += len;
			continue;
		}
		// Do not escape HTML here, just copy ASCII
		sv_catpvf(out, "%c", *p);
		p++;
	}
	input = SvPV_nolen(out);
	p = input; // prevent further processing, as we've already handled all input

	/* Preprocess: replace \r\n with \n in input */
	if (opts->enable_preprocess) {
		SV* pre = newSVpv("", 0);
		const char* q = input;
		while (*q) {
			if (*q == '\r' && *(q+1) == '\n') {
				sv_catpv(pre, "\n");
				q += 2;
			} else {
				sv_catpvf(pre, "%c", *q);
				q++;
			}
		}
		input = SvPV_nolen(pre);
		p = input;
	}
	out = newSVpv("", 0);

	while (*p) {
		// Fenced code block
		if (opts->enable_fenced_code && *p == '`' && *(p+1) == '`' && *(p+2) == '`') {
			p += 3;
			// Optional language specifier
			const char* lang_start = p;
			while (*p && *p != '\n' && *p != ' ') p++;
			int lang_len = (int)(p-lang_start);
			while (*p && *p != '\n') p++;
			//if (*p == '\n') p++;
			const char* code_start = p;
			const char* fence = strstr(p, "```");
			int code_len = fence ? (int)(fence - code_start) : (int)strlen(code_start);
			if (lang_len > 0) {
				sv_catpvf(out, "<pre><code class=\"language-%.*s\">%.*s</code></pre>\n", lang_len, lang_start, code_len, code_start);
			} else {
				sv_catpvf(out, "<pre><code>%.*s</code></pre>\n", code_len, code_start);
			}
			if (fence) p = fence + 3;
			continue;
		}
		// Strikethrough
		if (opts->enable_strikethrough && *p == '~' && *(p+1) == '~') {
			p += 2;
			const char* start = p;
			while (*p && !(*p == '~' && *(p+1) == '~')) p++;
			sv_catpvf(out, "<del>%.*s</del>", (int)(p-start), start);
			if (*p == '~' && *(p+1) == '~') p += 2;
			continue;
		}
		// Headers
		if (opts->enable_headers && *p == '#' && (*(p+1) == ' ' || *(p+1) == '#')) {
			int level = 0;
			while (*p == '#') { level++; p++; }
			if (*p == ' ') p++;
			const char* start = p;
			while (*p && *p != '\n') p++;
			sv_catpvf(out, "<h%d>%.*s</h%d>\n", level, (int)(p-start), start, level);
			if (*p == '\n') p++;
			continue;
		}
		// Task list
		if (opts->enable_tasklist && *p == '-' && *(p+1) == ' ' && *(p+2) == '[' && (*(p+3) == ' ' || *(p+3) == 'x' || *(p+3) == 'X') && *(p+4) == ']') {
			int checked = (*(p+3) == 'x' || *(p+3) == 'X');
			p += 5;
			if (*p == ' ') p++;
			const char* start = p;
			while (*p && *p != '\n') p++;
			sv_catpvf(out, "<li><input type=\"checkbox\"%s disabled /> %.*s</li>\n", checked ? " checked" : "", (int)(p-start), start);
			if (*p == '\n') p++;
			continue;
		}
		// Table (very basic, only supports header row and one or more data rows)
		if (opts->enable_tables && *p == '|' && strchr(p, '\n')) {
			// Check if next line is a separator (|---|---|)
			const char* row_start = p;
			const char* nl = strchr(p, '\n');
			if (!nl) break;
			const char* sep = nl + 1;
			if (*sep == '|') {
				const char* sep_nl = strchr(sep, '\n');
				if (sep_nl && strstr(sep, "---") < sep_nl) {
					// Parse header
					sv_catpvf(out, "<table>\n<tr>");
					const char* cell = row_start + 1;
					while (cell < nl) {
						const char* pipe = strchr(cell, '|');
						if (!pipe || pipe > nl) pipe = nl;
						while (*cell == ' ') cell++;
						const char* cell_end = pipe;
						while (cell_end > cell && (*(cell_end-1) == ' ')) cell_end--;
						// Recursively process header cell content for inline markdown (bold, italic, links, etc.)
						SV* cell_sv = newSVpv("", 0);
						sv_catpvf(cell_sv, "%.*s", (int)(cell_end-cell), cell);
						SV* cell_html = markdown_to_html(SvPV_nolen(cell_sv), opts);
						const char* html_str = SvPV_nolen(cell_html);
						STRLEN html_len = strlen(html_str);
						// Remove wrapping <div>...</div> if present
						if (html_len > 11 && strncmp(html_str, "<div>", 5) == 0 && strncmp(html_str + html_len - 6, "</div>", 6) == 0) {
							SV* trimmed = newSVpv("", 0);
							sv_catpvn(trimmed, html_str + 5, html_len - 11);
							SvREFCNT_dec(cell_html);
							cell_html = trimmed;
						}
						sv_catpvf(out, "<th>%s</th>", SvPV_nolen(cell_html));
						SvREFCNT_dec(cell_sv);
						SvREFCNT_dec(cell_html);
						cell = pipe + 1;
					}
					sv_catpvf(out, "</tr>\n");
					// Parse rows
					const char* row = sep_nl + 1;
					while (*row == '|' && row) {
						const char* row_nl = strchr(row, '\n');
						if (!row_nl) row_nl = row + strlen(row);
						sv_catpvf(out, "<tr>");
						const char* cell = row + 1;
						while (cell < row_nl) {
							const char* pipe = strchr(cell, '|');
							if (!pipe || pipe > row_nl) pipe = row_nl;
							while (*cell == ' ') cell++;
							const char* cell_end = pipe;
							while (cell_end > cell && (*(cell_end-1) == ' ')) cell_end--;
							// Recursively process table cell content for inline markdown (bold, italic, links, etc.)
							SV* cell_sv = newSVpv("", 0);
							sv_catpvf(cell_sv, "%.*s", (int)(cell_end-cell), cell);
							SV* cell_html = markdown_to_html(SvPV_nolen(cell_sv), opts);
							const char* html_str = SvPV_nolen(cell_html);
							STRLEN html_len = strlen(html_str);
							// Remove wrapping <div>...</div> if present
							if (html_len > 11 && strncmp(html_str, "<div>", 5) == 0 && strncmp(html_str + html_len - 6, "</div>", 6) == 0) {
								SV* trimmed = newSVpv("", 0);
								sv_catpvn(trimmed, html_str + 5, html_len - 11);
								SvREFCNT_dec(cell_html);
								cell_html = trimmed;
							}
							sv_catpvf(out, "<td>%s</td>", SvPV_nolen(cell_html));
							SvREFCNT_dec(cell_sv);
							SvREFCNT_dec(cell_html);
							cell = pipe + 1;
						}
						sv_catpvf(out, "</tr>\n");
						if (*row_nl == '\0') break;
						row = row_nl + 1;
					}
					sv_catpvf(out, "</table>\n");
					p = row;
					continue;
				}
			}
		}
		// Bold
		if (opts->enable_bold && (
				(*p == '*' && *(p+1) == '*') ||
				(*p == '_' && *(p+1) == '_')
			)) {
			p += 2;
			const char* start = p;
			while (*p && !(
				((*p == '*' && *(p+1) == '*')) ||
				((*p == '_' && *(p+1) == '_'))
			)) p++;
			sv_catpvf(out, "<strong>%.*s</strong>", (int)(p-start), start);
			if ((*p == '*' && *(p+1) == '*') || (*p == '_' && *(p+1) == '_')) p += 2;
			continue;
		}
		// Italic
		if (opts->enable_italic && ((*p == '*' && *(p+1) != ' ') || (*p == '_' && *(p+1) != ' '))) {
			p++;
			const char* start = p;
			char end_marker = *(p-1); // either '*' or '_'
			while (*p && *p != end_marker) p++;
			sv_catpvf(out, "<em>%.*s</em>", (int)(p-start), start);
			if (*p == end_marker) p++;
			continue;
		}
		// Inline code
		if (opts->enable_code && *p == '`') {
			p++;
			const char* start = p;
			while (*p && *p != '`') p++;
			sv_catpvf(out, "<code>%.*s</code>", (int)(p-start), start);
			if (*p == '`') p++;
			continue;
		}
		// Images
		if (opts->enable_images && *p == '!' && *(p+1) == '[') {
			p += 2;
			const char* alt_start = p;
			while (*p && *p != ']') p++;
			int alt_len = (int)(p-alt_start);
			if (*p == ']') p++;
			if (*p == '(') {
				p++;
				const char* url_start = p;
				while (*p && *p != ')') p++;
				int url_len = (int)(p-url_start);
				sv_catpvf(out, "<img alt=\"%.*s\" src=\"%.*s\" />", alt_len, alt_start, url_len, url_start);
				if (*p == ')') p++;
				continue;
			}
		}
		// Links
		if (opts->enable_links && *p == '[') {
			p++;
			const char* text_start = p;
			while (*p && *p != ']') p++;
			int text_len = (int)(p-text_start);
			if (*p == ']') p++;
			if (*p == '(') {
				p++;
				const char* url_start = p;
				while (*p && *p != ')') p++;
				int url_len = (int)(p-url_start);
				sv_catpvf(out, "<a href=\"%.*s\">%.*s</a>", url_len, url_start, text_len, text_start);
				if (*p == ')') p++;
				continue;
			}
		}
		// Ordered lists
		// Ordered lists (support multiple consecutive lines as one <ol>)
		if (opts->enable_ordered_lists && 
			(p == input || *(p-1) == '\n') && 
			*p >= '1' && *p <= '9' && 
			(*(p+1) == '.' || *(p+1) == ')')) {
			sv_catpvf(out, "<ol>\n");
			while (opts->enable_ordered_lists && *p >= '1' && *p <= '9' && (*(p+1) == '.' || *(p+1) == ')')) {
				p += 2; // Skip number and dot/parenthesis
				if (*p == ' ') p++; // Skip space
				const char* start = p;
				while (*p && *p != '\n') p++;
				// Recursively process the list item content for inline markdown (bold, italic, links, etc.)
				SV* item_sv = newSVpv("", 0);
				sv_catpvf(item_sv, "%.*s", (int)(p-start), start);
				SV* item_html = markdown_to_html(SvPV_nolen(item_sv), opts);
				/* Remove wrapping <div>...</div> if present */
				const char* html_str = SvPV_nolen(item_html);
				STRLEN html_len = strlen(html_str);
				if (html_len > 11 && strncmp(html_str, "<div>", 5) == 0 && strncmp(html_str + html_len - 6, "</div>", 6) == 0) {
					SV* trimmed = newSVpv("", 0);
					sv_catpvn(trimmed, html_str + 5, html_len - 11);
					SvREFCNT_dec(item_html);
					item_html = trimmed;
				}
				sv_catpvf(out, "<li>%s</li>\n", SvPV_nolen(item_html));
				SvREFCNT_dec(item_sv);
				SvREFCNT_dec(item_html);
				if (*p == '\n') p++;
				// Skip blank lines between list items
				const char* lookahead = p;
				while (*lookahead == '\n') lookahead++;
				if (!(*lookahead >= '1' && *lookahead <= '9' && (*(lookahead+1) == '.' || *(lookahead+1) == ')')))
					break;
				p = lookahead;
			}
			sv_catpvf(out, "</ol>\n");
			continue;
		}
		// Unordered lists
		// Unordered lists (support multiple consecutive lines as one <ul>)
		if (opts->enable_unordered_lists && 
			(p == input || *(p-1) == '\n') && 
			(*p == '-' || *p == '*' || *p == '+') && (*(p+1) == ' ')) {
			sv_catpvf(out, "<ul>\n");
			while (opts->enable_unordered_lists && (*p == '-' || *p == '*' || *p == '+') && (*(p+1) == ' ')) {
				p++; // Skip marker
				if (*p == ' ') p++; // Skip space
				const char* start = p;
				while (*p && *p != '\n') p++;
				// Recursively process the list item content for inline markdown (bold, italic, links, etc.)
				SV* item_sv = newSVpv("", 0);
				sv_catpvf(item_sv, "%.*s", (int)(p-start), start);
				SV* item_html = markdown_to_html(SvPV_nolen(item_sv), opts);
				SvREFCNT_dec(item_html);
				item_html = markdown_to_html(SvPV_nolen(item_sv), opts);
				/* Remove wrapping <div>...</div> if present */
				const char* html_str = SvPV_nolen(item_html);
				STRLEN html_len = strlen(html_str);
				if (html_len > 11 && strncmp(html_str, "<div>", 5) == 0 && strncmp(html_str + html_len - 6, "</div>", 6) == 0) {
					SV* trimmed = newSVpv("", 0);
					sv_catpvn(trimmed, html_str + 5, html_len - 11);
					SvREFCNT_dec(item_html);
					item_html = trimmed;
				}
				sv_catpvf(out, "<li>%s</li>\n", SvPV_nolen(item_html));
				SvREFCNT_dec(item_sv);
				SvREFCNT_dec(item_html);
				if (*p == '\n') p++;
				// Skip blank lines between list items
				const char* lookahead = p;
				while (*lookahead == '\n') lookahead++;
				if (!(*lookahead == '-' || *lookahead == '*' || *lookahead == '+'))
					break;
				p = lookahead;
			}
			sv_catpvf(out, "</ul>\n");
			continue;
		}
		// Default: copy character
		sv_catpvf(out, "%c", *p);
		p++;
	}

	/* Split output on double newlines and wrap each part in <div>...</div> */
	STRLEN len;
	char* html = SvPV(out, len);

	/* Unescape all UTF-8 characters (convert &#x...; back to UTF-8), but do not touch HTML entities */
	SV* unescaped = newSVpv("", 0);
	char* scan = html;
	while (*scan) {
		if (scan[0] == '&' && scan[1] == '#' && scan[2] == 'x') {
			char* semi = strchr(scan, ';');
			if (semi && semi - scan < 10) {
				unsigned int codepoint = 0;
				if (sscanf(scan + 3, "%X", &codepoint) == 1) {
					/* Write codepoint as UTF-8 */
					unsigned char utf8buf[4];
					int utf8len = 0;
					if (codepoint <= 0x7F) {
						utf8buf[0] = (unsigned char)codepoint;
						utf8len = 1;
					} else if (codepoint <= 0x7FF) {
						utf8buf[0] = 0xC0 | ((codepoint >> 6) & 0x1F);
						utf8buf[1] = 0x80 | (codepoint & 0x3F);
						utf8len = 2;
					} else if (codepoint <= 0xFFFF) {
						utf8buf[0] = 0xE0 | ((codepoint >> 12) & 0x0F);
						utf8buf[1] = 0x80 | ((codepoint >> 6) & 0x3F);
						utf8buf[2] = 0x80 | (codepoint & 0x3F);
						utf8len = 3;
					} else if (codepoint <= 0x10FFFF) {
						utf8buf[0] = 0xF0 | ((codepoint >> 18) & 0x07);
						utf8buf[1] = 0x80 | ((codepoint >> 12) & 0x3F);
						utf8buf[2] = 0x80 | ((codepoint >> 6) & 0x3F);
						utf8buf[3] = 0x80 | (codepoint & 0x3F);
						utf8len = 4;
					}
					sv_catpvn(unescaped, (char*)utf8buf, utf8len);
					scan = semi + 1;
					continue;
				}
			}
		}
		sv_catpvn(unescaped, scan, 1);
		scan++;
	}
	html = SvPV_nolen(unescaped);

	SV* final = newSVpv("", 0);
	char* start = html;
	char* end;
	while ((end = strstr(start, "\n\n"))) {
		int part_len = (int)(end - start);
		if (part_len > 0) {
			sv_catpvf(final, "<div>%.*s</div>", part_len, start);
		}
		start = end + 2;
	}
	if (*start) {
		sv_catpvf(final, "<div>%s</div>", start);
	}
	/* Remove all newlines from the final output */
	STRLEN final_len;
	char* final_html = SvPV(final, final_len);
	SV* no_newlines = newSVpv("", 0);
	int in_code = 0;
	for (STRLEN i = 0; i < final_len; ) {
		// Detect start of code block
		if (!in_code && i + 5 < final_len && strncmp(final_html + i, "<pre><code", 10) == 0) {
			in_code = 1;
		}
		// Detect end of code block
		if (in_code && i + 13 < final_len && strncmp(final_html + i, "</code></pre>", 13) == 0) {
			in_code = 0;
		}
		STRLEN char_len = 1;
		unsigned char c = (unsigned char)final_html[i];
		if (c >= 0x80) {
			if ((c & 0xE0) == 0xC0) char_len = 2;
			else if ((c & 0xF0) == 0xE0) char_len = 3;
			else if ((c & 0xF8) == 0xF0) char_len = 4;
		}
		if (in_code || (final_html[i] != '\n' && final_html[i] != '\r')) {
			sv_catpvn(no_newlines, final_html + i, char_len);
		}
		i += char_len;
	}
	SvREFCNT_dec(final);
	final = no_newlines;
	SvREFCNT_dec(out);
	out = final;
	return out;
}


static SV* strip_markdown_except_lists_tables(const char* input) {
	SV* out = newSVpv("", 0);
	const char* p = input;

	while (*p) {
		// Ordered lists: keep numbers and text, remove ". " or ") "
		if ((p == input || *(p-1) == '\n') && *p >= '1' && *p <= '9' && (*(p+1) == '.' || *(p+1) == ')')) {
			// Copy number
			sv_catpvn(out, p, 1);
			sv_catpvn(out, " ", 1); // Keep space after number	
			p += 2;
			if (*p == ' ') p++;
			continue;
		}
		// Unordered lists: keep marker, remove space
		if ((p == input || *(p-1) == '\n') && (*p == '-' || *p == '*' || *p == '+') && *(p+1) == ' ') {
			sv_catpvn(out, p, 1);
			sv_catpvn(out, " ", 1); // Keep space after marker
			p += 2;
			continue;
		}
		// Tables: just copy everything (including pipes and dashes)
		if (*p == '|') {
			sv_catpvn(out, p, 1);
			p++;
			continue;
		}
		// Table separator row (---): just copy dashes and pipes
		if (*p == '-' && ((p > input && *(p-1) == '|') || (p == input))) {
			sv_catpvn(out, p, 1);
			p++;
			continue;
		}
		// Remove bold (** or __)
		if ((*p == '*' && *(p+1) == '*') || (*p == '_' && *(p+1) == '_')) {
			p += 2;
			continue;
		}
		// Remove italic (* or _)
		if (*p == '*' || *p == '_') {
			p++;
			continue;
		}
		// Remove strikethrough (~~)
		if (*p == '~' && *(p+1) == '~') {
			p += 2;
			continue;
		}
		// Remove inline code (`) and fenced code (```)
		if (*p == '`') {
			if (*(p+1) == '`' && *(p+2) == '`') {
				p += 3;
				// Skip until closing ```
				const char* fence = strstr(p, "```");
				if (fence) {
					p = fence + 3;
				} else {
					p += strlen(p);
				}
			} else {
				p++;
				// Skip until closing `
				while (*p && *p != '`') p++;
				if (*p == '`') p++;
			}
			continue;
		}
		// Remove images ![alt](url)
		if (*p == '!' && *(p+1) == '[') {
			p += 2;
			while (*p && *p != ']') p++;
			if (*p == ']') p++;
			if (*p == '(') {
				p++;
				while (*p && *p != ')') p++;
				if (*p == ')') p++;
			}
			continue;
		}
		// Remove links [text](url), keep text
		if (*p == '[') {
			p++;
			const char* text_start = p;
			while (*p && *p != ']') p++;
			int text_len = (int)(p - text_start);
			if (text_len > 0)
				sv_catpvn(out, text_start, text_len);
			if (*p == ']') p++;
			if (*p == '(') {
				p++;
				while (*p && *p != ')') p++;
				if (*p == ')') p++;
			}
			continue;
		}
		// Remove headers (#)
		if (*p == '#') {
			while (*p == '#') p++;
			if (*p == ' ') p++;
			continue;
		}
		// Remove task list [ ] or [x]
		if (*p == '[' && (*(p+1) == ' ' || *(p+1) == 'x' || *(p+1) == 'X') && *(p+2) == ']') {
			p += 3;
			if (*p == ' ') p++;
			continue;
		}
		// Default: copy character
		sv_catpvn(out, p, 1);
		p++;
	}
	return out;
}

MODULE = Markdown::Simple    PACKAGE = Markdown::Simple

SV*
strip_markdown(input)
	const char* input
CODE:
	RETVAL = strip_markdown_except_lists_tables(input);
OUTPUT:
	RETVAL

SV*
markdown_to_html(input, ...)
	const char* input
PREINIT:
	MarkdownOptions opts = {1, 1,1,1,1,1,1,1,1,1,1,1,1};
	HV* options;
	SV** val;
CODE:
	if (items > 1 && SvOK(ST(1)) && SvROK(ST(1)) && SvTYPE(SvRV(ST(1))) == SVt_PVHV) {
		options = (HV*)SvRV(ST(1));
		if ((val = hv_fetch(options, "headers", 7, 0)) && SvOK(*val)) opts.enable_headers = SvTRUE(*val);
		if ((val = hv_fetch(options, "bold", 4, 0)) && SvOK(*val)) opts.enable_bold = SvTRUE(*val);
		if (val = hv_fetch(options, "italic", 6, 0)) opts.enable_italic = SvTRUE(*val);
		if (val = hv_fetch(options, "links", 5, 0)) opts.enable_links = SvTRUE(*val);
		if (val = hv_fetch(options, "images", 6, 0)) opts.enable_images = SvTRUE(*val);
		if (val = hv_fetch(options, "code", 4, 0)) opts.enable_code = SvTRUE(*val);
		if (val = hv_fetch(options, "tables", 6, 0)) opts.enable_tables = SvTRUE(*val);
		if (val = hv_fetch(options, "tasklist", 8, 0)) opts.enable_tasklist = SvTRUE(*val);
		if (val = hv_fetch(options, "fenced_code", 11, 0)) opts.enable_fenced_code = SvTRUE(*val);
		if (val = hv_fetch(options, "strikethrough", 13, 0)) opts.enable_strikethrough = SvTRUE(*val);
		if (val = hv_fetch(options, "ordered_lists", 13, 0)) opts.enable_ordered_lists = SvTRUE(*val);
		if (val = hv_fetch(options, "unordered_lists", 15, 0)) opts.enable_unordered_lists = SvTRUE(*val);
		if (val = hv_fetch(options, "preprocess", 10, 0)) opts.enable_preprocess = SvTRUE(*val);
	}
	RETVAL = markdown_to_html(input, &opts);
OUTPUT:
	RETVAL
