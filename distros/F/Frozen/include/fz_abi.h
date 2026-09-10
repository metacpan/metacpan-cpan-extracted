#ifndef FZ_ABI_H
#define FZ_ABI_H

#include <stdint.h>

#define FZ_ABI_VERSION 1

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

typedef struct fz_abi {
    int abi_version;

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
} fz_abi;

#define FZ_NOHANDLE 0xFFFFFFFFu

#endif
