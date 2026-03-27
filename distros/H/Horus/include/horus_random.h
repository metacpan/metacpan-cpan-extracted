#ifndef HORUS_RANDOM_H
#define HORUS_RANDOM_H

/*
 * horus_random.h - Platform-native CSPRNG with pool buffering
 *
 * Strategy: arc4random_buf (macOS/BSD) > getrandom (Linux 3.17+) > /dev/urandom
 * A 4096-byte pool amortises syscall cost across ~256 UUID generations.
 */

#include <string.h>

/* ── Platform detection ─────────────────────────────────────────── */

#if defined(_WIN32) || defined(_WIN64)
#  define HORUS_HAVE_WIN32_CRYPT 1
#  ifndef WIN32_LEAN_AND_MEAN
#    define WIN32_LEAN_AND_MEAN
#  endif
#  include <windows.h>
   /* RtlGenRandom (SystemFunction036) — available since Windows XP */
#  ifdef __cplusplus
   extern "C"
#  endif
   BOOLEAN NTAPI SystemFunction036(PVOID, ULONG);
#  define RtlGenRandom SystemFunction036
#elif defined(__APPLE__) || defined(__FreeBSD__) || defined(__OpenBSD__) || defined(__NetBSD__)
#  define HORUS_HAVE_ARC4RANDOM 1
#  include <stdlib.h>
#elif defined(__linux__)
#  define HORUS_HAVE_GETRANDOM 1
#  include <sys/syscall.h>
#  include <unistd.h>
#  include <errno.h>
#  ifdef SYS_getrandom
#    define horus_getrandom(buf, len) syscall(SYS_getrandom, (buf), (len), 0)
#  else
#    undef HORUS_HAVE_GETRANDOM
#    define HORUS_HAVE_DEVURANDOM 1
#  endif
#else
#  define HORUS_HAVE_DEVURANDOM 1
#endif

#if defined(HORUS_HAVE_DEVURANDOM)
#  include <fcntl.h>
#  include <unistd.h>
#endif

/* ── Error handling ─────────────────────────────────────────────── */
/* HORUS_FATAL can be defined before including this header to override.
 * Perl XS modules define it as croak(); standalone C uses abort(). */
#ifndef HORUS_FATAL
#  include <stdio.h>
#  include <stdlib.h>
#  define HORUS_FATAL(msg) do { fprintf(stderr, "%s\n", (msg)); abort(); } while(0)
#endif

/* ── Low-level fill ─────────────────────────────────────────────── */

static void horus_fill_raw(unsigned char *buf, size_t len) {
#if defined(HORUS_HAVE_WIN32_CRYPT)
    /* RtlGenRandom takes ULONG, so fill in chunks if len > ULONG_MAX */
    while (len > 0) {
        ULONG chunk = (len > (size_t)0xFFFFFFFFUL) ? 0xFFFFFFFFUL : (ULONG)len;
        if (!RtlGenRandom(buf, chunk))
            HORUS_FATAL("Horus: RtlGenRandom failed");
        buf += chunk;
        len -= chunk;
    }
#elif defined(HORUS_HAVE_ARC4RANDOM)
    arc4random_buf(buf, len);
#elif defined(HORUS_HAVE_GETRANDOM)
    size_t done = 0;
    while (done < len) {
        long ret = horus_getrandom(buf + done, len - done);
        if (ret < 0) {
            if (errno == EINTR) continue;
            /* fallback to /dev/urandom on unexpected error */
            goto urandom_fallback;
        }
        done += (size_t)ret;
    }
    return;
urandom_fallback:
    {
#else
    {
#endif
#if defined(HORUS_HAVE_GETRANDOM) || defined(HORUS_HAVE_DEVURANDOM)
        static int fd = -1;
        if (fd < 0) {
            fd = open("/dev/urandom", O_RDONLY | O_CLOEXEC);
            if (fd < 0) {
                /* This should never happen on any modern Unix */
                HORUS_FATAL("Horus: cannot open /dev/urandom");
            }
        }
        {
            size_t done = 0;
            while (done < len) {
                ssize_t ret = read(fd, buf + done, len - done);
                if (ret < 0) {
                    if (errno == EINTR) continue;
                    HORUS_FATAL("Horus: read from /dev/urandom failed");
                }
                done += (size_t)ret;
            }
        }
    }
#endif
}

/* ── Random pool ────────────────────────────────────────────────── */

#define HORUS_POOL_SIZE 4096

static unsigned char horus_random_pool[HORUS_POOL_SIZE];
static int horus_pool_pos = HORUS_POOL_SIZE; /* start exhausted */

static inline void horus_pool_refill(void) {
    horus_fill_raw(horus_random_pool, HORUS_POOL_SIZE);
    horus_pool_pos = 0;
}

static inline void horus_random_bytes(unsigned char *buf, size_t len) {
    if (len >= HORUS_POOL_SIZE) {
        /* Large request: bypass pool */
        horus_fill_raw(buf, len);
        return;
    }
    if (horus_pool_pos + (int)len > HORUS_POOL_SIZE) {
        horus_pool_refill();
    }
    memcpy(buf, horus_random_pool + horus_pool_pos, len);
    horus_pool_pos += (int)len;
}

/* Fill a bulk buffer for batch UUID generation */
static inline void horus_random_bulk(unsigned char *buf, size_t len) {
    horus_fill_raw(buf, len);
}

#endif /* HORUS_RANDOM_H */
