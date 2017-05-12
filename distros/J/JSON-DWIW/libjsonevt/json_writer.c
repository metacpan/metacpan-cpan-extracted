/* Creation date: 2008-11-27T07:33:50Z
 * Authors: Don
 */

/*

 Copyright (c) 2008-2010 Don Owens <don@regexguy.com>.  All rights reserved.

 This is free software; you can redistribute it and/or modify it under
 the Perl Artistic license.  You should have received a copy of the
 Artistic license with this distribution, in the file named
 "Artistic".  You may also obtain a copy from
 http://regexguy.com/license/Artistic

 This program is distributed in the hope that it will be useful, but
 WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

*/

/* $Header: /repository/projects/libjsonevt/json_writer.c,v 1.6 2009-04-21 06:21:44 don Exp $ */



#include "jsonevt_private.h"

#include <stdlib.h>
#include <string.h>
#include <stdio.h>
#include <stdarg.h>
#include <sys/types.h>

#define WR_TYPE_PREFIX \
    jsonevt_data_type type

typedef enum {
    unknown, str, array, hash, float_val, int_val, uint_val, bool_val, data
} jsonevt_data_type;

struct jsonevt_writer_data_struct {
    WR_TYPE_PREFIX;
};

struct jsonevt_float_struct {
    WR_TYPE_PREFIX;
    double val;
};

struct jsonevt_int_struct {
    WR_TYPE_PREFIX;
    long val;
};

struct jsonevt_uint_struct {
    WR_TYPE_PREFIX;
    unsigned long val;
};

struct jsonevt_bool_struct {
    WR_TYPE_PREFIX;
    int val;
};

struct jsonevt_string_struct {
    WR_TYPE_PREFIX;
    size_t size;
    char * data;
};

typedef struct {
    WR_TYPE_PREFIX; /* for debugging */
    size_t max_size;
    size_t used_size;
    char * data;
} _jsonevt_buf;

/* typedef struct jsonevt_str_struct json_str_ctx; */


struct json_array_flags {
    int started:1;
    int ended: 1;
    int pad:30;
};

struct jsonevt_array_struct {
    WR_TYPE_PREFIX;
    _jsonevt_buf * str_ctx;
    size_t count;
    struct json_array_flags flags;
};

struct json_hash_flags {
    int started:1;
    int ended: 1;
    int pad:30;
};

struct jsonevt_hash_struct {
    WR_TYPE_PREFIX;
    _jsonevt_buf * str_ctx;
    size_t count;
    struct json_hash_flags flags;
};


static void *
_json_malloc(size_t size) {
    return malloc(size);
}

static void *
_json_realloc(void *buf, size_t size) {
    return realloc(buf, size);
}

static char *
_json_ensure_buf_size(_jsonevt_buf * ctx, size_t size) {
    if (size == 0) {
        size = 1;
    }

    if (ctx->data == 0) {
        ctx->data = _json_malloc(size);
        ctx->max_size = size;
    }
    else if (size > ctx->max_size) {
        ctx->data = _json_realloc(ctx->data, size);
        ctx->max_size = size;
    }

    return ctx->data;
}

jsonevt_float *
jsonevt_new_float(double val) {
    jsonevt_float *ctx = _json_malloc(sizeof(jsonevt_float));

    memset(ctx, 0, sizeof(jsonevt_float));
    ctx->type = float_val;
    ctx->val = val;

    return ctx;
}

jsonevt_int *
jsonevt_new_int(long val) {
    jsonevt_int *ctx = _json_malloc(sizeof(jsonevt_int));
    
    memset(ctx, 0, sizeof(jsonevt_int));
    ctx->type = int_val;
    ctx->val = val;

    return ctx;
}

jsonevt_uint *
jsonevt_new_uint(unsigned long val) {
    jsonevt_uint *ctx = _json_malloc(sizeof(jsonevt_uint));
    
    memset(ctx, 0, sizeof(jsonevt_uint));
    ctx->type = uint_val;
    ctx->val = val;

    return ctx;
}

jsonevt_bool *
jsonevt_new_bool(int val) {
    jsonevt_bool *ctx = _json_malloc(sizeof(jsonevt_bool));

    memset(ctx, 0, sizeof(jsonevt_bool));
    ctx->type = bool_val;
    ctx->val = val;

    return ctx;
}

