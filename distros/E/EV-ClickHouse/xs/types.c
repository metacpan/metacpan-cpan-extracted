/* --- JSON column helpers (ported from Clickhouse::Encoder) ---
 * ClickHouse's stable JSON / Object('json') type (24.8+). Native wire
 * layout (V1+V2+V3) is documented in Clickhouse-Encoder/doc/json-research.
 * The encoder accepts a Perl hashref per row (auto-flattened to dotted
 * paths) and the decoder returns the same shape on the way back.
 * Supported leaf kinds: Int64, UInt64, Float64, Bool, String,
 * Array(<those>).
 */
typedef enum {
    JV_ARRAY_BOOL = 0,
    JV_ARRAY_FLOAT64,
    JV_ARRAY_INT64,
    JV_ARRAY_STRING,
    JV_ARRAY_UINT64,
    JV_BOOL,
    JV_FLOAT64,
    JV_INT64,
    JV_STRING,
    JV_UINT64,
    JV_KIND_COUNT
} json_kind_t;

/* Lex-sort position (0..N) for each kind in the variant list with
 * "SharedVariant" inserted. Sorted order:
 *   "Array(Bool)" < "Array(Float64)" < "Array(Int64)" < "Array(String)"
 *   < "Array(UInt64)" < "Bool" < "Float64" < "Int64" < "SharedVariant"
 *   < "String" < "UInt64".
 * SharedVariant takes lex pos 8. */
static const int json_kind_to_lex_pos[JV_KIND_COUNT] = {
    /* JV_ARRAY_BOOL    */ 0,
    /* JV_ARRAY_FLOAT64 */ 1,
    /* JV_ARRAY_INT64   */ 2,
    /* JV_ARRAY_STRING  */ 3,
    /* JV_ARRAY_UINT64  */ 4,
    /* JV_BOOL          */ 5,
    /* JV_FLOAT64       */ 6,
    /* JV_INT64         */ 7,
    /* JV_STRING        */ 9,
    /* JV_UINT64        */ 10
};

static const char * const json_kind_type_name[JV_KIND_COUNT] = {
    "Array(Bool)", "Array(Float64)", "Array(Int64)", "Array(String)",
    "Array(UInt64)",
    "Bool", "Float64", "Int64", "String", "UInt64"
};

#define JSON_SHAREDVARIANT_LEX_POS 8
#define JSON_LEX_SLOTS 11

/* Build the ordered wire-slot table: slots[disc] = kind (-1 for SharedVariant),
 * skipping kinds absent from mask. Returns the total wire-slot count
 * (present user kinds + 1 for the always-present SharedVariant slot). */
static int json_build_lex_table(unsigned mask, int slots[JSON_LEX_SLOTS]) {
    int n = 0, lex;
    for (lex = 0; lex < JSON_LEX_SLOTS; lex++) {
        if (lex == JSON_SHAREDVARIANT_LEX_POS) { slots[n++] = -1; continue; }
        int k;
        for (k = 0; k < JV_KIND_COUNT; k++) {
            if (json_kind_to_lex_pos[k] == lex && (mask & (1u << k))) {
                slots[n++] = k;
                break;
            }
        }
    }
    return n;
}

static int json_kind_disc_in(int kind, const int slots[JSON_LEX_SLOTS], int n) {
    int i;
    for (i = 0; i < n; i++) if (slots[i] == kind) return i;
    return -1;
}

static int json_pkg_is_bool(const char *pkg) {
    return pkg && (strcmp(pkg, "JSON::PP::Boolean") == 0
                || strcmp(pkg, "Types::Serialiser::Boolean") == 0
                || strcmp(pkg, "JSON::XS::Boolean") == 0
                || strcmp(pkg, "Cpanel::JSON::XS::Boolean") == 0
                || strcmp(pkg, "boolean") == 0);
}

static int json_is_bool_ref(pTHX_ SV *val) {
    if (!(SvROK(val) && sv_isobject(val))) return 0;
    HV *stash = SvSTASH(SvRV(val));
    return stash && json_pkg_is_bool(HvNAME(stash));
}

/* For an arrayref leaf, infer the element kind. Returns the matching
 * JV_ARRAY_* kind, or -1 if heterogeneous / unsupported. The two int
 * flavors unify: all-non-negative with a big UV becomes UInt64, while
 * a negative next to a big UV is unrepresentable and fails. */
static int json_classify_array(pTHX_ AV *av) {
    SSize_t n = av_len(av) + 1, i;
    int seen_kind = -1;
    int seen_uint = 0, seen_neg = 0;
    for (i = 0; i < n; i++) {
        SV **e = av_fetch(av, i, 0);
        if (e && *e && SvGMAGICAL(*e)) mg_get(*e);
        if (!e || !SvOK(*e)) continue;
        int leaf;
        if (SvROK(*e)) {
            if (json_is_bool_ref(aTHX_ *e)) leaf = JV_BOOL;
            else return -1;     /* nested arrays/hashes not supported in array leaves */
        }
#ifdef SvIsBOOL
        else if (SvIsBOOL(*e)) leaf = JV_BOOL;
#endif
        else if (SvIOK(*e) && !SvNOK(*e)) {
            if (SvIsUV(*e)) {
                if (SvUVX(*e) > (UV)INT64_MAX) {
                    leaf = JV_UINT64;
                    seen_uint = 1;
                } else {
                    leaf = JV_INT64;
                }
            } else {
                leaf = JV_INT64;
                if (SvIVX(*e) < 0) seen_neg = 1;
            }
        }
        else if (SvNOK(*e)) {
            NV nv = SvNV(*e);
            leaf = (nv == (NV)(int64_t)nv
                    && nv >= (NV)INT64_MIN && nv <= (NV)INT64_MAX)
                 ? JV_INT64 : JV_FLOAT64;
            if (leaf == JV_INT64 && nv < 0) seen_neg = 1;
        } else {
            leaf = JV_STRING;
        }
        if (leaf == JV_INT64 || leaf == JV_UINT64) {
            if (seen_kind == -1) seen_kind = JV_INT64;
            else if (seen_kind != JV_INT64) return -1;
        } else {
            if (seen_kind == -1) seen_kind = leaf;
            else if (seen_kind != leaf) return -1;
        }
    }
    if (seen_kind == -1) return JV_ARRAY_INT64;       /* empty/all-null */
    if (seen_kind == JV_INT64) {
        if (seen_neg && seen_uint) return -1;
        return seen_uint ? JV_ARRAY_UINT64 : JV_ARRAY_INT64;
    }
    switch (seen_kind) {
        case JV_BOOL:    return JV_ARRAY_BOOL;
        case JV_FLOAT64: return JV_ARRAY_FLOAT64;
        case JV_STRING:  return JV_ARRAY_STRING;
        default:         return -1;
    }
}

static int json_classify_leaf(pTHX_ SV *val) {
    if (json_is_bool_ref(aTHX_ val)) return JV_BOOL;
#ifdef SvIsBOOL
    if (SvIsBOOL(val)) return JV_BOOL;
#endif
    if (SvIOK(val) && !SvNOK(val))
        return (SvIsUV(val) && SvUVX(val) > (UV)INT64_MAX)
             ? JV_UINT64 : JV_INT64;
    if (SvNOK(val)) {
        NV n = SvNV(val);
        if (n == (NV)(int64_t)n && n >= (NV)INT64_MIN && n <= (NV)INT64_MAX)
            return JV_INT64;
        return JV_FLOAT64;
    }
    return JV_STRING;
}

/* Classify any JSON value SV. Routes arrayrefs through json_classify_array
 * and scalars/Booleans through json_classify_leaf. Returns -1 for an
 * unsupported reference (hashref, blessed non-Boolean) or for a
 * heterogeneous array. */
static int json_classify_value(pTHX_ SV *val) {
    if (SvROK(val) && !json_is_bool_ref(aTHX_ val)) {
        if (SvTYPE(SvRV(val)) != SVt_PVAV) return -1;
        return json_classify_array(aTHX_ (AV*)SvRV(val));
    }
    return json_classify_leaf(aTHX_ val);
}

static int json_kind_from_type_name(const char *ts, size_t tl) {
    if (tl == 4  && memcmp(ts, "Bool",            4)  == 0) return JV_BOOL;
    if (tl == 7  && memcmp(ts, "Float64",         7)  == 0) return JV_FLOAT64;
    if (tl == 5  && memcmp(ts, "Int64",           5)  == 0) return JV_INT64;
    if (tl == 6  && memcmp(ts, "String",          6)  == 0) return JV_STRING;
    if (tl == 11 && memcmp(ts, "Array(Bool)",     11) == 0) return JV_ARRAY_BOOL;
    if (tl == 14 && memcmp(ts, "Array(Float64)",  14) == 0) return JV_ARRAY_FLOAT64;
    if (tl == 12 && memcmp(ts, "Array(Int64)",    12) == 0) return JV_ARRAY_INT64;
    if (tl == 13 && memcmp(ts, "Array(String)",   13) == 0) return JV_ARRAY_STRING;
    if (tl == 13 && memcmp(ts, "Array(UInt64)",   13) == 0) return JV_ARRAY_UINT64;
    if (tl == 6  && memcmp(ts, "UInt64",           6) == 0) return JV_UINT64;
    return -1;
}

/* Recursively flatten a JSON value hash into a flat HV of dotted-path names. */
/* Returns 1 on success, 0 when a value isn't encodable. Never croaks:
 * the encoder also runs async (native INSERT sample-block time), where
 * a croak would kill the process instead of erroring the query. */
static int flatten_json_hash(pTHX_ HV *src,
                             const char *prefix, STRLEN prefix_len,
                             HV *out_flat) {
    int src_magical = SvRMAGICAL((SV *)src);
    hv_iterinit(src);
    HE *he;
    while ((he = hv_iternext(src))) {
        I32 klen;
        char *kstr = hv_iterkey(he, &klen);
        SV *vsv = hv_iterval(src, he);
        STRLEN new_len = prefix_len + (prefix_len ? 1 : 0) + klen;
        SV *path_sv = sv_2mortal(newSV(new_len));
        SvPOK_only(path_sv);
        char *pbuf = SvPVX(path_sv);
        if (prefix_len) {
            memcpy(pbuf, prefix, prefix_len);
            pbuf[prefix_len] = '.';
            memcpy(pbuf + prefix_len + 1, kstr, klen);
        } else {
            memcpy(pbuf, kstr, klen);
        }
        pbuf[new_len] = '\0';   /* keep the POK SV contract NUL-terminated */
        SvCUR_set(path_sv, new_len);
        /* A tied src yields lazy FETCH proxies: materialize for the
         * checks below, and store a plain copy (borrowing the mortal
         * proxy would re-FETCH on every later read). */
        if (SvGMAGICAL(vsv)) mg_get(vsv);
        if (SvROK(vsv) && SvTYPE(SvRV(vsv)) == SVt_PVHV
            && !json_is_bool_ref(aTHX_ vsv)) {
            if (sv_isobject(vsv))
                return 0;
            if (!flatten_json_hash(aTHX_ (HV*)SvRV(vsv),
                                   SvPVX(path_sv), new_len, out_flat))
                return 0;
        } else {
            /* Copy whatever is magical (already FETCHed above): the
             * flat hash outlives the borrow, and a later SvPV would
             * re-FETCH. Plain values borrow as before. */
            (void)hv_store(out_flat, SvPVX(path_sv), new_len,
                           (src_magical || SvGMAGICAL(vsv))
                               ? newSVsv_nomg(vsv)
                               : SvREFCNT_inc_simple_NN(vsv), 0);
        }
    }
    return 1;
}

/* (path, len) pair for sorting paths whose keys may contain embedded NULs. */
typedef struct { char *path; STRLEN len; } json_path_entry_t;

static int json_cmp_path_entry(const void *a, const void *b) {
    const json_path_entry_t *pa = (const json_path_entry_t *)a;
    const json_path_entry_t *pb = (const json_path_entry_t *)b;
    STRLEN n = pa->len < pb->len ? pa->len : pb->len;
    int r = memcmp(pa->path, pb->path, n);
    if (r) return r;
    if (pa->len < pb->len) return -1;
    if (pa->len > pb->len) return  1;
    return 0;
}

/* Emit one element of an Array(T) Dynamic variant. */
static void json_emit_array_elem(pTHX_ native_buf_t *b, SV *ev, int k_match) {
    switch (k_match) {
        case JV_ARRAY_BOOL:
            if (!SvOK(ev)) { nbuf_u8(b, 0); break; }
            { SV *bv = SvROK(ev) ? SvRV(ev) : ev;
              nbuf_u8(b, SvTRUE(bv) ? 1 : 0); break; }
        case JV_ARRAY_INT64:
            nbuf_le64(b, SvOK(ev) ? (uint64_t)(int64_t)SvIV(ev) : 0);
            break;
        case JV_ARRAY_UINT64:
            nbuf_le64(b, SvOK(ev) ? (uint64_t)SvUV(ev) : 0);
            break;
        case JV_ARRAY_FLOAT64:
            nbuf_ledouble(b, SvOK(ev) ? SvNV(ev) : 0.0);
            break;
        case JV_ARRAY_STRING: {
            if (!SvOK(ev)) { nbuf_varuint(b, 0); break; }
            STRLEN sl;
            const char *ss = SvPV(ev, sl);
            nbuf_string(b, ss, sl);
            break;
        }
    }
}

static void json_emit_scalar(pTHX_ native_buf_t *b, SV *val, int k_match) {
    switch (k_match) {
        case JV_BOOL: {
            SV *bv = SvROK(val) ? SvRV(val) : val;
            nbuf_u8(b, SvTRUE(bv) ? 1 : 0);
            break;
        }
        case JV_INT64:
            nbuf_le64(b, (uint64_t)(int64_t)SvIV(val));
            break;
        case JV_UINT64:
            nbuf_le64(b, (uint64_t)SvUV(val));
            break;
        case JV_FLOAT64:
            nbuf_ledouble(b, SvNV(val));
            break;
        case JV_STRING: {
            STRLEN sl;
            const char *s = SvPV(val, sl);
            nbuf_string(b, s, sl);
            break;
        }
        default: break;
    }
}

/* --- Native protocol column decoder --- */

/* Column type codes for decoding. */
enum {
    CT_INT8, CT_INT16, CT_INT32, CT_INT64,
    CT_UINT8, CT_UINT16, CT_UINT32, CT_UINT64,
    CT_FLOAT32, CT_FLOAT64, CT_BFLOAT16,
    CT_STRING, CT_FIXEDSTRING,
    CT_ARRAY, CT_NULLABLE,
    CT_DATE, CT_DATE32, CT_DATETIME, CT_DATETIME64,
    CT_UUID, CT_ENUM8, CT_ENUM16,
    CT_DECIMAL32, CT_DECIMAL64, CT_DECIMAL128, CT_DECIMAL256,
    CT_LOWCARDINALITY, CT_NOTHING,
    CT_BOOL, CT_IPV4, CT_IPV6,
    CT_INT128, CT_UINT128,
    CT_INT256, CT_UINT256,
    CT_TUPLE, CT_MAP,
    CT_JSON,
    CT_VARIANT, CT_DYNAMIC,
    CT_TIME, CT_TIME64,
    CT_UNKNOWN
};

typedef struct col_type_s col_type_t;
struct col_type_s {
    int code;
    int param;            /* FixedString(N), DateTime64 precision, Decimal scale */
    int precision;        /* Decimal total digits (0 = width default) */
    col_type_t *inner;    /* Nullable, Array, LowCardinality */
    col_type_t **inners;  /* Tuple elements, Map key+value, JSON typed paths */
    char **inner_names;   /* JSON typed path names (NULL for other types) */
    int num_inners;
    char *type_str;       /* full type string (for Enum label lookup) */
    size_t type_str_len;
    char *tz;             /* timezone for DateTime/DateTime64 (NULL = UTC) */
    ch_tz_t **zones;      /* zone cache to load tz from (NULL: process cache) */
    const ch_tz_t *zone;  /* tz once loaded */
    int zone_state;       /* 0 not loaded yet, 1 loaded, -1 failed */
};

static ch_tz_t *ch_tz_process_zones;

/* The column's zone, loaded on first use; NULL for UTC and on failure
 * (zone_state -1, see col_type_zone_error). */
static const ch_tz_t *col_zone(col_type_t *t) {
    if (!t->tz) return NULL;
    if (!t->zone_state) {
        char err[8];
        t->zone = ch_tz_load(t->zones ? t->zones : &ch_tz_process_zones,
                             t->tz, err, sizeof(err));
        t->zone_state = t->zone ? 1 : -1;
    }
    return t->zone;
}

/* The tz of the first node whose zone failed to load, else NULL. */
static const char *col_type_zone_error(const col_type_t *t) {
    int i;
    const char *e;
    if (!t) return NULL;
    if (t->zone_state < 0) return t->tz;
    if ((e = col_type_zone_error(t->inner))) return e;
    for (i = 0; i < t->num_inners; i++)
        if ((e = col_type_zone_error(t->inners[i]))) return e;
    return NULL;
}

static void free_col_type(col_type_t *t) {
    int i;
    if (!t) return;
    if (t->inner) free_col_type(t->inner);
    if (t->inners) {
        for (i = 0; i < t->num_inners; i++)
            free_col_type(t->inners[i]);
        Safefree(t->inners);
    }
    if (t->inner_names) {
        for (i = 0; i < t->num_inners; i++)
            if (t->inner_names[i]) Safefree(t->inner_names[i]);
        Safefree(t->inner_names);
    }
    if (t->type_str) Safefree(t->type_str);
    if (t->tz) Safefree(t->tz);
    Safefree(t);
}

/* Max nesting depth for parse_col_type recursion (hostile type strings
 * like "Array(Array(Array(..." are bounded only by the block size). */
#define PARSE_COL_TYPE_MAX_DEPTH 100

static col_type_t* parse_col_type_depth(const char *type, size_t len, int depth);
static col_type_t* parse_col_type(const char *type, size_t len);

/*
 * Parse comma-separated type list inside Tuple(...) or Map(...).
 * Handles nested parentheses correctly.
 * Sets t->inners and t->num_inners.
 */
/* Index of the quote closing the '...' literal opened at s[i] (an Enum
 * label may hold parens and commas), or len if unterminated. */
static size_t skip_quoted(const char *s, size_t len, size_t i) {
    for (i++; i < len; i++) {
        if (s[i] == '\\') i++;
        else if (s[i] == '\'') return i;
    }
    return len;
}

static void parse_type_list(col_type_t *t, const char *inner, size_t inner_len, int rec_depth) {
    int depth = 0, count = 0;
    size_t i, start = 0;
    int in_bt;

    if (inner_len == 0) return; /* Tuple() — zero inners */

    /* Count elements; `quoted names` and 'labels' shield parens/commas */
    in_bt = 0;
    for (i = 0; i <= inner_len; i++) {
        if (i < inner_len && inner[i] == '`') in_bt = !in_bt;
        else if (i < inner_len && in_bt) ;
        else if (i < inner_len && inner[i] == '\'') i = skip_quoted(inner, inner_len, i);
        else if (i < inner_len && inner[i] == '(') depth++;
        else if (i < inner_len && inner[i] == ')') depth--;
        else if (i == inner_len || (inner[i] == ',' && depth == 0))
            count++;
    }

    Newxz(t->inners, count, col_type_t*);
    t->num_inners = count;

    /* Parse each element */
    count = 0;
    depth = 0;
    in_bt = 0;
    start = 0;
    for (i = 0; i <= inner_len; i++) {
        if (i < inner_len && inner[i] == '`') in_bt = !in_bt;
        else if (i < inner_len && in_bt) ;
        else if (i < inner_len && inner[i] == '\'') i = skip_quoted(inner, inner_len, i);
        else if (i < inner_len && inner[i] == '(') depth++;
        else if (i < inner_len && inner[i] == ')') depth--;
        else if (i == inner_len || (inner[i] == ',' && depth == 0)) {
            size_t s = start, e = i;
            while (s < e && inner[s] == ' ') s++;
            while (e > s && inner[e-1] == ' ') e--;
            /* Strip named tuple field prefix: "name Type" -> "Type".
             * The split is the first space outside `quotes`/parens. */
            {
                size_t sp;
                int q = 0;
                for (sp = s; sp < e; sp++) {
                    if (inner[sp] == '`') q = !q;
                    else if (q) ;
                    else if (inner[sp] == '(') break; /* type w/ parens, stop */
                    else if (inner[sp] == ' ') {
                        s = sp + 1;
                        while (s < e && inner[s] == ' ') s++;
                        break;
                    }
                }
            }
            t->inners[count++] = parse_col_type_depth(inner + s, e - s, rec_depth + 1);
            start = i + 1;
        }
    }
}

static col_type_t* parse_col_type_depth(const char *type, size_t len, int depth) {
    col_type_t *t;
    if (depth > PARSE_COL_TYPE_MAX_DEPTH) {
        /* Fail the way an unparsable type fails: CT_UNKNOWN reads as String */
        Newxz(t, 1, col_type_t);
        t->code = CT_UNKNOWN;
        return t;
    }
    Newxz(t, 1, col_type_t);

    if (len == 4 && memcmp(type, "Int8", 4) == 0)          t->code = CT_INT8;
    else if (len == 5 && memcmp(type, "Int16", 5) == 0)     t->code = CT_INT16;
    else if (len == 5 && memcmp(type, "Int32", 5) == 0)     t->code = CT_INT32;
    else if (len == 5 && memcmp(type, "Int64", 5) == 0)     t->code = CT_INT64;
    else if (len > 8 && memcmp(type, "Interval", 8) == 0)   t->code = CT_INT64;
    else if (len == 5 && memcmp(type, "UInt8", 5) == 0)     t->code = CT_UINT8;
    else if (len == 6 && memcmp(type, "UInt16", 6) == 0)    t->code = CT_UINT16;
    else if (len == 6 && memcmp(type, "UInt32", 6) == 0)    t->code = CT_UINT32;
    else if (len == 6 && memcmp(type, "UInt64", 6) == 0)    t->code = CT_UINT64;
    else if (len == 7 && memcmp(type, "Float32", 7) == 0)   t->code = CT_FLOAT32;
    else if (len == 7 && memcmp(type, "Float64", 7) == 0)   t->code = CT_FLOAT64;
    else if (len == 6 && memcmp(type, "String", 6) == 0)    t->code = CT_STRING;
    else if (len > 12 && memcmp(type, "FixedString(", 12) == 0) {
        t->code = CT_FIXEDSTRING;
        t->param = atoi(type + 12);
        /* Clamp hostile negatives: param feeds (size_t) casts */
        if (t->param < 0) t->param = 0;
    }
    else if (len > 6 && memcmp(type, "Array(", 6) == 0) {
        t->code = CT_ARRAY;
        t->inner = parse_col_type_depth(type + 6, len - 7, depth + 1);
    }
    else if (len > 9 && memcmp(type, "Nullable(", 9) == 0) {
        t->code = CT_NULLABLE;
        t->inner = parse_col_type_depth(type + 9, len - 10, depth + 1);
    }
    else if (len > 15 && memcmp(type, "LowCardinality(", 15) == 0) {
        t->code = CT_LOWCARDINALITY;
        t->inner = parse_col_type_depth(type + 15, len - 16, depth + 1);
    }
    else if (len == 4 && memcmp(type, "Date", 4) == 0)      t->code = CT_DATE;
    else if (len == 6 && memcmp(type, "Date32", 6) == 0)    t->code = CT_DATE32;
    else if (len == 8 && memcmp(type, "DateTime", 8) == 0)  t->code = CT_DATETIME;
    else if (len > 9 && memcmp(type, "DateTime(", 9) == 0) {
        t->code = CT_DATETIME;
        /* DateTime('timezone') — extract timezone */
        {
            const char *q = memchr(type + 9, '\'', len - 9);
            if (q) {
                const char *qe = memchr(q + 1, '\'', type + len - q - 1);
                if (qe && qe > q + 1) {
                    size_t tzlen = qe - q - 1;
                    Newx(t->tz, tzlen + 1, char);
                    Copy(q + 1, t->tz, tzlen, char);
                    t->tz[tzlen] = '\0';
                }
            }
        }
    }
    else if (len > 11 && memcmp(type, "DateTime64(", 11) == 0) {
        t->code = CT_DATETIME64;
        t->param = atoi(type + 11);
        /* Clamp hostile precision (drives a per-row scale loop) */
        if (t->param < 0) t->param = 0;
        if (t->param > 9) t->param = 9;
        /* DateTime64(N, 'timezone') — extract timezone */
        {
            const char *comma = memchr(type + 11, ',', len - 11);
            if (comma) {
                const char *q = memchr(comma, '\'', type + len - comma);
                if (q) {
                    const char *qe = memchr(q + 1, '\'', type + len - q - 1);
                    if (qe && qe > q + 1) {
                        size_t tzlen = qe - q - 1;
                        Newx(t->tz, tzlen + 1, char);
                        Copy(q + 1, t->tz, tzlen, char);
                        t->tz[tzlen] = '\0';
                    }
                }
            }
        }
    }
    else if (len == 4 && memcmp(type, "Time", 4) == 0)      t->code = CT_TIME;
    else if (len > 7 && memcmp(type, "Time64(", 7) == 0) {
        t->code = CT_TIME64;
        t->param = atoi(type + 7);
        if (t->param < 0) t->param = 0;
        if (t->param > 9) t->param = 9;
    }
    else if (len == 4 && memcmp(type, "UUID", 4) == 0)      t->code = CT_UUID;
    else if (len > 6 && memcmp(type, "Enum8(", 6) == 0) {
        t->code = CT_ENUM8;
        Newx(t->type_str, len + 1, char);
        Copy(type, t->type_str, len, char);
        t->type_str[len] = '\0';
        t->type_str_len = len;
    }
    else if (len > 7 && memcmp(type, "Enum16(", 7) == 0) {
        t->code = CT_ENUM16;
        Newx(t->type_str, len + 1, char);
        Copy(type, t->type_str, len, char);
        t->type_str[len] = '\0';
        t->type_str_len = len;
    }
    else if (len > 10 && memcmp(type, "Decimal32(", 10) == 0) {
        t->code = CT_DECIMAL32;
        t->param = atoi(type + 10);
        t->precision = 9;
        /* Clamp hostile scale (drives per-row pow10 loops) */
        if (t->param < 0)  t->param = 0;
        if (t->param > 76) t->param = 76;
    }
    else if (len > 10 && memcmp(type, "Decimal64(", 10) == 0) {
        t->code = CT_DECIMAL64;
        t->param = atoi(type + 10);
        t->precision = 18;
        if (t->param < 0)  t->param = 0;
        if (t->param > 76) t->param = 76;
    }
    else if (len > 11 && memcmp(type, "Decimal128(", 11) == 0) {
        t->code = CT_DECIMAL128;
        t->param = atoi(type + 11);
        t->precision = 38;
        if (t->param < 0)  t->param = 0;
        if (t->param > 76) t->param = 76;
    }
    else if (len > 11 && memcmp(type, "Decimal256(", 11) == 0) {
        t->code = CT_DECIMAL256;
        t->param = atoi(type + 11);
        t->precision = 76;
        if (t->param < 0)  t->param = 0;
        if (t->param > 76) t->param = 76;
    }
    else if (len > 8 && memcmp(type, "Decimal(", 8) == 0) {
        int precision = atoi(type + 8);
        const char *comma = memchr(type + 8, ',', len - 8);
        t->param = comma ? atoi(comma + 1) : 0;
        if (t->param < 0)  t->param = 0;
        if (t->param > 76) t->param = 76;
        if (precision < 1)  precision = 1;
        if (precision > 76) precision = 76;
        t->precision = precision;
        if (precision <= 9)        t->code = CT_DECIMAL32;
        else if (precision <= 18)  t->code = CT_DECIMAL64;
        else if (precision <= 38)  t->code = CT_DECIMAL128;
        else                       t->code = CT_DECIMAL256;
    }
    else if (len == 8 && memcmp(type, "BFloat16", 8) == 0) t->code = CT_BFLOAT16;
    /* Variant(...) and Dynamic: recognised here so the schema parser
     * doesn't choke. Wire-format decoding is NOT generic — selecting
     * one produces a clean decode error from decode_column so the
     * caller's response parsing doesn't desync. Use
     * `SELECT toString(col) FROM …` server-side to read the value as
     * its JSON representation, or `CAST(col AS String)`. */
    else if (len > 8 && memcmp(type, "Variant(", 8) == 0) {
        t->code = CT_VARIANT;
    }
    else if (len == 7 && memcmp(type, "Dynamic", 7) == 0) {
        t->code = CT_DYNAMIC;
    }
    else if (len == 7 && memcmp(type, "Nothing", 7) == 0) t->code = CT_NOTHING;
    else if (len == 4 && memcmp(type, "Bool", 4) == 0)   t->code = CT_BOOL;
    else if (len == 4 && memcmp(type, "IPv4", 4) == 0)    t->code = CT_IPV4;
    else if (len == 4 && memcmp(type, "IPv6", 4) == 0)    t->code = CT_IPV6;
    else if (len == 6 && memcmp(type, "Int128", 6) == 0)  t->code = CT_INT128;
    else if (len == 7 && memcmp(type, "UInt128", 7) == 0) t->code = CT_UINT128;
    else if (len == 6 && memcmp(type, "Int256", 6) == 0)  t->code = CT_INT256;
    else if (len == 7 && memcmp(type, "UInt256", 7) == 0) t->code = CT_UINT256;
    else if (len > 6 && memcmp(type, "Tuple(", 6) == 0) {
        t->code = CT_TUPLE;
        parse_type_list(t, type + 6, len - 7, depth);
    }
    else if (len > 4 && memcmp(type, "Map(", 4) == 0) {
        t->code = CT_MAP;
        parse_type_list(t, type + 4, len - 5, depth);
    }
    else if (len > 7 && memcmp(type, "Nested(", 7) == 0) {
        /* Nested(name1 Type1, name2 Type2) = Array(Tuple(Type1, Type2)) */
        col_type_t *tuple;
        Newxz(tuple, 1, col_type_t);
        tuple->code = CT_TUPLE;
        parse_type_list(tuple, type + 7, len - 8, depth);
        t->code = CT_ARRAY;
        t->inner = tuple;
    }
    else if ((len == 4 && memcmp(type, "JSON", 4) == 0)
          || (len > 5 && memcmp(type, "JSON(", 5) == 0 && type[len-1] == ')')
          || (len > 7 && memcmp(type, "Object(", 7) == 0)) {
        /* ClickHouse stable JSON type (24.8+); Object('json') is the
         * legacy spelling. JSON(name Type, ...) pins specific paths to
         * concrete inner types ("typed paths"); those skip the
         * Dynamic+Variant wrap and write as regular columns inline. */
        t->code = CT_JSON;
        if (len > 5 && type[4] == '(') {
            /* parse "name Type, name Type, ..." */
            const char *body = type + 5;
            size_t blen = len - 6;
            int idx = 0, pdepth = 0, in_bt = 0;
            size_t start = 0, i;
            typedef struct { size_t name_start, name_len, type_start, type_len; }
                jp_bound_t;
            jp_bound_t bounds[64];
            for (i = 0; i <= blen; i++) {
                char c = (i < blen) ? body[i] : ',';
                if (c == '`' && i < blen) in_bt = !in_bt;
                else if (in_bt && i < blen) ;
                else if (c == '\'' && i < blen) i = skip_quoted(body, blen, i);
                else if (c == '(') pdepth++;
                else if (c == ')') pdepth--;
                else if ((c == ',' && pdepth == 0) || i == blen) {
                    size_t ts = start, te = i, id;
                    int q = 0;
                    while (ts < te && (body[ts]==' '||body[ts]=='\t')) ts++;
                    while (te > ts && (body[te-1]==' '||body[te-1]=='\t')) te--;
                    if (te > ts && idx < 64) {
                        /* split on first blank outside `quotes` */
                        for (id = ts; id < te; id++) {
                            if (body[id] == '`') q = !q;
                            else if (!q && (body[id] == ' ' || body[id] == '\t')) break;
                        }
                        {
                            size_t ws = id;
                            while (ws < te && (body[ws]==' '||body[ws]=='\t')) ws++;
                            if (id > ts && ws < te) {
                                /* strip `quoting` for name compare/store */
                                if (id - ts >= 2 && body[ts] == '`' && body[id-1] == '`') {
                                    ts++;
                                    id--;
                                }
                                bounds[idx].name_start = ts;
                                bounds[idx].name_len   = id - ts;
                                bounds[idx].type_start = ws;
                                bounds[idx].type_len   = te - ws;
                                idx++;
                            }
                        }
                    }
                    start = i + 1;
                }
            }
            if (idx > 0) {
                /* Sort by name (lex) — wire-order requirement. */
                int j;
                for (j = 1; j < idx; j++) {
                    int z = j;
                    while (z > 0) {
                        size_t la = bounds[z-1].name_len, lb = bounds[z].name_len;
                        size_t m = la < lb ? la : lb;
                        int cmp = memcmp(body + bounds[z-1].name_start,
                                         body + bounds[z].name_start, m);
                        if (cmp == 0) cmp = (int)la - (int)lb;
                        if (cmp <= 0) break;
                        jp_bound_t tmp = bounds[z-1];
                        bounds[z-1] = bounds[z];
                        bounds[z] = tmp;
                        z--;
                    }
                }
                t->num_inners = idx;
                Newxz(t->inners, idx, col_type_t *);
                Newxz(t->inner_names, idx, char *);
                for (j = 0; j < idx; j++) {
                    Newx(t->inner_names[j], bounds[j].name_len + 1, char);
                    memcpy(t->inner_names[j],
                           body + bounds[j].name_start, bounds[j].name_len);
                    t->inner_names[j][bounds[j].name_len] = '\0';
                    t->inners[j] = parse_col_type_depth(
                        body + bounds[j].type_start, bounds[j].type_len, depth + 1);
                }
            }
        }
    }
    /* Geo type aliases (per ClickHouse docs / Encoder layout) */
    else if (len == 5 && memcmp(type, "Point", 5) == 0) {
        /* Point = Tuple(Float64, Float64) */
        t->code = CT_TUPLE;
        parse_type_list(t, "Float64,Float64", 15, depth);
    }
    else if (len == 4 && memcmp(type, "Ring", 4) == 0) {
        /* Ring = Array(Point) */
        t->code = CT_ARRAY;
        t->inner = parse_col_type_depth("Point", 5, depth + 1);
    }
    else if (len == 10 && memcmp(type, "LineString", 10) == 0) {
        /* LineString = Array(Point) */
        t->code = CT_ARRAY;
        t->inner = parse_col_type_depth("Point", 5, depth + 1);
    }
    else if (len == 15 && memcmp(type, "MultiLineString", 15) == 0) {
        /* MultiLineString = Array(Array(Point)) */
        t->code = CT_ARRAY;
        t->inner = parse_col_type_depth("Array(Point)", 12, depth + 1);
    }
    else if (len == 7 && memcmp(type, "Polygon", 7) == 0) {
        /* Polygon = Array(Ring) */
        t->code = CT_ARRAY;
        t->inner = parse_col_type_depth("Ring", 4, depth + 1);
    }
    else if (len == 12 && memcmp(type, "MultiPolygon", 12) == 0) {
        /* MultiPolygon = Array(Polygon) */
        t->code = CT_ARRAY;
        t->inner = parse_col_type_depth("Polygon", 7, depth + 1);
    }
    else if ((len > 25 && memcmp(type, "SimpleAggregateFunction(", 24) == 0)
          || (len > 19 && memcmp(type, "AggregateFunction(", 18) == 0)) {
        /* (Simple)AggregateFunction(func, Type...) — skip func, parse inner.
         * For SAF this is exact. For full AggregateFunction the raw inner
         * type matches simple aggregates (sum/min/max etc) but is wrong
         * for complex states (quantile, uniqExact, ...) — for those, run
         * finalizeAggregation(col) server-side and read the result. */
        size_t off = (memcmp(type, "Simple", 6) == 0) ? 24 : 18;
        const char *inner = type + off;
        size_t inner_len = len - off - 1;
        size_t ci;
        int pdepth = 0;
        for (ci = 0; ci < inner_len; ci++) {
            if (inner[ci] == '\'') ci = skip_quoted(inner, inner_len, ci);
            else if (inner[ci] == '(') pdepth++;
            else if (inner[ci] == ')') pdepth--;
            else if (inner[ci] == ',' && pdepth == 0) break;
        }
        if (ci < inner_len) {
            ci++;
            while (ci < inner_len && inner[ci] == ' ') ci++;
            Safefree(t);
            t = parse_col_type_depth(inner + ci, inner_len - ci, depth + 1);
        } else {
            t->code = CT_UNKNOWN;
        }
    }
    else {
        /* Unknown type — treat as String (read raw bytes) */
        t->code = CT_UNKNOWN;
    }

    return t;
}

