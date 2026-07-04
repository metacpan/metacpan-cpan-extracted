/*
 * tar.c - built-in tar plugin for File::Raw::Archive.
 *
 * Reads ustar (POSIX 1988), GNU `././@LongLink` extension for long
 * filenames / symlink targets, and PAX extended headers (POSIX
 * 1003.1-2001 typeflags 'x' and 'g'). Writes ustar + GNU @LongLink +
 * PAX 'x' + optional PAX 'g' header at archive start, with a `format`
 * option selecting auto / pax / gnu / ustar emission strategy.
 *
 * PAX keys handled on read AND write: path, linkpath, size, mtime
 * (with nanoseconds), atime, uid, gid, uname, gname, plus
 * SCHILY.xattr.* and LIBARCHIVE.xattr.* (optionally .b64 suffix for
 * binary values). Sparse-file PAX keys flag the entry but don't
 * reconstruct.
 */

#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "archive_plugin.h"
#include "arch_io.h"
#include "tar.h"

#include <ctype.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>

/* ============================================================
 * Octal / numeric helpers
 * ============================================================ */

/* Parse a NUL- or space-terminated octal field of `n` bytes. Honours
 * the GNU base-256 extension when bit 7 of the first byte is set
 * (used for size > 8 GiB, mtime, uid, etc.). */
static uint64_t
tar_parse_numeric(const char *field, size_t n)
{
    if (n == 0) return 0;
    if ((unsigned char)field[0] & 0x80) {
        /* Base-256: first byte's bit 7 is the marker (and bit 6 is
         * the sign bit; we treat negative as 0). */
        uint64_t v = 0;
        size_t i;
        if ((unsigned char)field[0] & 0x40) return 0;  /* negative */
        v = (unsigned char)field[0] & 0x3f;
        for (i = 1; i < n; i++) {
            v = (v << 8) | (unsigned char)field[i];
        }
        return v;
    }
    /* Octal ASCII, ignoring leading spaces and trailing spaces/NUL. */
    uint64_t v = 0;
    size_t i = 0;
    while (i < n && (field[i] == ' ' || field[i] == '0')) i++;
    /* If we ate everything as zeros/spaces, value is 0 (handles all-zero fields). */
    while (i < n && field[i] >= '0' && field[i] <= '7') {
        v = (v << 3) | (uint64_t)(field[i] - '0');
        i++;
    }
    return v;
}

/* Emit an octal value into a fixed-width field, NUL-terminated.
 * For values that don't fit, emit base-256 with the high bit set on
 * the first byte. */
static void
tar_emit_numeric(char *field, size_t n, uint64_t v)
{
    /* Try octal first. Field width n means n-1 digits (last byte NUL). */
    int fits_octal = 1;
    uint64_t check = v;
    size_t digits = 0;
    if (check == 0) digits = 1;
    while (check) { digits++; check >>= 3; }
    if (digits > n - 1) fits_octal = 0;

    if (fits_octal) {
        size_t i;
        field[n - 1] = '\0';
        for (i = n - 1; i > 0; i--) {
            field[i - 1] = (char)('0' + (v & 7));
            v >>= 3;
        }
    } else {
        /* Base-256, big-endian, with high bit set on first byte. */
        size_t i;
        for (i = n; i > 0; i--) {
            field[i - 1] = (char)(v & 0xff);
            v >>= 8;
        }
        field[0] |= 0x80;
    }
}

/* Compute the standard tar header checksum: sum of all bytes treating
 * the chksum field itself as eight spaces. */
static uint32_t
tar_compute_checksum(const tar_header_t *h)
{
    const unsigned char *p = (const unsigned char *)h;
    uint32_t sum = 0;
    size_t i;
    for (i = 0; i < TAR_BLOCK_SIZE; i++) {
        if (i >= offsetof(tar_header_t, chksum) &&
            i <  offsetof(tar_header_t, chksum) + sizeof h->chksum) {
            sum += ' ';
        } else {
            sum += p[i];
        }
    }
    return sum;
}

static int
tar_block_is_zero(const char *block)
{
    size_t i;
    for (i = 0; i < TAR_BLOCK_SIZE; i++) if (block[i]) return 0;
    return 1;
}

/* ============================================================
 * PAX record parsing / emission
 * ============================================================ */

typedef struct pax_kv {
    char *key;
    char *value;
    size_t value_len;
    struct pax_kv *next;
} pax_kv_t;

static void
pax_kv_free(pax_kv_t *list)
{
    while (list) {
        pax_kv_t *n = list->next;
        free(list->key);
        free(list->value);
        free(list);
        list = n;
    }
}

static void
pax_kv_set(pax_kv_t **list, const char *key, const char *value, size_t value_len)
{
    pax_kv_t *cur;
    for (cur = *list; cur; cur = cur->next) {
        if (strcmp(cur->key, key) == 0) {
            free(cur->value);
            cur->value = (char *)malloc(value_len + 1);
            memcpy(cur->value, value, value_len);
            cur->value[value_len] = '\0';
            cur->value_len = value_len;
            return;
        }
    }
    pax_kv_t *fresh = (pax_kv_t *)calloc(1, sizeof *fresh);
    fresh->key = strdup(key);
    fresh->value = (char *)malloc(value_len + 1);
    memcpy(fresh->value, value, value_len);
    fresh->value[value_len] = '\0';
    fresh->value_len = value_len;
    fresh->next = *list;
    *list = fresh;
}

static const pax_kv_t *
pax_kv_find(const pax_kv_t *list, const char *key)
{
    while (list) {
        if (strcmp(list->key, key) == 0) return list;
        list = list->next;
    }
    return NULL;
}

/* Parse a buffer of length `len` as a sequence of PAX records:
 *   "<L> <key>=<value>\n"
 * where <L> is the ASCII byte length of the whole record. */
