#ifndef FZ_FORMAT_H
#define FZ_FORMAT_H

#include "fz/fz_compat.h"

#define FZ_MAGIC0 'F'
#define FZ_MAGIC1 'R'
#define FZ_MAGIC2 'Z'
#define FZ_MAGIC3 'N'

#define FZ_FORMAT_VERSION 1
#define FZ_HEADER_SIZE    64
#define FZ_ENDIAN_PROBE   0x01020304u
#define FZ_OFFSET_WIDTH   4

#define FZ_FLAG_OFF64     0x1u
#define FZ_FLAG_INTERNED  0x2u
#define FZ_FLAG_FLATINDEX 0x4u

#define FZ_T_UNDEF 0u
#define FZ_T_FALSE 1u
#define FZ_T_TRUE  2u
#define FZ_T_INT   3u
#define FZ_T_UINT  4u
#define FZ_T_NUM   5u
#define FZ_T_STR   6u
#define FZ_T_HASH  7u
#define FZ_T_ARRAY 8u
#define FZ_T_MAX   8u

#define FZ_TAG_BITS  4
#define FZ_TAG_MASK  0xFu
#define FZ_ALIGN     8

#define FZ_MAX_BLOCK 0x7FFFFFF8u

#define FZ_MAX_DEPTH 256

#define FZ_SLOT(tag, off) ((uint32_t)((tag) | (((uint32_t)(off) >> 3) << FZ_TAG_BITS)))
#define FZ_SLOT_TAG(s)    ((uint32_t)((s) & FZ_TAG_MASK))
#define FZ_SLOT_OFF(s)    ((uint32_t)(((s) >> FZ_TAG_BITS) << 3))

static uint32_t fz_rd_u32(const unsigned char *p) {
    return (uint32_t)p[0] | ((uint32_t)p[1] << 8)
         | ((uint32_t)p[2] << 16) | ((uint32_t)p[3] << 24);
}

static void fz_wr_u32(unsigned char *p, uint32_t v) {
    p[0] = (unsigned char)(v & 0xff);
    p[1] = (unsigned char)((v >> 8) & 0xff);
    p[2] = (unsigned char)((v >> 16) & 0xff);
    p[3] = (unsigned char)((v >> 24) & 0xff);
}

#define FZ_H_MAGIC        0
#define FZ_H_VERSION      4
#define FZ_H_HEADER_SIZE  6
#define FZ_H_FLAGS        8
#define FZ_H_ENDIAN      12
#define FZ_H_OFFWIDTH    16
#define FZ_H_TOTAL       20
#define FZ_H_ROOT        24
#define FZ_H_SEED        28
#define FZ_H_STROFF      32
#define FZ_H_STRLEN      36
#define FZ_H_NODES       40
#define FZ_H_STRINGS     44
#define FZ_H_CHECKSUM    48
#define FZ_H_FLATIDX     52

#define FZ_E_BOUNDS   (-1)
#define FZ_E_ALIGN    (-2)
#define FZ_E_TAG      (-3)
#define FZ_E_COUNT    (-4)
#define FZ_E_DEPTH    (-5)

static long fz_walk_check(const unsigned char *b, uint32_t len,
                          uint32_t slot, int depth) {
    uint32_t tag = FZ_SLOT_TAG(slot);
    uint32_t off = FZ_SLOT_OFF(slot);
    long count = 1, sub;
    uint32_t n, i;

    if (depth > FZ_MAX_DEPTH) return FZ_E_DEPTH;
    if (tag > FZ_T_MAX)       return FZ_E_TAG;

    if (tag == FZ_T_UNDEF || tag == FZ_T_TRUE || tag == FZ_T_FALSE) return 1;

    if (off < FZ_HEADER_SIZE || off >= len) return FZ_E_BOUNDS;
    if (off & (FZ_ALIGN - 1))               return FZ_E_ALIGN;

    switch (tag) {
    case FZ_T_INT:
    case FZ_T_UINT:
    case FZ_T_NUM:
        if (off + 8 > len) return FZ_E_BOUNDS;
        return 1;

    case FZ_T_STR:
        if (off + 8 > len) return FZ_E_BOUNDS;
        n = fz_rd_u32(b + off);

        if (n > len || off + 8 + n + 1 > len) return FZ_E_BOUNDS;
        return 1;

    case FZ_T_ARRAY:
        if (off + 4 > len) return FZ_E_BOUNDS;
        n = fz_rd_u32(b + off);
        if (n > (len - off) / 4) return FZ_E_COUNT;
        if (off + 4 + n * 4 > len) return FZ_E_BOUNDS;
        for (i = 0; i < n; i++) {
            sub = fz_walk_check(b, len, fz_rd_u32(b + off + 4 + i * 4), depth + 1);
            if (sub < 0) return sub;
            count += sub;
        }
        return count;

    case FZ_T_HASH:
        if (off + 8 > len) return FZ_E_BOUNDS;
        n = fz_rd_u32(b + off);
        if (n > (len - off) / 8) return FZ_E_COUNT;
        if (off + 8 + n * 8 > len) return FZ_E_BOUNDS;
        for (i = 0; i < n; i++) {
            uint32_t koff = fz_rd_u32(b + off + 8 + i * 4);
            if (koff < FZ_HEADER_SIZE || koff + 8 > len) return FZ_E_BOUNDS;
            if (koff & (FZ_ALIGN - 1))                   return FZ_E_ALIGN;
            {
                uint32_t kl = fz_rd_u32(b + koff);
                if (kl > len || koff + 8 + kl + 1 > len) return FZ_E_BOUNDS;
            }
        }
        for (i = 0; i < n; i++) {
            sub = fz_walk_check(b, len,
                                fz_rd_u32(b + off + 8 + n * 4 + i * 4), depth + 1);
            if (sub < 0) return sub;
            count += sub;
        }
        return count;
    }
    return FZ_E_TAG;
}

static uint32_t fz_checksum(const unsigned char *b, uint32_t len) {
    uint32_t h = 2166136261u;
    uint32_t i;
    for (i = 0; i < len; i++) {
        unsigned char c = (i >= FZ_H_CHECKSUM && i < FZ_H_CHECKSUM + 4)
                        ? 0 : b[i];
        h ^= (uint32_t)c;
        h *= 16777619u;
    }
    return h;
}

#endif
