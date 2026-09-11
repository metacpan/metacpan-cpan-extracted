#ifndef FZ_ABI_H
#define FZ_ABI_H

#include <stdint.h>

#define FZ_ABI_VERSION 4

#ifndef FZ_CONTAINER_FWD
#define FZ_CONTAINER_FWD
typedef struct fz_container fz_container;
#endif

#define FZ_ABSENT 0
#define FZ_LEAF   1
#define FZ_BRANCH 2

enum {
    FZ_K_BAD   = -1,
    FZ_K_UNDEF = 0,
    FZ_K_FALSE = 1,
    FZ_K_TRUE  = 2,
    FZ_K_INT   = 3,
    FZ_K_UINT  = 4,
    FZ_K_NUM   = 5,
    FZ_K_STR   = 6,
    FZ_K_HASH  = 7,
    FZ_K_ARRAY = 8
};

#define FZ_ERR_OK        0
#define FZ_ERR_ENOENT  (-1)
#define FZ_ERR_SHORT   (-2)
#define FZ_ERR_MAGIC   (-3)
#define FZ_ERR_VERSION (-4)
#define FZ_ERR_ENDIAN  (-5)
#define FZ_ERR_OFFW    (-6)
#define FZ_ERR_TOTAL   (-7)
#define FZ_ERR_MAP     (-8)
#define FZ_ERR_OFF64   (-9)

typedef void (*fz_leaf_fn)(void *ud, const char **segs, const uint32_t *lens,
                           int depth, uint32_t node);

/* Build flags for `freeze` and `freeze_container`.
 *
 * These replaced a bare `int lossy_nv` in version 4, which is a CHANGED
 * SIGNATURE rather than an append - the one time this table has done that,
 * and the reason FZ_ABI_VERSION went to 4 rather than growing two more
 * entries that differ from the first pair by one argument. A consumer built
 * against 3 or earlier will not link against 4; check `>= 4` before calling
 * either. FZ_F_LOSSY_NV is 1, so a caller that used to pass 1 means what it
 * always meant.
 *
 * FZ_F_STRINGIFY stores every defined non-reference scalar as its STRING
 * form, whatever Perl thinks it is. A reader that returns text - a
 * translation catalogue, a config of labels - otherwise has to bridge the
 * gap itself, because JSON's 5 decodes to an IV and freezes as an integer,
 * and `str` answers NULL for it. undef is unaffected and stays undef: it has
 * no string form worth inventing. */
#define FZ_F_LOSSY_NV  1u
#define FZ_F_STRINGIFY 2u

