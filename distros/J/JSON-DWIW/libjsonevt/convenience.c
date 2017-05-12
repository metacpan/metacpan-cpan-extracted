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

/* $Revision: 1461 $ */

/* Convenience functions */

#include <jsonevt_private.h>

#include <stdlib.h>
#include <string.h>


typedef struct {
    jsonevt_he_pair *entries;
    uint num_entries;
} parse_hash_cd;

static char *dup_str(const char *data, uint num_bytes, int pad_with_null) {
    uint size = 0;
    char *buf;

    size = pad_with_null ? num_bytes + 1 : num_bytes;
    buf = (char *)malloc(size);

    memcpy(buf, data, num_bytes);
    if (pad_with_null) {
        buf[num_bytes] = '\x00';
    }
    
    return buf;
}

#define JSONEVT_ALLOC_DATUM(d, buf, s, pad) (d).data = (char *)malloc(pad ? s + 1: s); \
    (d).size = (pad ? s + 1 : s); (d).allocated = 1; memcpy((d).data, buf, s)

static int
ph_add_hash_pair(void * cb_data, const char * data, uint data_len, uint flags, uint level) {
    parse_hash_cd *cd = (parse_hash_cd *)cb_data;
    jsonevt_he_pair *entry = 0;

    if (flags & JSON_EVT_IS_HASH_KEY) {

        if (cd->num_entries == 0) {
            cd->entries = (jsonevt_he_pair *)malloc(sizeof(jsonevt_he_pair) * 2);
            ZERO_MEM(cd->entries, sizeof(*(cd->entries)));
            ZERO_MEM(cd->entries + 1, sizeof(*(cd->entries)));

        }
        else {
            cd->entries = (jsonevt_he_pair *)realloc(cd->entries,
                sizeof(jsonevt_he_pair) * (cd->num_entries + 2));
        }
        
        ZERO_MEM(&cd->entries[cd->num_entries + 1], sizeof(*(cd->entries)));
        
        cd->num_entries += 1;

        entry = &cd->entries[cd->num_entries - 1];

        JSONEVT_ALLOC_DATUM(entry->key, data, data_len, 1);
    }
    else if (flags & JSON_EVT_IS_HASH_VALUE) {
        entry = &cd->entries[cd->num_entries - 1];
        JSONEVT_ALLOC_DATUM(entry->val, data, data_len, 1);
    }

    return 0;
}

static int
ph_string_callback(void * cb_data, const char * data, uint data_len, uint flags, uint level) {
    if (level != 1) {
        return JSONEVT_ERR_UNEXPECTED_STRING;
    }

    return ph_add_hash_pair(cb_data, data, data_len, flags, level);
}

static int
ph_number_callback(void * cb_data, const char * data, uint data_len, uint flags, uint level) {
    if (level != 1) {
        return JSONEVT_ERR_UNEXPECTED_NUMBER;
    }

    return ph_add_hash_pair(cb_data, data, data_len, flags, level);
}

static int
ph_array_begin_callback(void * cb_data, uint flags, uint level) {
    return JSONEVT_ERR_UNEXPECTED_ARRAY;
}

static int
ph_hash_begin_callback(void * cb_data, uint flags, uint level) {
    if (level != 0) {
        return JSONEVT_ERR_UNEXPECTED_HASH;
    }

    return 0;
}

static int
ph_bool_callback(void * cb_data, uint bool_val, uint flags, uint level) {
    return JSONEVT_ERR_UNEXPECTED_BOOL;
}

static int
ph_null_callback(void * cb_data, uint flags, uint level) {
    return JSONEVT_ERR_UNEXPECTED_NULL;
}

void
jsonevt_util_free_hash(jsonevt_he_pair *hash) {
    jsonevt_he_pair *p;

    if (!hash) {
        return;
    }

    for (p = hash; p->key.allocated; p++) {
        if (p->key.data) {
            free(p->key.data);
        }
        if (p->val.data) {
            free(p->val.data);
        }
    }

    free(hash);
}

int
jsonevt_util_parse_hash(const char *json_str, uint json_str_size, jsonevt_he_pair **ret_val,
    uint *num_entries, char **error_out) {

    jsonevt_ctx * ctx = 0;
    char *error = NULL;
    int rv = 1;
    parse_hash_cd cb_data;

    ZERO_MEM(&cb_data, sizeof(cb_data));

    ctx = jsonevt_new_ctx();

    jsonevt_set_cb_data(ctx, &cb_data);

    jsonevt_set_string_cb(ctx, ph_string_callback);
    jsonevt_set_number_cb(ctx, ph_number_callback);
    jsonevt_set_begin_array_cb(ctx, ph_array_begin_callback);
    jsonevt_set_begin_hash_cb(ctx, ph_hash_begin_callback);
    jsonevt_set_bool_cb(ctx, ph_bool_callback);
    jsonevt_set_null_cb(ctx, ph_null_callback);

    
    if (! jsonevt_parse(ctx, json_str, json_str_size) ) {
        error = jsonevt_get_error(ctx);
        if (error_out) {
            *error_out = dup_str(error, strlen(error), 1);
        }
        rv = 0;
        if (cb_data.entries) {
            jsonevt_util_free_hash(cb_data.entries);
        }
    }
    else {
        rv = 1;
        if (error_out) {
            *error_out = 0;
        }
        *ret_val = cb_data.entries;
        *num_entries = cb_data.num_entries;
    }

    jsonevt_free_ctx(ctx); ctx = 0;


    return rv;
}
