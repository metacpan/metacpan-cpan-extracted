/* --- Native protocol response parser --- */

/*
 * Skip block info fields (revision >= DBMS_MIN_REVISION_WITH_BLOCK_INFO).
 * Returns 1 on success, 0 if need more data.
 */
static int skip_block_info(const char *buf, size_t len, size_t *pos) {
    for (;;) {
        uint64_t field_num;
        int rc = read_varuint(buf, len, pos, &field_num);
        if (rc == 0) return 0;
        if (rc < 0) return -1;
        if (field_num == 0) return 1;  /* end marker */
        if (field_num == 1) {
            /* is_overflows: UInt8 */
            uint8_t dummy;
            rc = read_u8(buf, len, pos, &dummy);
            if (rc <= 0) return rc;
        } else if (field_num == 2) {
            /* bucket_num: Int32 */
            int32_t dummy;
            rc = read_i32(buf, len, pos, &dummy);
            if (rc <= 0) return rc;
        } else {
            return -1;  /* protocol error */
        }
    }
}

/*
 * Try to parse one server packet from recv_buf.
 * Returns:
 *   1  = packet consumed, continue reading
 *   0  = need more data
 *  -1  = error (message in *errmsg, caller must Safefree)
 *   2  = EndOfStream
 *   3  = Pong
 *   4  = Hello parsed (self->server_* fields populated)
 */

/* Parse a Data block (table_name + optional-LZ4-chain + block_info + columns)
 * and decode-and-discard each column. Used by SERVER_LOG and SERVER_PROFILE_EVENTS,
 * which carry a block in the same wire format as SERVER_DATA but whose contents
 * the client does not surface to Perl.
 *
 * `lz4_optional` (used by PROFILE_EVENTS only): if set, fall back to parsing
 * the body uncompressed when LZ4 hard-fails — older servers occasionally send
 * profile_events uncompressed even on a compressed connection.
 *
 * Returns 1 on success (advances *outer_pos past the consumed bytes),
 *         0 on need-more-data,
 *        -1 on hard error (sets *errmsg). */
static int parse_and_discard_block(ev_clickhouse_t *self,
                                    const char *buf, size_t len, size_t *outer_pos,
                                    const char *kind, int lz4_optional,
                                    char **errmsg) {
    size_t pos = *outer_pos;
    int rc;
    char *decompressed = NULL;
    int more_maybe = 0;  /* chain stopped mid-frame: short block = need-more */
    const char *bbuf;
    size_t blen, bpos;
    char errbuf[64];

    rc = skip_native_string(buf, len, &pos);
    if (rc == 0) return 0;
    if (rc < 0) {
        snprintf(errbuf, sizeof(errbuf), "malformed %s block", kind);
        *errmsg = safe_strdup(errbuf);
        return -1;
    }

#ifdef HAVE_LZ4
    if (self->compress) {
        int need_more = 0;
        const char *lz4_err = NULL;
        decompressed = ch_lz4_decompress_chain(buf, len, &pos, &blen,
                                                &need_more, &lz4_err,
                                                &more_maybe);
        if (!decompressed) {
            if (need_more) return 0;
            if (!lz4_optional) {
                snprintf(errbuf, sizeof(errbuf), "%s: LZ4 decompression failed", kind);
                *errmsg = safe_strdup(lz4_err ? lz4_err : errbuf);
                return -1;
            }
            /* fall through to uncompressed parsing */
        }
    }
    if (decompressed) {
        bbuf = decompressed;
        bpos = 0;
    } else
#endif
    {
        bbuf = buf;
        blen = len;
        bpos = pos;
    }

#define _BAIL(rc_val) do { \
    if (decompressed) Safefree(decompressed); \
    if (rc_val < 0) { snprintf(errbuf, sizeof(errbuf), "malformed %s block", kind); *errmsg = safe_strdup(errbuf); } \
    return rc_val; \
} while (0)

    if (self->server_revision >= DBMS_MIN_REVISION_WITH_BLOCK_INFO) {
        rc = skip_block_info(bbuf, blen, &bpos);
        if (rc <= 0) _BAIL(rc);
    }
    {
        uint64_t nc, nr, c;
        rc = read_varuint(bbuf, blen, &bpos, &nc);
        if (rc <= 0) _BAIL(rc);
        rc = read_varuint(bbuf, blen, &bpos, &nr);
        if (rc <= 0) _BAIL(rc);

        for (c = 0; c < nc; c++) {
            const char *ctype;
            size_t ctype_len;
            rc = skip_native_string(bbuf, blen, &bpos);
            if (rc <= 0) _BAIL(rc);
            rc = read_native_string_ref(bbuf, blen, &bpos, &ctype, &ctype_len);
            if (rc <= 0) _BAIL(rc);
            /* custom serialization flag (revision >= 54446) */
            if (bpos >= blen) _BAIL(0);
            if ((uint8_t)bbuf[bpos]) {
                if (decompressed) Safefree(decompressed);
                *errmsg = safe_strdup("custom serialization not supported");
                return -1;
            }
            bpos++;
            if (nr > 0) {
                col_type_t *ct = parse_col_type(ctype, ctype_len);
                int col_err = 0;
                /* lc_self is NULL: a LowCardinality column with an inherited
                 * dictionary hard-errors here. Real log schemas have none. */
                SV **vals = decode_column(bbuf, blen, &bpos, nr, ct, &col_err, 0);
                if (!vals) {
                    free_col_type(ct);
                    if (col_err || (decompressed && !more_maybe)) {
                        if (decompressed) Safefree(decompressed);
                        snprintf(errbuf, sizeof(errbuf), "malformed %s block", kind);
                        *errmsg = safe_strdup(errbuf);
                        return -1;
                    }
                    if (decompressed) Safefree(decompressed);
                    return 0;
                }
                {
                    uint64_t j;
                    for (j = 0; j < nr; j++) SvREFCNT_dec(vals[j]);
                }
                Safefree(vals);
                free_col_type(ct);
            }
        }
    }

