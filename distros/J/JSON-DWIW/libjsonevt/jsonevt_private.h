/* Creation date: 2007-07-18 00:51:42
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

/* $Revision$ */

#ifndef JSONEVT_PRIVATE_H
#define JSONEVT_PRIVATE_H

#include "jsonevt.h"
#include "utf8.h"
#include "print.h"
#include "jsonevt_utils.h"

JSON_DO_CPLUSPLUS_WRAP_BEGIN

#include <string.h>

typedef struct {
    char * buf;
    uint len;
} json_datum;

struct context_flags_struct {
    int have_char:1;
    int pad:7;
};

typedef struct json_extern_ctx json_context;

struct json_extern_ctx {
    const char * buf;
    uint len;
    uint pos;
    uint char_pos;

    char * error;
    uint error_byte_pos;
    uint error_char_pos;
    uint error_line;
    uint error_byte_col;
    uint error_char_col;
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

    uint string_count;
    uint longest_string_bytes;
    uint longest_string_chars;
    uint number_count;
    uint bool_count;
    uint null_count;
    uint hash_count;
    uint array_count;
    uint deepest_level;
    uint line;
    uint byte_count;
    uint char_count;

    uint options;
    uint bad_char_policy;

    uint cur_char;
    uint cur_char_len;
    uint cur_byte_pos;
    uint cur_char_pos;
    uint cur_line;
    uint cur_byte_col;
    uint cur_char_col;

    struct context_flags_struct flags;
    jsonevt_ctx * ext_ctx;

    int cb_early_return_val;
};

/*

typedef struct {
    char * buf;
    uint len;
    uint pos;
    uint char_pos;
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

    uint cur_char;
    uint cur_char_len;
    uint cur_byte_pos;
    uint cur_char_pos;
    uint cur_line;
    uint cur_byte_col;
    uint cur_char_col;

    uint options;
    uint bad_char_policy;

    struct context_flags_struct flags;
    jsonevt_ctx * ext_ctx;
} json_context;
*/

struct str_flags_struct {
    int using_orig:1;
    int pad:6;
};

typedef struct {
    char * buf;
    uint len;
    uint pos;
    char * stack_buf;
    uint stack_buf_len;
    struct str_flags_struct flags;
} json_str; /* used to build up string when parsing */

#define JSON_DO_DEBUG 0

#if defined(JSONEVT_HAVE_FULL_VARIADIC_MACROS)
#if JSON_DO_DEBUG
#define JSON_DEBUG(...) printf("in %s, %s (%d) - ", __func__, __FILE__, __LINE__); \
    printf(__VA_ARGS__);                                                \
    printf("\n"); fflush(stdout)
#else
/* FIXME: make this work under compilers not supporting variadic macros */
#define JSON_DEBUG(...)
#endif

#if JSON_DO_TRACE
#define JSON_TRACE(...) printf("%s (%d) - ", __FILE__, __LINE__); printf(__VA_ARGS__); printf("\n"); fflush(stdout)
#else
#define JSON_TRACE(...)
#endif

#else
void JSON_DEBUG(char *fmt, ...);
void JSON_TRACE(char *fmt, ...);
#endif

#if defined(JSONEVT_HAVE_FULL_VARIADIC_MACROS)
#if 0
#define PDB(...) fprintf(stderr, "in %s, line %d of %s: ", __func__, __LINE__, __FILE__); \
    fprintf(stderr, __VA_ARGS__); fprintf(stderr, "\n"); fflush(stderr)
#else
#define PDB(...)
#endif
#else
void PDB(char *fmt, ...);
#endif

#ifdef JSONEVT_ON_WINDOWS
#define JSONEVT_INLINE_FUNC
#else
#define JSONEVT_INLINE_FUNC inline
#endif

#ifdef JSONEVT_ON_WINDOWS
#define _CRT_SECURE_NO_WARNINGS
#endif



#define UNLESS(stuff) if (! stuff)

#define BUF_EQ(buf1, buf2, len) ( strncmp(buf1, buf2, len) == 0 )
#define MEM_EQ(buf1, buf2, len) ( memcmp(buf1, buf2, len) == 0 )

