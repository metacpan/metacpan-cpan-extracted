/* --- Gzip compression/decompression --- */

/* Compress data with gzip. Returns malloc'd buffer, sets *out_len. NULL on error. */
static char* gzip_compress(const char *data, size_t data_len, size_t *out_len) {
    z_stream strm;
    char *out;
    size_t out_cap;
    int ret;

    if (data_len > (size_t)UINT_MAX) return NULL;

    Zero(&strm, 1, z_stream);
    ret = deflateInit2(&strm, Z_DEFAULT_COMPRESSION, Z_DEFLATED, 15 + 16, 8, Z_DEFAULT_STRATEGY);
    if (ret != Z_OK) return NULL;

    out_cap = deflateBound(&strm, (uLong)data_len);
    if (out_cap > (size_t)UINT_MAX) { deflateEnd(&strm); return NULL; }
    Newx(out, out_cap, char);

    strm.next_in = (Bytef *)data;
    strm.avail_in = (uInt)data_len;
    strm.next_out = (Bytef *)out;
    strm.avail_out = (uInt)out_cap;

    ret = deflate(&strm, Z_FINISH);
    if (ret != Z_STREAM_END) {
        Safefree(out);
        deflateEnd(&strm);
        return NULL;
    }

    *out_len = strm.total_out;
    deflateEnd(&strm);
    return out;
}

/* Decompress gzip data. Returns malloc'd buffer, sets *out_len. NULL on error. */
static char* gzip_decompress(const char *data, size_t data_len, size_t *out_len) {
    z_stream strm;
    char *out;
    size_t out_cap;
    int ret;

    if (data_len > (size_t)UINT_MAX) return NULL;

    Zero(&strm, 1, z_stream);
    ret = inflateInit2(&strm, 15 + 16); /* auto-detect gzip */
    if (ret != Z_OK) return NULL;

    /* Estimate 4x expansion, but clamp to CH_MAX_DECOMPRESS_SIZE so the
     * initial allocation can never exceed the cap on its own. Comparing
     * data_len against cap/4 (instead of multiplying first) also avoids a
     * size_t overflow of data_len*4 on 32-bit. If the real output is
     * larger than the cap, the doubling branch below trips the limit. */
    if (data_len > CH_MAX_DECOMPRESS_SIZE / 4)
        out_cap = CH_MAX_DECOMPRESS_SIZE;
    else
        out_cap = data_len * 4;
    if (out_cap < 4096) out_cap = 4096;
    Newx(out, out_cap, char);

    strm.next_in = (Bytef *)data;
    strm.avail_in = (uInt)data_len;

    *out_len = 0;
    do {
        if (*out_len + 4096 > out_cap) {
            out_cap *= 2;
            if (out_cap > CH_MAX_DECOMPRESS_SIZE) {
                Safefree(out);
                inflateEnd(&strm);
                return NULL;
            }
            Renew(out, out_cap, char);
        }
        strm.next_out = (Bytef *)(out + *out_len);
        strm.avail_out = (uInt)(out_cap - *out_len);

        ret = inflate(&strm, Z_NO_FLUSH);
        if (ret == Z_STREAM_ERROR || ret == Z_DATA_ERROR ||
            ret == Z_MEM_ERROR || ret == Z_BUF_ERROR) {
            Safefree(out);
            inflateEnd(&strm);
            return NULL;
        }
        *out_len = strm.total_out;
    } while (ret != Z_STREAM_END);

    inflateEnd(&strm);
    return out;
}

#ifdef HAVE_LZ4

/*
 * Decompress a ClickHouse LZ4 compressed block.
 * Input: compressed block starting at checksum (16 + 9 + payload bytes).
 * Returns malloc'd buffer with decompressed data, sets *out_len.
 * Returns NULL on error or if need more data (sets *need_more=1).
 */