static col_type_t* parse_col_type(const char *type, size_t len) {
    return parse_col_type_depth(type, len, 0);
}

/* Structurally equal types; a timezone missing on either side matches
 * any (it means the session's). */
static int col_type_same(const col_type_t *a, const col_type_t *b) {
    int i;
    if (!a || !b) return a == b;
    if (a->code != b->code || a->code == CT_UNKNOWN || a->param != b->param
        || a->precision != b->precision || a->num_inners != b->num_inners)
        return 0;
    if (a->tz && b->tz && strcmp(a->tz, b->tz)) return 0;
    if ((a->code == CT_ENUM8 || a->code == CT_ENUM16)
        && (a->type_str_len != b->type_str_len
            || memcmp(a->type_str, b->type_str, a->type_str_len)))
        return 0;
    if (!col_type_same(a->inner, b->inner)) return 0;
    for (i = 0; i < a->num_inners; i++) {
        if (!col_type_same(a->inners[i], b->inners[i])) return 0;
        if (a->inner_names && b->inner_names
            && strcmp(a->inner_names[i] ? a->inner_names[i] : "",
                      b->inner_names[i] ? b->inner_names[i] : ""))
            return 0;
    }
    return 1;
}

/* Give tz-less DateTime/DateTime64 nodes the session's timezone (the
 * server reads and renders their wall times in it), and load zones from
 * the connection's cache. */
static void col_type_default_tz(col_type_t *t, const char *tz, ch_tz_t **zones) {
    int i;
    if (!t) return;
    t->zones = zones;
    if (tz && tz[0] && (t->code == CT_DATETIME || t->code == CT_DATETIME64)
        && !t->tz) {
        size_t n = strlen(tz);
        Newx(t->tz, n + 1, char);
        Copy(tz, t->tz, n + 1, char);
    }
    col_type_default_tz(t->inner, tz, zones);
    for (i = 0; i < t->num_inners; i++)
        col_type_default_tz(t->inners[i], tz, zones);
}

static const char *hv_session_tz(pTHX_ HV *hv) {
    SV **svp = hv ? hv_fetchs(hv, "session_timezone", 0) : NULL;
    if (!svp) return NULL;
    SvGETMAGIC(*svp);
    return SvOK(*svp) ? SvPV_nomg_nolen(*svp) : NULL;
}

/* The session_timezone a query is sent with: its own setting, else the
 * connection's. Read once at enqueue, so later decoding never runs user
 * code or sees the settings changed in flight. */
static char *query_session_tz(pTHX_ ev_clickhouse_t *self, HV *settings) {
    const char *tz = hv_session_tz(aTHX_ settings);
    if (!tz) tz = hv_session_tz(aTHX_ self->default_settings);
    return tz ? safe_strdup(tz) : NULL;
}

/* "" restores the server default, as on the server. */
static const char *effective_tz(ev_clickhouse_t *self, const char *query_tz) {
    return query_tz && query_tz[0] ? query_tz : self->server_timezone;
}

/* Size in bytes for fixed-width types. Returns 0 for variable-width. */
static size_t col_type_fixed_size(col_type_t *t) {
    switch (t->code) {
        case CT_INT8:  case CT_UINT8:  case CT_ENUM8:  case CT_BOOL: return 1;
        case CT_INT16: case CT_UINT16: case CT_ENUM16:
        case CT_DATE:  case CT_BFLOAT16: return 2;
        case CT_INT32: case CT_UINT32: case CT_FLOAT32:
        case CT_DECIMAL32: case CT_DATE32: case CT_DATETIME:
        case CT_IPV4: case CT_TIME: return 4;
        case CT_INT64: case CT_UINT64: case CT_FLOAT64:
        case CT_DECIMAL64: case CT_DATETIME64: case CT_TIME64: return 8;
        case CT_UUID: case CT_DECIMAL128:
        case CT_INT128: case CT_UINT128: case CT_IPV6: return 16;
        case CT_INT256: case CT_UINT256: case CT_DECIMAL256: return 32;
        case CT_FIXEDSTRING: return (size_t)t->param;
        default: return 0;
    }
}

/* --- Decode helper functions for opt-in type formatting --- */

/* Proleptic Gregorian date of a day count since 1970-01-01, in int64
 * (no time_t: 32-bit platforms would wrap past 2038). */
static void civil_from_days(int64_t days, int64_t *y, int *m, int *d) {
    int64_t era, yy;
    unsigned doe, yoe, doy, mp;
    days += 719468;
    era = (days >= 0 ? days : days - 146096) / 146097;
    doe = (unsigned)(days - era * 146097);
    yoe = (doe - doe / 1460 + doe / 36524 - doe / 146096) / 365;
    yy = (int64_t)yoe + era * 400;
    doy = doe - (365 * yoe + yoe / 4 - yoe / 100);
    mp = (5 * doy + 2) / 153;
    *d = (int)(doy - (153 * mp + 2) / 5 + 1);
    *m = (int)(mp < 10 ? mp + 3 : mp - 9);
    *y = yy + (*m <= 2);
}

/* "YYYY-MM-DD HH:MM:SS" of seconds since the epoch, into buf; length. */
static int format_civil_secs(int64_t secs, char *buf, size_t sz) {
    int64_t days = secs / 86400, rem = secs % 86400, y;
    int m, d;
    if (rem < 0) { rem += 86400; days--; }
    civil_from_days(days, &y, &m, &d);
    return snprintf(buf, sz, "%04lld-%02d-%02d %02d:%02d:%02d", (long long)y,
                    m, d, (int)(rem / 3600), (int)(rem / 60 % 60), (int)(rem % 60));
}

/* Convert days since Unix epoch to "YYYY-MM-DD". */
static SV* days_to_date_sv(int32_t days) {
    char buf[32];
    int64_t y;
    int m, d, n;
    civil_from_days(days, &y, &m, &d);
    n = snprintf(buf, sizeof(buf), "%04lld-%02d-%02d", (long long)y, m, d);
    return newSVpvn(buf, n);
}

/* Format a UNIX epoch as "YYYY-MM-DD HH:MM:SS" in zone (NULL = UTC). */
static SV* epoch_to_datetime_sv_ex(uint32_t epoch, const ch_tz_t *zone) {
    char buf[48];
    int n = format_civil_secs((int64_t)epoch + ch_tz_offset(zone, epoch),
                              buf, sizeof(buf));
    return newSVpvn(buf, n);
}

/* Convert DateTime64 to "YYYY-MM-DD HH:MM:SS.fff..." in zone (NULL = UTC) */
static SV* dt64_to_datetime_sv_ex(int64_t val, int precision, const ch_tz_t *zone) {
    int64_t scale = 1;
    int p;
    int64_t epoch, frac;
    char buf[64];
    int n;

    for (p = 0; p < precision; p++) scale *= 10;
    epoch = val / scale;
    frac = val % scale;
    if (frac < 0) { epoch--; frac += scale; }

    /* zone rules work in int years: beyond ~34000 years show UTC */
    if (epoch > -((int64_t)1 << 40) && epoch < ((int64_t)1 << 40))
        epoch += ch_tz_offset(zone, epoch);
    n = format_civil_secs(epoch, buf, 40);
    if (precision > 0) {
        char fracbuf[24];
        int fi;
        snprintf(fracbuf, sizeof(fracbuf), "%0*lld", precision, (long long)frac);
        buf[n++] = '.';
        for (fi = 0; fi < precision && n < 63; fi++)
            buf[n++] = fracbuf[fi];
    }
    return newSVpvn(buf, n);
}

/* Wall time given as seconds-as-if-UTC, read in the column's zone; *ok
 * is 0 when that zone cannot be loaded. */
static int64_t wall_in_tz_to_epoch(int64_t utc_wall, col_type_t *ct, int *ok) {
    const ch_tz_t *zone = col_zone(ct);
    *ok = !(ct->tz && !zone);
    return ch_tz_wall_to_epoch(zone, utc_wall);
}

/* Compute 10^n as double */
static double pow10_int(int n) {
    double r = 1.0;
    int i;
    for (i = 0; i < n; i++) r *= 10.0;
    return r;
}

/* Parse enum label for a given code from type string like "Enum8('a'=1,'b'=2)" */
static SV* enum_label_for_code(const char *type_str, size_t type_str_len, int code) {
    /* Find the opening '(' */
    const char *p = memchr(type_str, '(', type_str_len);
    const char *end;
    if (!p) return newSViv(code);
    p++;
    end = type_str + type_str_len - 1; /* skip closing ')' */

    while (p < end) {
        /* Skip whitespace */
        while (p < end && *p == ' ') p++;
        if (p >= end || *p != '\'') break;
        p++; /* skip opening quote */

        /* Read label (handle escaped quotes) */
        {
            const char *label_start = p;
            size_t label_len;
            int val;

            while (p < end) {
                if (*p == '\\' && p + 1 < end) { p += 2; continue; }
                if (*p == '\'') {
                    if (p + 1 < end && *(p+1) == '\'') { p += 2; continue; }
                    break;
                }
                p++;
            }
            label_len = p - label_start;
            if (p < end) p++; /* skip closing quote */

            /* Skip ' = ' */
            while (p < end && (*p == ' ' || *p == '=')) p++;

            /* Read integer value */
            val = (int)strtol(p, NULL, 10);

            if (val == code) {
                /* Labels carry C-style escapes on the wire (\' \\ \t
                 * ...) and possibly '' doubling: restore both. */
                const char *r = label_start, *span_end, *q, *span;
                char *out, *w;
                span = label_start + label_len;
                for (q = label_start; q < span; q++) {
                    if (*q == '\\') break;
                    if (*q == '\'' && q + 1 < span && q[1] == '\'') break;
                }
                if (q >= span)
                    return newSVpvn(label_start, label_len);
                Newx(out, label_len + 1, char);
                w = out;
                span_end = span;
                while (r < span_end) {
                    if (*r == '\\' && r + 1 < span_end) {
                        char e = *++r;
                        switch (e) {
                        case 't': *w++ = '\t'; break;
                        case 'n': *w++ = '\n'; break;
                        case 'r': *w++ = '\r'; break;
                        case 'b': *w++ = '\b'; break;
                        case 'f': *w++ = '\f'; break;
                        case 'v': *w++ = '\v'; break;
                        case '0': *w++ = '\0'; break;
                        default:  *w++ = e; break;
                        }
                        r++;
                        continue;
                    }
                    if (*r == '\'' && r + 1 < span_end && r[1] == '\'') r++;
                    *w++ = *r++;
                }
                {
                    SV *sv = newSVpvn(out, w - out);
                    Safefree(out);
                    return sv;
                }
            }

            /* Skip to next entry */
            while (p < end && *p != ',') p++;
            if (p < end) p++; /* skip comma */
        }
    }
    /* Not found — return numeric code */
    return newSViv(code);
}

/* Decoded Enum entry for label lookup on insert. */
typedef struct {
    char *label;
    size_t len;
    int code;
} enum_entry_t;

/* Parse "Enum8('a' = 1, ...)" once per column into decoded entries.
 * Mirrors enum_label_for_code's label scanning (C escapes, '' doubling).
 * Returns the entry count; free with enum_free_entries. */
static size_t enum_parse_entries(const char *type_str, size_t type_str_len,
                                 enum_entry_t **out) {
    const char *p, *end;
    size_t n = 0, cap = 0;
    enum_entry_t *entries = NULL;
    *out = NULL;
    if (!type_str) return 0;
    p = memchr(type_str, '(', type_str_len);
    if (!p) return 0;
    p++;
    end = type_str + type_str_len - 1;
    while (p < end) {
        const char *label_start, *span_end, *r;
        size_t raw_len, dlen = 0;
        char *dec = NULL;
        int code;
        while (p < end && *p == ' ') p++;
        if (p >= end || *p != '\'') break;
        p++;
        label_start = p;
        while (p < end) {
            if (*p == '\\' && p + 1 < end) { p += 2; continue; }
            if (*p == '\'') {
                if (p + 1 < end && *(p+1) == '\'') { p += 2; continue; }
                break;
            }
            p++;
        }
        raw_len = p - label_start;
        if (p < end) p++;
        while (p < end && (*p == ' ' || *p == '=')) p++;
        code = (int)strtol(p, NULL, 10);
        if (raw_len > 0) {
            Newx(dec, raw_len, char);
            span_end = label_start + raw_len;
            r = label_start;
            while (r < span_end) {
                if (*r == '\\' && r + 1 < span_end) {
                    char e = *++r;
                    switch (e) {
                    case 't': dec[dlen++] = '\t'; break;
                    case 'n': dec[dlen++] = '\n'; break;
                    case 'r': dec[dlen++] = '\r'; break;
                    case 'b': dec[dlen++] = '\b'; break;
                    case 'f': dec[dlen++] = '\f'; break;
                    case 'v': dec[dlen++] = '\v'; break;
                    case '0': dec[dlen++] = '\0'; break;
                    default:  dec[dlen++] = e; break;
                    }
                    r++;
                    continue;
                }
                if (*r == '\'' && r + 1 < span_end && r[1] == '\'') r++;
                dec[dlen++] = *r++;
            }
        }
        if (n == cap) {
            cap = cap ? cap * 2 : 8;
            Renew(entries, cap, enum_entry_t);
        }
        entries[n].label = dec;
        entries[n].len = dlen;
        entries[n].code = code;
        n++;
        while (p < end && *p != ',') p++;
        if (p < end) p++;
    }
    *out = entries;
    return n;
}

static void enum_free_entries(enum_entry_t *entries, size_t n) {
    size_t i;
    for (i = 0; i < n; i++)
        Safefree(entries[i].label);
    Safefree(entries);
}

static int enum_code_for_label(const enum_entry_t *entries, size_t n,
                               const char *s, size_t len, int *code_out) {
    size_t i;
    for (i = 0; i < n; i++) {
        if (entries[i].len == len
            && (len == 0 || memcmp(entries[i].label, s, len) == 0)) {
            *code_out = entries[i].code;
            return 1;
        }
    }
    return 0;
}

/*
 * Decode a column of `nrows` values from the native binary format.
 * Returns an array of SVs (one per row). Returns NULL on failure.
 * Sets *decode_err=1 on definitive errors (vs needing more data).
 * Advances *pos past the consumed bytes.
 */

#ifdef __SIZEOF_INT128__
static SV* int128_to_sv(const char *p, int is_signed) {
    unsigned __int128 uv;
    char dbuf[42];
    int dlen = 0, neg = 0, k;
    if (is_signed) {
        __int128 sv;
        memcpy(&sv, p, 16);
        neg = sv < 0;
        uv = neg ? -(unsigned __int128)sv : (unsigned __int128)sv;
    } else {
        memcpy(&uv, p, 16);
    }
    do {
        dbuf[dlen++] = '0' + (int)(uv % 10);
        uv /= 10;
    } while (uv);
    if (neg) dbuf[dlen++] = '-';
    for (k = 0; k < dlen/2; k++) {
        char tmp = dbuf[k]; dbuf[k] = dbuf[dlen-1-k]; dbuf[dlen-1-k] = tmp;
    }
    return newSVpvn(dbuf, dlen);
}
#endif

/* Convert a 256-bit LE unsigned integer (as 4 x uint64_t) to decimal string.
 * Works on all platforms (no __int128 required). */
static SV* uint256_to_sv(const char *p) {
    /* Copy into 4 x uint64_t LE limbs: v[0] = lowest */
    uint64_t v[4];
    char dbuf[80];
    int dlen = 0, k;

    memcpy(v, p, 32);

    /* Handle zero */
    if (v[0] == 0 && v[1] == 0 && v[2] == 0 && v[3] == 0)
        return newSVpvn("0", 1);

    /* Repeatedly divide by 10, collecting remainders */
    while (v[0] || v[1] || v[2] || v[3]) {
        uint64_t rem = 0;
        int i;
        for (i = 3; i >= 0; i--) {
#ifdef __SIZEOF_INT128__
            unsigned __int128 cur = ((unsigned __int128)rem << 64) | v[i];
            v[i] = (uint64_t)(cur / 10);
            rem = (uint64_t)(cur % 10);
#else
            /* Without 128-bit: split each 64-bit limb into hi32:lo32 */
            uint64_t hi = (rem << 32) | (v[i] >> 32);
            uint64_t q_hi = hi / 10;
            uint64_t r_hi = hi % 10;
            uint64_t lo = (r_hi << 32) | (v[i] & 0xFFFFFFFFULL);
            uint64_t q_lo = lo / 10;
            rem = lo % 10;
            v[i] = (q_hi << 32) | q_lo;
#endif
        }
        dbuf[dlen++] = '0' + (int)rem;
    }
    for (k = 0; k < dlen/2; k++) {
        char tmp = dbuf[k]; dbuf[k] = dbuf[dlen-1-k]; dbuf[dlen-1-k] = tmp;
    }
    return newSVpvn(dbuf, dlen);
}

static SV* int256_to_sv(const char *p, int is_signed) {
    if (is_signed && ((unsigned char)p[31] & 0x80)) {
        /* Negative: two's complement negate, format, prepend '-' */
        unsigned char neg[32];
        int i, carry = 1;
        SV *sv;
        STRLEN svlen;
        char *s;
        for (i = 0; i < 32; i++) {
            int b = (unsigned char)(~((unsigned char)p[i])) + carry;
            neg[i] = (unsigned char)(b & 0xFF);
            carry = b >> 8;
        }
        sv = uint256_to_sv((const char *)neg);
        /* Prepend '-' */
        s = SvPV(sv, svlen);
        {
            SV *result = newSV(svlen + 1);
            SvPOK_on(result);
            SvCUR_set(result, svlen + 1);
            *SvPVX(result) = '-';
            Copy(s, SvPVX(result) + 1, svlen, char);
            SvPVX(result)[svlen + 1] = '\0';
            SvREFCNT_dec(sv);
            return result;
        }
    }
    return uint256_to_sv(p);
}

/* Native sends every serialization state prefix of a column's type tree,
 * depth first, before any of its data; the only one we meet outside JSON
 * is the LowCardinality keys version. 1 = ok, 0 = need more, -1 = bad. */
static int read_col_prefix(const char *buf, size_t len, size_t *pos,
                           col_type_t *ct) {
    int i, rc;
    switch (ct->code) {
    case CT_LOWCARDINALITY: {
        uint64_t version;
        if (*pos > len || len - *pos < 8) return 0;
        memcpy(&version, buf + *pos, 8);
        if (version != 1) return -1;
        *pos += 8;
        return 1;
    }
    case CT_ARRAY:
    case CT_NULLABLE:
        return ct->inner ? read_col_prefix(buf, len, pos, ct->inner) : 1;
    case CT_TUPLE:
    case CT_MAP:
        for (i = 0; i < ct->num_inners; i++)
            if ((rc = read_col_prefix(buf, len, pos, ct->inners[i])) <= 0)
                return rc;
        return 1;
    default:
        return 1;
    }
}

static SV** decode_column_data(const char *buf, size_t len, size_t *pos,
                               uint64_t nrows, col_type_t *ct, int *decode_err,
                               uint32_t decode_flags, ev_clickhouse_t *lc_self,
                               int lc_col_idx);

static SV** decode_data(const char *buf, size_t len, size_t *pos,
                        uint64_t nrows, col_type_t *ct, int *decode_err,
                        uint32_t decode_flags) {
    return decode_column_data(buf, len, pos, nrows, ct, decode_err, decode_flags, NULL, -1);
}

/* One whole column of a block: prefixes, then data. */
static SV** decode_column_ex(const char *buf, size_t len, size_t *pos,
                             uint64_t nrows, col_type_t *ct, int *decode_err,
                             uint32_t decode_flags, ev_clickhouse_t *lc_self,
                             int lc_col_idx) {
    if (nrows) {
        int rc = read_col_prefix(buf, len, pos, ct);
        if (rc <= 0) {
            if (rc < 0 && decode_err) *decode_err = 1;
            return NULL;
        }
    }
    return decode_column_data(buf, len, pos, nrows, ct, decode_err, decode_flags,
                              lc_self, lc_col_idx);
}

static SV** decode_column(const char *buf, size_t len, size_t *pos,
                           uint64_t nrows, col_type_t *ct, int *decode_err,
                           uint32_t decode_flags) {
    return decode_column_ex(buf, len, pos, nrows, ct, decode_err, decode_flags, NULL, -1);
}

