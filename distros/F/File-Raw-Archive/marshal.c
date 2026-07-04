/*
 * marshal.c - implementation of the parallel-job binary format.
 *
 * Pure C, no Perl dependency. Big-endian on the wire so behaviour is
 * stable across architectures (we already pay one byte-swap per int
 * on x86; the cost is negligible against the syscalls).
 */

#include "marshal.h"

#include <errno.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

/* ============================================================
 * Endian helpers
 * ============================================================ */

static void
put_u32(char *p, uint32_t v)
{
    p[0] = (char)((v >> 24) & 0xff);
    p[1] = (char)((v >> 16) & 0xff);
    p[2] = (char)((v >>  8) & 0xff);
    p[3] = (char)( v        & 0xff);
}

static uint32_t
get_u32(const char *p)
{
    return ((uint32_t)(unsigned char)p[0] << 24)
         | ((uint32_t)(unsigned char)p[1] << 16)
         | ((uint32_t)(unsigned char)p[2] <<  8)
         | ((uint32_t)(unsigned char)p[3]);
}

static void
put_u64(char *p, uint64_t v)
{
    put_u32(p,     (uint32_t)(v >> 32));
    put_u32(p + 4, (uint32_t)(v & 0xffffffffu));
}

static uint64_t
get_u64(const char *p)
{
    return ((uint64_t)get_u32(p)     << 32)
         | ((uint64_t)get_u32(p + 4));
}

/* ============================================================
 * Marshal (build payload)
 * ============================================================ */

int
marshal_job(const char *path, size_t path_len,
            const char *content, size_t content_len,
            uint32_t mode,
            uint64_t mtime, uint32_t mtime_ns,
            uint32_t uid, uint32_t gid,
            int apply_xattrs,
            const ArchiveXattr *xattrs, size_t xattr_count,
            char **out_payload, size_t *out_len)
{
    size_t total =
        4 + path_len + 1 +       /* path_len + path + NUL */
        4 + content_len +        /* content_len + content */
        4 +                      /* mode */
        8 + 4 +                  /* mtime + mtime_ns */
        4 + 4 +                  /* uid + gid */
        4 +                      /* apply_xattrs */
        4;                       /* xattr_count */

    size_t i;
    for (i = 0; i < xattr_count; i++) {
        total += 4 + xattrs[i].key_len + 1     /* key_len + key + NUL */
              +  4 + xattrs[i].value_len;      /* value_len + value */
    }

    char *buf = (char *)malloc(total);
    if (!buf) return -1;
    char *p = buf;

    put_u32(p, (uint32_t)path_len); p += 4;
    if (path_len) memcpy(p, path, path_len);
    p += path_len;
    *p++ = '\0';

    put_u32(p, (uint32_t)content_len); p += 4;
    if (content_len) memcpy(p, content, content_len);
    p += content_len;

    put_u32(p, mode); p += 4;
    put_u64(p, mtime); p += 8;
    put_u32(p, mtime_ns); p += 4;
    put_u32(p, uid); p += 4;
    put_u32(p, gid); p += 4;
    put_u32(p, (uint32_t)(apply_xattrs ? 1 : 0)); p += 4;
    put_u32(p, (uint32_t)xattr_count); p += 4;

    for (i = 0; i < xattr_count; i++) {
        put_u32(p, (uint32_t)xattrs[i].key_len); p += 4;
        if (xattrs[i].key_len) memcpy(p, xattrs[i].key, xattrs[i].key_len);
        p += xattrs[i].key_len;
        *p++ = '\0';
        put_u32(p, (uint32_t)xattrs[i].value_len); p += 4;
        if (xattrs[i].value_len) memcpy(p, xattrs[i].value, xattrs[i].value_len);
        p += xattrs[i].value_len;
    }

    *out_payload = buf;
    *out_len = total;
    return 0;
}

/* ============================================================
 * IO (length-prefixed wire transfer)
 * ============================================================ */

