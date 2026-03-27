#ifndef HORUS_TIME_H
#define HORUS_TIME_H

/*
 * horus_time.h - Timestamp helpers for UUID generation
 *
 * Gregorian: 60-bit count of 100-nanosecond intervals since Oct 15, 1582
 * Unix epoch: 48-bit milliseconds since Jan 1, 1970
 */

#include <stdint.h>

#if defined(_WIN32) || defined(_WIN64)
#  ifndef WIN32_LEAN_AND_MEAN
#    define WIN32_LEAN_AND_MEAN
#  endif
#  include <windows.h>
   /* Windows FILETIME epoch (1601-01-01) to UUID epoch (1582-10-15)
      offset in 100-nanosecond intervals: 6653 days × 86400 × 10^7 */
#  define HORUS_WIN_TO_UUID_OFFSET UINT64_C(5748192000000000)
   /* Windows FILETIME epoch to Unix epoch (1970-01-01)
      offset in 100-nanosecond intervals */
#  define HORUS_WIN_TO_UNIX_OFFSET UINT64_C(116444736000000000)
#else
#  include <sys/time.h>
#endif

/* Offset between UUID epoch (1582-10-15) and Unix epoch (1970-01-01)
 * in 100-nanosecond intervals */
#define HORUS_UUID_EPOCH_OFFSET UINT64_C(0x01B21DD213814000)

/* ── Gregorian timestamp (for v1, v6) ───────────────────────────── */

static inline uint64_t horus_gregorian_100ns(void) {
#if defined(_WIN32) || defined(_WIN64)
    /* Windows FILETIME gives 100ns intervals since 1601-01-01.
       Convert to UUID epoch (1582-10-15) by subtracting the offset. */
    FILETIME ft;
    ULARGE_INTEGER ui;
    GetSystemTimeAsFileTime(&ft);
    ui.LowPart  = ft.dwLowDateTime;
    ui.HighPart = ft.dwHighDateTime;
    /* FILETIME_epoch + UUID_to_WIN offset = UUID epoch */
    return ui.QuadPart + HORUS_WIN_TO_UUID_OFFSET
         - HORUS_WIN_TO_UNIX_OFFSET + HORUS_UUID_EPOCH_OFFSET;
#elif defined(CLOCK_REALTIME) && !defined(__APPLE__)
    /* Use clock_gettime for nanosecond resolution where available */
    struct timespec ts;
    clock_gettime(CLOCK_REALTIME, &ts);
    return ((uint64_t)ts.tv_sec * 10000000ULL)
         + ((uint64_t)ts.tv_nsec / 100ULL)
         + HORUS_UUID_EPOCH_OFFSET;
#else
    /* Fallback: gettimeofday gives microsecond resolution */
    struct timeval tv;
    gettimeofday(&tv, NULL);
    return ((uint64_t)tv.tv_sec * 10000000ULL)
         + ((uint64_t)tv.tv_usec * 10ULL)
         + HORUS_UUID_EPOCH_OFFSET;
#endif
}

/* ── Unix epoch milliseconds (for v7) ──────────────────────────── */

static inline uint64_t horus_unix_epoch_ms(void) {
#if defined(_WIN32) || defined(_WIN64)
    FILETIME ft;
    ULARGE_INTEGER ui;
    GetSystemTimeAsFileTime(&ft);
    ui.LowPart  = ft.dwLowDateTime;
    ui.HighPart = ft.dwHighDateTime;
    /* Convert from Windows FILETIME (1601) to Unix epoch (1970) ms */
    return (ui.QuadPart - HORUS_WIN_TO_UNIX_OFFSET) / 10000ULL;
#else
    struct timeval tv;
    gettimeofday(&tv, NULL);
    return ((uint64_t)tv.tv_sec * 1000ULL) + ((uint64_t)tv.tv_usec / 1000ULL);
#endif
}

/* ── Extract Gregorian timestamp from v1 UUID bytes ─────────────── */

static inline uint64_t horus_extract_time_v1(const unsigned char *bytes) {
    /* v1 layout: time_low (bytes 0-3), time_mid (bytes 4-5),
     * time_hi_and_version (bytes 6-7, version in high nibble) */
    uint64_t time_low  = ((uint64_t)bytes[0] << 24) | ((uint64_t)bytes[1] << 16)
                       | ((uint64_t)bytes[2] << 8)  | (uint64_t)bytes[3];
    uint64_t time_mid  = ((uint64_t)bytes[4] << 8)  | (uint64_t)bytes[5];
    uint64_t time_hi   = ((uint64_t)(bytes[6] & 0x0F) << 8) | (uint64_t)bytes[7];

    return (time_hi << 48) | (time_mid << 32) | time_low;
}

/* ── Extract Gregorian timestamp from v6 UUID bytes ─────────────── */

static inline uint64_t horus_extract_time_v6(const unsigned char *bytes) {
    /* v6 layout: time_high (bytes 0-3), time_mid (bytes 4-5),
     * time_low_and_version (bytes 6-7, version in high nibble of byte 6) */
    uint64_t time_high = ((uint64_t)bytes[0] << 24) | ((uint64_t)bytes[1] << 16)
                       | ((uint64_t)bytes[2] << 8)  | (uint64_t)bytes[3];
    uint64_t time_mid  = ((uint64_t)bytes[4] << 8)  | (uint64_t)bytes[5];
    uint64_t time_low  = ((uint64_t)(bytes[6] & 0x0F) << 8) | (uint64_t)bytes[7];

    return (time_high << 28) | (time_mid << 12) | time_low;
}

/* ── Extract Unix epoch ms from v7 UUID bytes ───────────────────── */

static inline uint64_t horus_extract_time_v7(const unsigned char *bytes) {
    /* v7 layout: 48-bit Unix ms timestamp in bytes 0-5 */
    return ((uint64_t)bytes[0] << 40) | ((uint64_t)bytes[1] << 32)
         | ((uint64_t)bytes[2] << 24) | ((uint64_t)bytes[3] << 16)
         | ((uint64_t)bytes[4] << 8)  | (uint64_t)bytes[5];
}

/* ── Convert Gregorian 100ns ticks to Unix epoch seconds (NV) ──── */

static inline double horus_gregorian_to_unix(uint64_t ticks) {
    if (ticks < HORUS_UUID_EPOCH_OFFSET) return 0.0;
    return (double)(ticks - HORUS_UUID_EPOCH_OFFSET) / 10000000.0;
}

/* ── Convert Unix epoch ms to Unix epoch seconds (NV) ──────────── */

static inline double horus_ms_to_unix(uint64_t ms) {
    return (double)ms / 1000.0;
}

#endif /* HORUS_TIME_H */