static SV** decode_column_data(const char *buf, size_t len, size_t *pos,
                               uint64_t nrows, col_type_t *ct, int *decode_err,
                               uint32_t decode_flags, ev_clickhouse_t *lc_self,
                               int lc_col_idx) {
    SV **out;
    uint64_t i;
    size_t fsz;

    /* Bound nrows against the remaining buffer before allocating out[].
     * Every wire column consumes at least one byte per row (a value, an
     * offset, a null-map byte or an index), so a row count larger than the
     * bytes left cannot be satisfied yet.  Return NULL WITHOUT setting
     * decode_err -- exactly the per-type need-more convention -- so the caller
     * treats it as "need more data" on the incremental (uncompressed) path and
     * as a hard error on the compressed path (where the whole block is already
     * present).  This caps the out[] allocation to the available data and
     * stops a hostile server forcing a huge alloc from a tiny message, while
     * also covering recursive Array/Map/Tuple/LowCardinality element counts.
     * No exception for FixedString(0): real servers reject it outright,
     * so it can only arrive from a hostile one. (An empty Tuple() takes
     * a 1-byte-per-row placeholder on the wire, so the bound holds.) */
    if (*pos > len) return NULL;
    if (nrows > (uint64_t)(len - *pos)) {
        return NULL;
    }

    Newxz(out, nrows ? nrows : 1, SV*);

    if (ct->code == CT_NOTHING) {
        /* Nothing type: 1 placeholder byte ('0') per row */
        if (*pos > len || nrows > len - *pos) goto fail;
        *pos += nrows;
        for (i = 0; i < nrows; i++)
            out[i] = newSV(0);
        return out;
    }

    if (ct->code == CT_VARIANT || ct->code == CT_DYNAMIC) {
        /* The wire format is per-version and includes shared substream
         * dispatch we don't replicate here. Set decode_err so the calling
         * parser surfaces a clean error and tears the connection down,
         * instead of trying to read garbage strings (which would desync
         * every subsequent column). Recommend a server-side workaround. */
        if (decode_err) *decode_err = 1;
        goto fail;
    }

    if (ct->code == CT_NULLABLE) {
        /* null bitmap: nrows bytes of UInt8 */
        uint8_t *nulls;
        SV **inner;
        if (*pos > len || nrows > len - *pos) goto fail;
        Newx(nulls, nrows, uint8_t);
        Copy(buf + *pos, nulls, nrows, uint8_t);
        *pos += nrows;

        /* decode inner column */
        inner = decode_data(buf, len, pos, nrows, ct->inner, decode_err, decode_flags);
        if (!inner) { Safefree(nulls); goto fail; }

        for (i = 0; i < nrows; i++) {
            if (nulls[i]) {
                SvREFCNT_dec(inner[i]);
                out[i] = newSV(0); /* undef */
            } else {
                out[i] = inner[i];
            }
        }
        Safefree(nulls);
        Safefree(inner);
        return out;
    }

    if (ct->code == CT_LOWCARDINALITY) {
        /*
         * LowCardinality wire format (all multi-byte integers are UInt64 LE):
         *   PREFIX:  UInt64 key_version, read by read_col_prefix()
         *   DATA:    UInt64 serialization_type (bits 0-7: index type,
         *            bit 8: NeedGlobalDictionary, bit 9: HasAdditionalKeys,
         *            bit 10: NeedUpdateDictionary)
         *            if NeedUpdateDictionary: UInt64 num_keys + dictionary data
         *            UInt64 num_indices + index data
         *   Zero rows (an empty nested array) carry no DATA at all.
         */
        uint64_t ser_type, num_keys = 0, num_indices;
        size_t saved = *pos;
        int key_type;
        size_t idx_size;
        SV **dict = NULL;
        int dict_borrowed = 0;  /* 1 if dict points to lc_self storage */
        /* LC(Nullable(T)) dictionaries travel as plain T with slot 0
         * reserved for NULL (the server synthesizes the null map). */
        int dict_nullable = ct->inner && ct->inner->code == CT_NULLABLE;
        col_type_t *dict_ct = dict_nullable ? ct->inner->inner : ct->inner;

        if (nrows == 0) return out;

        /* serialization_type: UInt64 */
        if (*pos + 8 > len) goto lc_fail;
        memcpy(&ser_type, buf + *pos, 8); *pos += 8;

        key_type = (int)(ser_type & 0xFF);
        /* key_type: 0=UInt8, 1=UInt16, 2=UInt32, 3=UInt64 */
        if (key_type > 3 || (ser_type & ~(uint64_t)0x6FF)) {
            if (decode_err) *decode_err = 1;
            goto lc_fail;
        }

        /* Read dictionary if NeedUpdateDictionary (bit 10) */
        if (ser_type & (1ULL << 10)) {
            if (*pos + 8 > len) goto lc_fail;
            memcpy(&num_keys, buf + *pos, 8); *pos += 8;

            dict = decode_data(buf, len, pos, num_keys, dict_ct, decode_err, decode_flags);
            if (!dict) goto lc_fail;
        } else {
            /* NeedUpdateDictionary=0: reuse dictionary from prior block */
            if (lc_self && lc_col_idx >= 0 && lc_col_idx < lc_self->lc_num_cols
                && lc_self->lc_dicts[lc_col_idx]) {
                dict = lc_self->lc_dicts[lc_col_idx];
                num_keys = lc_self->lc_dict_sizes[lc_col_idx];
                dict_borrowed = 1;
            } else {
                if (decode_err) *decode_err = 1;
                goto lc_fail;
            }
        }

        /* Read indices: UInt64 num_indices + index data */
        if (*pos + 8 > len) goto lc_fail;
        memcpy(&num_indices, buf + *pos, 8); *pos += 8;

        idx_size = (key_type == 0) ? 1 : (key_type == 1) ? 2 :
                   (key_type == 2) ? 4 : 8;
        if (num_indices != nrows) {
            if (decode_err) *decode_err = 1;
            goto lc_fail;
        }
        if (*pos > len || num_indices > (len - *pos) / idx_size) goto lc_fail;
        for (i = 0; i < nrows; i++) {
            uint64_t idx = 0;
            memcpy(&idx, buf + *pos + i * idx_size, idx_size);
            if (idx >= num_keys) {
                if (decode_err) *decode_err = 1;
                goto lc_fail;
            }
        }

        /* Store new dictionary for cross-block reuse (after validation) */
        if (!dict_borrowed && lc_self && lc_col_idx >= 0 && lc_col_idx < lc_self->lc_num_cols) {
            if (lc_self->lc_dicts[lc_col_idx]) {
                uint64_t di;
                for (di = 0; di < lc_self->lc_dict_sizes[lc_col_idx]; di++)
                    SvREFCNT_dec(lc_self->lc_dicts[lc_col_idx][di]);
                Safefree(lc_self->lc_dicts[lc_col_idx]);
            }
            SV **dcopy;
            Newx(dcopy, num_keys > 0 ? num_keys : 1, SV*);
            for (i = 0; i < num_keys; i++)
                dcopy[i] = SvREFCNT_inc(dict[i]);
            lc_self->lc_dicts[lc_col_idx] = dcopy;
            lc_self->lc_dict_sizes[lc_col_idx] = num_keys;
        }

        for (i = 0; i < nrows; i++) {
            uint64_t idx = 0;
            memcpy(&idx, buf + *pos + i * idx_size, idx_size);
            if (dict_nullable && idx == 0)
                out[i] = newSV(0);
            else
                out[i] = SvREFCNT_inc(dict[idx]);
        }
        *pos += num_indices * idx_size;

        if (dict && !dict_borrowed) {
            for (i = 0; i < num_keys; i++) SvREFCNT_dec(dict[i]);
            Safefree(dict);
        }
        return out;

    lc_fail:
        if (dict && !dict_borrowed) {
            for (i = 0; i < num_keys; i++) SvREFCNT_dec(dict[i]);
            Safefree(dict);
        }
        *pos = saved;
        goto fail;
    }

    if (ct->code == CT_STRING) {
        for (i = 0; i < nrows; i++) {
            const char *s;
            size_t slen;
            if (read_native_string_ref(buf, len, pos, &s, &slen) <= 0) {
                /* clean up already-created SVs */
                uint64_t j;
                for (j = 0; j < i; j++) SvREFCNT_dec(out[j]);
                goto fail;
            }
            out[i] = newSVpvn(s, slen);
        }
        return out;
    }

    if (ct->code == CT_ARRAY) {
        /* offsets: nrows x UInt64 */
        uint64_t *offsets;
        SV **elems;
        uint64_t total, prev;

        if (*pos > len || nrows > (len - *pos) / 8) goto fail;
        Newx(offsets, nrows, uint64_t);
        Copy(buf + *pos, offsets, nrows, uint64_t);
        *pos += nrows * 8;

        /* validate offset monotonicity */
        prev = 0;
        for (i = 0; i < nrows; i++) {
            if (offsets[i] < prev) {
                Safefree(offsets);
                if (decode_err) *decode_err = 1;
                goto fail;
            }
            prev = offsets[i];
        }

        total = nrows > 0 ? offsets[nrows - 1] : 0;

        /* decode all inner elements */
        elems = decode_data(buf, len, pos, total, ct->inner, decode_err, decode_flags);
        if (!elems) { Safefree(offsets); goto fail; }

        /* build AV for each row */
        prev = 0;
        for (i = 0; i < nrows; i++) {
            uint64_t count = offsets[i] - prev;
            AV *av = newAV();
            uint64_t j;
            if (count > 0) av_extend(av, count - 1);
            for (j = 0; j < count; j++) {
                av_push(av, elems[prev + j]);
            }
            out[i] = newRV_noinc((SV*)av);
            prev = offsets[i];
        }

        Safefree(offsets);
        Safefree(elems);
        return out;
    }

    if (ct->code == CT_TUPLE) {
        /* Tuple: each element is a separate column, transpose to row arrays */
        SV ***cols = NULL;
        int j;

        if (ct->num_inners == 0) {
            /* Empty Tuple(): 1 placeholder byte per row on the wire */
            if (*pos > len || nrows > len - *pos) goto fail;
            *pos += nrows;
        }
        else {
        Newxz(cols, ct->num_inners, SV**);
        for (j = 0; j < ct->num_inners; j++) {
            cols[j] = decode_data(buf, len, pos, nrows, ct->inners[j], decode_err, decode_flags);
            if (!cols[j]) {
                int k;
                for (k = 0; k < j; k++) {
                    for (i = 0; i < nrows; i++) SvREFCNT_dec(cols[k][i]);
                    Safefree(cols[k]);
                }
                Safefree(cols);
                goto fail;
            }
        }
        }

        for (i = 0; i < nrows; i++) {
            AV *av = newAV();
            if (ct->num_inners > 0) av_extend(av, ct->num_inners - 1);
            for (j = 0; j < ct->num_inners; j++)
                av_push(av, cols[j][i]);
            out[i] = newRV_noinc((SV*)av);
        }

        if (cols) {
            for (j = 0; j < ct->num_inners; j++) Safefree(cols[j]);
            Safefree(cols);
        }
        return out;
    }

    if (ct->code == CT_JSON) {
        /* Wire layout (V1/V2/V3 supported); see JSON helpers + Encoder docs. */
        size_t saved = *pos;
        uint64_t obj_ver;
        uint64_t num_paths64;
        json_path_entry_t *jpe = NULL;
        int *path_kinds_buf = NULL;     /* concatenated [path][kind_idx] */
        int *path_kind_count = NULL;
        int wire_slots_cleanup = 0;     /* slot-count for var_avs cleanup */
        AV **var_avs = NULL;
        uint64_t *offs = NULL;
        AV *pending_inner = NULL;
        int p;

        if (*pos > len || len - *pos < 8) goto json_fail;
        memcpy(&obj_ver, buf + *pos, 8); *pos += 8;
        if (obj_ver != 0 && obj_ver != 2 && obj_ver != 4) goto json_hard;
        if (obj_ver == 0) {
            uint64_t dummy;
            if (read_varuint(buf, len, pos, &dummy) <= 0) goto json_fail;
        }
        if (read_varuint(buf, len, pos, &num_paths64) <= 0) goto json_fail;
        if (num_paths64 > (uint64_t)INT_MAX) goto json_hard;
        /* each path serializes to >=1 wire byte, so a count larger than the
         * bytes left is malformed -- bound before the (jpe/path_kind) allocs */
        if (num_paths64 > (uint64_t)(len - *pos)) goto json_fail;
        int num_paths = (int)num_paths64;

        if (num_paths > 0) {
            Newx(jpe, num_paths, json_path_entry_t);
            Newxz(path_kind_count, num_paths, int);
            Newxz(path_kinds_buf,  num_paths * JSON_LEX_SLOTS, int);
        }
        for (p = 0; p < num_paths; p++) {
            const char *ps; size_t pl;
            if (read_native_string_ref(buf, len, pos, &ps, &pl) <= 0) goto json_fail;
            jpe[p].path = (char*)ps;
            jpe[p].len  = pl;
        }
        if (obj_ver == 4) {
            uint64_t shared_ver, dummy;
            if (read_varuint(buf, len, pos, &shared_ver) <= 0) goto json_fail;
            if (shared_ver == 1 || shared_ver == 2)
                if (read_varuint(buf, len, pos, &dummy) <= 0) goto json_fail;
        }
        for (p = 0; p < ct->num_inners; p++) {
            int prc = read_col_prefix(buf, len, pos, ct->inners[p]);
            if (prc == 0) goto json_fail;
            if (prc < 0) goto json_hard;
        }

        for (p = 0; p < num_paths; p++) {
            uint64_t dyn_ver, var_mode, ntypes;
            if (*pos > len || len - *pos < 8) goto json_fail;
            memcpy(&dyn_ver, buf + *pos, 8); *pos += 8;
            if (dyn_ver != 1 && dyn_ver != 2 && dyn_ver != 4) goto json_hard;
            if (dyn_ver == 1) {
                uint64_t dummy;
                if (read_varuint(buf, len, pos, &dummy) <= 0) goto json_fail;
            }
            if (read_varuint(buf, len, pos, &ntypes) <= 0) goto json_fail;
            if (ntypes >= (uint64_t)JSON_LEX_SLOTS) goto json_hard;
            int *kinds = path_kinds_buf + p * JSON_LEX_SLOTS;
            uint64_t ti;
            for (ti = 0; ti < ntypes; ti++) {
                const char *ts; size_t tl;
                if (read_native_string_ref(buf, len, pos, &ts, &tl) <= 0) goto json_fail;
                int k = json_kind_from_type_name(ts, tl);
                if (k < 0) goto json_hard;
                kinds[ti] = k;
            }
            path_kind_count[p] = (int)ntypes;
            if (*pos > len || len - *pos < 8) goto json_fail;
            memcpy(&var_mode, buf + *pos, 8); *pos += 8;
            if (var_mode != 0) goto json_hard;
        }

        /* Allocate per-row hashref. */
        for (i = 0; i < nrows; i++) out[i] = newRV_noinc((SV*)newHV());

        /* Typed-path data first (in declaration order). For each typed path,
         * decode a regular column via inner type, then store per-row into
         * out[i]'s hashref under the typed-path name. */
        if (ct->num_inners > 0) {
            int tp;
            for (tp = 0; tp < ct->num_inners; tp++) {
                SV **tpcol = decode_data(buf, len, pos, (uint64_t)nrows,
                                         ct->inners[tp], decode_err, decode_flags);
                if (!tpcol) goto json_fail;
                size_t nlen = strlen(ct->inner_names[tp]);
                for (i = 0; i < nrows; i++) {
                    HV *row_hv = (HV*)SvRV(out[i]);
                    if (!hv_store(row_hv, ct->inner_names[tp], (I32)nlen,
                                  tpcol[i], 0))
                        SvREFCNT_dec(tpcol[i]);
                }
                Safefree(tpcol);
            }
        }

        for (p = 0; p < num_paths; p++) {
            if (*pos > len || len - *pos < (size_t)nrows) goto json_fail;
            const unsigned char *discs = (const unsigned char *)(buf + *pos);
            *pos += (size_t)nrows;

            int nv = path_kind_count[p];
            int slot_to_kind[JSON_LEX_SLOTS];
            unsigned mask = 0;
            int s, kk;
            int *kinds = path_kinds_buf + p * JSON_LEX_SLOTS;
            for (kk = 0; kk < nv; kk++) mask |= 1u << kinds[kk];
            int wire_slots = json_build_lex_table(mask, slot_to_kind);

            uint64_t var_counts[JSON_LEX_SLOTS] = {0};
            uint64_t r2;
            for (r2 = 0; r2 < (uint64_t)nrows; r2++) {
                unsigned char d = discs[r2];
                if (d == 0xff) continue;
                if (d >= wire_slots) goto json_hard;
                var_counts[d]++;
            }

            Newxz(var_avs, wire_slots, AV*);
            wire_slots_cleanup = wire_slots;

            for (s = 0; s < wire_slots; s++) {
                int kind = slot_to_kind[s];
                uint64_t nv_rows = var_counts[s];
                AV *sub = newAV();
                var_avs[s] = sub;
                if (kind < 0 || kind == JV_STRING) {
                    /* SharedVariant (kind<0) takes the same String wire shape;
                     * the encoder never routes rows there but the format still
                     * allocates the slot. */
                    uint64_t k;
                    for (k = 0; k < nv_rows; k++) {
                        const char *vs; size_t vl;
                        if (read_native_string_ref(buf, len, pos, &vs, &vl) <= 0)
                            goto json_fail;
                        av_push(sub, newSVpvn(vs, vl));
                    }
                } else if (kind == JV_INT64) {
                    if (*pos > len || len - *pos < 8 * nv_rows) goto json_fail;
                    uint64_t k;
                    for (k = 0; k < nv_rows; k++) {
                        int64_t v; memcpy(&v, buf + *pos, 8); *pos += 8;
                        av_push(sub, newSViv((IV)v));
                    }
                } else if (kind == JV_UINT64) {
                    if (*pos > len || len - *pos < 8 * nv_rows) goto json_fail;
                    uint64_t k;
                    for (k = 0; k < nv_rows; k++) {
                        uint64_t v; memcpy(&v, buf + *pos, 8); *pos += 8;
                        av_push(sub, newSVuv((UV)v));
                    }
                } else if (kind == JV_FLOAT64) {
                    if (*pos > len || len - *pos < 8 * nv_rows) goto json_fail;
                    uint64_t k;
                    for (k = 0; k < nv_rows; k++) {
                        double v; memcpy(&v, buf + *pos, 8); *pos += 8;
                        av_push(sub, newSVnv(v));
                    }
                } else if (kind == JV_BOOL) {
                    if (*pos > len || len - *pos < nv_rows) goto json_fail;
                    uint64_t k;
                    for (k = 0; k < nv_rows; k++) {
                        unsigned char b8 = (unsigned char)buf[(*pos)++];
                        av_push(sub, newSViv(b8 ? 1 : 0));
                    }
                } else if (kind >= JV_ARRAY_BOOL && kind <= JV_ARRAY_UINT64) {
                    if (nv_rows == 0) continue;
                    if (*pos > len || len - *pos < 8 * nv_rows) goto json_fail;
                    Newx(offs, nv_rows, uint64_t);
                    uint64_t k;
                    for (k = 0; k < nv_rows; k++) {
                        memcpy(&offs[k], buf + *pos, 8); *pos += 8;
                    }
                    uint64_t prev = 0;
                    for (k = 0; k < nv_rows; k++) {
                        uint64_t cnt;
                        /* validate offset monotonicity (cf. Array/Map);
                         * a decrease would wrap cnt below */
                        if (offs[k] < prev) goto json_fail;
                        cnt = offs[k] - prev;
                        pending_inner = newAV();
                        /* every element costs >= 1 byte, so only pre-extend
                         * what is actually present; a wilder cnt trips the
                         * per-element bounds checks instead of OOMing here */
                        if (cnt > 0 && cnt <= (uint64_t)(len - *pos))
                            av_extend(pending_inner, (SSize_t)cnt - 1);
                        uint64_t j;
                        for (j = 0; j < cnt; j++) {
                            switch (kind) {
                                case JV_ARRAY_BOOL:
                                    if (*pos >= len) goto json_fail;
                                    av_push(pending_inner,
                                            newSViv((unsigned char)buf[(*pos)++] ? 1 : 0));
                                    break;
                                case JV_ARRAY_INT64: {
                                    if (*pos > len || len - *pos < 8) goto json_fail;
                                    int64_t v; memcpy(&v, buf + *pos, 8); *pos += 8;
                                    av_push(pending_inner, newSViv((IV)v));
                                    break;
                                }
                                case JV_ARRAY_UINT64: {
                                    if (*pos > len || len - *pos < 8) goto json_fail;
                                    uint64_t v; memcpy(&v, buf + *pos, 8); *pos += 8;
                                    av_push(pending_inner, newSVuv((UV)v));
                                    break;
                                }
                                case JV_ARRAY_FLOAT64: {
                                    if (*pos > len || len - *pos < 8) goto json_fail;
                                    double v; memcpy(&v, buf + *pos, 8); *pos += 8;
                                    av_push(pending_inner, newSVnv(v));
                                    break;
                                }
                                case JV_ARRAY_STRING: {
                                    const char *vs; size_t vl;
                                    if (read_native_string_ref(buf, len, pos, &vs, &vl) <= 0)
                                        goto json_fail;
                                    av_push(pending_inner, newSVpvn(vs, vl));
                                    break;
                                }
                            }
                        }
                        av_push(sub, newRV_noinc((SV*)pending_inner));
                        pending_inner = NULL;     /* now owned by sub */
                        prev = offs[k];
                    }
                    Safefree(offs); offs = NULL;
                } else {
                    goto json_hard;
                }
            }

            /* Distribute values into per-row hashes (dotted keys, unflattened later). */
            SSize_t cursors[JSON_LEX_SLOTS] = {0};
            uint64_t r3;
            for (r3 = 0; r3 < (uint64_t)nrows; r3++) {
                unsigned char d = discs[r3];
                if (d == 0xff) continue;
                SV **e = av_fetch(var_avs[d], cursors[d]++, 0);
                if (!e) continue;
                HV *row_hv = (HV*)SvRV(out[r3]);
                SV *vsv = SvREFCNT_inc(*e);
                if (!hv_store(row_hv, jpe[p].path, (I32)jpe[p].len, vsv, 0))
                    SvREFCNT_dec(vsv);
            }
            for (s = 0; s < wire_slots; s++)
                if (var_avs[s]) SvREFCNT_dec((SV*)var_avs[s]);
            Safefree(var_avs); var_avs = NULL;
            wire_slots_cleanup = 0;
        }

        /* Trailing shared data: N UInt64 offsets, then if last>0 strings. */
        if (nrows > 0) {
            if (*pos > len || len - *pos < 8 * (size_t)nrows) goto json_fail;
            uint64_t last_offset;
            memcpy(&last_offset, buf + *pos + 8 * (nrows - 1), 8);
            *pos += 8 * (size_t)nrows;
            if (last_offset > 0) {
                uint64_t k;
                for (k = 0; k < 2 * last_offset; k++) {
                    const char *s; size_t l;
                    if (read_native_string_ref(buf, len, pos, &s, &l) <= 0) goto json_fail;
                }
            }
        }

        /* Unflatten dotted keys back into nested hashes. */
        for (i = 0; i < nrows; i++) {
            HV *row_hv = (HV*)SvRV(out[i]);
            AV *keys = (AV*)sv_2mortal((SV*)newAV());
            hv_iterinit(row_hv);
            HE *he;
            while ((he = hv_iternext(row_hv))) {
                I32 klen;
                char *kstr = hv_iterkey(he, &klen);
                if (memchr(kstr, '.', klen))
                    av_push(keys, newSVpvn(kstr, klen));
            }
            SSize_t nk = av_len(keys) + 1, ki;
            for (ki = 0; ki < nk; ki++) {
                SV *ksv = *av_fetch(keys, ki, 0);
                STRLEN klen;
                const char *kstr = SvPV(ksv, klen);
                HV *cur = row_hv;
                STRLEN seg_start = 0, off;
                int conflict = 0;
                for (off = 0; off <= klen; off++) {
                    if (off == klen || kstr[off] == '.') {
                        const char *seg = kstr + seg_start;
                        STRLEN slen = off - seg_start;
                        if (off == klen) {
                            SV **leaf = hv_fetch(row_hv, kstr, (I32)klen, 0);
                            if (!leaf) { conflict = 1; break; }
                            SV *val = SvREFCNT_inc(*leaf);
                            if (!hv_store(cur, seg, (I32)slen, val, 0)) {
                                SvREFCNT_dec(val);
                                conflict = 1;
                            }
                        } else {
                            SV **next = hv_fetch(cur, seg, (I32)slen, 0);
                            if (next && SvROK(*next) && SvTYPE(SvRV(*next)) == SVt_PVHV) {
                                cur = (HV*)SvRV(*next);
                            } else if (next) {
                                conflict = 1; break;
                            } else {
                                HV *new_hv = newHV();
                                hv_store(cur, seg, (I32)slen,
                                         newRV_noinc((SV*)new_hv), 0);
                                cur = new_hv;
                            }
                        }
                        seg_start = off + 1;
                    }
                }
                if (!conflict)
                    (void)hv_delete(row_hv, kstr, (I32)klen, G_DISCARD);
            }
        }

        if (jpe) Safefree(jpe);
        if (path_kinds_buf) Safefree(path_kinds_buf);
        if (path_kind_count) Safefree(path_kind_count);
        return out;

    json_hard:
        if (decode_err) *decode_err = 1;
        /* fall through to shared cleanup */
    json_fail:
        if (pending_inner) SvREFCNT_dec((SV*)pending_inner);
        if (offs) Safefree(offs);
        if (var_avs) {
            int sx;
            for (sx = 0; sx < wire_slots_cleanup; sx++)
                if (var_avs[sx]) SvREFCNT_dec((SV*)var_avs[sx]);
            Safefree(var_avs);
        }
        if (jpe) Safefree(jpe);
        if (path_kinds_buf) Safefree(path_kinds_buf);
        if (path_kind_count) Safefree(path_kind_count);
        for (i = 0; i < nrows; i++) if (out[i]) SvREFCNT_dec(out[i]);
        *pos = saved;
        /* Short read: leave decode_err clear so the incremental parser
         * waits for more data. Definitive corruption jumps to json_hard. */
        goto fail;
    }

    if (ct->code == CT_MAP) {
        if (ct->num_inners != 2) { if (decode_err) *decode_err = 1; goto fail; }
        /* Map(K,V): wire format same as Array — offsets + keys column + values column */
        uint64_t *offsets, total, prev;
        SV **keys_col, **vals_col;

        if (*pos > len || nrows > (len - *pos) / 8) goto fail;
        Newx(offsets, nrows, uint64_t);
        Copy(buf + *pos, offsets, nrows, uint64_t);
        *pos += nrows * 8;

        /* validate offset monotonicity */
        prev = 0;
        for (i = 0; i < nrows; i++) {
            if (offsets[i] < prev) {
                Safefree(offsets);
                if (decode_err) *decode_err = 1;
                goto fail;
            }
            prev = offsets[i];
        }

        total = nrows > 0 ? offsets[nrows - 1] : 0;

        keys_col = decode_data(buf, len, pos, total, ct->inners[0], decode_err, decode_flags);
        if (!keys_col) { Safefree(offsets); goto fail; }

        vals_col = decode_data(buf, len, pos, total, ct->inners[1], decode_err, decode_flags);
        if (!vals_col) {
            for (i = 0; i < total; i++) SvREFCNT_dec(keys_col[i]);
            Safefree(keys_col);
            Safefree(offsets);
            goto fail;
        }

        prev = 0;
        for (i = 0; i < nrows; i++) {
            uint64_t count = offsets[i] - prev;
            HV *hv = newHV();
            uint64_t j;
            for (j = 0; j < count; j++) {
                STRLEN klen;
                const char *kstr = SvPV(keys_col[prev + j], klen);
                {
                    SV *val_sv = SvREFCNT_inc(vals_col[prev + j]);
                    if (!hv_store(hv, kstr, klen, val_sv, 0))
                        SvREFCNT_dec(val_sv);
                }
            }
            out[i] = newRV_noinc((SV*)hv);
            prev = offsets[i];
        }

        for (i = 0; i < total; i++) {
            SvREFCNT_dec(keys_col[i]);
            SvREFCNT_dec(vals_col[i]);
        }
        Safefree(keys_col);
        Safefree(vals_col);
        Safefree(offsets);
        return out;
    }

    /* Fixed-width types */
    fsz = col_type_fixed_size(ct);
    if (ct->code == CT_FIXEDSTRING && fsz == 0) {
        /* FixedString(0): 0 bytes per row, produce empty strings */
        for (i = 0; i < nrows; i++)
            out[i] = newSVpvn("", 0);
        return out;
    }
    if (fsz > 0) {
        const ch_tz_t *zone = NULL;

        if (*pos > len || nrows > (len - *pos) / fsz) goto fail;

        if (ct->tz && (decode_flags & DECODE_DT_STR) &&
            (ct->code == CT_DATETIME || ct->code == CT_DATETIME64)) {
            zone = col_zone(ct);
            if (!zone) {
                if (decode_err) *decode_err = 1;
                goto fail;
            }
        }

        for (i = 0; i < nrows; i++) {
            const char *p = buf + *pos + i * fsz;
            switch (ct->code) {
                case CT_INT8:    out[i] = newSViv(*(int8_t*)p); break;
                case CT_INT16:   { int16_t v; memcpy(&v, p, 2); out[i] = newSViv(v); break; }
                case CT_INT32:   { int32_t v; memcpy(&v, p, 4); out[i] = newSViv(v); break; }
                case CT_INT64:   { int64_t v; memcpy(&v, p, 8); out[i] = newSViv((IV)v); break; }
                case CT_UINT8: case CT_BOOL:
                                 out[i] = newSVuv(*(uint8_t*)p); break;
                case CT_UINT16:  { uint16_t v; memcpy(&v, p, 2); out[i] = newSVuv(v); break; }
                case CT_UINT32:  { uint32_t v; memcpy(&v, p, 4); out[i] = newSVuv(v); break; }
                case CT_UINT64:  { uint64_t v; memcpy(&v, p, 8); out[i] = newSVuv((UV)v); break; }
                case CT_FLOAT32: { float v; memcpy(&v, p, 4); out[i] = newSVnv(v); break; }
                case CT_FLOAT64: { double v; memcpy(&v, p, 8); out[i] = newSVnv(v); break; }
                case CT_ENUM8:
                    if (decode_flags & DECODE_ENUM_STR)
                        out[i] = enum_label_for_code(ct->type_str, ct->type_str_len, *(int8_t*)p);
                    else
                        out[i] = newSViv(*(int8_t*)p);
                    break;
                case CT_ENUM16: {
                    int16_t v; memcpy(&v, p, 2);
                    if (decode_flags & DECODE_ENUM_STR)
                        out[i] = enum_label_for_code(ct->type_str, ct->type_str_len, v);
                    else
                        out[i] = newSViv(v);
                    break;
                }
                case CT_DATE: {
                    uint16_t v; memcpy(&v, p, 2);
                    if (decode_flags & DECODE_DT_STR)
                        out[i] = days_to_date_sv((int32_t)v);
                    else
                        out[i] = newSVuv(v);
                    break;
                }
                case CT_DATE32: {
                    int32_t v; memcpy(&v, p, 4);
                    if (decode_flags & DECODE_DT_STR)
                        out[i] = days_to_date_sv(v);
                    else
                        out[i] = newSViv(v);
                    break;
                }
                case CT_DATETIME: {
                    uint32_t v; memcpy(&v, p, 4);
                    if (decode_flags & DECODE_DT_STR)
                        out[i] = epoch_to_datetime_sv_ex(v, zone);
                    else
                        out[i] = newSVuv(v);
                    break;
                }
                case CT_DATETIME64: {
                    int64_t v; memcpy(&v, p, 8);
                    if (decode_flags & DECODE_DT_STR)
                        out[i] = dt64_to_datetime_sv_ex(v, ct->param, zone);
                    else
                        out[i] = newSViv((IV)v);
                    break;
                }
                case CT_TIME: {
                    int32_t v; memcpy(&v, p, 4);
                    out[i] = newSViv(v);
                    break;
                }
                case CT_TIME64: {
                    int64_t v; memcpy(&v, p, 8);
                    out[i] = newSViv((IV)v);
                    break;
                }
                case CT_DECIMAL32: {
                    int32_t v; memcpy(&v, p, 4);
                    if (decode_flags & DECODE_DEC_SCALE)
                        out[i] = newSVnv((double)v / pow10_int(ct->param));
                    else
                        out[i] = newSViv(v);
                    break;
                }
                case CT_DECIMAL64: {
                    int64_t v; memcpy(&v, p, 8);
                    if (decode_flags & DECODE_DEC_SCALE)
                        out[i] = newSVnv((double)v / pow10_int(ct->param));
                    else
                        out[i] = newSViv((IV)v);
                    break;
                }
                case CT_DECIMAL128: {
                  #ifdef __SIZEOF_INT128__
                    if (decode_flags & DECODE_DEC_SCALE) {
                        __int128 sv128;
                        memcpy(&sv128, p, 16);
                        /* Use long double for Decimal128 to preserve more precision */
                        out[i] = newSVnv((NV)((long double)sv128 / (long double)pow10_int(ct->param)));
                    } else {
                        out[i] = int128_to_sv(p, 1);
                    }
                  #else
                    out[i] = newSVpvn(p, 16);
                  #endif
                    break;
                }
                case CT_DECIMAL256: {
                    /* No native int256; deliver raw 32 bytes (LE, signed) so
                     * users can pass them to e.g. Math::BigInt. */
                    out[i] = newSVpvn(p, 32);
                    break;
                }
                case CT_BFLOAT16: {
                    /* Top 16 bits of a Float32 (BE assembled into LE Float32). */
                    uint8_t buf[4] = {0, 0, ((const uint8_t*)p)[0], ((const uint8_t*)p)[1]};
                    float v;
                    memcpy(&v, buf, 4);
                    out[i] = newSVnv(v);
                    break;
                }
                case CT_UUID: {
                    /* UUID: two LE UInt64 halves, each reversed for display.
                     * Nibble table instead of snprintf: same bytes, ~10x
                     * less formatting work per row. */
                    static const char hexd[] = "0123456789abcdef";
                    static const uint8_t uord[16] =
                        {7,6,5,4,3,2,1,0,15,14,13,12,11,10,9,8};
                    char ustr[36];
                    char *w = ustr;
                    const unsigned char *u = (const unsigned char *)p;
                    int k;
                    for (k = 0; k < 16; k++) {
                        unsigned char b;
                        if (k == 4 || k == 6 || k == 8 || k == 10)
                            *w++ = '-';
                        b = u[uord[k]];
                        *w++ = hexd[b >> 4];
                        *w++ = hexd[b & 15];
                    }
                    out[i] = newSVpvn(ustr, 36);
                    break;
                }
                case CT_IPV4: {
                    /* UInt32 LE, MSB is first octet */
                    uint32_t v;
                    struct in_addr addr;
                    char abuf[INET_ADDRSTRLEN];
                    memcpy(&v, p, 4);
                    addr.s_addr = htonl(v);
                    inet_ntop(AF_INET, &addr, abuf, sizeof(abuf));
                    out[i] = newSVpv(abuf, 0);
                    break;
                }
                case CT_IPV6: {
                    /* 16 bytes in network byte order */
                    char abuf[INET6_ADDRSTRLEN];
                    inet_ntop(AF_INET6, p, abuf, sizeof(abuf));
                    out[i] = newSVpv(abuf, 0);
                    break;
                }
                case CT_INT128: {
                  #ifdef __SIZEOF_INT128__
                    out[i] = int128_to_sv(p, 1);
                  #else
                    out[i] = newSVpvn(p, 16);
                  #endif
                    break;
                }
                case CT_UINT128: {
                  #ifdef __SIZEOF_INT128__
                    out[i] = int128_to_sv(p, 0);
                  #else
                    out[i] = newSVpvn(p, 16);
                  #endif
                    break;
                }
                case CT_INT256:
                    out[i] = int256_to_sv(p, 1); break;
                case CT_UINT256:
                    out[i] = int256_to_sv(p, 0); break;
                case CT_FIXEDSTRING: default:
                    out[i] = newSVpvn(p, fsz); break;
            }
        }
        *pos += nrows * fsz;
        return out;
    }

    /* CT_UNKNOWN: try reading as String */
    for (i = 0; i < nrows; i++) {
        const char *s;
        size_t slen;
        if (read_native_string_ref(buf, len, pos, &s, &slen) <= 0) {
            uint64_t j;
            for (j = 0; j < i; j++) SvREFCNT_dec(out[j]);
            goto fail;
        }
        out[i] = newSVpvn(s, slen);
    }
    return out;

fail:
    Safefree(out);
    return NULL;
}

/* --- Native protocol column encoder (for INSERT) --- */

/* inet_pton's strictness is not portable: glibc rejects a leading zero in a
 * dotted quad, macOS and the BSDs accept it. ClickHouse rejects it, so the same
 * INSERT would be refused on Linux and silently stored on macOS. */
static int ipv4_text_is_strict(const char *s, size_t slen) {
    size_t i = 0;
    int group;
    for (group = 0; group < 4; group++) {
        size_t start = i;
        unsigned v = 0;
        while (i < slen && s[i] >= '0' && s[i] <= '9') {
            v = v * 10u + (unsigned)(s[i] - '0');
            i++;
        }
        if (i == start || i - start > 3 || v > 255) return 0;
        if (i - start > 1 && s[start] == '0') return 0;
        if (group < 3) {
            if (i >= slen || s[i] != '.') return 0;
            i++;
        }
    }
    return i == slen;
}

/* Parse an IPv4 address text into a host-order UInt32. Sets *ok. */
static uint32_t parse_ipv4_to_u32(const char *s, size_t slen, int *ok) {
    struct in_addr addr;
    char tmp[64];
    *ok = 0;
    if (slen == 0 || slen > 63) return 0;
    if (!ipv4_text_is_strict(s, slen)) return 0;
    memcpy(tmp, s, slen);
    tmp[slen] = '\0';
    if (inet_pton(AF_INET, tmp, &addr) == 1) {
        *ok = 1;
        return ntohl(addr.s_addr);
    }
    return 0;
}

/* Parse an IPv6 address text into 16 network-order bytes. Returns 1 on
 * success, 0 on failure (zero-fills the output either way). A dotted
 * quad maps to ::ffff:0:0/96, like the server's text parser. */
static int parse_ipv6_to_bytes(const char *s, size_t slen, unsigned char addr[16]) {
    char tmp[64];
    struct in_addr a4;
    memset(addr, 0, 16);
    if (slen == 0 || slen > 63) return 0;
    memcpy(tmp, s, slen);
    tmp[slen] = '\0';
    if (inet_pton(AF_INET6, tmp, addr) == 1) return 1;
    if (!ipv4_text_is_strict(s, slen)) return 0;
    if (inet_pton(AF_INET, tmp, &a4) != 1) return 0;
    addr[10] = 0xff;
    addr[11] = 0xff;
    memcpy(addr + 12, &a4.s_addr, 4);
    return 1;
}

/* Mirror of read_col_prefix(): every LowCardinality keys version of the
 * type tree, depth first, ahead of the column data. */
static void write_col_prefix(native_buf_t *b, col_type_t *ct) {
    int i;
    switch (ct->code) {
    case CT_LOWCARDINALITY:
        nbuf_le64(b, 1);
        break;
    case CT_ARRAY:
    case CT_NULLABLE:
        if (ct->inner) write_col_prefix(b, ct->inner);
        break;
    case CT_TUPLE:
    case CT_MAP:
        for (i = 0; i < ct->num_inners; i++)
            write_col_prefix(b, ct->inners[i]);
        break;
    default:
        break;
    }
}

/* Write the LowCardinality serialization-type + num_keys header for a
 * trivial 1:1 dictionary encoding (every value becomes its own dict
 * entry). Returns idx_size via *out_idx_size for the caller's index-write loop. */
static void lc_write_keys_header(native_buf_t *b, uint64_t nrows, size_t *out_idx_size) {
    int key_type;
    size_t idx_size;
    uint64_t ser_type, nk = nrows;
    if (nrows <= 0xFF)        { key_type = 0; idx_size = 1; }
    else if (nrows <= 0xFFFF) { key_type = 1; idx_size = 2; }
    else                      { key_type = 2; idx_size = 4; }
    /* HasAdditionalKeys | NeedUpdateDictionary */
    ser_type = (uint64_t)key_type | (1ULL << 9) | (1ULL << 10);
    nbuf_append(b, (const char *)&ser_type, 8);
    nbuf_append(b, (const char *)&nk, 8);
    *out_idx_size = idx_size;
}

/* An Enum type's default value, as on the server: its smallest code. */
static int enum_default_code(col_type_t *t) {
    enum_entry_t *entries = NULL;
    size_t i, n = enum_parse_entries(t->type_str, t->type_str_len, &entries);
    int code = n ? entries[0].code : 0;
    for (i = 1; i < n; i++)
        if (entries[i].code < code) code = entries[i].code;
    enum_free_entries(entries, n);
    return code;
}

/* Placeholder for a NULL of the given inner type. Must itself parse
 * under the strict encoders, or one NULL fails the batch. */
static void nullable_inner_zero(col_type_t *t, const char **p, size_t *len) {
    static const char zero_str[] = "0";
    static const char empty_str[] = "";
    static const char zero_uuid[] = "00000000-0000-0000-0000-000000000000";
    static const char zero_ip4[] = "0.0.0.0";
    static const char zero_ip6[] = "::";
    static const char zero_time[] = "00:00:00";
    static char enum_buf[8];
    switch (t->code) {
    case CT_ENUM8:
    case CT_ENUM16:
        *len = (size_t)snprintf(enum_buf, sizeof(enum_buf), "%d", enum_default_code(t));
        *p = enum_buf;
        break;
    case CT_STRING:
    case CT_FIXEDSTRING:
        *p = empty_str; *len = 0; break;
    case CT_UUID:
        *p = zero_uuid; *len = sizeof(zero_uuid) - 1; break;
    case CT_IPV4:
        *p = zero_ip4; *len = sizeof(zero_ip4) - 1; break;
    case CT_IPV6:
        *p = zero_ip6; *len = sizeof(zero_ip6) - 1; break;
    case CT_TIME:
    case CT_TIME64:
        *p = zero_time; *len = sizeof(zero_time) - 1; break;
    default:
        *p = zero_str; *len = 1; break;
    }
}

static SV *nullable_inner_zero_sv(pTHX_ col_type_t *t) {
    const char *p;
    size_t len;
    if (t->code == CT_ENUM8 || t->code == CT_ENUM16)
        return newSViv(enum_default_code(t));
    nullable_inner_zero(t, &p, &len);
    if (t->code == CT_STRING || t->code == CT_FIXEDSTRING)
        return newSVpvn("", 0);
    if (len == 1 && p[0] == '0')
        return newSViv(0);
    return newSVpvn(p, len);
}

/* Write num_indices + identity-mapped indices [0..nrows-1] for a trivial
 * LowCardinality 1:1 dictionary. */
static void lc_write_indices(native_buf_t *b, uint64_t nrows, size_t idx_size) {
    uint64_t i, ni = nrows;
    nbuf_append(b, (const char *)&ni, 8);
    for (i = 0; i < nrows; i++) {
        if (idx_size == 1)      { uint8_t idx = (uint8_t)i;  nbuf_append(b, (const char *)&idx, 1); }
        else if (idx_size == 2) { uint16_t idx = (uint16_t)i; nbuf_append(b, (const char *)&idx, 2); }
        else                    { uint32_t idx = (uint32_t)i; nbuf_append(b, (const char *)&idx, 4); }
    }
}

/* Write num_indices + per-row indices for an LC(Nullable) dictionary
 * whose slot 0 is NULL: null rows map to 0, row i maps to i + 1. */
static void lc_write_nullable_indices(native_buf_t *b, uint64_t nrows,
                                      size_t idx_size, uint8_t *nulls) {
    uint64_t i, ni = nrows;
    nbuf_append(b, (const char *)&ni, 8);
    for (i = 0; i < nrows; i++) {
        uint64_t v = nulls[i] ? 0 : i + 1;
        if (idx_size == 1)      { uint8_t idx = (uint8_t)v;  nbuf_append(b, (const char *)&idx, 1); }
        else if (idx_size == 2) { uint16_t idx = (uint16_t)v; nbuf_append(b, (const char *)&idx, 2); }
        else                    { uint32_t idx = (uint32_t)v; nbuf_append(b, (const char *)&idx, 4); }
    }
}

/* Parse "YYYY-MM-DD HH:MM:SS[.fff...]" into a DateTime64 scaled int64
 * (total_seconds * 10^precision + fractional). Sets *ok; on invalid input
 * returns 0 with *ok = 0. Pre-1970 dates work: the day count is a floor,
 * so the fraction always adds. */
static int64_t parse_datetime64_to_scaled(const char *s, size_t len, int precision,
                                          col_type_t *ct, int *ok) {
    int32_t days;
    int64_t total, v, scale = 1;
    int sc;
    *ok = 0;
    if (!valid_date_prefix(s, len)) return 0;
    if (len != 10 && len < 19) return 0;
    if (len >= 19 && !valid_time_part(s)) return 0;
    days = date_string_to_days(s, 10);
    total = (int64_t)days * 86400 + parse_hms(s, len);
    if (ct->tz && ct->tz[0]) {
        int tok = 0;
        total = wall_in_tz_to_epoch(total, ct, &tok);
        if (!tok) return 0;
    }
    for (sc = 0; sc < precision; sc++) scale *= 10;
    if (total > INT64_MAX / scale || total < INT64_MIN / scale) return 0;
    v = total * scale;
    /* Full consumption: a suffix past the seconds must be a fraction.
     * The server interprets designators like 'Z'/'+03:00' with TZ
     * conversion the client cannot replicate, so anything but digits
     * fails rather than silently writing a divergent instant. Extra
     * fraction digits truncate, matching the server. */
    if (len > 19 && (len < 20 || s[19] != '.')) return 0;
    if (len >= 20 && s[19] == '.') {
        const char *fp = s + 20;
        const char *fe = s + len;
        int64_t frac = 0;
        int digits = 0;
        while (fp < fe && digits < precision) {
            if (*fp < '0' || *fp > '9') return 0;
            frac = frac * 10 + (*fp - '0');
            fp++;
            digits++;
        }
        while (fp < fe) {
            if (*fp < '0' || *fp > '9') return 0;
            fp++;
        }
        while (digits < precision) { frac *= 10; digits++; }
        /* total*scale was bounded; the fraction can still push v over */
        if (v > INT64_MAX - frac) return 0;
        v += frac;
    }
    *ok = 1;
    return v;
}

/* Expand an exponent-form decimal ("[+-]mantissa[eE][+-]digits") into
 * plain text for the existing decimal parsers. Returns 1 with *out_len
 * set, 0 when there is no exponent marker (caller uses the input as is),
 * -1 when invalid. The point shifts textually (exact, no float maths);
 * int_digits past precision-scale fail, huge positive exponents fail
 * fast and huge negative ones collapse to zero, without big buffers. */
