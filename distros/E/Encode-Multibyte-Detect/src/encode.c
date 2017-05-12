#include <string.h>
#include "encode.h"

enum check_state
{
    DEFAULT = 0,
    UTF8_1_1,
    UTF8_2_1, UTF8_2_2,
    UTF8_3_1, UTF8_3_2, UTF8_3_3,
    UTF8_4_1, UTF8_4_2, UTF8_4_3, UTF8_4_4,
    UTF8_5_1, UTF8_5_2, UTF8_5_3, UTF8_5_4, UTF8_5_5,
    EUC_1, EUC_2, EUC_3,
    EUC_TW_1, EUC_TW_2, EUC_TW_3
};

struct check
{
    enum check_state state;
    int good, bad, strange;
    wchar_t current;
};

static inline void utf8_check_next(struct check *ct, unsigned char c)
{
    if (!ct->state) {
        // 00-7F - normal chars
        if (!(c & 0x80)) return;

        // 80-BF - bad start char
        if ((c & 0xC0) == 0x80) {
            ct->bad++;
            ct->state = DEFAULT;
            return;
        }

        // C0-DF - 2-byte sequence
        if ((c & 0xE0) == 0xC0) {
            ct->current = c & 0x1F;
            ct->state = UTF8_1_1;
            return;
        }

        // E0-EF - 3-byte sequence
        if ((c & 0xF0) == 0xE0) {
            ct->current = c & 0x0F;
            ct->state = UTF8_2_1;
            return;
        }

        // F0-F7 - 4-byte sequence
        if ((c & 0xF8) == 0xF0) {
            ct->current = c & 0x07;
            ct->state = UTF8_3_1;
            return;
        }

        // F8-FB - 5-byte sequence
        if ((c & 0xFC) == 0xF8) {
            ct->current = c & 0x03;
            ct->state = UTF8_4_1;
            return;
        }

        // FC-FD - 6-byte sequence
        if ((c & 0xFE) == 0xFC) {
            ct->current = c & 0x01;
            ct->state = UTF8_5_1;
            return;
        }

        // FE-FF - normal chars
        return;
    }

    // all other - bad sequence
    if ((c & 0xC0) != 0x80) {
        ct->bad++;
        ct->state = DEFAULT;
        return;
    }

    ct->current = (ct->current << 6) | (c & 0x3F);

    // 0080-07FF
    if (ct->state == UTF8_1_1) {
        if (ct->current < 0x80) {
            ct->strange++;
        }
        else {
            ct->good++;
        }
        ct->state = DEFAULT;
        return;
    }

    // 0800-FFFF
    if (ct->state == UTF8_2_2) {
        if (ct->current < 0x0800 || (ct->current >= 0xD800 && ct->current <= 0xDFFF)) {
            ct->strange++;
        }
        else {
            ct->good++;
        }
        ct->state = DEFAULT;
        return;
    }

    // 00010000-001FFFFF
    if (ct->state == UTF8_3_3) {
        if (ct->current < 0x00010000 || ct->current > 0x0010FFFF) {
            ct->strange++;
        }
        else {
            ct->good++;
        }
        ct->state = DEFAULT;
        return;
    }

    // 00200000 - 7FFFFFFF
    if (ct->state == UTF8_4_4 || ct->state == UTF8_5_5) {
        ct->strange++;
        ct->state = DEFAULT;
        return;
    }

    ct->state++;
}

static inline void euc_cn_check_next(struct check *ct, unsigned char c)
{
    if (!ct->state) {
        // 00-7F - normal chars
        if (!(c & 0x80)) return;

        // A1-F7 - first byte
        if (c >= 0xA1 && c <= 0xF7) {
            ct->state = EUC_1;
            return;
        }

        // all other - bad sequence
        ct->bad++;
        ct->state = DEFAULT;
        return;
    }

    // A1-FE - second byte
    if (c >= 0xA1 && c <= 0xFE) {
        ct->good++;
        ct->state = DEFAULT;
        return;
    }

    // all other - bad sequence
    ct->bad++;
    ct->state = DEFAULT;
    return;
}

