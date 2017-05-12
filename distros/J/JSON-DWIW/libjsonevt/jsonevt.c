/* Creation date: 2007-07-13 20:41:08
 * Authors: Don
 */

/*

 Copyright (c) 2007-2010 Don Owens <don@regexguy.com>.  All rights reserved.

 This is free software; you can redistribute it and/or modify it under
 the Perl Artistic license.  You should have received a copy of the
 Artistic license with this distribution, in the file named
 "Artistic".  You may also obtain a copy from
 http://regexguy.com/license/Artistic

 This program is distributed in the hope that it will be useful, but
 WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

*/

/* $Header: /repository/projects/libjsonevt/jsonevt.c,v 1.51 2009-02-24 06:22:21 don Exp $ */

/*
#if defined(__WIN32) || defined(WIN32) || defined(_WIN32)
#define JSONEVT_ON_WINDOWS
#endif
*/

#include "jsonevt_private.h"

#include <stdlib.h>
#include <string.h>
#include <stdio.h>
#include <stdarg.h>
#include <sys/types.h>

#ifdef JSONEVT_ON_WINDOWS
typedef unsigned int uint;
#endif

#ifndef JSONEVT_ON_WINDOWS
#define USE_MMAP
#endif

#ifdef USE_MMAP
#include <sys/mman.h>
#include <unistd.h>
#endif

#include <fcntl.h>
#include <sys/stat.h>

#define BFD(x) { #x, x },

typedef struct {
    const char *n;
    unsigned int val;
} fd;

static fd flag_data[ ] =
    {
        BFD(JSON_EVT_PARSE_NUMBER_HAVE_SIGN)
        BFD(JSON_EVT_PARSE_NUMBER_HAVE_DECIMAL)
        BFD(JSON_EVT_PARSE_NUMBER_HAVE_EXPONENT)
        BFD(JSON_EVT_IS_HASH_KEY)
        BFD(JSON_EVT_IS_HASH_VALUE)
        BFD(JSON_EVT_IS_ARRAY_ELEMENT)
        BFD(JSON_EVT_IS_C_COMMENT)
        BFD(JSON_EVT_IS_CPLUSPLUS_COMMENT)
        BFD(JSON_EVT_IS_PERL_COMMENT)
        { NULL, 0 }
    };


#if 0
#define SETUP_TRACE fprintf(stderr, "in %s() at line %d of %s\n", __func__, __LINE__, __FILE__); \
    fflush(stderr);
#else
#define SETUP_TRACE
#endif

#define memzero(buf, size) memset(buf, 0, size)

static char * vset_error(json_context * ctx, char * file, uint line, char * fmt, va_list *ap);

#ifdef JSONEVT_HAVE_VARIADIC_MACROS
#define SET_ERROR(ctx,fmt,...) set_error(ctx, __FILE__, __LINE__, fmt, ## __VA_ARGS__)
#else
static char *
SET_ERROR(json_context * ctx, char * fmt, ...) {
    va_list ap;
    char * error;

    va_start(ap, fmt);
    error = vset_error(ctx, "", 0, fmt, &ap);
    va_end(ap);

    return error;
}
#endif

#define ERROR_IS_SET(ctx) ((ctx)->ext_ctx->error)
#define BREAK_ON_ERROR(ctx) if (ERROR_IS_SET(ctx)) { break; }

static int parse_value(json_context * ctx, uint level, uint flags);
static char * set_error(json_context * ctx, char * file, uint line, char * fmt, ...);

/*
#define UNI_CHK_RETURN(ctx, val) ((ctx->options && (ctx->options & JSON_EVT_OPTION_BAD_CHAR_POLICY_CONVERT ? val : (ctx->options & JSON_EVT_OPTION_BAD_CHAR_POLICY_PASS ? val : 0)) ) : 0)
*/


static uint
json_utf8_to_uni_with_check(json_context * ctx, const char * str, uint cur_len, uint * ret_len,
    uint flags) {

    uint uval;
    unsigned char * s = (unsigned char *)str;

    if (ret_len) {
        *ret_len = 0;
    }

    if (cur_len == 0) {
        return 0;
    }

    uval = utf8_bytes_to_unicode((uint8_t *)str, cur_len, ret_len);

    if (uval == 0) {
        if (ctx->bad_char_policy && (ctx->bad_char_policy & JSON_EVT_OPTION_BAD_CHAR_POLICY_CONVERT)) {
            uval = (uint)*s;
            if (ret_len) {
                *ret_len = 1;
            }
        }
        else {
            SET_ERROR(ctx, "bad utf-8 sequence");
        }
    }

    return uval;
}

#define UTF8_TO_CODE_POINT(ctx, str, cur_len, ret_len) ( cur_len > 0 ? ( UTF8_BYTE_IS_INVARIANT(*str) ? ( (*ret_len = 1), (uint)*str) : json_utf8_to_uni_with_check(ctx, str, cur_len, ret_len, 0)) : 0 )

#define READ_CHAR(ctx, ret_len) ( HAVE_MORE_CHARS(ctx) ? (UTF8_TO_CODE_POINT(ctx, &(ctx)->buf[(ctx)->pos], (ctx)->len - (ctx)->pos, ret_len)) : 0 )


static uint
peek_char(json_context * ctx) {
    uint len = 0;

    if (ctx->pos >= ctx->len) {
        return 0;
    }
    
    ctx->cur_char = READ_CHAR(ctx, &len);
    ctx->cur_char_len = len;
    ctx->flags.have_char = 1;
    
    return ctx->cur_char;
}

static uint
next_char(json_context * ctx) {
    uint len = 0;

    if (ctx->pos >= ctx->len) {
        return 0;
    }

    if (JSON_IS_END_OF_LINE(ctx->cur_char)) {
        ctx->cur_line++;
        ctx->cur_byte_col = 0;
        ctx->cur_char_col = 0;
    }
    else {
        if (ctx->pos) {
            ctx->cur_byte_col += ctx->cur_char_len;
            ctx->cur_char_col++;
        }
    }

    ctx->cur_byte_pos = ctx->pos;
    ctx->cur_char = READ_CHAR(ctx, &len);
    ctx->cur_char_len = len;
    ctx->cur_char_pos = ctx->char_pos;

    ctx->flags.have_char = 1;

    ctx->pos += len;
    ctx->char_pos++;

    return ctx->cur_char;
}