#define HEX_NIBBLE_TO_INT(nc) \
    ( nc >= '0' && nc <= '9' ? (int)(nc - '0') :                        \
        ( nc >= 'a' && nc <= 'f' ? (int)(nc - 'a' + 10) :               \
            ( nc >= 'A' && nc <= 'F' ? (int)(nc - 'A' + 10) : -1  )     \
          )                                                             \
      )


#define STATIC_BUF_SIZE 32

int js_asprintf(char ** ret, const char * fmt, ...);

#define ZERO_MEM(buf, buf_size) JSON_DEBUG("ZERO_MEM: buf=%p, size=%u", buf, buf_size); \
    memset(buf, 0, buf_size)
#define MEM_CPY(dst_buf, src_buf, size) JSON_DEBUG("MEM_CPY: dst=%p, src=%p, size=%u", \
        (dst_buf), (src_buf), (size));                                  \
    memcpy(dst_buf, src_buf, size)

/* linefeed or line separator */
#define JSON_IS_END_OF_LINE(ch) ( (ch) == 0x0a || (ch) == 0x2028)

#define NEXT_CHAR(c) (next_char(c))
#define PEEK_CHAR(ctx) ( (ctx)->flags.have_char ? (ctx)->cur_char : peek_char(ctx) )
#define PEEK_CHAR_LEN(c) (c->cur_char_len);

#define HAVE_MORE_CHARS(ctx) (ctx->pos >= ctx->len ? 0 : 1)
#define AT_END_OF_BUF(c) ( (c)->pos >= (c)->len )

#define GET_BUF(c) ((c)->buf)
#define GET_STACK_BUF(c) ((c)->stack_buf)
#define GET_STACK_BUF_LEN(s) ((s)->stack_buf_len)
#define USING_STACK_BUF(s) ((s)->stack_buf && (s)->buf == (s)->stack_buf)
#define USING_ORIG_BUF(s) ((s)->flags.using_orig)
#define CUR_POS(c) ((c)->cur_byte_pos)
#define CUR_CHAR(c) ( (c)->cur_char )
#define CUR_CHAR_POS(c) ((c)->cur_char_pos)
#define CUR_LINE(ctx) ((ctx)->cur_line)
#define CUR_COL(ctx) ((ctx)->cur_char_col)
#define CUR_BYTE_COL(ctx) ((ctx)->cur_byte_col)
#define CUR_BUF(c) (&c->buf[c->pos])
#define BUF_POS(c) ( (c)->pos )
#define BYTES_LEFT(c) ((c)->len - (c)->pos)
#define INIT_JSON_STR(s) ( ZERO_MEM(s, sizeof(json_str)) )

#define INCR_DATA_DEPTH(ctx, level) if (level > (ctx)->ext_ctx->deepest_level) \
        { (ctx)->ext_ctx->deepest_level = level; }

#define UPDATE_STATS_STRING_BYTES(ctx, len) if (len > (ctx)->ext_ctx->longest_string_bytes) \
        { (ctx)->ext_ctx->longest_string_bytes = len; }

#define UPDATE_STATS_STRING_CHARS(ctx, len) if (len > (ctx)->ext_ctx->longest_string_chars) \
        { (ctx)->ext_ctx->longest_string_chars = len; }


#define CLEAR_JSON_STR(s) JSON_DEBUG("CLEAR_JSON_STR() called: buf=%p, len=%u", (s)->buf, (s)->len); \
    if (! (USING_ORIG_BUF(s) || USING_STACK_BUF(s)) ) { JSON_DEBUG("CLEAR_JSON_STR() - calling free(%p)", (s)->buf); free((void *)((s)->buf)); (s)->buf = NULL; } JSON_DEBUG("CLEAR_JSON_STR() completed: buf=%p, len=%u", (s)->buf, (s)->len)

#define INIT_JSON_STR_STATIC_BUF(s, orig_buf, orig_len, st_buf, st_buf_len) \
    ZERO_MEM((void *)(s), sizeof(json_str)); (s)->flags.using_orig = 1;  \
    (s)->buf = (char *)(orig_buf); (s)->len = orig_len;                 \
    (s)->stack_buf = st_buf; (s)->stack_buf_len = st_buf_len;           \
    JSON_DEBUG("INIT_JSON_STR_STATIC_BUF() called, orig_buf=%p, orig_len=%u", orig_buf, orig_len)

