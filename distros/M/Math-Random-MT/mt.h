#ifndef _MATH_MT_H_
#define _MATH_MT_H_

#if defined(_MSC_VER) && (_MSC_VER < 1600) // for MS Visual Studio prior to 2010
typedef unsigned __int32 uint32_t;
#elif defined(__linux__) || defined(__GLIBC__) || defined(__WIN32__) || defined(_MSC_VER) || defined(__APPLE__) || defined(__GNU__)
#include <stdint.h>
#elif defined(__osf__)
#include <inttypes.h>
#else
#include <sys/types.h>
#endif

enum { N = 624, M = 397 };

struct mt {
    uint32_t mt[N];
    int mti;
    uint32_t seed;
};

struct mt *mt_init(void);
void mt_free(struct mt *self);
uint32_t mt_get_seed(struct mt *self);
void mt_init_seed(struct mt *self, uint32_t seed);
void mt_setup_array(struct mt *self, uint32_t *array, int n);
double mt_genrand(struct mt *self);
uint32_t mt_genirand(struct mt *self);

#endif
