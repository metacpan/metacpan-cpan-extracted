/*
 * sha_hw.c - SHA-1 and SHA-256 on the ARMv8 SHA instructions.
 *
 * Chosen at run time: the build always compiles these (the functions carry
 * their own target attribute where the compiler does not enable the feature
 * globally), and frh_hw_*_blocks() return them only when the CPU reports the
 * instructions. Anything else gets NULL and the portable code runs.
 */

#include "sha_hw.h"
#include <string.h>

#if !defined(FRH_NO_HW) && defined(__aarch64__) && (defined(__clang__) || defined(__GNUC__))
#  define FRH_HW_ARM 1
#  include <arm_neon.h>
#  if defined(__ARM_FEATURE_SHA2)
#    define FRH_TARGET_SHA2
#  elif defined(__clang__)
#    define FRH_TARGET_SHA2 __attribute__((target("sha2")))
#  else
#    define FRH_TARGET_SHA2 __attribute__((target("+sha2")))
#  endif
#  if defined(__APPLE__)
#    include <sys/sysctl.h>
#  elif defined(__linux__)
#    include <sys/auxv.h>
#    ifndef AT_HWCAP
#      define AT_HWCAP 16
#    endif
#  endif
#  ifndef HWCAP_SHA1
#    define HWCAP_SHA1 (1UL << 5)
#  endif
#  ifndef HWCAP_SHA2
#    define HWCAP_SHA2 (1UL << 6)
#  endif
#endif

#ifdef FRH_HW_ARM

static int
cpu_has(const char *apple_name, unsigned long linux_bit)
{
#  if defined(__APPLE__)
    int v = 0;
    size_t len = sizeof v;
    (void)linux_bit;
    if (sysctlbyname(apple_name, &v, &len, NULL, 0) != 0) return 0;
    return v != 0;
#  elif defined(__linux__)
    (void)apple_name;
    return (getauxval(AT_HWCAP) & linux_bit) != 0;
#  else
    (void)apple_name; (void)linux_bit;
#    if defined(__ARM_FEATURE_SHA2)
    return 1;     /* built for a CPU that has it */
#    else
    return 0;
#    endif
#  endif
}

static const uint32_t K256[64] = {
    0x428a2f98, 0x71374491, 0xb5c0fbcf, 0xe9b5dba5, 0x3956c25b, 0x59f111f1, 0x923f82a4, 0xab1c5ed5,
    0xd807aa98, 0x12835b01, 0x243185be, 0x550c7dc3, 0x72be5d74, 0x80deb1fe, 0x9bdc06a7, 0xc19bf174,
    0xe49b69c1, 0xefbe4786, 0x0fc19dc6, 0x240ca1cc, 0x2de92c6f, 0x4a7484aa, 0x5cb0a9dc, 0x76f988da,
    0x983e5152, 0xa831c66d, 0xb00327c8, 0xbf597fc7, 0xc6e00bf3, 0xd5a79147, 0x06ca6351, 0x14292967,
    0x27b70a85, 0x2e1b2138, 0x4d2c6dfc, 0x53380d13, 0x650a7354, 0x766a0abb, 0x81c2c92e, 0x92722c85,
    0xa2bfe8a1, 0xa81a664b, 0xc24b8b70, 0xc76c51a3, 0xd192e819, 0xd6990624, 0xf40e3585, 0x106aa070,
    0x19a4c116, 0x1e376c08, 0x2748774c, 0x34b0bcb5, 0x391c0cb3, 0x4ed8aa4a, 0x5b9cca4f, 0x682e6ff3,
    0x748f82ee, 0x78a5636f, 0x84c87814, 0x8cc70208, 0x90befffa, 0xa4506ceb, 0xbef9a3f7, 0xc67178f2
};

static inline uint32x4_t
load_be32x4(const unsigned char *p)
{
    return vreinterpretq_u32_u8(vrev32q_u8(vld1q_u8(p)));
}

/* Four rounds per step: msg[i & 3] holds W[4i .. 4i+3]; once used, it is
 * replaced by W[4i+16 ..], from the three that follow it. */
