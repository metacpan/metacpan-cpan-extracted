#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"


#include <stdio.h>
#include <string.h>
#include "unicode/utypes.h"
#include "IBM_CODES/bocu1.c" /* not bocu1.h */

int
utf8_next_char_safe(uint8_t *s, int32_t i, int32_t len, int32_t *c)
{
    int rest = len - i;
    int codepoint = 0;
    uint8_t *p = s + i;

    if (/*i >= len || */*p == 0) {
        /* codepoint = 0; */
        codepoint = 0;
    } else if (rest >= 1 && *p <= 0x7f) {
        /* U+0000 - U+007F */
        codepoint = *p++;
    } else if (rest >= 2 && *p <= 0xdf) {
        /* U+0080 - U+07FF */
        codepoint = *p++ & 0x1f;
        if ((*p & 0xc0) != 0x80) goto bail;
        codepoint = (codepoint << 6) | (*p++ & 0x3f);
    } else if (rest >= 3 && *p <= 0xef) {
        /* U+0800 - U+FFFF */
        codepoint = *p++ & 0x0f;
        if ((*p & 0xc0) != 0x80) goto bail;
        codepoint = (codepoint << 6) | (*p++ & 0x3f);
        if ((*p & 0xc0) != 0x80) goto bail;
        codepoint = (codepoint << 6) | (*p++ & 0x3f);
    } else if (rest >= 4 && *p <= 0xf7) {
        codepoint = *p++ & 0x07;
        if ((*p & 0xc0) != 0x80) goto bail;
        codepoint = (codepoint << 6) | (*p++ & 0x3f);
        if ((*p & 0xc0) != 0x80) goto bail;
        codepoint = (codepoint << 6) | (*p++ & 0x3f);
        if ((*p & 0xc0) != 0x80) goto bail;
        codepoint = (codepoint << 6) | (*p++ & 0x3f);
    } else {
        goto bail;
    }
    goto end;

  bail:
    /* *c = 0; */
    return 0;
  end:
    *c = codepoint;
    return p - (s + i);
}

int
utf8_append_char_safe(uint8_t *p, int32_t room, int32_t c)
{
    if (c < 0) {
        return 0;
    } else if (c <= 0x0000007f) {
        *p++ = (uint8_t)c;
        return 1;
    } else if (c <= 0x000007ff) {
        *p++ = 0xc0 | (uint8_t)(c >> 6);
        *p++ = 0x80 | (uint8_t)(c & 0x3f);
        return 2;
    } else if (c <= 0x0000ffff) {
        *p++ = 0xe0 | (uint8_t)(c >> 12);
        *p++ = 0x80 | (uint8_t)((c >> 6) & 0x3f);
        *p++ = 0x80 | (uint8_t)(c & 0x3f);
        return 3;
    } else if (c <= 0x001fffff) {
        *p++ = 0xf0 | (uint8_t)(c >> 18);
        *p++ = 0x80 | (uint8_t)((c >> 12) & 0x3f);
        *p++ = 0x80 | (uint8_t)((c >> 6) & 0x3f);
        *p++ = 0x80 | (uint8_t)(c & 0x3f);
        return 4;
    } else {
        return 0;
    }
}

SV*
xs_from_bocu1_to_utf8(uint8_t *bocu1str, int bocu1_length)
{
    Bocu1Rx rx={ 0, 0, 0 };
    int32_t c, i, count;
    uint8_t *utf8_buf;
    int32_t utf8_buf_size = bocu1_length * 3 + 1, utf8_len = 0;
    SV* sv_utf8str;

    utf8_buf = (uint8_t *)malloc(utf8_buf_size);
    if (utf8_buf == NULL) {
        warn("Error: cannot allocate sufficient memory\n");
        goto bail;
    }
    *utf8_buf = '\0';

    for (i=0; i<bocu1_length; i++) {
        c = decodeBocu1(&rx, bocu1str[i]);
        if (c < -1) {
            croak("Error: from_bocu1_to_utf8 detects encoding error at string index %ld\n", i);
            goto bail;
        }
        if (c >= 0) {
            /* UTF8_APPEND_CHAR_SAFE(p, count, rest, c); */
            count = utf8_append_char_safe(utf8_buf + utf8_len, utf8_buf_size - utf8_len, c);
            if (count == 0) {
                warn("Error: buffer overflow\n");
                goto bail;
            }
            utf8_len += count;
        }
    }

    sv_utf8str = (SV*)newSVpv((char *)utf8_buf, utf8_len);
    free(utf8_buf);
    return sv_utf8str;
 bail:
    if (utf8_buf != NULL) free(utf8_buf);
    return NULL;
}

