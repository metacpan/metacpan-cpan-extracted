#ifndef FZ_MAP_H
#define FZ_MAP_H

#include "fz/fz_format.h"

#ifdef _WIN32
#  include <windows.h>
#else
#  include <sys/types.h>
#  include <sys/stat.h>
#  include <sys/mman.h>
#  include <fcntl.h>
#  include <unistd.h>
#endif

#define FZ_SRC_MMAP   0
#define FZ_SRC_MALLOC 1
#define FZ_SRC_SV     2

#ifndef FZ_CONTAINER_FWD
#define FZ_CONTAINER_FWD
typedef struct fz_container fz_container;
#endif

struct fz_container {
    const unsigned char *base;
    size_t               len;
    int                  src;
    int                  borrow;
    SV                  *holder;
#ifdef _WIN32
    HANDLE               fh;
    HANDLE               mh;
#endif
};

#define FZ_OPEN_OK        0
#define FZ_OPEN_ENOENT  (-1)
#define FZ_OPEN_SHORT   (-2)
#define FZ_OPEN_MAGIC   (-3)
#define FZ_OPEN_VERSION (-4)
#define FZ_OPEN_ENDIAN  (-5)
#define FZ_OPEN_OFFW    (-6)
#define FZ_OPEN_TOTAL   (-7)
#define FZ_OPEN_MAP     (-8)
#define FZ_OPEN_OFF64   (-9)

static int fz_check_header(const unsigned char *b, size_t len) {
    uint32_t flags;
    if (len < FZ_HEADER_SIZE) return FZ_OPEN_SHORT;
    if (b[0] != FZ_MAGIC0 || b[1] != FZ_MAGIC1
     || b[2] != FZ_MAGIC2 || b[3] != FZ_MAGIC3) return FZ_OPEN_MAGIC;
    if ((b[FZ_H_VERSION] | (b[FZ_H_VERSION + 1] << 8)) != FZ_FORMAT_VERSION)
        return FZ_OPEN_VERSION;

    if (fz_rd_u32(b + FZ_H_ENDIAN) != FZ_ENDIAN_PROBE) return FZ_OPEN_ENDIAN;
    if (b[FZ_H_OFFWIDTH] != FZ_OFFSET_WIDTH)           return FZ_OPEN_OFFW;
    flags = fz_rd_u32(b + FZ_H_FLAGS);
    if (flags & FZ_FLAG_OFF64)                         return FZ_OPEN_OFF64;

    if (fz_rd_u32(b + FZ_H_TOTAL) != (uint32_t)len)    return FZ_OPEN_TOTAL;
    return FZ_OPEN_OK;
}

static const char *fz_open_error(int rc) {
    switch (rc) {
    case FZ_OPEN_ENOENT:  return "cannot be opened";
    case FZ_OPEN_SHORT:   return "is shorter than a header";
    case FZ_OPEN_MAGIC:   return "does not begin with FRZN";
    case FZ_OPEN_VERSION: return "is a format version this build does not read";
    case FZ_OPEN_ENDIAN:  return "was written on the other endianness";
    case FZ_OPEN_OFFW:    return "uses an offset width this build does not read";
    case FZ_OPEN_OFF64:   return "uses 64-bit offsets, which are reserved";
    case FZ_OPEN_TOTAL:   return "is truncated: total_size disagrees with its length";
    case FZ_OPEN_MAP:     return "cannot be mapped";
    default:              return "is not a Frozen block";
    }
}

static void fz_container_release(fz_container *c) {
    if (!c || !c->base) return;
#ifdef _WIN32
    if (c->src == FZ_SRC_MMAP) {
        UnmapViewOfFile((LPCVOID)c->base);
        if (c->mh != INVALID_HANDLE_VALUE) CloseHandle(c->mh);
        if (c->fh != INVALID_HANDLE_VALUE) CloseHandle(c->fh);
    }
#else
    if (c->src == FZ_SRC_MMAP) {
#  ifdef FZ_DEBUG_POISON

        (void)mmap((void *)c->base, c->len, PROT_NONE,
                   MAP_PRIVATE | MAP_ANON | MAP_FIXED, -1, 0);
#  else
        munmap((void *)c->base, c->len);
#  endif
    }
#endif
    if (c->src == FZ_SRC_MALLOC) free((void *)c->base);
    c->base = NULL;
    c->len  = 0;
}

