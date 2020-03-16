/* Jenkins Small Fast -- "A small noncryptographic PRNG"
 * http://burtleburtle.net/bob/rand/smallprng.html
 * https://www.pcg-random.org/posts/some-prng-implementations.html */

#include <stdint.h>

#include "jsf.h"

#define rot32(x, k) (((x) << (k)) | ((x) >> (32 - (k))))

struct ranctx {
    uint32_t a;
    uint32_t b;
    uint32_t c;
    uint32_t d;
};

struct ranctx ctx;

void raninit(uint32_t seed) {
    uint32_t i;
    ctx.a = 0xf1ea5eed, ctx.b = ctx.c = ctx.d = seed;
    for (i = 0; i < 20; ++i)
        ranval();
}

uint32_t ranval(void) {
    uint32_t e = ctx.a - rot32(ctx.b, 27);
    ctx.a      = ctx.b ^ rot32(ctx.c, 17);
    ctx.b      = ctx.c + ctx.d;
    ctx.c      = ctx.d + e;
    ctx.d      = e + ctx.a;
    return ctx.d;
}