#undef _BAIL

    if (!decompressed) pos = bpos;
    if (decompressed) Safefree(decompressed);
    *outer_pos = pos;
    return 1;
}

/* Like parse_and_discard_block, but for each row of the block invokes
 * `cb` with one hashref keyed by column name. Used by on_log.
 * Caller has already verified cb is non-NULL. */
static int parse_and_emit_log_block(ev_clickhouse_t *self,
                                     const char *buf, size_t len, size_t *outer_pos,
                                     SV *cb, char **errmsg) {
    size_t pos = *outer_pos;
    int rc;
    char *decompressed = NULL;
    const char *bbuf;
    size_t blen, bpos;

    rc = skip_native_string(buf, len, &pos);
    if (rc == 0) return 0;
    if (rc < 0) { *errmsg = safe_strdup("malformed log block"); return -1; }

#ifdef HAVE_LZ4
    if (self->compress) {
        int need_more = 0;
        const char *lz4_err = NULL;
        /* NULL: a short block here is already treated as need-more. */
        decompressed = ch_lz4_decompress_chain(buf, len, &pos, &blen,
                                                &need_more, &lz4_err, NULL);
        if (!decompressed) {
            if (need_more) return 0;
            /* server log frames are not always compressed even with
             * compress=1 negotiated — fall through to raw parsing. */
        }
    }
    if (decompressed) { bbuf = decompressed; bpos = 0; }
    else
#endif
    { bbuf = buf; blen = len; bpos = pos; }

#define _BAIL_LOG(rc_val) do { \
    if (decompressed) Safefree(decompressed); \
    if (rc_val < 0) { *errmsg = safe_strdup("malformed log block"); } \
    return rc_val; \
} while (0)

    if (self->server_revision >= DBMS_MIN_REVISION_WITH_BLOCK_INFO) {
        rc = skip_block_info(bbuf, blen, &bpos);
        if (rc <= 0) _BAIL_LOG(rc);
    }
    uint64_t nc, nr;
    rc = read_varuint(bbuf, blen, &bpos, &nc);
    if (rc <= 0) _BAIL_LOG(rc);
    rc = read_varuint(bbuf, blen, &bpos, &nr);
    if (rc <= 0) _BAIL_LOG(rc);

    /* Collect column name + decoded values, then assemble per-row HVs. */
    char     **names = NULL;
    SV      ***data  = NULL;     /* data[col][row] */
    if (nc > 0) {
        /* A column occupies at least one wire byte (its name-length varint),
         * so more columns than remaining bytes is malformed — reject before
         * the allocation rather than letting Newxz attempt a huge size. */
        if (nc > (uint64_t)(blen - bpos)) _BAIL_LOG(-1);
        Newxz(names, nc, char *);
        Newxz(data,  nc, SV **);
    }
    /* err_seen: -1 = malformed, 0 = success / need-more, +1 = all columns
     * parsed cleanly. We distinguish "loop completed all nc columns" from
     * "loop broke early needing more data" via the explicit flag rather
     * than inspecting bpos, since bpos always advances past the header. */
    int err_seen = 1;
    for (uint64_t c = 0; c < nc; c++) {
        const char *cname; size_t cname_len;
        rc = read_native_string_ref(bbuf, blen, &bpos, &cname, &cname_len);
        if (rc <= 0) { err_seen = rc < 0 ? -1 : 0; break; }
        Newx(names[c], cname_len + 1, char);
        Copy(cname, names[c], cname_len, char);
        names[c][cname_len] = '\0';

        const char *ctype; size_t ctype_len;
        rc = read_native_string_ref(bbuf, blen, &bpos, &ctype, &ctype_len);
        if (rc <= 0) { err_seen = rc < 0 ? -1 : 0; break; }
        if (bpos >= blen) { err_seen = 0; break; }
        if ((uint8_t)bbuf[bpos]) { err_seen = -1; break; }
        bpos++;
        if (nr > 0) {
            col_type_t *ct = parse_col_type(ctype, ctype_len);
            int col_err = 0;
            /* lc_self is NULL: a LowCardinality column with an inherited
             * dictionary hard-errors here. Real log schemas have none. */
            SV **vals = decode_column(bbuf, blen, &bpos, nr, ct, &col_err, 0);
            free_col_type(ct);
            if (!vals) { err_seen = col_err ? -1 : 0; break; }
            data[c] = vals;
        }
    }

    if (err_seen == 1) {
        /* Pin cb across the loop: an on_log handler that calls
         * $ch->on_log(undef) would otherwise free the CV mid-iteration. */
        SvREFCNT_inc(cb);
        self->callback_depth++;
        for (uint64_t r = 0; r < nr; r++) {
            HV *row = newHV();
            for (uint64_t c = 0; c < nc; c++) {
                SV *v = data[c][r];
                SvREFCNT_inc(v);    /* hv_store consumes one ref */
                (void)hv_store(row, names[c], strlen(names[c]), v, 0);
            }
            dSP;
            ENTER; SAVETMPS; PUSHMARK(SP);
            EXTEND(SP, 1);
            PUSHs(sv_2mortal(newRV_noinc((SV *)row)));
            PUTBACK;
            call_sv(cb, G_EVAL | G_VOID | G_DISCARD);
            WARN_AND_CLEAR_ERRSV("on_log");
            FREETMPS; LEAVE;
            /* freed state is authoritatively handled by check_destroyed below */
            if (self->magic == EV_CH_FREED) break;
        }
        /* Drop the cb pin BEFORE callback_depth-- : dropping the last ref
         * to the on_log CV (a handler may have reassigned on_log) can free
         * a closure that captured $ch, triggering DESTROY. Doing it while
         * callback_depth is still raised keeps Safefree(self) deferred so
         * the check_destroyed below can detect and finalize it. */
        SvREFCNT_dec(cb);
        self->callback_depth--;
    }

    /* Free locally-collected SVs + names regardless of self's state. */
    for (uint64_t c = 0; c < nc; c++) {
        if (data && data[c]) {
            for (uint64_t r = 0; r < nr; r++) SvREFCNT_dec(data[c][r]);
            Safefree(data[c]);
        }
        if (names && names[c]) Safefree(names[c]);
    }
    if (data)  Safefree(data);
    if (names) Safefree(names);