static int
pax_parse_records(const char *buf, size_t len, pax_kv_t **out)
{
    size_t pos = 0;
    while (pos < len) {
        size_t L = 0;
        size_t lstart = pos;
        while (pos < len && buf[pos] >= '0' && buf[pos] <= '9') {
            L = L * 10 + (buf[pos] - '0');
            pos++;
        }
        if (pos == lstart || pos >= len || buf[pos] != ' ') return -1;
        pos++;  /* skip space */
        if (lstart + L > len) return -1;
        /* The record minus the digits + space is "kw=value\n" */
        size_t rec_inner_end = lstart + L - 1;  /* position of '\n' */
        if (rec_inner_end >= len || buf[rec_inner_end] != '\n') return -1;
        const char *eq = (const char *)memchr(buf + pos, '=', rec_inner_end - pos);
        if (!eq) return -1;
        size_t key_len   = eq - (buf + pos);
        size_t value_len = rec_inner_end - (eq - buf) - 1;
        char *key = (char *)malloc(key_len + 1);
        memcpy(key, buf + pos, key_len);
        key[key_len] = '\0';
        /* pax_kv_set duplicates value; we'll free key after. */
        pax_kv_set(out, key, eq + 1, value_len);
        free(key);
        pos = lstart + L;
    }
    return 0;
}

/* Build one PAX record into `out_buf` (caller-provided, must be big
 * enough). Returns the byte length. The fixed-point challenge: the
 * leading L includes its own digit count. */
static size_t
pax_build_record(char *out_buf, const char *key, const char *value, size_t value_len)
{
    size_t key_len = strlen(key);
    /* Inner = key + '=' + value + '\n' */
    size_t inner = key_len + 1 + value_len + 1;
    /* L is a positive integer; its digit count + 1 (for the space) + inner = total. */
    size_t L = inner + 2;  /* start with 1-digit guess */
    for (;;) {
        char tmp[32];
        int dlen = snprintf(tmp, sizeof tmp, "%zu", L);
        size_t total = (size_t)dlen + 1 + inner;
        if (total == L) break;
        L = total;
    }
    int dlen = snprintf(out_buf, 32, "%zu ", L);
    memcpy(out_buf + dlen, key, key_len);
    out_buf[dlen + key_len] = '=';
    memcpy(out_buf + dlen + key_len + 1, value, value_len);
    out_buf[L - 1] = '\n';
    return L;
}

/* ============================================================
 * Base64 (for SCHILY.xattr.*.b64 binary values)
 * ============================================================ */

static const char b64_alphabet[] =
    "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

static int
b64_decode_byte(int c)
{
    if (c >= 'A' && c <= 'Z') return c - 'A';
    if (c >= 'a' && c <= 'z') return c - 'a' + 26;
    if (c >= '0' && c <= '9') return c - '0' + 52;
    if (c == '+') return 62;
    if (c == '/') return 63;
    return -1;
}

/* malloc-allocates *out; caller frees. Returns 0 on success, -1 on
 * malformed input. */
static int
b64_decode(const char *in, size_t in_len, char **out, size_t *out_len)
{
    size_t cap = (in_len / 4) * 3 + 4;
    char *buf = (char *)malloc(cap);
    if (!buf) return -1;
    size_t bp = 0;
    int quad[4] = { -1, -1, -1, -1 };
    int qi = 0;
    size_t i;
    for (i = 0; i < in_len; i++) {
        int c = (unsigned char)in[i];
        if (c == '=' || c == '\r' || c == '\n' || c == ' ' || c == '\t') {
            if (c == '=') {
                quad[qi++] = -2;
                if (qi == 4) goto flush;
            }
            continue;
        }
        int v = b64_decode_byte(c);
        if (v < 0) { free(buf); return -1; }
        quad[qi++] = v;
        if (qi == 4) {
flush:
            if (quad[0] < 0 || quad[1] < 0) { free(buf); return -1; }
            buf[bp++] = (char)(((quad[0] & 0x3f) << 2) | ((quad[1] & 0x30) >> 4));
            if (quad[2] >= 0) {
                buf[bp++] = (char)(((quad[1] & 0x0f) << 4) | ((quad[2] & 0x3c) >> 2));
                if (quad[3] >= 0) {
                    buf[bp++] = (char)(((quad[2] & 0x03) << 6) | (quad[3] & 0x3f));
                }
            }
            qi = 0;
            quad[0] = quad[1] = quad[2] = quad[3] = -1;
        }
    }
    *out = buf;
    *out_len = bp;
    return 0;
}

static char *
b64_encode(const char *in, size_t in_len)
{
    size_t out_len = 4 * ((in_len + 2) / 3);
    char *out = (char *)malloc(out_len + 1);
    if (!out) return NULL;
    size_t i, op = 0;
    for (i = 0; i + 2 < in_len; i += 3) {
        unsigned a = (unsigned char)in[i];
        unsigned b = (unsigned char)in[i+1];
        unsigned c = (unsigned char)in[i+2];
        out[op++] = b64_alphabet[a >> 2];
        out[op++] = b64_alphabet[((a & 3) << 4) | (b >> 4)];
        out[op++] = b64_alphabet[((b & 0xf) << 2) | (c >> 6)];
        out[op++] = b64_alphabet[c & 0x3f];
    }
    if (i < in_len) {
        unsigned a = (unsigned char)in[i];
        unsigned b = (i+1 < in_len) ? (unsigned char)in[i+1] : 0;
        out[op++] = b64_alphabet[a >> 2];
        out[op++] = b64_alphabet[((a & 3) << 4) | (b >> 4)];
        if (i + 1 < in_len) {
            out[op++] = b64_alphabet[(b & 0xf) << 2];
        } else {
            out[op++] = '=';
        }
        out[op++] = '=';
    }
    out[op] = '\0';
    return out;
}

static int
needs_b64(const char *value, size_t value_len)
{
    size_t i;
    for (i = 0; i < value_len; i++) {
        unsigned c = (unsigned char)value[i];
        if (c == 0 || c == '\n' || c < 0x20 || c > 0x7e) return 1;
    }
    return 0;
}

/* ============================================================
 * Cursor state
 * ============================================================ */

