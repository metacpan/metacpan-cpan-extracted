#include <stdio.h>
#include <string.h>
#include <idn/api.h>
#include <eav.h>
#include <eav/private.h>
#include <eav/auto_tld.h>


/* is_utf8_inet_domain: validates that domain is fqdn & have valid tld */
extern int
is_utf8_domain (idn_resconf_t ctx,
                idn_action_t actions,
                idn_result_t *r,
                const char *start,
                const char *end,
                bool tld_check)
{
    int rc;
    char domain[DOMAIN_SIZE];
    char *ch = NULL;
    size_t len;
    extern int is_ascii_domain (const char *start, const char *end);
    extern int is_tld (const char *start, const char *end);
    extern int is_special_domain (const char *start, const char *end);


    if (start == end)
        return inverse(EEAV_DOMAIN_EMPTY);

    *r = idn_res_encodename (ctx, actions, start, domain, DOMAIN_SIZE - 1);

    if (*r != idn_success)
        return inverse(EEAV_IDN_ERROR);

    len = strlen (domain);

    /* idn_res_encodename() does NOT check numeric domains */
    rc = is_ascii_domain (domain, domain + len);

    if (rc != EEAV_NO_ERROR)
        return rc;

    if (tld_check == false)
        return EEAV_NO_ERROR;

    /* special & reserved domains */
    if (is_special_domain (domain, domain + len))
        return TLD_TYPE_SPECIAL;

    /* fqdn & tld tests */
    ch = strrchr(domain, '.');

    if (ch == NULL)
        return inverse(EEAV_DOMAIN_NOT_FQDN);

    return (is_tld (ch + 1, domain + len));
}

