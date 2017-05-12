/* Creation date: 2007-07-13 20:56:30
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

#ifndef JSONEVT_H
#define JSONEVT_H

#include <sys/types.h>
#include <stdio.h>

#include <jsonevt_config.h>

#ifdef JSONEVT_DEF_HAVE_INTTYPES_H
#include <inttypes.h>
#else
#ifdef JSONEVT_DEF_HAVE_STDINT_H
#include <stdint.h>
#endif
#endif


#ifdef __cplusplus
#define JSON_DO_CPLUSPLUS_WRAP_BEGIN extern "C" {
#define JSON_DO_CPLUSPLUS_WRAP_END }
#else
#define JSON_DO_CPLUSPLUS_WRAP_BEGIN
#define JSON_DO_CPLUSPLUS_WRAP_END
#endif

JSON_DO_CPLUSPLUS_WRAP_BEGIN

#if defined(__WIN32) || defined(WIN32) || defined(_WIN32)
#define JSONEVT_ON_WINDOWS
#endif

#ifdef _MSC_VER
/* Microsoft Visual C++ */
#if _MSC_VER >= 1400
/* MS Visual C++ 2005 */
#define JSONEVT_HAVE_FULL_VARIADIC_MACROS
#define JSONEVT_HAVE_VARIADIC_MACROS
#endif

#if _MSC_VER < 1400
#define JSONEVT_NO_HAVE_VSNPRINTF
#endif

#endif

#if defined(__GNUC__) && !defined(__STRICT_ANSI__)
#define JSONEVT_HAVE_FULL_VARIADIC_MACROS
#define JSONEVT_HAVE_VARIADIC_MACROS
#endif

#undef JSONEVT_HAVE_FULL_VARIADIC_MACROS
#undef JSONEVT_HAVE_VARIADIC_MACROS

/* FIXME: probably should change this to ifdef HAVE_TYPE_UINT from jsonevt_config.h */
/* #ifdef JSONEVT_ON_WINDOWS */
#ifndef JSONEVT_DEF_HAVE_UINT
typedef unsigned int uint;
#endif

typedef struct json_extern_ctx jsonevt_ctx;

jsonevt_ctx * jsonevt_new_ctx();
void jsonevt_free_ctx(jsonevt_ctx * ctx);
void jsonevt_reset_ctx(jsonevt_ctx * ctx);
char * jsonevt_get_error(jsonevt_ctx * ctx);
int jsonevt_parse(jsonevt_ctx * ctx, const char * buf, uint len);
int jsonevt_parse_file(jsonevt_ctx * ctx, const char * file);

typedef int (*json_gen_cb)(void * cb_data, uint flags, uint level);

typedef int (*json_string_cb)(void * cb_data, const char * data, uint data_len,
    uint flags, uint level);
typedef int (*json_number_cb)(void * cb_data, const char * data, uint data_len,
    uint flags, uint level);
typedef int (*json_bool_cb)(void * cb_data, uint bool_val, uint flags, uint level);
typedef int (*json_comment_cb)(void * cb_data, const char * data, uint data_len,
    uint flags, uint level);

typedef json_gen_cb json_array_begin_cb;
typedef json_gen_cb json_array_end_cb;
typedef json_gen_cb json_array_begin_element_cb;
typedef json_gen_cb json_array_end_element_cb;
typedef json_gen_cb json_hash_begin_cb;
typedef json_gen_cb json_hash_end_cb;
typedef json_gen_cb json_hash_begin_entry_cb;
typedef json_gen_cb json_hash_end_entry_cb;
typedef json_gen_cb json_null_cb;

/*
    int string_callback(void * cb_data, const char * data, uint data_len, uint flags, uint level);

    int number_callback(void * cb_data, const char * data, uint data_len, uint flags, uint level);

    int array_begin_callback(void * cb_data, uint flags, uint level);

    int array_element_begin_callback(void * cb_data, uint flags, uint level);

    int array_element_end_callback(void * cb_data, uint flags, uint level);

    int array_end_callback(void * cb_data, uint flags, uint level);

    int hash_begin_callback(void * cb_data, uint flags, uint level);

    int hash_entry_begin_callback(void * cb_data, uint flags, uint level);

    int hash_entry_end_callback(void * cb_data, uint flags, uint level);

    int hash_end_callback(void * cb_data, uint flags, uint level);

    int bool_callback(void * cb_data, uint bool_val, uint flags, uint level);

    int null_callback(void * cb_data, uint flags, uint level);
*/

int jsonevt_set_cb_data(jsonevt_ctx * ctx, void * data);