typedef struct {
    archive_pull_fn pull;
    void           *src;
    archive_push_fn push;
    void           *sink;

    pax_kv_t *global_kv;
    pax_kv_t *next_kv;     /* per-entry 'x' header, applied to next regular entry */

    /* read-side: pending bytes of the current entry payload */
    uint64_t entry_remaining;
    uint64_t entry_pad;     /* bytes of zero padding still to consume after entry */

    /* read-side: storage for the current entry's strings/xattrs.
     * Lifetime: until the next read_next call. */
    char *cur_name;
    char *cur_link;
    ArchiveXattr *cur_xattrs;
    size_t        cur_xattr_count;
    size_t        cur_xattr_cap;
    int           sparse_warning_emitted;

    /* write-side: chosen format and counters */
    int format;             /* 0=auto 1=pax 2=gnu 3=ustar */
    int level;              /* gzip level for gz sink (informational) */
    /* PAX header sequence number for the conventional name. */
    int pax_header_seq;
} tar_cursor_t;

#define FMT_AUTO  0
#define FMT_PAX   1
#define FMT_GNU   2
#define FMT_USTAR 3

static int
read_full(archive_pull_fn pull, void *src, char *buf, size_t len)
{
    size_t got = 0;
    while (got < len) {
        int n = pull(src, buf + got, len - got);
        if (n < 0) return -1;
        if (n == 0) return (int)got;
        got += (size_t)n;
    }
    return (int)got;
}

static int
write_full(archive_push_fn push, void *sink, const char *buf, size_t len)
{
    size_t put = 0;
    while (put < len) {
        int n = push(sink, buf + put, len - put);
        if (n < 0) return -1;
        if (n == 0) return -1;
        put += (size_t)n;
    }
    return 0;
}

static void
free_cur_buffers(tar_cursor_t *c)
{
    free(c->cur_name);    c->cur_name = NULL;
    free(c->cur_link);    c->cur_link = NULL;
    if (c->cur_xattrs) {
        size_t i;
        for (i = 0; i < c->cur_xattr_count; i++) {
            free((void *)c->cur_xattrs[i].key);
            free((void *)c->cur_xattrs[i].value);
        }
        free(c->cur_xattrs);
    }
    c->cur_xattrs = NULL;
    c->cur_xattr_count = 0;
    c->cur_xattr_cap = 0;
}

/* ============================================================
 * Read side
 * ============================================================ */

static int
tar_read_open(pTHX_ const ArchivePlugin *self, archive_pull_fn pull,
              void *src, HV *opts, void **out_cursor)
{
    PERL_UNUSED_ARG(self);
    PERL_UNUSED_ARG(opts);
    tar_cursor_t *c = (tar_cursor_t *)calloc(1, sizeof *c);
    if (!c) return -1;
    c->pull = pull;
    c->src  = src;
    *out_cursor = c;
    return 0;
}

/* Skip the trailing zero padding of the previous entry, if any. */
static int
consume_pending_padding(tar_cursor_t *c)
{
    char buf[TAR_BLOCK_SIZE];
    while (c->entry_remaining > 0 || c->entry_pad > 0) {
        if (c->entry_remaining > 0) {
            size_t take = c->entry_remaining > sizeof buf ? sizeof buf : (size_t)c->entry_remaining;
            int n = read_full(c->pull, c->src, buf, take);
            if (n < (int)take) return -1;
            c->entry_remaining -= take;
        }
        if (c->entry_remaining == 0 && c->entry_pad > 0) {
            size_t take = c->entry_pad > sizeof buf ? sizeof buf : (size_t)c->entry_pad;
            int n = read_full(c->pull, c->src, buf, take);
            if (n < (int)take) return -1;
            c->entry_pad -= take;
        }
    }
    return 0;
}

/* Read a tar header block, return:
 *   1 = got a valid header (in *h), 0 = end of archive, -1 = error */
static int
read_one_header(tar_cursor_t *c, tar_header_t *h)
{
    char buf[TAR_BLOCK_SIZE];
    int n = read_full(c->pull, c->src, buf, TAR_BLOCK_SIZE);
    if (n < 0) return -1;
    if (n == 0) return 0;  /* clean EOF */
    if (n < TAR_BLOCK_SIZE) return -1;
    if (tar_block_is_zero(buf)) {
        /* First zero block: try one more. Two zero blocks => end-of-archive. */
        char buf2[TAR_BLOCK_SIZE];
        int n2 = read_full(c->pull, c->src, buf2, TAR_BLOCK_SIZE);
        (void)n2;  /* Either way: end. */
        return 0;
    }
    memcpy(h, buf, sizeof *h);

    /* Verify checksum. */
    uint32_t stored = (uint32_t)tar_parse_numeric(h->chksum, sizeof h->chksum);
    uint32_t actual = tar_compute_checksum(h);
    if (stored != actual) return -1;

    return 1;
}

/* Read an entry payload of `size` bytes followed by zero padding into
 * a malloced buffer. Caller frees. */
static int
read_payload(tar_cursor_t *c, uint64_t size, char **out)
{
    *out = NULL;
    if (size == 0) {
        *out = (char *)malloc(1);
        return *out ? 0 : -1;
    }
    char *buf = (char *)malloc((size_t)size + 1);
    if (!buf) return -1;
    int n = read_full(c->pull, c->src, buf, (size_t)size);
    if (n < (int)size) { free(buf); return -1; }
    buf[size] = '\0';

    /* Skip padding. */
    size_t pad = (TAR_BLOCK_SIZE - ((size_t)size % TAR_BLOCK_SIZE)) % TAR_BLOCK_SIZE;
    if (pad > 0) {
        char pbuf[TAR_BLOCK_SIZE];
        int pn = read_full(c->pull, c->src, pbuf, pad);
        if (pn < (int)pad) { free(buf); return -1; }
    }
    *out = buf;
    return 0;
}

/* Apply a per-entry PAX kv list onto entry `out`, parsing typed
 * values. Xattr keys (SCHILY.xattr.* and LIBARCHIVE.xattr.*) accumulate
 * into c->cur_xattrs[]. */
