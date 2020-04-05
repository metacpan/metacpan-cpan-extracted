#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <assert.h>
#include <eav.h>
#include <eav/private.h>
#include <eav/private_email.h>
#if defined(__WIN32) && defined(EAV_EXTRA)
    #include <strndup.h>
#endif


extern eav_result_t *
is_6531_email  (const char *email,
                size_t length,
                bool tld_check)
{
    INIT_EAV_RESULT_T(result);
#ifdef EAV_EXTRA
    result->lpart = result->domain = NULL;
#endif
    char *ch = NULL;
    char *brs = NULL;
    char *bre = NULL;
    const char *end = email + length;

    /* see "private_email.h" */
    basic_email_check (email);

    result->rc = is_6531_local (email, ch);

    if (result->rc != EEAV_NO_ERROR)
        return result;

    brs = ch + 1;

    if (*brs != '[') {
        result->rc = is_utf8_domain (
            &(result->idn_rc),
            ch + 1,
            end,
            tld_check );

        if (result->rc >= 0) {
            result->is_domain = true;
#ifdef EAV_EXTRA
            result->lpart = strndup (email, brs - email - 1);
            result->domain = strndup (brs, end - brs);
#endif
        }

        return result;
    }

    /* seems to be an ip address */
    check_ip(); /* see private_email.h */

#ifdef EAV_EXTRA
    if (result->rc == EEAV_NO_ERROR) {
        result->lpart = strndup (email, brs - email - 1);
        result->domain = strndup (brs + 1, bre - brs - 1);
    }
#endif

    return result;
}