int jsonevt_set_string_cb(jsonevt_ctx * ctx, json_string_cb callback);
int jsonevt_set_number_cb(jsonevt_ctx * ctx, json_number_cb callback);
int jsonevt_set_begin_array_cb(jsonevt_ctx * ctx, json_array_begin_cb callback);
int jsonevt_set_end_array_cb(jsonevt_ctx * ctx, json_array_end_cb callback);
int jsonevt_set_begin_array_element_cb(jsonevt_ctx * ctx, json_array_begin_element_cb callback);
int jsonevt_set_end_array_element_cb(jsonevt_ctx * ctx, json_array_end_element_cb callback);
int jsonevt_set_begin_hash_cb(jsonevt_ctx * ctx, json_hash_begin_cb callback);
int jsonevt_set_end_hash_cb(jsonevt_ctx * ctx, json_hash_end_cb callback);
int jsonevt_set_begin_hash_entry_cb(jsonevt_ctx * ctx, json_hash_begin_entry_cb callback);
int jsonevt_set_end_hash_entry_cb(jsonevt_ctx * ctx, json_hash_end_entry_cb callback);
int jsonevt_set_bool_cb(jsonevt_ctx * ctx, json_bool_cb callback);
int jsonevt_set_null_cb(jsonevt_ctx * ctx, json_null_cb callback);
int jsonevt_set_comment_cb(jsonevt_ctx * ctx, json_comment_cb callback);

/* int jsonevt_set_options(jsonevt_ctx * ctx, uint options); */
int jsonevt_set_bad_char_policy(jsonevt_ctx * ctx, uint policy);

/* use these to find out where an error occurred or where a callback
   terminated the parse early
*/
uint jsonevt_get_error_line(jsonevt_ctx * ctx);
uint jsonevt_get_error_char_col(jsonevt_ctx * ctx);
uint jsonevt_get_error_byte_col(jsonevt_ctx * ctx);
uint jsonevt_get_error_char_pos(jsonevt_ctx * ctx);
uint jsonevt_get_error_byte_pos(jsonevt_ctx * ctx);

uint jsonevt_get_stats_string_count(jsonevt_ctx * ctx);
uint jsonevt_get_stats_longest_string_bytes(jsonevt_ctx * ctx);
uint jsonevt_get_stats_longest_string_chars(jsonevt_ctx * ctx);
uint jsonevt_get_stats_number_count(jsonevt_ctx * ctx);
uint jsonevt_get_stats_bool_count(jsonevt_ctx * ctx);
uint jsonevt_get_stats_null_count(jsonevt_ctx * ctx);
uint jsonevt_get_stats_hash_count(jsonevt_ctx * ctx);
uint jsonevt_get_stats_array_count(jsonevt_ctx * ctx);
uint jsonevt_get_stats_deepest_level(jsonevt_ctx * ctx);
uint jsonevt_get_stats_line_count(jsonevt_ctx * ctx);
uint jsonevt_get_stats_byte_count(jsonevt_ctx * ctx);
uint jsonevt_get_stats_char_count(jsonevt_ctx * ctx);

void jsonevt_get_version(uint *major, uint *minor, uint *patch);

typedef struct {
    char *data;
    uint size;
    uint allocated;
} jsonevt_datum;

typedef struct {
    jsonevt_datum key;
    jsonevt_datum val;
} jsonevt_he_pair;

int jsonevt_util_parse_hash(const char *json_str, uint json_str_size, jsonevt_he_pair **ret_val,
    uint *num_entries, char **error);

#define JSONEVT_SET_DATUM(datum, buf, size) (datum)->data = buf; (datum)->size = size; \
    (datum)->allocated = 1;

void jsonevt_util_free_hash(jsonevt_he_pair *hash);

/* Use these inside a callback to find out where the parser is in the buffer/file. */
/* These will be implemented later. */
/*
uint jsonevt_get_line_num(jsonevt_ctx * ctx);
uint jsonevt_get_char_col(jsonevt_ctx * ctx);
uint jsonevt_get_byte_col(json_ctx * ctx);
uint jsonevt_get_char_pos(json_ctx * ctx);
uint jsonevt_get_byte_pos(json_ctx * ctx);
*/

#define JSON_EVT_PARSE_NUMBER_HAVE_SIGN     1
#define JSON_EVT_PARSE_NUMBER_HAVE_DECIMAL  (1 << 1)
#define JSON_EVT_PARSE_NUMBER_HAVE_EXPONENT (1 << 2)

