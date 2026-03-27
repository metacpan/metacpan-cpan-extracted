#ifndef HORUS_UUID_H
#define HORUS_UUID_H

/*
 * horus_uuid.h - Core UUID generation: v1-v8, NIL, MAX
 *
 * All generators write into a 16-byte output buffer.
 * Version and variant bits are stamped last.
 */

#include <string.h>
#include <stdint.h>
#include <unistd.h>  /* getuid, getgid */

/* ── Version/variant stamping ───────────────────────────────────── */

static inline void horus_stamp_version_variant(unsigned char *uuid, int version) {
    uuid[6] = (uuid[6] & 0x0F) | ((unsigned char)(version) << 4);
    uuid[8] = (uuid[8] & 0x3F) | 0x80;
}

/* ── NIL UUID ───────────────────────────────────────────────────── */

static inline void horus_uuid_nil(unsigned char *out) {
    memset(out, 0x00, 16);
}

/* ── MAX UUID ───────────────────────────────────────────────────── */

static inline void horus_uuid_max(unsigned char *out) {
    memset(out, 0xFF, 16);
}

/* ── v4: Random ─────────────────────────────────────────────────── */

static inline void horus_uuid_v4(unsigned char *out) {
    horus_random_bytes(out, 16);
    horus_stamp_version_variant(out, 4);
}

/* ── v1: Time-based (Gregorian) ─────────────────────────────────── */

typedef struct {
    unsigned char node[6];
    uint16_t clock_seq;
    uint64_t last_time;
    int initialized;
} horus_v1_state_t;

static inline void horus_v1_init_state(horus_v1_state_t *state) {
    horus_random_bytes(state->node, 6);
    state->node[0] |= 0x01; /* multicast bit per RFC 9562 */
    {
        unsigned char cs[2];
        horus_random_bytes(cs, 2);
        state->clock_seq = ((uint16_t)(cs[0] & 0x3F) << 8) | (uint16_t)cs[1];
    }
    state->last_time = 0;
    state->initialized = 1;
}

static inline void horus_uuid_v1(unsigned char *out, horus_v1_state_t *state) {
    uint64_t ts;
    uint32_t time_low;
    uint16_t time_mid, time_hi;

    if (!state->initialized)
        horus_v1_init_state(state);

    ts = horus_gregorian_100ns();

    if (ts <= state->last_time) {
        state->clock_seq = (state->clock_seq + 1) & 0x3FFF;
    }
    state->last_time = ts;

    time_low = (uint32_t)(ts & 0xFFFFFFFF);
    time_mid = (uint16_t)((ts >> 32) & 0xFFFF);
    time_hi  = (uint16_t)((ts >> 48) & 0x0FFF);

    /* time_low: bytes 0-3 (big-endian) */
    out[0] = (unsigned char)(time_low >> 24);
    out[1] = (unsigned char)(time_low >> 16);
    out[2] = (unsigned char)(time_low >> 8);
    out[3] = (unsigned char)(time_low);
    /* time_mid: bytes 4-5 */
    out[4] = (unsigned char)(time_mid >> 8);
    out[5] = (unsigned char)(time_mid);
    /* time_hi_and_version: bytes 6-7 */
    out[6] = (unsigned char)(time_hi >> 8);
    out[7] = (unsigned char)(time_hi);
    /* clock_seq_hi_and_variant: byte 8 */
    out[8] = (unsigned char)(state->clock_seq >> 8);
    /* clock_seq_low: byte 9 */
    out[9] = (unsigned char)(state->clock_seq);
    /* node: bytes 10-15 */
    memcpy(out + 10, state->node, 6);

    horus_stamp_version_variant(out, 1);
}

/* ── v2: DCE Security ───────────────────────────────────────────── */

static inline void horus_uuid_v2(unsigned char *out, horus_v1_state_t *state,
                                  int domain, uint32_t id) {
    uint64_t ts;
    uint16_t time_mid, time_hi;

    if (!state->initialized)
        horus_v1_init_state(state);

    ts = horus_gregorian_100ns();
    state->last_time = ts;

    time_mid = (uint16_t)((ts >> 32) & 0xFFFF);
    time_hi  = (uint16_t)((ts >> 48) & 0x0FFF);

    /* Replace time_low with the identifier */
    out[0] = (unsigned char)(id >> 24);
    out[1] = (unsigned char)(id >> 16);
    out[2] = (unsigned char)(id >> 8);
    out[3] = (unsigned char)(id);
    /* time_mid: bytes 4-5 */
    out[4] = (unsigned char)(time_mid >> 8);
    out[5] = (unsigned char)(time_mid);
    /* time_hi_and_version: bytes 6-7 */
    out[6] = (unsigned char)(time_hi >> 8);
    out[7] = (unsigned char)(time_hi);
    /* clock_seq_hi replaced with local domain */
    out[8] = (unsigned char)(domain & 0xFF);
    /* clock_seq_low */
    out[9] = (unsigned char)(state->clock_seq & 0xFF);
    /* node: bytes 10-15 */
    memcpy(out + 10, state->node, 6);

    horus_stamp_version_variant(out, 2);
}

/* ── v3: MD5 namespace ──────────────────────────────────────────── */

static inline void horus_uuid_v3(unsigned char *out,
                                  const unsigned char *ns_bytes,
                                  const unsigned char *name, size_t name_len) {
    horus_md5_ctx ctx;
    unsigned char digest[16];

    horus_md5_init(&ctx);
    horus_md5_update(&ctx, ns_bytes, 16);
    horus_md5_update(&ctx, name, name_len);
    horus_md5_final(digest, &ctx);

    memcpy(out, digest, 16);
    horus_stamp_version_variant(out, 3);
}