static inline void euc_jp_check_next(struct check *ct, unsigned char c)
{
    if (!ct->state) {
        // 00-7F - normal chars
        if (!(c & 0x80)) return;

        // A1-FE - first byte
        if (c >= 0xA1 && c <= 0xFE) {
            ct->state = EUC_1;
            return;
        }

        // 8E - first byte
        if (c == 0x8E) {
            ct->state = EUC_2;
            return;
        }

        // 8F - first byte
        if (c == 0x8F) {
            ct->state = EUC_3;
            return;
        }

        // all other - bad sequence
        ct->bad++;
        ct->state = DEFAULT;
        return;
    }

    // 8E XX sequence
    if (ct->state == EUC_2) {
        // A1-DF - second byte
        if (c >= 0xA1 && c <= 0xDF) {
            ct->good++;
            ct->state = DEFAULT;
            return;
        }

        // all other - bad sequence
        ct->bad++;
        ct->state = DEFAULT;
        return;
    }

    // 8F XX sequence
    if (ct->state == EUC_3) {
        // A1-FE - second byte
        if (c >= 0xA1 && c <= 0xFE) {
            ct->good++;
            ct->state = DEFAULT;
            return;
        }

        // all other - bad sequence
        ct->bad++;
        ct->state = DEFAULT;
        return;
    }

    // A1-FE - second byte
    if (c >= 0xA1 && c <= 0xFE) {
        ct->good++;
        ct->state = DEFAULT;
        return;
    }

    // all other - bad sequence
    ct->bad++;
    ct->state = DEFAULT;
    return;
}

static inline void euc_kr_check_next(struct check *ct, unsigned char c)
{
    if (!ct->state) {
        // 00-7F - normal chars
        if (!(c & 0x80)) return;

        // A1-FE - first byte
        if (c >= 0xA1 && c <= 0xFE) {
            ct->state = EUC_1;
            return;
        }

        // all other - bad sequence
        ct->bad++;
        ct->state = DEFAULT;
        return;
    }

    // A1-FE - second byte
    if (c >= 0xA1 && c <= 0xFE) {
        ct->good++;
        ct->state = DEFAULT;
        return;
    }

    // all other - bad sequence
    ct->bad++;
    ct->state = DEFAULT;
    return;
}

static inline void euc_tw_check_next(struct check *ct, unsigned char c)
{
    if (!ct->state) {
        // 00-7F - normal chars
        if (!(c & 0x80)) return;

        // A1-FE - first byte
        if (c >= 0xA1 && c <= 0xFE) {
            ct->state = EUC_1;
            return;
        }

        // 8E - first byte
        if (c == 0x8E) {
            ct->state = EUC_TW_1;
            return;
        }

        // all other - bad sequence
        ct->bad++;
        ct->state = DEFAULT;
        return;
    }

    // 8F XX XX XX - second byte
    if (ct->state == EUC_TW_1) {
        if (c >= 0xA1 && c <= 0xB0) {
            ct->state = EUC_TW_2;
            return;
        }

        // all other - bad sequence
        ct->bad++;
        ct->state = DEFAULT;
        return;
    }

    // 8F XX XX XX - third byte
    if (ct->state == EUC_TW_2) {
        if (c >= 0xA1 && c <= 0xFE) {
            ct->state = EUC_TW_3;
            return;
        }

        // all other - bad sequence
        ct->bad++;
        ct->state = DEFAULT;
        return;
    }

    // 8F XX XX XX - fourth byte
    if (ct->state == EUC_TW_3) {
        if (c >= 0xA1 && c <= 0xFE) {
            ct->good++;
            ct->state = DEFAULT;
            return;
        }

        // all other - bad sequence
        ct->bad++;
        ct->state = DEFAULT;
        return;
    }

    // A1-FE - second byte
    if (c >= 0xA1 && c <= 0xFE) {
        ct->good++;
        ct->state = DEFAULT;
        return;
    }

    // all other - bad sequence
    ct->bad++;
    ct->state = DEFAULT;
    return;
}

void utf8_check(const char* str, int *good, int *bad, int *strange, int flags)
{
    struct check ct;

    memset(&ct, 0, sizeof(ct));

    while (*str) {
        utf8_check_next(&ct, *(unsigned char*)str);
        if (((flags & ENC_CHECK_BREAK_ON_BAD) && ct.bad) ||
            ((flags & ENC_CHECK_BREAK_ON_STRANGE) && ct.strange))
                break;
        str++;
    }

    // unfinished sequence
    if (ct.state && !*str) ct.bad++;

    *good = ct.good;
    *bad = ct.bad;
    *strange = ct.strange;
}

void utf8_check_mem(const void* mem, size_t size, int *good, int *bad, int *strange, int flags)
{
    struct check ct;

    memset(&ct, 0, sizeof(ct));

    while (size) {
        utf8_check_next(&ct, *(unsigned char*)mem);
        if (((flags & ENC_CHECK_BREAK_ON_BAD) && ct.bad) ||
            ((flags & ENC_CHECK_BREAK_ON_STRANGE) && ct.strange))
                break;
        mem++;
        size--;
    }

    // unfinished sequence
    if (ct.state && !size) ct.bad++;

    *good = ct.good;
    *bad = ct.bad;
    *strange = ct.strange;
}

