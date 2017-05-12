// Creation date: 2008-09-28T00:25:45Z
// Authors: Don

#include <jsonevt++.h>

#include <string.h>

typedef struct {
    std::vector<std::string> *list;
} pas_cb;

static int
pas_string_callback(void * cb_data, const char * data, uint data_len, uint flags, uint level) {
    pas_cb *cb = (pas_cb *)cb_data;
    std::string str;

    if (level != 1) {
        return JSONEVT_ERR_UNEXPECTED_STRING;
    }

    str.assign(data, (size_t)data_len);
    cb->list->push_back(str);

    return 0;
}

static int
pas_number_callback(void * cb_data, const char * data, uint data_len, uint flags, uint level) {
    pas_cb *cb = (pas_cb *)cb_data;
    std::string str;

    if (level != 1) {
        return JSONEVT_ERR_UNEXPECTED_NUMBER;
    }

    str.assign(data, (size_t)data_len);
    cb->list->push_back(str);
}

static int
pas_array_begin_callback(void * cb_data, uint flags, uint level) {
    if (level != 0) {
        return JSONEVT_ERR_UNEXPECTED_ARRAY;
    }

    return 0;
}

static int
pas_hash_begin_callback(void * cb_data, uint flags, uint level) {
    return JSONEVT_ERR_UNEXPECTED_HASH;
}

static int
pas_bool_callback(void * cb_data, uint bool_val, uint flags, uint level) {
    return JSONEVT_ERR_UNEXPECTED_BOOL;
}

static int
pas_null_callback(void * cb_data, uint flags, uint level) {
    return JSONEVT_ERR_UNEXPECTED_NULL;
}

int
JSONEvt::parse_list_of_strings(const std::string& json_str,
    std::vector<std::string>& result, std::string &err_out) {

    const char *json;
    uint json_str_size;

    json = json_str.c_str();
    json_str_size = (uint)json_str.size();

    return JSONEvt::parse_list_of_strings(json, json_str_size, result, err_out);
}

int
JSONEvt::parse_list_of_strings(const char *json_str, uint json_str_size,
    std::vector<std::string>& result, std::string &err_out) {
    
    jsonevt_ctx * ctx = 0;
    char *error = NULL;
    int rv = 1;
    pas_cb cb_data;

    memset(&cb_data, 0, sizeof(cb_data));
    cb_data.list = &result;

    ctx = jsonevt_new_ctx();

    jsonevt_set_cb_data(ctx, &cb_data);

    jsonevt_set_string_cb(ctx, pas_string_callback);
    jsonevt_set_number_cb(ctx, pas_number_callback);
    jsonevt_set_begin_array_cb(ctx, pas_array_begin_callback);
    jsonevt_set_begin_hash_cb(ctx, pas_hash_begin_callback);
    jsonevt_set_bool_cb(ctx, pas_bool_callback);
    jsonevt_set_null_cb(ctx, pas_null_callback);

    
    if (! jsonevt_parse(ctx, json_str, json_str_size) ) {
        error = jsonevt_get_error(ctx);
        err_out.assign(error);
        rv = 0;
    }
    else {
        rv = 1;
    }

    jsonevt_free_ctx(ctx); ctx = 0;


    return rv;
}