static void
apply_pax_to_entry(tar_cursor_t *c, const pax_kv_t *list, ArchiveEntry *out)
{
    while (list) {
        const char *k = list->key;
        const char *v = list->value;
        size_t vlen = list->value_len;
        if (strcmp(k, "path") == 0) {
            free(c->cur_name);
            c->cur_name = (char *)malloc(vlen + 1);
            memcpy(c->cur_name, v, vlen);
            c->cur_name[vlen] = '\0';
            out->name = c->cur_name;
            out->name_len = vlen;
        } else if (strcmp(k, "linkpath") == 0) {
            free(c->cur_link);
            c->cur_link = (char *)malloc(vlen + 1);
            memcpy(c->cur_link, v, vlen);
            c->cur_link[vlen] = '\0';
            out->link_target = c->cur_link;
            out->link_target_len = vlen;
        } else if (strcmp(k, "size") == 0) {
            out->size = strtoull(v, NULL, 10);
        } else if (strcmp(k, "mtime") == 0) {
            const char *dot = (const char *)memchr(v, '.', vlen);
            out->mtime = strtoull(v, NULL, 10);
            if (dot && (size_t)(dot - v) < vlen - 1) {
                /* Parse fractional part into nanoseconds (truncate/pad to 9 digits). */
                uint32_t ns = 0;
                int seen = 0;
                size_t i;
                for (i = (size_t)(dot - v + 1); i < vlen && seen < 9; i++) {
                    if (v[i] < '0' || v[i] > '9') break;
                    ns = ns * 10 + (uint32_t)(v[i] - '0');
                    seen++;
                }
                while (seen < 9) { ns *= 10; seen++; }
                out->mtime_ns = ns;
            }
        } else if (strcmp(k, "uid") == 0) {
            out->uid = (uint32_t)strtoul(v, NULL, 10);
        } else if (strcmp(k, "gid") == 0) {
            out->gid = (uint32_t)strtoul(v, NULL, 10);
        } else if (strncmp(k, "SCHILY.xattr.", 13) == 0
                || strncmp(k, "LIBARCHIVE.xattr.", 17) == 0) {
            size_t prefix_len = (k[0] == 'S') ? 13 : 17;
            const char *xname = k + prefix_len;
            size_t xname_len  = strlen(xname);
            int is_b64 = 0;
            if (xname_len > 4 && strcmp(xname + xname_len - 4, ".b64") == 0) {
                is_b64 = 1;
                xname_len -= 4;
            }
            char *decoded = NULL;
            size_t dec_len = 0;
            if (is_b64) {
                if (b64_decode(v, vlen, &decoded, &dec_len) < 0) {
                    list = list->next;
                    continue;
                }
            } else {
                decoded = (char *)malloc(vlen + 1);
                memcpy(decoded, v, vlen);
                decoded[vlen] = '\0';
                dec_len = vlen;
            }
            if (c->cur_xattr_count >= c->cur_xattr_cap) {
                size_t ncap = c->cur_xattr_cap ? c->cur_xattr_cap * 2 : 4;
                ArchiveXattr *na = (ArchiveXattr *)realloc(c->cur_xattrs, ncap * sizeof(*na));
                if (!na) { free(decoded); list = list->next; continue; }
                c->cur_xattrs = na;
                c->cur_xattr_cap = ncap;
            }
            char *kdup = (char *)malloc(xname_len + 1);
            memcpy(kdup, xname, xname_len);
            kdup[xname_len] = '\0';
            c->cur_xattrs[c->cur_xattr_count].key = kdup;
            c->cur_xattrs[c->cur_xattr_count].key_len = xname_len;
            c->cur_xattrs[c->cur_xattr_count].value = decoded;
            c->cur_xattrs[c->cur_xattr_count].value_len = dec_len;
            c->cur_xattr_count++;
        } else if (strncmp(k, "GNU.sparse.", 11) == 0) {
            out->is_sparse = 1;
            if (!c->sparse_warning_emitted) {
                /* Single warning per archive. */
                fprintf(stderr,
                    "File::Raw::Archive: sparse-encoded entries present; "
                    "dense bytes returned verbatim\n");
                c->sparse_warning_emitted = 1;
            }
        }
        /* All other vendor keys silently ignored. */
        list = list->next;
    }
}

static int
typeflag_to_ae(char tf)
{
    switch (tf) {
    case TF_REGULAR:
    case TF_AREGULAR:   return AE_FILE;
    case TF_HARDLINK:   return AE_HARDLINK;
    case TF_SYMLINK:    return AE_SYMLINK;
    case TF_CHAR:       return AE_CHAR;
    case TF_BLOCK:      return AE_BLOCK;
    case TF_DIRECTORY:  return AE_DIR;
    case TF_FIFO:       return AE_FIFO;
    default:            return AE_OTHER;
    }
}