void euc_cn_check(const char* str, int *good, int *bad, int *strange, int flags)
{
    struct check ct;

    memset(&ct, 0, sizeof(ct));

    while (*str) {
        euc_cn_check_next(&ct, *(unsigned char*)str);
        if ((flags & ENC_CHECK_BREAK_ON_BAD) && ct.bad)
            break;
        str++;
    }

    // unfinished sequence
    if (ct.state && !*str) ct.bad++;

    *good = ct.good;
    *bad = ct.bad;
    *strange = 0;
}

void euc_cn_check_mem(const void* mem, size_t size, int *good, int *bad, int *strange, int flags)
{
    struct check ct;

    memset(&ct, 0, sizeof(ct));

    while (size) {
        euc_cn_check_next(&ct, *(unsigned char*)mem);
        if ((flags & ENC_CHECK_BREAK_ON_BAD) && ct.bad)
            break;
        mem++;
        size--;
    }

    // unfinished sequence
    if (ct.state && !size) ct.bad++;

    *good = ct.good;
    *bad = ct.bad;
    *strange = 0;
}

void euc_jp_check(const char* str, int *good, int *bad, int *strange, int flags)
{
    struct check ct;

    memset(&ct, 0, sizeof(ct));

    while (*str) {
        euc_jp_check_next(&ct, *(unsigned char*)str);
        if ((flags & ENC_CHECK_BREAK_ON_BAD) && ct.bad)
            break;
        str++;
    }

    // unfinished sequence
    if (ct.state && !*str) ct.bad++;

    *good = ct.good;
    *bad = ct.bad;
    *strange = 0;
}

void euc_jp_check_mem(const void* mem, size_t size, int *good, int *bad, int *strange, int flags)
{
    struct check ct;

    memset(&ct, 0, sizeof(ct));

    while (size) {
        euc_jp_check_next(&ct, *(unsigned char*)mem);
        if ((flags & ENC_CHECK_BREAK_ON_BAD) && ct.bad)
            break;
        mem++;
        size--;
    }

    // unfinished sequence
    if (ct.state && !size) ct.bad++;

    *good = ct.good;
    *bad = ct.bad;
    *strange = 0;
}

void euc_kr_check(const char* str, int *good, int *bad, int *strange, int flags)
{
    struct check ct;

    memset(&ct, 0, sizeof(ct));

    while (*str) {
        euc_kr_check_next(&ct, *(unsigned char*)str);
        if ((flags & ENC_CHECK_BREAK_ON_BAD) && ct.bad)
            break;
        str++;
    }

    // unfinished sequence
    if (ct.state && !*str) ct.bad++;

    *good = ct.good;
    *bad = ct.bad;
    *strange = 0;
}

void euc_kr_check_mem(const void* mem, size_t size, int *good, int *bad, int *strange, int flags)
{
    struct check ct;

    memset(&ct, 0, sizeof(ct));

    while (size) {
        euc_kr_check_next(&ct, *(unsigned char*)mem);
        if ((flags & ENC_CHECK_BREAK_ON_BAD) && ct.bad)
            break;
        mem++;
        size--;
    }

    // unfinished sequence
    if (ct.state && !size) ct.bad++;

    *good = ct.good;
    *bad = ct.bad;
    *strange = 0;
}

void euc_tw_check(const char* str, int *good, int *bad, int *strange, int flags)
{
    struct check ct;

    memset(&ct, 0, sizeof(ct));

    while (*str) {
        euc_tw_check_next(&ct, *(unsigned char*)str);
        if ((flags & ENC_CHECK_BREAK_ON_BAD) && ct.bad)
            break;
        str++;
    }

    // unfinished sequence
    if (ct.state && !*str) ct.bad++;

    *good = ct.good;
    *bad = ct.bad;
    *strange = 0;
}

void euc_tw_check_mem(const void* mem, size_t size, int *good, int *bad, int *strange, int flags)
{
    struct check ct;

    memset(&ct, 0, sizeof(ct));

    while (size) {
        euc_tw_check_next(&ct, *(unsigned char*)mem);
        if ((flags & ENC_CHECK_BREAK_ON_BAD) && ct.bad)
            break;
        mem++;
        size--;
    }

    // unfinished sequence
    if (ct.state && !size) ct.bad++;

    *good = ct.good;
    *bad = ct.bad;
    *strange = 0;
}