static char* ch_lz4_decompress(const char *data, size_t data_len,
                                size_t *out_len, size_t *consumed,
                                int *need_more, const char **err_reason) {
    uint32_t compressed_with_header, uncompressed_size;
    uint32_t payload_size;
    uint8_t method;
    char *out;
    int ret;

    *need_more = 0;
    *consumed = 0;
    if (err_reason) *err_reason = NULL;

    /* Need at least checksum (16) + header (9) */
    if (data_len < CH_CHECKSUM_SIZE + CH_COMPRESS_HEADER_SIZE) {
        *need_more = 1;
        return NULL;
    }

    /* Read header fields (after 16-byte checksum) */
    method = (uint8_t)data[CH_CHECKSUM_SIZE];
    if (method != CH_LZ4_METHOD) {
        if (err_reason) *err_reason = "unsupported compression method";
        return NULL;
    }
    memcpy(&compressed_with_header, data + CH_CHECKSUM_SIZE + 1, 4);
    memcpy(&uncompressed_size, data + CH_CHECKSUM_SIZE + 5, 4);

    if (uncompressed_size > CH_MAX_DECOMPRESS_SIZE) {
        if (err_reason) *err_reason = "decompressed size exceeds 128 MB limit";
        return NULL;
    }

    if (compressed_with_header < CH_COMPRESS_HEADER_SIZE) {
        if (err_reason) *err_reason = "compressed_with_header too small";
        return NULL;
    }

    payload_size = compressed_with_header - CH_COMPRESS_HEADER_SIZE;

    /* Need full block */
    if (data_len < CH_CHECKSUM_SIZE + CH_COMPRESS_HEADER_SIZE + payload_size) {
        *need_more = 1;
        return NULL;
    }

    /* Verify checksum */
    {
        ch_uint128_t expected, actual;
        memcpy(&expected.lo, data, 8);
        memcpy(&expected.hi, data + 8, 8);
        actual = ch_city_hash128(data + CH_CHECKSUM_SIZE, compressed_with_header);
        if (actual.lo != expected.lo || actual.hi != expected.hi) {
            if (err_reason) *err_reason = "CityHash128 checksum mismatch";
            return NULL;
        }
    }

    Newx(out, uncompressed_size, char);
    ret = LZ4_decompress_safe(data + CH_CHECKSUM_SIZE + CH_COMPRESS_HEADER_SIZE,
                              out, (int)payload_size, (int)uncompressed_size);
    if (ret < 0 || (uint32_t)ret != uncompressed_size) {
        Safefree(out);
        if (err_reason) *err_reason = "LZ4 decompression failed";
        return NULL;
    }

    *out_len = uncompressed_size;
    *consumed = CH_CHECKSUM_SIZE + CH_COMPRESS_HEADER_SIZE + payload_size;
    return out;
}

/*
 * Compress data into a ClickHouse LZ4 compressed block.
 * Returns malloc'd buffer (checksum + header + LZ4 payload), sets *out_len.
 */
static char* ch_lz4_compress(const char *data, size_t data_len, size_t *out_len) {
    int max_compressed;
    if (data_len > (size_t)INT_MAX) return NULL;
    max_compressed = LZ4_compressBound((int)data_len);
    char *out;
    int compressed_size;
    uint32_t compressed_with_header;
    ch_uint128_t checksum;

    Newx(out, CH_CHECKSUM_SIZE + CH_COMPRESS_HEADER_SIZE + max_compressed, char);

    compressed_size = LZ4_compress_default(
        data, out + CH_CHECKSUM_SIZE + CH_COMPRESS_HEADER_SIZE,
        (int)data_len, max_compressed);

    if (compressed_size <= 0) {
        Safefree(out);
        return NULL;
    }

    compressed_with_header = (uint32_t)compressed_size + CH_COMPRESS_HEADER_SIZE;

    /* Write header */
    out[CH_CHECKSUM_SIZE] = (char)CH_LZ4_METHOD;
    memcpy(out + CH_CHECKSUM_SIZE + 1, &compressed_with_header, 4);
    {   uint32_t uncomp = (uint32_t)data_len;
        memcpy(out + CH_CHECKSUM_SIZE + 5, &uncomp, 4);
    }

    /* Compute checksum over header + compressed data */
    checksum = ch_city_hash128(out + CH_CHECKSUM_SIZE, compressed_with_header);
    memcpy(out, &checksum.lo, 8);
    memcpy(out + 8, &checksum.hi, 8);

    *out_len = CH_CHECKSUM_SIZE + CH_COMPRESS_HEADER_SIZE + compressed_size;
    return out;
}

/* Decompress one or more consecutive LZ4 sub-blocks starting at buf[*pos].
 * Advances *pos past every consumed sub-block; *out_len is total decompressed
 * size. Returns malloc'd buffer (caller Safefrees) on success, NULL on
 * not-enough-data (sets *need_more=1) or on hard error (sets *err). */
static char* ch_lz4_decompress_chain(const char *buf, size_t len, size_t *pos,
                                      size_t *out_len, int *need_more,
                                      const char **err) {
    size_t comp_consumed;
    char *out;

    *need_more = 0;
    *err = NULL;

    out = ch_lz4_decompress(buf + *pos, len - *pos, out_len,
                            &comp_consumed, need_more, err);
    if (!out) return NULL;
    *pos += comp_consumed;

    while (len - *pos >= CH_CHECKSUM_SIZE + CH_COMPRESS_HEADER_SIZE
           && (uint8_t)buf[*pos + CH_CHECKSUM_SIZE] == CH_LZ4_METHOD) {
        size_t extra_len, extra_consumed;
        int extra_need_more = 0;
        const char *extra_err = NULL;
        char *extra = ch_lz4_decompress(buf + *pos, len - *pos, &extra_len,
                                         &extra_consumed,
                                         &extra_need_more, &extra_err);
        if (!extra) {
            Safefree(out);
            if (extra_need_more) { *need_more = 1; return NULL; }
            *err = extra_err;
            return NULL;
        }
        if (extra_len > CH_MAX_DECOMPRESS_SIZE - *out_len) {
            Safefree(extra);
            Safefree(out);
            *err = "LZ4 chain decompressed size exceeds limit";
            return NULL;
        }
        Renew(out, *out_len + extra_len, char);
        Copy(extra, out + *out_len, extra_len, char);
        *out_len += extra_len;
        *pos += extra_consumed;
        Safefree(extra);
    }
    return out;
}