static int decimal_expand_exp(const char *p, size_t len, int scale,
                              int precision, char *out, size_t out_sz,
                              size_t *out_len) {
    size_t k, mant_len, exp_len, i, j;
    const char *mant, *exp_p, *ip, *fp;
    size_t ilen, flen;
    int neg = 0, exp_neg = 0;
    long exp = 0, int_after, limit;
    const char *sig;
    size_t sig_len, use, k3, need;
    char *w;
    for (k = 0; k < len; k++)
        if (p[k] == 'e' || p[k] == 'E') break;
    if (k == len) return 0;
    mant = p;
    mant_len = k;
    exp_p = p + k + 1;
    exp_len = len - mant_len - 1;
    if (mant_len == 0) return -1;
    i = 0;
    if (mant[0] == '-') { neg = 1; i = 1; }
    else if (mant[0] == '+') i = 1;
    if (i >= mant_len) return -1;
    j = i;
    while (j < mant_len && mant[j] >= '0' && mant[j] <= '9') j++;
    ip = mant + i;
    ilen = j - i;
    fp = mant + j;
    flen = 0;
    if (j < mant_len && mant[j] == '.') {
        size_t fstart;
        j++;
        fstart = j;
        while (j < mant_len && mant[j] >= '0' && mant[j] <= '9') j++;
        fp = mant + fstart;
        flen = j - fstart;
    }
    if (j != mant_len) return -1;
    if (ilen == 0 && flen == 0) return -1;
    if (exp_len == 0) {
        if (mant_len >= out_sz) return -1;
        memcpy(out, mant, mant_len);
        *out_len = mant_len;
        return 1;
    }
    i = 0;
    if (exp_p[0] == '-') { exp_neg = 1; i = 1; }
    else if (exp_p[0] == '+') i = 1;
    if (i >= exp_len) return -1;
    for (; i < exp_len; i++) {
        int d;
        if (exp_p[i] < '0' || exp_p[i] > '9') return -1;
        d = exp_p[i] - '0';
        if (exp < 2000000L)
            exp = exp * 10 + d;
    }
    if (exp_neg) exp = -exp;
    /* Significant digits live in two spans (int, frac) around the point;
     * gather the needed prefix into one buffer. int_after <= limit and
     * scale bound every copy below, so no big buffers. */
    {
        char dig[256];
        size_t first, total = ilen + flen, want = 0, got = 0, k4;
        size_t z = 0;
        while (z < ilen && ip[z] == '0') z++;
        if (z == ilen) {
            size_t z2 = 0;
            while (z2 < flen && fp[z2] == '0') z2++;
            first = ilen + z2;
        } else {
            first = z;
        }
        sig_len = (first >= total) ? 0 : total - first;
        sig = dig;
        limit = (long)precision - (long)scale;
        int_after = (long)sig_len + exp - (long)flen;
        if (int_after > limit) return -1;
        if (sig_len == 0) goto zero;
        if (int_after <= 0 && -int_after >= scale) goto zero;
        if (int_after <= 0) want = (size_t)scale;
        else want = (size_t)int_after + (size_t)scale;
        if (want > sizeof(dig)) want = sizeof(dig);
        for (k4 = first; k4 < total && got < want; k4++)
            dig[got++] = (k4 < ilen) ? ip[k4] : fp[k4 - ilen];
        sig_len = got;
        w = out;
        if (neg) {
            if (out_sz < 2) return -1;
            *w++ = '-';
        }
        if (int_after <= 0) {
            long lead = -int_after;
            use = sig_len;
            if (use > (size_t)(scale - lead)) use = (size_t)(scale - lead);
            need = 2 + (size_t)lead + use;
            if ((size_t)(w - out) + need >= out_sz) return -1;
            *w++ = '0';
            *w++ = '.';
            for (k3 = 0; k3 < (size_t)lead; k3++) *w++ = '0';
            memcpy(w, sig, use);
            w += use;
        } else if (sig_len >= (size_t)int_after) {
            use = sig_len - (size_t)int_after;
            if (use > (size_t)scale) use = (size_t)scale;
            need = (size_t)int_after + (use ? use + 1 : 0);
            if ((size_t)(w - out) + need >= out_sz) return -1;
            memcpy(w, sig, (size_t)int_after);
            w += int_after;
            if (use) {
                *w++ = '.';
                memcpy(w, sig + int_after, use);
                w += use;
            }
        } else {
            size_t pad = (size_t)int_after - sig_len;
            need = sig_len + pad;
            if ((size_t)(w - out) + need >= out_sz) return -1;
            memcpy(w, sig, sig_len);
            w += sig_len;
            for (k3 = 0; k3 < pad; k3++) *w++ = '0';
        }
        *out_len = (size_t)(w - out);
        return 1;
    zero:
        w = out;
        if (neg) {
            if (out_sz < 2) return -1;
            *w++ = '-';
        }
        if ((size_t)(w - out) + 1 >= out_sz) return -1;
        *w++ = '0';
        *out_len = (size_t)(w - out);
        return 1;
    }
}

/* Parse "[+-]?digits[.digits]" into a scaled int64 raw value. `scale`
 * is the target Decimal's fractional digits; `precision` its total
 * digits. Mirrors the server's TSV verdicts (probed): full consumption
 * (leading '+' ok, no whitespace, trailing garbage fails), extra
 * fraction digits truncated, significant integer digits beyond
 * precision-scale fail. Sets *ok; the digit bound keeps every
 * intermediate below 10^18, so no accumulation can overflow. */
static int64_t parse_decimal_to_raw(const char *p, size_t len, int scale,
                                    int precision, int *ok) {
    const char *e, *dstart, *sig;
    int neg = 0, int_digits = 0, frac_digits = 0, seen = 0, s;
    uint64_t integer_part = 0, frac_part = 0, raw;
    char exp_buf[256];
    size_t exp_len = 0, ek;
    int has_e = 0;
    *ok = 0;
    if (scale < 0 || scale > 18 || precision < 1 || precision > 18) return 0;
    if (len == 0) return 0;
    for (ek = 0; ek < len; ek++)
        if (p[ek] == 'e' || p[ek] == 'E') { has_e = 1; break; }
    if (has_e) {
        if (decimal_expand_exp(p, len, scale, precision,
                               exp_buf, sizeof(exp_buf), &exp_len) != 1)
            return 0;
        p = exp_buf;
        len = exp_len;
    }
    e = p + len;
    if (*p == '-') { neg = 1; p++; }
    else if (*p == '+') p++;
    dstart = p;
    while (p < e && *p >= '0' && *p <= '9') p++;
    if (p > dstart) seen = 1;
    sig = dstart;
    while (sig < p && *sig == '0') sig++;
    int_digits = (int)(p - sig);
    if (p < e && *p == '.') {
        p++;
        while (p < e && *p >= '0' && *p <= '9' && frac_digits < scale) {
            frac_part = frac_part * 10 + (uint64_t)(*p - '0');
            p++;
            frac_digits++;
        }
        while (p < e && *p >= '0' && *p <= '9') { p++; seen = 1; }
        if (frac_digits > 0) seen = 1;
    }
    if (p != e) return 0;
    if (!seen) return 0;
    if (int_digits > precision - scale) return 0;
    /* Significant span only: leading zeros never reach the accumulator,
     * and int_digits <= precision - scale keeps the scaled value < 10^18. */
    for (p = sig; p < e && *p >= '0' && *p <= '9'; p++)
        integer_part = integer_part * 10 + (uint64_t)(*p - '0');
    for (s = frac_digits; s < scale; s++) frac_part *= 10;
    for (s = 0; s < scale; s++) integer_part *= 10;
    raw = integer_part + frac_part;
    *ok = 1;
    return neg ? -(int64_t)raw : (int64_t)raw;
}

/* limbs = limbs * 10 + digit over nlimbs LE u64 limbs. Returns 0 on
 * overflow. Portable 32-bit-half arithmetic (no __int128 needed). */
static int limbs_mul10add(uint64_t *limbs, int nlimbs, unsigned digit) {
    uint64_t carry = digit;
    int i;
    for (i = 0; i < nlimbs; i++) {
        uint64_t t = limbs[i];
        uint64_t p1 = (t & 0xffffffffULL) * 10 + carry;
        uint64_t p2 = (t >> 32) * 10 + (p1 >> 32);
        limbs[i] = ((p2 & 0xffffffffULL) << 32) | (p1 & 0xffffffffULL);
        carry = p2 >> 32;
    }
    return carry == 0;
}

/* Two's-complement negate over nlimbs LE u64 limbs. */
static void limbs_negate(uint64_t *limbs, int nlimbs) {
    uint64_t carry = 1;
    int i;
    for (i = 0; i < nlimbs; i++) {
        uint64_t v = ~limbs[i] + carry;
        carry = (v == 0 && carry == 1) ? 1 : 0;
        limbs[i] = v;
    }
}

/* Parse decimal text into a scaled raw value over nlimbs LE u64 limbs.
 * Same shape as parse_decimal_to_raw: full consumption, truncation of
 * extra fraction digits, int_digits <= precision - scale. Values above
 * the signed max fail (the server errors on those too). */
static int parse_decimal_limbs(const char *p, size_t len, int scale,
                               int precision, int max_scale, int max_prec,
                               uint64_t *limbs, int nlimbs) {
    const char *e, *dstart, *sig;
    int neg = 0, int_digits = 0, frac_digits = 0, seen = 0, s, i;
    char exp_buf[256];
    size_t exp_len = 0, ek;
    int has_e = 0;
    for (i = 0; i < nlimbs; i++) limbs[i] = 0;
    if (scale < 0 || scale > max_scale || precision < 1 || precision > max_prec)
        return 0;
    if (len == 0) return 0;
    for (ek = 0; ek < len; ek++)
        if (p[ek] == 'e' || p[ek] == 'E') { has_e = 1; break; }
    if (has_e) {
        if (decimal_expand_exp(p, len, scale, precision,
                               exp_buf, sizeof(exp_buf), &exp_len) != 1)
            return 0;
        p = exp_buf;
        len = exp_len;
    }
    e = p + len;
    if (*p == '-') { neg = 1; p++; }
    else if (*p == '+') p++;
    dstart = p;
    while (p < e && *p >= '0' && *p <= '9') p++;
    if (p > dstart) seen = 1;
    sig = dstart;
    while (sig < p && *sig == '0') sig++;
    int_digits = (int)(p - sig);
    for (p = sig; p < e && *p >= '0' && *p <= '9'; p++)
        if (!limbs_mul10add(limbs, nlimbs, (unsigned)(*p - '0'))) return 0;
    if (p < e && *p == '.') {
        p++;
        while (p < e && *p >= '0' && *p <= '9' && frac_digits < scale) {
            if (!limbs_mul10add(limbs, nlimbs, (unsigned)(*p - '0'))) return 0;
            p++;
            frac_digits++;
        }
        while (p < e && *p >= '0' && *p <= '9') { p++; seen = 1; }
        if (frac_digits > 0) seen = 1;
    }
    if (p != e) return 0;
    if (!seen) return 0;
    if (int_digits > precision - scale) return 0;
    for (s = frac_digits; s < scale; s++)
        if (!limbs_mul10add(limbs, nlimbs, 0)) return 0;
    if (limbs[nlimbs - 1] & 0x8000000000000000ULL) {
        /* magnitude >= 2^(64n-1): valid only as exactly -MIN */
        int k, is_min = neg;
        for (k = 0; k < nlimbs - 1; k++)
            if (limbs[k]) { is_min = 0; break; }
        if (limbs[nlimbs - 1] != 0x8000000000000000ULL) is_min = 0;
        if (!is_min) return 0;
    }
    if (neg) limbs_negate(limbs, nlimbs);
    return 1;
}

static int parse_decimal256_to_raw(const char *p, size_t len, int scale,
                                   int precision, unsigned char out[32]) {
    uint64_t limbs[4];
    memset(out, 0, 32);
    if (!parse_decimal_limbs(p, len, scale, precision, 76, 76, limbs, 4))
        return 0;
    memcpy(out, limbs, 32);
    return 1;
}

static int parse_decimal128_to_raw(const char *p, size_t len, int scale,
                                   int precision, unsigned char out[16]) {
    uint64_t limbs[2];
    memset(out, 0, 16);
    if (!parse_decimal_limbs(p, len, scale, precision, 38, 38, limbs, 2))
        return 0;
    memcpy(out, limbs, 16);
    return 1;
}

/* Parse decimal integer text into nlimbs LE u64 limbs. signed=0 rejects
 * '-'; either way the magnitude must fit (signed: sign bit clear for
 * positive, representable INT_MIN for negative). */
static int parse_int_limbs(const char *p, size_t len, uint64_t *limbs,
                           int nlimbs, int is_signed) {
    size_t i;
    int neg = 0, k;
    if (len == 0) return 0;
    if (*p == '-') {
        if (!is_signed) return 0;
        neg = 1; p++; len--;
    }
    else if (*p == '+') { p++; len--; }
    if (len == 0) return 0;
    for (k = 0; k < nlimbs; k++) limbs[k] = 0;
    for (i = 0; i < len; i++) {
        if (p[i] < '0' || p[i] > '9') return 0;
        if (!limbs_mul10add(limbs, nlimbs, (unsigned)(p[i] - '0'))) return 0;
    }
    if (neg) {
        for (k = 0; k < nlimbs; k++)
            if (limbs[k]) break;
        if (k == nlimbs) return 1;   /* -0 */
        limbs_negate(limbs, nlimbs);
        if (!(limbs[nlimbs - 1] & 0x8000000000000000ULL)) return 0;
    } else if (is_signed) {
        if (limbs[nlimbs - 1] & 0x8000000000000000ULL) return 0;
    }
    return 1;
}

/* Parse a UUID string into 16 LE bytes (two LE UInt64 halves of the
 * 128-bit value). Returns 1 on success. Accepts exactly what the server
 * accepts: 32 hex digits, or 36 chars with dashes at 8/13/18/23. */
static int parse_uuid_to_le_bytes(const char *s, size_t slen, unsigned char ubytes[16]) {
    unsigned char raw[16] = {0};
    int k = 0, j;
    memset(ubytes, 0, 16);
    if (slen != 32 && slen != 36) return 0;
    for (j = 0; j < (int)slen; j++) {
        char c = s[j];
        unsigned char nibble;
        if (slen == 36 && (j == 8 || j == 13 || j == 18 || j == 23)) {
            if (c != '-') return 0;
            continue;
        }
        if (c >= '0' && c <= '9') nibble = (unsigned char)(c - '0');
        else if (c >= 'a' && c <= 'f') nibble = (unsigned char)(10 + c - 'a');
        else if (c >= 'A' && c <= 'F') nibble = (unsigned char)(10 + c - 'A');
        else return 0;
        if (k % 2 == 0) raw[k/2] = (unsigned char)(nibble << 4);
        else raw[k/2] |= nibble;
        k++;
    }
    if (k != 32) return 0;
    /* Reverse each 8-byte half for LE storage */
    for (k = 0; k < 8; k++) ubytes[k] = raw[7 - k];
    for (k = 0; k < 8; k++) ubytes[8 + k] = raw[15 - k];
    return 1;
}

/* Parse '[−]H+:MM:SS[.frac]' or '[−]MM:SS[.frac]' to seconds (Time)
 * or scaled units (Time64). Mirrors the server's TSV grammar (lax
 * ranges, fraction truncated to scale, rejected when scale is 0).
 * Returns the value with *ok = 1, or 0 with *ok = 0. */
static int64_t parse_time_text(const char *s, size_t len, int scale, int *ok) {
    uint64_t parts[3] = {0, 0, 0};
    int nparts = 0, neg = 0, frac_digits = 0, sc;
    uint64_t mag, tail;
    size_t i = 0, j;
    *ok = 0;
    if (len == 0) return 0;
    if (s[0] == '-') { neg = 1; i = 1; }
    else if (s[0] == '+') i = 1;
    for (;;) {
        uint64_t v = 0;
        size_t start = i, ndig;
        if (nparts == 3) return 0;
        while (i < len && s[i] >= '0' && s[i] <= '9') {
            if (v > (UINT64_MAX - (uint64_t)(s[i] - '0')) / 10) return 0;
            v = v * 10 + (uint64_t)(s[i] - '0');
            i++;
        }
        ndig = i - start;
        if (ndig == 0) return 0;
        if (nparts > 0 && ndig != 2) return 0;
        parts[nparts++] = v;
        if (i < len && s[i] == ':') { i++; continue; }
        break;
    }
    if (nparts < 2) return 0;
    if (nparts == 2) { parts[2] = parts[1]; parts[1] = parts[0]; parts[0] = 0; }
    if (parts[0] > (UINT64_MAX / 3600)) return 0;
    mag = parts[0] * 3600;
    tail = parts[1] * 60 + parts[2];
    if (mag > UINT64_MAX - tail) return 0;
    mag += tail;
    if (i < len && s[i] == '.') {
        if (scale <= 0) return 0;
        i++;
        j = i;
        while (j < len && s[j] >= '0' && s[j] <= '9') j++;
        if (j == i) return 0;
        for (; i < j && frac_digits < scale; i++, frac_digits++) {
            if (mag > (UINT64_MAX - (uint64_t)(s[i] - '0')) / 10) return 0;
            mag = mag * 10 + (uint64_t)(s[i] - '0');
        }
        i = j;
    }
    if (i != len) return 0;
    for (sc = frac_digits; sc < scale; sc++) {
        if (mag > UINT64_MAX / 10) return 0;
        mag *= 10;
    }
    if (neg) {
        if (mag > (uint64_t)INT64_MAX + 1) return 0;
        *ok = 1;
        return mag == (uint64_t)INT64_MAX + 1 ? INT64_MIN : -(int64_t)mag;
    }
    if (mag > (uint64_t)INT64_MAX) return 0;
    *ok = 1;
    return (int64_t)mag;
}

/* TSV unescape: \\ → \, \n → newline, \t → tab, \0 → null byte */
static size_t tsv_unescape(const char *src, size_t src_len, char *dst) {
    size_t i, j = 0;
    for (i = 0; i < src_len; i++) {
        if (src[i] == '\\' && i + 1 < src_len) {
            switch (src[i+1]) {
                case '\\': dst[j++] = '\\'; i++; break;
                case 'n':  dst[j++] = '\n'; i++; break;
                case 't':  dst[j++] = '\t'; i++; break;
                case '0':  dst[j++] = '\0'; i++; break;
                case '\'': dst[j++] = '\''; i++; break;
                case 'b':  dst[j++] = '\b'; i++; break;
                case 'r':  dst[j++] = '\r'; i++; break;
                case 'a':  dst[j++] = '\a'; i++; break;
                case 'f':  dst[j++] = '\f'; i++; break;
                default:   dst[j++] = src[i]; break;
            }
        } else {
            dst[j++] = src[i];
        }
    }
    return j;
}

static int is_tsv_null(const char *s, size_t len) {
    return len == 2 && s[0] == '\\' && s[1] == 'N';
}

/* TSV escape: inverse of tsv_unescape — appends escaped bytes to buffer */
static void tsv_escape(native_buf_t *b, const char *s, size_t len) {
    size_t i, start = 0;
    for (i = 0; i < len; i++) {
        char esc = 0;
        switch (s[i]) {
            case '\\': esc = '\\'; break;
            case '\t': esc = 't';  break;
            case '\n': esc = 'n';  break;
            case '\0': esc = '0';  break;
            case '\b': esc = 'b';  break;
            case '\r': esc = 'r';  break;
            case '\a': esc = 'a';  break;
            case '\f': esc = 'f';  break;
        }
        if (esc) {
            if (i > start)
                nbuf_append(b, s + start, i - start);
            nbuf_grow(b, 2);
            b->data[b->len++] = '\\';
            b->data[b->len++] = esc;
            start = i + 1;
        }
    }
    if (start < len)
        nbuf_append(b, s + start, len - start);
}

/* Snapshot of arrayref INSERT data. Native INSERT encodes rows later (at
 * sample-block time), so holding the caller's AV would let a post-call
 * clear/push silently change the batch: keep the cells, shared by
 * reference, row-major in one array, projected through columns_at. */
typedef struct {
    SSize_t nrows;
    SSize_t bad_row;      /* first row that is not an arrayref, -1 if none */
    SSize_t width;        /* columns_at entries, -1 without projection */
    SSize_t ncells, cap;
    SSize_t *off;         /* row r owns cells[off[r] .. off[r + 1]) */
    SV **cells;           /* NULL = missing cell */
} insert_snap_t;

static int insert_snap_free(pTHX_ SV *sv, MAGIC *mg) {
    insert_snap_t *sn = (insert_snap_t *)mg->mg_ptr;
    SSize_t i;
    PERL_UNUSED_ARG(sv);
    for (i = 0; i < sn->ncells; i++)
        if (sn->cells[i]) SvREFCNT_dec(sn->cells[i]);
    Safefree(sn->cells);
    Safefree(sn->off);
    Safefree(sn);
    return 0;
}

static MGVTBL insert_snap_vtbl = {
    NULL, NULL, NULL, NULL, insert_snap_free, NULL, NULL, NULL
};

static insert_snap_t *insert_snap_get(pTHX_ SV *sv) {
    MAGIC *mg = sv ? mg_findext(sv, PERL_MAGIC_ext, &insert_snap_vtbl) : NULL;
    return mg ? (insert_snap_t *)mg->mg_ptr : NULL;
}

static void insert_snap_push(insert_snap_t *sn, SV *cell) {
    if (sn->ncells == sn->cap) {
        if (sn->cap > (SSize_t)(SSize_t_MAX / 2 / sizeof(SV *)))
            croak("insert data too large");
        sn->cap = sn->cap ? sn->cap * 2 : 64;
        Renew(sn->cells, sn->cap, SV *);
    }
    sn->cells[sn->ncells++] = cell;
}

/* The columns_at insert option as positions in a mortal buffer, NULL
 * when absent; croaks unless it is a non-empty array of non-negative
 * integers. */
static SSize_t *insert_columns_at(pTHX_ HV *settings, SSize_t *count) {
    SV **svp = settings ? hv_fetchs(settings, "columns_at", 0) : NULL;
    AV *av;
    SSize_t n, j, *pos;
    *count = 0;
    if (!svp) return NULL;
    SvGETMAGIC(*svp);
    if (!SvOK(*svp)) return NULL;
    if (!SvROK(*svp) || SvTYPE(SvRV(*svp)) != SVt_PVAV
        || (n = av_len((AV *)SvRV(*svp)) + 1) < 1)
        croak("columns_at must be a non-empty array of non-negative integers");
    av = (AV *)SvRV(*svp);
    pos = (SSize_t *)SvPVX(sv_2mortal(newSV(n * sizeof(SSize_t))));
    for (j = 0; j < n; j++) {
        SV **e = av_fetch(av, j, 0);
        SV *v = e ? *e : &PL_sv_undef;
        NV nv;
        SvGETMAGIC(v);
        if (!SvOK(v) || SvROK(v) || !looks_like_number(v)
            || !((nv = SvNV_nomg(v)) >= 0 && nv <= (NV)(SSize_t_MAX / 2))
            || nv != (NV)(SSize_t)nv)
            croak("columns_at must be a non-empty array of non-negative integers");
        pos[j] = (SSize_t)nv;
    }
    *count = n;
    return pos;
}

/* A plain row's cell is shared by reference; a get-magical one (a tied
 * scalar) is FETCHed once now and copied, as in a tied row. */
static SV *snap_cell(pTHX_ SV *cell) {
    if (!cell) return NULL;
    return SvGMAGICAL(cell) ? newSVsv(cell) : SvREFCNT_inc(cell);
}

static SV *snapshot_insert_av(pTHX_ AV *src, const SSize_t *proj, SSize_t nproj) {
    SSize_t n = av_len(src) + 1;
    SSize_t i;
    insert_snap_t *sn;
    /* av_fetch on a tied AV returns a lazy mortal FETCH proxy, not the
     * value. Materialize tied rows/cells now (src is alive) and copy
     * the values so the snapshot never dangles if the caller frees
     * the tied container before the deferred encode. */
    int src_magical = SvRMAGICAL((SV *)src);
    /* Mortal during the build: a dying FETCH longjmps out of insert(),
     * and the partial copy must die with the scope instead of leaking. */
    SV *holder = sv_2mortal(newSV(0));

    Newxz(sn, 1, insert_snap_t);
    sn->bad_row = -1;
    sn->width = proj ? nproj : -1;
    sv_magicext(holder, NULL, PERL_MAGIC_ext, &insert_snap_vtbl, (char *)sn, 0);
    Newx(sn->off, n + 1, SSize_t);
    sn->off[0] = 0;
    if (proj && n > 0) {
        if (nproj > SSize_t_MAX / (SSize_t)sizeof(SV *) / n)
            croak("insert data too large");
        sn->cap = n * nproj;
        Newx(sn->cells, sn->cap, SV *);
    }
    for (i = 0; i < n; i++) {
        SV **e = av_fetch(src, i, 0);
        SV *row = (e && *e) ? *e : &PL_sv_undef;
        AV *rsrc = NULL;
        if (src_magical || SvGMAGICAL(row)) {
            if (SvGMAGICAL(row)) mg_get(row);
            if (SvROK(row) && SvTYPE(SvRV(row)) == SVt_PVAV) {
                rsrc = (AV *)SvRV(row);
                /* Own the row AV through the copy loop below; the
                 * FETCH proxy borrows it. Mortal: scope frees it. */
                (void)sv_2mortal(newRV_inc((SV *)rsrc));
            }
        } else if (SvROK(row) && SvTYPE(SvRV(row)) == SVt_PVAV) {
            rsrc = (AV *)SvRV(row);
        }
        if (!rsrc) {
            if (sn->bad_row < 0) sn->bad_row = i;
        } else if (SvRMAGICAL((SV *)rsrc)) {
            SSize_t len = av_len(rsrc) + 1;
            SSize_t j, rn = proj ? nproj : len;
            for (j = 0; j < rn; j++) {
                SSize_t at = proj ? proj[j] : j;
                SV **c = at < len ? av_fetch(rsrc, at, 0) : NULL;
                insert_snap_push(sn, (c && *c) ? newSVsv(*c) : NULL);
            }
        } else {
            SSize_t len = AvFILLp(rsrc) + 1;
            SV **arr = AvARRAY(rsrc);
            SSize_t j;
            if (proj) {
                for (j = 0; j < nproj; j++)
                    insert_snap_push(sn, snap_cell(aTHX_
                        proj[j] < len ? arr[proj[j]] : NULL));
            } else {
                for (j = 0; j < len; j++)
                    insert_snap_push(sn, snap_cell(aTHX_ arr[j]));
            }
        }
        sn->off[i + 1] = sn->ncells;
    }
    sn->nrows = n;
    /* Un-mortalize: the caller owns the holder from here on. */
    return SvREFCNT_inc(holder);
}

/* Serialize an AV of AVs to TabSeparated format for HTTP INSERT, each
 * row projected through proj when given. Returns malloc'd buffer;
 * caller must Safefree(). */

static char* serialize_av_to_tsv(pTHX_ AV *rows, const SSize_t *proj,
                                 SSize_t nproj, size_t *out_len) {
    native_buf_t b;
    SSize_t nrows = av_len(rows) + 1;
    SSize_t r;

    nbuf_init(&b);

    for (r = 0; r < nrows; r++) {
        SV **row_svp = av_fetch(rows, r, 0);
        AV *row;
        SSize_t ncols, c, last;

        if (row_svp && *row_svp && SvGMAGICAL(*row_svp))
            mg_get(*row_svp);
        if (!row_svp || !SvROK(*row_svp) ||
            SvTYPE(SvRV(*row_svp)) != SVt_PVAV) {
            Safefree(b.data);
            croak("insert data: row %" IVdf " is not an ARRAY ref", (IV)r);
        }
        row = (AV *)SvRV(*row_svp);
        last = av_len(row);
        ncols = proj ? nproj : last + 1;

        for (c = 0; c < ncols; c++) {
            SV **val_svp = !proj ? av_fetch(row, c, 0)
                         : proj[c] <= last ? av_fetch(row, proj[c], 0)
                         : NULL;
            if (c > 0)
                nbuf_u8(&b, '\t');

            if (val_svp && *val_svp && SvGMAGICAL(*val_svp))
                mg_get(*val_svp);
            if (!val_svp || !SvOK(*val_svp)) {
                nbuf_append(&b, "\\N", 2);
            } else if (SvROK(*val_svp)) {
                /* Nested AV/HV refs (Array/Tuple/Map columns) cannot be
                 * round-tripped through TSV without column-type info from
                 * the server, which the HTTP path doesn't have. Fail loudly
                 * rather than silently sending ARRAY(0x...) garbage. */
                Safefree(b.data);
                croak("insert data: row %" IVdf " column %" IVdf " is a "
                      "reference; nested Array/Tuple/Map columns require "
                      "the native protocol", (IV)r, (IV)c);
            } else {
                STRLEN vlen;
                /* nomg: already FETCHed above; a second FETCH would
                 * double user-visible side effects. */
                const char *v = SvPV_nomg(*val_svp, vlen);
                tsv_escape(&b, v, vlen);
            }
        }
        nbuf_u8(&b, '\n');
    }

    *out_len = b.len;
    return b.data;
}

/* Strict "[+-]?digits" parses with full consumption and overflow
 * detection (server TSV parity: no whitespace, no trailing garbage).
 * Length-delimited: TSV fields are not NUL-terminated. */
static int64_t parse_int64_strict(const char *s, size_t len, int *ok) {
    const char *e = s + len;
    int neg = 0;
    uint64_t cutoff, cutlim, v = 0;
    *ok = 0;
    if (len == 0) return 0;
    if (*s == '-') { neg = 1; s++; }
    else if (*s == '+') s++;
    if (s >= e || *s < '0' || *s > '9') return 0;
    cutoff = neg ? (uint64_t)INT64_MAX + 1 : (uint64_t)INT64_MAX;
    cutlim = cutoff % 10;
    cutoff /= 10;
    for (; s < e; s++) {
        unsigned d;
        if (*s < '0' || *s > '9') return 0;
        d = (unsigned)(*s - '0');
        if (v > cutoff || (v == cutoff && d > cutlim)) return 0;
        v = v * 10 + d;
    }
    *ok = 1;
    if (!neg) return (int64_t)v;
    return v == (uint64_t)INT64_MAX + 1 ? INT64_MIN : -(int64_t)v;
}

static uint64_t parse_uint64_strict(const char *s, size_t len, int *ok) {
    const char *e = s + len;
    uint64_t v = 0;
    *ok = 0;
    if (len == 0) return 0;
    if (*s == '+') s++;
    else if (*s == '-') return 0;
    if (s >= e || *s < '0' || *s > '9') return 0;
    for (; s < e; s++) {
        unsigned d;
        if (*s < '0' || *s > '9') return 0;
        d = (unsigned)(*s - '0');
        if (v > (UINT64_MAX - d) / 10) return 0;
        v = v * 10 + d;
    }
    *ok = 1;
    return v;
}

/* SV to int64/uint64 for integer columns. IOK passes through; NOK goes
 * through SvNV with a range check so 1e15 encodes exactly instead of
 * stringifying to "1e+15" and truncating to 1; anything else parses the
 * string form strictly. !SvOK fails: a null into a non-nullable column
 * must error, never land as 0. */
static int64_t sv_to_int64_strict(pTHX_ SV *sv, int *ok) {
    STRLEN vlen;
    const char *s;
    *ok = 0;
    if (!SvOK(sv)) return 0;
    if (SvIOK(sv)) { *ok = 1; return SvIV(sv); }
    if (SvNOK(sv)) {
        double d = SvNV(sv);
        if (!(d > -9.223372036854776e18 && d < 9.223372036854776e18)) return 0;
        *ok = 1;
        return (int64_t)d;
    }
    s = SvPV(sv, vlen);
    return parse_int64_strict(s, vlen, ok);
}

static uint64_t sv_to_uint64_strict(pTHX_ SV *sv, int *ok) {
    STRLEN vlen;
    const char *s;
    *ok = 0;
    if (!SvOK(sv)) return 0;
    if (SvIsUV(sv)) { *ok = 1; return SvUV(sv); }
    if (SvIOK(sv)) {
        IV iv = SvIV(sv);
        if (iv < 0) return 0;
        *ok = 1;
        return (uint64_t)iv;
    }
    if (SvNOK(sv)) {
        double d = SvNV(sv);
        if (!(d >= 0.0 && d < 1.8446744073709552e19)) return 0;
        *ok = 1;
        return (uint64_t)d;
    }
    s = SvPV(sv, vlen);
    return parse_uint64_strict(s, vlen, ok);
}

/* TSV boolean: exactly "0"/"1" or true/false in any case (probed server
 * verdicts: "2", "00", "01" all fail with Code 467). */
static int bool_text_to_u8(const char *s, size_t len, uint8_t *out) {
    if (len == 1 && (*s == '0' || *s == '1')) {
        *out = (uint8_t)(*s - '0');
        return 1;
    }
    if (len == 4 &&
        (*s == 't' || *s == 'T') && (s[1] == 'r' || s[1] == 'R') &&
        (s[2] == 'u' || s[2] == 'U') && (s[3] == 'e' || s[3] == 'E')) {
        *out = 1;
        return 1;
    }
    if (len == 5 &&
        (*s == 'f' || *s == 'F') && (s[1] == 'a' || s[1] == 'A') &&
        (s[2] == 'l' || s[2] == 'L') && (s[3] == 's' || s[3] == 'S') &&
        (s[4] == 'e' || s[4] == 'E')) {
        *out = 0;
        return 1;
    }
    return 0;
}

/* Exact label match for a TSV field. Backslash escapes decode before
 * comparing, mirroring the server's TSV parsing. */
static int enum_match_tsv(const enum_entry_t *entries, size_t n,
                          const char *s, size_t len, int *code_out) {
    char *tmp;
    size_t ulen;
    int found;
    if (!memchr(s, '\\', len))
        return enum_code_for_label(entries, n, s, len, code_out);
    Newx(tmp, len, char);
    ulen = tsv_unescape(s, len, tmp);
    found = enum_code_for_label(entries, n, tmp, ulen, code_out);
    Safefree(tmp);
    return found;
}

/* A code the type does not declare would make every later read of the
 * column fail ("Unexpected value in enum"); the server's text parser
 * rejects it too. */
static int enum_has_code(const enum_entry_t *entries, size_t n, int64_t code) {
    size_t i;
    for (i = 0; i < n; i++)
        if (entries[i].code == code) return 1;
    return 0;
}

/* Labels win over codes, as in the server's text parsers; a number
 * needs the label lookup only when some label looks like one. */
static int enum_has_numeric_label(const enum_entry_t *entries, size_t n) {
    size_t i, j;
    for (i = 0; i < n; i++) {
        const char *l = entries[i].label;
        j = (entries[i].len > 1 && (l[0] == '-' || l[0] == '+')) ? 1 : 0;
        if (j >= entries[i].len) continue;
        while (j < entries[i].len && l[j] >= '0' && l[j] <= '9') j++;
        if (j == entries[i].len) return 1;
    }
    return 0;
}

static void nbuf_enum(native_buf_t *b, int type_code, int code) {
    if (type_code == CT_ENUM8) {
        int8_t v = (int8_t)code;
        nbuf_append(b, (const char *)&v, 1);
    } else {
        int16_t v = (int16_t)code;
        nbuf_append(b, (const char *)&v, 2);
    }
}

/* The whole of s[0..len) as a number. Text values need not be
 * NUL-terminated (substituted defaults are not), so strtod gets a copy. */
static int text_to_double(const char *s, size_t len, int as_float, double *out) {
    char buf[64], *p = buf, *endp;
    int ok;
    if (len == 0) return 0;
    if (len >= sizeof(buf)) Newx(p, len + 1, char);
    memcpy(p, s, len);
    p[len] = '\0';
    *out = as_float ? (double)strtof(p, &endp) : strtod(p, &endp);
    ok = endp == p + len;
    if (p != buf) Safefree(p);
    return ok;
}

/*
 * Encode a column of text values into native binary format.
 * Returns 1 on success, 0 if type is unsupported (caller falls back to inline SQL).
 */