/* ── v5: SHA-1 namespace ────────────────────────────────────────── */

static inline void horus_uuid_v5(unsigned char *out,
                                  const unsigned char *ns_bytes,
                                  const unsigned char *name, size_t name_len) {
    horus_sha1_ctx ctx;
    unsigned char digest[20];

    horus_sha1_init(&ctx);
    horus_sha1_update(&ctx, ns_bytes, 16);
    horus_sha1_update(&ctx, name, name_len);
    horus_sha1_final(digest, &ctx);

    memcpy(out, digest, 16);  /* first 16 bytes of SHA-1 */
    horus_stamp_version_variant(out, 5);
}

/* ── v6: Reordered time ─────────────────────────────────────────── */

typedef struct {
    unsigned char last[16]; /* last emitted v6 UUID for monotonic guarantee */
    int has_last;
} horus_v6_state_t;

static inline void horus_uuid_v6(unsigned char *out, horus_v1_state_t *v1state,
                                  horus_v6_state_t *v6state) {
    uint64_t ts;

    if (!v1state->initialized)
        horus_v1_init_state(v1state);

    ts = horus_gregorian_100ns();

    /* v6 reorders: most significant bits first for sorting
     * time_high (bits 59..28 of timestamp) -> bytes 0-3
     * time_mid  (bits 27..16) -> bytes 4-5
     * time_low  (bits 15..4)  -> byte 6 low nibble + byte 7 */

    out[0] = (unsigned char)(ts >> 52);
    out[1] = (unsigned char)(ts >> 44);
    out[2] = (unsigned char)(ts >> 36);
    out[3] = (unsigned char)(ts >> 28);
    out[4] = (unsigned char)(ts >> 20);
    out[5] = (unsigned char)(ts >> 12);
    out[6] = (unsigned char)((ts >> 4) & 0x0F);
    out[7] = (unsigned char)((ts << 4) & 0xF0);
    /* Fill remaining bits: clock_seq and node */
    out[8] = (unsigned char)(v1state->clock_seq >> 8);
    out[9] = (unsigned char)(v1state->clock_seq);
    memcpy(out + 10, v1state->node, 6);

    horus_stamp_version_variant(out, 6);

    /* Monotonic guarantee: if new UUID <= last, increment last and use that */
    if (v6state->has_last && memcmp(out, v6state->last, 16) <= 0) {
        int i, carry = 1;
        memcpy(out, v6state->last, 16);
        /* Increment bytes 8-15 (after version/variant fields) */
        for (i = 15; i >= 8 && carry; i--) {
            int val = (int)out[i] + carry;
            out[i] = (unsigned char)(val & 0xFF);
            carry = val >> 8;
        }
        /* Re-stamp variant (byte 8 top 2 bits) in case carry corrupted it */
        out[8] = (out[8] & 0x3F) | 0x80;
    }

    memcpy(v6state->last, out, 16);
    v6state->has_last = 1;
}

/* ── v7: Unix epoch time with monotonic counter ─────────────────── */

typedef struct {
    uint64_t last_ms;
    unsigned char last_rand[8]; /* bytes 8-15 of the last UUID (after variant) */
} horus_v7_state_t;

static inline void horus_uuid_v7(unsigned char *out, horus_v7_state_t *state) {
    uint64_t ms = horus_unix_epoch_ms();

    /* 48-bit timestamp: bytes 0-5 */
    out[0] = (unsigned char)(ms >> 40);
    out[1] = (unsigned char)(ms >> 32);
    out[2] = (unsigned char)(ms >> 24);
    out[3] = (unsigned char)(ms >> 16);
    out[4] = (unsigned char)(ms >> 8);
    out[5] = (unsigned char)(ms);

    if (ms == state->last_ms) {
        /* Same millisecond: increment the random portion for monotonicity */
        int i;
        int carry = 1;
        /* Increment bytes 8-15 (stored in last_rand) */
        for (i = 7; i >= 0 && carry; i--) {
            int val = (int)state->last_rand[i] + carry;
            state->last_rand[i] = (unsigned char)(val & 0xFF);
            carry = val >> 8;
        }
        /* rand_a: bytes 6-7 (12 bits after version) */
        if (carry) {
            /* Overflow: increment rand_a portion */
            unsigned char r[2];
            horus_random_bytes(r, 2);
            out[6] = r[0];
            out[7] = r[1];
            horus_random_bytes(state->last_rand, 8);
        } else {
            out[6] = state->last_rand[0];
            out[7] = state->last_rand[1];
        }
        memcpy(out + 8, state->last_rand + 2, 6);
    } else {
        /* New millisecond: fresh random */
        unsigned char r[10]; /* 2 for rand_a + 8 for rand_b */
        horus_random_bytes(r, 10);
        out[6] = r[0];
        out[7] = r[1];
        memcpy(out + 8, r + 2, 6);

        /* Save state */
        state->last_ms = ms;
        memcpy(state->last_rand, r, 8);
    }

    horus_stamp_version_variant(out, 7);

    /* Update saved state to reflect version/variant stamping */
    state->last_rand[0] = out[6];
    state->last_rand[1] = out[7];
    memcpy(state->last_rand + 2, out + 8, 6);
}

/* ── v8: Custom ─────────────────────────────────────────────────── */

static inline void horus_uuid_v8(unsigned char *out,
                                  const unsigned char *custom_data) {
    memcpy(out, custom_data, 16);
    horus_stamp_version_variant(out, 8);
}

#endif /* HORUS_UUID_H */
