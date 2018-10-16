/* *INDENT-ON* */
#ifdef __cplusplus
extern "C" {
#endif

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#define NEED_newRV_noinc
#include "ppport.h"
#include <sys/socket.h>
#include "maxminddb.h"

#define MATH_INT64_NATIVE_IF_AVAILABLE
#include "perl_math_int64.h"
#include "perl_math_int128.h"

#ifdef __cplusplus
}
#endif

static void iterate_record_entry(MMDB_s *mmdb, SV *data_callback,
                                 SV *node_callback, uint32_t node_num,
                                 mmdb_uint128_t ipnum, int depth,
                                 int max_depth, uint64_t record,
                                 uint8_t record_type,
                                 MMDB_entry_s *record_entry);

static SV *decode_bytes(MMDB_entry_data_s *entry_data)
{
    return newSVpvn((char *)entry_data->bytes, entry_data->data_size);
}

static SV *decode_simple_value(MMDB_entry_data_list_s **current)
{
    MMDB_entry_data_s entry_data = (*current)->entry_data;
    switch (entry_data.type) {
    case MMDB_DATA_TYPE_UTF8_STRING:
        return newSVpvn_utf8((char *)entry_data.utf8_string, entry_data.data_size, 1);
    case MMDB_DATA_TYPE_DOUBLE:
        return newSVnv(entry_data.double_value);
    case MMDB_DATA_TYPE_BYTES:
        return decode_bytes(&entry_data);
    case MMDB_DATA_TYPE_FLOAT:
        return newSVnv(entry_data.float_value);
    case MMDB_DATA_TYPE_UINT16:
        return newSVuv(entry_data.uint16);
    case MMDB_DATA_TYPE_UINT32:
        return newSVuv(entry_data.uint32);
    case MMDB_DATA_TYPE_INT32:
        return newSViv(entry_data.int32);
    case MMDB_DATA_TYPE_UINT64:
        return newSVu64(entry_data.uint64);
    case MMDB_DATA_TYPE_UINT128:
        /* We don't handle the case where uint128 is a byte array since even
         * the pure Perl MaxMind::DB::Reader requires Math::Int128, which in
         * turn requires GCC 4.4+. Therefore we know that we have an int128
         * type available if this code is compiling at all. */
        return newSVu128(entry_data.uint128);
    case MMDB_DATA_TYPE_BOOLEAN:
        /* Note to future coders - do not use PL_sv_yes, PL_sv_no, or bool_sv
         * - these all produce read-only SVs */
        return newSViv(entry_data.boolean);
    default:
        croak(
            "MaxMind::DB::Reader::XS - error decoding unknown type number %i",
            entry_data.type
            );
    }

    /* It shouldn't be possible to reach this. */
    return NULL;
}

static SV *decode_entry_data_list(MMDB_entry_data_list_s **entry_data_list);

static SV *decode_array(MMDB_entry_data_list_s **current)
{
    int size = (*current)->entry_data.data_size;

    AV *av = newAV();
    av_extend(av, size);
    for (uint i = 0; i < size; i++) {
        *current = (*current)->next;
        av_push(av, decode_entry_data_list(current));
    }

    return newRV_noinc((SV *)av);
}

static SV *decode_map(MMDB_entry_data_list_s **current)
{
    int size = (*current)->entry_data.data_size;

    HV *hv = newHV();
    hv_ksplit(hv, size);
    for (uint i = 0; i < size; i++) {
        *current = (*current)->next;
        char *key = (char *)(*current)->entry_data.utf8_string;
        int key_size = (*current)->entry_data.data_size;
        *current = (*current)->next;
        SV *val = decode_entry_data_list(current);
        (void)hv_store(hv, key, key_size, val, 0);
    }

    return newRV_noinc((SV *)hv);
}

static SV *decode_entry_data_list(MMDB_entry_data_list_s **current)
{
    switch ((*current)->entry_data.type) {
    case MMDB_DATA_TYPE_MAP:
        return decode_map(current);
    case MMDB_DATA_TYPE_ARRAY:
        return decode_array(current);
    default:
        return decode_simple_value(current);
    }
}

static SV *decode_and_free_entry_data_list(
    MMDB_entry_data_list_s *entry_data_list)
{
    MMDB_entry_data_list_s *current = entry_data_list;
    SV *sv = decode_entry_data_list(&current);
    MMDB_free_entry_data_list(entry_data_list);
    return sv;
}