static char *
vset_error(json_context * ctx, char * file, uint line, char * fmt, va_list *ap) {
    char * error = NULL;
    char * loc = NULL;
    char * msg = NULL;
    int loc_len = 0;
    int msg_len = 0;

    if (! ctx->ext_ctx) {
        return NULL;
    }

    if (ctx->ext_ctx->error) {
        return ctx->ext_ctx->error;
    }

#if JSON_DO_DEBUG
    loc_len = js_asprintf(&loc, "%s (%u) v%u.%u.%u byte %u, char %u, line %u, col %u (byte col %u) - ",
        file, line, JSON_EVT_MAJOR_VERSION, JSON_EVT_MINOR_VERSION, JSON_EVT_PATCH_LEVEL,
        CUR_POS(ctx), CUR_CHAR_POS(ctx), CUR_LINE(ctx), CUR_COL(ctx), CUR_BYTE_COL(ctx));
#else
#if NO_VERSION_IN_ERROR
    loc_len = js_asprintf(&loc, "byte %u, char %u, line %u, col %u (byte col %u) - ",
        CUR_POS(ctx), CUR_CHAR_POS(ctx), CUR_LINE(ctx), CUR_COL(ctx), CUR_BYTE_COL(ctx));
#else
    loc_len = js_asprintf(&loc, "v%u.%u.%u byte %u, char %u, line %u, col %u (byte col %u) - ",
        JSON_EVT_MAJOR_VERSION, JSON_EVT_MINOR_VERSION, JSON_EVT_PATCH_LEVEL,
        CUR_POS(ctx), CUR_CHAR_POS(ctx), CUR_LINE(ctx), CUR_COL(ctx), CUR_BYTE_COL(ctx));
#endif
#endif

    msg_len = js_vasprintf(&msg, fmt, ap);

    JSONEVT_NEW(error, loc_len + msg_len + 1, char);
	MEM_CPY(error, loc, loc_len);
    MEM_CPY(&error[loc_len], msg, msg_len);
    error[loc_len + msg_len] = '\x00';

    ctx->ext_ctx->error = error;
    ctx->ext_ctx->error_line = CUR_LINE(ctx);
    ctx->ext_ctx->error_char_col = CUR_COL(ctx);
    ctx->ext_ctx->error_byte_col = CUR_BYTE_COL(ctx);
    ctx->ext_ctx->error_byte_pos = CUR_POS(ctx);
    ctx->ext_ctx->error_char_pos = CUR_CHAR_POS(ctx);

    JSONEVT_FREE_MEM(msg);
    JSONEVT_FREE_MEM(loc);

    return error;
}

static char *
set_error(json_context * ctx, char * file, uint line, char * fmt, ...) {
    va_list ap;
    char * error;

    va_start(ap, fmt);
    error = vset_error(ctx, file, line, fmt, &ap);
    va_end(ap);

    return error;
}

static int
eat_whitespace(json_context *ctx, int commas_are_whitespace, uint line) {
    uint this_char;
    int keep_going = 1;
    uint last_char = 0;
    uint last_char_valid = 0;
    const char * tmp_buf = NULL;

    SETUP_TRACE;

    PDB("pos=%u, len=%u", ctx->pos, ctx->len);

    if (! HAVE_MORE_CHARS(ctx)) {
        return 0;
    }

    SETUP_TRACE;

    while (keep_going && HAVE_MORE_CHARS(ctx)) {
        this_char = PEEK_CHAR(ctx);

        if (this_char >= 0x0009 && this_char <= 0x000d) {
            /* U+0009 - tab
               U+000A - line feed
               U+000B - vertical tab
               U+000C - form feed
               U+000D - carriage return

             */
            NEXT_CHAR(ctx);
            continue;
        }

        switch (this_char) {
          case 0x0020: /* space */
          case 0x0085: /* NEL - next line */
          case 0x00a0: /* NSBP - non-breaking space */
          case 0x200b: /* ZWSP - zero width space */
          case 0x2028: /* LS - line separator */
          case 0x2029: /* PS - paragraph separator */
          case 0x2060: /* WJ - word joiner */
              
              NEXT_CHAR(ctx);
              break;

          case ',':
              if (commas_are_whitespace) {
                  NEXT_CHAR(ctx);
              }
              else {
                  keep_going = 0;
              }
              break;

          case '#':
              tmp_buf = CUR_BUF(ctx);
              while (HAVE_MORE_CHARS(ctx)) {
                  this_char = NEXT_CHAR(ctx);
                  if (this_char == 0x000a || this_char == 0x0085 || this_char == 0x2028) {
                      /* eat the eol char */
                      this_char = NEXT_CHAR(ctx);
                      DO_COMMENT_CALLBACK_WITH_RET(ctx, tmp_buf,
                          CUR_BUF(ctx) - tmp_buf - 1, JSON_EVT_IS_PERL_COMMENT);
                      break;
                  }
              }
              
              /* end of buffer */
              DO_COMMENT_CALLBACK_WITH_RET(ctx, tmp_buf,
                  CUR_BUF(ctx) - tmp_buf, JSON_EVT_IS_PERL_COMMENT);
              
              break;

          case '/':
              this_char = NEXT_CHAR(ctx);
              if (this_char == '/') {
                  /* C++ style comment -- rest of line is a comment */
                  tmp_buf = CUR_BUF(ctx);
                  while (HAVE_MORE_CHARS(ctx)) {
                      this_char = NEXT_CHAR(ctx);
                      if (this_char == 0x000a || this_char == 0x0085 || this_char == 0x2028) {
                          /* eat the eol char */
                          this_char = NEXT_CHAR(ctx);
                          DO_COMMENT_CALLBACK_WITH_RET(ctx, tmp_buf,
                              CUR_BUF(ctx) - tmp_buf - 1, JSON_EVT_IS_CPLUSPLUS_COMMENT);
                          break;
                      }
                  }

                  /* end of buffer */
                  DO_COMMENT_CALLBACK_WITH_RET(ctx, tmp_buf,
                      CUR_BUF(ctx) - tmp_buf, JSON_EVT_IS_CPLUSPLUS_COMMENT);

                  break;
              }
              else if (this_char == '*') {
                  last_char_valid = 0;
                  tmp_buf = CUR_BUF(ctx);

                  while (HAVE_MORE_CHARS(ctx)) {
                      this_char = NEXT_CHAR(ctx);
                      if (last_char_valid) {
                          if (this_char == '/') {
                              if (last_char == '*') {
                                  /* end of comment */
                                  DO_COMMENT_CALLBACK_WITH_RET(ctx, tmp_buf,
                                      CUR_BUF(ctx) - tmp_buf - 2, JSON_EVT_IS_C_COMMENT);
                                  this_char = NEXT_CHAR(ctx);
                                  break;
                              }
                          }
                      }
                      else {
                          last_char_valid = 1;
                      }

                      last_char = this_char;
                  }
              }
              else {
                  JSON_DEBUG("bad comment -- found first '/' but not second one");
                  SET_ERROR(ctx, "syntax error -- can't have '/' by itself");
                  return 0;
              }
              break;

          default:
              /* JSON_DEBUG("%c is not whitespace (code line %u)", this_char, line); */
              keep_going = 0;
              break;
        }
    }
    
    return 1;
}