#undef _BAIL_LOG

    /* Single cleanup point: decompressed always needs freeing if allocated,
     * regardless of which branch we return from. */
    int ret;
    /* on_log — or dropping the pinned cb above — may have freed self.
     * check_destroyed finalizes any deferred Safefree and reports it. */
    if (check_destroyed(self)) {
        ret = -2;
    } else if (err_seen < 0) {
        *errmsg = safe_strdup("malformed log block");
        ret = -1;
    } else if (err_seen == 0) {         /* need more data — do not advance outer_pos */
        ret = 0;
    } else {
        /* For the uncompressed path bpos has been advanced inside the outer
         * buf; copy it back to pos. For the LZ4 path pos was already advanced
         * past the chain by ch_lz4_decompress_chain, and bpos is an offset
         * into the freed decompressed buffer — don't touch pos. */
        if (!decompressed) pos = bpos;
        *outer_pos = pos;
        ret = 1;
    }
    if (decompressed) Safefree(decompressed);
    return ret;
}

/* Dispatch the on_progress callback with five UInt values. Returns -2 if
 * the handler freed self, 0 otherwise. Shared between SERVER_PROGRESS
 * (per-packet) and EndOfStream (flush of any uncoalesced accumulator). */
static int fire_progress_cb(ev_clickhouse_t *self, const uint64_t pp[5]) {
    int i;
    dSP;
    self->callback_depth++;
    ENTER; SAVETMPS;
    PUSHMARK(SP);
    EXTEND(SP, 5);
    for (i = 0; i < 5; i++) PUSHs(sv_2mortal(newSVuv(pp[i])));
    PUTBACK;
    PINNED_CALL_SV(self->on_progress, G_DISCARD | G_EVAL);
    WARN_AND_CLEAR_ERRSV("progress handler");
    FREETMPS; LEAVE;
    self->callback_depth--;
    return check_destroyed(self) ? -2 : 0;
}