SV*
xs_from_utf8_to_bocu1(uint8_t *utf8str, int utf8_length)
{
    int32_t i, count, prev, c, packed;
    uint8_t *bocu1_buf, *p;
    int32_t bocu1_buf_size = utf8_length * 11/10 + 1;
    SV* sv_bocu1str;

    p = bocu1_buf = (uint8_t *)malloc(bocu1_buf_size);
    if (bocu1_buf == NULL) {
        return NULL;
    }
    *bocu1_buf = '\0';

    prev = 0;
    for (i=0; i<utf8_length;) {
        /* UTF8_NEXT_CHAR_SAFE(utf8str, i, utf8_length, c, FALSE); */
        count = utf8_next_char_safe(utf8str, i, utf8_length, &c);
        if (count == 0) {
            croak("Error: illegal UTF-8 code at string index %ld\n", i);
            goto bail;
        }
        if (c == 0) { /* || c==0xa || c==0xd) {*/
            break;
        }
        i += count;

        if (c == 0xfeff && i == 3) {
            /* ignore the signature byte sequence */
            /* 3 because U+feff = "\xef\xbb\xbf" in BOCU-1 */
            continue;
        }

        packed = encodeBocu1(&prev, c);
        count = BOCU1_LENGTH_FROM_PACKED(packed);
        switch(count) {
        case 4:
          *p++ = (uint8_t)(packed >> 24);
           /* fall down */
        case 3:
          *p++ = (uint8_t)(packed >> 16);
           /* fall down */
        case 2:
          *p++ = (uint8_t)(packed >> 8);
           /* fall down */
        case 1:
          *p++ = (uint8_t)packed;
           /* fall down */
        default:
          break;
        }
        /* p += count - 1; */
    }

    sv_bocu1str = (SV*)newSVpv((char *)bocu1_buf, p - bocu1_buf);
    free(bocu1_buf);
    return sv_bocu1str;
 bail:
    if (bocu1_buf != NULL) free(bocu1_buf);
    return NULL;
}

MODULE = Encode::BOCU1::XS		PACKAGE = Encode::BOCU1::XS		

SV*
encode(obj, utf8, check)
    SV* obj
    SV* utf8
    IV  check
  PROTOTYPE: $$;$
  PREINIT:
    SV* sv_bocu1_octet;
    char *utf8str;
    STRLEN bytes;
  CODE:
    utf8str = SvPV(utf8, bytes);
    sv_bocu1_octet = xs_from_utf8_to_bocu1((uint8_t *)utf8str, bytes);

    /* $_[1] = '' if $check; */ /* not implemented yet */
    RETVAL = sv_bocu1_octet;
  OUTPUT:
    RETVAL

SV*
decode(obj,str,check)
    SV* obj
    SV* str
    IV  check
  PROTOTYPE: $$;$
  PREINIT:
    char *bocu1_octet;
    SV* sv_utf8str;
    STRLEN bytes;
  CODE:
    bocu1_octet = SvPV(str, bytes);
    sv_utf8str = xs_from_bocu1_to_utf8((uint8_t *)bocu1_octet, bytes);
    SvUTF8_on(sv_utf8str);

    /* $_[1] = '' if $check; */ /* not implemented yet */
    RETVAL = sv_utf8str;
  OUTPUT:
    RETVAL