static uint
switch_from_static_buf(json_str * s, uint new_size) {
    char * orig_buf = s->buf;
    uint orig_len = s->len;

    new_size = new_size > orig_len ? new_size : orig_len;
    if (new_size == 0) {
        new_size = 8;
    }

    ALLOC_NEW_BUF(s, new_size);
	MEM_CPY(s->buf, orig_buf, orig_len);
    s->flags.using_orig = 0;

    JSON_DEBUG("-- switched to heap buf (%p, len %u), orig_buf is %p, len %u, stack_buf %p, len %u",
        s->buf, new_size, orig_buf, orig_len, s->stack_buf, s->stack_buf_len);
    
    return 1;
}

#if 0
static uint
switch_to_dynamic_buf(json_str * s) {
    if (s->flags.using_orig) {
        char * orig_buf = s->buf;
        uint orig_len = s->len;

        if (0 && s->stack_buf && orig_len <= s->stack_buf_len) {
            JSON_DEBUG("-- switching to stack buf (%p), old buf is %p", s->stack_buf, orig_buf);
            s->buf = s->stack_buf;
            s->len = s->stack_buf_len;
        }
        else {
            /* FIXME: should up to a power of 2 */
            JSON_DEBUG("-- switching to heap buf");
            ALLOC_NEW_BUF(s, orig_len);
        }

        MEM_CPY(s->buf, orig_buf, orig_len);
        s->flags.using_orig = 0;
    }

    return 1;
}
#endif

#define UNICODE_TO_BYTES(ctx, code_point, out_buf) \
    (UNICODE_IS_INVARIANT(code_point)  ?  (*(out_buf) = code_point, 1) : \
        utf8_unicode_to_bytes((uint32_t)code_point, out_buf) )


/* return estimate JSON string size in bytes */
/* assume utf-8 for now */
static uint
estimate_json_string_size(const char * buf, uint max_len, uint boundary_char,
    uint * end_quote_pos) {
    uint i;
    uint size = 0;
    uint bytes_this_char = 0;

    JSON_DEBUG("max_len=%u", max_len);

    if (end_quote_pos) {
        *end_quote_pos = 0;
    }

    for (i = 0; i < max_len; i++) {
        if (size < max_len) {
            if (buf[size] == boundary_char) {
                if (end_quote_pos) {
                    *end_quote_pos = size;
                    JSON_DEBUG("set end_quote_pos=%u", *end_quote_pos);
                }
                break;
            }
            size++;
        }
        else {
            JSON_DEBUG("returning size %u", size);
            return size;
        }

        /* FIXME: utf-8 can be two bytes, both of which can have the high bit set, e.g.,
           ce a9 (e with accute accent */

        if (buf[size - 1] & 0x80) {
            JSON_DEBUG("HERE in multibyte sequence");


            /* multi-byte char */
            bytes_this_char = 1;
            size++;
            while (bytes_this_char < 4) {
                if (size < max_len) {
                    size++;
                    bytes_this_char++;
                    if (! (buf[size - 1] & 0x80) ) {
                        break;
                    }
                }
                else {
                    break;
                }
            }
        }



    }

    JSON_DEBUG("returning size %u", size);
    return size;
}


#define EAT_DIGITS(ctx) while (HAVE_MORE_CHARS(ctx) && \
        CUR_CHAR(ctx) >= '0' && CUR_CHAR(ctx) <= '9' ) { NEXT_CHAR(ctx); } \
    if (CUR_CHAR(ctx) >= '0' && CUR_CHAR(ctx) <= '9' ) { NEXT_CHAR(ctx); }


/*
#define EAT_DIGITS(ctx) fprintf(stderr, "looking at char %c\n", CUR_CHAR(ctx)); while (HAVE_MORE_CHARS(ctx) && \
        CUR_CHAR(ctx) >= '0' && CUR_CHAR(ctx) <= '9' ) { NEXT_CHAR(ctx); fprintf(stderr, "looking at char %c\n", CUR_CHAR(ctx)); }
*/

#define kParseNumberHaveSign     JSON_EVT_PARSE_NUMBER_HAVE_SIGN
#define kParseNumberHaveDecimal  JSON_EVT_PARSE_NUMBER_HAVE_DECIMAL
#define kParseNumberHaveExponent JSON_EVT_PARSE_NUMBER_HAVE_EXPONENT
/*
#define kParseNumberDone         (1 << 3)
#define kParseNumberTryBigNum    (1 << 4)
*/
static int
parse_number(json_context * ctx, uint level, uint flags) {
    uint this_char;
    uint start_pos = 0;
    uint len = 0;

    this_char = PEEK_CHAR(ctx);
    start_pos = CUR_POS(ctx);

    if (this_char == '-') {
        this_char = NEXT_CHAR(ctx);
        flags |= kParseNumberHaveSign;
    }

    if (this_char < '0' || this_char > '9') {
        SET_ERROR(ctx, "syntax error");
        return 0;
    }

    ctx->ext_ctx->number_count++;

    EAT_DIGITS(ctx);

    if (HAVE_MORE_CHARS(ctx)) {
        this_char = CUR_CHAR(ctx);
        
        if (this_char == '.') {
            flags |= kParseNumberHaveDecimal;
            NEXT_CHAR(ctx);
            EAT_DIGITS(ctx);
            this_char = CUR_CHAR(ctx);
        }

        if (HAVE_MORE_CHARS(ctx)) {
            if (this_char == 'E' || this_char == 'e') {
                /* exponential notation */
                flags |= kParseNumberHaveExponent;
                this_char = NEXT_CHAR(ctx);

                if (HAVE_MORE_CHARS(ctx)) {
                    if (this_char == '+' || this_char == '-') {
                        this_char = NEXT_CHAR(ctx);
                    }

                    EAT_DIGITS(ctx);
                    this_char = CUR_CHAR(ctx);
                }
            }
        }
    }
        
    if (ctx->number_cb) {
        len = CUR_POS(ctx) - start_pos;

        /* work around edge case where the entire input is just a number */
        if (level == 0) {
            len++;
        }
        /*
        if (BYTES_LEFT(ctx) == 0) {
            len++;
        }
        */
        

        DO_CB_WITH_RET(ctx, "number", ctx->number_cb(ctx->cb_data, &(ctx->buf[start_pos]), len,
                flags, level));
    }

    return 1;
}

/*
 If is_identifier is true, this word is an identifier, e.g., an
 unquoted hash key, so the characters is may consist of are limited to
 [0-9A-Za-z_] and must start with a letter.  If is_identifier is
 false, the word must be either "true", "false", or "null".
 */