static int parse_native_packet(ev_clickhouse_t *self, char **errmsg) {
    const char *buf = self->recv_buf;
    size_t len = self->recv_len;
    size_t pos = 0;
    uint64_t ptype;
    int rc;

    rc = read_varuint(buf, len, &pos, &ptype);
    if (rc == 0) return 0;
    if (rc < 0) {
        *errmsg = safe_strdup("malformed packet type");
        return -1;
    }

    switch ((int)ptype) {

    case SERVER_HELLO: {
        char *sname = NULL;
        uint64_t major, minor, revision;

        rc = read_native_string_alloc(buf, len, &pos, &sname, NULL);
        if (rc == 0) return 0;
        if (rc < 0) { *errmsg = safe_strdup("malformed server name"); return -1; }

        rc = read_varuint(buf, len, &pos, &major);
        if (rc == 0) { Safefree(sname); return 0; }
        if (rc < 0) { Safefree(sname); *errmsg = safe_strdup("malformed server version major"); return -1; }

        rc = read_varuint(buf, len, &pos, &minor);
        if (rc == 0) { Safefree(sname); return 0; }
        if (rc < 0) { Safefree(sname); *errmsg = safe_strdup("malformed server version minor"); return -1; }

        rc = read_varuint(buf, len, &pos, &revision);
        if (rc == 0) { Safefree(sname); return 0; }
        if (rc < 0) { Safefree(sname); *errmsg = safe_strdup("malformed server revision"); return -1; }

        CLEAR_STR(self->server_name);
        self->server_name = sname;
        self->server_version_major = (unsigned int)major;
        self->server_version_minor = (unsigned int)minor;
        self->server_revision = (unsigned int)revision;

        /* The server emits these fields per the negotiated revision =
         * min(server_rev, our advertised CH_CLIENT_REVISION). Gate on
         * server_revision so we don't read garbage from older servers. */
        if (self->server_revision >= DBMS_MIN_REVISION_WITH_SERVER_TIMEZONE) {
            char *tz = NULL;
            rc = read_native_string_alloc(buf, len, &pos, &tz, NULL);
            if (rc == 0) return 0;
            if (rc < 0) { *errmsg = safe_strdup("malformed timezone"); return -1; }
            CLEAR_STR(self->server_timezone);
            self->server_timezone = tz;
        }

        if (self->server_revision >= DBMS_MIN_REVISION_WITH_SERVER_DISPLAY_NAME) {
            char *dn = NULL;
            rc = read_native_string_alloc(buf, len, &pos, &dn, NULL);
            if (rc == 0) return 0;
            if (rc < 0) { *errmsg = safe_strdup("malformed display name"); return -1; }
            CLEAR_STR(self->server_display_name);
            self->server_display_name = dn;
        }

        if (self->server_revision >= DBMS_MIN_REVISION_WITH_VERSION_PATCH) {
            uint64_t patch;
            rc = read_varuint(buf, len, &pos, &patch);
            if (rc == 0) return 0;
            if (rc < 0) { *errmsg = safe_strdup("malformed version patch"); return -1; }
            self->server_version_patch = (unsigned int)patch;
        }

        /* consume from recv_buf */
        recv_consume(self, pos);
        return 4;
    }

    case SERVER_DATA:
    case SERVER_TOTALS:
    case SERVER_EXTREMES: {
        uint64_t num_cols, num_rows;
        const char *dbuf;   /* data buffer (may point to decompressed data) */
        size_t dlen, dpos;
        char *decompressed = NULL;
        int more_maybe = 0;  /* chain stopped mid-frame: short block = need-more */

        /* table name — outside compression */
        rc = skip_native_string(buf, len, &pos);
        if (rc == 0) return 0;
        if (rc < 0) { *errmsg = safe_strdup("malformed table name"); return -1; }

#ifdef HAVE_LZ4
        if (self->compress) {
            /* Decompress the block body — may span multiple LZ4 sub-blocks. */
            int need_more = 0;
            const char *lz4_err = NULL;
            decompressed = ch_lz4_decompress_chain(buf, len, &pos, &dlen,
                                                    &need_more, &lz4_err,
                                                    &more_maybe);
            if (!decompressed) {
                if (need_more) return 0;
                *errmsg = safe_strdup(lz4_err ? lz4_err : "LZ4 decompression failed");
                return -1;
            }
            dbuf = decompressed;
            dpos = 0;
        } else
#endif
        {
            dbuf = buf;
            dlen = len;
            dpos = pos;
        }

        /* block info */
        if (self->server_revision >= DBMS_MIN_REVISION_WITH_BLOCK_INFO) {
            rc = skip_block_info(dbuf, dlen, &dpos);
            if (rc == 0) {
                if (decompressed) {
                    Safefree(decompressed);
                    if (more_maybe) return 0;
                    *errmsg = safe_strdup("truncated compressed block");
                    return -1;
                }
                return 0;
            }
            if (rc < 0) { if (decompressed) Safefree(decompressed); *errmsg = safe_strdup("malformed block info"); return -1; }
        }

        rc = read_varuint(dbuf, dlen, &dpos, &num_cols);
        if (rc == 0) {
            if (decompressed) {
                Safefree(decompressed);
                if (more_maybe) return 0;
                *errmsg = safe_strdup("truncated compressed block");
                return -1;
            }
            return 0;
        }
        if (rc < 0) { if (decompressed) Safefree(decompressed); *errmsg = safe_strdup("malformed num_cols"); return -1; }

        rc = read_varuint(dbuf, dlen, &dpos, &num_rows);
        if (rc == 0) {
            if (decompressed) {
                Safefree(decompressed);
                if (more_maybe) return 0;
                *errmsg = safe_strdup("truncated compressed block");
                return -1;
            }
            return 0;
        }
        if (rc < 0) { if (decompressed) Safefree(decompressed); *errmsg = safe_strdup("malformed num_rows"); return -1; }

        /* Empty data block — skip or handle column names/types */
        if (num_rows == 0) {
            /* INSERT two-phase: server sent sample block with column structure */
            if (self->native_state == NATIVE_WAIT_INSERT_META
                && (self->insert_data || self->insert_av) && num_cols > 0) {
                const char **cnames;
                size_t *cname_lens;
                const char **ctypes_str;
                size_t *ctype_lens;
                col_type_t **ctypes;
                char *data_pkt;
                size_t data_pkt_len;
                uint64_t c;
                int meta_hard = 0;             /* 1 = hard error, 0 = need more */
                const char *meta_err = NULL;   /* non-NULL → goto meta_cleanup */

                /* Bound the column count to the remaining wire bytes before
                 * allocating, same as the other block-decode sites. */
                if (num_cols > (uint64_t)(dlen - dpos)) {
                    if (decompressed) Safefree(decompressed);
                    *errmsg = safe_strdup("too many columns");
                    return -1;
                }
                Newxz(cnames, num_cols, const char *);
                Newxz(cname_lens, num_cols, size_t);
                Newxz(ctypes_str, num_cols, const char *);
                Newxz(ctype_lens, num_cols, size_t);
                Newxz(ctypes, num_cols, col_type_t *);

                for (c = 0; c < num_cols; c++) {
                    rc = read_native_string_ref(dbuf, dlen, &dpos,
                            &cnames[c], &cname_lens[c]);
                    if (rc <= 0) {
                        meta_hard = (rc < 0 || decompressed != NULL);
                        meta_err = "malformed cname";
                        goto meta_cleanup;
                    }
                    rc = read_native_string_ref(dbuf, dlen, &dpos,
                            &ctypes_str[c], &ctype_lens[c]);
                    if (rc <= 0) {
                        meta_hard = (rc < 0 || decompressed != NULL);
                        meta_err = "malformed ctype";
                        goto meta_cleanup;
                    }
                    ctypes[c] = parse_col_type(ctypes_str[c], ctype_lens[c]);

                    /* custom serialization flag (revision >= 54446) */
                    if (dpos >= dlen) {
                        meta_hard = (decompressed != NULL);
                        meta_err = "truncated custom_ser";
                        goto meta_cleanup;
                    }
                    if ((uint8_t)dbuf[dpos]) {
                        meta_hard = 1;
                        meta_err = "custom serialization not supported";
                        goto meta_cleanup;
                    }
                    dpos++;
                }
                goto meta_ok;

            meta_cleanup:
                for (c = 0; c < num_cols; c++) if (ctypes[c]) free_col_type(ctypes[c]);
                Safefree(cnames); Safefree(cname_lens);
                Safefree(ctypes_str); Safefree(ctype_lens);
                Safefree(ctypes);
                if (decompressed) Safefree(decompressed);
                if (meta_hard) { *errmsg = safe_strdup(meta_err); return -1; }
                return 0;

            meta_ok: ;

                /* Build binary data block from stored data */
                if (self->insert_av) {
                    data_pkt = build_native_insert_data_from_av(aTHX_ self,
                        (AV *)SvRV(self->insert_av),
                        cnames, cname_lens, ctypes_str, ctype_lens,
                        ctypes, (int)num_cols, &data_pkt_len);
                } else {
                    data_pkt = build_native_insert_data(self,
                        self->insert_data, self->insert_data_len,
                        cnames, cname_lens, ctypes_str, ctype_lens,
                        ctypes, (int)num_cols, &data_pkt_len);
                }

                for (c = 0; c < num_cols; c++)
                    free_col_type(ctypes[c]);
                Safefree(cnames); Safefree(cname_lens);
                Safefree(ctypes_str); Safefree(ctype_lens);
                Safefree(ctypes);

                {
                /* Check encode-failure sentinel before freeing insert data */
                int encode_failed = (!data_pkt && data_pkt_len == (size_t)-1);

                /* Free stored INSERT data */
                CLEAR_INSERT(self);

                if (decompressed) Safefree(decompressed);
                else pos = dpos;
                recv_consume(self, pos);

                if (!data_pkt) {
                    /* Send empty Data block to complete the INSERT protocol */
                    native_buf_t fallback;
                    nbuf_init(&fallback);
                    nbuf_empty_data_block(&fallback, self->compress);
                    data_pkt = fallback.data;
                    data_pkt_len = fallback.len;
                    if (encode_failed)
                        self->insert_err = safe_strdup(
                            "native INSERT encoding failed (unsupported type)");
                }
                }

                /* Send the data block — write to send_buf and start writing */
                self->native_state = NATIVE_WAIT_RESULT;
                send_replace(self, data_pkt, data_pkt_len);
                if (try_write(self)) return -2;
                return 1;
            }

            /* INSERT two-phase with 0-column sample block: free data,
             * send empty Data block, transition to WAIT_RESULT */
            if (self->native_state == NATIVE_WAIT_INSERT_META
                && (self->insert_data || self->insert_av) && num_cols == 0) {
                native_buf_t fallback;

                CLEAR_INSERT(self);

                if (decompressed) Safefree(decompressed);
                else pos = dpos;
                recv_consume(self, pos);

                nbuf_init(&fallback);
                nbuf_empty_data_block(&fallback, self->compress);
                self->native_state = NATIVE_WAIT_RESULT;
                send_replace(self, fallback.data, fallback.len);
                self->insert_err = safe_strdup(
                    "INSERT failed: server sent 0-column sample block");
                if (try_write(self)) return -2;
                return 1;
            }

            /* Normal empty block — capture column names/types so callers can
             * inspect schema after a zero-row SELECT. Reset only when we have
             * columns to record so the terminating empty block (num_cols=0)
             * doesn't wipe the schema we already captured; this also drops
             * any partial state from a need-more retry. */
            {
                uint64_t c;
                if (num_cols > 0) {
                    CLEAR_SV(self->native_col_names);
                    CLEAR_SV(self->native_col_types);
                    self->native_col_names = newAV();
                    self->native_col_types = newAV();
                }
                for (c = 0; c < num_cols; c++) {
                    const char *cname, *ctype;
                    size_t cname_len, ctype_len;

                    rc = read_native_string_ref(dbuf, dlen, &dpos, &cname, &cname_len);
                    if (rc <= 0) {
                        if (decompressed) Safefree(decompressed);
                        if (rc < 0) { *errmsg = safe_strdup("malformed cname"); return -1; }
                        return 0;
                    }
                    av_push(self->native_col_names, newSVpvn(cname, cname_len));

                    rc = read_native_string_ref(dbuf, dlen, &dpos, &ctype, &ctype_len);
                    if (rc <= 0) {
                        if (decompressed) Safefree(decompressed);
                        if (rc < 0) { *errmsg = safe_strdup("malformed ctype"); return -1; }
                        return 0;
                    }
                    av_push(self->native_col_types, newSVpvn(ctype, ctype_len));

                    /* custom serialization flag (revision >= 54446) */
                    if (dpos >= dlen) {
                        if (decompressed) Safefree(decompressed);
                        return 0;
                    }
                    if ((uint8_t)dbuf[dpos]) {
                        if (decompressed) Safefree(decompressed);
                        *errmsg = safe_strdup("custom serialization not supported");
                        return -1;
                    }
                    dpos++;
                }
            }
            if (decompressed) Safefree(decompressed);
            else pos = dpos;  /* uncompressed: advance pos to match dpos */
            recv_consume(self, pos);
            return 1;
        }

        /* Decode columns and convert to rows */
        {
            SV ***columns = NULL;
            col_type_t **col_types = NULL;
            const char **cnames = NULL;
            size_t *cname_lens = NULL;
            uint64_t c, r;
            int named = (self->decode_flags & DECODE_NAMED_ROWS) ? 1 : 0;

            /* More columns than remaining wire bytes is malformed; reject
             * before allocating so a bogus count can't drive a huge Newxz. */
            if (num_cols > (uint64_t)(dlen - dpos)) {
                if (decompressed) Safefree(decompressed);
                *errmsg = safe_strdup("too many columns");
                return -1;
            }
            Newxz(columns, num_cols, SV**);
            Newxz(col_types, num_cols, col_type_t*);
            if (named) {
                Newxz(cnames, num_cols, const char *);
                Newx(cname_lens, num_cols, size_t);
            }

            for (c = 0; c < num_cols; c++) {
                const char *cname, *ctype;
                size_t cname_len, ctype_len;

                rc = read_native_string_ref(dbuf, dlen, &dpos, &cname, &cname_len);
                if (rc == 0) {
                    if (decompressed) { *errmsg = safe_strdup("truncated cname"); goto data_error; }
                    goto data_need_more;
                }
                if (rc < 0) { *errmsg = safe_strdup("malformed cname"); goto data_error; }

                if (named) {
                    cnames[c] = cname;
                    cname_lens[c] = cname_len;
                }

                /* Allocate AVs on first column of first data block. Reset
                 * any partial state from a need-more retry: pipeline_advance
                 * cleared at dispatch, but if we returned 0 mid-loop the AVs
                 * may now hold a partial column list. */
                if (c == 0) {
                    CLEAR_SV(self->native_col_names);
                    CLEAR_SV(self->native_col_types);
                    self->native_col_names = newAV();
                    self->native_col_types = newAV();
                }
                av_push(self->native_col_names, newSVpvn(cname, cname_len));

                rc = read_native_string_ref(dbuf, dlen, &dpos, &ctype, &ctype_len);
                if (rc == 0) {
                    if (decompressed) { *errmsg = safe_strdup("truncated ctype"); goto data_error; }
                    goto data_need_more;
                }
                if (rc < 0) { *errmsg = safe_strdup("malformed ctype"); goto data_error; }

                col_types[c] = parse_col_type(ctype, ctype_len);
                av_push(self->native_col_types, newSVpvn(ctype, ctype_len));

                /* custom serialization flag (revision >= 54446) */
                if (dpos >= dlen) {
                    if (decompressed) { *errmsg = safe_strdup("truncated custom_ser"); goto data_error; }
                    goto data_need_more;
                }
                if ((uint8_t)dbuf[dpos]) {
                    *errmsg = safe_strdup("custom serialization not supported");
                    goto data_error;
                }
                dpos++;

                /* Allocate LC dict state on first column of first block */
                if (c == 0 && !self->lc_dicts) {
                    Newxz(self->lc_dicts, num_cols, SV**);
                    Newxz(self->lc_dict_sizes, num_cols, uint64_t);
                    self->lc_num_cols = (int)num_cols;
                }

                {
                    int col_err = 0;
                    columns[c] = decode_column_ex(dbuf, dlen, &dpos, num_rows, col_types[c], &col_err, self->decode_flags, self, (int)c);
                    if (!columns[c]) {
                        if (col_err || (decompressed && !more_maybe)) {
                            *errmsg = safe_strdup("decode_column failed");
                            goto data_error;
                        }
                        goto data_need_more;
                    }
                }
            }

            /* Convert column-oriented to row-oriented */
            {
            AV **target;
            if (ptype == SERVER_TOTALS) {
                if (!self->native_totals) self->native_totals = newAV();
                target = &self->native_totals;
            } else if (ptype == SERVER_EXTREMES) {
                if (!self->native_extremes) self->native_extremes = newAV();
                target = &self->native_extremes;
            } else {
                if (!self->native_rows) self->native_rows = newAV();
                target = &self->native_rows;
            }

            if (named) {
                for (r = 0; r < num_rows; r++) {
                    HV *hv = newHV();
                    for (c = 0; c < num_cols; c++) {
                        if (!hv_store(hv, cnames[c], cname_lens[c], columns[c][r], 0))
                            SvREFCNT_dec(columns[c][r]);
                    }
                    av_push(*target, newRV_noinc((SV*)hv));
                }
            } else {
                for (r = 0; r < num_rows; r++) {
                    AV *row = newAV();
                    if (num_cols > 0)
                        av_extend(row, num_cols - 1);
                    for (c = 0; c < num_cols; c++) {
                        av_push(row, columns[c][r]);
                    }
                    av_push(*target, newRV_noinc((SV*)row));
                }
            }
            }

            /* Fire on_data streaming callback if set (only for DATA, not TOTALS/EXTREMES) */
            {
                SV *on_data = (ptype == SERVER_DATA) ? peek_cb_on_data(self) : NULL;
                if (on_data && self->native_rows) {
                    /* Hold a reference across call_sv: a reentrant
                     * skip_pending() / cancel() in the handler would
                     * otherwise pop the cb_queue entry and free this
                     * callback while we're still invoking it. */
                    SvREFCNT_inc(on_data);
                    self->callback_depth++;
                    {
                        dSP;
                        ENTER; SAVETMPS;
                        PUSHMARK(SP);
                        PUSHs(sv_2mortal(newRV_inc((SV*)self->native_rows)));
                        PUTBACK;
                        call_sv(on_data, G_DISCARD | G_EVAL);
                        WARN_AND_CLEAR_ERRSV("on_data handler");
                        FREETMPS; LEAVE;
                    }
                    /* Decrement on_data BEFORE callback_depth-- so a DESTROY
                     * triggered by the dec (closure holding last $ch ref)
                     * still sees callback_depth > 0 and defers Safefree(self). */
                    SvREFCNT_dec(on_data);
                    self->callback_depth--;
                    /* Clear accumulated rows for next block */
                    CLEAR_SV(self->native_rows);
                    if (check_destroyed(self)) {
                        if (cnames) Safefree(cnames);
                        if (cname_lens) Safefree(cname_lens);
                        for (c = 0; c < num_cols; c++) {
                            Safefree(columns[c]);
                            free_col_type(col_types[c]);
                        }
                        Safefree(columns); Safefree(col_types);
                        if (decompressed) Safefree(decompressed);
                        return -2;
                    }
                }
            }

            /* Cleanup column arrays (SVs moved to rows, don't dec refcnt) */
            for (c = 0; c < num_cols; c++) {
                Safefree(columns[c]);
                free_col_type(col_types[c]);
            }
            Safefree(columns);
            Safefree(col_types);
            if (cnames) Safefree(cnames);
            if (cname_lens) Safefree(cname_lens);
            if (decompressed) Safefree(decompressed);
            else pos = dpos;  /* uncompressed: advance pos to match dpos */

            /* Consume from recv_buf */
            recv_consume(self, pos);
            return 1;

        data_error:
        data_need_more:
            /* Cleanup partial decode */
            for (c = 0; c < num_cols; c++) {
                if (columns[c]) {
                    uint64_t j;
                    for (j = 0; j < num_rows; j++) {
                        if (columns[c][j]) SvREFCNT_dec(columns[c][j]);
                    }
                    Safefree(columns[c]);
                }
                if (col_types[c]) free_col_type(col_types[c]);
            }
            Safefree(columns);
            Safefree(col_types);
            if (cnames) Safefree(cnames);
            if (cname_lens) Safefree(cname_lens);
            if (decompressed) Safefree(decompressed);
            if (*errmsg) {
                /* data_error: flush recv_buf — data is malformed, cannot resume */
                self->recv_len = 0;
                return -1;
            }
            return 0;
        }
    }

    case SERVER_EXCEPTION: {
        /* code: Int32, name: String, message: String,
         * stack_trace: String, has_nested: UInt8 */
        int32_t code;
        const char *name, *msg, *stack;
        size_t name_len, msg_len, stack_len;
        uint8_t has_nested;
        char *err;

        /* We just read the top-level exception */
        rc = read_i32(buf, len, &pos, &code);
        if (rc == 0) return 0;
        if (rc < 0) { *errmsg = safe_strdup("malformed exception code"); return -1; }

        rc = read_native_string_ref(buf, len, &pos, &name, &name_len);
        if (rc == 0) return 0;
        if (rc < 0) { *errmsg = safe_strdup("malformed exception name"); return -1; }

        rc = read_native_string_ref(buf, len, &pos, &msg, &msg_len);
        if (rc == 0) return 0;
        if (rc < 0) { *errmsg = safe_strdup("malformed exception message"); return -1; }

        rc = read_native_string_ref(buf, len, &pos, &stack, &stack_len);
        if (rc == 0) return 0;
        if (rc < 0) { *errmsg = safe_strdup("malformed exception stack"); return -1; }

        rc = read_u8(buf, len, &pos, &has_nested);
        if (rc == 0) return 0;
        if (rc < 0) { *errmsg = safe_strdup("malformed exception has_nested"); return -1; }

        /* Skip nested exceptions — keep the top-level code, not the innermost. */
        while (has_nested) {
            int32_t nested_code;
            int i;
            rc = read_i32(buf, len, &pos, &nested_code);
            if (rc == 0) return 0;
            if (rc < 0) { *errmsg = safe_strdup("malformed nested exception"); return -1; }
            /* name, message, stack_trace */
            for (i = 0; i < 3; i++) {
                rc = skip_native_string(buf, len, &pos);
                if (rc == 0) return 0;
                if (rc < 0) { *errmsg = safe_strdup("malformed nested exception"); return -1; }
            }
            rc = read_u8(buf, len, &pos, &has_nested);
            if (rc == 0) return 0;
            if (rc < 0) { *errmsg = safe_strdup("malformed nested exception"); return -1; }
        }

        self->last_error_code = code;

        Newx(err, msg_len + name_len + 64, char);
        snprintf(err, msg_len + name_len + 64, "Code: %d. %.*s: %.*s",
                 (int)code, (int)name_len, name, (int)msg_len, msg);

        recv_consume(self, pos);

        *errmsg = err;
        return -1;
    }

    case SERVER_PROGRESS: {
        /* rows, bytes, total_rows, written_rows (>=54420), written_bytes (>=54420) */
        uint64_t pp[5] = {0};
        int n = (self->server_revision >= DBMS_MIN_REVISION_WITH_PROGRESS_WRITES) ? 5 : 3;
        int i;
        for (i = 0; i < n; i++) {
            rc = read_varuint(buf, len, &pos, &pp[i]);
            if (rc == 0) return 0;
            if (rc < 0) { *errmsg = safe_strdup("malformed progress packet"); return -1; }
        }

        recv_consume(self, pos);

        if (self->on_progress) {
            /* Coalesce when progress_period is set: the protocol sends
             * incremental deltas, so accumulate and fire at the cadence. */
            if (self->progress_period > 0) {
                for (i = 0; i < 5; i++) self->progress_acc[i] += pp[i];
                double now = ev_now(self->loop);
                if (now - self->progress_last < self->progress_period)
                    return 1;
                self->progress_last = now;
                for (i = 0; i < 5; i++) { pp[i] = self->progress_acc[i]; self->progress_acc[i] = 0; }
            }

            if (fire_progress_cb(self, pp) < 0) return -2;
        }

        return 1;
    }

    case SERVER_PROFILE_INFO: {
        /* rows, blocks, bytes, applied_limit, rows_before_limit, calc_rows_before_limit */
        uint64_t pi[6];
        int i;
        for (i = 0; i < 6; i++) {
            rc = read_varuint(buf, len, &pos, &pi[i]);
            if (rc == 0) return 0;
            if (rc < 0) { *errmsg = safe_strdup("malformed profile_info packet"); return -1; }
        }
        self->profile_rows = pi[0];
        self->profile_bytes = pi[2];
        self->profile_rows_before_limit = pi[4];
        recv_consume(self, pos);
        return 1;
    }

    case SERVER_TABLE_COLUMNS: {
        /* Format: string(table_name) + string(column_description) */
        int i;
        for (i = 0; i < 2; i++) {
            rc = skip_native_string(buf, len, &pos);
            if (rc == 0) return 0;
            if (rc < 0) { *errmsg = safe_strdup("malformed table_columns packet"); return -1; }
        }
        recv_consume(self, pos);
        return 1;
    }

    case SERVER_LOG: {
        if (self->on_log) {
            rc = parse_and_emit_log_block(self, buf, len, &pos, self->on_log, errmsg);
        } else {
            rc = parse_and_discard_block(self, buf, len, &pos, "server log", 0, errmsg);
        }
        if (rc <= 0) return rc;
        recv_consume(self, pos);
        return 1;
    }

    case SERVER_PROFILE_EVENTS: {
        rc = parse_and_discard_block(self, buf, len, &pos, "profile_events", 1, errmsg);
        if (rc <= 0) return rc;
        recv_consume(self, pos);
        return 1;
    }

    case SERVER_TIMEZONE_UPDATE: {
        /* Server-side session timezone changed mid-query. Format: string(tz). */
        char *tz = NULL;
        rc = read_native_string_alloc(buf, len, &pos, &tz, NULL);
        if (rc == 0) return 0;
        if (rc < 0) { *errmsg = safe_strdup("malformed timezone_update packet"); return -1; }
        CLEAR_STR(self->server_timezone);
        self->server_timezone = tz;
        recv_consume(self, pos);
        return 1;
    }

    case SERVER_PONG:
        recv_consume(self, pos);
        return 3;

    case SERVER_END_OF_STREAM:
        recv_consume(self, pos);
        return 2;

    default: {
        /* Unknown packet type */
        char err[64];
        snprintf(err, sizeof(err), "unknown server packet type: %llu",
                 (unsigned long long)ptype);
        *errmsg = safe_strdup(err);
        self->recv_len = 0;
        return -1;
    }
    }
}

