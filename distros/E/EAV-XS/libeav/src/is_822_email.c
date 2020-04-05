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
is_822_email (const char *email, size_t length, bool tld_check)
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

    result->rc = is_822_local (email, ch);

    if (result->rc != EEAV_NO_ERROR)
        return result;

    brs = ch + 1;

    if (*brs != '[') {
        result->rc = is_ascii_domain (ch + 1, end);

        if (result->rc == EEAV_NO_ERROR) {
            result->is_domain = true;
#ifdef EAV_EXTRA
            result->lpart = strndup (email, brs - email - 1);
            result->domain = strndup (brs, end - brs);
#endif
            check_tld();
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