static void call_node_callback(SV *node_callback, uint32_t node_num,
                               MMDB_search_node_s *node)
{
    if (!SvOK(node_callback)) {
        // nothing to do
        return;
    }

    dSP;

    ENTER;
    SAVETMPS;

    PUSHMARK(SP);
    EXTEND(SP, 3);
    mPUSHu(node_num);
    mPUSHs(newSVu64(node->left_record));
    mPUSHs(newSVu64(node->right_record));
    PUTBACK;

    call_sv(node_callback, G_VOID);

    FREETMPS;
    LEAVE;

    return;
}

static void call_data_callback(MMDB_s *mmdb, SV *data_callback,
                               mmdb_uint128_t ipnum, int depth,
                               MMDB_entry_s *record_entry)
{

    if (!SvOK(data_callback)) {
        // nothing to do
        return;
    }

    MMDB_entry_data_list_s *entry_data_list;
    int status = MMDB_get_entry_data_list(record_entry, &entry_data_list);
    if (MMDB_SUCCESS != status) {
        const char *error = MMDB_strerror(status);
        MMDB_free_entry_data_list(entry_data_list);
        croak(
            "MaxMind::DB::Reader::XS - Entry data error looking at offset %i: %s",
            record_entry->offset, error
            );
    }
    SV *decoded_entry = decode_and_free_entry_data_list(entry_data_list);

    dSP;

    ENTER;
    SAVETMPS;

    PUSHMARK(SP);
    EXTEND(SP, 3);
    mPUSHs(newSVu128(ipnum));
    mPUSHi(depth);
    mPUSHs(decoded_entry);
    PUTBACK;

    call_sv(data_callback, G_VOID);

    FREETMPS;
    LEAVE;

    return;
}

static void iterate_search_nodes(MMDB_s *mmdb, SV *data_callback,
                                  SV *node_callback, uint32_t node_num,
                                  mmdb_uint128_t ipnum,
                                  int depth,
                                  int max_depth)
{

    MMDB_search_node_s node;
    int status = MMDB_read_node(mmdb, node_num, &node);
    if (MMDB_SUCCESS != status) {
        const char *error = MMDB_strerror(status);
        croak(
            "MaxMind::DB::Reader::XS - Error reading node: %s",
            error
            );
    }

    call_node_callback(node_callback, node_num, &node);

    iterate_record_entry(mmdb, data_callback, node_callback, node_num, ipnum,
                         depth, max_depth, node.left_record,
                         node.left_record_type,
                         &node.left_record_entry);

    ipnum |= ((mmdb_uint128_t)1) << ( max_depth - depth );

    iterate_record_entry(mmdb, data_callback, node_callback, node_num, ipnum,
                         depth, max_depth, node.right_record,
                         node.right_record_type,
                         &node.right_record_entry);
}

static void iterate_record_entry(MMDB_s *mmdb, SV *data_callback,
                                 SV *node_callback, uint32_t node_num,
                                 mmdb_uint128_t ipnum, int depth,
                                 int max_depth, uint64_t record,
                                 uint8_t record_type,
                                 MMDB_entry_s *record_entry)
{

    switch (record_type) {
    case MMDB_RECORD_TYPE_INVALID:
        croak(
            "MaxMind::DB::Reader::XS - Invalid record when reading node"
            );
    case MMDB_RECORD_TYPE_SEARCH_NODE:
        iterate_search_nodes(mmdb, data_callback, node_callback, record,
                              ipnum, depth + 1, max_depth);
        return;
    case  MMDB_RECORD_TYPE_EMPTY:
        // We ignore empty branches of the search tree
        return;
    case MMDB_RECORD_TYPE_DATA:
        call_data_callback(mmdb, data_callback, ipnum, depth,
                           record_entry);
        return;
    default:
        croak("MaxMind::DB::Reader::XS - Unknown record type: %u",
              record_type);
    }
}

/* *INDENT-OFF* */

MODULE = MaxMind::DB::Reader::XS    PACKAGE = MaxMind::DB::Reader::XS

BOOT:
     PERL_MATH_INT64_LOAD_OR_CROAK;
     PERL_MATH_INT128_LOAD_OR_CROAK;