static int
tar_read_next(pTHX_ const ArchivePlugin *self, void *cursor, ArchiveEntry *out)
{
    PERL_UNUSED_ARG(self);
    tar_cursor_t *c = (tar_cursor_t *)cursor;

    if (consume_pending_padding(c) < 0) return -1;
    free_cur_buffers(c);
    memset(out, 0, sizeof *out);

    /* Inner loop: peel off PAX / @LongLink prefix blocks until we see
     * a regular entry. */
    char *long_name = NULL;
    char *long_link = NULL;
    pax_kv_t *per_entry = NULL;

    for (;;) {
        tar_header_t h;
        int rc = read_one_header(c, &h);
        if (rc < 0) { pax_kv_free(per_entry); free(long_name); free(long_link); return -1; }
        if (rc == 0) {
            pax_kv_free(per_entry); free(long_name); free(long_link);
            return 0;  /* end of archive */
        }

        char tf = h.typeflag;
        uint64_t size = tar_parse_numeric(h.size, sizeof h.size);

        if (tf == TF_GNU_LONGNAME || tf == TF_GNU_LONGLINK) {
            char *payload;
            if (read_payload(c, size, &payload) < 0) {
                pax_kv_free(per_entry); free(long_name); free(long_link); return -1;
            }
            if (tf == TF_GNU_LONGNAME) { free(long_name); long_name = payload; }
            else                       { free(long_link); long_link = payload; }
            continue;
        }
        if (tf == TF_PAX_FILE) {
            char *payload;
            if (read_payload(c, size, &payload) < 0) {
                pax_kv_free(per_entry); free(long_name); free(long_link); return -1;
            }
            pax_parse_records(payload, (size_t)size, &per_entry);
            free(payload);
            continue;
        }
        if (tf == TF_PAX_GLOBAL) {
            char *payload;
            if (read_payload(c, size, &payload) < 0) {
                pax_kv_free(per_entry); free(long_name); free(long_link); return -1;
            }
            pax_parse_records(payload, (size_t)size, &c->global_kv);
            free(payload);
            continue;
        }

        /* Regular entry. Populate from ustar header first. */
        if (long_name) {
            c->cur_name = long_name;
            long_name = NULL;
            out->name = c->cur_name;
            out->name_len = strlen(c->cur_name);
        } else if (h.prefix[0]) {
            size_t pl = strnlen(h.prefix, sizeof h.prefix);
            size_t nl = strnlen(h.name,   sizeof h.name);
            c->cur_name = (char *)malloc(pl + 1 + nl + 1);
            memcpy(c->cur_name, h.prefix, pl);
            c->cur_name[pl] = '/';
            memcpy(c->cur_name + pl + 1, h.name, nl);
            c->cur_name[pl + 1 + nl] = '\0';
            out->name = c->cur_name;
            out->name_len = pl + 1 + nl;
        } else {
            size_t nl = strnlen(h.name, sizeof h.name);
            c->cur_name = (char *)malloc(nl + 1);
            memcpy(c->cur_name, h.name, nl);
            c->cur_name[nl] = '\0';
            out->name = c->cur_name;
            out->name_len = nl;
        }

        if (long_link) {
            c->cur_link = long_link;
            long_link = NULL;
            out->link_target = c->cur_link;
            out->link_target_len = strlen(c->cur_link);
        } else if (h.linkname[0]) {
            size_t ll = strnlen(h.linkname, sizeof h.linkname);
            c->cur_link = (char *)malloc(ll + 1);
            memcpy(c->cur_link, h.linkname, ll);
            c->cur_link[ll] = '\0';
            out->link_target = c->cur_link;
            out->link_target_len = ll;
        }

        out->size  = size;
        out->mode  = (uint32_t)tar_parse_numeric(h.mode,  sizeof h.mode);
        out->uid   = (uint32_t)tar_parse_numeric(h.uid,   sizeof h.uid);
        out->gid   = (uint32_t)tar_parse_numeric(h.gid,   sizeof h.gid);
        out->mtime =            tar_parse_numeric(h.mtime, sizeof h.mtime);
        out->mtime_ns = 0;
        out->type  = typeflag_to_ae(tf);

        /* Apply globals first, then per-entry PAX overrides. */
        if (c->global_kv) apply_pax_to_entry(c, c->global_kv, out);
        if (per_entry)    apply_pax_to_entry(c, per_entry, out);
        pax_kv_free(per_entry);

        if (c->cur_xattr_count) {
            out->xattrs = c->cur_xattrs;
            out->xattr_count = c->cur_xattr_count;
        }

        /* Set up payload bookkeeping. */
        c->entry_remaining = (out->type == AE_FILE) ? out->size : 0;
        if (out->type != AE_FILE) {
            /* Some producers emit a non-zero size for non-files (rare); skip the bytes. */
            c->entry_remaining = out->size;
        }
        c->entry_pad = c->entry_remaining
            ? (TAR_BLOCK_SIZE - (c->entry_remaining % TAR_BLOCK_SIZE)) % TAR_BLOCK_SIZE
            : 0;

        return 1;
    }
}

static int
tar_read_data(pTHX_ const ArchivePlugin *self, void *cursor, char *buf, size_t len)
{
    PERL_UNUSED_ARG(self);
    tar_cursor_t *c = (tar_cursor_t *)cursor;
    if (c->entry_remaining == 0) return 0;
    size_t take = (c->entry_remaining < len) ? (size_t)c->entry_remaining : len;
    int n = read_full(c->pull, c->src, buf, take);
    if (n < (int)take) return -1;
    c->entry_remaining -= take;
    /* When the entry is exhausted, consume padding so next read_next
     * starts on a header boundary. */
    if (c->entry_remaining == 0 && c->entry_pad > 0) {
        char pad[TAR_BLOCK_SIZE];
        int pn = read_full(c->pull, c->src, pad, (size_t)c->entry_pad);
        if (pn < (int)c->entry_pad) return -1;
        c->entry_pad = 0;
    }
    return (int)take;
}

static void
tar_read_close(pTHX_ const ArchivePlugin *self, void *cursor)
{
    PERL_UNUSED_ARG(self);
    if (!cursor) return;
    tar_cursor_t *c = (tar_cursor_t *)cursor;
    pax_kv_free(c->global_kv);
    free_cur_buffers(c);
    free(c);
}

/* ============================================================
 * Write side
 * ============================================================ */

static int
parse_format_opt(pTHX_ HV *opts)
{
    if (!opts) return FMT_AUTO;
    SV **sv = hv_fetchs(opts, "format", 0);
    if (!sv || !*sv || !SvOK(*sv)) return FMT_AUTO;
    STRLEN n;
    const char *p = SvPV(*sv, n);
    if (n == 4 && memcmp(p, "auto",  4) == 0) return FMT_AUTO;
    if (n == 3 && memcmp(p, "pax",   3) == 0) return FMT_PAX;
    if (n == 3 && memcmp(p, "gnu",   3) == 0) return FMT_GNU;
    if (n == 5 && memcmp(p, "ustar", 5) == 0) return FMT_USTAR;
    return -1;
}

/* Returns 1 if this entry's name fits the ustar 100/256-byte limit. */
static int
ustar_name_fits(const ArchiveEntry *e)
{
    return e->name_len <= 100;
    /* (We could also try a prefix split; we leave that to PAX/@LongLink path.) */
}

static int
ustar_link_fits(const ArchiveEntry *e)
{
    return e->link_target_len <= 100;
}

