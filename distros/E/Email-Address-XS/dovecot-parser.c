/*
 * Copyright (c) 2002-2018 Dovecot authors
 * Copyright (c) 2015-2018 Pali <pali@cpan.org>
 *
 * Permission is hereby granted, free of charge, to any person obtaining a
 * copy of this software and associated documentation files (the "Software"),
 * to deal in the Software without restriction, including without limitation
 * the rights to use, copy, modify, merge, publish, distribute, sublicense,
 * and/or sell copies of the Software, and to permit persons to whom the
 * Software is furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 * FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
 * DEALINGS IN THE SOFTWARE.
 */

#include <errno.h>
#include <stdbool.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>

#include "dovecot-parser.h"

#ifndef SIZE_MAX
#define SIZE_MAX ((size_t)-1)
#endif

void i_panic(const char *format, ...);

#ifdef DEBUG
#define i_assert(expr) \
	do { if (!(expr)) \
	i_panic("file %s: line %d (%s): assertion failed: (%s)",	\
		__FILE__,						\
		__LINE__,						\
		__FUNCTION__,						\
		#expr);							\
	} while ( 0 )
#else
#define i_assert(expr)
#endif

typedef struct {
	char *buf;
	size_t len;
	size_t size;
} string_t;

struct rfc822_parser_context {
	const unsigned char *data, *end;
	string_t *last_comment;

	/* Replace NUL characters with this string */
	const char *nul_replacement_str;
};

struct message_address_parser_context {
	struct rfc822_parser_context parser;

	struct message_address *first_addr, *last_addr, addr;
	string_t *str;

	bool fill_missing, non_strict_dots, non_strict_dots_as_invalid;
};

static string_t *str_new(size_t initial_size)
{
	char *buf;
	string_t *str;

	if (!initial_size)
		initial_size = 1;

	if (initial_size >= SIZE_MAX / 2)
		i_panic("str_new() failed: %s", "initial_size is too big");

	buf = malloc(initial_size);
	if (!buf)
		i_panic("malloc() failed: %s", strerror(errno));

	str = malloc(sizeof(string_t));
	if (!str)
		i_panic("malloc() failed: %s", strerror(errno));

	buf[0] = 0;

	str->buf = buf;
	str->len = 0;
	str->size = initial_size;

	return str;
}

static void str_free(string_t **str)
{
	free((*str)->buf);
	free(*str);
	*str = NULL;
}

static const char *str_c(string_t *str)
{
	return str->buf;
}

static char *str_ccopy(string_t *str)
{
	char *copy;

	copy = malloc(str->len+1);
	if (!copy)
		i_panic("malloc() failed: %s", strerror(errno));

	memcpy(copy, str->buf, str->len);
	copy[str->len] = 0;
	return copy;
}

static size_t str_len(const string_t *str)
{
	return str->len;
}

static void str_append_data(string_t *str, const void *data, size_t len)
{
	char *new_buf;
	size_t need_size;

	need_size = str->len + len + 1;

	if (len >= SIZE_MAX / 2 || need_size >= SIZE_MAX / 2)
		i_panic("%s() failed: %s", __FUNCTION__, "len is too big");

	if (need_size > str->size) {
		str->size = 1;
		while (str->size < need_size)
			str->size <<= 1;

		new_buf = realloc(str->buf, str->size);
		if (!new_buf)
			i_panic("realloc() failed: %s", strerror(errno));

		str->buf = new_buf;
	}

	memcpy(str->buf + str->len, data, len);
	str->len += len;
	str->buf[str->len] = 0;
}

static void str_append(string_t *str, const char *cstr)
{
	str_append_data(str, cstr, strlen(cstr));
}

static void str_append_c(string_t *str, unsigned char chr)
{
	str_append_data(str, &chr, 1);
}

static void str_truncate(string_t *str, size_t len)
{
	if (str->size - 1 <= len || str->len <= len)
		return;

	str->len = len;
	str->buf[len] = 0;
}

/*
   atext        =       ALPHA / DIGIT / ; Any character except controls,
                        "!" / "#" /     ;  SP, and specials.
                        "$" / "%" /     ;  Used for atoms
                        "&" / "'" /
                        "*" / "+" /
                        "-" / "/" /
                        "=" / "?" /
                        "^" / "_" /
                        "`" / "{" /
                        "|" / "}" /
                        "~"

  MIME:

  token := 1*<any (US-ASCII) CHAR except SPACE, CTLs,
              or tspecials>
  tspecials :=  "(" / ")" / "<" / ">" / "@" /
                "," / ";" / ":" / "\" / <">
                "/" / "[" / "]" / "?" / "="

  So token is same as dot-atom, except stops also at '/', '?' and '='.
*/

/* atext chars are marked with 1, alpha and digits with 2,
   atext-but-mime-tspecials with 4 */
unsigned char rfc822_atext_chars[256] = {
	0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, /* 0-15 */
	0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, /* 16-31 */
	0, 1, 0, 1, 1, 1, 1, 1, 0, 0, 1, 1, 0, 1, 0, 4, /* 32-47 */
	2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 0, 0, 0, 4, 0, 4, /* 48-63 */
	0, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, /* 64-79 */
	2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 0, 0, 0, 1, 1, /* 80-95 */
	1, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, /* 96-111 */
	2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 1, 1, 1, 1, 0, /* 112-127 */

	2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2,
	2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2,
	2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2,
	2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2,
	2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2,
	2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2,
	2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2,
	2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2
};

#define IS_ATEXT(c) \
	(rfc822_atext_chars[(int)(unsigned char)(c)] != 0)
#define IS_ATEXT_NON_TSPECIAL(c) \
	((rfc822_atext_chars[(int)(unsigned char)(c)] & 3) != 0)

/*
   qtext           =   %d33 /             ; Printable US-ASCII
                       %d35-91 /          ;  characters not including
                       %d93-126 /         ;  "\" or the quote character
                       obs-qtext

   obs-qtext       =   obs-NO-WS-CTL

   obs-NO-WS-CTL   =   %d1-8 /            ; US-ASCII control
                       %d11 /             ;  characters that do not
                       %d12 /             ;  include the carriage
                       %d14-31 /          ;  return, line feed, and
                       %d127              ;  white space characters

  So qtext is everything expects '\0', '\t', '\n', '\r', ' ', '"', '\\'.
*/

/* non-qtext characters */
#define CHAR_NEEDS_ESCAPE(c) ((c) == '"' || (c) == '\\' || (c) == '\0' || (c) == '\t' || (c) == '\n' || (c) == '\r')

/* quote with "" and escape all needed characters */
static void str_append_maybe_escape(string_t *str, const char *data, size_t len, bool quote_dot)
{
	const char *p;
	const char *end;

	if (len == 0) {
		str_append(str, "\"\"");
		return;
	}

	/* leading or trailing dot needs to be always quoted */
	if (data[0] == '.' || data[len-1] == '.')
		quote_dot = true;

	end = data + len;

	/* see if we need to quote it */
	for (p = data; p != end; p++) {
		if (!IS_ATEXT(*p) && (quote_dot || *p != '.'))
			break;
	}

	if (p == end) {
		str_append_data(str, data, len);
		return;
	}

	/* see if we need to escape it */
	for (p = data; p != end; p++) {
		if (CHAR_NEEDS_ESCAPE(*p))
			break;
	}

	if (p == end) {
		/* only quote */
		str_append_c(str, '"');
		str_append_data(str, data, len);
		str_append_c(str, '"');
		return;
	}

	/* quote and escape */
	str_append_c(str, '"');
	str_append_data(str, data, (size_t) (p - data));

	for (; p != end; p++) {
		if (CHAR_NEEDS_ESCAPE(*p))
			str_append_c(str, '\\');
		str_append_c(str, *p);
	}

	str_append_c(str, '"');
}

/* Parse given data using RFC 822 token parser. */
static void rfc822_parser_init(struct rfc822_parser_context *ctx,
			const unsigned char *data, size_t size,
			string_t *last_comment)
{
	memset(ctx, 0, sizeof(*ctx));
	ctx->data = data;
	ctx->end = data + size;
	ctx->last_comment = last_comment;
}

static void rfc822_parser_deinit(struct rfc822_parser_context *ctx)
{
	/* make sure the parsing didn't trigger a bug that caused reading
	   past the end pointer. */
	i_assert(ctx->data <= ctx->end);
	/* make sure the parser is no longer accessed */
	ctx->data = ctx->end = NULL;
}

/* The functions below return 1 = more data available, 0 = no more data
   available (but a value might have been returned now), -1 = invalid input.

   LWSP is automatically skipped after value, but not before it. So typically
   you begin with skipping LWSP and then start using the parse functions. */

/* Parse comment. Assumes parser's data points to '(' */
static int rfc822_skip_comment(struct rfc822_parser_context *ctx)
{
	const unsigned char *start;
	size_t len;
	int level = 1;

	i_assert(*ctx->data == '(');

	if (ctx->last_comment != NULL)
		str_truncate(ctx->last_comment, 0);

	start = ++ctx->data;
	for (; ctx->data < ctx->end; ctx->data++) {
		switch (*ctx->data) {
		case '\0':
			if (ctx->nul_replacement_str != NULL) {
				if (ctx->last_comment != NULL) {
					str_append_data(ctx->last_comment, start,
							ctx->data - start);
					str_append(ctx->last_comment,
						   ctx->nul_replacement_str);
					start = ctx->data + 1;
				}
			} else {
				return -1;
			}
			break;
		case '(':
			level++;
			break;
		case ')':
			if (--level == 0) {
				if (ctx->last_comment != NULL) {
					str_append_data(ctx->last_comment, start,
							ctx->data - start);
				}
				ctx->data++;
				return ctx->data < ctx->end ? 1 : 0;
			}
			break;
		case '\n':
			/* folding whitespace, remove the (CR)LF */
			if (ctx->last_comment == NULL)
				break;
			len = ctx->data - start;
			if (len > 0 && start[len-1] == '\r')
				len--;
			str_append_data(ctx->last_comment, start, len);
			start = ctx->data + 1;
			break;
		case '\\':
			ctx->data++;
			if (ctx->data >= ctx->end)
				return -1;
#if 0
			if (*ctx->data == '\r' || *ctx->data == '\n' ||
			    *ctx->data == '\0') {
				/* quoted-pair doesn't allow CR/LF/NUL.
				   They are part of the obs-qp though, so don't
				   return them as error. */
				ctx->data--;
				break;
			}
#endif
			if (ctx->last_comment != NULL) {
				str_append_data(ctx->last_comment, start,
						ctx->data - start - 1);
			}
			start = ctx->data;
			break;
		}
	}

	/* missing ')' */
	return -1;
}

/* Skip LWSP if there is any */
static int rfc822_skip_lwsp(struct rfc822_parser_context *ctx)
{
	for (; ctx->data < ctx->end;) {
		if (*ctx->data == ' ' || *ctx->data == '\t' ||
		    *ctx->data == '\r' || *ctx->data == '\n') {
                        ctx->data++;
			continue;
		}

		if (*ctx->data != '(')
			break;

		if (rfc822_skip_comment(ctx) < 0)
			return -1;
	}
	return ctx->data < ctx->end ? 1 : 0;
}

/* Stop at next non-atext char */
int rfc822_parse_atom(struct rfc822_parser_context *ctx, string_t *str)
{
	const unsigned char *start;

	/*
	   atom            = [CFWS] 1*atext [CFWS]
	   atext           =
	     ; Any character except controls, SP, and specials.
	*/
	if (ctx->data >= ctx->end || !IS_ATEXT(*ctx->data))
		return -1;

	for (start = ctx->data++; ctx->data < ctx->end; ctx->data++) {
		if (IS_ATEXT(*ctx->data))
			continue;

		str_append_data(str, start, ctx->data - start);
		return rfc822_skip_lwsp(ctx);
	}

	str_append_data(str, start, ctx->data - start);
	return 0;
}

/* Like parse_atom() but don't stop at '.' */
static int rfc822_parse_dot_atom(struct rfc822_parser_context *ctx, string_t *str, bool stop_trailing_dot)
{
	const unsigned char *start;
	const unsigned char *last_dot_ptr;
	bool last_is_dot;
	bool dot_problem;
	int ret;

	/*
	   dot-atom        = [CFWS] dot-atom-text [CFWS]
	   dot-atom-text   = 1*atext *("." 1*atext)

	   atext           =
	     ; Any character except controls, SP, and specials.

	   For RFC-822 compatibility allow LWSP around '.'
	*/
	if (ctx->data >= ctx->end || !IS_ATEXT(*ctx->data))
		return -1;

	last_dot_ptr = ctx->data;
	last_is_dot = false;
	dot_problem = false;

	for (start = ctx->data++; ctx->data < ctx->end; ) {
		if (IS_ATEXT(*ctx->data)) {
			ctx->data++;
			continue;
		}

#if 0
		if (start == ctx->data)
			dot_problem = true;
#endif
		str_append_data(str, start, ctx->data - start);

		if (ctx->data - start > 0)
			last_is_dot = false;

		if ((ret = rfc822_skip_lwsp(ctx)) <= 0)
			return (dot_problem && ret >= 0) ? -2 : ret;

		if (*ctx->data != '.') {
			if (last_is_dot && stop_trailing_dot) {
				ctx->data = last_dot_ptr;
				return dot_problem ? -2 : 1;
			}
			return (last_is_dot || dot_problem) ? -2 : 1;
		}

		if (last_is_dot)
			dot_problem = true;

		last_dot_ptr = ctx->data;
		ctx->data++;
		str_append_c(str, '.');
		last_is_dot = true;

		if (rfc822_skip_lwsp(ctx) <= 0)
			return (dot_problem && ret >= 0) ? -2 : ret;
		start = ctx->data;
	}

#if 0
	i_assert(start != ctx->data);
#endif
	str_append_data(str, start, ctx->data - start);
	return dot_problem ? -2 : 0;
}

/* "quoted string" */
static int rfc822_parse_quoted_string(struct rfc822_parser_context *ctx, string_t *str)
{
	const unsigned char *start;
	bool char_problem;
	int ret;
	size_t len;

	i_assert(ctx->data < ctx->end);
	i_assert(*ctx->data == '"');
	ctx->data++;
	char_problem = false;

	for (start = ctx->data; ctx->data < ctx->end; ctx->data++) {
		switch (*ctx->data) {
		case '\0':
			if (ctx->nul_replacement_str != NULL) {
				str_append_data(str, start, ctx->data - start);
				str_append(str, ctx->nul_replacement_str);
				start = ctx->data + 1;
			} else {
				char_problem = true;
			}
			break;
		case '"':
			str_append_data(str, start, ctx->data - start);
			ctx->data++;
			ret = rfc822_skip_lwsp(ctx);
			return (char_problem && ret >= 0) ? -2 : ret;
		case '\r':
			if (ctx->data+1 < ctx->end && *(ctx->data+1) != '\n')
				char_problem = true;
			break;
		case '\n':
#if 0
			/* folding whitespace, remove the (CR)LF */
			len = ctx->data - start;
			if (len > 0 && start[len-1] == '\r')
				len--;
			str_append_data(str, start, len);
			start = ctx->data + 1;
#endif
			len = ctx->data - start;
			if (len <= 0 || start[len-1] != '\r')
				char_problem = true;
			break;
		case '\\':
			ctx->data++;
			if (ctx->data >= ctx->end)
				return -1;
#if 0
			if (*ctx->data == '\r' || *ctx->data == '\n' ||
			    *ctx->data == '\0') {
				/* quoted-pair doesn't allow CR/LF/NUL.
				   They are part of the obs-qp though, so don't
				   return them as error. */
				ctx->data--;
				break;
			}
#endif
			str_append_data(str, start, ctx->data - start - 1);
			str_append_c(str, *ctx->data);
			start = ctx->data+1;
			break;
		}
	}

	/* missing '"' */
	return -1;
}

static int
rfc822_parse_atom_or_dot(struct rfc822_parser_context *ctx, string_t *str)
{
	const unsigned char *start;

	/*
	   atom            = [CFWS] 1*atext [CFWS]
	   atext           =
	     ; Any character except controls, SP, and specials.

	   The difference between this function and rfc822_parse_dot_atom()
	   is that this doesn't just silently skip over all the whitespace.
	*/
	for (start = ctx->data; ctx->data < ctx->end; ctx->data++) {
		if (IS_ATEXT(*ctx->data) || *ctx->data == '.')
			continue;

		str_append_data(str, start, ctx->data - start);
		return rfc822_skip_lwsp(ctx);
	}

	str_append_data(str, start, ctx->data - start);
	return 0;
}

/* atom or quoted-string */
static int rfc822_parse_phrase(struct rfc822_parser_context *ctx, string_t *str)
{
	int ret;
	bool char_problem;

	char_problem = false;

	/*
	   phrase     = 1*word / obs-phrase
	   word       = atom / quoted-string
	   obs-phrase = word *(word / "." / CFWS)
	*/

	if (ctx->data >= ctx->end)
		return 0;
	if (*ctx->data == '.')
		return -1;

	for (;;) {
		if (*ctx->data == '"')
			ret = rfc822_parse_quoted_string(ctx, str);
		else
			ret = rfc822_parse_atom_or_dot(ctx, str);

		if (ret <= 0 && ret != -2)
			return (char_problem && ret == 0) ? -2 : ret;

		if (ret == -2) {
			char_problem = true;
			if (ctx->data >= ctx->end)
				return -2;
		}

		if (!IS_ATEXT(*ctx->data) && *ctx->data != '"'
		    && *ctx->data != '.')
			break;
		str_append_c(str, ' ');
	}
	ret = rfc822_skip_lwsp(ctx);
	return (char_problem && ret >= 0) ? -2 : ret;
}

static int
rfc822_parse_domain_literal(struct rfc822_parser_context *ctx, string_t *str)
{
	const unsigned char *start;
	size_t len;

	/*
	   domain-literal  = [CFWS] "[" *([FWS] dcontent) [FWS] "]" [CFWS]
	   dcontent        = dtext / quoted-pair
	   dtext           = NO-WS-CTL /     ; Non white space controls
			     %d33-90 /       ; The rest of the US-ASCII
			     %d94-126        ;  characters not including "[",
					     ;  "]", or "\"
	*/
	i_assert(ctx->data < ctx->end);
	i_assert(*ctx->data == '[');

	for (start = ctx->data++; ctx->data < ctx->end; ctx->data++) {
		switch (*ctx->data) {
		case '\0':
			if (ctx->nul_replacement_str != NULL) {
				str_append_data(str, start, ctx->data - start);
				str_append(str, ctx->nul_replacement_str);
				start = ctx->data + 1;
			} else {
				return -1;
			}
			break;
		case '[':
			/* not allowed */
			return -1;
		case ']':
			str_append_data(str, start, ctx->data - start + 1);
			ctx->data++;
			return rfc822_skip_lwsp(ctx);
		case '\n':
			/* folding whitespace, remove the (CR)LF */
			len = ctx->data - start;
			if (len > 0 && start[len-1] == '\r')
				len--;
			str_append_data(str, start, len);
			start = ctx->data + 1;
			break;
		case '\\':
			/* note: the '\' is preserved in the output */
			ctx->data++;
			if (ctx->data >= ctx->end)
				return -1;
#if 0
			if (*ctx->data == '\r' || *ctx->data == '\n' ||
			    *ctx->data == '\0') {
				/* quoted-pair doesn't allow CR/LF/NUL.
				   They are part of the obs-qp though, so don't
				   return them as error. */
				str_append_data(str, start, ctx->data - start);
				start = ctx->data;
				ctx->data--;
				break;
			}
#endif
			break;
		}
	}

	/* missing ']' */
	return -1;
}

/* dot-atom / domain-literal */
static int rfc822_parse_domain(struct rfc822_parser_context *ctx, string_t *str)
{
	/*
	   domain          = dot-atom / domain-literal / obs-domain
	   domain-literal  = [CFWS] "[" *([FWS] dcontent) [FWS] "]" [CFWS]
	   obs-domain      = atom *("." atom)
	*/
	i_assert(ctx->data < ctx->end);
	i_assert(*ctx->data == '@');
	ctx->data++;

	if (rfc822_skip_lwsp(ctx) <= 0)
		return -1;

	if (*ctx->data == '[')
		return rfc822_parse_domain_literal(ctx, str);
	else
		return rfc822_parse_dot_atom(ctx, str, false);
}

static void add_address(struct message_address_parser_context *ctx)
{
	struct message_address *addr;

	addr = malloc(sizeof(struct message_address));
	if (!addr)
		i_panic("malloc() failed: %s", strerror(errno));

	memcpy(addr, &ctx->addr, sizeof(ctx->addr));
	memset(&ctx->addr, 0, sizeof(ctx->addr));

	if (ctx->first_addr == NULL)
		ctx->first_addr = addr;
	else
		ctx->last_addr->next = addr;
	ctx->last_addr = addr;
}

static int
parse_nonstrict_dot_atom(struct rfc822_parser_context *ctx, string_t *str)
{
	int ret = -1;

	do {
		while (*ctx->data == '.') {
			str_append_c(str, '.');
			ctx->data++;
			if (ctx->data == ctx->end) {
				/* @domain is missing, but local-part
				   parsing was successful */
				return 0;
			}
			ret = 1;
		}
		if (*ctx->data == '@')
			break;
		ret = rfc822_parse_atom(ctx, str);
	} while (ret > 0 && *ctx->data == '.');
	return ret;
}

static int parse_local_part(struct message_address_parser_context *ctx)
{
	int ret;
	bool char_problem;

	/*
	   local-part      = dot-atom / quoted-string / obs-local-part
	   obs-local-part  = word *("." word)
	*/
	i_assert(ctx->parser.data < ctx->parser.end);

	str_truncate(ctx->str, 0);
	char_problem = false;

	while (ctx->parser.data < ctx->parser.end) {
		if (*ctx->parser.data == '"')
			ret = rfc822_parse_quoted_string(&ctx->parser, ctx->str);
		else if (!ctx->non_strict_dots || ctx->non_strict_dots_as_invalid)
			ret = rfc822_parse_dot_atom(&ctx->parser, ctx->str, true);
		else
			ret = parse_nonstrict_dot_atom(&ctx->parser, ctx->str);
		if (ret < 0 && (ret != -2 || (!ctx->non_strict_dots && !ctx->non_strict_dots_as_invalid)))
			return -1;
		if (ret == -2)
			char_problem = true;
		if (ctx->parser.data >= ctx->parser.end)
			break;
		if ((ret = rfc822_skip_lwsp(&ctx->parser)) <= 0)
			break;
		if (*ctx->parser.data != '.')
			break;
		ctx->parser.data++;
		if (ctx->parser.data >= ctx->parser.end) {
			char_problem = true;
			break;
		}
		if ((ret = rfc822_skip_lwsp(&ctx->parser)) <= 0)
			break;
		if (ctx->parser.data >= ctx->parser.end || *ctx->parser.data == '@') {
			char_problem = true;
			break;
		}
	}

	if (char_problem || ret < 0)
		ctx->addr.invalid_syntax = true;

	ctx->addr.mailbox = str_ccopy(ctx->str);
	ctx->addr.mailbox_len = str_len(ctx->str);
	return ret;
}

static int parse_domain(struct message_address_parser_context *ctx)
{
	int ret;

	str_truncate(ctx->str, 0);
	if ((ret = rfc822_parse_domain(&ctx->parser, ctx->str)) < 0 && (ret != -2 || (!ctx->non_strict_dots && !ctx->non_strict_dots_as_invalid)))
		return -1;

	ctx->addr.domain = str_ccopy(ctx->str);
	ctx->addr.domain_len = str_len(ctx->str);
	return ret;
}

static int parse_domain_list(struct message_address_parser_context *ctx)
{
	int ret;
	bool dot_problem;

	/* obs-domain-list = "@" domain *(*(CFWS / "," ) [CFWS] "@" domain) */
	str_truncate(ctx->str, 0);
	dot_problem = false;
	for (;;) {
		if (ctx->parser.data >= ctx->parser.end)
			return dot_problem ? -2 : 0;

		if (*ctx->parser.data != '@')
			break;

		if (str_len(ctx->str) > 0)
			str_append_c(ctx->str, ',');

		str_append_c(ctx->str, '@');
		if ((ret = rfc822_parse_domain(&ctx->parser, ctx->str)) <= 0 && (ret != -2 || (!ctx->non_strict_dots && !ctx->non_strict_dots_as_invalid)))
			return ret;

		if (ret == -2)
			dot_problem = true;

		while (rfc822_skip_lwsp(&ctx->parser) > 0 &&
		       *ctx->parser.data == ',')
			ctx->parser.data++;
	}
	ctx->addr.route = str_ccopy(ctx->str);
	ctx->addr.route_len = str_len(ctx->str);
	return dot_problem ? -2 : 1;
}

static int parse_angle_addr(struct message_address_parser_context *ctx,
			    bool parsing_path)
{
	int ret;

	/* "<" [ "@" route ":" ] local-part "@" domain ">" */
	i_assert(*ctx->parser.data == '<');
	ctx->parser.data++;

	if (rfc822_skip_lwsp(&ctx->parser) <= 0)
		return -1;

	if (*ctx->parser.data == '@') {
		if ((ret = parse_domain_list(ctx)) > 0 && *ctx->parser.data == ':') {
			ctx->parser.data++;
		} else if (parsing_path && (ctx->parser.data >= ctx->parser.end || *ctx->parser.data != ':')) {
			return -1;
		} else {
			if (ctx->fill_missing && ret != -2)
				ctx->addr.route = strdup("INVALID_ROUTE");
			ctx->addr.invalid_syntax = true;
			if (ctx->parser.data >= ctx->parser.end)
				return -1;
			if (ret == -2)
				ctx->parser.data++;
			/* try to continue anyway */
		}
		if (rfc822_skip_lwsp(&ctx->parser) <= 0)
			return -1;
	}

	if (*ctx->parser.data == '>') {
		/* <> address isn't valid */
	} else {
		if ((ret = parse_local_part(ctx)) <= 0 && (ret != -2 || (!ctx->non_strict_dots && !ctx->non_strict_dots_as_invalid)))
			return -1;
		if (ret == -2)
			ctx->addr.invalid_syntax = true;
		if (ctx->parser.data >= ctx->parser.end)
			return 0;
		if (*ctx->parser.data == '@') {
			if ((ret = parse_domain(ctx)) <= 0 && (ret != -2 || (!ctx->non_strict_dots && !ctx->non_strict_dots_as_invalid)))
				return -1;
			if (ret == -2)
				ctx->addr.invalid_syntax = true;
			if (ctx->parser.data >= ctx->parser.end)
				return 0;
		}
	}

	if (*ctx->parser.data != '>')
		return -1;
	ctx->parser.data++;

	return rfc822_skip_lwsp(&ctx->parser);
}

static int parse_name_addr(struct message_address_parser_context *ctx)
{
	int ret;

	/*
	   name-addr       = [display-name] angle-addr
	   display-name    = phrase
	*/
	str_truncate(ctx->str, 0);
	ret = rfc822_parse_phrase(&ctx->parser, ctx->str);
	if ((ret <= 0 && (ret != -2 || (!ctx->non_strict_dots && !ctx->non_strict_dots_as_invalid))) ||
	    *ctx->parser.data != '<')
		return -1;

	if (ret == -2)
		ctx->addr.invalid_syntax = true;

	if (str_len(ctx->str) == 0) {
		/* Cope with "<address>" without display name */
		ctx->addr.name = NULL;
	} else {
		ctx->addr.name = str_ccopy(ctx->str);
		ctx->addr.name_len = str_len(ctx->str);
	}

	if (ctx->parser.last_comment != NULL)
		str_truncate(ctx->parser.last_comment, 0);

	if (parse_angle_addr(ctx, false) < 0) {
		/* broken */
		if (ctx->fill_missing)
			ctx->addr.domain = strdup("SYNTAX_ERROR");
		ctx->addr.invalid_syntax = true;
	}

	if (ctx->parser.last_comment != NULL) {
		if (str_len(ctx->parser.last_comment) > 0) {
			ctx->addr.comment =
				str_ccopy(ctx->parser.last_comment);
			ctx->addr.comment_len =
				str_len(ctx->parser.last_comment);
		}
	}

	return ctx->parser.data < ctx->parser.end ? 1 : 0;
}

static int parse_addr_spec(struct message_address_parser_context *ctx)
{
	/* addr-spec       = local-part "@" domain */
	int ret, ret2 = -3;

	i_assert(ctx->parser.data < ctx->parser.end);

	if (ctx->parser.last_comment != NULL)
		str_truncate(ctx->parser.last_comment, 0);

#if 0
	bool quoted_string = *ctx->parser.data == '"';
#endif
	ret = parse_local_part(ctx);
	if (ret <= 0) {
		/* end of input or parsing local-part failed */
		ctx->addr.invalid_syntax = true;
	}
	if (ret != 0 && ctx->parser.data < ctx->parser.end &&
	    *ctx->parser.data == '@') {
		ret2 = parse_domain(ctx);
		if (ret2 <= 0 && ret != -2)
			ret = ret2;
		if (ret2 == -2) {
			ctx->addr.invalid_syntax = true;
			if (ctx->parser.data >= ctx->parser.end)
				ret = 0;
		}
	}

	if (ctx->parser.last_comment != NULL && str_len(ctx->parser.last_comment) > 0) {
		ctx->addr.comment = str_ccopy(ctx->parser.last_comment);
		ctx->addr.comment_len = str_len(ctx->parser.last_comment);
	} else if (ret2 == -3) {
#if 0
		/* So far we've read user without @domain and without
		   (Display Name). We'll assume that a single "user" (already
		   read into addr.mailbox) is a mailbox, but if it's followed
		   by anything else it's a display-name. */
		str_append_c(ctx->str, ' ');
		size_t orig_str_len = str_len(ctx->str);
		(void)rfc822_parse_phrase(&ctx->parser, ctx->str);
		if (str_len(ctx->str) != orig_str_len) {
			ctx->addr.mailbox = NULL;
			ctx->addr.name = str_ccopy(ctx->str);
			ctx->addr.name_len = str_len(ctx->str);
		} else {
			if (!quoted_string)
				ctx->addr.domain = strdup("");
		}
		ctx->addr.invalid_syntax = true;
		ret = -1;
#endif
	}
	return ret;
}

static void add_fixed_address(struct message_address_parser_context *ctx)
{
	if (ctx->addr.mailbox == NULL) {
		ctx->addr.mailbox = strdup(!ctx->fill_missing ? "" : "MISSING_MAILBOX");
		ctx->addr.invalid_syntax = true;
	}
	if (ctx->addr.domain == NULL || ctx->addr.domain_len == 0) {
		free(ctx->addr.domain);
		ctx->addr.domain = strdup(!ctx->fill_missing ? "" : "MISSING_DOMAIN");
		ctx->addr.invalid_syntax = true;
	}
	add_address(ctx);
}

static int parse_mailbox(struct message_address_parser_context *ctx)
{
	const unsigned char *start;
	size_t len;
	int ret;

	/* mailbox         = name-addr / addr-spec */
	start = ctx->parser.data;
	if ((ret = parse_name_addr(ctx)) < 0) {
		/* nope, should be addr-spec */
		if (ctx->addr.name != NULL) {
			free(ctx->addr.name);
			ctx->addr.name = NULL;
		}
		if (ctx->addr.route != NULL) {
			free(ctx->addr.route);
			ctx->addr.route = NULL;
		}
		if (ctx->addr.mailbox != NULL) {
			free(ctx->addr.mailbox);
			ctx->addr.mailbox = NULL;
		}
		if (ctx->addr.domain != NULL) {
			free(ctx->addr.domain);
			ctx->addr.domain = NULL;
		}
		if (ctx->addr.comment != NULL) {
			free(ctx->addr.comment);
			ctx->addr.comment = NULL;
		}
		if (ctx->addr.original != NULL) {
			free(ctx->addr.original);
			ctx->addr.original = NULL;
		}
		ctx->parser.data = start;
		ret = parse_addr_spec(ctx);
		if (ctx->addr.invalid_syntax && ctx->addr.name == NULL &&
		    ctx->addr.mailbox != NULL && ctx->addr.domain == NULL) {
			ctx->addr.name = ctx->addr.mailbox;
			ctx->addr.name_len = ctx->addr.mailbox_len;
			ctx->addr.mailbox = NULL;
			ctx->addr.mailbox_len = 0;
		}
	}

	if (ret < 0)
		ctx->addr.invalid_syntax = true;

	len = ctx->parser.data - start;
	ctx->addr.original = malloc(len + 1);
	if (!ctx->addr.original)
		i_panic("malloc() failed: %s", strerror(errno));

	memcpy(ctx->addr.original, start, len);
	ctx->addr.original[len] = 0;
	ctx->addr.original_len = len;

	add_fixed_address(ctx);

	free(ctx->addr.original);
	ctx->addr.original = NULL;
	return ret;
}

static int parse_group(struct message_address_parser_context *ctx)
{
	int ret;

	/*
	   group           = display-name ":" [mailbox-list / CFWS] ";" [CFWS]
	   display-name    = phrase
	*/
	str_truncate(ctx->str, 0);
	ret = rfc822_parse_phrase(&ctx->parser, ctx->str);
	if ((ret <= 0 && (ret != -2 || (!ctx->non_strict_dots && !ctx->non_strict_dots_as_invalid))) ||
	    *ctx->parser.data != ':')
		return -1;

	if (ret == -2)
		ctx->addr.invalid_syntax = true;

	/* from now on don't return -1 even if there are problems, so that
	   the caller knows this is a group */
	ctx->parser.data++;
	if ((ret = rfc822_skip_lwsp(&ctx->parser)) <= 0)
		ctx->addr.invalid_syntax = true;

	ctx->addr.mailbox = str_ccopy(ctx->str);
	ctx->addr.mailbox_len = str_len(ctx->str);
	add_address(ctx);

	if (ret > 0 && *ctx->parser.data != ';') {
		for (;;) {
			/* mailbox-list    =
			   	(mailbox *("," mailbox)) / obs-mbox-list */
			if (parse_mailbox(ctx) <= 0) {
				/* broken mailbox - try to continue anyway. */
			}
			if (ctx->parser.data >= ctx->parser.end ||
			    *ctx->parser.data != ',')
				break;
			ctx->parser.data++;
			if (rfc822_skip_lwsp(&ctx->parser) <= 0) {
				ret = -1;
				break;
			}
		}
	}
	if (ret >= 0) {
		if (ctx->parser.data >= ctx->parser.end ||
		    *ctx->parser.data != ';')
			ret = -1;
		else {
			ctx->parser.data++;
			ret = rfc822_skip_lwsp(&ctx->parser);
		}
	}
	if (ret < 0)
		ctx->addr.invalid_syntax = true;

	add_address(ctx);
	return ret == 0 ? 0 : 1;
}

static int parse_address(struct message_address_parser_context *ctx)
{
	const unsigned char *start;
	int ret;

	/* address         = mailbox / group */
	start = ctx->parser.data;
	if ((ret = parse_group(ctx)) < 0) {
		/* not a group, try mailbox */
		ctx->parser.data = start;
		ret = parse_mailbox(ctx);
	}
	return ret;
}

static int parse_address_list(struct message_address_parser_context *ctx,
			      unsigned int max_addresses)
{
	const unsigned char *start;
	size_t len;
	int ret = 0;

	/* address-list    = (address *("," address)) / obs-addr-list */
	while (max_addresses > 0) {
		max_addresses--;
		if ((ret = parse_address(ctx)) == 0)
			break;
		if (ctx->parser.data >= ctx->parser.end ||
		    *ctx->parser.data != ',') {
			ctx->last_addr->invalid_syntax = true;
			ret = -1;
			break;
		}
		ctx->parser.data++;
		start = ctx->parser.data;
		if ((ret = rfc822_skip_lwsp(&ctx->parser)) <= 0) {
			if (ret < 0) {
				/* ends with some garbage */
				len = ctx->parser.data - start;
				ctx->addr.original = malloc(len + 1);
				if (!ctx->addr.original)
					i_panic("malloc() failed: %s", strerror(errno));

				memcpy(ctx->addr.original, start, len);
				ctx->addr.original[len] = 0;
				ctx->addr.original_len = len;

				add_fixed_address(ctx);

				free(ctx->addr.original);
				ctx->addr.original = NULL;
			}
			break;
		}
	}
	return ret;
}

static char *mem_copy(const char *mem, size_t len)
{
	char *copy;

	copy = malloc(len+1);
	if (!copy)
		i_panic("malloc() failed: %s", strerror(errno));

	memcpy(copy, mem, len);
	copy[len] = 0;
	return copy;
}

void message_address_add(struct message_address **first, struct message_address **last,
			 const char *name, size_t name_len, const char *route, size_t route_len,
			 const char *mailbox, size_t mailbox_len, const char *domain, size_t domain_len,
			 const char *comment, size_t comment_len)
{
	struct message_address *message;

	message = malloc(sizeof(struct message_address));
	if (!message)
		i_panic("malloc() failed: %s", strerror(errno));

	message->name = name ? mem_copy(name, name_len) : NULL;
	message->name_len = name_len;
	message->route = route ? mem_copy(route, route_len) : NULL;
	message->route_len = route_len;
	message->mailbox = mailbox ? mem_copy(mailbox, mailbox_len) : NULL;
	message->mailbox_len = mailbox_len;
	message->domain = domain ? mem_copy(domain, domain_len) : NULL;
	message->domain_len = domain_len;
	message->comment = comment ? mem_copy(comment, comment_len) : NULL;
	message->comment_len = comment_len;
	message->original = NULL;
	message->original_len = 0;
	message->next = NULL;

	if (!*first)
		*first = message;
	else
		(*last)->next = message;

	*last = message;
}

void message_address_free(struct message_address **addr)
{
	struct message_address *current;
	struct message_address *next;

	current = *addr;

	while (current) {
		next = current->next;
		free(current->name);
		free(current->route);
		free(current->mailbox);
		free(current->domain);
		free(current->comment);
		free(current->original);
		free(current);
		current = next;
	}

	*addr = NULL;
}

struct message_address *
message_address_parse(const char *input, size_t input_len,
		      unsigned int max_addresses,
		      enum message_address_parse_flags flags)
{
	string_t *str;
	struct message_address_parser_context ctx;

	memset(&ctx, 0, sizeof(ctx));

	str = str_new(128);

	rfc822_parser_init(&ctx.parser, (const unsigned char *)input, input_len, str);

	if (rfc822_skip_lwsp(&ctx.parser) <= 0) {
		/* no addresses */
		str_free(&str);
		return NULL;
	}

	ctx.str = str_new(128);
	ctx.fill_missing = (flags & MESSAGE_ADDRESS_PARSE_FLAG_FILL_MISSING) != 0;
	ctx.non_strict_dots = (flags & MESSAGE_ADDRESS_PARSE_FLAG_STRICT_DOTS) == 0;
	ctx.non_strict_dots_as_invalid = (flags & MESSAGE_ADDRESS_PARSE_FLAG_NON_STRICT_DOTS_AS_INVALID) != 0;

	(void)parse_address_list(&ctx, max_addresses);

	str_free(&ctx.str);
	str_free(&str);

	rfc822_parser_deinit(&ctx.parser);

	return ctx.first_addr;
}

static bool has_mime_word(const char *str, size_t len)
{
	const char *ptr;
	const char *end;

	ptr = str;
	end = str+len;

	while ((ptr = memchr(ptr, '=', end - ptr)) != NULL) {
		ptr++;
		if (*ptr == '?')
			return true;
	}

	return false;
}

void message_address_write(char **output, size_t *output_len, const struct message_address *addr)
{
	string_t *str;
	const char *tmp;
	bool first = true, in_group = false;

	str = str_new(128);

#if 0
	if (addr == NULL)
		return;

	/* <> path */
	if (addr->mailbox == NULL && addr->domain == NULL) {
		i_assert(addr->next == NULL);
		str_append(str, "<>");
		return;
	}
#endif

	/* a) mailbox@domain
	   b) name <@route:mailbox@domain>
	   c) group: .. ; */

	while (addr != NULL) {
		if (first)
			first = false;
		else
			str_append(str, ", ");

		if (addr->domain == NULL) {
			if (!in_group) {
				/* beginning of group. mailbox is the group
				   name, others are NULL. */
				if (addr->mailbox != NULL && addr->mailbox_len != 0) {
					/* check for MIME encoded-word */
					if (has_mime_word(addr->mailbox, addr->mailbox_len))
						/* MIME encoded-word MUST NOT appear within a 'quoted-string'
						   so escaping and quoting of phrase is not possible, instead
						   use obsolete RFC822 phrase syntax which allow spaces */
						str_append_data(str, addr->mailbox, addr->mailbox_len);
					else
						str_append_maybe_escape(str, addr->mailbox, addr->mailbox_len, true);
				} else {
					/* empty group name needs to be quoted */
					str_append(str, "\"\"");
				}
				str_append(str, ": ");
				first = true;
			} else {
				/* end of group. all fields should be NULL. */
				i_assert(addr->mailbox == NULL);

				/* cut out the ", " */
				tmp = str_c(str)+str_len(str)-2;
				i_assert((tmp[0] == ',' || tmp[0] == ':') && tmp[1] == ' ');
				if (tmp[0] == ',' && tmp[1] == ' ')
					str_truncate(str, str_len(str)-2);
				else if (tmp[0] == ':' && tmp[1] == ' ')
					str_truncate(str, str_len(str)-1);
				str_append_c(str, ';');
			}

			in_group = !in_group;
		} else if ((addr->name == NULL || addr->name_len == 0) &&
			   addr->route == NULL) {
			/* no name and no route. use only mailbox@domain */
			i_assert(addr->mailbox != NULL);

			str_append_maybe_escape(str, addr->mailbox, addr->mailbox_len, false);
			str_append_c(str, '@');
			str_append_data(str, addr->domain, addr->domain_len);

			if (addr->comment != NULL) {
				str_append(str, " (");
				str_append_data(str, addr->comment, addr->comment_len);
				str_append_c(str, ')');
			}
		} else {
			/* name and/or route. use full <mailbox@domain> Name */
			i_assert(addr->mailbox != NULL);

			if (addr->name != NULL && addr->name_len != 0) {
				/* check for MIME encoded-word */
				if (has_mime_word(addr->name, addr->name_len))
					/* MIME encoded-word MUST NOT appear within a 'quoted-string'
					   so escaping and quoting of phrase is not possible, instead
					   use obsolete RFC822 phrase syntax which allow spaces */
					str_append_data(str, addr->name, addr->name_len);
				else
					str_append_maybe_escape(str, addr->name, addr->name_len, true);
			}
			if (addr->route != NULL ||
			    addr->mailbox_len != 0 ||
			    addr->domain_len != 0) {
				if (addr->name != NULL && addr->name_len != 0)
					str_append_c(str, ' ');
				str_append_c(str, '<');
				if (addr->route != NULL) {
					str_append_data(str, addr->route, addr->route_len);
					str_append_c(str, ':');
				}
				str_append_maybe_escape(str, addr->mailbox, addr->mailbox_len, false);
				if (addr->domain_len != 0) {
					str_append_c(str, '@');
					str_append_data(str, addr->domain, addr->domain_len);
				}
				str_append_c(str, '>');
			}
			if (addr->comment != NULL) {
				str_append(str, " (");
				str_append_data(str, addr->comment, addr->comment_len);
				str_append_c(str, ')');
			}
		}

		addr = addr->next;
	}

	*output = str_ccopy(str);
	*output_len = str_len(str);
	str_free(&str);
}

void compose_address(char **output, size_t *output_len, const char *mailbox, size_t mailbox_len, const char *domain, size_t domain_len)
{
	string_t *str;

	str = str_new(128);

	str_append_maybe_escape(str, mailbox, mailbox_len, false);
	str_append_c(str, '@');
	str_append_data(str, domain, domain_len);

	*output = str_ccopy(str);
	*output_len = str_len(str);
	str_free(&str);
}

void split_address(const char *input, size_t input_len, char **mailbox, size_t *mailbox_len, char **domain, size_t *domain_len)
{
	struct message_address_parser_context ctx;
	int ret;

	if (!input || !input[0]) {
		*mailbox = NULL;
		*mailbox_len = 0;
		*domain = NULL;
		*domain_len = 0;
		return;
	}

	memset(&ctx, 0, sizeof(ctx));

	rfc822_parser_init(&ctx.parser, (const unsigned char *)input, input_len, NULL);

	ctx.str = str_new(128);
	ctx.fill_missing = false;
	ctx.non_strict_dots = false;
	ctx.non_strict_dots_as_invalid = false;

	ret = rfc822_skip_lwsp(&ctx.parser);

	if (ret > 0)
		ret = parse_addr_spec(&ctx);
	else
		ret = -1;

	if (ret >= 0)
		ret = rfc822_skip_lwsp(&ctx.parser);

	if (ret < 0 || ctx.parser.data != ctx.parser.end || ctx.addr.invalid_syntax) {
		free(ctx.addr.mailbox);
		free(ctx.addr.domain);
		*mailbox = NULL;
		*mailbox_len = 0;
		*domain = NULL;
		*domain_len = 0;
	} else {
		*mailbox = ctx.addr.mailbox;
		*mailbox_len = ctx.addr.mailbox_len;
		*domain = ctx.addr.domain;
		*domain_len = ctx.addr.domain_len;
	}

	free(ctx.addr.comment);
	free(ctx.addr.route);
	free(ctx.addr.name);
	free(ctx.addr.original);

	rfc822_parser_deinit(&ctx.parser);

	str_free(&ctx.str);
}

void string_free(char *string)
{
	free(string);
}