static int encode_column_text(native_buf_t *b,
                               const char **values, size_t *value_lens,
                               uint64_t nrows, col_type_t *ct) {
    uint64_t i;

    switch (ct->code) {
    case CT_INT8: {
        for (i = 0; i < nrows; i++) {
            int ok = 0;
            int64_t w = parse_int64_strict(values[i], value_lens[i], &ok);
            if (!ok || w < -128 || w > 127) return 0;
            {
                int8_t v = (int8_t)w;
                nbuf_append(b, (const char *)&v, 1);
            }
        }
        return 1;
    }
    case CT_ENUM8: case CT_ENUM16: {
        enum_entry_t *entries = NULL;
        size_t nentries = enum_parse_entries(ct->type_str, ct->type_str_len, &entries);
        int rc = 1;
        for (i = 0; i < nrows; i++) {
            int code, ok = 0;
            if (!enum_match_tsv(entries, nentries, values[i], value_lens[i], &code)) {
                int64_t w = parse_int64_strict(values[i], value_lens[i], &ok);
                if (!ok || !enum_has_code(entries, nentries, w)) { rc = 0; break; }
                code = (int)w;
            }
            nbuf_enum(b, ct->code, code);
        }
        enum_free_entries(entries, nentries);
        return rc;
    }
    case CT_INT16: {
        for (i = 0; i < nrows; i++) {
            int ok = 0;
            int64_t w = parse_int64_strict(values[i], value_lens[i], &ok);
            if (!ok || w < -32768 || w > 32767) return 0;
            {
                int16_t v = (int16_t)w;
                nbuf_append(b, (const char *)&v, 2);
            }
        }
        return 1;
    }
    case CT_INT32: case CT_DATE32: {
        for (i = 0; i < nrows; i++) {
            int32_t v;
            if (ct->code == CT_DATE32 && value_lens[i] >= 10
                && values[i][4] == '-') {
                if (value_lens[i] != 10) return 0;
                if (!valid_date_prefix(values[i], value_lens[i])) return 0;
                v = date_string_to_days(values[i], value_lens[i]);
            } else {
                int ok = 0;
                int64_t w = parse_int64_strict(values[i], value_lens[i], &ok);
                if (!ok || w < (int64_t)INT32_MIN || w > (int64_t)INT32_MAX)
                    return 0;
                v = (int32_t)w;
            }
            nbuf_append(b, (const char *)&v, 4);
        }
        return 1;
    }
    case CT_INT64: {
        for (i = 0; i < nrows; i++) {
            int ok = 0;
            int64_t v = parse_int64_strict(values[i], value_lens[i], &ok);
            if (!ok) return 0;
            nbuf_append(b, (const char *)&v, 8);
        }
        return 1;
    }
    case CT_UINT8: {
        for (i = 0; i < nrows; i++) {
            int ok = 0;
            uint64_t w = parse_uint64_strict(values[i], value_lens[i], &ok);
            if (!ok || w > 255) return 0;
            {
                uint8_t v = (uint8_t)w;
                nbuf_append(b, (const char *)&v, 1);
            }
        }
        return 1;
    }
    case CT_BOOL: {
        for (i = 0; i < nrows; i++) {
            uint8_t v;
            if (!bool_text_to_u8(values[i], value_lens[i], &v)) return 0;
            nbuf_append(b, (const char *)&v, 1);
        }
        return 1;
    }
    case CT_UINT16: case CT_DATE: {
        for (i = 0; i < nrows; i++) {
            uint16_t v;
            if (ct->code == CT_DATE && value_lens[i] >= 10
                && values[i][4] == '-') {
                int32_t days;
                if (value_lens[i] != 10) return 0;
                if (!valid_date_prefix(values[i], value_lens[i])) return 0;
                days = date_string_to_days(values[i], value_lens[i]);
                if (days < 0 || days > 65535) return 0;
                v = (uint16_t)days;
            } else {
                int ok = 0;
                uint64_t w = parse_uint64_strict(values[i], value_lens[i],
                                                 &ok);
                if (!ok || w > 65535) return 0;
                v = (uint16_t)w;
            }
            nbuf_append(b, (const char *)&v, 2);
        }
        return 1;
    }
    case CT_UINT32: case CT_DATETIME: {
        int rc = 1;
        for (i = 0; i < nrows; i++) {
            uint32_t v;
            if (ct->code == CT_DATETIME && value_lens[i] >= 10
                && values[i][4] == '-') {
                int32_t days;
                int64_t total;
                if (value_lens[i] != 10 && value_lens[i] != 19) { rc = 0; break; }
                if (!valid_date_prefix(values[i], value_lens[i])) { rc = 0; break; }
                if (value_lens[i] >= 19 && !valid_time_part(values[i])) { rc = 0; break; }
                days = date_string_to_days(values[i], 10);
                total = (int64_t)days * 86400
                      + parse_hms(values[i], value_lens[i]);
                if (ct->tz) {
                    int tok = 0;
                    total = wall_in_tz_to_epoch(total, ct, &tok);
                    if (!tok) { rc = 0; break; }
                }
                if (total < 0 || total > (int64_t)UINT32_MAX) { rc = 0; break; }
                v = (uint32_t)total;
            } else {
                int ok = 0;
                uint64_t w = parse_uint64_strict(values[i], value_lens[i],
                                                 &ok);
                if (!ok || w > (uint64_t)UINT32_MAX) { rc = 0; break; }
                v = (uint32_t)w;
            }
            nbuf_append(b, (const char *)&v, 4);
        }
        return rc;
    }
    case CT_UINT64: {
        for (i = 0; i < nrows; i++) {
            int ok = 0;
            uint64_t v = parse_uint64_strict(values[i], value_lens[i], &ok);
            if (!ok) return 0;
            nbuf_append(b, (const char *)&v, 8);
        }
        return 1;
    }
    case CT_FLOAT32: {
        for (i = 0; i < nrows; i++) {
            double d;
            float v;
            if (!text_to_double(values[i], value_lens[i], 1, &d)) return 0;
            v = (float)d;
            nbuf_append(b, (const char *)&v, 4);
        }
        return 1;
    }
    case CT_FLOAT64: {
        for (i = 0; i < nrows; i++) {
            double v;
            if (!text_to_double(values[i], value_lens[i], 0, &v)) return 0;
            nbuf_append(b, (const char *)&v, 8);
        }
        return 1;
    }
    case CT_DATETIME64: {
        int rc = 1;
        for (i = 0; i < nrows; i++) {
            int64_t v;
            if (value_lens[i] >= 10 && values[i][4] == '-') {
                int ok = 0;
                v = parse_datetime64_to_scaled(values[i], value_lens[i],
                                               ct->param, ct, &ok);
                if (!ok) { rc = 0; break; }
            } else {
                int ok = 0;
                v = parse_int64_strict(values[i], value_lens[i], &ok);
                if (!ok) { rc = 0; break; }
            }
            nbuf_append(b, (const char *)&v, 8);
        }
        return rc;
    }
    case CT_TIME: {
        for (i = 0; i < nrows; i++) {
            int ok = 0;
            int64_t v = parse_time_text(values[i], value_lens[i], 0, &ok);
            int32_t w;
            if (!ok || v > INT32_MAX || v < INT32_MIN) return 0;
            w = (int32_t)v;
            nbuf_append(b, (const char *)&w, 4);
        }
        return 1;
    }
    case CT_TIME64: {
        for (i = 0; i < nrows; i++) {
            int ok = 0;
            int64_t v = parse_time_text(values[i], value_lens[i],
                                        ct->param, &ok);
            if (!ok) return 0;
            nbuf_append(b, (const char *)&v, 8);
        }
        return 1;
    }
    case CT_DECIMAL32: {
        for (i = 0; i < nrows; i++) {
            int ok = 0;
            int32_t v = (int32_t)parse_decimal_to_raw(values[i], value_lens[i],
                                                     ct->param, ct->precision,
                                                     &ok);
            if (!ok) return 0;
            nbuf_append(b, (const char *)&v, 4);
        }
        return 1;
    }
    case CT_DECIMAL64: {
        for (i = 0; i < nrows; i++) {
            int ok = 0;
            int64_t v = parse_decimal_to_raw(values[i], value_lens[i],
                                             ct->param, ct->precision, &ok);
            if (!ok) return 0;
            nbuf_append(b, (const char *)&v, 8);
        }
        return 1;
    }
    case CT_DECIMAL128: {
        for (i = 0; i < nrows; i++) {
            unsigned char raw[16];
            if (!parse_decimal128_to_raw(values[i], value_lens[i],
                                         ct->param, ct->precision, raw))
                return 0;
            nbuf_append(b, (const char *)raw, 16);
        }
        return 1;
    }
    case CT_DECIMAL256: {
        for (i = 0; i < nrows; i++) {
            unsigned char raw[32];
            if (!parse_decimal256_to_raw(values[i], value_lens[i],
                                         ct->param, ct->precision, raw))
                return 0;
            nbuf_append(b, (const char *)raw, 32);
        }
        return 1;
    }
    case CT_BFLOAT16: {
        for (i = 0; i < nrows; i++) {
            double d;
            float fv;
            if (!text_to_double(values[i], value_lens[i], 0, &d)) return 0;
            fv = (float)d;
            uint8_t b32[4]; memcpy(b32, &fv, 4);
            nbuf_append(b, (const char *)&b32[2], 2);
        }
        return 1;
    }
    case CT_STRING: {
        for (i = 0; i < nrows; i++) {
            if (memchr(values[i], '\\', value_lens[i])) {
                char *tmp;
                size_t ulen;
                Newx(tmp, value_lens[i], char);
                ulen = tsv_unescape(values[i], value_lens[i], tmp);
                nbuf_string(b, tmp, ulen);
                Safefree(tmp);
            } else {
                nbuf_string(b, values[i], value_lens[i]);
            }
        }
        return 1;
    }
    case CT_FIXEDSTRING: {
        size_t fsz = (size_t)ct->param;
        for (i = 0; i < nrows; i++) {
            if (memchr(values[i], '\\', value_lens[i])) {
                char *tmp;
                size_t ulen;
                size_t tmp_sz = value_lens[i] > fsz ? value_lens[i] : fsz;
                Newxz(tmp, tmp_sz, char);
                ulen = tsv_unescape(values[i], value_lens[i], tmp);
                if (ulen > fsz) { Safefree(tmp); return 0; }
                nbuf_append(b, tmp, fsz);
                Safefree(tmp);
            } else {
                size_t cplen;
                if (value_lens[i] > fsz) return 0;
                cplen = value_lens[i];
                nbuf_grow(b, fsz);
                memcpy(b->data + b->len, values[i], cplen);
                if (cplen < fsz)
                    memset(b->data + b->len + cplen, 0, fsz - cplen);
                b->len += fsz;
            }
        }
        return 1;
    }
    case CT_UUID: {
        for (i = 0; i < nrows; i++) {
            unsigned char ubytes[16];
            if (!parse_uuid_to_le_bytes(values[i], value_lens[i], ubytes))
                return 0;
            nbuf_append(b, (const char *)ubytes, 16);
        }
        return 1;
    }
    case CT_IPV4: {
        for (i = 0; i < nrows; i++) {
            int ok = 0;
            uint32_t v = parse_ipv4_to_u32(values[i], value_lens[i], &ok);
            if (!ok) return 0;
            nbuf_append(b, (const char *)&v, 4);
        }
        return 1;
    }
    case CT_IPV6: {
        for (i = 0; i < nrows; i++) {
            unsigned char addr[16];
            if (!parse_ipv6_to_bytes(values[i], value_lens[i], addr))
                return 0;
            nbuf_append(b, (const char *)addr, 16);
        }
        return 1;
    }
    case CT_NULLABLE: {
        /* null bitmap + inner column */
        uint8_t *nulls;
        const char **inner_vals;
        size_t *inner_lens;

        Newx(nulls, nrows, uint8_t);
        Newxz(inner_vals, nrows, const char *);
        Newx(inner_lens, nrows, size_t);

        for (i = 0; i < nrows; i++) {
            if (is_tsv_null(values[i], value_lens[i])) {
                nulls[i] = 1;
                nullable_inner_zero(ct->inner,
                                    &inner_vals[i], &inner_lens[i]);
            } else {
                nulls[i] = 0;
                inner_vals[i] = values[i];
                inner_lens[i] = value_lens[i];
            }
        }

        nbuf_append(b, (const char *)nulls, nrows);
        {
            int rc = encode_column_text(b, inner_vals, inner_lens, nrows, ct->inner);
            Safefree(nulls);
            Safefree(inner_vals);
            Safefree(inner_lens);
            return rc;
        }
    }
    case CT_LOWCARDINALITY: {
        /* Trivial 1:1 dictionary: each value is its own dict entry. */
        size_t idx_size;
        native_buf_t dict_buf;
        int rc;

        if (nrows == 0) return 1;
        if (ct->inner->code == CT_NULLABLE) {
            /* Dict travels as plain T with slot 0 reserved for NULL:
             * [T default] + rows (nulls substituted), null->0 else i+1. */
            const char **dvals;
            size_t *dlens;
            uint8_t *nulls;
            const char *zp;
            size_t zlen;
            nullable_inner_zero(ct->inner->inner, &zp, &zlen);
            Newx(dvals, nrows + 1, const char *);
            Newx(dlens, nrows + 1, size_t);
            Newx(nulls, nrows ? nrows : 1, uint8_t);
            dvals[0] = zp;
            dlens[0] = zlen;
            for (i = 0; i < nrows; i++) {
                if (is_tsv_null(values[i], value_lens[i])) {
                    nulls[i] = 1;
                    dvals[i + 1] = zp;
                    dlens[i + 1] = zlen;
                } else {
                    nulls[i] = 0;
                    dvals[i + 1] = values[i];
                    dlens[i + 1] = value_lens[i];
                }
            }
            lc_write_keys_header(b, nrows + 1, &idx_size);
            nbuf_init(&dict_buf);
            rc = encode_column_text(&dict_buf, dvals, dlens, nrows + 1,
                                    ct->inner->inner);
            Safefree(dvals);
            Safefree(dlens);
            if (!rc) { Safefree(dict_buf.data); Safefree(nulls); return 0; }
            nbuf_append(b, dict_buf.data, dict_buf.len);
            Safefree(dict_buf.data);
            lc_write_nullable_indices(b, nrows, idx_size, nulls);
            Safefree(nulls);
            return 1;
        }

        lc_write_keys_header(b, nrows, &idx_size);
        nbuf_init(&dict_buf);
        rc = encode_column_text(&dict_buf, values, value_lens, nrows, ct->inner);
        if (!rc) { Safefree(dict_buf.data); return 0; }
        nbuf_append(b, dict_buf.data, dict_buf.len);
        Safefree(dict_buf.data);
        lc_write_indices(b, nrows, idx_size);
        return 1;
    }
    default:
        return 0;  /* unsupported type — fall back to inline SQL */
    }
}

/* A plain number never reads as date text; stringifying it would only
 * allocate a PV in the caller's scalar. */
#define SV_PLAIN_NUM(sv) (!SvGMAGICAL(sv) && !SvPOK(sv) && !SvROK(sv) \
                          && (SvIOK(sv) || SvNOK(sv)))

/* The text SvPV would give a plain number (same rules as sv_2pv: IV
 * first, 0 for zeroes, Inf/NaN, %g at NV_DIG), written to buf instead of
 * cached in the caller's scalar. buf holds SV_NUM_TEXT_MAX bytes. */
#define SV_NUM_TEXT_MAX 64

#if defined(__SIZEOF_INT128__) && NVSIZE == 8 && NV_DIG == 15
#define HAVE_FAST_G15 1
/* The 15 significant digits %.15g prints for 1e-13 <= |v| < 1e21: the
 * exact binary value rounded half-even, as glibc does. v equals
 * q * 10^(e10 - 14) after rounding, q in [10^14, 10^15). 0 = out of range. */
static int g15_digits(double v, uint64_t *qp, int *e10p, int *negp) {
    static const uint64_t p5[28] = {
        1ULL, 5ULL, 25ULL, 125ULL, 625ULL, 3125ULL, 15625ULL, 78125ULL,
        390625ULL, 1953125ULL, 9765625ULL, 48828125ULL, 244140625ULL,
        1220703125ULL, 6103515625ULL, 30517578125ULL, 152587890625ULL,
        762939453125ULL, 3814697265625ULL, 19073486328125ULL,
        95367431640625ULL, 476837158203125ULL, 2384185791015625ULL,
        11920928955078125ULL, 59604644775390625ULL, 298023223876953125ULL,
        1490116119384765625ULL, 7450580596923828125ULL
    };
    const uint64_t lo15 = 100000000000000ULL, hi15 = 1000000000000000ULL;
    uint64_t bits, mant, q;
    int exp2, neg, e10, tries;
    double a;
    memcpy(&bits, &v, 8);
    neg = (int)(bits >> 63);
    exp2 = (int)((bits >> 52) & 0x7ff);
    if (exp2 == 0 || exp2 == 0x7ff) return 0;
    a = neg ? -v : v;
    if (!(a >= 1e-13 && a < 1e21)) return 0;
    mant = (bits & ((1ULL << 52) - 1)) | (1ULL << 52);
    exp2 -= 1075;
    /* floor(log10(a)) to within one, corrected below */
    e10 = ((exp2 + 52) * 78913) >> 18;
    /* Double arithmetic first: a * 10^k is off by at most 0.12 from the
     * exact product, so it decides the rounding unless it lands near .5
     * or a digit-count boundary. */
    for (tries = 0; tries < 3; tries++) {
        static const double p10d[23] = {
            1e0, 1e1, 1e2, 1e3, 1e4, 1e5, 1e6, 1e7, 1e8, 1e9, 1e10, 1e11,
            1e12, 1e13, 1e14, 1e15, 1e16, 1e17, 1e18, 1e19, 1e20, 1e21, 1e22
        };
        int k = 14 - e10;
        double y, f, r;
        if (k < -22 || k > 22) break;
        y = k >= 0 ? a * p10d[k] : a / p10d[-k];
        if (y < 1e14) { e10--; continue; }
        if (y >= 1e15) { e10++; continue; }
        if (y < 1e14 + 1 || y > 1e15 - 2) break;
        f = floor(y);
        r = y - f;
        if (r > 0.3 && r < 0.7) break;
        *qp = (uint64_t)f + (r >= 0.7);
        *e10p = e10;
        *negp = neg;
        return 1;
    }
    for (tries = 0; ; tries++) {
        int k = 14 - e10, s, up;
        unsigned __int128 n, r;
        if (tries > 3 || k < -7 || k > 27) return 0;
        if (k >= 0) {
            n = (unsigned __int128)mant * p5[k];
            s = k + exp2;
            if (s >= 0) {
                if (s > 10) return 0;
                q = (uint64_t)(n << s);
                up = 0;
                if ((n << s) >> 64) return 0;
            } else {
                unsigned __int128 half;
                if (-s > 120) return 0;
                if ((n >> -s) >> 64) { e10++; continue; }
                q = (uint64_t)(n >> -s);
                r = n & ((((unsigned __int128)1) << -s) - 1);
                half = ((unsigned __int128)1) << (-s - 1);
                up = r > half || (r == half && (q & 1));
            }
        } else {
            uint64_t d = p5[-k];
            s = exp2 + k;
            if (s < 0 || s > 60) return 0;
            n = (unsigned __int128)mant << s;
            if ((n / d) >> 64) { e10++; continue; }
            q = (uint64_t)(n / d);
            r = n % d;
            up = 2 * r > d || (2 * r == d && (q & 1));
        }
        if (q >= hi15) { e10++; continue; }
        if (q < lo15) { e10--; continue; }
        if (up) q++;
        if (q == hi15) { q = lo15; e10++; }
        break;
    }
    *qp = q;
    *e10p = e10;
    *negp = neg;
    return 1;
}

/* snprintf(buf, "%.15g", v) where g15_digits applies, else 0. */
static int fast_g15(double v, char *buf) {
    uint64_t q;
    int e10, neg;
    char dig[16], *p = buf;
    if (!g15_digits(v, &q, &e10, &neg)) return 0;
    {
        int i, nd = 15;
        uint32_t hi = (uint32_t)(q / 100000000), lo = (uint32_t)(q % 100000000);
        for (i = 14; i >= 7; i--) { dig[i] = (char)('0' + lo % 10); lo /= 10; }
        for (i = 6; i >= 0; i--) { dig[i] = (char)('0' + hi % 10); hi /= 10; }
        while (nd > 1 && dig[nd - 1] == '0') nd--;
        if (neg) *p++ = '-';
        if (e10 < -4 || e10 >= 15) {
            int x = e10 < 0 ? -e10 : e10;
            *p++ = dig[0];
            if (nd > 1) { *p++ = '.'; for (i = 1; i < nd; i++) *p++ = dig[i]; }
            *p++ = 'e';
            *p++ = e10 < 0 ? '-' : '+';
            if (x >= 100) *p++ = (char)('0' + x / 100);
            *p++ = (char)('0' + x / 10 % 10);
            *p++ = (char)('0' + x % 10);
        } else if (e10 >= 0) {
            for (i = 0; i <= e10; i++) *p++ = i < 15 ? dig[i] : '0';
            if (nd > e10 + 1) { *p++ = '.'; for (i = e10 + 1; i < nd; i++) *p++ = dig[i]; }
        } else {
            *p++ = '0';
            *p++ = '.';
            for (i = 0; i < -e10 - 1; i++) *p++ = '0';
            for (i = 0; i < nd; i++) *p++ = dig[i];
        }
    }
    *p = '\0';
    return (int)(p - buf);
}
#endif

static const char *sv_num_text(pTHX_ SV *sv, char *buf, STRLEN *len) {
    NV nv;
    int n;
    if (SvIOK(sv)) {
        n = SvIsUV(sv) ? snprintf(buf, SV_NUM_TEXT_MAX, "%" UVuf, SvUVX(sv))
                       : snprintf(buf, SV_NUM_TEXT_MAX, "%" IVdf, SvIVX(sv));
    } else {
        nv = SvNVX(sv);
        if (nv == 0.0 && !Perl_isnan(nv))
            n = snprintf(buf, SV_NUM_TEXT_MAX, "0");
        else if (Perl_isnan(nv))
            n = snprintf(buf, SV_NUM_TEXT_MAX, "NaN");
        else if (Perl_isinf(nv))
            n = snprintf(buf, SV_NUM_TEXT_MAX, nv > 0 ? "Inf" : "-Inf");
        else {
#ifdef HAVE_FAST_G15
            n = fast_g15((double)nv, buf);
            if (!n)
#endif
            n = snprintf(buf, SV_NUM_TEXT_MAX, "%.*" NVgf, NV_DIG, nv);
        }
    }
    *len = (STRLEN)n;
    return buf;
}

/* SvPV(sv, len) without caching a string in a plain number. */
#define SV_TEXT(sv, buf, len) \
    (SV_PLAIN_NUM(sv) ? sv_num_text(aTHX_ (sv), (buf), &(len)) : SvPV((sv), (len)))

/* parse_decimal_to_raw() of the text SvPV gives a plain number, computed
 * from the number: 1 when done (*ok the verdict), 0 to parse the text. */
static int num_decimal_raw(pTHX_ SV *sv, int scale, int precision,
                           int64_t *raw, int *ok) {
    static const uint64_t p10[19] = {
        1ULL, 10ULL, 100ULL, 1000ULL, 10000ULL, 100000ULL, 1000000ULL,
        10000000ULL, 100000000ULL, 1000000000ULL, 10000000000ULL,
        100000000000ULL, 1000000000000ULL, 10000000000000ULL,
        100000000000000ULL, 1000000000000000ULL, 10000000000000000ULL,
        100000000000000000ULL, 1000000000000000000ULL
    };
    uint64_t mag, t;
    int neg = 0, int_digits = 0;
    *ok = 0;
    if (!SV_PLAIN_NUM(sv) || scale < 0 || scale > 18
        || precision < 1 || precision > 18)
        return 0;
    if (SvIOK(sv)) {
        if (SvIsUV(sv)) {
            mag = SvUVX(sv);
        } else {
            IV iv = SvIVX(sv);
            neg = iv < 0;
            mag = neg ? (uint64_t)0 - (uint64_t)iv : (uint64_t)iv;
        }
        for (t = mag; t; t /= 10) int_digits++;
        if (int_digits > precision - scale) return 1;
        mag *= p10[scale];
    } else {
#ifdef HAVE_FAST_G15
        NV nv = SvNVX(sv);
        uint64_t q;
        int e10, sh;
        if (nv == 0.0) {
            *raw = 0;
            *ok = 1;
            return 1;
        }
        if (!g15_digits((double)nv, &q, &e10, &neg)) return 0;
        int_digits = e10 >= 0 ? e10 + 1 : 0;
        if (int_digits > precision - scale) return 1;
        sh = e10 - 14 + scale;
        mag = sh >= 0 ? q * p10[sh] : -sh > 18 ? 0 : q / p10[-sh];
#else
        return 0;
#endif
    }
    *raw = neg ? -(int64_t)mag : (int64_t)mag;
    *ok = 1;
    return 1;
}

/*
 * Encode a column of Perl SV values into native binary format.
 * Like encode_column_text() but takes SVs directly — no TSV parsing/unescaping.
 * Returns 1 on success, 0 if type is unsupported.
 */