static int
ustar_numeric_fits(uint64_t v, size_t field_n)
{
    /* field_n includes the trailing NUL: usable digits = field_n - 1. */
    uint64_t cap = 1;
    size_t i;
    for (i = 0; i < field_n - 1; i++) {
        if (cap > (UINT64_MAX >> 3)) return 1;
        cap <<= 3;
    }
    return v < cap;
}

static int
emit_block(tar_cursor_t *c, const char *block)
{
    return write_full(c->push, c->sink, block, TAR_BLOCK_SIZE);
}

static int
emit_padding_for(tar_cursor_t *c, uint64_t size)
{
    if (size == 0) return 0;
    size_t pad = (TAR_BLOCK_SIZE - (size_t)(size % TAR_BLOCK_SIZE)) % TAR_BLOCK_SIZE;
    if (!pad) return 0;
    char zeros[TAR_BLOCK_SIZE] = {0};
    return write_full(c->push, c->sink, zeros, pad);
}

/* Build a base ustar header into `h` (caller pre-zeroed). Truncates
 * fields to ustar limits; PAX/@LongLink override paths handled by the
 * caller. */
static void
build_ustar_header(tar_header_t *h, const ArchiveEntry *e, char typeflag, const char *override_name)
{
    const char *name = override_name ? override_name : e->name;
    size_t name_len = override_name ? strlen(override_name) : e->name_len;
    size_t cpy = name_len > sizeof h->name ? sizeof h->name : name_len;
    memcpy(h->name, name, cpy);

    if (e->link_target && e->link_target_len) {
        size_t llen = e->link_target_len;
        if (llen > sizeof h->linkname) llen = sizeof h->linkname;
        memcpy(h->linkname, e->link_target, llen);
    }

    tar_emit_numeric(h->mode,  sizeof h->mode,  (uint64_t)(e->mode  ? e->mode  : 0644));
    tar_emit_numeric(h->uid,   sizeof h->uid,   (uint64_t)e->uid);
    tar_emit_numeric(h->gid,   sizeof h->gid,   (uint64_t)e->gid);
    tar_emit_numeric(h->size,  sizeof h->size,  e->size);
    tar_emit_numeric(h->mtime, sizeof h->mtime, e->mtime);

    h->typeflag = typeflag;
    memcpy(h->magic, "ustar", 5);
    h->version[0] = '0';
    h->version[1] = '0';

    /* checksum: fill chksum field with spaces, compute, then write. */
    memset(h->chksum, ' ', sizeof h->chksum);
    uint32_t sum = tar_compute_checksum(h);
    /* chksum is 6 octal digits + NUL + space per convention. */
    char tmp[8];
    snprintf(tmp, sizeof tmp, "%06o", (unsigned)sum);
    memcpy(h->chksum, tmp, 6);
    h->chksum[6] = '\0';
    h->chksum[7] = ' ';
}

/* Emit a GNU @LongLink block carrying `payload` of `payload_len` bytes
 * with the given flag (TF_GNU_LONGNAME or TF_GNU_LONGLINK). */
static int
emit_gnu_longlink(tar_cursor_t *c, char flag, const char *payload, size_t payload_len)
{
    tar_header_t h;
    memset(&h, 0, sizeof h);
    /* @LongLink "filename" is the literal `././@LongLink`. */
    strcpy(h.name, "././@LongLink");
    tar_emit_numeric(h.mode,  sizeof h.mode,  0644);
    tar_emit_numeric(h.size,  sizeof h.size,  (uint64_t)payload_len);
    tar_emit_numeric(h.mtime, sizeof h.mtime, 0);
    h.typeflag = flag;
    /* GNU magic is "ustar  " (5 + space + space). */
    memcpy(h.magic, "ustar ", 6);
    h.version[0] = ' ';
    h.version[1] = '\0';
    memset(h.chksum, ' ', sizeof h.chksum);
    uint32_t sum = tar_compute_checksum(&h);
    char tmp[8];
    snprintf(tmp, sizeof tmp, "%06o", (unsigned)sum);
    memcpy(h.chksum, tmp, 6);
    h.chksum[6] = '\0';
    h.chksum[7] = ' ';
    if (emit_block(c, (char *)&h) < 0) return -1;
    /* Payload with trailing NUL, padded to block boundary. */
    if (write_full(c->push, c->sink, payload, payload_len) < 0) return -1;
    if (emit_padding_for(c, payload_len) < 0) return -1;
    return 0;
}

/* Emit a PAX 'x' header carrying the given pre-built records buffer. */
static int
emit_pax_header(tar_cursor_t *c, char flag, const ArchiveEntry *e,
                const char *records, size_t records_len)
{
    tar_header_t h;
    memset(&h, 0, sizeof h);
    /* Conventional PAX header name: <dirname>/PaxHeaders/<basename>. */
    char name[100];
    const char *base = e ? e->name : "";
    size_t base_len = e ? e->name_len : 0;
    const char *slash = base ? (const char *)memchr(base, '/', base_len) : NULL;
    /* Find LAST slash. */
    if (base) {
        const char *p;
        slash = NULL;
        for (p = base; p < base + base_len; p++) if (*p == '/') slash = p;
    }
    if (slash) {
        size_t dirlen = slash - base;
        size_t baselen = base_len - dirlen - 1;
        snprintf(name, sizeof name, "%.*s/PaxHeaders/%.*s",
                 (int)dirlen, base, (int)baselen, slash + 1);
    } else if (e) {
        snprintf(name, sizeof name, "PaxHeaders/%.*s", (int)base_len, base);
    } else {
        snprintf(name, sizeof name, "PaxHeaders/global.%d", c->pax_header_seq++);
    }
    name[sizeof name - 1] = '\0';
    strncpy(h.name, name, sizeof h.name);

    tar_emit_numeric(h.mode,  sizeof h.mode,  0644);
    tar_emit_numeric(h.size,  sizeof h.size,  (uint64_t)records_len);
    tar_emit_numeric(h.mtime, sizeof h.mtime, 0);
    h.typeflag = flag;
    memcpy(h.magic, "ustar", 5);
    h.version[0] = '0';
    h.version[1] = '0';
    memset(h.chksum, ' ', sizeof h.chksum);
    uint32_t sum = tar_compute_checksum(&h);
    char tmp[8];
    snprintf(tmp, sizeof tmp, "%06o", (unsigned)sum);
    memcpy(h.chksum, tmp, 6);
    h.chksum[6] = '\0';
    h.chksum[7] = ' ';
    if (emit_block(c, (char *)&h) < 0) return -1;
    if (write_full(c->push, c->sink, records, records_len) < 0) return -1;
    if (emit_padding_for(c, records_len) < 0) return -1;
    return 0;
}