jsonevt_string *
jsonevt_new_string(char * buf, size_t size) {
    jsonevt_string * ctx = _json_malloc(sizeof(jsonevt_string));
    
    UNLESS (buf) {
        size = 0;
    }

    memset(ctx, 0, sizeof(jsonevt_string));
    ctx->type = str;
    ctx->size = size;
    ctx->data = (char *)_json_malloc(size + 1);
    
    memcpy(ctx->data, buf, size);
    ctx->data[size] = 0;

    return ctx;
}


static _jsonevt_buf *
json_new_buf(size_t size) {
    _jsonevt_buf * ctx = _json_malloc(sizeof(_jsonevt_buf));
    
    memset(ctx, 0, sizeof(_jsonevt_buf));
    ctx->type = data;

    if (size > 0) {
        _json_ensure_buf_size(ctx, size + 1);
    }

    return ctx;
}

static void
_json_free_buf(_jsonevt_buf * ctx) {

    if (! ctx) {
        return;
    }

    if (ctx->data) {
        free(ctx->data);
    }

    free(ctx);
}

static void
json_str_disown_buffer(_jsonevt_buf *ctx) {
    if (ctx) {
        memset(ctx, 0, sizeof(_jsonevt_buf));
    }
}

static int
json_append_bytes(_jsonevt_buf * ctx, char * data, size_t length) {
    size_t new_size;

    UNLESS (data) {
        length = 0;
    }

    if (ctx->max_size - ctx->used_size < length + 1) {
        new_size = length + 1 + ctx->used_size;
        _json_ensure_buf_size(ctx, new_size);
    }

    memcpy(&(ctx->data[ctx->used_size]), data, length);
    ctx->used_size += length;
    ctx->data[ctx->used_size] = '\x00';

    return 1;
}

static int
json_append_one_byte(_jsonevt_buf * ctx, char to_append) {
    return json_append_bytes(ctx, &to_append, 1);
}

static int
json_append_unicode_char(_jsonevt_buf * ctx, uint32_t code_point)  {
    uint32_t size = 0;
    uint8_t bytes[4];

    size = utf8_unicode_to_bytes(code_point, bytes);
    
    return json_append_bytes(ctx, (char *)bytes, size);
}

static char *
json_get_str_buffer(_jsonevt_buf * ctx, size_t * size) {
    if (size) {
        *size = ctx->used_size;
    }
    
    return ctx->data;
}

static _jsonevt_buf *
_json_escape_c_buffer(char * str, size_t length, unsigned long options) {
    _jsonevt_buf * ctx = json_new_buf(length + 1);
    size_t i;
    uint32_t this_char;
    char * tmp_buf = NULL;
    uint32_t char_len = 0;

    /* opening quotes */
    json_append_one_byte(ctx, '"');

    for (i = 0; i < length;) {
        this_char = utf8_bytes_to_unicode((uint8_t *)str + i, length - i - 1, &char_len);
        if (char_len == 0) {
            /* bad utf-8 sequence */
            /* for now, assume latin-1 and convert to utf-8 */
            char_len = 1;
            this_char = str[i];
        }

        i += char_len;

        switch (this_char) {
          case '\\':
              json_append_bytes(ctx, "\\\\", 2);
              break;

          case '"':
              json_append_bytes(ctx, "\\\"", 2);
              break;

          case '/':
              json_append_bytes(ctx, "\\/", 2);
              break;
              
          case 0x08:
              json_append_bytes(ctx, "\\b", 2);
              break;
              
          case 0x0c:
              json_append_bytes(ctx, "\\f", 2);
              break;
              
          case 0x0a:
              json_append_bytes(ctx, "\\n", 2);
              break;
              
          case 0x0d:
              json_append_bytes(ctx, "\\r", 2);
              break;
              
          case 0x09:
              json_append_bytes(ctx, "\\t", 2);
              break;
              

          default:
              if (this_char < 0x1f || ( this_char >= 0x80 && (options & JSON_EVT_OPTION_ASCII) ) ) {
                  /* FIXME: don't use js_asprintf -- instead convert
                     the bits directly to hex nibbles
                  */
                  js_asprintf(&tmp_buf, "\\u%04x", this_char);
                  json_append_bytes(ctx, tmp_buf, strlen(tmp_buf));
                  free(tmp_buf); tmp_buf = NULL;
              }
              else {
                  json_append_unicode_char(ctx, this_char);
              }

              break;
        }
    }


    /* closing quotes */
    json_append_one_byte(ctx, '"');

    return ctx;
}

