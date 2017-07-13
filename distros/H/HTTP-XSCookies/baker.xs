#define PERL_NO_GET_CONTEXT     /* we want efficiency */
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"

#include <string.h>
#include "buffer.h"
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

/*
 * Given a name and a value, which can be a string or a hashref,
 * build a cookie with that data.
 */
static void build_cookie(pTHX_ SV* pname, SV* pvalue, Buffer* cookie)
{
    const char* cname = 0;
    STRLEN nlen = 0;
    const char* cvalue = 0;
    STRLEN vlen = 0;
    SV* ref = 0;
    HV* values = 0;
    SV** nval = 0;

    /* name not a valid string? bail out */
    if (!SvOK(pname) || !SvPOK(pname)) {
        return;
    }

    /* value not a valid scalar? bail out */
    if (!SvOK(pvalue)) {
        return;
    }

    cname = SvPV_const(pname, nlen);

    if (SvPOK(pvalue)) {
        /* value is a simple string */
        cvalue = SvPV_const(pvalue, vlen);
        cookie_put_string(cookie, cname, nlen, cvalue, vlen, 1);
        return;
    }

    /* value not a valid ref? bail out */
    if (!SvRV(pvalue)) {
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

    /* first store cookie name and value, URL-encoding both */
    cvalue = SvPV_const(*nval, vlen);
    cookie_put_string(cookie, cname, nlen, cvalue, vlen, 1);

    /* now iterate over all other values */
    hv_iterinit(values);
    while (nval) {
        SV* val = 0;
        I32 klen = 0;
        char* key = 0;
        HE* entry = hv_iternext(values);
        if (!entry) {
            /* no more hash keys */
            break;
        }

        key = hv_iterkey(entry, &klen);
        if (!key || klen <= 0) {
            /* invalid key */
            continue;
        }

        if (strcmp(key, COOKIE_NAME_VALUE) == 0) {
            /* already processed */
            continue;
        }

        vlen = 0;
        val = hv_iterval(values, entry);
        if (!SvOK(val)) {
            continue;
        }
        if (SvIOK(val) && !SvIV(val)) {
            continue;
        }

        cvalue = SvPV_const(val, vlen);
        if (cvalue == 0) {
            continue;
        }

        /* TODO: should we skip if cvalue is invalid / empty? */

        if      (strcasecmp(key, COOKIE_NAME_DOMAIN) == 0) {
            cookie_put_string (cookie, COOKIE_NAME_DOMAIN   , sizeof(COOKIE_NAME_DOMAIN)    - 1, cvalue, vlen, 0);
        } else if (strcasecmp(key, COOKIE_NAME_PATH      ) == 0) {
            cookie_put_string (cookie, COOKIE_NAME_PATH     , sizeof(COOKIE_NAME_PATH)      - 1, cvalue, vlen, 0);
        } else if (strcasecmp(key, COOKIE_NAME_MAX_AGE   ) == 0) {
            cookie_put_string (cookie, COOKIE_NAME_MAX_AGE  , sizeof(COOKIE_NAME_MAX_AGE)   - 1, cvalue, vlen, 0);
        } else if (strcasecmp(key, COOKIE_NAME_EXPIRES   ) == 0) {
            cookie_put_date (cookie, COOKIE_NAME_EXPIRES    , sizeof(COOKIE_NAME_EXPIRES)   - 1, cvalue);
        } else if (strcasecmp(key, COOKIE_NAME_SECURE    ) == 0) {
            cookie_put_boolean(cookie, COOKIE_NAME_SECURE   , sizeof(COOKIE_NAME_SECURE)    - 1, 1);
        } else if (strcasecmp(key, COOKIE_NAME_HTTP_ONLY ) == 0) {
            cookie_put_boolean(cookie, COOKIE_NAME_HTTP_ONLY, sizeof(COOKIE_NAME_HTTP_ONLY) - 1, 1);
        } else if (strcasecmp(key, COOKIE_NAME_SAME_SITE ) == 0) {
            cookie_put_string (cookie, COOKIE_NAME_SAME_SITE  , sizeof(COOKIE_NAME_SAME_SITE)   - 1, cvalue, vlen, 0);
        }
    }
}

/*
 * Given a string, parse it as a cookie into its component values
 * and return a hashref with them.
 */
static HV* parse_cookie(pTHX_ SV* pstr)
{
    /* we will always return a hashref, maybe empty */
    HV* hv = newHV();

    do {
        const char* cstr = 0;
        STRLEN slen = 0;
        Buffer cookie;
        Buffer name;
        Buffer value;

        /* string not valid? bail out */
        if (!SvOK(pstr) || !SvPOK(pstr)) {
            break;
        }

        /* empty string? bail out */
        cstr = SvPV_const(pstr, slen);
        if (!cstr || !slen) {
            break;
        }

        /* wrap a Buffer around this string, so that we can
         * more easily work with it */
        buffer_wrap(&cookie, cstr, slen);

        /* prepare memory for name / value buffers */
        buffer_init(&name , 0);
        buffer_init(&value, 0);

        while (1) {
            cookie_get_pair(&cookie, &name, &value);
            if (name.pos == 0) {
                /* got an empty name => ran out of data */
                break;
            }

            /* only first value seen for a name is kept */
            if (!hv_exists(hv, name.data, name.pos)) {
                SV* pval = newSVpv(value.data, value.pos);
                hv_store(hv, name.data, name.pos, pval, 0);
            }

            /* reset buffers for name / value, avoiding memory reallocation */
            buffer_reset(&name);
            buffer_reset(&value);
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
    RETVAL = newSVpv(cookie.data, cookie.pos);
    buffer_fini(&cookie);
  OUTPUT: RETVAL

SV*
crush_cookie(SV* str)
  CODE:
    RETVAL = newRV_noinc((SV *) parse_cookie(aTHX_ str));
  OUTPUT: RETVAL