typedef struct fz_abi {
    int abi_version;

    /* CALL THESE TWO AS `(FZ->open)(...)` AND `(FZ->close)(...)`, with the
     * member parenthesised. On Windows a perl built with PERL_IMPLICIT_SYS -
     * which Strawberry is - has XSUB.h turn `open` into PerlLIO_open and
     * `close` into PerlLIO_close, which iperlsys.h defines as function-like
     * macros. `FZ->close(c)` puts the name in front of `(`, the macro fires,
     * and the translation unit does not compile. `(FZ->close)` leaves the
     * name followed by `)`, where a function-like macro cannot fire.
     *
     * The declarations below are safe for the same reason, which is why this
     * header compiles everywhere and only call sites break - Frozen 0.01
     * shipped and failed on the Strawberry 5.42 smoker for exactly this, in
     * its own selftest. Defining NO_XSLOCKS before XSUB.h is the other way
     * out, but that is the consumer's whole translation unit to decide about,
     * and this is one pair of parentheses. */
    fz_container *(*open)(pTHX_ const char *path, int copy, int *err);

    fz_container *(*attach)(const char *bytes, STRLEN len, int *err);
    void          (*close)(pTHX_ fz_container *c);
    const char   *(*error)(int rc);

    uint32_t (*root)(const fz_container *c);

    int (*probe)(const fz_container *c, uint32_t node,
                 const char *key, STRLEN klen, uint32_t *out);

    uint32_t (*child)(const fz_container *c, uint32_t node,
                      const char *key, STRLEN klen);

    uint32_t (*path)(const fz_container *c, uint32_t node,
                     const char *path, STRLEN plen, char sep);

    int (*at)(const fz_container *c, uint32_t node, uint32_t i,
              uint32_t *out);

    int (*key_at)(const fz_container *c, uint32_t node, uint32_t i,
                  const char **key, STRLEN *klen, int *utf8);

    uint32_t (*count)(const fz_container *c, uint32_t node);

    int (*kind)(const fz_container *c, uint32_t node);

    const char *(*str)(const fz_container *c, uint32_t node,
                       STRLEN *len, int *utf8);
    int (*iv)(const fz_container *c, uint32_t node, IV *out);
    int (*uv)(const fz_container *c, uint32_t node, UV *out);
    int (*nv)(const fz_container *c, uint32_t node, NV *out);

    int (*walk)(const fz_container *c, uint32_t node,
                fz_leaf_fn cb, void *ud, UV *count);

    SV *(*sv_from_node)(pTHX_ fz_container *c, uint32_t node);

    SV *(*freeze)(pTHX_ SV *data, unsigned flags, const char *flatsep);

    fz_container *(*freeze_container)(pTHX_ SV *data, unsigned flags,
                                      const char *flatsep, int *err);

    uint32_t (*val_at)(const fz_container *c, uint32_t node, uint32_t i);

    /* ---- version 3: reading a block somebody else owns ---------------------
     *
     * `borrow` attaches to bytes WITHOUT COPYING THEM. `attach` copies, which
     * is right for a scalar the caller may free, and wrong for a page of shared
     * memory that outlives every reader and was put there so it would not be
     * duplicated.
     *
     * WHAT IT SAVES SCALES WITH THE BLOCK, because the copy is the only part
     * that does. Attaching costs a fixed overhead plus a memcpy; reading does
     * not care how big the block is. Measured through the Perl surface, which
     * carries more fixed cost than this entry does:
     *
     *        568 bytes    attach    144ns     read 55ns
     *      56 kilobytes   attach    796ns     read 55ns
     *     569 kilobytes   attach   6989ns     read 59ns
     *       3 megabytes   attach  38713ns     read 57ns
     *
     * So on a small block borrowing saves little, and on a table of any size it
     * saves nearly all of it. The second is the case shared memory exists for:
     * a block written once and read by every process, where a copy per reader
     * is the cost the arena was built to avoid.
     *
     * THE CALLER OWNS THE LIFETIME. The bytes must outlive the container and
     * nothing here can check that. Use it for a mapping you control.
     *
     * `release` is `close` without an interpreter, for a container that holds
     * no perl reference - which a borrowed one never does. It answers 0 and
     * does nothing for a container that does, because dropping an SV's
     * refcount needs a perl to drop it in; call (FZ->close) for those.
     *
     * `verify` walks the block and returns the number of nodes it reached, or
     * a negative FZ_E_* when the structure does not hold together. A block that
     * arrived through shared memory is the case this exists for: it can be
     * checked before it is trusted, which is the one thing a caller cannot do
     * with a structure somebody else wrote. It does NOT check the checksum -
     * that is the Perl surface's `verify`, and it is a separate O(n) pass.
     *
     * All three take no pTHX and no perl type, so they are callable from a
     * translation unit that has never included perl.h. Note that the REST of
     * this header is not: `pTHX_` and `STRLEN` appear above, so a consumer
     * still needs the perl headers to include it at all. */
    fz_container *(*borrow)(const void *bytes, size_t len, int *err);
    int           (*release)(fz_container *c);
    long          (*verify)(const fz_container *c);
} fz_abi;

#define FZ_NOHANDLE 0xFFFFFFFFu

#endif