char *
jsonevt_escape_c_buffer(char * in_buf, size_t length_in, size_t *length_out,
    unsigned long options) {

    _jsonevt_buf *str = _json_escape_c_buffer(in_buf, length_in, options);
    char *ret_buf;

    ret_buf = json_get_str_buffer(str, length_out);
    json_str_disown_buffer(str);
    _json_free_buf(str);

    return ret_buf;
}

jsonevt_array *
jsonevt_new_array() {
    jsonevt_array * ctx = _json_malloc(sizeof(jsonevt_array));
    memset(ctx, 0, sizeof(jsonevt_array));
    ctx->type = array;

    return ctx;
}

void
jsonevt_free_array(jsonevt_array * ctx) {
     UNLESS (ctx) {
        return;
    }

    if (ctx->str_ctx) {
        _json_free_buf(ctx->str_ctx);
    }

    free(ctx);
}

void
jsonevt_array_start(jsonevt_array * ctx) {
    UNLESS (ctx->flags.started) {
        ctx->str_ctx = json_new_buf(1);
        json_append_one_byte(ctx->str_ctx, '[');

        ctx->flags.started = 1;
    }
}

void
jsonevt_array_end(jsonevt_array * ctx) {
    json_append_one_byte(ctx->str_ctx, ']');
    ctx->flags.ended = 1;
}


char *
jsonevt_array_get_string(jsonevt_array * ctx, size_t * length_ptr) {
    UNLESS (ctx->str_ctx) {
        return NULL;
    }

    if (length_ptr) {
        *length_ptr = ctx->str_ctx->used_size;
    }

    return ctx->str_ctx->data;
}


int
jsonevt_array_append_raw_element(jsonevt_array * ctx, char * buf, size_t length) {
    UNLESS (ctx->flags.started) {
        ctx->str_ctx = json_new_buf(1 + length);
        json_append_one_byte(ctx->str_ctx, '[');
        ctx->flags.started = 1;
    }
    else if (ctx->count > 0) {
        json_append_one_byte(ctx->str_ctx, ',');
    }

    json_append_bytes(ctx->str_ctx, buf, length);
    ctx->count++;

    return 1;
}

int
jsonevt_array_append_buffer(jsonevt_array * ctx, char * buf, size_t length) {
    _jsonevt_buf * str_ctx = _json_escape_c_buffer(buf, length, JSON_EVT_OPTION_NONE);
    int rv;

    rv = jsonevt_array_append_raw_element(ctx, str_ctx->data, str_ctx->used_size);
    _json_free_buf(str_ctx);
    return rv;
}

int
jsonevt_array_append_string_buffer(jsonevt_array * array, char * buf) {
    return jsonevt_array_append_buffer(array, buf, strlen(buf));
}

int
jsonevt_array_add_data(jsonevt_array *dest, jsonevt_writer_data *src) {

    size_t src_len = 0;
    char *src_buf = 0;
    int rv = 0;

    src_buf = jsonevt_get_data_string(src, &src_len);

    rv = jsonevt_array_append_raw_element(dest, src_buf, src_len);

    /* FIXME: decide here whether to free data in src */

    return rv;
}

void
jsonevt_array_disown_buffer(jsonevt_array *array) {
    json_str_disown_buffer(array->str_ctx);
}

jsonevt_hash *
jsonevt_new_hash() {
    jsonevt_hash * ctx = (jsonevt_hash *)_json_malloc(sizeof(jsonevt_hash));
    memset(ctx, 0, sizeof(jsonevt_hash));
    ctx->type = hash;

    return ctx;
}

void
jsonevt_free_hash(jsonevt_hash * ctx) {
    UNLESS (ctx) {
        return;
    }

    if (ctx->str_ctx) {
        _json_free_buf(ctx->str_ctx);
    }

    free(ctx);
}

void
jsonevt_hash_start(jsonevt_hash * ctx) {
    if (! ctx->flags.started) {
        ctx->str_ctx = json_new_buf(0);
        json_append_one_byte(ctx->str_ctx, '{');
        ctx->flags.started = 1;
    }
}

void
jsonevt_hash_end(jsonevt_hash * ctx) {
    json_append_one_byte(ctx->str_ctx, '}');
}

char *
jsonevt_hash_get_string(jsonevt_hash * ctx, size_t * length_ptr) {
    if (! ctx->str_ctx) {
        return NULL;
    }

    if (length_ptr) {
        *length_ptr = ctx->str_ctx->used_size;
    }

    return ctx->str_ctx->data;
}

