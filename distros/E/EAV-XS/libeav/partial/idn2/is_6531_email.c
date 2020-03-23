#include <stdio.h>
#include <string.h>
#include <eav.h>
#include <eav/private.h>
#include <eav/private_email.h>


extern eav_result_t
is_6531_email  (const char *email,
                size_t length,
                bool tld_check)
{
    eav_result_t result = INIT_EAV_RESULT_T();
    char *ch = NULL;
    char *brs = NULL;
    char *bre = NULL;
    const char *end = email + length;

    /* see "private_email.h" */
    basic_email_check (email);

    result.rc = is_6531_local (email, ch);

    if (result.rc != EEAV_NO_ERROR)
        return result;

    brs = ch + 1;

    if (*brs != '[') {
        result.rc = is_utf8_domain (
            &result.idn_rc,
            ch + 1,
            end,
            tld_check );

        if (result.rc >= 0) {
            result.is_domain = true;
        }

        return result;
    }

    /* seems to be an ip address */
    check_ip(); /* see private_email.h */

    return result;
}
