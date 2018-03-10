#define PERL_NO_GET_CONTEXT     /* we want efficiency */
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"

#include <string.h>
#include "buffer.h"
#include "uri.h"
#include "cookie.h"

#if defined(_WIN32) || defined(_WIN64)
#define snprintf    _snprintf
#define vsnprintf   _vsnprintf
#define strcasecmp  _stricmp
#define strncasecmp _strnicmp
#else
#include <strings.h>
#endif


/*
 * Possible field names in a cookie.
 */
#define COOKIE_NAME_VALUE      "value"
#define COOKIE_NAME_DOMAIN     "Domain"
#define COOKIE_NAME_PATH       "Path"
#define COOKIE_NAME_MAX_AGE    "Max-Age"
#define COOKIE_NAME_EXPIRES    "Expires"
#define COOKIE_NAME_SECURE     "Secure"
#define COOKIE_NAME_HTTP_ONLY  "HttpOnly"
#define COOKIE_NAME_SAME_SITE  "SameSite"

static void get_encoded_value(pTHX_ SV* value, Buffer* encoded, int encode)
{
    SV* ref = 0;
    const char* vstr = 0;
    STRLEN vlen = 0;
    int j = 0;

    Buffer unencoded;
    buffer_reset(encoded);

    /* common case: just a string */
    if (!SvROK(value)) {
        vstr = SvPV_const(value, vlen);
        buffer_wrap(&unencoded, vstr, vlen);
        if (encode) {
            url_encode(&unencoded, encoded);
        } else {
            buffer_append_buf(encoded, &unencoded);
        }
        return;
    }

    /* less common case: a reference => multiple values */
    ref = SvRV(value);
    if (SvTYPE(ref) == SVt_PVAV) {
        AV* values = (AV*) ref;
        int top = av_tindex(values);
        int count = 0;
        buffer_init(&unencoded , 0);
        for (j = 0; j <= top; ++j) {
            SV** elem = av_fetch(values, j, 0);
            if (!SvOK(*elem) || !SvPOK(*elem)) {
                continue;
            }
            vstr = SvPV_const(*elem, vlen);
            if (count) {
                buffer_append_str(&unencoded, "&", 1);
            }
            buffer_append_str(&unencoded, vstr, vlen);
            ++count;
        }
        if (encode) {
            url_encode(&unencoded, encoded);
        } else {
            buffer_append_buf(encoded, &unencoded);
        }
        buffer_fini(&unencoded);
    }

    /* don't know (yet) how to deal with other ref types */
}

/*
 * Given a name and a value, which can be a string or a hashref,
 * build a cookie with that data.
 */
static void build_cookie(pTHX_ SV* pname, SV* pvalue, Buffer* cookie)
{
    const char* nstr = 0;
    STRLEN nlen = 0;
    const char* vstr = 0;
    STRLEN vlen = 0;
    SV* ref = 0;
    HV* values = 0;
    SV** nval = 0;
    Buffer encoded;

    /* name not a valid string? bail out */
    if (!SvOK(pname) || !SvPOK(pname)) {
        return;
    }

    /* value not a valid scalar? bail out */
    if (!SvOK(pvalue)) {
        return;
    }

    nstr = SvPV_const(pname, nlen);

    if (SvPOK(pvalue)) {
        /* value is a simple string */
        vstr = SvPV_const(pvalue, vlen);
        cookie_put_string(cookie, nstr, nlen, vstr, vlen, 1, 1);
        return;
    }

    /* value not a valid ref? bail out */
    if (!SvROK(pvalue)) {
        return;
    }

    /* value not a valid hashref? bail out */
    ref = SvRV(pvalue);
    if (SvTYPE(ref) != SVt_PVHV) {
        return;
    }
    values = (HV*) ref;

    /* value for name not there? bail out */
    nval = hv_fetch(values, COOKIE_NAME_VALUE, sizeof(COOKIE_NAME_VALUE) -1, 0);
    if (!nval) {
        return;
    }

    buffer_init(&encoded , 0);

    /* first store cookie name and value, URL-encoding both */
    get_encoded_value(aTHX_ *nval, &encoded, 1);
    cookie_put_string(cookie, nstr, nlen, encoded.data, encoded.wpos, 1, 0);

    /* now iterate over all other values */
    hv_iterinit(values);
    while (nval) {
        SV* value = 0;
        I32 klen = 0;
        char* kstr = 0;
        HE* entry = hv_iternext(values);
        if (!entry) {
            /* no more hash keys */
            break;
        }

        kstr = hv_iterkey(entry, &klen);
        if (!kstr || klen <= 0) {
            /* invalid key */
            continue;
        }

        if (strcmp(kstr, COOKIE_NAME_VALUE) == 0) {
            /* name was already processed */
            continue;
        }

        value = hv_iterval(values, entry);
        if (!SvOK(value)) {
            continue;
        }

        /* value could be a string or an array, so need to encode it */
        get_encoded_value(aTHX_ value, &encoded, 0);
        vstr = encoded.data;
        vlen = encoded.wpos;
        if (vstr == 0) {
            continue;
        }

        /* TODO: should we skip if vstr is invalid / empty? */

        if        (strcasecmp(kstr, COOKIE_NAME_DOMAIN) == 0) {
            cookie_put_string (cookie, COOKIE_NAME_DOMAIN   , sizeof(COOKIE_NAME_DOMAIN)      - 1, vstr, vlen, 0, 0);
        } else if (strcasecmp(kstr, COOKIE_NAME_PATH      ) == 0) {
            cookie_put_string (cookie, COOKIE_NAME_PATH     , sizeof(COOKIE_NAME_PATH)        - 1, vstr, vlen, 0, 0);
        } else if (strcasecmp(kstr, COOKIE_NAME_MAX_AGE   ) == 0) {
            cookie_put_string (cookie, COOKIE_NAME_MAX_AGE  , sizeof(COOKIE_NAME_MAX_AGE)     - 1, vstr, vlen, 0, 0);
        } else if (strcasecmp(kstr, COOKIE_NAME_EXPIRES   ) == 0) {
            cookie_put_date (cookie, COOKIE_NAME_EXPIRES    , sizeof(COOKIE_NAME_EXPIRES)     - 1, vstr, vlen);
        } else if (strcasecmp(kstr, COOKIE_NAME_SECURE    ) == 0) {
            cookie_put_boolean(cookie, COOKIE_NAME_SECURE   , sizeof(COOKIE_NAME_SECURE)      - 1, SvTRUE(value));
        } else if (strcasecmp(kstr, COOKIE_NAME_HTTP_ONLY ) == 0) {
            cookie_put_boolean(cookie, COOKIE_NAME_HTTP_ONLY, sizeof(COOKIE_NAME_HTTP_ONLY)   - 1, SvTRUE(value));
        } else if (strcasecmp(kstr, COOKIE_NAME_SAME_SITE ) == 0) {
            cookie_put_string (cookie, COOKIE_NAME_SAME_SITE  , sizeof(COOKIE_NAME_SAME_SITE) - 1, vstr, vlen, 0, 0);
        }
    }
    buffer_fini(&encoded);
}