static int
parse_word(json_context * ctx, int is_identifier, uint level, uint flags) {
    uint this_char = PEEK_CHAR(ctx);
    uint start_pos;
    const char * start_buf;
    uint len;

    if (this_char >= '0' && this_char <= '9') {
        if (flags & JSON_EVT_IS_HASH_KEY) {
            SET_ERROR(ctx, "syntax error in hash key (bare keys must begin with [A-Za-z_0-9])");
            return 0;
        }
        return parse_number(ctx, level, flags);
    }

    /* FIXME: check "strict" option here and error out if set and this is a hash key */

    /* FIXME: check identifiers by section 5.16 of version 3.0 of unicode standard, 
       but allow $ and _
    */


    start_pos = CUR_POS(ctx);
    start_buf = &ctx->buf[start_pos];

    while (HAVE_MORE_CHARS(ctx) &&
        ( (this_char >= '0' && this_char <= '9')
            || (this_char >= 'A' && this_char <= 'Z')
            || (this_char >= 'a' && this_char <= 'z')
            || this_char == '_' || this_char == '$'
          )) {
            this_char = NEXT_CHAR(ctx);
    }

    len = CUR_POS(ctx) - start_pos;

    if (len == 0) {
        if (flags & JSON_EVT_IS_HASH_VALUE) {
            SET_ERROR(ctx, "syntax error in hash value");
        }
        else if (flags & JSON_EVT_IS_HASH_KEY) {
            SET_ERROR(ctx, "syntax error in hash key");
        }
        else {
            SET_ERROR(ctx, "syntax error");
        }

        return 0;
    }


    if (is_identifier) {

        /* treat as if it were a string */
        if (ctx->string_cb) {
            DO_CB_WITH_RET(ctx, "string",
                ctx->string_cb(ctx->cb_data, start_buf, len, flags, level));
        }

        ctx->ext_ctx->string_count++;

        return 1;
    }
    else {
        if (BUF_EQ("true", start_buf, len)) {
            DO_BOOL_CALLBACK_WITH_RET(ctx, 1, flags, level);
            ctx->ext_ctx->bool_count++;
            return 1;
        }
        else if (BUF_EQ("false", start_buf, len)) {
            DO_BOOL_CALLBACK_WITH_RET(ctx, 0, flags, level);
            ctx->ext_ctx->bool_count++;
            return 1;
        }
        else if (BUF_EQ("null", start_buf, len)) {
            /* call null callback */
            DO_GEN_CALLBACK_WITH_RET(ctx, null_cb, flags, level, "null");
            ctx->ext_ctx->null_count++;
            return 1;
        }
        else {
            SET_ERROR(ctx, "syntax error");
            /* fwrite(start_buf, 1, len, stdout); */
            return 0;
        }
    }

    SET_ERROR(ctx, "unknown error in parse_word()");
    return 0;
}

#define GET_HEX_NIBBLE(ctx, nv, u_bytes, i, this_char, error_msg)       \
                  this_char = NEXT_CHAR(ctx);                           \
                  nv = HEX_NIBBLE_TO_INT(this_char);                    \
                  if (nv == -1) {                                       \
                      SET_ERROR(ctx, error_msg);                        \
                      CLEAR_JSON_STR(&str);                             \
                      return 0;                                         \
                  }                                                     \
                  u_bytes[i] = (uint8_t)nv;                             \
                  i++;

static int
parse_string(json_context * ctx, uint level, uint flags) {
    uint32_t this_char;
    int nibble_val;
    uint32_t quote_char;
    uint char_count = 0;
    uint buf_size = 0;
    json_str str;
    uint end_quote_pos = 0;
    uint8_t u_bytes[4];
    uint32_t u_bytes_len;
    /* uint multiplier; */
    int i;
    /* uint this_val; */
    uint first_time = 1;
    const char * orig_buf = NULL;
    char stack_buf[STATIC_BUF_SIZE];
    int cb_rv = CB_OK_VAL;

    SETUP_TRACE;

    ZERO_MEM((void *)&str, sizeof(json_str));

    this_char = PEEK_CHAR(ctx);
    if (this_char == '"' || this_char == '\'') {
        quote_char = this_char;
    }
    else {
        JSON_DEBUG("bad quote: 0x%04x", this_char);
        SET_ERROR(ctx, "syntax error: missing quote in string");
        return 0;
    }

    SETUP_TRACE;

    ctx->ext_ctx->string_count++;

    if (CUR_POS(ctx) == 0) {
        NEXT_CHAR(ctx);
    }

    orig_buf = CUR_BUF(ctx);
    
    while (HAVE_MORE_CHARS(ctx)) {
        this_char = NEXT_CHAR(ctx);
        BREAK_ON_ERROR(ctx);

        if (first_time) {
            first_time = 0;

            buf_size = estimate_json_string_size(orig_buf, ctx->len - CUR_POS(ctx),
                quote_char, &end_quote_pos);

            INIT_JSON_STR_STATIC_BUF(&str, orig_buf, end_quote_pos, stack_buf, STATIC_BUF_SIZE);
            GROW_JSON_STR(&str, buf_size);
        }

        if (this_char == quote_char) {
            SETUP_TRACE;

            UPDATE_STATS_STRING_BYTES(ctx, str.pos);
            UPDATE_STATS_STRING_CHARS(ctx, char_count);

            if (ctx->string_cb) {
                SETUP_TRACE;
                JSON_DEBUG("about to call string callback with buf %p, len %u, flags %#x, level %u",
                    str.buf, str.pos, flags, level);
                cb_rv = ctx->string_cb(ctx->cb_data, str.buf, str.pos, flags, level);
                SETUP_TRACE;
            }

            CLEAR_JSON_STR(&str);

            if (CB_IS_TERM(cb_rv)) {
                SETUP_TRACE;
                SET_CB_ERROR(ctx, "string");
                CB_SET_TERM_VAL(ctx, cb_rv);
                return 0;
            }

            /* eat the quote */
            NEXT_CHAR(ctx);
            BREAK_ON_ERROR(ctx);

            SETUP_TRACE;

            return 1;
        }

        char_count++;

        if (this_char == '\\') {
            this_char = NEXT_CHAR(ctx);
            SWITCH_FROM_STATIC(&str);

            /* FIXME: should \0 be accepted, as in the ECMA standard? */
            switch (this_char) {
              case '\\': /* 0x5c */
              case '/':  /* 0x2f */
              case '"':  /* 0x22 */
              case '\'': /* 0x27 */
                  /* treat these as literals */
                  break;

              case 'b': /* 0x62 */
                  this_char = 0x08; /* backspace */
                  break;
                  
              case 'n': /* 0x6e */
                  this_char = 0x0a; /* line feed */
                  break;

              case 'v': /* 0x76 */
                  this_char = 0x0b; /* vertical tab */
                  break;

              case 'f': /* 0x66 */
                  this_char = 0x0c; /* form feed */
                  break;

              case 'r': /* 0x72 */
                  this_char = 0x0d; /* carriage return */
                  break;

              case 't': /* 0x74 */
                  this_char = 0x09; /* tab */
                  break;

              case 'x': /* 0x78 */
                  /* hex escape sequence */

#define BHE_MSG "bad hex escape character specification"

                  i = 0;
                  GET_HEX_NIBBLE(ctx, nibble_val, u_bytes, i, this_char, BHE_MSG);
                  GET_HEX_NIBBLE(ctx, nibble_val, u_bytes, i, this_char, BHE_MSG);

                  this_char = 16 * u_bytes[0] + u_bytes[1];

                  break;

              case 'u': /* 0x75 */
                  /* unicode escape sequence */

#define BUE_MSG "bad unicode character specification"

                  i = 0;
                  GET_HEX_NIBBLE(ctx, nibble_val, u_bytes, i, this_char, BUE_MSG);
                  GET_HEX_NIBBLE(ctx, nibble_val, u_bytes, i, this_char, BUE_MSG);
                  GET_HEX_NIBBLE(ctx, nibble_val, u_bytes, i, this_char, BUE_MSG);
                  GET_HEX_NIBBLE(ctx, nibble_val, u_bytes, i, this_char, BUE_MSG);

                  this_char = 4096 * u_bytes[0] + 256 * u_bytes[1] + 16 * u_bytes[2] + u_bytes[3];

                  break;


              default:
                  /* unrecognized escape, send it through literally */
                  /* FIXME: check "strict" option here and error out if set */
                  break;
            }

        }

        BREAK_ON_ERROR(ctx);

        u_bytes_len = UNICODE_TO_BYTES(ctx, this_char, u_bytes);
        MAYBE_APPEND_BYTES(&str, u_bytes, u_bytes_len);

    }
    
    JSON_DEBUG("Error: got %c (0x%04x)", this_char, this_char);
    SET_ERROR(ctx, "unterminated string");
    CLEAR_JSON_STR(&str);

    return 0;
}