/* Build PAX records from an entry. Returns malloced buffer; *out_len
 * set. Caller frees. The `force_all` flag: if 1, emit records for
 * every applicable field regardless of whether ustar would have fit
 * (used for format=pax). */
static int
build_pax_for_entry(const ArchiveEntry *e, char **out, size_t *out_len, int force_all)
{
    /* Worst-case size: each record at most 32 + key + value + a few bytes.
     * Aggregate xattr sizes and pad. */
    size_t cap = 256;
    size_t i;
    if (e->name_len > 100 || force_all) cap += 32 + 8 + e->name_len;
    if (e->link_target_len > 100 || force_all) cap += 32 + 12 + e->link_target_len;
    if (!ustar_numeric_fits(e->size, sizeof ((tar_header_t *)0)->size) || force_all) cap += 64;
    if (e->mtime_ns) cap += 64;
    if (!ustar_numeric_fits(e->uid, sizeof ((tar_header_t *)0)->uid) || force_all) cap += 32;
    if (!ustar_numeric_fits(e->gid, sizeof ((tar_header_t *)0)->gid) || force_all) cap += 32;
    for (i = 0; i < e->xattr_count; i++) {
        cap += 64 + 32 + e->xattrs[i].key_len + e->xattrs[i].value_len * 2 + 16;
    }
    if (cap < 4096) cap = 4096;
    char *buf = (char *)malloc(cap);
    if (!buf) return -1;
    size_t pos = 0;
    char tmp[64];

    if (e->name_len > 100 || force_all) {
        char *rec = buf + pos;
        pos += pax_build_record(rec, "path", e->name, e->name_len);
    }
    if ((e->link_target_len > 100 && e->link_target_len) || (force_all && e->link_target_len)) {
        pos += pax_build_record(buf + pos, "linkpath", e->link_target, e->link_target_len);
    }
    if (!ustar_numeric_fits(e->size, sizeof ((tar_header_t *)0)->size) || force_all) {
        int n = snprintf(tmp, sizeof tmp, "%llu", (unsigned long long)e->size);
        pos += pax_build_record(buf + pos, "size", tmp, (size_t)n);
    }
    if (e->mtime_ns) {
        int n = snprintf(tmp, sizeof tmp, "%llu.%09u",
                         (unsigned long long)e->mtime, (unsigned)e->mtime_ns);
        pos += pax_build_record(buf + pos, "mtime", tmp, (size_t)n);
    }
    if (!ustar_numeric_fits(e->uid, sizeof ((tar_header_t *)0)->uid) || force_all) {
        int n = snprintf(tmp, sizeof tmp, "%u", (unsigned)e->uid);
        pos += pax_build_record(buf + pos, "uid", tmp, (size_t)n);
    }
    if (!ustar_numeric_fits(e->gid, sizeof ((tar_header_t *)0)->gid) || force_all) {
        int n = snprintf(tmp, sizeof tmp, "%u", (unsigned)e->gid);
        pos += pax_build_record(buf + pos, "gid", tmp, (size_t)n);
    }
    /* xattrs */
    for (i = 0; i < e->xattr_count; i++) {
        const ArchiveXattr *x = &e->xattrs[i];
        int b64 = needs_b64(x->value, x->value_len);
        char keybuf[300];
        snprintf(keybuf, sizeof keybuf, "SCHILY.xattr.%.*s%s",
                 (int)x->key_len, x->key, b64 ? ".b64" : "");
        if (b64) {
            char *enc = b64_encode(x->value, x->value_len);
            if (enc) {
                pos += pax_build_record(buf + pos, keybuf, enc, strlen(enc));
                free(enc);
            }
        } else {
            pos += pax_build_record(buf + pos, keybuf, x->value, x->value_len);
        }
    }

    *out = buf;
    *out_len = pos;
    return 0;
}

static int
tar_write_open(pTHX_ const ArchivePlugin *self, archive_push_fn push,
               void *sink, HV *opts, void **out_cursor)
{
    PERL_UNUSED_ARG(self);
    int fmt = parse_format_opt(aTHX_ opts);
    if (fmt < 0) return -1;
    tar_cursor_t *c = (tar_cursor_t *)calloc(1, sizeof *c);
    if (!c) return -1;
    c->push = push;
    c->sink = sink;
    c->format = fmt;

    /* PAX 'g' global header from opts.global_meta. */
    if (opts) {
        SV **gm = hv_fetchs(opts, "global_meta", 0);
        if (gm && *gm && SvROK(*gm) && SvTYPE(SvRV(*gm)) == SVt_PVHV) {
            HV *gh = (HV *)SvRV(*gm);
            char *records = (char *)malloc(4096);
            size_t rcap = 4096, rpos = 0;
            hv_iterinit(gh);
            HE *he;
            while ((he = hv_iternext(gh))) {
                I32 klen_i;
                const char *k = hv_iterkey(he, &klen_i);
                SV *v = hv_iterval(gh, he);
                STRLEN vlen;
                const char *vp = SvPV(v, vlen);
                size_t need = (size_t)klen_i + vlen + 64;
                if (rpos + need > rcap) {
                    while (rpos + need > rcap) rcap *= 2;
                    records = (char *)realloc(records, rcap);
                }
                /* Build using a NUL-terminated key (pax_build_record needs strlen). */
                char keybuf[256];
                memcpy(keybuf, k, klen_i);
                keybuf[klen_i] = '\0';
                rpos += pax_build_record(records + rpos, keybuf, vp, vlen);
            }
            if (rpos > 0) {
                if (emit_pax_header(c, TF_PAX_GLOBAL, NULL, records, rpos) < 0) {
                    free(records);
                    free(c);
                    return -1;
                }
            }
            free(records);
        }
    }

    *out_cursor = c;
    return 0;
}