#define JSON_EVT_IS_HASH_KEY          (1 << 3)
#define JSON_EVT_IS_HASH_VALUE        (1 << 4)
#define JSON_EVT_IS_ARRAY_ELEMENT     (1 << 5)
#define JSON_EVT_IS_C_COMMENT         (1 << 6)
#define JSON_EVT_IS_CPLUSPLUS_COMMENT (1 << 7)
#define JSON_EVT_IS_PERL_COMMENT      (1 << 8)

/* print names of the above flags that are in "flags" to stderr */
int jsonevt_print_flags(uint flags, FILE *fp);

#define JSON_EVT_OPTION_NONE                    0

#define JSON_EVT_OPTION_BAD_CHAR_POLICY_ERROR   0
#define JSON_EVT_OPTION_BAD_CHAR_POLICY_CONVERT 1
#define JSON_EVT_OPTION_BAD_CHAR_POLICY_PASS    (1 << 1)
#define JSON_EVT_OPTION_ASCII                   (1 << 2)

/* #define JSON_EVT_OPTION_CONVERT_BOOL             1 */

#define JSONEVT_ERR_UNEXPECTED_HASH 1000
#define JSONEVT_ERR_UNEXPECTED_ARRAY 1001
#define JSONEVT_ERR_UNEXPECTED_BOOL 1002
#define JSONEVT_ERR_UNEXPECTED_NULL 1003
#define JSONEVT_ERR_UNEXPECTED_STRING 1004
#define JSONEVT_ERR_UNEXPECTED_NUMBER 1005


/* defined in jsonevt_config.h, taken from autoconf values in config.h */
#define JSON_EVT_MAJOR_VERSION JSONEVT_MAJOR_VERSION
#define JSON_EVT_MINOR_VERSION JSONEVT_MINOR_VERSION
#define JSON_EVT_PATCH_LEVEL JSONEVT_PATCH_VERSION

/* writer */

typedef struct jsonevt_array_struct jsonevt_array;
typedef struct jsonevt_hash_struct jsonevt_hash;
typedef struct jsonevt_string_struct jsonevt_string;
typedef struct jsonevt_writer_data_struct jsonevt_writer_data;
typedef struct jsonevt_float_struct jsonevt_float;
typedef struct jsonevt_int_struct jsonevt_int;
typedef struct jsonevt_uint_struct jsonevt_uint;
typedef struct jsonevt_bool_struct jsonevt_bool;

jsonevt_float *jsonevt_new_float(double val);
jsonevt_int *jsonevt_new_int(long val);
jsonevt_uint *jsonevt_new_uint(unsigned long val);
jsonevt_bool *jsonevt_new_bool(int val);
jsonevt_string * json_new_string(char * buf, size_t size);

jsonevt_array * jsonevt_new_array();
void jsonevt_free_array(jsonevt_array * array);
void jsonevt_array_start(jsonevt_array * array);
void jsonevt_array_end(jsonevt_array * array);
int jsonevt_array_append_buffer(jsonevt_array * array, char * buf, size_t length);
int jsonevt_array_append_string_buffer(jsonevt_array * array, char * buf);
int jsonevt_array_append_raw_element(jsonevt_array * array, char * buf, size_t length);
char * jsonevt_array_get_string(jsonevt_array * array, size_t * length_ptr);
void jsonevt_array_disown_buffer(jsonevt_array *array);
int jsonevt_array_add_data(jsonevt_array *dest, jsonevt_writer_data *src);

jsonevt_hash * jsonevt_new_hash();
void jsonevt_free_hash(jsonevt_hash * hash);
void jsonevt_hash_start(jsonevt_hash * hash);
int jsonevt_hash_append_buffer(jsonevt_hash * hash, char * key, size_t key_size,
    char * val, size_t val_size);
int jsonevt_hash_append_string_buffer(jsonevt_hash * hash, char * key, char * val);
int jsonevt_hash_append_raw_entry(jsonevt_hash * hash, char * key, size_t key_size,
    char * val, size_t val_size);
char * jsonevt_hash_get_string(jsonevt_hash * hash, size_t * length_ptr);
void jsonevt_hash_disown_buffer(jsonevt_hash *hash);
int jsonevt_hash_add_data(jsonevt_hash *dest, jsonevt_writer_data *src, char *key, size_t key_len);

/* utility -- be careful when generating your own JSON */
char * jsonevt_escape_c_buffer(char *in_buf, size_t length_in, size_t *length_out,
    unsigned long options);

char * jsonevt_get_data_string(jsonevt_writer_data *ctx, size_t *length_ptr);

int jsonevt_do_unit_tests();

JSON_DO_CPLUSPLUS_WRAP_END

#endif