static int
parse_array(json_context * ctx, uint level, uint flags) {
    uint this_char = PEEK_CHAR(ctx);
    int keep_going = 1;
    int found_comma = 0;

    SETUP_TRACE;

    if (this_char != '[') {
        return 0;
    }

    ctx->ext_ctx->array_count++;

    DO_GEN_CALLBACK_WITH_RET(ctx, begin_array_cb, flags, level, "begin_array");

    level++;

    INCR_DATA_DEPTH(ctx, level);

    if (CUR_POS(ctx) == 0) {
        NEXT_CHAR(ctx);
    }

    NEXT_CHAR(ctx);

    EAT_WHITESPACE(ctx, 0);
    this_char = PEEK_CHAR(ctx);
    if (this_char == ']') {
        DO_GEN_CALLBACK_WITH_RET(ctx, end_array_cb, flags, level - 1, "end_array");
        NEXT_CHAR(ctx);
        EAT_WHITESPACE(ctx, 0);
        return 1;
    }

    if (AT_END_OF_BUF(ctx)) {
        SET_ERROR(ctx, "array not terminated");
        return 0;
    }

    while (keep_going) {
        DO_GEN_CALLBACK_WITH_RET(ctx, begin_array_element_cb, 0, level, "begin_array_element");

        if (! parse_value(ctx, level, JSON_EVT_IS_ARRAY_ELEMENT)) {
            JSON_DEBUG("parse_value() returned error");
            return 0;
        }

        DO_GEN_CALLBACK_WITH_RET(ctx, end_array_element_cb, 0, level, "end_array_element");

        EAT_WHITESPACE(ctx, 0);
        this_char = PEEK_CHAR(ctx);

        if (this_char == ',') {
            EAT_WHITESPACE(ctx, 1);
            found_comma = 1;
        }
        else {
            found_comma = 0;
        }

        switch (this_char) {
          case ']':
              /* end of the array */
              DO_GEN_CALLBACK_WITH_RET(ctx, end_array_cb, flags, level - 1, "end_array");
              NEXT_CHAR(ctx);
              EAT_WHITESPACE(ctx, 0);
              return 1;
              break;

          default:
              if (! found_comma) {
                  /* error */
                  JSON_DEBUG("didn't find comma for array, char is %c", this_char);
                  SET_ERROR(ctx, "syntax error in array");
                  return 0;
              }
              break;
        }
        
    }
    
    SET_ERROR(ctx, "unknown error in array");
    return 0;
}

static int
parse_hash(json_context * ctx, uint level, uint flags) {
    uint this_char = PEEK_CHAR(ctx);
    int keep_going = 1;
    int found_comma = 0;

    JSON_DEBUG("parse_hash() called");

    if (this_char != '{') {
        SET_ERROR(ctx, "syntax error: bad object (didn't find '{'");
        return 0;
    }

    ctx->ext_ctx->hash_count++;

    JSON_DEBUG("before begin_hash_cb call");

    DO_GEN_CALLBACK_WITH_RET(ctx, begin_hash_cb, flags, level, "begin_hash");

    level++;
    INCR_DATA_DEPTH(ctx, level);

    JSON_DEBUG("after begin_hash_cb call");

    if (CUR_POS(ctx) == 0) {
        NEXT_CHAR(ctx);
    }

    NEXT_CHAR(ctx);
    EAT_WHITESPACE(ctx, 1);
    this_char = PEEK_CHAR(ctx);
    if (this_char == '}') {
        DO_GEN_CALLBACK_WITH_RET(ctx, end_hash_cb, flags, level - 1, "end_hash");
        NEXT_CHAR(ctx);
        EAT_WHITESPACE(ctx, 0);
        return 1;
    }

    while (keep_going) {
        EAT_WHITESPACE(ctx, 0);
        this_char = PEEK_CHAR(ctx);
        
        DO_GEN_CALLBACK_WITH_RET(ctx, begin_hash_entry_cb, 0, level, "begin_hash_entry");

        /* this should be parse_string() or parse_identifier */
        if (this_char == '\'' || this_char == '"') {
            if (! parse_string(ctx, level, JSON_EVT_IS_HASH_KEY)) {
                JSON_DEBUG("parse_string() returned error");
                return 0;
            }
        }
        else {
            if (! parse_word(ctx, 1, level, JSON_EVT_IS_HASH_KEY) ) {
                JSON_DEBUG("parse_word() returned error");
                return 0;
            }
        }

        EAT_WHITESPACE(ctx, 0);
        this_char = PEEK_CHAR(ctx);

        if (this_char != ':') {
            JSON_DEBUG("parse error");
            SET_ERROR(ctx, "syntax error: bad object (missing ':')");
            return 0;
        }

        NEXT_CHAR(ctx);
        EAT_WHITESPACE(ctx, 0);

        JSON_DEBUG("looking at 0x%02x ('%c'), pos %u", PEEK_CHAR(ctx), PEEK_CHAR(ctx), ctx->pos);
        if (!parse_value(ctx, level, JSON_EVT_IS_HASH_VALUE)) {
            JSON_DEBUG("parse error in object");
            return 0;
        }

        DO_GEN_CALLBACK_WITH_RET(ctx, end_hash_entry_cb, 0, level, "end_hash_entry");

        EAT_WHITESPACE(ctx, 0);
        this_char = PEEK_CHAR(ctx);

        if (this_char == ',') {
            found_comma = 1;
            EAT_WHITESPACE(ctx, 1);
        }
        else {
            found_comma = 0;
        }

        this_char = PEEK_CHAR(ctx);
        switch (this_char) {
          case '}':
              DO_GEN_CALLBACK_WITH_RET(ctx, end_hash_cb, flags, level - 1, "end_hash");
              NEXT_CHAR(ctx);
              EAT_WHITESPACE(ctx, 0);
              return 1;
              break;

          default:
              if (! found_comma) {
                  SET_ERROR(ctx, "syntax error: bad object (missing ',' or '}')");
                  return 0;
              }
              break;
        }

    }
    SET_ERROR(ctx, "unknown error in parse_hash()");
    return 0;
}