static int fz_container_open(pTHX_ fz_container *c, const char *path,
                             int want_copy) {
    memset(c, 0, sizeof *c);
#ifdef _WIN32
    c->fh = INVALID_HANDLE_VALUE;
    c->mh = INVALID_HANDLE_VALUE;
#endif

    if (want_copy) {
        PerlIO *fh = PerlIO_open(path, "rb");
        Off_t sz;
        unsigned char *buf;
        if (!fh) return FZ_OPEN_ENOENT;
        PerlIO_seek(fh, 0, SEEK_END);
        sz = PerlIO_tell(fh);
        PerlIO_seek(fh, 0, SEEK_SET);
        if (sz < 0) { PerlIO_close(fh); return FZ_OPEN_SHORT; }
        buf = (unsigned char *)malloc((size_t)sz ? (size_t)sz : 1);
        if (!buf) { PerlIO_close(fh); return FZ_OPEN_MAP; }
        if (PerlIO_read(fh, buf, (Size_t)sz) != (SSize_t)sz) {
            free(buf); PerlIO_close(fh); return FZ_OPEN_SHORT;
        }
        PerlIO_close(fh);
        c->base = buf;
        c->len  = (size_t)sz;
        c->src  = FZ_SRC_MALLOC;
        return FZ_OPEN_OK;
    }

#ifdef _WIN32
    {
        HANDLE fh = CreateFileA(path, GENERIC_READ, FILE_SHARE_READ, NULL,
                                OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, NULL);
        LARGE_INTEGER sz;
        HANDLE mh;
        void *addr;
        if (fh == INVALID_HANDLE_VALUE) return FZ_OPEN_ENOENT;
        if (!GetFileSizeEx(fh, &sz) || sz.QuadPart == 0) {
            CloseHandle(fh); return FZ_OPEN_SHORT;
        }
        mh = CreateFileMappingA(fh, NULL, PAGE_READONLY, 0, 0, NULL);
        if (!mh) { CloseHandle(fh); return FZ_OPEN_MAP; }
        addr = MapViewOfFile(mh, FILE_MAP_READ, 0, 0, 0);
        if (!addr) { CloseHandle(mh); CloseHandle(fh); return FZ_OPEN_MAP; }
        c->base = (const unsigned char *)addr;
        c->len  = (size_t)sz.QuadPart;
        c->src  = FZ_SRC_MMAP;
        c->fh   = fh;
        c->mh   = mh;
        return FZ_OPEN_OK;
    }
#else
    {
        int fd = open(path, O_RDONLY);
        struct stat st;
        void *addr;
        if (fd < 0) return FZ_OPEN_ENOENT;
        if (fstat(fd, &st) != 0 || st.st_size <= 0) { close(fd); return FZ_OPEN_SHORT; }
        addr = mmap(NULL, (size_t)st.st_size, PROT_READ, MAP_PRIVATE, fd, 0);

        close(fd);
        if (addr == MAP_FAILED) return FZ_OPEN_MAP;
        c->base = (const unsigned char *)addr;
        c->len  = (size_t)st.st_size;
        c->src  = FZ_SRC_MMAP;
        return FZ_OPEN_OK;
    }
#endif
}

static int fz_container_attach_bytes(fz_container *c, const char *p, size_t len) {
    unsigned char *buf;
    memset(c, 0, sizeof *c);
#ifdef _WIN32
    c->fh = INVALID_HANDLE_VALUE;
    c->mh = INVALID_HANDLE_VALUE;
#endif
    buf = (unsigned char *)malloc(len ? len : 1);
    if (!buf) return FZ_OPEN_MAP;
    memcpy(buf, p, len);
    c->base = buf;
    c->len  = len;
    c->src  = FZ_SRC_MALLOC;
    return FZ_OPEN_OK;
}

static int fz_container_attach(pTHX_ fz_container *c, SV *sv) {
    STRLEN len;
    const char *p = SvPV(sv, len);
    return fz_container_attach_bytes(c, p, (size_t)len);
}

#endif