static int search_char(char c, const Buffer* buf, int start)
{
    int pos = -1;
    unsigned int j = 0;
    for (j = start; j < buf->wpos; ++j) {
        if (buf->data[j] == c) {
            pos = j;
            break;
        }
    }
    return pos;
}

/*
 * Given a string, parse it as a cookie into its component values
 * and return a hashref with them.
 *
 * Some standard field names have no value associated:
 *
 *   Secure
 *   HttpOnly
 *
 * Parameter allow_no_value controls what we do:
 *
 * =0: ignore these names, as if they had not been specified
 * >0: always treat these names as having a value of undef
 */
static HV* parse_cookie(pTHX_ SV* pstr, int allow_no_value)
{
    /* we will always return a hashref, maybe empty */
    HV* hv = newHV();

    do {
        const char* cstr = 0;
        STRLEN clen = 0;
        Buffer cookie;
        Buffer name;
        Buffer value;

        /* string not valid? bail out */
        if (!SvOK(pstr) || !SvPOK(pstr)) {
            break;
        }

        /* empty string? bail out */
        cstr = SvPV_const(pstr, clen);
        if (!cstr || !clen) {
            break;
        }

        /* wrap a Buffer around this string, so that we can
         * more easily work with it */
        buffer_wrap(&cookie, cstr, clen);

        /* prepare memory for name / value buffers */
        buffer_init(&name , 0);
        buffer_init(&value, 0);

        while (1) {
            int equals = 0;
            int pos = 0;
            AV* array = 0;
            int key = 0;
            unsigned int ini = 0;
            unsigned int end = 0;
            SV* ref = 0;

            /* reset buffers for name / value, avoiding memory reallocation */
            buffer_reset(&name);
            buffer_reset(&value);

            /* get the pair name=value, return whether we saw an equals sign */
            equals = cookie_get_pair(&cookie, &name, &value);

            /* got an empty name => ran out of data */
            if (name.wpos == 0) {
                break;
            }

            /* only first value seen for a name is kept */
            if (hv_exists(hv, name.data, name.wpos)) {
                continue;
            }

            if (!equals) {
                /* didn't see an equal sign => name with no value */
                if (allow_no_value) {
                    /* store a name => undef pair*/
                    SV* nil = newSV(0);
                    hv_store(hv, name.data, name.wpos, nil, 0);
                }
                continue;
            }

            pos = search_char('&', &value, value.rpos);
            if (pos < 0) {
                /* no & chars? simple string */
                SV* str = newSVpvn(value.data, value.wpos);
                hv_store(hv, name.data, name.wpos, str, 0);
                continue;
            }

            /* & chars => create arrayref */
            array = newAV();
            end = pos;
            while (1) {
                SV* str = 0;
                if (ini >= value.wpos) {
                    break;
                }
                str = sv_2mortal(newSVpvn(value.data + ini, end - ini));
                if (av_store(array, key, str)) {
                    SvREFCNT_inc(str);
                }
                ++key;
                ini = ++end;
                pos = search_char('&', &value, end);
                end = pos < 0 ? value.wpos : pos;
            }
            ref = newRV_noinc((SV*) array);
            hv_store(hv, name.data, name.wpos, ref, 0);
        }

        /* release memory for name / value buffers */
        buffer_fini(&value);
        buffer_fini(&name );
    } while (0);

    return hv;
}


MODULE = HTTP::XSCookies        PACKAGE = HTTP::XSCookies
PROTOTYPES: DISABLE

#################################################################

SV*
bake_cookie(SV* name, SV* value)
  PREINIT:
    Buffer cookie;
  CODE:
    buffer_init(&cookie, 0);
    build_cookie(aTHX_ name, value, &cookie);
    RETVAL = newSVpvn(cookie.data, cookie.wpos);
    buffer_fini(&cookie);
  OUTPUT: RETVAL

SV*
crush_cookie(SV* str, ...)
  PREINIT:
    IV allow_no_value = 0;
  CODE:
    if (items > 1) {
        allow_no_value = SvIV(ST(1));
    }
    RETVAL = newRV_noinc((SV *) parse_cookie(aTHX_ str, allow_no_value));
  OUTPUT: RETVAL