static int
parse_value(json_context * ctx, uint level, uint flags) {
    uint this_char;

    SETUP_TRACE;
    PDB("HERE");

    EAT_WHITESPACE(ctx, 0);

    this_char = PEEK_CHAR(ctx);

    PDB("HERE - char is %#04x", this_char);

    /* JSON_DEBUG("parse_value() - pos %u, char %c", CUR_POS(ctx), this_char); */
    
    switch (this_char) {
      case '"':
      case '\'':
          return parse_string(ctx, level, flags);
          break;

      case '[':
          return parse_array(ctx, level, flags);
          break;

      case '{':
          PDB("Found hash");
          return parse_hash(ctx, level, flags);
          break;
          
      case '-':
      case '+':
          return parse_number(ctx, level, flags);
          break;

      default:
          if (this_char >= '0' && this_char <= '9') {
              return parse_number(ctx, level, flags);
          }

          return parse_word(ctx, 0, level, flags);
          break;
    }
    
    return 0;
}

jsonevt_ctx *
jsonevt_new_ctx() {
    jsonevt_ctx *ctx;
    /* JSONEVT_NEW(ctx, sizeof(jsonevt_ctx), jsonevt_ctx); */
    /* FIXME: - this may be where the "invalid pointer" (rt.cpan.org #47344) is coming from */
    JSONEVT_NEW(ctx, 1, jsonevt_ctx);
    ZERO_MEM((void *)ctx, sizeof(jsonevt_ctx));

    JSON_DEBUG("allocated new jsonevt_ctx %p", ctx);
    
    return ctx;
}

void
jsonevt_free_ctx(jsonevt_ctx * ext_ctx) {
    if (ext_ctx) {
        if (ext_ctx->error) {
            JSONEVT_FREE_MEM(ext_ctx->error);
            ext_ctx->error = NULL;
        }

        JSON_DEBUG("deallocating jsonevt_ctx %p", ext_ctx);        
        JSONEVT_FREE_MEM(ext_ctx);
        JSON_DEBUG("deallocated jsonevt_ctx %p", ext_ctx);
    }
}

void
jsonevt_reset_ctx(jsonevt_ctx * ctx) {
    void * cb_data;
    json_string_cb string_cb;
    json_array_begin_cb begin_array_cb;
    json_array_end_cb end_array_cb;
    json_array_begin_element_cb begin_array_element_cb;
    json_array_end_element_cb end_array_element_cb;
    json_hash_begin_cb begin_hash_cb;
    json_hash_end_cb end_hash_cb;
    json_hash_begin_entry_cb begin_hash_entry_cb;
    json_hash_end_entry_cb end_hash_entry_cb;
    json_number_cb number_cb;
    json_bool_cb bool_cb;
    json_null_cb null_cb;
    json_comment_cb comment_cb;

    uint options;
    uint bad_char_policy;

    UNLESS (ctx) {
        return;
    }

    ctx->ext_ctx = ctx;

    cb_data = ctx->cb_data;

    string_cb = ctx->string_cb;
    begin_array_cb = ctx->begin_array_cb;
    end_array_cb = ctx->end_array_cb;
    begin_array_element_cb = ctx->begin_array_element_cb;
    end_array_element_cb = ctx->end_array_element_cb;
    begin_hash_cb = ctx->begin_hash_cb;
    end_hash_cb = ctx->end_hash_cb;
    begin_hash_entry_cb = ctx->begin_hash_entry_cb;
    end_hash_entry_cb = ctx->end_hash_entry_cb;
    number_cb = ctx->number_cb;
    bool_cb = ctx->bool_cb;
    null_cb = ctx->null_cb;
    comment_cb = ctx->comment_cb;

    options = ctx->options;
    bad_char_policy = ctx->bad_char_policy;

    if (ctx->error) {
        JSONEVT_FREE_MEM(ctx->error);
        ctx->error = NULL;
    }

    ZERO_MEM((void *)ctx, sizeof(*ctx)); 

    ctx->cb_data = cb_data;

    ctx->string_cb = string_cb;
    ctx->begin_array_cb = begin_array_cb;
    ctx->end_array_cb = end_array_cb;
    ctx->begin_array_element_cb = begin_array_element_cb;
    ctx->end_array_element_cb = end_array_element_cb;
    ctx->begin_hash_cb = begin_hash_cb;
    ctx->end_hash_cb = end_hash_cb;
    ctx->begin_hash_entry_cb = begin_hash_entry_cb;
    ctx->end_hash_entry_cb = end_hash_entry_cb;
    ctx->number_cb = number_cb;
    ctx->bool_cb = bool_cb;
    ctx->null_cb = null_cb;
    ctx->comment_cb = comment_cb;

    ctx->options = options;
    ctx->bad_char_policy = bad_char_policy;

    ctx->cb_early_return_val = 0;
}

char *
jsonevt_get_error(jsonevt_ctx * ctx) {
    return ctx->error;
}

JSONEVT_INLINE_FUNC int
jsonevt_set_cb_data(jsonevt_ctx * ctx, void * data) {
    if (ctx) {
        ctx->cb_data = data;
        return 1;
    }

    return 0;
}

JSONEVT_INLINE_FUNC int
jsonevt_set_string_cb(jsonevt_ctx * ctx, json_string_cb callback) {
    if (ctx) {
        ctx->string_cb = callback;
        return 1;
    }

    return 0;
}

JSONEVT_INLINE_FUNC int
jsonevt_set_number_cb(jsonevt_ctx * ctx, json_number_cb callback) {
    if (ctx) {
        ctx->number_cb = callback;
        return 1;
    }

    return 0;
}

JSONEVT_INLINE_FUNC int
jsonevt_set_begin_array_cb(jsonevt_ctx * ctx, json_array_begin_cb callback) {
    if (ctx) {
        ctx->begin_array_cb = callback;
        return 1;
    }

    return 0;
}

JSONEVT_INLINE_FUNC int
jsonevt_set_end_array_cb(jsonevt_ctx * ctx, json_array_end_cb callback) {
    if (ctx) {
        ctx->end_array_cb = callback;
        return 1;
    }

    return 0;
}