static int encode_column_sv(pTHX_ native_buf_t *b,
                            SV **values, uint64_t nrows,
                            col_type_t *ct) {
    uint64_t i;
    char nbuf_num[SV_NUM_TEXT_MAX];

    switch (ct->code) {
    case CT_INT8: {
        for (i = 0; i < nrows; i++) {
            int ok = 0;
            int64_t w = sv_to_int64_strict(aTHX_ values[i], &ok);
            if (!ok || w < -128 || w > 127) return 0;
            {
                int8_t v = (int8_t)w;
                nbuf_append(b, (const char *)&v, 1);
            }
        }
        return 1;
    }
    case CT_ENUM8: case CT_ENUM16: {
        enum_entry_t *entries = NULL;
        size_t nentries = enum_parse_entries(ct->type_str, ct->type_str_len, &entries);
        int numeric_labels = enum_has_numeric_label(entries, nentries);
        int rc = 1;
        for (i = 0; i < nrows; i++) {
            SV *v = values[i];
            int code, ok = 0;
            if (!SvOK(v)) { rc = 0; break; }
            if (SvPOK(v) || numeric_labels) {
                STRLEN vlen;
                const char *s = SvPV(v, vlen);
                ok = enum_code_for_label(entries, nentries, s, vlen, &code);
            }
            if (!ok) {
                int64_t w = sv_to_int64_strict(aTHX_ v, &ok);
                if (!ok || !enum_has_code(entries, nentries, w)) { rc = 0; break; }
                code = (int)w;
            }
            nbuf_enum(b, ct->code, code);
        }
        enum_free_entries(entries, nentries);
        return rc;
    }
    case CT_INT16: {
        for (i = 0; i < nrows; i++) {
            int ok = 0;
            int64_t w = sv_to_int64_strict(aTHX_ values[i], &ok);
            if (!ok || w < -32768 || w > 32767) return 0;
            {
                int16_t v = (int16_t)w;
                nbuf_append(b, (const char *)&v, 2);
            }
        }
        return 1;
    }
    case CT_INT32: case CT_DATE32: {
        for (i = 0; i < nrows; i++) {
            int32_t v;
            STRLEN vlen;
            const char *s;
            if (!SvOK(values[i])) return 0;
            if (SV_PLAIN_NUM(values[i])) { s = NULL; vlen = 0; }
            else s = SvPV(values[i], vlen);
            if (ct->code == CT_DATE32 && vlen >= 10 && s[4] == '-') {
                if (vlen != 10) return 0;
                if (!valid_date_prefix(s, vlen)) return 0;
                v = date_string_to_days(s, vlen);
            } else {
                int ok = 0;
                int64_t w = sv_to_int64_strict(aTHX_ values[i], &ok);
                if (!ok || w < (int64_t)INT32_MIN || w > (int64_t)INT32_MAX)
                    return 0;
                v = (int32_t)w;
            }
            nbuf_append(b, (const char *)&v, 4);
        }
        return 1;
    }
    case CT_INT64: {
        for (i = 0; i < nrows; i++) {
            int ok = 0;
            int64_t v = sv_to_int64_strict(aTHX_ values[i], &ok);
            if (!ok) return 0;
            nbuf_append(b, (const char *)&v, 8);
        }
        return 1;
    }
    case CT_UINT8: {
        for (i = 0; i < nrows; i++) {
            int ok = 0;
            uint64_t w = sv_to_uint64_strict(aTHX_ values[i], &ok);
            if (!ok || w > 255) return 0;
            {
                uint8_t v = (uint8_t)w;
                nbuf_append(b, (const char *)&v, 1);
            }
        }
        return 1;
    }
    case CT_BOOL: {
        for (i = 0; i < nrows; i++) {
            uint8_t v;
            if (!SvOK(values[i])) return 0;
            v = SvTRUE(values[i]) ? 1 : 0;
            nbuf_append(b, (const char *)&v, 1);
        }
        return 1;
    }
    case CT_UINT16: case CT_DATE: {
        for (i = 0; i < nrows; i++) {
            uint16_t v;
            STRLEN vlen;
            const char *s;
            if (!SvOK(values[i])) return 0;
            if (SV_PLAIN_NUM(values[i])) { s = NULL; vlen = 0; }
            else s = SvPV(values[i], vlen);
            if (ct->code == CT_DATE && vlen >= 10 && s[4] == '-') {
                int32_t days;
                if (vlen != 10) return 0;
                if (!valid_date_prefix(s, vlen)) return 0;
                days = date_string_to_days(s, vlen);
                if (days < 0 || days > 65535) return 0;
                v = (uint16_t)days;
            } else {
                int ok = 0;
                uint64_t w = sv_to_uint64_strict(aTHX_ values[i], &ok);
                if (!ok || w > 65535) return 0;
                v = (uint16_t)w;
            }
            nbuf_append(b, (const char *)&v, 2);
        }
        return 1;
    }
    case CT_UINT32: case CT_DATETIME: {
        int rc = 1;
        for (i = 0; i < nrows; i++) {
            uint32_t v;
            STRLEN vlen;
            const char *s;
            if (!SvOK(values[i])) { rc = 0; break; }
            if (SV_PLAIN_NUM(values[i])) { s = NULL; vlen = 0; }
            else s = SvPV(values[i], vlen);
            if (ct->code == CT_DATETIME && vlen >= 10 && s[4] == '-') {
                int32_t days;
                int64_t total;
                if (vlen != 10 && vlen != 19) { rc = 0; break; }
                if (!valid_date_prefix(s, vlen)) { rc = 0; break; }
                if (vlen >= 19 && !valid_time_part(s)) { rc = 0; break; }
                days = date_string_to_days(s, 10);
                total = (int64_t)days * 86400 + parse_hms(s, vlen);
                if (ct->tz) {
                    int tok = 0;
                    total = wall_in_tz_to_epoch(total, ct, &tok);
                    if (!tok) { rc = 0; break; }
                }
                if (total < 0 || total > (int64_t)UINT32_MAX) { rc = 0; break; }
                v = (uint32_t)total;
            } else {
                int ok = 0;
                uint64_t w = sv_to_uint64_strict(aTHX_ values[i], &ok);
                if (!ok || w > (uint64_t)UINT32_MAX) { rc = 0; break; }
                v = (uint32_t)w;
            }
            nbuf_append(b, (const char *)&v, 4);
        }
        return rc;
    }
    case CT_UINT64: {
        for (i = 0; i < nrows; i++) {
            int ok = 0;
            uint64_t v = sv_to_uint64_strict(aTHX_ values[i], &ok);
            if (!ok) return 0;
            nbuf_append(b, (const char *)&v, 8);
        }
        return 1;
    }
    case CT_FLOAT32: {
        for (i = 0; i < nrows; i++) {
            float v;
            if (!SvOK(values[i])) return 0;
            if (SvNOK(values[i])) {
                v = (float)SvNV(values[i]);
            } else {
                STRLEN vlen;
                const char *s = SV_TEXT(values[i], nbuf_num, vlen);
                char *endp;
                if (vlen == 0) return 0;
                v = strtof(s, &endp);
                if (endp != s + vlen) return 0;
            }
            nbuf_append(b, (const char *)&v, 4);
        }
        return 1;
    }
    case CT_FLOAT64: {
        for (i = 0; i < nrows; i++) {
            double v;
            if (!SvOK(values[i])) return 0;
            if (SvNOK(values[i])) {
                v = SvNV(values[i]);
            } else {
                STRLEN vlen;
                const char *s = SV_TEXT(values[i], nbuf_num, vlen);
                char *endp;
                if (vlen == 0) return 0;
                v = strtod(s, &endp);
                if (endp != s + vlen) return 0;
            }
            nbuf_append(b, (const char *)&v, 8);
        }
        return 1;
    }
    case CT_DATETIME64: {
        int rc = 1;
        for (i = 0; i < nrows; i++) {
            int64_t v;
            if (!SvOK(values[i])) { rc = 0; break; }
            if (SvIOK(values[i])) {
                v = (int64_t)SvIV(values[i]);
            } else {
                STRLEN vlen;
                const char *s = SV_TEXT(values[i], nbuf_num, vlen);
                if (vlen >= 10 && s[4] == '-') {
                    int ok = 0;
                    v = parse_datetime64_to_scaled(s, vlen, ct->param, ct, &ok);
                    if (!ok) { rc = 0; break; }
                } else {
                    int ok = 0;
                    v = parse_int64_strict(s, vlen, &ok);
                    if (!ok) { rc = 0; break; }
                }
            }
            nbuf_append(b, (const char *)&v, 8);
        }
        return rc;
    }
    case CT_TIME: {
        for (i = 0; i < nrows; i++) {
            int64_t v;
            int32_t w;
            if (!SvOK(values[i])) return 0;
            if (SvIOK(values[i])) {
                v = (int64_t)SvIV(values[i]);
            } else {
                STRLEN vlen;
                const char *s = SV_TEXT(values[i], nbuf_num, vlen);
                int ok = 0;
                v = parse_time_text(s, vlen, 0, &ok);
                if (!ok) {
                    v = parse_int64_strict(s, vlen, &ok);
                    if (!ok) return 0;
                }
            }
            if (v > INT32_MAX || v < INT32_MIN) return 0;
            w = (int32_t)v;
            nbuf_append(b, (const char *)&w, 4);
        }
        return 1;
    }
    case CT_TIME64: {
        for (i = 0; i < nrows; i++) {
            int64_t v;
            if (!SvOK(values[i])) return 0;
            if (SvIOK(values[i])) {
                v = (int64_t)SvIV(values[i]);
            } else {
                STRLEN vlen;
                const char *s = SV_TEXT(values[i], nbuf_num, vlen);
                int ok = 0;
                v = parse_time_text(s, vlen, ct->param, &ok);
                if (!ok) {
                    v = parse_int64_strict(s, vlen, &ok);
                    if (!ok) return 0;
                }
            }
            nbuf_append(b, (const char *)&v, 8);
        }
        return 1;
    }
    case CT_DECIMAL32: {
        for (i = 0; i < nrows; i++) {
            STRLEN vlen;
            const char *s;
            int ok = 0;
            int32_t v;
            int64_t raw;
            if (!SvOK(values[i])) return 0;
            if (!num_decimal_raw(aTHX_ values[i], ct->param, ct->precision,
                                 &raw, &ok)) {
                s = SV_TEXT(values[i], nbuf_num, vlen);
                raw = parse_decimal_to_raw(s, vlen, ct->param,
                                           ct->precision, &ok);
            }
            v = (int32_t)raw;
            if (!ok) return 0;
            nbuf_append(b, (const char *)&v, 4);
        }
        return 1;
    }
    case CT_DECIMAL64: {
        for (i = 0; i < nrows; i++) {
            STRLEN vlen;
            const char *s;
            int ok = 0;
            int64_t v;
            if (!SvOK(values[i])) return 0;
            if (!num_decimal_raw(aTHX_ values[i], ct->param, ct->precision,
                                 &v, &ok)) {
                s = SV_TEXT(values[i], nbuf_num, vlen);
                v = parse_decimal_to_raw(s, vlen, ct->param, ct->precision, &ok);
            }
            if (!ok) return 0;
            nbuf_append(b, (const char *)&v, 8);
        }
        return 1;
    }
    case CT_DECIMAL128: {
        for (i = 0; i < nrows; i++) {
            STRLEN vlen;
            const char *s;
            unsigned char raw[16];
            if (!SvOK(values[i])) return 0;
            s = SV_TEXT(values[i], nbuf_num, vlen);
            if (!parse_decimal128_to_raw(s, vlen, ct->param, ct->precision,
                                         raw))
                return 0;
            nbuf_append(b, (const char *)raw, 16);
        }
        return 1;
    }
    case CT_DECIMAL256: {
        /* Decimal text, or raw 32 bytes (LE, signed) — the shape the
         * decoder delivers. Useful with Math::BigInt::to_bytes(LE).
         * The raw fallback needs a non-text byte, so a 32-char typo
         * fails loudly instead of storing garbage. */
        for (i = 0; i < nrows; i++) {
            STRLEN slen;
            const char *s;
            unsigned char raw[32];
            if (!SvOK(values[i])) return 0;
            s = SV_TEXT(values[i], nbuf_num, slen);
            if (parse_decimal256_to_raw(s, slen, ct->param, ct->precision, raw)) {
                nbuf_append(b, (const char *)raw, 32);
            } else if (slen == 32) {
                STRLEN k;
                int binary = 0;
                for (k = 0; k < slen; k++) {
                    unsigned char c = (unsigned char)s[k];
                    if (c < 0x20 || c > 0x7E) { binary = 1; break; }
                }
                if (!binary) return 0;
                nbuf_append(b, s, 32);
            } else {
                return 0;
            }
        }
        return 1;
    }
    case CT_BFLOAT16: {
        for (i = 0; i < nrows; i++) {
            float fv;
            if (!SvOK(values[i])) return 0;
            if (SvNOK(values[i])) {
                fv = (float)SvNV(values[i]);
            } else {
                STRLEN vlen;
                const char *s = SV_TEXT(values[i], nbuf_num, vlen);
                char *endp;
                if (vlen == 0) return 0;
                fv = (float)strtod(s, &endp);
                if (endp != s + vlen) return 0;
            }
            uint8_t b32[4]; memcpy(b32, &fv, 4);
            /* Truncate to top 16 bits — bytes [2,3] of a LE Float32. */
            nbuf_append(b, (const char *)&b32[2], 2);
        }
        return 1;
    }
    case CT_STRING: {
        for (i = 0; i < nrows; i++) {
            STRLEN vlen;
            const char *v;
            if (!SvOK(values[i])) return 0;
            v = SV_TEXT(values[i], nbuf_num, vlen);
            nbuf_string(b, v, vlen);
        }
        return 1;
    }
    case CT_FIXEDSTRING: {
        size_t fsz = (size_t)ct->param;
        for (i = 0; i < nrows; i++) {
            STRLEN vlen;
            const char *v;
            if (!SvOK(values[i])) return 0;
            v = SV_TEXT(values[i], nbuf_num, vlen);
            if ((size_t)vlen > fsz) return 0;
            nbuf_grow(b, fsz);
            memcpy(b->data + b->len, v, vlen);
            if ((size_t)vlen < fsz)
                memset(b->data + b->len + vlen, 0, fsz - (size_t)vlen);
            b->len += fsz;
        }
        return 1;
    }
    case CT_UUID: {
        for (i = 0; i < nrows; i++) {
            unsigned char ubytes[16];
            STRLEN slen;
            const char *s;
            if (!SvOK(values[i])) return 0;
            s = SV_TEXT(values[i], nbuf_num, slen);
            if (!parse_uuid_to_le_bytes(s, slen, ubytes)) return 0;
            nbuf_append(b, (const char *)ubytes, 16);
        }
        return 1;
    }
    case CT_IPV4: {
        for (i = 0; i < nrows; i++) {
            STRLEN vlen;
            const char *s;
            uint32_t v;
            int ok = 0;
            if (!SvOK(values[i])) return 0;
            s = SV_TEXT(values[i], nbuf_num, vlen);
            v = parse_ipv4_to_u32(s, (size_t)vlen, &ok);
            if (!ok) return 0;
            nbuf_append(b, (const char *)&v, 4);
        }
        return 1;
    }
    case CT_IPV6: {
        for (i = 0; i < nrows; i++) {
            unsigned char addr[16];
            STRLEN vlen;
            const char *s;
            if (!SvOK(values[i])) return 0;
            s = SV_TEXT(values[i], nbuf_num, vlen);
            if (!parse_ipv6_to_bytes(s, (size_t)vlen, addr)) return 0;
            nbuf_append(b, (const char *)addr, 16);
        }
        return 1;
    }
    case CT_NULLABLE: {
        uint8_t *nulls;
        SV **inner_vals;
        SV *zero_sv;

        Newx(nulls, nrows, uint8_t);
        Newx(inner_vals, nrows ? nrows : 1, SV *);
        zero_sv = nullable_inner_zero_sv(aTHX_ ct->inner);

        for (i = 0; i < nrows; i++) {
            if (!SvOK(values[i])) {
                nulls[i] = 1;
                inner_vals[i] = zero_sv;
            } else {
                nulls[i] = 0;
                inner_vals[i] = values[i];
            }
        }

        nbuf_append(b, (const char *)nulls, nrows);
        {
            int rc = encode_column_sv(aTHX_ b, inner_vals, nrows, ct->inner);
            Safefree(nulls);
            Safefree(inner_vals);
            SvREFCNT_dec(zero_sv);
            return rc;
        }
    }
    case CT_LOWCARDINALITY: {
        size_t idx_size;
        native_buf_t dict_buf;
        int rc;

        if (nrows == 0) return 1;
        if (ct->inner->code == CT_NULLABLE) {
            /* Dict travels as plain T with slot 0 reserved for NULL:
             * [T default] + rows (nulls substituted), null->0 else i+1. */
            SV **dvals;
            uint8_t *nulls;
            SV *zero_sv = nullable_inner_zero_sv(aTHX_ ct->inner->inner);
            Newx(dvals, nrows + 1, SV *);
            Newx(nulls, nrows ? nrows : 1, uint8_t);
            dvals[0] = zero_sv;
            for (i = 0; i < nrows; i++) {
                if (!SvOK(values[i])) {
                    nulls[i] = 1;
                    dvals[i + 1] = zero_sv;
                } else {
                    nulls[i] = 0;
                    dvals[i + 1] = values[i];
                }
            }
            lc_write_keys_header(b, nrows + 1, &idx_size);
            nbuf_init(&dict_buf);
            rc = encode_column_sv(aTHX_ &dict_buf, dvals, nrows + 1,
                                  ct->inner->inner);
            Safefree(dvals);
            SvREFCNT_dec(zero_sv);
            if (!rc) { Safefree(dict_buf.data); Safefree(nulls); return 0; }
            nbuf_append(b, dict_buf.data, dict_buf.len);
            Safefree(dict_buf.data);
            lc_write_nullable_indices(b, nrows, idx_size, nulls);
            Safefree(nulls);
            return 1;
        }

        lc_write_keys_header(b, nrows, &idx_size);
        nbuf_init(&dict_buf);
        rc = encode_column_sv(aTHX_ &dict_buf, values, nrows, ct->inner);
        if (!rc) { Safefree(dict_buf.data); return 0; }
        nbuf_append(b, dict_buf.data, dict_buf.len);
        Safefree(dict_buf.data);
        lc_write_indices(b, nrows, idx_size);
        return 1;
    }
    case CT_ARRAY: {
        /* Each value must be an AV ref. Wire format: offsets + flat inner data */
        uint64_t total = 0;
        uint64_t *offsets;
        SV **all_elems;
        uint64_t pos = 0;
        int rc;

        for (i = 0; i < nrows; i++) {
            AV *av;
            if (!SvROK(values[i]) || SvTYPE(SvRV(values[i])) != SVt_PVAV)
                return 0;
            av = (AV *)SvRV(values[i]);
            { SSize_t cnt = av_len(av) + 1; if (cnt > 0) total += (uint64_t)cnt; }
        }

        Newx(offsets, nrows, uint64_t);
        Newx(all_elems, total ? total : 1, SV *);

        for (i = 0; i < nrows; i++) {
            AV *av = (AV *)SvRV(values[i]);
            SSize_t n = av_len(av) + 1, j;
            /* av_fetch on a tie returns a lazy mortal proxy: copy the
             * fetched value (borrowing the proxy would re-FETCH on
             * every later read). Plain arrays borrow as before. */
            int av_magical = SvRMAGICAL((SV *)av);
            /* A tie whose FETCHSIZE grew since the sizing pass would
             * overflow all_elems: fail clean instead. */
            if (n > 0 && (uint64_t)n > total - pos)
                goto arr_oom;
            for (j = 0; j < n; j++) {
                SV **ep = av_fetch(av, j, 0);
                SV *elem = (ep && *ep) ? *ep : &PL_sv_undef;
                /* Fetch exactly once: a borrowed proxy re-FETCHes on
                 * every later read, and a later SvPV would too. */
                if (av_magical || SvGMAGICAL(elem))
                    elem = sv_2mortal(newSVsv(elem));
                all_elems[pos++] = elem;
            }
            offsets[i] = pos;
        }
        /* Encode what was actually gathered: a tie that shrank since
         * the sizing pass must not leave total pointing past pos. */
        total = pos;

        /* write offsets as uint64 LE */
        nbuf_append(b, (const char *)offsets, nrows * 8);
        rc = encode_column_sv(aTHX_ b, all_elems, total, ct->inner);
        Safefree(offsets);
        Safefree(all_elems);
        return rc;
    arr_oom:
        Safefree(offsets);
        Safefree(all_elems);
        return 0;
    }
    case CT_TUPLE: {
        /* Each value must be an AV ref with num_inners elements */
        int j;
        if (ct->num_inners == 0) {
            /* Empty Tuple(): 1 placeholder byte per row on the wire */
            for (i = 0; i < nrows; i++) {
                if (!SvROK(values[i]) || SvTYPE(SvRV(values[i])) != SVt_PVAV)
                    return 0;
                nbuf_append(b, "0", 1);
            }
            return 1;
        }
        for (j = 0; j < ct->num_inners; j++) {
            SV **col_vals;
            int rc;
            Newx(col_vals, nrows ? nrows : 1, SV *);
            for (i = 0; i < nrows; i++) {
                AV *av;
                SV **ep;
                SV *elem;
                if (!SvROK(values[i]) || SvTYPE(SvRV(values[i])) != SVt_PVAV) {
                    Safefree(col_vals);
                    return 0;
                }
                av = (AV *)SvRV(values[i]);
                ep = av_fetch(av, j, 0);
                elem = (ep && *ep) ? *ep : &PL_sv_undef;
                if (SvRMAGICAL((SV *)av) || SvGMAGICAL(elem))
                    elem = sv_2mortal(newSVsv(elem));
                col_vals[i] = elem;
            }
            rc = encode_column_sv(aTHX_ b, col_vals, nrows, ct->inners[j]);
            Safefree(col_vals);
            if (!rc) return 0;
        }
        return 1;
    }
    case CT_MAP: {
        /* Each value must be a hashref. Wire format: offsets + key column + value column */
        uint64_t total = 0;
        uint64_t cap = 0;
        uint64_t *offsets;
        SV **all_keys, **all_vals;
        uint64_t pos = 0;
        int rc;

        if (ct->num_inners != 2) return 0;

        for (i = 0; i < nrows; i++) {
            HV *hv;
            if (!SvROK(values[i]) || SvTYPE(SvRV(values[i])) != SVt_PVHV)
                return 0;
            hv = (HV *)SvRV(values[i]);
            /* sizing hint only: HvUSEDKEYS is meaningless for tied
             * hashes, so the fill loop grows below as needed. */
            total += HvUSEDKEYS(hv);
        }

        Newx(offsets, nrows, uint64_t);
        cap = total ? total : 1;
        Newx(all_keys, cap, SV *);
        Newx(all_vals, cap, SV *);

        for (i = 0; i < nrows; i++) {
            HV *hv = (HV *)SvRV(values[i]);
            HE *he;
            /* hv_iterval on a tie returns a lazy mortal FETCH proxy:
             * copy the fetched value (borrowing the proxy would
             * re-FETCH on every later read, and its fake-HE key
             * is not safe to borrow either). */
            int hv_magical = SvRMAGICAL((SV *)hv);
            hv_iterinit(hv);
            while ((he = hv_iternext(hv))) {
                I32 klen;
                SV *vsv;
                char *key = hv_iterkey(he, &klen);
                if (pos >= cap) {
                    if (cap > (uint64_t)SIZE_MAX / (2 * sizeof(SV *)))
                        goto map_oom;
                    cap *= 2;
                    Renew(all_keys, cap, SV *);
                    Renew(all_vals, cap, SV *);
                }
                vsv = hv_iterval(hv, he);
                if (hv_magical) {
                    all_keys[pos] = sv_2mortal(newSVpvn(key, klen));
                    all_vals[pos] = sv_2mortal(newSVsv(vsv));
                } else {
                    all_keys[pos] = hv_iterkeysv(he);
                    all_vals[pos] = SvGMAGICAL(vsv)
                        ? sv_2mortal(newSVsv(vsv)) : vsv;
                }
                pos++;
            }
            offsets[i] = pos;
        }
        total = pos;

        nbuf_append(b, (const char *)offsets, nrows * 8);
        rc = encode_column_sv(aTHX_ b, all_keys, total, ct->inners[0]);
        if (rc) rc = encode_column_sv(aTHX_ b, all_vals, total, ct->inners[1]);
        Safefree(offsets);
        Safefree(all_keys);
        Safefree(all_vals);
        return rc;
    map_oom:
        Safefree(offsets);
        Safefree(all_keys);
        Safefree(all_vals);
        return 0;
    }
    case CT_JSON: {
        /* Wire layout (V1) per Clickhouse-Encoder/doc/json-research:
         *   Object prefix: UInt64=0, varint K (twice), K * lenstr path
         *   Per-path Dynamic prefix: UInt64=1, varint T (twice),
         *                            T * lenstr type-name, UInt64=0
         *   Per-path data: N disc bytes, then per-variant data in lex
         *                  order including a SharedVariant slot
         *   Shared data trailer: N * UInt64 LE zero (no shared paths)
         */
        ENTER; SAVETMPS;
        int p;
        HV **row_hvs = NULL;
        if (nrows > 0) {
            Newxz(row_hvs, nrows, HV*);
            SAVEFREEPV(row_hvs);
        }
        HV *all_paths = (HV*)sv_2mortal((SV*)newHV());

        for (i = 0; i < nrows; i++) {
            SV *val = values[i];
            if (!SvOK(val)) { row_hvs[i] = NULL; continue; }
            if (!SvROK(val) || SvTYPE(SvRV(val)) != SVt_PVHV) {
                FREETMPS; LEAVE;
                return 0;
            }
            HV *flat = (HV*)sv_2mortal((SV*)newHV());
            if (!flatten_json_hash(aTHX_ (HV*)SvRV(val), NULL, 0, flat)) {
                FREETMPS; LEAVE;
                return 0;
            }
            row_hvs[i] = flat;
        }

        /* Typed paths: extract per-row values from each flat HV (and
         * hv_delete to keep them out of the dynamic-paths discovery).
         * Missing keys substitute undef as a placeholder; the inner
         * encoder treats undef as the type's zero/default. */
        int n_typed = (ct->code == CT_JSON) ? ct->num_inners : 0;
        SV ***typed_vals = NULL;
        if (n_typed > 0) {
            Newxz(typed_vals, n_typed, SV **);
            SAVEFREEPV(typed_vals);
            int tp;
            for (tp = 0; tp < n_typed; tp++) {
                Newxz(typed_vals[tp], nrows > 0 ? nrows : 1, SV *);
                SAVEFREEPV(typed_vals[tp]);
                size_t nlen = strlen(ct->inner_names[tp]);
                for (i = 0; i < nrows; i++) {
                    if (!row_hvs[i]) {
                        typed_vals[tp][i] = &PL_sv_undef;
                        continue;
                    }
                    SV **e = hv_fetch(row_hvs[i], ct->inner_names[tp],
                                      (I32)nlen, 0);
                    if (e && SvOK(*e)) {
                        typed_vals[tp][i] = SvREFCNT_inc(*e);
                        sv_2mortal(typed_vals[tp][i]);
                        hv_delete(row_hvs[i], ct->inner_names[tp],
                                  (I32)nlen, G_DISCARD);
                    } else {
                        typed_vals[tp][i] = &PL_sv_undef;
                    }
                }
            }
        }

        /* Now collect dynamic-path keys (typed paths already removed). */
        for (i = 0; i < nrows; i++) {
            if (!row_hvs[i]) continue;
            hv_iterinit(row_hvs[i]);
            HE *he;
            while ((he = hv_iternext(row_hvs[i]))) {
                I32 klen;
                char *kstr = hv_iterkey(he, &klen);
                (void)hv_store(all_paths, kstr, klen, newSViv(1), 0);
            }
        }

        int num_paths = (int)HvUSEDKEYS(all_paths);
        json_path_entry_t *pe = NULL;
        if (num_paths > 0) {
            Newx(pe, num_paths, json_path_entry_t);
            SAVEFREEPV(pe);
            p = 0;
            hv_iterinit(all_paths);
            HE *he;
            while ((he = hv_iternext(all_paths))) {
                I32 klen;
                char *kstr = hv_iterkey(he, &klen);
                pe[p].path = kstr;
                pe[p].len  = (STRLEN)klen;
                p++;
            }
            if (num_paths > 1)
                qsort(pe, num_paths, sizeof(*pe), json_cmp_path_entry);
        }

        unsigned *kind_masks = NULL;
        if (num_paths > 0) {
            Newxz(kind_masks, num_paths, unsigned);
            SAVEFREEPV(kind_masks);
            for (p = 0; p < num_paths; p++) {
                for (i = 0; i < nrows; i++) {
                    if (!row_hvs[i]) continue;
                    SV **e = hv_fetch(row_hvs[i], pe[p].path, (I32)pe[p].len, 0);
                    if (!e || !SvOK(*e)) continue;
                    int k = json_classify_value(aTHX_ *e);
                    if (k < 0) { FREETMPS; LEAVE; return 0; }
                    kind_masks[p] |= 1u << k;
                }
            }
        }

        /* Object structure prefix */
        nbuf_le64(b, 0);                              /* Object V1 */
        nbuf_varuint(b, (uint64_t)num_paths);
        nbuf_varuint(b, (uint64_t)num_paths);
        for (p = 0; p < num_paths; p++)
            nbuf_string(b, pe[p].path, pe[p].len);
        for (p = 0; p < n_typed; p++)
            write_col_prefix(b, ct->inners[p]);

        int *path_slots = NULL;
        int *wire_slot_counts = NULL;
        if (num_paths > 0) {
            Newx(path_slots, num_paths * JSON_LEX_SLOTS, int);
            SAVEFREEPV(path_slots);
            Newx(wire_slot_counts, num_paths, int);
            SAVEFREEPV(wire_slot_counts);
            for (p = 0; p < num_paths; p++)
                wire_slot_counts[p] = json_build_lex_table(
                    kind_masks[p], path_slots + p*JSON_LEX_SLOTS);
        }

        /* Per-path Dynamic V1 prefix + Variant mode */
        for (p = 0; p < num_paths; p++) {
            int wire_slots = wire_slot_counts[p];
            int kc = wire_slots - 1;
            nbuf_le64(b, 1);                       /* Dynamic V1 */
            nbuf_varuint(b, (uint64_t)kc);
            nbuf_varuint(b, (uint64_t)kc);
            int *slots = path_slots + p*JSON_LEX_SLOTS;
            int s;
            for (s = 0; s < wire_slots; s++) {
                int k = slots[s];
                if (k < 0) continue;
                const char *nm = json_kind_type_name[k];
                nbuf_string(b, nm, strlen(nm));
            }
            nbuf_le64(b, 0);                       /* Variant BASIC */
        }

        /* Typed-path column data — comes BEFORE dynamic-path Variant data
         * on the wire. Emitted in declaration (sorted) order via the
         * inner type's encoder. */
        if (n_typed > 0) {
            int tp;
            for (tp = 0; tp < n_typed; tp++) {
                int rc = encode_column_sv(aTHX_ b, typed_vals[tp],
                                          nrows, ct->inners[tp]);
                if (rc != 1) { FREETMPS; LEAVE; return 0; }
            }
        }

        /* Per-path Variant data */
        for (p = 0; p < num_paths; p++) {
            int wire_slots = wire_slot_counts[p];
            int *slots = path_slots + p*JSON_LEX_SLOTS;

            /* Discriminator byte per row */
            for (i = 0; i < nrows; i++) {
                if (!row_hvs[i]) { nbuf_u8(b, 0xff); continue; }
                SV **e = hv_fetch(row_hvs[i], pe[p].path, (I32)pe[p].len, 0);
                if (!e || !SvOK(*e)) { nbuf_u8(b, 0xff); continue; }
                int k = json_classify_value(aTHX_ *e);
                nbuf_u8(b, (uint8_t)json_kind_disc_in(k, slots, wire_slots));
            }

            /* Per-variant data in lex order. SharedVariant has zero rows. */
            int s;
            for (s = 0; s < wire_slots; s++) {
                int k_match = slots[s];
                if (k_match < 0) continue;
                int is_array = (k_match >= JV_ARRAY_BOOL
                             && k_match <= JV_ARRAY_UINT64);
                if (is_array) {
                    uint64_t offset = 0;
                    for (i = 0; i < nrows; i++) {
                        if (!row_hvs[i]) continue;
                        SV **e = hv_fetch(row_hvs[i], pe[p].path,
                                          (I32)pe[p].len, 0);
                        if (!e || !SvOK(*e)) continue;
                        if (json_classify_value(aTHX_ *e) != k_match) continue;
                        AV *av = (AV*)SvRV(*e);
                        SSize_t n = av_len(av) + 1;
                        offset += (uint64_t)n;
                        nbuf_le64(b, offset);
                    }
                }
                for (i = 0; i < nrows; i++) {
                    if (!row_hvs[i]) continue;
                    SV **e = hv_fetch(row_hvs[i], pe[p].path,
                                      (I32)pe[p].len, 0);
                    if (!e || !SvOK(*e)) continue;
                    if (json_classify_value(aTHX_ *e) != k_match) continue;
                    if (is_array) {
                        AV *av = (AV*)SvRV(*e);
                        SSize_t n = av_len(av) + 1, j;
                        int av_magical = SvRMAGICAL((SV*)av);
                        for (j = 0; j < n; j++) {
                            SV **elem = av_fetch(av, j, 0);
                            SV *ev = (elem && *elem)
                                   ? *elem : &PL_sv_undef;
                            if (av_magical || SvGMAGICAL(ev))
                                ev = sv_2mortal(newSVsv(ev));
                            if (!SvOK(ev)) ev = &PL_sv_undef;
                            json_emit_array_elem(aTHX_ b, ev, k_match);
                        }
                    } else {
                        json_emit_scalar(aTHX_ b, *e, k_match);
                    }
                }
            }
        }

        /* Shared data trailer: N UInt64 LE zero offsets */
        if (nrows > 0) {
            size_t nbytes = (size_t)nrows * 8;
            nbuf_grow(b, nbytes);
            memset(b->data + b->len, 0, nbytes);
            b->len += nbytes;
        }
        FREETMPS; LEAVE;
        return 1;
    }
    default:
        return 0;
    }
}

/*
 * Wrap a filled Data block body into a CLIENT_DATA packet with optional LZ4 + empty trailing block.
 * Consumes body->data (frees it). Returns malloc'd packet, or NULL on failure.
 */
static char* wrap_data_block(ev_clickhouse_t *self, native_buf_t *body, size_t *out_len) {
    native_buf_t pkt;

    nbuf_init(&pkt);
    nbuf_varuint(&pkt, CLIENT_DATA);
    nbuf_cstring(&pkt, "");   /* table name — outside compression */

  #ifdef HAVE_LZ4
    if (self->compress) {
        char *compressed;
        size_t comp_len;
        compressed = ch_lz4_compress(body->data, body->len, &comp_len);
        Safefree(body->data);
        body->data = NULL;
        if (compressed) {
            nbuf_append(&pkt, compressed, comp_len);
            Safefree(compressed);
        } else {
            Safefree(pkt.data);
            *out_len = 0;
            return NULL;
        }
    } else
  #endif
    {
        nbuf_append(&pkt, body->data, body->len);
        Safefree(body->data);
        body->data = NULL;
    }

    nbuf_empty_data_block(&pkt, self->compress);

    *out_len = pkt.len;
    return pkt.data;
}

/* --- Client-side defaults for empty values (empty_as_default/defaults) ---
 *
 * The server sends a TableColumns packet before the INSERT sample block;
 * its description text carries each table column's DEFAULT/MATERIALIZED/
 * ALIAS/EPHEMERAL kind and expression. Resolution runs once per insert at
 * sample-block time and yields one col_default_t per column; the build
 * functions below then only substitute the cell before the existing
 * encoders run.
 */

typedef struct {
    char *name; size_t name_len;
    char kind;  /* 0 none, D/M/A/E */
    char *expr; size_t expr_len;
} tc_col_t;

struct tc_cols_s {
    tc_col_t *cols;
    int ncols;
    int bad;    /* the description did not parse completely */
};

/* One column's resolved default for a pending insert. */
typedef struct {
    int subst;          /* substitute empty cells in this column */
    int nullable;       /* column top is Nullable (or LC(Nullable)) */
    int to_null;        /* substitution value is NULL */
    SV *subst_sv;       /* arrayref-path value, owned */
    char *subst_text;   /* string-path cell, owned */
    size_t subst_text_len;
    char *err;          /* why an empty value here cannot be filled, owned */
} col_default_t;

/* ClickHouse string unescape shared by the wire and literal levels:
 * \n \t \r \b \f \v \a \0 \e \xHH, anything else \X to X. */
static int hex_val(char c) {
    if (c >= '0' && c <= '9') return c - '0';
    if (c >= 'a' && c <= 'f') return c - 'a' + 10;
    if (c >= 'A' && c <= 'F') return c - 'A' + 10;
    return -1;
}

static size_t ch_unescape(const char *src, size_t len, char *dst) {
    size_t i = 0, j = 0;
    int hi, lo;
    while (i < len) {
        if (src[i] == '\\' && i + 1 < len) {
            char c = src[i + 1];
            size_t adv = 2;
            switch (c) {
            case 'n': c = '\n'; break;
            case 't': c = '\t'; break;
            case 'r': c = '\r'; break;
            case 'b': c = '\b'; break;
            case 'f': c = '\f'; break;
            case 'v': c = '\v'; break;
            case 'a': c = '\a'; break;
            case '0': c = '\0'; break;
            case 'e': c = '\x1b'; break;
            case 'x':
                hi = (i + 2 < len) ? hex_val(src[i + 2]) : -1;
                lo = (i + 3 < len) ? hex_val(src[i + 3]) : -1;
                if (hi >= 0 && lo >= 0) {
                    c = (char)((hi << 4) | lo);
                    adv = 4;
                }
                break;
            default: break;
            }
            dst[j++] = c;
            i += adv;
        } else {
            dst[j++] = src[i++];
        }
    }
    return j;
}

static void free_insert_tc(ev_clickhouse_t *self) {
    if (self->insert_tc) {
        int i;
        for (i = 0; i < self->insert_tc->ncols; i++) {
            Safefree(self->insert_tc->cols[i].name);
            Safefree(self->insert_tc->cols[i].expr);
        }
        Safefree(self->insert_tc->cols);
        Safefree(self->insert_tc);
        self->insert_tc = NULL;
    }
}

static void free_insert_default_state(ev_clickhouse_t *self) {
    self->insert_empty_as_default = 0;
    CLEAR_SV(self->insert_defaults);
    free_insert_tc(self);
}

static void free_col_defaults(col_default_t *cdefs, int ncols) {
    int i;
    if (!cdefs) return;
    for (i = 0; i < ncols; i++) {
        if (cdefs[i].subst_sv) SvREFCNT_dec(cdefs[i].subst_sv);
        Safefree(cdefs[i].subst_text);
        Safefree(cdefs[i].err);
    }
    Safefree(cdefs);
}

/* Split one description line into tab fields; returns field count. */
static int split_tabs(const char *line, size_t len,
                      const char **f, size_t *fl, int maxf) {
    int n = 0;
    size_t start = 0, i;
    for (i = 0; i <= len && n < maxf; i++) {
        if (i == len || line[i] == '\t') {
            f[n] = line + start;
            fl[n] = i - start;
            n++;
            start = i + 1;
        }
    }
    return n;
}

/* Parse the TableColumns description text: a header line, the count
 * line, then one line per column. Anything short of that marks it bad,
 * so no column silently falls back to its type's zero. */
static tc_cols_t *parse_table_columns_desc(const char *s, size_t len) {
    tc_cols_t *tc;
    const char *p = s, *end = s + len, *nl, *q;
    const char *f[8];
    size_t fl[8];
    int nf, n = 0, i;
    Newxz(tc, 1, tc_cols_t);
    tc->bad = 1;
    nl = memchr(p, '\n', (size_t)(end - p));
    if (!nl) return tc;
    p = nl + 1;
    nl = memchr(p, '\n', (size_t)(end - p));
    if (!nl) return tc;
    for (q = p; q < nl && *q >= '0' && *q <= '9'; q++) {
        if (n > 100000) return tc;
        n = n * 10 + (*q - '0');
    }
    /* "N columns:" */
    if (q == p || (q < nl && *q != ' ') || n > 100000) return tc;
    p = nl + 1;
    if (n > 0) Newxz(tc->cols, n, tc_col_t);
    tc->ncols = n;
    for (i = 0; i < n; i++) {
        const char *le;
        size_t j, k;
        char *un;
        if (p >= end) return tc;
        nl = memchr(p, '\n', (size_t)(end - p));
        le = nl ? nl : end;
        nf = split_tabs(p, (size_t)(le - p), f, fl, 8);
        if (nf < 1 || fl[0] < 3 || f[0][0] != '`') return tc;
        j = 1;
        while (j < fl[0]) {
            if (f[0][j] == '\\' && j + 1 < fl[0]) { j += 2; continue; }
            if (f[0][j] == '`') break;
            j++;
        }
        if (j >= fl[0] || j + 1 >= fl[0] || f[0][j + 1] != ' ') return tc;
        Newx(un, j, char);
        k = ch_unescape(f[0] + 1, j - 1, un);
        tc->cols[i].name = un;
        tc->cols[i].name_len = k;
        if (nf > 1) {
            if (fl[1] == 7 && memcmp(f[1], "DEFAULT", 7) == 0)
                tc->cols[i].kind = 'D';
            else if (fl[1] == 12 && memcmp(f[1], "MATERIALIZED", 12) == 0)
                tc->cols[i].kind = 'M';
            else if (fl[1] == 5 && memcmp(f[1], "ALIAS", 5) == 0)
                tc->cols[i].kind = 'A';
            else if (fl[1] == 9 && memcmp(f[1], "EPHEMERAL", 9) == 0)
                tc->cols[i].kind = 'E';
            if (tc->cols[i].kind) {
                if (nf < 3) return tc;
                Newx(un, fl[2] + 1, char);
                k = ch_unescape(f[2], fl[2], un);
                tc->cols[i].expr = un;
                tc->cols[i].expr_len = k;
            }
        }
        p = le + 1;
    }
    tc->bad = 0;
    return tc;
}

static const tc_col_t *find_tc_col(const tc_cols_t *tc,
                                   const char *name, size_t len) {
    int i;
    if (!tc) return NULL;
    for (i = 0; i < tc->ncols; i++) {
        if (tc->cols[i].name && tc->cols[i].name_len == len
            && memcmp(tc->cols[i].name, name, len) == 0)
            return &tc->cols[i];
    }
    return NULL;
}

/* Constant DEFAULT literals: number, string, NULL, true/false,
 * array/tuple of literals. Anything else is not a literal. */
enum { L_NUM, L_STR, L_NULL, L_BOOL, L_ARR, L_TUP };

typedef struct lit_s lit_t;
struct lit_s {
    int kind;
    const char *ptr; size_t len;
    char *str; size_t str_len;
    int boolean;
    lit_t **items; size_t nitems; size_t nicap;
    col_type_t *cast;     /* CAST / :: target type, NULL when none */
};

static void free_lit(lit_t *l) {
    if (!l) return;
    if (l->cast) free_col_type(l->cast);
    if (l->kind == L_STR) Safefree(l->str);
    if (l->items) {
        size_t i;
        for (i = 0; i < l->nitems; i++) free_lit(l->items[i]);
        Safefree(l->items);
    }
    Safefree(l);
}

static const char *skip_ws(const char *p, const char *end) {
    while (p < end && (*p == ' ' || *p == '\t' || *p == '\n'
                       || *p == '\r' || *p == '\f' || *p == '\v'))
        p++;
    return p;
}

static int is_wordchar(char c) {
    return (c >= 'A' && c <= 'Z') || (c >= 'a' && c <= 'z')
        || (c >= '0' && c <= '9') || c == '_';
}

static lit_t *parse_lit(const char **pp, const char *end, int depth);

static int lit_push(lit_t *l, lit_t *item) {
    if (l->nitems == l->nicap) {
        size_t ncap = l->nicap ? l->nicap * 2 : 4;
        if (ncap > 100000) return 0;
        Renew(l->items, ncap, lit_t *);
        l->nicap = ncap;
    }
    l->items[l->nitems++] = item;
    return 1;
}

/* Past a type name ("Decimal(9, 2)", "DateTime('UTC')"), else NULL. */
static const char *skip_type_name(const char *p, const char *end) {
    int depth = 0;
    if (p >= end || !((*p >= 'A' && *p <= 'Z') || (*p >= 'a' && *p <= 'z')
                      || *p == '_'))
        return NULL;
    while (p < end && is_wordchar(*p)) p++;
    p = skip_ws(p, end);
    if (p >= end || *p != '(') return p;
    for (; p < end; p++) {
        if (*p == '\'') {
            for (p++; p < end && *p != '\''; p++)
                if (*p == '\\') p++;
            if (p >= end) return NULL;
        } else if (*p == '(') {
            depth++;
        } else if (*p == ')' && --depth == 0) {
            return p + 1;
        }
    }
    return NULL;
}