char *
jsonevt_string_get_string(jsonevt_string *ctx, size_t * length_ptr) {
    UNLESS (ctx->data) {
        return NULL;
    }

    if (length_ptr) {
        *length_ptr = ctx->size;
    }

    return ctx->data;
}

char *
jsonevt_get_data_string(jsonevt_writer_data *ctx, size_t *length_ptr) {
    UNLESS (ctx) {
        *length_ptr = 0;
        return NULL;
    }

    if (ctx->type == array) {
        return jsonevt_array_get_string((jsonevt_array *)ctx, length_ptr);
    }
    else if (ctx->type == hash) {
        return jsonevt_hash_get_string((jsonevt_hash *)ctx, length_ptr);
    }
    else if (ctx->type == str) {
        return jsonevt_string_get_string((jsonevt_string *)ctx, length_ptr);
    }

    *length_ptr = 0;
    return NULL;
}

int
jsonevt_hash_append_raw_entry(jsonevt_hash * ctx, char * key, size_t key_size, char * val,
    size_t val_size) {
    _jsonevt_buf * key_ctx = _json_escape_c_buffer(key, key_size, JSON_EVT_OPTION_NONE);

    if (! ctx->flags.started) {
        /* add 3 -- 1 for open brace, 1 for closing brace, one for the colon */
        ctx->str_ctx = json_new_buf(3 + key_ctx->used_size + val_size);
        json_append_one_byte(ctx->str_ctx, '{');
        ctx->flags.started = 1;
    }
    else if (ctx->count > 0) {
        json_append_one_byte(ctx->str_ctx, ',');
    }

    json_append_bytes(ctx->str_ctx, key_ctx->data, key_ctx->used_size);
    json_append_one_byte(ctx->str_ctx, ':');
    json_append_bytes(ctx->str_ctx, val, val_size);
    ctx->count++;

    _json_free_buf(key_ctx);

    return 1;
}

int
jsonevt_hash_append_buffer(jsonevt_hash * ctx, char * key, size_t key_size, char * val,
    size_t val_size) {
    _jsonevt_buf * val_ctx = _json_escape_c_buffer(val, val_size, JSON_EVT_OPTION_NONE);
    int rv;

    rv = jsonevt_hash_append_raw_entry(ctx, key, key_size, val_ctx->data, val_ctx->used_size);
    _json_free_buf(val_ctx);
    return rv;
}

int
jsonevt_hash_append_string_buffer(jsonevt_hash * hash, char * key, char * val) {
    return jsonevt_hash_append_buffer(hash, key, strlen(key), val, strlen(val));
}

void
jsonevt_hash_disown_buffer(jsonevt_hash *hash) {
    json_str_disown_buffer(hash->str_ctx);
}

int
jsonevt_hash_add_data(jsonevt_hash *dest, jsonevt_writer_data *src, char *key, size_t key_len) {

    size_t src_len = 0;
    char *src_buf = 0;
    int rv = 0;

    src_buf = jsonevt_get_data_string(src, &src_len);
    rv = jsonevt_hash_append_raw_entry(dest, key, key_len, src_buf, src_len);

    /* FIXME: decide here whether to free data in src */

    return rv;
}

int
jsonevt_do_unit_tests() {
    _jsonevt_buf * val_ctx;
    char *test_buf = "foo \x0a \"\xe7\x81\xab\" bar";
    char *expected_buf = NULL;
    char *rv = NULL;
    size_t length_in = 0;
    size_t length_out = 0;

    /* internal function */
    val_ctx = _json_escape_c_buffer(test_buf, strlen(test_buf), JSON_EVT_OPTION_NONE);
    
    expected_buf = "foo \x0a \\\"\xe7\x81\xab\\\" bar";

    printf("Internal: _json_escape_c_buffer()\n");
    printf("\tin: %s\n", test_buf);
    printf("\tout: %s\n", val_ctx->data);
    printf("\n");
    
    /* public function */
    printf("Public: jsonevt_escape_c_buffer()\n");
    
    length_in = strlen(test_buf);
    rv = jsonevt_escape_c_buffer(test_buf, length_in, &length_out,
        JSON_EVT_OPTION_NONE);
    printf("\tin (%u bytes): %s\n", (unsigned int)length_in, test_buf);
    printf("\tout (%u bytes): %s\n", (unsigned int)length_out, rv);

    return 0;
}