JSONEVT_INLINE_FUNC int
jsonevt_set_begin_array_element_cb(jsonevt_ctx * ctx, json_array_begin_element_cb callback) {
    if (ctx) {
        ctx->begin_array_element_cb = callback;
        return 1;
    }

    return 0;
}

JSONEVT_INLINE_FUNC int
jsonevt_set_end_array_element_cb(jsonevt_ctx * ctx, json_array_end_element_cb callback) {
    if (ctx) {
        ctx->end_array_element_cb = callback;
        return 1;
    }

    return 0;
}

JSONEVT_INLINE_FUNC int
jsonevt_set_begin_hash_cb(jsonevt_ctx * ctx, json_hash_begin_cb callback) {
    if (ctx) {
        ctx->begin_hash_cb = callback;
        return 1;
    }

    return 0;
}

JSONEVT_INLINE_FUNC int
jsonevt_set_end_hash_cb(jsonevt_ctx * ctx, json_hash_end_cb callback) {
    if (ctx) {
        ctx->end_hash_cb = callback;
        return 1;
    }

    return 0;
}

JSONEVT_INLINE_FUNC int
jsonevt_set_begin_hash_entry_cb(jsonevt_ctx * ctx, json_hash_begin_entry_cb callback) {
    if (ctx) {
        ctx->begin_hash_entry_cb = callback;
        return 1;
    }

    return 0;
}

JSONEVT_INLINE_FUNC int
jsonevt_set_end_hash_entry_cb(jsonevt_ctx * ctx, json_hash_end_entry_cb callback) {
    if (ctx) {
        ctx->end_hash_entry_cb = callback;
    }

    return 0;
}

JSONEVT_INLINE_FUNC int
jsonevt_set_bool_cb(jsonevt_ctx * ctx, json_bool_cb callback) {
    if (ctx) {
        ctx->bool_cb = callback;
        return 1;
    }

    return 0;
}

JSONEVT_INLINE_FUNC int
jsonevt_set_null_cb(jsonevt_ctx * ctx, json_null_cb callback) {
    if (ctx) {
        ctx->null_cb = callback;
        return 1;
    }

    return 0;
}

JSONEVT_INLINE_FUNC int
jsonevt_set_comment_cb(jsonevt_ctx * ctx, json_comment_cb callback) {
    if (ctx) {
        ctx->comment_cb = callback;
        return 1;
    }

    return 0;
}

/*
JSONEVT_INLINE_FUNC int
jsonevt_set_options(jsonevt_ctx * ctx, uint options) {
    ctx->options = options;

    return 1;
}
*/

JSONEVT_INLINE_FUNC int
jsonevt_set_bad_char_policy(jsonevt_ctx * ctx, uint policy) {
    ctx->bad_char_policy = policy;
    
    return 1;
}

JSONEVT_INLINE_FUNC uint
jsonevt_get_error_line(jsonevt_ctx * ctx) {
    return ctx->error_line;
}

JSONEVT_INLINE_FUNC uint
jsonevt_get_error_char_col(jsonevt_ctx * ctx) {
    return ctx->error_char_col;
}

JSONEVT_INLINE_FUNC uint
jsonevt_get_error_byte_col(jsonevt_ctx * ctx) {
    return ctx->error_byte_col;
}

JSONEVT_INLINE_FUNC uint
jsonevt_get_error_char_pos(jsonevt_ctx * ctx) {
    return ctx->error_char_pos;
}

JSONEVT_INLINE_FUNC uint
jsonevt_get_error_byte_pos(jsonevt_ctx * ctx) {
    return ctx->error_byte_pos;
}

uint
jsonevt_get_stats_string_count(jsonevt_ctx * ctx) {
    return ctx->string_count;
}

uint
jsonevt_get_stats_longest_string_bytes(jsonevt_ctx * ctx) {
    return ctx->longest_string_bytes;
}

uint
jsonevt_get_stats_longest_string_chars(jsonevt_ctx * ctx) {
    return ctx->longest_string_chars;
}

uint
jsonevt_get_stats_number_count(jsonevt_ctx * ctx) {
    return ctx->number_count;
}

uint
jsonevt_get_stats_bool_count(jsonevt_ctx * ctx) {
    return ctx->bool_count;
}

uint
jsonevt_get_stats_null_count(jsonevt_ctx * ctx) {
    return ctx->null_count;
}

uint
jsonevt_get_stats_hash_count(jsonevt_ctx * ctx) {
    return ctx->hash_count;
}

uint
jsonevt_get_stats_array_count(jsonevt_ctx * ctx) {
    return ctx->array_count;
}

uint
jsonevt_get_stats_deepest_level(jsonevt_ctx * ctx) {
    return ctx->deepest_level;
}

uint
jsonevt_get_stats_line_count(jsonevt_ctx * ctx) {
    return ctx->line;
}

uint
jsonevt_get_stats_byte_count(jsonevt_ctx * ctx) {
    return ctx->byte_count;
}

uint
jsonevt_get_stats_char_count(jsonevt_ctx * ctx) {
    return ctx->char_count;
}

/*
JSONEVT_INLINE_FUNC uint
jsonevt_get_line_num(jsonevt_ctx * ctx) {
    return CUR_LINE(ctx);
}
*/

static int
check_bom(json_context * ctx) {
    uint len = ctx->len;
    const char * buf = ctx->buf;
    char * error_fmt = "found BOM for unsupported %s encoding -- this parser requires UTF-8";

    /* check for UTF BOM signature */
    /* The signature, if present, is the U+FEFF character encoded the
       same as the rest of the buffer.
       See <http://www.unicode.org/unicode/faq/utf_bom.html#25>.
    */
    if (len >= 1) {
        switch (*buf) {

          case '\xEF': /* maybe utf-8 */
              if (len >= 3 && MEM_EQ(buf, "\xEF\xBB\xBF", 3)) {
                  /* UTF-8 signature */

                  /* Move our position past the signature and parse as
                     if there were no signature, but this explicitly
                     indicates the buffer is encoded in utf-8
                  */
                  NEXT_CHAR(ctx);
                  NEXT_CHAR(ctx);

              }
              return 1;
              break;


              /* The rest, if present are not supported by this
                 parser, so reject with an error.
              */

          case '\xFE': /* maybe utf-16 big-endian */
              if (len >= 2 && MEM_EQ(buf, "\xFE\xFF", 2)) {
                  /* UTF-16BE */
                  SET_ERROR(ctx, error_fmt, "UTF-16BE");
                  return 0;
              }
              break;

          case '\xFF': /* maybe utf-16 little-endian or utf-32 little-endian */
              if (len >= 2) {
                  if (MEM_EQ(buf, "\xFF\xFE", 2)) {
                      /* UTF-16LE */
                      SET_ERROR(ctx, error_fmt, "UTF-16LE");
                      return 0;
                  }
                  else if (len >= 4) {
                      if (MEM_EQ(buf, "\xFF\xFE\x00\x00", 4)) {
                          /* UTF-32LE */
                          SET_ERROR(ctx, error_fmt, "UTF-32LE");
                          return 0;
                      }
                  }
              }
              break;

          case '\x00': /* maybe utf-32 big-endian */
              if (len >= 4) {
                  if (MEM_EQ(buf, "\x00\x00\xFE\xFF", 4)) {
                      /* UTF-32BE */
                      SET_ERROR(ctx, error_fmt, "UTF-32B");
                      return 0;
                  }
              }
              break;

          default:
              /* allow through */
              return 1;
              break;
        }

    }

    return 1;
}