static lit_t *parse_lit_atom(const char **pp, const char *end, int depth);

/* Record a cast on l; 0 when l already carries a different cast type
 * (a cast of a cast is not a client-side literal). */
static int lit_set_cast(lit_t *l, const char *type, size_t len) {
    col_type_t *t = parse_col_type(type, len);
    if (l->cast) {
        int same = col_type_same(l->cast, t);
        free_col_type(t);
        return same;
    }
    l->cast = t;
    return 1;
}

/* A literal, also in the constant forms ALTER writes: CAST(lit, 'Type'),
 * CAST(lit AS Type), lit::Type. The cast type is kept: the literal only
 * stands for the default when it matches the column (lit_casts_ok). */
static lit_t *parse_lit(const char **pp, const char *end, int depth) {
    const char *p = skip_ws(*pp, end);
    lit_t *l;
    if (p >= end || depth > 64) return NULL;
    {
        size_t kw = end - p > 5 && strncmp(p, "_CAST", 5) == 0 ? 5
                  : end - p > 4 && strncasecmp(p, "CAST", 4) == 0 ? 4 : 0;
        const char *q = kw && !is_wordchar(p[kw]) ? skip_ws(p + kw, end) : end;
        if (q < end && *q == '(') {
            q++;
            l = parse_lit(&q, end, depth + 1);
            if (!l) return NULL;
            q = skip_ws(q, end);
            if (q < end && *q == ',') {
                lit_t *t;
                int ok;
                q++;
                t = parse_lit(&q, end, depth + 1);
                if (!t || t->kind != L_STR || t->cast) { free_lit(t); free_lit(l); return NULL; }
                ok = lit_set_cast(l, t->str, t->str_len);
                free_lit(t);
                if (!ok) { free_lit(l); return NULL; }
            } else if (end - q > 2 && strncasecmp(q, "AS", 2) == 0
                       && !is_wordchar(q[2])) {
                const char *ts = skip_ws(q + 2, end);
                q = skip_type_name(ts, end);
                if (!q || !lit_set_cast(l, ts, (size_t)(q - ts))) {
                    free_lit(l);
                    return NULL;
                }
            } else {
                free_lit(l);
                return NULL;
            }
            q = skip_ws(q, end);
            if (q >= end || *q != ')') { free_lit(l); return NULL; }
            p = q + 1;
            goto suffix;
        }
    }
    l = parse_lit_atom(&p, end, depth);
    if (!l) return NULL;
suffix:
    for (;;) {
        const char *ts, *q = skip_ws(p, end);
        if (end - q < 2 || q[0] != ':' || q[1] != ':') break;
        ts = skip_ws(q + 2, end);
        q = skip_type_name(ts, end);
        if (!q || !lit_set_cast(l, ts, (size_t)(q - ts))) {
            free_lit(l);
            return NULL;
        }
        p = q;
    }
    *pp = p;
    return l;
}

static lit_t *parse_lit_atom(const char **pp, const char *end, int depth) {
    const char *p = skip_ws(*pp, end);
    lit_t *l;
    if (p >= end || depth > 64) return NULL;
    if (*p == '\'') {
        size_t cap = (size_t)(end - p), k = 0;
        char *buf;
        Newx(buf, cap ? cap : 1, char);
        p++;
        for (;;) {
            if (p >= end) { Safefree(buf); return NULL; }
            if (*p == '\'') {
                if (p + 1 < end && p[1] == '\'') {
                    buf[k++] = '\'';
                    p += 2;
                    continue;
                }
                p++;
                break;
            }
            if (*p == '\\' && p + 1 < end) {
                char c = p[1];
                size_t adv = 2;
                int hi, lo;
                switch (c) {
                case 'n': c = '\n'; break;
                case 't': c = '\t'; break;
                case 'r': c = '\r'; break;
                case 'b': c = '\b'; break;
                case 'f': c = '\f'; break;
                case 'v': c = '\v'; break;
                case 'a': c = '\a'; break;
                case '0': c = '\0'; break;
                case 'e': c = '\x1b'; break;
                case 'x':
                    hi = (p + 2 < end) ? hex_val(p[2]) : -1;
                    lo = (p + 3 < end) ? hex_val(p[3]) : -1;
                    if (hi >= 0 && lo >= 0) {
                        c = (char)((hi << 4) | lo);
                        adv = 4;
                    }
                    break;
                default: break;
                }
                buf[k++] = c;
                p += adv;
                continue;
            }
            buf[k++] = *p++;
        }
        Newxz(l, 1, lit_t);
        l->kind = L_STR;
        l->str = buf;
        l->str_len = k;
        *pp = p;
        return l;
    }
    if (*p == '[' || *p == '(') {
        char open = *p, close = (open == '[') ? ']' : ')';
        int is_tup = (open == '(');
        lit_t *first = NULL;
        p++;
        Newxz(l, 1, lit_t);
        l->kind = is_tup ? L_TUP : L_ARR;
        p = skip_ws(p, end);
        if (p < end && *p == close) {
            p++;
            *pp = p;
            return l;
        }
        first = parse_lit(&p, end, depth + 1);
        if (!first) { free_lit(l); return NULL; }
        p = skip_ws(p, end);
        if (is_tup && p < end && *p == ')') {
            p++;
            free_lit(l);
            *pp = p;
            return first;
        }
        if (p >= end || *p != ',') {
            free_lit(first);
            free_lit(l);
            return NULL;
        }
        if (!lit_push(l, first)) {
            free_lit(first);
            free_lit(l);
            return NULL;
        }
        for (;;) {
            lit_t *item;
            p++;
            item = parse_lit(&p, end, depth + 1);
            if (!item) { free_lit(l); return NULL; }
            if (!lit_push(l, item)) {
                free_lit(item);
                free_lit(l);
                return NULL;
            }
            p = skip_ws(p, end);
            if (p < end && *p == ',') continue;
            if (p < end && *p == close) { p++; break; }
            free_lit(l);
            return NULL;
        }
        *pp = p;
        return l;
    }
    if ((*p >= '0' && *p <= '9') || *p == '.' || *p == '+' || *p == '-') {
        const char *start = p;
        int seendigit = 0;
        if (*p == '+' || *p == '-') p++;
        if (p + 1 < end && p[0] == '0' && (p[1] == 'x' || p[1] == 'X')) {
            p += 2;
            while (p < end && hex_val(*p) >= 0) { p++; seendigit = 1; }
            if (!seendigit) return NULL;
        } else {
            while (p < end && *p >= '0' && *p <= '9') { p++; seendigit = 1; }
            if (p < end && *p == '.') {
                p++;
                while (p < end && *p >= '0' && *p <= '9') {
                    p++;
                    seendigit = 1;
                }
            }
            if (p < end && (*p == 'e' || *p == 'E')) {
                const char *e = p + 1;
                if (e < end && (*e == '+' || *e == '-')) e++;
                if (e < end && *e >= '0' && *e <= '9') {
                    p = e + 1;
                    while (p < end && *p >= '0' && *p <= '9') p++;
                }
            }
            if (!seendigit) return NULL;
        }
        Newxz(l, 1, lit_t);
        l->kind = L_NUM;
        l->ptr = start;
        l->len = (size_t)(p - start);
        *pp = p;
        return l;
    }
    if ((*p >= 'A' && *p <= 'Z') || (*p >= 'a' && *p <= 'z') || *p == '_') {
        const char *w = p;
        size_t wl;
        while (p < end && is_wordchar(*p)) p++;
        wl = (size_t)(p - w);
        Newxz(l, 1, lit_t);
        if ((wl == 4 && strncasecmp(w, "NULL", 4) == 0)) {
            l->kind = L_NULL;
        } else if (wl == 4 && strncasecmp(w, "TRUE", 4) == 0) {
            l->kind = L_BOOL;
            l->boolean = 1;
        } else if (wl == 5 && strncasecmp(w, "FALSE", 5) == 0) {
            l->kind = L_BOOL;
            l->boolean = 0;
        } else {
            Safefree(l);
            return NULL;
        }
        *pp = p;
        return l;
    }
    return NULL;
}

static const col_type_t *strip_lc(const col_type_t *t) {
    while (t && t->code == CT_LOWCARDINALITY) t = t->inner;
    return t;
}

/* A CAST to the column's own type (LowCardinality aside, Nullable on the
 * column side allowed) leaves the value to the column's encoder; any other
 * target type converts on the server in ways the client does not mimic. */
static int cast_matches(const col_type_t *cast, const col_type_t *col) {
    cast = strip_lc(cast);
    col = strip_lc(col);
    if (col_type_same(cast, col)) return 1;
    return col && col->code == CT_NULLABLE
        && col_type_same(cast, strip_lc(col->inner));
}

/* 1 when every cast in the literal targets the type at its position in
 * the column type. */
static int lit_casts_ok(const lit_t *l, const col_type_t *ct) {
    const col_type_t *t = strip_lc(ct);
    size_t i;
    if (l->cast && !cast_matches(l->cast, ct)) return 0;
    if (t && t->code == CT_NULLABLE) t = strip_lc(t->inner);
    for (i = 0; i < l->nitems; i++) {
        const col_type_t *et = NULL;
        if (l->kind == L_ARR && t && t->code == CT_ARRAY)
            et = t->inner;
        else if (l->kind == L_TUP && t && t->code == CT_TUPLE
                 && i < (size_t)t->num_inners)
            et = t->inners[i];
        if (!lit_casts_ok(l->items[i], et)) return 0;
    }
    return 1;
}

/* A whole expression is a literal only if one value spans it. */
static lit_t *parse_default_literal(const char *s, size_t len) {
    const char *p = s, *end = s + len;
    lit_t *l = parse_lit(&p, end, 0);
    if (!l) return NULL;
    p = skip_ws(p, end);
    if (p != end) { free_lit(l); return NULL; }
    return l;
}

/* Verbatim number text, hex normalized to decimal; NULL when the hex
 * value does not fit 64 bits. Caller frees. */
static char *num_normalize(const char *p, size_t len, size_t *out_len) {
    const char *q = p;
    size_t qlen = len;
    char *out;
    int neg = 0;
    if (qlen > 0 && (*q == '+' || *q == '-')) {
        neg = (*q == '-');
        q++;
        qlen--;
    }
    if (qlen > 2 && q[0] == '0' && (q[1] == 'x' || q[1] == 'X')) {
        unsigned long long v = 0;
        size_t i;
        for (i = 2; i < qlen; i++) {
            int d = hex_val(q[i]);
            if (d < 0) break;
            if (v > (ULLONG_MAX >> 4)) return NULL;
            v = v * 16 + (unsigned)d;
        }
        Newx(out, 32, char);
        if (neg)
            *out_len = (size_t)snprintf(out, 32, "-%llu", v);
        else
            *out_len = (size_t)snprintf(out, 32, "%llu", v);
        return out;
    }
    Newx(out, len + 1, char);
    Copy(p, out, len, char);
    out[len] = '\0';
    *out_len = len;
    return out;
}

static int nullable_top(col_type_t *ct) {
    if (!ct) return 0;
    if (ct->code == CT_NULLABLE) return 1;
    if (ct->code == CT_LOWCARDINALITY && ct->inner
        && ct->inner->code == CT_NULLABLE)
        return 1;
    return 0;
}

/* Arrayref-path conversion of a literal. Returns an owned SV, or NULL
 * for exotic nests the client cannot express. */
static SV *lit_to_sv(pTHX_ lit_t *l) {
    size_t i;
    AV *av;
    SV *sv;
    char *norm;
    size_t nlen;
    switch (l->kind) {
    case L_NUM:
        norm = num_normalize(l->ptr, l->len, &nlen);
        if (!norm) return NULL;
        sv = newSVpvn(norm, nlen);
        Safefree(norm);
        return sv;
    case L_STR:
        return newSVpvn(l->str, l->str_len);
    case L_NULL:
        return newSV(0);
    case L_BOOL:
        return newSViv(l->boolean);
    case L_ARR:
    case L_TUP:
        av = newAV();
        for (i = 0; i < l->nitems; i++) {
            SV *e = lit_to_sv(aTHX_ l->items[i]);
            if (!e) {
                SvREFCNT_dec((SV *)av);
                return NULL;
            }
            av_store(av, (SSize_t)i, e);
        }
        return newRV_noinc((SV *)av);
    }
    return NULL;
}

/* String-path conversion: appends the TSV cell. 0 when the value has
 * no text form (nested types need binary encoding). */
static int lit_to_text(lit_t *l, native_buf_t *b) {
    char *norm;
    size_t nlen;
    switch (l->kind) {
    case L_NUM:
        norm = num_normalize(l->ptr, l->len, &nlen);
        if (!norm) return 0;
        nbuf_append(b, norm, nlen);
        Safefree(norm);
        return 1;
    case L_STR:
        tsv_escape(b, l->str, l->str_len);
        return 1;
    case L_NULL:
        nbuf_append(b, "\\N", 2);
        return 1;
    case L_BOOL:
        nbuf_append(b, l->boolean ? "1" : "0", 1);
        return 1;
    default:
        return 0;
    }
}

/* Zero value for a column with no DEFAULT. Returns an owned SV, sets
 * *impossible when the type has no client-side zero. to_null handled
 * by the caller. */
static SV *zero_sv_for(pTHX_ col_type_t *ct, int *impossible) {
    size_t i;
    AV *av;
    SV *sv;
    *impossible = 0;
    switch (ct->code) {
    case CT_ARRAY:
        return newRV_noinc((SV *)newAV());
    case CT_MAP:
        return newRV_noinc((SV *)newHV());
    case CT_TUPLE:
        av = newAV();
        for (i = 0; i < (size_t)ct->num_inners; i++) {
            col_type_t *in = ct->inners[i];
            if (!in) {
                SvREFCNT_dec((SV *)av);
                *impossible = 1;
                return NULL;
            }
            if (in->code == CT_NULLABLE
                || (in->code == CT_LOWCARDINALITY && in->inner
                    && in->inner->code == CT_NULLABLE)) {
                av_store(av, (SSize_t)i, newSV(0));
                continue;
            }
            sv = zero_sv_for(aTHX_ in, impossible);
            if (!sv || *impossible) {
                if (sv) SvREFCNT_dec(sv);
                SvREFCNT_dec((SV *)av);
                *impossible = 1;
                return NULL;
            }
            av_store(av, (SSize_t)i, sv);
        }
        return newRV_noinc((SV *)av);
    case CT_LOWCARDINALITY:
        if (!ct->inner) { *impossible = 1; return NULL; }
        return zero_sv_for(aTHX_ ct->inner, impossible);
    case CT_JSON:
        return newRV_noinc((SV *)newHV());
    default:
        if (ct->code == CT_UNKNOWN || ct->code == CT_NOTHING
            || ct->code == CT_VARIANT || ct->code == CT_DYNAMIC
            || ct->code == CT_INT128 || ct->code == CT_UINT128
            || ct->code == CT_INT256 || ct->code == CT_UINT256) {
            *impossible = 1;
            return NULL;
        }
        return nullable_inner_zero_sv(aTHX_ ct);
    }
}

/* Zero value as a string-path cell. 1 with *out malloc'd, 0 when the
 * type has no text form. to_null handled by the caller. */
static int zero_text_for(col_type_t *ct, char **out, size_t *out_len) {
    const char *p;
    size_t len;
    *out = NULL;
    *out_len = 0;
    switch (ct->code) {
    case CT_ARRAY:
    case CT_MAP:
    case CT_TUPLE:
        return 0;
    case CT_LOWCARDINALITY:
        if (!ct->inner) return 0;
        return zero_text_for(ct->inner, out, out_len);
    case CT_JSON:
    case CT_UNKNOWN:
    case CT_NOTHING:
    case CT_VARIANT:
    case CT_DYNAMIC:
    case CT_INT128:
    case CT_UINT128:
    case CT_INT256:
    case CT_UINT256:
        return 0;
    default:
        nullable_inner_zero(ct, &p, &len);
        Newx(*out, len + 1, char);
        Copy(p, *out, len, char);
        (*out)[len] = '\0';
        *out_len = len;
        return 1;
    }
}

/* Resolve one column's default from a caller value. */
static void resolve_from_sv(col_default_t *cd, SV *v) {
    if (!SvOK(v)) {
        cd->to_null = 1;
        return;
    }
    if (SvROK(v)) {
        cd->subst_sv = SvREFCNT_inc(v);
        return;
    }
    cd->subst_sv = SvREFCNT_inc(v);
    {
        STRLEN l;
        const char *s = SvPV(cd->subst_sv, l);
        native_buf_t b;
        nbuf_init(&b);
        tsv_escape(&b, s, l);
        cd->subst_text = b.data;
        cd->subst_text_len = b.len;
    }
}

/* Resolve one column from a DEFAULT literal. 1 ok, 0 failure. */
static int resolve_from_lit(pTHX_ col_default_t *cd, lit_t *l) {
    native_buf_t b;
    if (l->kind == L_NULL) {
        cd->to_null = 1;
        return 1;
    }
    cd->subst_sv = lit_to_sv(aTHX_ l);
    if (!cd->subst_sv) return 0;
    nbuf_init(&b);
    if (lit_to_text(l, &b)) {
        cd->subst_text = b.data;
        cd->subst_text_len = b.len;
    } else {
        Safefree(b.data);
    }
    return 1;
}

/* Message helpers: short errors naming the column and the fix. */
static void resolve_err_trunc(const char *src, size_t len,
                              char *dst, size_t dstsz) {
    size_t n = len < dstsz - 1 ? len : dstsz - 1;
    size_t i;
    for (i = 0; i < n; i++)
        dst[i] = (src[i] == '\n' || src[i] == '\r') ? ' ' : src[i];
    dst[n] = '\0';
}

/* Resolve every column's default once per insert. NULL on failure
 * with the reason in errbuf. */
static col_default_t *resolve_insert_defaults(pTHX_ ev_clickhouse_t *self,
    const char **cnames, size_t *cname_lens, col_type_t **ctypes,
    const char **ctypes_str, size_t *ctype_lens, int num_cols,
    char *errbuf, size_t errbuf_sz) {
    col_default_t *cdefs;
    int i;
    Newxz(cdefs, num_cols, col_default_t);
    for (i = 0; i < num_cols; i++) {
        col_default_t *cd = &cdefs[i];
        SV **dp = NULL;
        const tc_col_t *tc;
        lit_t *lit;
        char expr_tr[72];
        if (self->insert_defaults) {
            dp = hv_fetch(self->insert_defaults, cnames[i],
                          (I32)cname_lens[i], 0);
        }
        if (dp && *dp) {
            cd->subst = 1;
            cd->nullable = nullable_top(ctypes[i]);
            resolve_from_sv(cd, *dp);
            continue;
        }
        if (!self->insert_empty_as_default) continue;
        cd->subst = 1;
        cd->nullable = nullable_top(ctypes[i]);
        if (!self->insert_tc) {
            snprintf(errbuf, errbuf_sz, "server did not send column "
                     "defaults for this insert: use data_format => "
                     "'Native' for server-side defaults");
            goto col_fail;
        }
        if (self->insert_tc->bad) {
            snprintf(errbuf, errbuf_sz, "cannot parse the server's column "
                     "description: use data_format => 'Native' for "
                     "server-side defaults");
            goto col_fail;
        }
        tc = find_tc_col(self->insert_tc, cnames[i], cname_lens[i]);
        if (!tc || !tc->kind) {
            int imp = 0;
            char *t = NULL;
            size_t tl = 0;
            if (cd->nullable) {
                cd->to_null = 1;
                continue;
            }
            cd->subst_sv = zero_sv_for(aTHX_ ctypes[i], &imp);
            if (!cd->subst_sv || imp) {
                if (cd->subst_sv) SvREFCNT_dec(cd->subst_sv);
                cd->subst_sv = NULL;
                goto no_client_default;
            }
            if (zero_text_for(ctypes[i], &t, &tl)) {
                cd->subst_text = t;
                cd->subst_text_len = tl;
            }
            continue;
        }
        if (tc->kind != 'D') {
            const char *kw = (tc->kind == 'M') ? "MATERIALIZED"
                           : (tc->kind == 'A') ? "ALIAS" : "EPHEMERAL";
            if (tc->expr && tc->expr_len) {
                resolve_err_trunc(tc->expr, tc->expr_len, expr_tr,
                                  sizeof(expr_tr));
                snprintf(errbuf, errbuf_sz, "%s '%s': use data_format => "
                         "'Native' for server-side defaults", kw, expr_tr);
            } else {
                snprintf(errbuf, errbuf_sz, "%s column: use data_format => "
                         "'Native' for server-side defaults", kw);
            }
            goto col_fail;
        }
        lit = parse_default_literal(tc->expr ? tc->expr : "",
                                    tc->expr ? tc->expr_len : 0);
        if (lit && !lit_casts_ok(lit, ctypes[i])) {
            free_lit(lit);
            lit = NULL;
        }
        if (!lit) {
            if (tc->expr && tc->expr_len)
                resolve_err_trunc(tc->expr, tc->expr_len, expr_tr,
                                  sizeof(expr_tr));
            else
                expr_tr[0] = '\0';
            snprintf(errbuf, errbuf_sz, "non-literal DEFAULT '%s': use "
                     "data_format => 'Native' for server-side defaults",
                     expr_tr);
            goto col_fail;
        }
        if (!resolve_from_lit(aTHX_ cd, lit)) {
            free_lit(lit);
            goto no_client_default;
        }
        free_lit(lit);
        continue;
    no_client_default:
        snprintf(errbuf, errbuf_sz, "no client-side default for empty "
                 "values: use data_format => 'Native'");
    col_fail:
        /* Fails the insert only when a value needs the substitution. */
        {
            size_t n = strlen(errbuf);
            Newx(cd->err, n + 1, char);
            Copy(errbuf, cd->err, n + 1, char);
            errbuf[0] = '\0';
        }
    }
    if (self->insert_defaults) {
        HE *he;
        hv_iterinit(self->insert_defaults);
        while ((he = hv_iternext(self->insert_defaults))) {
            I32 klen;
            char *key = hv_iterkey(he, &klen);
            int j, found = 0;
            for (j = 0; j < num_cols; j++) {
                if (cname_lens[j] == (size_t)klen
                    && memcmp(cnames[j], key, (size_t)klen) == 0) {
                    found = 1;
                    break;
                }
            }
            if (!found) {
                char k_tr[64];
                resolve_err_trunc(key, (size_t)klen, k_tr,
                                  sizeof(k_tr));
                snprintf(errbuf, errbuf_sz, "defaults key '%s' matches "
                         "no insert column", k_tr);
                goto fail;
            }
        }
    }
    return cdefs;
fail:
    free_col_defaults(cdefs, num_cols);
    return NULL;
}

/* --- Insert encoding error context --- */

/* The column and rows of the encode call in progress, so a failure or an
 * exception can be traced back to its row. */
typedef struct {
    int col;          /* -1 outside a column */
    SSize_t r0, n;
} enc_progress_t;

#define ERR_VALUE_MAX 40
#define ERR_NAME_MAX  60

static void err_quote(native_buf_t *b, const char *s, size_t len) {
    size_t i, n = len > ERR_VALUE_MAX ? ERR_VALUE_MAX : len;
    nbuf_u8(b, '\'');
    for (i = 0; i < n; i++) {
        unsigned char c = (unsigned char)s[i];
        char esc[8];
        switch (c) {
        case '\'': nbuf_append(b, "\\'", 2); break;
        case '\\': nbuf_append(b, "\\\\", 2); break;
        case '\n': nbuf_append(b, "\\n", 2); break;
        case '\t': nbuf_append(b, "\\t", 2); break;
        case '\r': nbuf_append(b, "\\r", 2); break;
        default:
            if (c < 0x20 || c > 0x7e) {
                snprintf(esc, sizeof(esc), "\\x%02x", c);
                nbuf_append(b, esc, 4);
            } else {
                nbuf_u8(b, c);
            }
        }
    }
    nbuf_u8(b, '\'');
    if (n < len) nbuf_append(b, "...", 3);
}

static void err_append(native_buf_t *b, const char *s) {
    nbuf_append(b, s, strlen(s));
}

static void err_zone(native_buf_t *b, const char *tz) {
    err_append(b, ": unknown timezone '");
    nbuf_append(b, tz, strlen(tz) > 60 ? 60 : strlen(tz));
    err_append(b, "' or missing timezone database");
}

/* A value as error text, without running overloads: undef, the type of a
 * reference, else the quoted (escaped, truncated) string. */
static void err_value_sv(pTHX_ native_buf_t *b, SV *v) {
    if (SvROK(v)) {
        SV *rv = SvRV(v);
        err_append(b, sv_reftype(rv, SvOBJECT(rv)));
        err_append(b, SvOBJECT(rv) ? " object" : " reference");
    } else if (!SvOK(v)) {
        err_append(b, "undef");
    } else {
        STRLEN l;
        const char *s = SvPV_nomg(v, l);
        err_quote(b, s, l);
    }
}

static void err_name(native_buf_t *b, const char *s, size_t len) {
    nbuf_append(b, s, len > ERR_NAME_MAX ? ERR_NAME_MAX : len);
    if (len > ERR_NAME_MAX) err_append(b, "...");
}

/* "column 'name' (type)" */
static void err_where(char *dst, size_t sz, const char *name, size_t name_len,
                      const char *type, size_t type_len) {
    native_buf_t b;
    nbuf_init(&b);
    err_append(&b, "column '");
    err_name(&b, name, name_len);
    err_append(&b, "' (");
    err_name(&b, type, type_len);
    err_append(&b, ")");
    snprintf(dst, sz, "%.*s", (int)b.len, b.data);
    Safefree(b.data);
}

static void err_finish(char *errbuf, size_t sz, native_buf_t *msg) {
    snprintf(errbuf, sz, "%.*s", (int)msg->len, msg->data);
    Safefree(msg->data);
}

/* Exception text on one line, the die location kept. */
static void err_exception(pTHX_ native_buf_t *b, SV *err) {
    STRLEN l, i;
    const char *s;
    if (!err) { err_append(b, "died"); return; }
    if (SvROK(err)) {
        err_append(b, "died with ");
        err_value_sv(aTHX_ b, err);
        return;
    }
    s = SvPV_nomg(err, l);
    while (l && (s[l - 1] == '\n' || s[l - 1] == '\r')) l--;
    if (l > 160) l = 160;
    for (i = 0; i < l; i++)
        nbuf_u8(b, (s[i] == '\n' || s[i] == '\r') ? ' ' : s[i]);
}

static int sv_encodes(pTHX_ SV *v, col_type_t *ct, native_buf_t *scratch) {
    scratch->len = 0;
    return encode_column_sv(aTHX_ scratch, &v, 1, ct);
}

/* Inside a top-level value that does not encode, the innermost element
 * that does not encode on its own (the value itself when none). */
static SV *locate_bad_sv(pTHX_ SV *v, col_type_t *ct, native_buf_t *scratch) {
    SSize_t j, n;
    switch (ct->code) {
    case CT_NULLABLE:
    case CT_LOWCARDINALITY:
        return SvOK(v) && ct->inner ? locate_bad_sv(aTHX_ v, ct->inner, scratch) : v;
    case CT_ARRAY:
    case CT_TUPLE:
        if (!SvROK(v) || SvTYPE(SvRV(v)) != SVt_PVAV) return v;
        n = ct->code == CT_ARRAY ? av_len((AV *)SvRV(v)) + 1 : ct->num_inners;
        for (j = 0; j < n; j++) {
            col_type_t *et = ct->code == CT_ARRAY ? ct->inner : ct->inners[j];
            SV **e = av_fetch((AV *)SvRV(v), j, 0);
            SV *ev = (e && *e) ? *e : &PL_sv_undef;
            if (et && !sv_encodes(aTHX_ ev, et, scratch))
                return locate_bad_sv(aTHX_ ev, et, scratch);
        }
        return v;
    case CT_MAP: {
        HV *hv;
        HE *he;
        if (!SvROK(v) || SvTYPE(SvRV(v)) != SVt_PVHV || ct->num_inners != 2)
            return v;
        hv = (HV *)SvRV(v);
        hv_iterinit(hv);
        while ((he = hv_iternext(hv))) {
            SV *k = hv_iterkeysv(he);
            SV *val = hv_iterval(hv, he);
            if (!sv_encodes(aTHX_ k, ct->inners[0], scratch))
                return k;
            if (!sv_encodes(aTHX_ val, ct->inners[1], scratch))
                return locate_bad_sv(aTHX_ val, ct->inners[1], scratch);
        }
        return v;
    }
    default:
        return v;
    }
}

/* Why encoding vals[0..n) as ct failed: the type cannot be encoded at
 * all, else the first value that fails on its own (row base + index),
 * with the failing element of a nested value. Re-encodes only on this
 * error path. */
static void describe_sv_failure(pTHX_ char *errbuf, size_t sz,
                                const char *where, col_type_t *ct,
                                SV **vals, SSize_t n, SSize_t base,
                                const char *unit) {
    native_buf_t msg, scratch;
    SSize_t k;
    nbuf_init(&msg);
    nbuf_init(&scratch);
    err_append(&msg, where);
    if (col_type_zone_error(ct)) {
        err_zone(&msg, col_type_zone_error(ct));
    } else if (!encode_column_sv(aTHX_ &scratch, vals, 0, ct)) {
        err_append(&msg, ": unsupported type");
    } else {
        for (k = 0; k < n; k++)
            if (!sv_encodes(aTHX_ vals[k], ct, &scratch)) break;
        if (k < n) {
            char rb[64];
            SV *bad = locate_bad_sv(aTHX_ vals[k], ct, &scratch);
            snprintf(rb, sizeof(rb), ", %s %ld: invalid %s ", unit,
                     (long)(base + k), bad == vals[k] ? "value" : "element");
            err_append(&msg, rb);
            err_value_sv(aTHX_ &msg, bad);
        } else {
            err_append(&msg, ": invalid value");
        }
    }
    Safefree(scratch.data);
    err_finish(errbuf, sz, &msg);
}

/* describe_sv_failure() for the TabSeparated path; rows are lines. */
static void describe_text_failure(char *errbuf, size_t sz, const char *where,
                                  col_type_t *ct, const char **vals,
                                  size_t *lens, SSize_t n) {
    native_buf_t msg, scratch;
    SSize_t k;
    nbuf_init(&msg);
    nbuf_init(&scratch);
    err_append(&msg, where);
    if (col_type_zone_error(ct)) {
        err_zone(&msg, col_type_zone_error(ct));
    } else if (!encode_column_text(&scratch, vals, lens, 0, ct)) {
        err_append(&msg, ": unsupported type");
    } else {
        for (k = 0; k < n; k++) {
            scratch.len = 0;
            if (!encode_column_text(&scratch, &vals[k], &lens[k], 1, ct)) break;
        }
        if (k < n) {
            char rb[48];
            snprintf(rb, sizeof(rb), ", line %ld: invalid value ", (long)(k + 1));
            err_append(&msg, rb);
            err_quote(&msg, vals[k], lens[k]);
        } else {
            err_append(&msg, ": invalid value");
        }
    }
    Safefree(scratch.data);
    err_finish(errbuf, sz, &msg);
}

/* Exceptions from user code (overloads, tied values) during the deferred
 * native encode must not escape the I/O callback: run_guarded() calls a
 * C function inside an eval through a private XSUB. */
typedef struct {
    void (*fn)(pTHX_ void *);
    void *arg;
} ch_guarded_t;

static CV *ch_guard_cv;

XS_INTERNAL(ch_guard_xs) {
    dXSARGS;
    ch_guarded_t *g;
    if (items != 1) croak_xs_usage(cv, "guard");
    g = INT2PTR(ch_guarded_t *, SvIV(ST(0)));
    g->fn(aTHX_ g->arg);
    XSRETURN_EMPTY;
}

/* 1 when fn returned, 0 when it died (exception copied to *err when err
 * is given); $@ is left as it was. */
static int run_guarded(pTHX_ void (*fn)(pTHX_ void *), void *arg, SV **err) {
    dSP;
    ch_guarded_t g;
    int died;
    g.fn = fn;
    g.arg = arg;
    if (err) *err = NULL;
    ENTER; SAVETMPS;
    save_scalar(PL_errgv);
    PUSHMARK(SP);
    mXPUSHi(PTR2IV(&g));
    PUTBACK;
    call_sv((SV *)ch_guard_cv, G_EVAL | G_DISCARD);
    died = SvROK(ERRSV) || SvTRUE(ERRSV);
    if (died && err) *err = newSVsv(ERRSV);
    FREETMPS; LEAVE;
    return !died;
}

typedef struct {
    ev_clickhouse_t *self;
    const char **names; size_t *name_lens;
    col_type_t **types;
    const char **types_str; size_t *type_lens;
    int ncols;
    char *errbuf; size_t errbuf_sz;
    col_default_t *cdefs;
} resolve_args_t;

static void resolve_fn(pTHX_ void *p) {
    resolve_args_t *a = (resolve_args_t *)p;
    a->cdefs = resolve_insert_defaults(aTHX_ a->self, a->names, a->name_lens,
        a->types, a->types_str, a->type_lens, a->ncols, a->errbuf,
        a->errbuf_sz);
}

/* resolve_insert_defaults(): a caller's default value may be an object
 * whose stringification dies. */
static col_default_t *resolve_insert_defaults_guarded(pTHX_ ev_clickhouse_t *self,
    const char **cnames, size_t *cname_lens, col_type_t **ctypes,
    const char **ctypes_str, size_t *ctype_lens, int num_cols,
    char *errbuf, size_t errbuf_sz) {
    resolve_args_t a;
    SV *err = NULL;
    a.self = self; a.names = cnames; a.name_lens = cname_lens;
    a.types = ctypes; a.types_str = ctypes_str; a.type_lens = ctype_lens;
    a.ncols = num_cols; a.errbuf = errbuf; a.errbuf_sz = errbuf_sz;
    a.cdefs = NULL;
    if (!run_guarded(aTHX_ resolve_fn, &a, &err)) {
        native_buf_t msg;
        nbuf_init(&msg);
        err_append(&msg, "defaults: ");
        err_exception(aTHX_ &msg, err);
        if (err) SvREFCNT_dec(err);
        err_finish(errbuf, errbuf_sz, &msg);
        return NULL;
    }
    return a.cdefs;
}

/* Skip one column's data (prefixes already consumed). 1 = ok, 0 = malformed,
 * -1 = a type this walker does not know (caller decodes instead). */