static int
tar_write_add(pTHX_ const ArchivePlugin *self, void *cursor,
              const ArchiveEntry *entry, const char *content, size_t len)
{
    PERL_UNUSED_ARG(self);
    tar_cursor_t *c = (tar_cursor_t *)cursor;

    int needs_pax  = 0;
    int needs_gnu  = 0;
    int needs_long_name = !ustar_name_fits(entry);
    int needs_long_link = entry->link_target && !ustar_link_fits(entry);

    if (!ustar_numeric_fits(entry->size,  sizeof ((tar_header_t *)0)->size)
     || !ustar_numeric_fits(entry->uid,   sizeof ((tar_header_t *)0)->uid)
     || !ustar_numeric_fits(entry->gid,   sizeof ((tar_header_t *)0)->gid)
     || !ustar_numeric_fits(entry->mtime, sizeof ((tar_header_t *)0)->mtime)
     || entry->mtime_ns
     || entry->xattr_count) {
        needs_pax = 1;
    }

    if (c->format == FMT_USTAR) {
        if (needs_pax || needs_long_name || needs_long_link) return -1;
    } else if (c->format == FMT_GNU) {
        if (needs_pax) return -1;
        if (needs_long_name || needs_long_link) needs_gnu = 1;
    } else if (c->format == FMT_PAX) {
        needs_pax = 1;  /* force */
    } else { /* FMT_AUTO */
        if (needs_pax) needs_pax = 1;
        else if (needs_long_name || needs_long_link) needs_gnu = 1;
    }

    /* Emit GNU @LongLink prefix blocks (for name and/or linkpath). */
    if (needs_gnu) {
        if (needs_long_name && entry->name_len) {
            if (emit_gnu_longlink(c, TF_GNU_LONGNAME, entry->name, entry->name_len + 1) < 0) return -1;
        }
        if (needs_long_link && entry->link_target_len) {
            if (emit_gnu_longlink(c, TF_GNU_LONGLINK, entry->link_target, entry->link_target_len + 1) < 0) return -1;
        }
    }

    /* Emit PAX 'x' header. */
    if (needs_pax) {
        char *records;
        size_t rlen;
        if (build_pax_for_entry(entry, &records, &rlen, c->format == FMT_PAX) < 0) return -1;
        if (rlen > 0) {
            if (emit_pax_header(c, TF_PAX_FILE, entry, records, rlen) < 0) {
                free(records); return -1;
            }
        }
        free(records);
    }

    /* Emit ustar header. */
    tar_header_t h;
    memset(&h, 0, sizeof h);
    char typeflag;
    switch (entry->type) {
    case AE_DIR:      typeflag = TF_DIRECTORY; break;
    case AE_SYMLINK:  typeflag = TF_SYMLINK;   break;
    case AE_HARDLINK: typeflag = TF_HARDLINK;  break;
    case AE_FIFO:     typeflag = TF_FIFO;      break;
    case AE_CHAR:     typeflag = TF_CHAR;      break;
    case AE_BLOCK:    typeflag = TF_BLOCK;     break;
    default:          typeflag = TF_REGULAR;   break;
    }
    /* If name overflows ustar AND we're not using PAX/@LongLink, that's
     * an error. (Already handled above in format branches.) */
    const char *name_for_header = entry->name;
    char tnbuf[101];
    if (entry->name_len > 100) {
        /* Use a truncated stand-in; the real name is in PAX/@LongLink. */
        size_t cpy = 100;
        memcpy(tnbuf, entry->name, cpy);
        tnbuf[cpy] = '\0';
        name_for_header = tnbuf;
    }
    build_ustar_header(&h, entry, typeflag, name_for_header);
    if (emit_block(c, (char *)&h) < 0) return -1;

    /* Emit payload. */
    if (entry->size > 0 && content) {
        if (write_full(c->push, c->sink, content, (size_t)entry->size) < 0) return -1;
        if (emit_padding_for(c, entry->size) < 0) return -1;
    } else if (len > 0 && content) {
        if (write_full(c->push, c->sink, content, len) < 0) return -1;
        if (emit_padding_for(c, len) < 0) return -1;
    }

    return 0;
}

static int
tar_write_close(pTHX_ const ArchivePlugin *self, void *cursor)
{
    PERL_UNUSED_ARG(self);
    if (!cursor) return 0;
    tar_cursor_t *c = (tar_cursor_t *)cursor;
    char zeros[TAR_BLOCK_SIZE * 2] = {0};
    int rc = write_full(c->push, c->sink, zeros, sizeof zeros);
    pax_kv_free(c->global_kv);
    free(c);
    return rc;
}

/* ============================================================
 * Probe
 * ============================================================ */

static int
tar_probe(const char *bytes, size_t len)
{
    if (len < TAR_BLOCK_SIZE) return 0;
    const tar_header_t *h = (const tar_header_t *)bytes;
    if (memcmp(h->magic, "ustar", 5) == 0) {
        /* Verify checksum to weed out false positives. */
        uint32_t stored = (uint32_t)tar_parse_numeric(h->chksum, sizeof h->chksum);
        uint32_t actual = tar_compute_checksum(h);
        if (stored == actual) return 90;
        return 60;
    }
    /* Old-style: maybe still tar if checksum verifies. */
    uint32_t stored = (uint32_t)tar_parse_numeric(h->chksum, sizeof h->chksum);
    uint32_t actual = tar_compute_checksum(h);
    if (stored == actual && stored != 0) return 50;
    return 0;
}

/* ============================================================
 * Plugin descriptor
 * ============================================================ */

ArchivePlugin tar_plugin = {
    .name        = "tar",
    .probe       = tar_probe,
    .read_open   = tar_read_open,
    .read_next   = tar_read_next,
    .read_data   = tar_read_data,
    .read_close  = tar_read_close,
    .read_seek_to = NULL,
    .write_open  = tar_write_open,
    .write_add   = tar_write_add,
    .write_close = tar_write_close,
    .state       = NULL,
};
