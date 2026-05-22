/* --- Native protocol packet builders --- */

static char* build_native_hello(ev_clickhouse_t *self, size_t *out_len) {
    native_buf_t b;
    nbuf_init(&b);

    nbuf_varuint(&b, CLIENT_HELLO);
    nbuf_cstring(&b, CH_CLIENT_NAME);
    nbuf_varuint(&b, CH_CLIENT_VERSION_MAJOR);
    nbuf_varuint(&b, CH_CLIENT_VERSION_MINOR);
    nbuf_varuint(&b, CH_CLIENT_REVISION);
    nbuf_cstring(&b, self->database ? self->database : "default");
    nbuf_cstring(&b, self->user ? self->user : "default");
    nbuf_cstring(&b, self->password ? self->password : "");

    *out_len = b.len;
    return b.data;
}

static char* build_native_ping(size_t *out_len) {
    native_buf_t b;
    nbuf_init(&b);
    nbuf_varuint(&b, CLIENT_PING);
    *out_len = b.len;
    return b.data;
}

/* Write a Data-block info header (field_num=1 is_overflows + field_num=2
 * bucket_num=-1 + end marker). Required for revision >= DBMS_MIN_REVISION_WITH_BLOCK_INFO. */
static void nbuf_block_info(native_buf_t *b) {
    int32_t bucket = -1;
    nbuf_varuint(b, 1);  /* field_num = 1 */
    nbuf_u8(b, 0);       /* is_overflows = false */
    nbuf_varuint(b, 2);  /* field_num = 2 */
    nbuf_append(b, (const char *)&bucket, 4);  /* bucket_num = -1 */
    nbuf_varuint(b, 0);  /* end of block info */
}

/* Build an empty Data block (signals end of client data after Query) */
static void nbuf_empty_data_block(native_buf_t *b, int do_compress) {
    nbuf_varuint(b, CLIENT_DATA);
    nbuf_cstring(b, "");   /* table name — outside compression */

    /* block body: block info + num_cols + num_rows */
#ifdef HAVE_LZ4
    if (do_compress) {
        native_buf_t body;
        char *compressed;
        size_t comp_len;

        nbuf_init(&body);
        nbuf_block_info(&body);
        nbuf_varuint(&body, 0);    /* num_columns = 0 */
        nbuf_varuint(&body, 0);    /* num_rows = 0 */

        compressed = ch_lz4_compress(body.data, body.len, &comp_len);
        Safefree(body.data);
        if (compressed) {
            nbuf_append(b, compressed, comp_len);
            Safefree(compressed);
            return;
        }
        /* LZ4 failed (should never happen) — fall through to uncompressed */
    }
#else
    (void)do_compress;
#endif

    nbuf_block_info(b);
    nbuf_varuint(b, 0);    /* num_columns = 0 */
    nbuf_varuint(b, 0);    /* num_rows = 0 */
}

static char* build_native_query(ev_clickhouse_t *self, const char *sql,
                                 size_t sql_len, HV *defaults, HV *overrides,
                                 const char *ext_data, size_t ext_len,
                                 size_t *out_len) {
    native_buf_t b;
    const char *query_id = NULL;
    STRLEN query_id_len = 0;
    nbuf_init(&b);

    /* Pre-scan settings for query_id (needed before settings block) */
    {
        SV **svp;
        if (overrides && (svp = hv_fetch(overrides, "query_id", 8, 0)))
            query_id = SvPV(*svp, query_id_len);
        else if (defaults && (svp = hv_fetch(defaults, "query_id", 8, 0)))
            query_id = SvPV(*svp, query_id_len);
    }

    /* Query packet */
    nbuf_varuint(&b, CLIENT_QUERY);
    nbuf_string(&b, query_id ? query_id : "", query_id_len);

    /* Client info — field order must match ClientInfo::read() */
    nbuf_u8(&b, QUERY_INITIAL);
    nbuf_cstring(&b, "");  /* initial_user */
    nbuf_cstring(&b, "");  /* initial_query_id */
    nbuf_cstring(&b, "[::ffff:127.0.0.1]:0"); /* initial_address */

    /* initial_query_start_time_microseconds (revision >= 54449) */
    {
        uint64_t zero64 = 0;
        nbuf_append(&b, (const char *)&zero64, 8);
    }

    /* iface_type: 1=TCP, os_user, client_hostname, client_name */
    nbuf_u8(&b, 1);
    nbuf_cstring(&b, "");  /* os_user */
    nbuf_cstring(&b, "");  /* client_hostname */
    nbuf_cstring(&b, CH_CLIENT_NAME);
    nbuf_varuint(&b, CH_CLIENT_VERSION_MAJOR);
    nbuf_varuint(&b, CH_CLIENT_VERSION_MINOR);
    nbuf_varuint(&b, CH_CLIENT_REVISION);

    /* quota_key_in_client_info (always present, revision >= ~54060) */
    nbuf_cstring(&b, "");

    /* distributed_depth (revision >= 54448) */
    nbuf_varuint(&b, 0);

    /* version_patch (revision >= 54401) */
    nbuf_varuint(&b, 0);

    /* OpenTelemetry trace context (revision >= 54442): no trace */
    nbuf_u8(&b, 0);

    /* parallel_replicas (revision >= 54453) */
    nbuf_varuint(&b, 0);  /* collaborate_with_initiator */
    nbuf_varuint(&b, 0);  /* count_participating_replicas */
    nbuf_varuint(&b, 0);  /* number_of_current_replica */

    /* Settings (serialized as strings: revision >= 54429)
     * Format: repeated (String name, UInt8 is_important, String value),
     * terminated by empty name. */
    write_native_settings(&b, defaults, overrides);
    nbuf_cstring(&b, "");  /* empty name = end of settings */

    /* interserver_secret: empty string (revision >= 54441) */
    nbuf_cstring(&b, "");

    /* state (stage), compression, query */
    nbuf_varuint(&b, STAGE_COMPLETE);
#ifdef HAVE_LZ4
    nbuf_varuint(&b, self->compress ? 1 : 0);
#else
    nbuf_varuint(&b, 0);
#endif
    nbuf_string(&b, sql, sql_len);

    /* Parameters block: param_* keys, terminated by empty name. */
    write_native_params(&b, defaults, overrides);
    nbuf_cstring(&b, "");  /* end of parameters */

    /* External tables: named Data packets the query can reference as
     * tables, sent before the terminating empty block. */
    if (ext_data && ext_len) nbuf_append(&b, ext_data, ext_len);

    nbuf_empty_data_block(&b, self->compress);

    *out_len = b.len;
    return b.data;
}