/*
 * Process native protocol responses from recv_buf.
 * Called from on_readable when protocol == PROTO_NATIVE.
 */
static void process_native_response(ev_clickhouse_t *self) {
    while (self->recv_len > 0 && self->magic == EV_CH_MAGIC) {
        char *errmsg = NULL;
        int rc;
        rc = parse_native_packet(self, &errmsg);

        if (rc == 0) {
            /* need more data */
            return;
        }

        if (rc == -2) {
            /* object destroyed inside callback */
            return;
        }

        if (rc == 4) {
            /* ServerHello received — send addendum (revision >= 54458) */
            if (self->native_state == NATIVE_WAIT_HELLO) {
                /* Addendum: quota_key (only if server supports it) */
                if (self->server_revision >= DBMS_MIN_PROTOCOL_VERSION_WITH_ADDENDUM) {
                    native_buf_t ab;
                    nbuf_init(&ab);
                    nbuf_cstring(&ab, "");  /* quota_key */
                    send_replace(self, ab.data, ab.len);
                    if (try_write(self)) return;
                    if (self->send_pos < self->send_len) {
                        /* Addendum partially written (EAGAIN); io_cb finishes
                         * connect once the buffer drains, otherwise pipeline_advance
                         * could overwrite the unsent tail with a queued query. */
                        self->pending_addendum_finish = 1;
                        return;
                    }
                }
                self->native_state = NATIVE_IDLE;
                if (finish_connect(self)) return;
            }
            /* pipeline_advance -> try_write may free self; no data
             * in recv_buf for the just-dispatched request yet */
            return;
        }

        if (rc == -1) {
            /* error */
            if (self->native_state == NATIVE_WAIT_HELLO) {
                /* Skip auto_reconnect on a malformed ServerHello: the peer
                 * isn't a ClickHouse server, so retrying just spins.
                 * (connect_timeout still uses fail_connection, which retries.) */
                teardown_io_error(self, errmsg, "connection failed");
                Safefree(errmsg);
                return;
            }

            /* Stop query timeout timer */
            stop_timing(self);

            /* Query error — deliver to callback */
            CLEAR_SV(self->native_rows);
            CLEAR_INSERT(self);
            CLEAR_STR(self->insert_err);
            self->native_state = NATIVE_IDLE;
            self->recv_len = 0; /* flush malformed data */
            if (self->send_count > 0) self->send_count--;
            lc_free_dicts(self);
            int destroyed = deliver_error(self, errmsg);
            Safefree(errmsg);
            if (destroyed) return;

            /* advance pipeline — may free self via try_write error */
            pipeline_advance(self);
            return;
        }

        if (rc == 2) {
            /* EndOfStream — deliver accumulated rows or deferred error */
            stop_timing(self);
            self->native_state = NATIVE_IDLE;
            CLEAR_INSERT(self);
            if (self->send_count > 0) self->send_count--;
            lc_free_dicts(self);

            /* Flush any uncoalesced progress accumulated since the last
             * fire so users instrumenting via on_progress see the full
             * total when the query completes within one progress_period
             * of the last fire. */
            if (self->on_progress && self->progress_period > 0) {
                int any = 0, i;
                for (i = 0; i < 5; i++) if (self->progress_acc[i]) { any = 1; break; }
                if (any) {
                    uint64_t pp[5];
                    memcpy(pp, self->progress_acc, sizeof(pp));
                    memset(self->progress_acc, 0, sizeof(self->progress_acc));
                    if (fire_progress_cb(self, pp) < 0) return;
                }
            }

            if (self->insert_err) {
                char *err = self->insert_err;
                self->insert_err = NULL;
                CLEAR_SV(self->native_rows);
                int destroyed = deliver_error(self, err);
                Safefree(err);
                if (destroyed) return;
            } else {
                AV *rows = self->native_rows;
                self->native_rows = NULL;
                if (deliver_rows(self, rows)) return;
            }

            /* advance pipeline — may free self via try_write error */
            pipeline_advance(self);
            return;
        }

        if (rc == 3) {
            /* Pong — deliver to the queued cb (keepalive no-op or user ping) */
            self->native_state = NATIVE_IDLE;
            stop_timing(self);
            if (self->send_count > 0) self->send_count--;
            AV *rows = newAV();
            if (deliver_rows(self, rows)) return;
            pipeline_advance(self);
            return;
        }

        /* rc == 1: Data/Progress/ProfileInfo — continue reading */
    }
}