MMDB_s *
_open_mmdb(self, file, flags)
    char *file;
    U32 flags;
    PREINIT:
        MMDB_s *mmdb;
        uint16_t status;

    CODE:
        if (file == NULL) {
            croak("MaxMind::DB::Reader::XS - No file passed to _open_mmdb()\n");
        }
        mmdb = (MMDB_s *)malloc(sizeof(MMDB_s));
        status = MMDB_open(file, flags, mmdb);

        if (MMDB_SUCCESS != status) {
            const char *error = MMDB_strerror(status);
            free(mmdb);
            croak(
                "MaxMind::DB::Reader::XS - Error opening database file \"%s\": %s",
                file, error
                );
        }

        RETVAL = mmdb;
    OUTPUT:
        RETVAL

void
_close_mmdb(self, mmdb)
        MMDB_s *mmdb;
    CODE:
        MMDB_close(mmdb);
        free(mmdb);

SV *
_raw_metadata(self, mmdb)
        MMDB_s *mmdb
    PREINIT:
        MMDB_entry_data_list_s *entry_data_list;
    CODE:
        int status = MMDB_get_metadata_as_entry_data_list(mmdb, &entry_data_list);
        if (MMDB_SUCCESS != status) {
            const char *error = MMDB_strerror(status);
            MMDB_free_entry_data_list(entry_data_list);
            croak(
                "MaxMind::DB::Reader::XS - Error getting metadata: %s",
                error
                );
        }

        RETVAL = decode_and_free_entry_data_list(entry_data_list);
    OUTPUT:
        RETVAL

SV *
__data_for_address(self, mmdb, ip_address)
        MMDB_s *mmdb
        char *ip_address
    PREINIT:
        int gai_status, mmdb_status, get_status;
        MMDB_lookup_result_s result;
        MMDB_entry_data_list_s *entry_data_list;
    CODE:
        if (!ip_address || *ip_address == '\0') {
            croak("You must provide an IP address to look up");
        }

        result = MMDB_lookup_string(mmdb, ip_address, &gai_status, &mmdb_status);
        if (0 != gai_status) {
            croak(
                "The IP address you provided (%s) is not a valid IPv4 or IPv6 address",
                ip_address);
        }

        if (MMDB_SUCCESS != mmdb_status) {
            const char *mmdb_error = MMDB_strerror(mmdb_status);
            croak(
                "MaxMind::DB::Reader::XS - Error looking up IP address \"%s\": %s",
                ip_address, mmdb_error
                );
        }

        if (result.found_entry) {
            get_status = MMDB_get_entry_data_list(&result.entry, &entry_data_list);
            if (MMDB_SUCCESS != get_status) {
                const char *get_error = MMDB_strerror(get_status);
                MMDB_free_entry_data_list(entry_data_list);
                croak(
                    "MaxMind::DB::Reader::XS - Entry data error looking up \"%s\": %s",
                    ip_address, get_error
                    );
            }
            RETVAL = decode_and_free_entry_data_list(entry_data_list);
        } else {
            RETVAL = &PL_sv_undef;
        }
    OUTPUT:
        RETVAL

void
_iterate_search_tree(self, mmdb, data_callback, node_callback)
        MMDB_s *mmdb
        SV *data_callback;
        SV *node_callback;
    PREINIT:
        uint32_t node_num;
        int depth;
        int max_depth;
    CODE:
        node_num = 0;
        depth = 1;
        max_depth = mmdb->metadata.ip_version == 6 ? 128 : 32;
        mmdb_uint128_t ipnum = 0;

        iterate_search_nodes(mmdb, data_callback, node_callback, node_num,
            ipnum, depth, max_depth);

void
__read_node(self, mmdb, node_number)
        MMDB_s *mmdb
        U32 node_number
    PREINIT:
        MMDB_search_node_s node;
        int status;
    PPCODE:
        status = MMDB_read_node(mmdb, node_number, &node);
        if (MMDB_SUCCESS != status) {
            const char *error = MMDB_strerror(status);
            croak(
                "MaxMind::DB::Reader::XS - Error trying to read node %i: %s",
                node_number, error
                );
        }
        EXTEND(SP, 2);
        mPUSHu(node.left_record);
        mPUSHu(node.right_record);

SV *
libmaxminddb_version()
    CODE:
        const char *v = MMDB_lib_version();
        RETVAL = newSVpv(v, strlen(v));
    OUTPUT:
        RETVAL