static int skip_column_data(const char *buf, size_t len, size_t *pos,
                            uint64_t nrows, col_type_t *ct) {
    size_t fsz;
    uint64_t i;
    int rc;
    if (!ct) return -1;
    if (*pos > len) return 0;
    fsz = col_type_fixed_size(ct);
    if (fsz) {
        if (nrows > (len - *pos) / fsz) return 0;
        *pos += nrows * fsz;
        return 1;
    }
    switch (ct->code) {
    case CT_STRING:
        for (i = 0; i < nrows; i++)
            if (skip_native_string(buf, len, pos) <= 0) return 0;
        return 1;
    case CT_NOTHING:
        if (nrows > len - *pos) return 0;
        *pos += nrows;
        return 1;
    case CT_NULLABLE:
        if (nrows > len - *pos) return 0;
        *pos += nrows;
        return skip_column_data(buf, len, pos, nrows, ct->inner);
    case CT_ARRAY:
    case CT_MAP: {
        uint64_t total = 0;
        if (nrows > (len - *pos) / 8) return 0;
        if (nrows) memcpy(&total, buf + *pos + (nrows - 1) * 8, 8);
        *pos += nrows * 8;
        if (ct->code == CT_ARRAY)
            return skip_column_data(buf, len, pos, total, ct->inner);
        if (ct->num_inners != 2) return -1;
        if ((rc = skip_column_data(buf, len, pos, total, ct->inners[0])) <= 0)
            return rc;
        return skip_column_data(buf, len, pos, total, ct->inners[1]);
    }
    case CT_TUPLE:
        for (i = 0; i < (uint64_t)ct->num_inners; i++)
            if ((rc = skip_column_data(buf, len, pos, nrows, ct->inners[i])) <= 0)
                return rc;
        return 1;
    case CT_LOWCARDINALITY: {
        uint64_t ser_type, nkeys, nidx;
        size_t idx_size;
        col_type_t *dict_ct;
        if (!nrows) return 1;
        if (!ct->inner || len - *pos < 8) return !ct->inner ? -1 : 0;
        memcpy(&ser_type, buf + *pos, 8);
        *pos += 8;
        /* One keys block follows HasAdditionalKeys and/or NeedUpdateDictionary. */
        if ((ser_type & 0xFF) > 3 || !(ser_type & ((1ULL << 9) | (1ULL << 10))))
            return 0;
        idx_size = (size_t)1 << (ser_type & 0xFF);
        dict_ct = ct->inner->code == CT_NULLABLE ? ct->inner->inner : ct->inner;
        if (len - *pos < 8) return 0;
        memcpy(&nkeys, buf + *pos, 8);
        *pos += 8;
        if ((rc = skip_column_data(buf, len, pos, nkeys, dict_ct)) <= 0) return rc;
        if (len - *pos < 8) return 0;
        memcpy(&nidx, buf + *pos, 8);
        *pos += 8;
        if (nidx != nrows || nidx > (len - *pos) / idx_size) return 0;
        *pos += nidx * idx_size;
        return 1;
    }
    default:
        return -1;
    }
}

/*
 * Turn a Native-format block (as ClickHouse::Encoder or `format Native`
 * writes it) into a protocol Data packet: BlockInfo first, and the
 * custom-serialization byte after each column type. Returns NULL with
 * errbuf set on a malformed block.
 */
/* The server's native reader converts String <-> LowCardinality(String)
 * but turns other mismatches (a NULL for a non-Nullable column) into the
 * type's zero rather than the column DEFAULT: insist on the table's types. */
static int block_type_matches(const char *have, size_t have_len,
                              const char *want, size_t want_len) {
    if (have_len == want_len && memcmp(have, want, have_len) == 0) return 1;
    if (want_len > 16 && memcmp(want, "LowCardinality(", 15) == 0
        && want_len - 16 == have_len && memcmp(want + 15, have, have_len) == 0)
        return 1;
    return 0;
}

static char* build_native_body_packet(ev_clickhouse_t *self, const char *buf,
                                      size_t len, const char **want_names,
                                      size_t *want_name_lens,
                                      const char **want_types,
                                      size_t *want_type_lens, int want_cols,
                                      size_t *out_len, char *errbuf,
                                      size_t errbuf_sz) {
    native_buf_t body;
    uint64_t ncols, nrows, c;
    size_t pos = 0;
    nbuf_init(&body);
    nbuf_block_info(&body);
    if (read_varuint(buf, len, &pos, &ncols) <= 0
        || read_varuint(buf, len, &pos, &nrows) <= 0)
        goto bad;
    if (ncols != (uint64_t)want_cols) {
        snprintf(errbuf, errbuf_sz, "Native block has %llu columns, the insert %d",
                 (unsigned long long)ncols, want_cols);
        goto fail;
    }
    nbuf_varuint(&body, ncols);
    nbuf_varuint(&body, nrows);
    for (c = 0; c < ncols; c++) {
        const char *name, *type;
        size_t name_len, type_len, start;
        col_type_t *ct;
        int rc = 0;
        if (read_native_string_ref(buf, len, &pos, &name, &name_len) <= 0
            || read_native_string_ref(buf, len, &pos, &type, &type_len) <= 0)
            goto bad;
        if (name_len != want_name_lens[c] || memcmp(name, want_names[c], name_len)
            || !block_type_matches(type, type_len, want_types[c], want_type_lens[c])) {
            snprintf(errbuf, errbuf_sz, "Native block column %llu '%.*s' (%.*s) does "
                     "not match the table's '%.*s' (%.*s); send it without data_block",
                     (unsigned long long)c,
                     (int)(name_len > 60 ? 60 : name_len), name,
                     (int)(type_len > 60 ? 60 : type_len), type,
                     (int)(want_name_lens[c] > 60 ? 60 : want_name_lens[c]), want_names[c],
                     (int)(want_type_lens[c] > 60 ? 60 : want_type_lens[c]), want_types[c]);
            goto fail;
        }
        nbuf_string(&body, name, name_len);
        nbuf_string(&body, type, type_len);
        nbuf_u8(&body, 0);
        start = pos;
        ct = parse_col_type(type, type_len);
        if (ct && (!nrows || read_col_prefix(buf, len, &pos, ct) > 0))
            rc = nrows ? skip_column_data(buf, len, &pos, nrows, ct) : 1;
        if (ct && rc < 0) {
            int derr = 0;
            SV **vals;
            pos = start;
            vals = decode_column(buf, len, &pos, nrows, ct, &derr, 0);
            if (vals) {
                uint64_t i;
                for (i = 0; i < nrows; i++) SvREFCNT_dec(vals[i]);
                Safefree(vals);
                rc = 1;
            }
        }
        free_col_type(ct);
        if (rc != 1) {
            snprintf(errbuf, errbuf_sz, "malformed Native data in column '%.*s' (%.*s)",
                     (int)(name_len > 60 ? 60 : name_len), name,
                     (int)(type_len > 60 ? 60 : type_len), type);
            Safefree(body.data);
            *out_len = (size_t)-1;
            return NULL;
        }
        nbuf_append(&body, buf + start, pos - start);
    }
    if (pos != len) goto bad;
    return wrap_data_block(self, &body, out_len);
bad:
    snprintf(errbuf, errbuf_sz, "malformed Native data");
fail:
    Safefree(body.data);
    *out_len = (size_t)-1;
    return NULL;
}

/*
 * Build a native protocol Data block from TabSeparated text data.
 * col_names/col_types_str are string references into the sample block buffer.
 * Returns malloc'd packet data (CLIENT_DATA + block), or NULL on failure.
 */
static char* build_native_insert_data(ev_clickhouse_t *self,
                                       const char *tsv_data, size_t tsv_len,
                                       const char **col_names, size_t *col_name_lens,
                                       const char **col_types_str, size_t *col_type_lens,
                                       col_type_t **col_types,
                                       int num_cols,
                                       col_default_t *cdefs,
                                       size_t *out_len,
                                       char *errbuf, size_t errbuf_sz) {
    /* Parse TSV into rows and fields */
    int nrows = 0, max_rows = 64;
    const char **fields = NULL;  /* flat array: fields[row * num_cols + col] */
    size_t *field_lens = NULL;
    const char *p = tsv_data;
    const char *end = tsv_data + tsv_len;

    Newxz(fields, max_rows * num_cols, const char *);
    Newx(field_lens, max_rows * num_cols, size_t);

    while (p < end) {
        const char *line_end = memchr(p, '\n', end - p);
        const char *line_limit = line_end ? line_end : end;
        int col;

        /* No blank-line skipping: the server keeps a blank line as an
         * (empty-field) row, or errors when columns are missing. */
        /* The server rejects DOS line endings (error 117); match it
         * rather than silently storing the \r. Mid-field \r stays. */
        if (line_limit > p && line_limit[-1] == '\r') {
            Safefree(fields);
            Safefree(field_lens);
            snprintf(errbuf, errbuf_sz, "line %d ends with \\r "
                     "(CRLF line endings are illegal in TabSeparated data)",
                     nrows + 1);
            *out_len = (size_t)-1;
            return NULL;
        }

        if (nrows >= max_rows) {
            if (max_rows > INT_MAX / 2 ||
                (num_cols > 0 && max_rows * 2 > INT_MAX / num_cols)) {
                Safefree(fields);
                Safefree(field_lens);
                *out_len = 0;
                return NULL;
            }
            max_rows *= 2;
            Renew(fields, max_rows * num_cols, const char *);
            Renew(field_lens, max_rows * num_cols, size_t);
        }

        /* split line by tabs */
        {
            const char *fp = p;
            for (col = 0; col < num_cols; col++) {
                const char *tab;
                if (fp > line_limit) fp = line_limit;
                if (col < num_cols - 1) {
                    tab = memchr(fp, '\t', line_limit - fp);
                    if (!tab) tab = line_limit;
                } else {
                    tab = line_limit;
                }
                fields[nrows * num_cols + col] = fp;
                field_lens[nrows * num_cols + col] = tab - fp;
                fp = tab + 1;
            }
        }
        nrows++;
        p = line_limit + 1;
    }

    if (nrows == 0) {
        Safefree(fields);
        Safefree(field_lens);
        *out_len = 0;
        return NULL;
    }

    /* Build the Data block body: block info + num_cols + num_rows + columns */
    {
        native_buf_t body;
        int col;

        nbuf_init(&body);
        nbuf_block_info(&body);
        nbuf_varuint(&body, (uint64_t)num_cols);
        nbuf_varuint(&body, (uint64_t)nrows);

        /* encode each column */
        for (col = 0; col < num_cols; col++) {
            const char **col_vals;
            size_t *col_vlens;
            int row;
            int sub = cdefs ? cdefs[col].subst : 0;
            int nulcol = sub && cdefs[col].nullable;

            /* column name and type */
            nbuf_string(&body, col_names[col], col_name_lens[col]);
            nbuf_string(&body, col_types_str[col], col_type_lens[col]);
            nbuf_u8(&body, 0);  /* has_custom_serialization = false */

            /* gather column values from row-major fields */
            Newxz(col_vals, nrows, const char *);
            Newx(col_vlens, nrows, size_t);
            for (row = 0; row < nrows; row++) {
                const char *fp = fields[row * num_cols + col];
                size_t fl = field_lens[row * num_cols + col];
                if (sub && (fl == 0
                            || (!nulcol && is_tsv_null(fp, fl)))) {
                    if (cdefs[col].to_null) {
                        fp = "\\N";
                        fl = 2;
                    } else if (cdefs[col].subst_text) {
                        fp = cdefs[col].subst_text;
                        fl = cdefs[col].subst_text_len;
                    } else {
                        char where[160];
                        err_where(where, sizeof(where), col_names[col],
                                  col_name_lens[col], col_types_str[col],
                                  col_type_lens[col]);
                        snprintf(errbuf, errbuf_sz, "%s, line %d: %s", where,
                                 row + 1, cdefs[col].err ? cdefs[col].err
                                 : "no client-side default for empty values: "
                                   "use data_format => 'Native'");
                        Safefree(col_vals);
                        Safefree(col_vlens);
                        Safefree(body.data);
                        Safefree(fields);
                        Safefree(field_lens);
                        *out_len = (size_t)-1;
                        return NULL;
                    }
                }
                col_vals[row] = fp;
                col_vlens[row] = fl;
            }

            if (nrows) write_col_prefix(&body, col_types[col]);
            if (!encode_column_text(&body, col_vals, col_vlens,
                                    (uint64_t)nrows, col_types[col])) {
                char where[160];
                err_where(where, sizeof(where), col_names[col],
                          col_name_lens[col], col_types_str[col],
                          col_type_lens[col]);
                describe_text_failure(errbuf, errbuf_sz, where, col_types[col],
                                      col_vals, col_vlens, nrows);
                Safefree(col_vals);
                Safefree(col_vlens);
                Safefree(body.data);
                Safefree(fields);
                Safefree(field_lens);
                *out_len = (size_t)-1;  /* sentinel: encode failure */
                return NULL;
            }
            Safefree(col_vals);
            Safefree(col_vlens);
        }

        Safefree(fields);
        Safefree(field_lens);

        return wrap_data_block(self, &body, out_len);
    }
}

static void nbuf_reserve(native_buf_t *b, size_t cap) {
    if (cap > b->cap) {
        b->cap = cap;
        Renew(b->data, cap, char);
    }
}

/* Rows per pass of the insert build: a pass encodes every column of a
 * chunk of rows while their scalars are cache-hot, instead of walking all
 * rows' scalars once per column. */
#define INSERT_CHUNK_ROWS 1024

enum { ENC_WHOLE, ENC_PLAIN, ENC_NULLABLE, ENC_ARRAY, ENC_LC };

/* Types whose column encoding is the concatenation of per-value bytes. */
static int enc_plain_type(const col_type_t *ct) {
    switch (ct->code) {
    case CT_INT8: case CT_INT16: case CT_INT32: case CT_INT64:
    case CT_UINT8: case CT_UINT16: case CT_UINT32: case CT_UINT64:
    case CT_BOOL: case CT_FLOAT32: case CT_FLOAT64: case CT_BFLOAT16:
    case CT_DATE: case CT_DATE32: case CT_DATETIME: case CT_DATETIME64:
    case CT_TIME: case CT_TIME64:
    case CT_DECIMAL32: case CT_DECIMAL64: case CT_DECIMAL128: case CT_DECIMAL256:
    case CT_STRING: case CT_FIXEDSTRING: case CT_UUID: case CT_IPV4: case CT_IPV6:
    case CT_ENUM8: case CT_ENUM16:
        return 1;
    default:
        return 0;
    }
}

/* Nullable/Array/LowCardinality of a plain type encode a chunk as parts
 * that concatenate across chunks; anything else is encoded whole. */
static int enc_col_mode(const col_type_t *ct) {
    if (enc_plain_type(ct)) return ENC_PLAIN;
    if (!ct->inner || !enc_plain_type(ct->inner)) return ENC_WHOLE;
    switch (ct->code) {
    case CT_NULLABLE:       return ENC_NULLABLE;
    case CT_ARRAY:          return ENC_ARRAY;
    case CT_LOWCARDINALITY: return ENC_LC;
    default:                return ENC_WHOLE;
    }
}

typedef struct {
    int mode;
    native_buf_t data;    /* values, array elements or LC dictionary */
    native_buf_t aux;     /* null map or array offsets */
    uint64_t base;        /* array elements so far */
} enc_col_t;

typedef struct {
    enc_col_t *cols;
    int ncols;
    SV **vals;
    native_buf_t tmp;
    native_buf_t out;
} enc_ctx_t;

static void enc_ctx_free(pTHX_ void *p) {
    enc_ctx_t *x = (enc_ctx_t *)p;
    int c;
    for (c = 0; c < x->ncols; c++) {
        Safefree(x->cols[c].data.data);
        Safefree(x->cols[c].aux.data);
    }
    Safefree(x->cols);
    Safefree(x->vals);
    Safefree(x->tmp.data);
    Safefree(x->out.data);
    Safefree(x);
}

/* Gather one column of n rows, with empty cells replaced by the column's
 * resolved default when cd asks for it: '' always, undef unless the
 * column is Nullable. */
static SSize_t snap_gather(const insert_snap_t *sn, SSize_t r0, SSize_t n,
                           int col, const col_default_t *cd, SV **vals) {
    SSize_t k;
    SV *to;
    for (k = 0; k < n; k++) {
        SSize_t o = sn->off[r0 + k];
        SV *v = col < sn->off[r0 + k + 1] - o ? sn->cells[o + col] : NULL;
        vals[k] = v ? v : &PL_sv_undef;
    }
    if (!cd || !cd->subst) return -1;
    to = cd->to_null ? &PL_sv_undef : cd->subst_sv;
    for (k = 0; k < n; k++) {
        SV *v = vals[k];
        if (SvOK(v) ? SvPOK(v) && SvCUR(v) == 0 : !cd->nullable) {
            if (!to) return cd->err ? k : -1;
            vals[k] = to;
        }
    }
    return -1;
}

/* Move one chunk's encoding of n rows (tmp) into the column's parts. */
static void enc_split_chunk(enc_col_t *ec, const native_buf_t *tmp, SSize_t n) {
    switch (ec->mode) {
    case ENC_NULLABLE:
        nbuf_append(&ec->aux, tmp->data, (size_t)n);
        nbuf_append(&ec->data, tmp->data + n, tmp->len - (size_t)n);
        break;
    case ENC_ARRAY: {
        SSize_t k;
        uint64_t off = 0, abs;
        nbuf_grow(&ec->aux, (size_t)n * 8);
        for (k = 0; k < n; k++) {
            memcpy(&off, tmp->data + k * 8, 8);
            abs = ec->base + off;
            memcpy(ec->aux.data + ec->aux.len, &abs, 8);
            ec->aux.len += 8;
        }
        ec->base += off;
        nbuf_append(&ec->data, tmp->data + n * 8, tmp->len - (size_t)n * 8);
        break;
    }
    case ENC_LC: {
        /* ser_type, num_keys, dictionary, num_indices, indices */
        int key_type = (unsigned char)tmp->data[0];
        size_t w = key_type == 0 ? 1 : key_type == 1 ? 2 : 4;
        nbuf_append(&ec->data, tmp->data + 16, tmp->len - 24 - (size_t)n * w);
        break;
    }
    default:
        break;
    }
}

/*
 * Build a native protocol Data block from an insert snapshot.
 * Like build_native_insert_data() but encodes SVs directly via encode_column_sv().
 */
static char* build_native_insert_data_from_av(pTHX_ ev_clickhouse_t *self,
                                               SV *snap_sv,
                                               const char **col_names, size_t *col_name_lens,
                                               const char **col_types_str, size_t *col_type_lens,
                                               col_type_t **col_types,
                                               int num_cols,
                                               col_default_t *cdefs,
                                               enc_progress_t *prog,
                                               size_t *out_len,
                                               char *errbuf, size_t errbuf_sz) {
    insert_snap_t *sn = insert_snap_get(aTHX_ snap_sv);
    SSize_t nrows = sn ? sn->nrows : 0;
    enc_ctx_t *x;
    SSize_t r0, fail_r0 = 0, fail_n = 0, fail_nodef = -1;
    int c, fail = num_cols;
    size_t need;
    char *pkt;

    if (nrows <= 0) {
        *out_len = 0;
        return NULL;
    }
    if (sn->bad_row >= 0) {
        snprintf(errbuf, errbuf_sz, "row %ld is not an arrayref",
                 (long)sn->bad_row);
        *out_len = (size_t)-1;  /* sentinel: encode failure */
        return NULL;
    }
    if (sn->width >= 0 && sn->width != num_cols) {
        snprintf(errbuf, errbuf_sz, "columns_at has %ld positions but the "
                 "insert has %d columns", (long)sn->width, num_cols);
        *out_len = (size_t)-1;
        return NULL;
    }

    ENTER;
    Newxz(x, 1, enc_ctx_t);
    SAVEDESTRUCTOR_X(enc_ctx_free, x);
    Newxz(x->cols, num_cols, enc_col_t);
    x->ncols = num_cols;
    Newx(x->vals, nrows, SV *);
    nbuf_init(&x->tmp);
    for (c = 0; c < num_cols; c++) {
        enc_col_t *ec = &x->cols[c];
        size_t fsz = col_type_fixed_size(col_types[c]);
        ec->mode = enc_col_mode(col_types[c]);
        nbuf_init(&ec->data);
        nbuf_init(&ec->aux);
        if (ec->mode == ENC_PLAIN && fsz)
            nbuf_reserve(&ec->data, fsz * (size_t)nrows);
        else if (ec->mode == ENC_NULLABLE)
            nbuf_reserve(&ec->aux, (size_t)nrows);
        else if (ec->mode == ENC_ARRAY)
            nbuf_reserve(&ec->aux, 8 * (size_t)nrows);
    }

    /* A failing column stops the work on itself and every later column,
     * so the column reported is the first failing one, as column order
     * would find it. */
    for (r0 = 0; r0 < nrows && fail > 0; r0 += INSERT_CHUNK_ROWS) {
        SSize_t n = nrows - r0 < INSERT_CHUNK_ROWS ? nrows - r0 : INSERT_CHUNK_ROWS;
        ENTER; SAVETMPS;
        for (c = 0; c < fail; c++) {
            enc_col_t *ec = &x->cols[c];
            int ok;
            SSize_t nodef;
            if (ec->mode == ENC_WHOLE) continue;
            nodef = snap_gather(sn, r0, n, c, cdefs ? &cdefs[c] : NULL, x->vals);
            if (nodef >= 0) {
                fail = c; fail_r0 = r0; fail_n = n; fail_nodef = r0 + nodef;
                break;
            }
            prog->col = c; prog->r0 = r0; prog->n = n;
            if (ec->mode == ENC_PLAIN) {
                ok = encode_column_sv(aTHX_ &ec->data, x->vals, (uint64_t)n,
                                      col_types[c]);
            } else {
                x->tmp.len = 0;
                ok = encode_column_sv(aTHX_ &x->tmp, x->vals, (uint64_t)n,
                                      col_types[c]);
                if (ok) enc_split_chunk(ec, &x->tmp, n);
            }
            if (!ok) {
                fail = c; fail_r0 = r0; fail_n = n; fail_nodef = -1;
            }
            else if (r0 == 0 && n < nrows
                     && !(ec->mode == ENC_PLAIN && col_type_fixed_size(col_types[c])))
                nbuf_reserve(&ec->data,
                    (size_t)((double)ec->data.len / n * nrows * 1.1) + 64);
        }
        FREETMPS; LEAVE;
    }
    for (c = 0; c < fail; c++) {
        if (x->cols[c].mode != ENC_WHOLE) continue;
        SSize_t nodef;
        ENTER; SAVETMPS;
        nodef = snap_gather(sn, 0, nrows, c, cdefs ? &cdefs[c] : NULL, x->vals);
        prog->col = c; prog->r0 = 0; prog->n = nrows;
        if (nodef >= 0) {
            fail = c; fail_r0 = 0; fail_n = nrows; fail_nodef = nodef;
        } else if (!encode_column_sv(aTHX_ &x->cols[c].data, x->vals,
                                     (uint64_t)nrows, col_types[c])) {
            fail = c; fail_r0 = 0; fail_n = nrows; fail_nodef = -1;
        }
        FREETMPS; LEAVE;
    }
    if (fail < num_cols) {
        char where[160];
        prog->col = fail; prog->r0 = fail_r0; prog->n = fail_n;
        err_where(where, sizeof(where), col_names[fail], col_name_lens[fail],
                  col_types_str[fail], col_type_lens[fail]);
        if (fail_nodef >= 0) {
            snprintf(errbuf, errbuf_sz, "%s, row %ld: %s", where,
                     (long)fail_nodef, cdefs[fail].err);
        } else {
            snap_gather(sn, fail_r0, fail_n, fail, cdefs ? &cdefs[fail] : NULL,
                        x->vals);
            describe_sv_failure(aTHX_ errbuf, errbuf_sz, where, col_types[fail],
                                x->vals, fail_n, fail_r0, "row");
        }
        *out_len = (size_t)-1;  /* sentinel: encode failure */
        LEAVE;
        return NULL;
    }
    prog->col = -1;

    need = 64;
    for (c = 0; c < num_cols; c++) {
        need += col_name_lens[c] + col_type_lens[c] + 64
              + x->cols[c].data.len + x->cols[c].aux.len;
        if (x->cols[c].mode == ENC_LC) need += 24 + 4 * (size_t)nrows;
    }
    nbuf_init(&x->out);
    nbuf_reserve(&x->out, need);
    if (!self->compress) {
        nbuf_varuint(&x->out, CLIENT_DATA);
        nbuf_cstring(&x->out, "");   /* table name */
    }
    nbuf_block_info(&x->out);
    nbuf_varuint(&x->out, (uint64_t)num_cols);
    nbuf_varuint(&x->out, (uint64_t)nrows);
    for (c = 0; c < num_cols; c++) {
        enc_col_t *ec = &x->cols[c];
        nbuf_string(&x->out, col_names[c], col_name_lens[c]);
        nbuf_string(&x->out, col_types_str[c], col_type_lens[c]);
        nbuf_u8(&x->out, 0);  /* has_custom_serialization = false */
        write_col_prefix(&x->out, col_types[c]);
        if (ec->mode == ENC_LC) {
            size_t idx_size;
            lc_write_keys_header(&x->out, (uint64_t)nrows, &idx_size);
            nbuf_append(&x->out, ec->data.data, ec->data.len);
            lc_write_indices(&x->out, (uint64_t)nrows, idx_size);
        } else {
            nbuf_append(&x->out, ec->aux.data, ec->aux.len);
            nbuf_append(&x->out, ec->data.data, ec->data.len);
        }
        Safefree(ec->data.data); ec->data.data = NULL;
        Safefree(ec->aux.data);  ec->aux.data = NULL;
    }

    if (!self->compress) {
        nbuf_empty_data_block(&x->out, 0);
        pkt = x->out.data;
        *out_len = x->out.len;
    } else {
        pkt = wrap_data_block(self, &x->out, out_len);
    }
    x->out.data = NULL;
    LEAVE;
    return pkt;
}

typedef struct {
    ev_clickhouse_t *self;
    SV *snap;
    const char **names; size_t *name_lens;
    const char **types_str; size_t *type_lens;
    col_type_t **types;
    int ncols;
    col_default_t *cdefs;
    enc_progress_t prog;
    size_t *out_len;
    char *errbuf; size_t errbuf_sz;
    char *pkt;
} av_build_t;

static void av_build_fn(pTHX_ void *p) {
    av_build_t *a = (av_build_t *)p;
    a->pkt = build_native_insert_data_from_av(aTHX_ a->self, a->snap,
        a->names, a->name_lens, a->types_str, a->type_lens, a->types,
        a->ncols, a->cdefs, &a->prog, a->out_len, a->errbuf, a->errbuf_sz);
}

typedef struct {
    SV *v;
    col_type_t *ct;
    native_buf_t *scratch;
} encode_one_t;

static void encode_one_fn(pTHX_ void *p) {
    encode_one_t *a = (encode_one_t *)p;
    (void)sv_encodes(aTHX_ a->v, a->ct, a->scratch);
}

/* build_native_insert_data_from_av() with exceptions from user code
 * turned into an encode failure naming the column and row that died. */
static char* build_native_insert_data_from_av_guarded(pTHX_ ev_clickhouse_t *self,
                                               SV *snap_sv,
                                               const char **col_names, size_t *col_name_lens,
                                               const char **col_types_str, size_t *col_type_lens,
                                               col_type_t **col_types,
                                               int num_cols,
                                               col_default_t *cdefs,
                                               size_t *out_len,
                                               char *errbuf, size_t errbuf_sz) {
    av_build_t a;
    SV *err = NULL;
    native_buf_t msg;
    int c;

    a.self = self; a.snap = snap_sv;
    a.names = col_names; a.name_lens = col_name_lens;
    a.types_str = col_types_str; a.type_lens = col_type_lens;
    a.types = col_types; a.ncols = num_cols; a.cdefs = cdefs;
    a.prog.col = -1; a.prog.r0 = 0; a.prog.n = 0;
    a.out_len = out_len; a.errbuf = errbuf; a.errbuf_sz = errbuf_sz;
    a.pkt = NULL;
    if (run_guarded(aTHX_ av_build_fn, &a, &err))
        return a.pkt;

    nbuf_init(&msg);
    c = a.prog.col;
    if (c >= 0 && c < num_cols) {
        insert_snap_t *sn = insert_snap_get(aTHX_ snap_sv);
        char where[160];
        SSize_t k, row = -1;
        err_where(where, sizeof(where), col_names[c], col_name_lens[c],
                  col_types_str[c], col_type_lens[c]);
        err_append(&msg, where);
        if (sn && a.prog.n > 0 && a.prog.r0 + a.prog.n <= sn->nrows) {
            SV **vals;
            native_buf_t scratch;
            encode_one_t one;
            Newx(vals, a.prog.n, SV *);
            nbuf_init(&scratch);
            snap_gather(sn, a.prog.r0, a.prog.n, c,
                        cdefs ? &cdefs[c] : NULL, vals);
            one.ct = col_types[c];
            one.scratch = &scratch;
            for (k = 0; k < a.prog.n && row < 0; k++) {
                one.v = vals[k];
                if (!run_guarded(aTHX_ encode_one_fn, &one, NULL))
                    row = a.prog.r0 + k;
            }
            Safefree(scratch.data);
            Safefree(vals);
        }
        if (row >= 0) {
            char rb[48];
            snprintf(rb, sizeof(rb), ", row %ld", (long)row);
            err_append(&msg, rb);
        }
        err_append(&msg, ": ");
    }
    err_exception(aTHX_ &msg, err);
    if (err) SvREFCNT_dec(err);
    err_finish(errbuf, errbuf_sz, &msg);
    *out_len = (size_t)-1;  /* sentinel: encode failure */
    return NULL;
}

/*
 * Build the external-table Data packets for a native query. `external`
 * maps table-name => { structure => [name => type, ...], data => [[..],..] }.
 * Each entry becomes one CLIENT_DATA packet (named block, optionally LZ4)
 * to be spliced into the query stream before the terminating empty block.
 *
 * Returns a malloc'd buffer of the concatenated packets with *out_len set
 * (an empty 0-length buffer when `external` has no tables). On error
 * returns NULL and writes a message into errbuf. The caller must
 * Safefree the returned buffer.
 */
static char* build_external_tables(pTHX_ ev_clickhouse_t *self, HV *external,
                                   const char *tz, size_t *out_len,
                                   char *errbuf, size_t errbuf_sz) {
    native_buf_t out;
    HE *he;

    *out_len = 0;
    nbuf_init(&out);
    hv_iterinit(external);

    while ((he = hv_iternext(external))) {
        I32 tnlen;
        const char *tname = hv_iterkey(he, &tnlen);
        SV *spec_sv = hv_iterval(external, he);
        HV *spec;
        SV **st, **dt;
        AV *structure, *rows;
        SSize_t sn, nrows, row;
        int ncols, col;
        native_buf_t body;
        body.data = NULL;

        if (!SvROK(spec_sv) || SvTYPE(SvRV(spec_sv)) != SVt_PVHV) {
            snprintf(errbuf, errbuf_sz, "external table '%s': spec must be a "
                     "hashref { structure => [...], data => [...] }", tname);
            goto fail;
        }
        spec = (HV *)SvRV(spec_sv);
        st = hv_fetchs(spec, "structure", 0);
        dt = hv_fetchs(spec, "data", 0);
        if (!st || !SvROK(*st) || SvTYPE(SvRV(*st)) != SVt_PVAV) {
            snprintf(errbuf, errbuf_sz, "external table '%s': 'structure' must "
                     "be an arrayref of name => type pairs", tname);
            goto fail;
        }
        if (!dt || !SvROK(*dt) || SvTYPE(SvRV(*dt)) != SVt_PVAV) {
            snprintf(errbuf, errbuf_sz, "external table '%s': 'data' must be "
                     "an arrayref of rows", tname);
            goto fail;
        }
        structure = (AV *)SvRV(*st);
        rows      = (AV *)SvRV(*dt);
        sn = av_len(structure) + 1;
        if (sn < 2 || (sn & 1)) {
            snprintf(errbuf, errbuf_sz, "external table '%s': 'structure' needs "
                     "a non-empty, even list of name => type pairs", tname);
            goto fail;
        }
        ncols = (int)(sn / 2);
        nrows = av_len(rows) + 1;
        if (nrows < 0) nrows = 0;

        /* block body: block info + num_columns + num_rows + columns */
        nbuf_init(&body);
        nbuf_block_info(&body);
        nbuf_varuint(&body, (uint64_t)ncols);
        nbuf_varuint(&body, (uint64_t)nrows);

        for (col = 0; col < ncols; col++) {
            SV **nm = av_fetch(structure, col * 2, 0);
            SV **ty = av_fetch(structure, col * 2 + 1, 0);
            STRLEN cnl, ctl;
            const char *cname, *ctype;
            col_type_t *ct;
            SV **col_vals;
            int enc;

            if (!nm || !ty || !SvOK(*nm) || !SvOK(*ty)) {
                snprintf(errbuf, errbuf_sz, "external table '%s': structure "
                         "name/type entries must be defined", tname);
                Safefree(body.data);
                goto fail;
            }
            cname = SvPV(*nm, cnl);
            ctype = SvPV(*ty, ctl);
            nbuf_string(&body, cname, cnl);
            nbuf_string(&body, ctype, ctl);
            nbuf_u8(&body, 0);   /* has_custom_serialization = false */

            ct = parse_col_type(ctype, ctl);
            col_type_default_tz(ct, tz, &self->zones);

            /* gather this column's values from the row-major data */
            Newx(col_vals, nrows > 0 ? nrows : 1, SV *);
            for (row = 0; row < nrows; row++) {
                SV **rsv = av_fetch(rows, row, 0);
                AV *rav;
                SV **vsv;
                if (!rsv || !SvROK(*rsv) || SvTYPE(SvRV(*rsv)) != SVt_PVAV) {
                    snprintf(errbuf, errbuf_sz, "external table '%s': each data "
                             "row must be an arrayref", tname);
                    Safefree(col_vals);
                    free_col_type(ct);
                    Safefree(body.data);
                    goto fail;
                }
                rav = (AV *)SvRV(*rsv);
                vsv = av_fetch(rav, col, 0);
                col_vals[row] = (vsv && *vsv) ? *vsv : &PL_sv_undef;
            }

            enc = 1;
            if (nrows) {
                write_col_prefix(&body, ct);
                enc = encode_column_sv(aTHX_ &body, col_vals,
                                       (uint64_t)nrows, ct);
            }
            if (!enc) {
                char where[160], what[512];
                err_where(where, sizeof(where), cname, cnl, ctype, ctl);
                describe_sv_failure(aTHX_ what, sizeof(what), where, ct,
                                    col_vals, nrows, 0, "row");
                snprintf(errbuf, errbuf_sz, "external table '%s': %s",
                         tname, what);
            }
            Safefree(col_vals);
            free_col_type(ct);
            if (!enc) {
                Safefree(body.data);
                goto fail;
            }
        }

        /* [CLIENT_DATA] [table name] [block — optionally LZ4-compressed] */
        nbuf_varuint(&out, CLIENT_DATA);
        nbuf_string(&out, tname, (size_t)tnlen);
      #ifdef HAVE_LZ4
        if (self->compress) {
            char *comp;
            size_t comp_len;
            comp = ch_lz4_compress(body.data, body.len, &comp_len);
            Safefree(body.data);
            body.data = NULL;
            if (!comp) {
                snprintf(errbuf, errbuf_sz, "external table '%s': LZ4 "
                         "compression failed", tname);
                goto fail;
            }
            nbuf_append(&out, comp, comp_len);
            Safefree(comp);
        } else
      #endif
        {
            nbuf_append(&out, body.data, body.len);
            Safefree(body.data);
            body.data = NULL;
        }
    }

    *out_len = out.len;
    return out.data;

fail:
    Safefree(out.data);
    *out_len = 0;
    return NULL;
}