FRH_TARGET_SHA2 static void
sha256_blocks_arm(uint32_t *state, const unsigned char *p, size_t n)
{
    uint32x4_t abcd = vld1q_u32(state);
    uint32x4_t efgh = vld1q_u32(state + 4);

    while (n--) {
        uint32x4_t abcd0 = abcd, efgh0 = efgh;
        uint32x4_t msg[4];
        int i;
        msg[0] = load_be32x4(p);
        msg[1] = load_be32x4(p + 16);
        msg[2] = load_be32x4(p + 32);
        msg[3] = load_be32x4(p + 48);
        for (i = 0; i < 16; i++) {
            uint32x4_t wk = vaddq_u32(msg[i & 3], vld1q_u32(K256 + 4 * i));
            uint32x4_t prev = abcd;
            abcd = vsha256hq_u32(abcd, efgh, wk);
            efgh = vsha256h2q_u32(efgh, prev, wk);
            if (i < 12)
                msg[i & 3] = vsha256su1q_u32(vsha256su0q_u32(msg[i & 3], msg[(i + 1) & 3]),
                                             msg[(i + 2) & 3], msg[(i + 3) & 3]);
        }
        abcd = vaddq_u32(abcd, abcd0);
        efgh = vaddq_u32(efgh, efgh0);
        p += 64;
    }
    vst1q_u32(state, abcd);
    vst1q_u32(state + 4, efgh);
}

/* Four rounds per step: choose for 0-19, parity 20-39, majority 40-59,
 * parity 60-79; e for the next step comes from a before this one. */
FRH_TARGET_SHA2 static void
sha1_blocks_arm(uint32_t *state, const unsigned char *p, size_t n)
{
    static const uint32_t K[4] = { 0x5A827999, 0x6ED9EBA1, 0x8F1BBCDC, 0xCA62C1D6 };
    uint32x4_t abcd = vld1q_u32(state);
    uint32_t e = state[4];

    while (n--) {
        uint32x4_t abcd0 = abcd;
        uint32_t e0 = e;
        uint32x4_t msg[4];
        int i;
        msg[0] = load_be32x4(p);
        msg[1] = load_be32x4(p + 16);
        msg[2] = load_be32x4(p + 32);
        msg[3] = load_be32x4(p + 48);
        for (i = 0; i < 20; i++) {
            uint32x4_t wk = vaddq_u32(msg[i & 3], vdupq_n_u32(K[i / 5]));
            uint32_t e_next = vsha1h_u32(vgetq_lane_u32(abcd, 0));
            if (i < 5)        abcd = vsha1cq_u32(abcd, e, wk);
            else if (i < 10)  abcd = vsha1pq_u32(abcd, e, wk);
            else if (i < 15)  abcd = vsha1mq_u32(abcd, e, wk);
            else              abcd = vsha1pq_u32(abcd, e, wk);
            e = e_next;
            if (i < 16)
                msg[i & 3] = vsha1su1q_u32(vsha1su0q_u32(msg[i & 3], msg[(i + 1) & 3], msg[(i + 2) & 3]),
                                           msg[(i + 3) & 3]);
        }
        abcd = vaddq_u32(abcd, abcd0);
        e += e0;
        p += 64;
    }
    vst1q_u32(state, abcd);
    state[4] = e;
}

frh_blocks32_fn
frh_hw_sha256_blocks(void)
{
    return cpu_has("hw.optional.arm.FEAT_SHA256", HWCAP_SHA2) ? sha256_blocks_arm : NULL;
}

frh_blocks32_fn
frh_hw_sha1_blocks(void)
{
    return cpu_has("hw.optional.arm.FEAT_SHA1", HWCAP_SHA1) ? sha1_blocks_arm : NULL;
}

const char *
frh_hw_name(void)
{
    return "armv8";
}

#else  /* no hardware path in this build */

frh_blocks32_fn frh_hw_sha256_blocks(void) { return NULL; }
frh_blocks32_fn frh_hw_sha1_blocks(void)   { return NULL; }
const char *frh_hw_name(void) { return "portable"; }

#endif