#endif /* HAVE_LZ4 */

/* --- Days-since-epoch calculation for Date encoding --- */

static int32_t date_string_to_days(const char *s, size_t len) {
    int year, month, day;
    if (len >= 10 && s[4] == '-' && s[7] == '-') {
        year = atoi(s);
        month = atoi(s + 5);
        day = atoi(s + 8);
        /* civil_from_days algorithm (Howard Hinnant) */
        if (month <= 2) { year--; month += 9; } else { month -= 3; }
        {
            int era = (year >= 0 ? year : year - 399) / 400;
            unsigned yoe = (unsigned)(year - era * 400);
            unsigned doy = (153 * (unsigned)month + 2) / 5 + (unsigned)day - 1;
            unsigned doe = yoe * 365 + yoe/4 - yoe/100 + doy;
            return (int32_t)(era * 146097 + (int)doe - 719468);
        }
    }
    /* fallback: numeric value */
    return (int32_t)strtol(s, NULL, 10);
}

static uint32_t datetime_string_to_epoch(const char *s, size_t len) {
    int hour = 0, min = 0, sec = 0;
    if (len >= 10 && s[4] == '-' && s[7] == '-') {
        if (len >= 19) {
            hour = atoi(s + 11);
            min = atoi(s + 14);
            sec = atoi(s + 17);
        }
        {
            int32_t days = date_string_to_days(s, 10);
            return (uint32_t)((int64_t)days * 86400 + hour * 3600 + min * 60 + sec);
        }
    }
    return (uint32_t)strtoul(s, NULL, 10);
}

/* --- TabSeparated parser --- */

/* Parse TabSeparated body into AV of AV. Handles \N -> undef, backslash escapes. */
static AV* parse_tab_separated(const char *data, size_t len) {
    AV *rows = newAV();
    const char *p = data;
    const char *end = data + len;
    const char *line_start;
    AV *row;
    char *buf;
    size_t buf_len;

    /* pre-allocate scratch buffer for unescaping */
    Newx(buf, len + 1, char);

    while (p < end) {
        /* skip trailing empty line */
        if (p + 1 == end && *p == '\n') break;

        row = newAV();
        line_start = p;

        while (p <= end) {
            int is_end_of_line = (p == end || *p == '\n');
            int is_tab = (!is_end_of_line && *p == '\t');

            if (is_end_of_line || is_tab) {
                const char *field_start = line_start;
                size_t field_len = p - field_start;

                /* check for \N (NULL) */
                if (field_len == 2 && field_start[0] == '\\' && field_start[1] == 'N') {
                    av_push(row, newSV(0));
                } else {
                    /* unescape */
                    buf_len = 0;
                    const char *s = field_start;
                    const char *s_end = field_start + field_len;
                    while (s < s_end) {
                        if (*s == '\\' && s + 1 < s_end) {
                            s++;
                            switch (*s) {
                                case 'n': buf[buf_len++] = '\n'; break;
                                case 't': buf[buf_len++] = '\t'; break;
                                case '\\': buf[buf_len++] = '\\'; break;
                                case '\'': buf[buf_len++] = '\''; break;
                                case '0': buf[buf_len++] = '\0'; break;
                                case 'a': buf[buf_len++] = '\a'; break;
                                case 'b': buf[buf_len++] = '\b'; break;
                                case 'f': buf[buf_len++] = '\f'; break;
                                case 'r': buf[buf_len++] = '\r'; break;
                                default: buf[buf_len++] = '\\'; buf[buf_len++] = *s; break;
                            }
                            s++;
                        } else {
                            buf[buf_len++] = *s++;
                        }
                    }
                    av_push(row, newSVpvn(buf, buf_len));
                }

                if (is_tab) {
                    p++;
                    line_start = p;
                } else {
                    if (p < end) p++; /* skip \n */
                    break;
                }
            } else {
                p++;
            }
        }
        av_push(rows, newRV_noinc((SV*)row));
    }

    Safefree(buf);
    return rows;
}