static int
write_full(int fd, const char *buf, size_t len)
{
    size_t put = 0;
    while (put < len) {
        ssize_t w = write(fd, buf + put, len - put);
        if (w < 0) {
            if (errno == EINTR) continue;
            return -1;
        }
        if (w == 0) { errno = EIO; return -1; }
        put += (size_t)w;
    }
    return 0;
}

static int
read_full(int fd, char *buf, size_t len)
{
    size_t got = 0;
    while (got < len) {
        ssize_t n = read(fd, buf + got, len - got);
        if (n < 0) {
            if (errno == EINTR) continue;
            return -1;
        }
        if (n == 0) return (int)got;   /* EOF */
        got += (size_t)n;
    }
    return (int)got;
}

int
marshal_send(int fd, const char *payload, size_t payload_len)
{
    char hdr[4];
    put_u32(hdr, (uint32_t)payload_len);
    if (write_full(fd, hdr, 4) < 0) return -1;
    if (write_full(fd, payload, payload_len) < 0) return -1;
    return 0;
}

/* ============================================================
 * Unmarshal (read job from fd)
 * ============================================================ */

#define MARSHAL_MAX_RECORD (256u * 1024u * 1024u)  /* 256 MiB sanity cap */

int
marshal_read_job(int fd, ParallelJob *out)
{
    char hdr[4];
    int n = read_full(fd, hdr, 4);
    if (n == 0) return 1;                /* clean EOF */
    if (n < 4)  return -1;               /* truncated header */

    uint32_t total = get_u32(hdr);
    if (total == 0 || total > MARSHAL_MAX_RECORD) return -1;

    char *arena = (char *)malloc(total);
    if (!arena) return -1;

    n = read_full(fd, arena, total);
    if (n != (int)total) { free(arena); return -1; }

    memset(out, 0, sizeof *out);
    out->_arena = arena;
    out->_arena_len = total;

    char *p = arena;
    char *end = arena + total;

    /* path */
    if (p + 4 > end) goto bad;
    out->path_len = get_u32(p); p += 4;
    if (p + out->path_len + 1 > end) goto bad;
    out->path = p;
    p += out->path_len + 1;            /* skip the NUL */

    /* content */
    if (p + 4 > end) goto bad;
    out->content_len = get_u32(p); p += 4;
    if (p + out->content_len > end) goto bad;
    out->content = p;
    p += out->content_len;

    /* fixed-shape metadata block */
    if (p + 4 + 8 + 4 + 4 + 4 + 4 + 4 > end) goto bad;
    out->mode         = get_u32(p); p += 4;
    out->mtime        = get_u64(p); p += 8;
    out->mtime_ns     = get_u32(p); p += 4;
    out->uid          = get_u32(p); p += 4;
    out->gid          = get_u32(p); p += 4;
    out->apply_xattrs = (int)get_u32(p); p += 4;
    out->xattr_count  = get_u32(p); p += 4;

    if (out->xattr_count > 0) {
        if (out->xattr_count > MARSHAL_MAX_RECORD / sizeof(ArchiveXattr)) goto bad;
        out->xattrs = (ArchiveXattr *)calloc(out->xattr_count, sizeof(ArchiveXattr));
        if (!out->xattrs) goto bad;
        size_t i;
        for (i = 0; i < out->xattr_count; i++) {
            if (p + 4 > end) goto bad;
            out->xattrs[i].key_len = get_u32(p); p += 4;
            if (p + out->xattrs[i].key_len + 1 > end) goto bad;
            out->xattrs[i].key = p;
            p += out->xattrs[i].key_len + 1;
            if (p + 4 > end) goto bad;
            out->xattrs[i].value_len = get_u32(p); p += 4;
            if (p + out->xattrs[i].value_len > end) goto bad;
            out->xattrs[i].value = p;
            p += out->xattrs[i].value_len;
        }
    }

    return 0;

bad:
    free(out->xattrs);
    free(arena);
    memset(out, 0, sizeof *out);
    return -1;
}

void
parallel_job_free(ParallelJob *j)
{
    if (!j) return;
    free(j->_arena);
    free(j->xattrs);
    memset(j, 0, sizeof *j);
}