int
jsonevt_parse(jsonevt_ctx * ext_ctx, const char * buf, uint len) {
    /* json_context ctx; */

    jsonevt_ctx * ctx = ext_ctx;
    int rv = 0;
    
    /* memzero((void *)&ctx, sizeof(ctx)); */

    jsonevt_reset_ctx(ctx);

    ctx->buf = buf;
    ctx->len = len;
    ctx->pos = 0;
    ctx->char_pos = 0;
    ctx->cur_line = 1;

    ctx->line = ctx->cur_line;
    ctx->byte_count = 0;
    ctx->char_count = 0;

    ctx->ext_ctx = ctx;

    /* ZERO_MEM( &(ctx->flags), sizeof(struct context_flags_struct) ); */

    if (check_bom(ctx)) {
        rv = parse_value(ctx, 0, 0);
        JSON_DEBUG("pos=%d, len=%d", ctx->pos, ctx->len);
        if (rv && ctx->pos < ctx->len) {
            EAT_WHITESPACE(ctx, 0);
            if (ctx->pos < ctx->len) {
                /* garbage at end */
                SET_ERROR(ctx, "syntax error - garbage at end of JSON");
                rv = 0;
            }
        }
    }

    ctx->line = ctx->cur_line;
    ctx->byte_count = ctx->cur_byte_pos;
    ctx->char_count = ctx->cur_char_pos;

    return rv;
}

void
jsonevt_get_version(uint *major, uint *minor, uint *patch) {
    if (major) {
        *major = JSON_EVT_MAJOR_VERSION;
    }

    if (minor) {
        *minor = JSON_EVT_MINOR_VERSION;
    }

    if (patch) {
        *patch = JSON_EVT_PATCH_LEVEL;
    }
}


int
jsonevt_parse_file(jsonevt_ctx * ext_ctx, const char * file) {
    int rv;
    char * buf = (char *)0;
    json_context ctx;
#ifdef USE_MMAP
    int fd;
    size_t file_size;
    struct stat file_info;

    /*
#if sizeof(file_info.st_size) > sizeof(file_size)
#endif
*/

    ZERO_MEM((void *)&ctx, sizeof(ctx));
    ctx.ext_ctx = ext_ctx;

    fd = open(file, O_RDONLY, 0);
    if (fd < 0) {
        JSON_DEBUG("couldn't open file %s", file);
        SET_ERROR(&ctx, "couldn't open input file %s", file);
        return 0;
    }

    if (fstat(fd, &file_info)) {
        JSON_DEBUG("couldn't stat %s", file);
        SET_ERROR(&ctx, "couldn't stat %s", file);
        close(fd);
        return 0;
    }

    file_size = file_info.st_size;

    /* MAP_FILE == 0 */
#ifndef MAP_PRIVATE
#define MAP_PRIVATE 2
#endif
    buf = (char *)mmap(NULL, file_size, PROT_READ, MAP_PRIVATE /*MAP_FIXED*/, fd, 0);
    if (buf == MAP_FAILED) {
        JSON_DEBUG("mmap failed.");
        SET_ERROR(&ctx, "mmap call failed for file %s", file);
        close(fd);
        return 0;
    }
#else
    FILE * fp;
    size_t file_size;
    size_t amtread;

    ZERO_MEM((void *)&ctx, sizeof(ctx));

    fp = fopen(file, "r");
    UNLESS (fp) {
        JSON_DEBUG("couldn't open input file %s", file);
        SET_ERROR(&ctx, "couldn't open input file %s", file);
        return 0;
    }

    fseek(fp, 0, SEEK_END);
    file_size = ftell(fp);
    fseek(fp, 0, SEEK_SET);

    JSONEVT_NEW(buf, file_size, char);

    /* FIXME: check for int overflow in file_size (size_t vs off_t) */
    amtread = fread((void *)buf, 1, file_size, fp);
    if (amtread != (size_t)file_size) {
        JSONEVT_FREE_MEM(buf);
        fclose(fp);
        JSON_DEBUG("got short read while slurping input file %s", file);
        SET_ERROR(&ctx, "got short read while slurping input file %s", file);
        return 0;
    }
#endif

    rv = jsonevt_parse(ext_ctx, buf, (uint)file_size);

#ifdef USE_MMAP
    if (munmap(buf, file_size)) {
        JSON_DEBUG("munmap failed.\n");
        SET_ERROR(&ctx, "munmap failed");
        close(fd);
        return 0;
    }

    close(fd);

#else
    JSONEVT_FREE_MEM(buf);
    fclose(fp);
#endif

    return rv;
}

void * _jsonevt_renew_with_log(void **ptr, size_t size, const char *var_name, unsigned int line_num,
    const char *func_name, const char *file_name) {

    fprintf(stderr, "realloc memory \"%s\" in %s, %s (%d) - %#"JSONEVT_PTR_xf" -> ", var_name,
        func_name, file_name, line_num, JSONEVT_PTR2UL(*ptr));
    fflush(stderr);
    if (*ptr) {
        *ptr = realloc(*ptr, size);
    }
    else {
        *ptr = malloc(size);
    }
    fprintf(stderr, "p = %#"JSONEVT_PTR_xf"\n", JSONEVT_PTR2UL(*ptr));
    fflush(stderr);

    return *ptr;
}

void * _jsonevt_renew(void **ptr, size_t size) {
    if (*ptr) {
        *ptr = realloc(*ptr, size);
    }
    else {
        *ptr = malloc(size);
    }

    return *ptr;
}

int
jsonevt_print_flags(uint flags, FILE *fp) {
    fd *f;
    int found = 0;

    if (fp == 0) {
        fp = stderr;
    }

    f = flag_data;
    for (f = flag_data; f->n; f++) {
        if (flags & f->val) {
            if (found) {
                fprintf(fp, " | ");
            }

            fprintf(fp, "%s", f->n);
            found = 1;
        }
    }

    if (found) {
        return 1;
    }
    else {
        return 0;
    }
}


#if !defined(JSONEVT_HAVE_FULL_VARIADIC_MACROS)
void JSON_DEBUG(char *fmt, ...) { }
void PDB(char *fmt, ...) { }
void JSON_TRACE(char *fmt, ...) { }
#endif
