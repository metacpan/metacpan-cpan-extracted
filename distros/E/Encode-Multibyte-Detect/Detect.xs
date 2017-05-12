#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "src/encode.c"
#include "src/encode.h"

MODULE = Encode::Multibyte::Detect      PACKAGE = Encode::Multibyte::Detect

bool
is_7bit(input)
        SV * input
    PREINIT:
        const char *str;
        STRLEN len;
    CODE:
        str = SvPVx(input, len);
        while (len) {
            if (*str & 0x80) break;
            str++; len--;
        }
        RETVAL = !len;
    OUTPUT:
        RETVAL

bool
is_valid_utf8(input)
        SV * input
    PREINIT:
        const char *str;
        int good, bad, strange;
        STRLEN len;
    CODE:
        str = SvPVx(input, len);
        utf8_check_mem(str, len, &good, &bad, &strange,
            ENC_CHECK_BREAK_ON_BAD);
        RETVAL = (good || strange) && !bad;
    OUTPUT:
        RETVAL

bool
is_strict_utf8(input)
        SV * input
    PREINIT:
        const char *str;
        int good, bad, strange;
        STRLEN len;
    CODE:
        str = SvPVx(input, len);
        utf8_check_mem(str, len, &good, &bad, &strange,
            ENC_CHECK_BREAK_ON_BAD | ENC_CHECK_BREAK_ON_STRANGE);
        RETVAL = good && !bad && !strange;
    OUTPUT:
        RETVAL

bool
is_valid_euc_cn(input)
        SV * input
    PREINIT:
        const char *str;
        int good, bad, strange;
        STRLEN len;
    CODE:
        str = SvPVx(input, len);
        euc_cn_check_mem(str, len, &good, &bad, &strange,
            ENC_CHECK_BREAK_ON_BAD);
        RETVAL = (good || strange) && !bad;
    OUTPUT:
        RETVAL

bool
is_valid_euc_jp(input)
        SV * input
    PREINIT:
        const char *str;
        int good, bad, strange;
        STRLEN len;
    CODE:
        str = SvPVx(input, len);
        euc_jp_check_mem(str, len, &good, &bad, &strange,
            ENC_CHECK_BREAK_ON_BAD);
        RETVAL = (good || strange) && !bad;
    OUTPUT:
        RETVAL

bool
is_valid_euc_kr(input)
        SV * input
    PREINIT:
        const char *str;
        int good, bad, strange;
        STRLEN len;
    CODE:
        str = SvPVx(input, len);
        euc_kr_check_mem(str, len, &good, &bad, &strange,
            ENC_CHECK_BREAK_ON_BAD);
        RETVAL = (good || strange) && !bad;
    OUTPUT:
        RETVAL

bool
is_valid_euc_tw(input)
        SV * input
    PREINIT:
        const char *str;
        int good, bad, strange;
        STRLEN len;
    CODE:
        str = SvPVx(input, len);
        euc_tw_check_mem(str, len, &good, &bad, &strange,
            ENC_CHECK_BREAK_ON_BAD);
        RETVAL = (good || strange) && !bad;
    OUTPUT:
        RETVAL