#define ALLOC_NEW_BUF(s, size) (s)->buf = (char *)malloc(size); \
                                  (s)->len = size; \
                                  JSON_DEBUG("ALLOC_NEW_BUF() called for size %u, returning %p", \
                                      size, (s)->buf);

#define REALLOC_BUF(s, size) if (USING_STACK_BUF(s)) { switch_from_static_buf(s, size); } else { \
        JSON_DEBUG("reallocing %p", (s)->buf); JSONEVT_RENEW((s)->buf, size, char); (s)->len = size; }

#define SWITCH_FROM_STATIC(s) JSON_DEBUG("SWITCH_FROM_STATIC() called"); if (USING_ORIG_BUF(s)) { switch_from_static_buf(s, 0); }

#define GROW_JSON_STR(s, min_size) if (min_size > (s)->len) { \
        if (USING_ORIG_BUF(s)) { SWITCH_FROM_STATIC(s); REALLOC_BUF((s), min_size); } \
        else { REALLOC_BUF((s), min_size); } }

/*
#define GROW_JSON_STR(s, min_size) (min_size > (s)->len ? (USING_ORIG_BUF(s) ? \
            (SWITCH_TO_DYNAMIC(s), REALLOC_BUF((s), min_size)) : REALLOC_BUF((s), min_size)) : 0)
            */

#define APPEND_BYTES(s, bytes, len) GROW_JSON_STR(s, (s)->pos + len + 1); \
    MEM_CPY(&((s)->buf[(s)->pos]), bytes, len); (s)->pos += len; \
    JSON_DEBUG("APPEND_BYTES(): appended %u bytes to %p, starting at %p", \
        len, (s)->buf, &((s)->buf[(s)->pos]) )

#define MAYBE_APPEND_BYTES(s, bytes, len) if (USING_ORIG_BUF(s)) {      \
        (s)->pos += len; } else { APPEND_BYTES(s, bytes, len); }

#define EAT_WHITESPACE(s, f) eat_whitespace(s, f, __LINE__)

#define CB_OK_VAL 0
#define CB_IS_TERM(the_call) (the_call ? 1 : 0)
#define CB_SET_TERM_VAL(ctx, val) (ctx)->cb_early_return_val = val

#define DO_GEN_CALLBACK(ctx, c_name, flags, level) ( (ctx)->c_name ? \
        (ctx)->c_name((ctx)->cb_data, flags, level) : CB_OK_VAL)

#define DO_BOOL_CALLBACK(ctx, val, flags, level) ( (ctx)->bool_cb ?  \
        (ctx)->bool_cb((ctx)->cb_data, val, flags, level) : CB_OK_VAL)

#define SET_CB_ERROR(ctx, cb_name) set_error(ctx, __FILE__, __LINE__, \
            "early termination from %s callback", cb_name)

#define RET_CB_TERM(ctx, cb_name) SET_CB_ERROR(ctx, cb_name); return 0

/* return with early-termination code if the callback indicated we should do so */
#define DO_CB_WITH_RET(ctx, cb_name, the_call) if (CB_IS_TERM(the_call)) { RET_CB_TERM(ctx, cb_name); }

#define DO_BOOL_CALLBACK_WITH_RET(ctx, val, flags, level) \
    DO_CB_WITH_RET(ctx, "bool", DO_BOOL_CALLBACK(ctx, val, flags, level))

#define DO_GEN_CALLBACK_WITH_RET(ctx, c_name, flags, level, c_name_str) \
    DO_CB_WITH_RET(ctx, c_name_str, DO_GEN_CALLBACK(ctx, c_name, flags, level))

#define DO_COMMENT_CALLBACK(ctx, data, data_len, flags) ( (ctx)->comment_cb ? \
        (ctx)->comment_cb((ctx)->cb_data, data, data_len, flags, 0) : CB_OK_VAL )

#define DO_COMMENT_CALLBACK_WITH_RET(ctx, data, data_len, flags) \
    DO_CB_WITH_RET(ctx, "comment", DO_COMMENT_CALLBACK(ctx, data, data_len, flags))


JSON_DO_CPLUSPLUS_WRAP_END

#endif
