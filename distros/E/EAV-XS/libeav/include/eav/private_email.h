#ifndef PRIVATE_EMAIL_H
#define PRIVATE_EMAIL_H

#include "auto_tld.h"

#ifdef HAVE_IDNKIT
#include <idn/api.h>
#define INIT_EAV_RESULT_T(x) \
    eav_result_t *x = malloc (sizeof(eav_result_t)); \
    assert (x != NULL); \
    x->is_ipv4 = x->is_ipv6 = x->is_domain = false; \
    x->rc = 0; \
    x->idn_rc = idn_success;
#else
#define INIT_EAV_RESULT_T(x) \
    eav_result_t *x = malloc (sizeof(eav_result_t)); \
    assert (x != NULL); \
    x->is_ipv4 = x->is_ipv6 = x->is_domain = false; \
    x->rc = x->idn_rc = 0;
#endif

#define basic_email_check(e) do { \
    if (length == 0) { \
        result->rc = inverse(EEAV_EMAIL_EMPTY); \
        return result; \
    } \
\
    ch = strrchr ((e), '@'); \
\
    if (ch == NULL || ch + 1 == end) { \
        result->rc = inverse(EEAV_DOMAIN_EMPTY); \
        return result; \
    } \
\
    if (ch - (e) > VALID_LPART_LEN) { \
        result->rc = inverse(EEAV_LPART_TOO_LONG); \
        return result; \
    } \
} while (0)

#define check_tld() do { \
    if (tld_check == false) { \
        result->rc = EEAV_NO_ERROR; \
        return result; \
    } \
\
    if (is_special_domain (ch + 1, end)) { \
        result->rc = TLD_TYPE_SPECIAL; \
        return result; \
    } \
\
    /* fqdn & tld tests */ \
    ch = strrchr(ch + 1, '.'); \
\
    if (ch == NULL) { \
        result->rc = inverse(EEAV_DOMAIN_NOT_FQDN); \
        return result; \
    } \
\
    result->rc = is_tld (ch + 1, end); \
} while (0)


#define check_ip() do { \
    if (end - brs <= 8) { /* minimum allowed IP length: 1.2.3.4 */ \
        result->rc = inverse(EEAV_IPADDR_INVALID); \
        return result; \
    } \
\
    bre = strrchr(brs, ']'); \
\
    if (bre == NULL) { \
        result->rc = inverse(EEAV_IPADDR_BRACKET_UNPAIR); \
        return result; \
    } \
\
    if (ISDIGIT(brs[1])) { /* ip address, possibly ipv4 */ \
        if (is_ipaddr (brs + 1, bre) == 0) { \
            result->rc = inverse(EEAV_IPADDR_INVALID); \
            return result; \
        } \
        result->is_ipv4 = true; \
    } \
    else { /* try ipv6 */ \
        ch = strchr (brs + 1, ':'); \
        if ((ch == NULL) || (is_ipaddr (ch + 1, bre) == 0)) { \
            result->rc = inverse(EEAV_IPADDR_INVALID); \
            return result; \
        } \
        result->is_ipv6 = true; \
    } \
    /* valid ip addr. */ \
    result->rc = EEAV_NO_ERROR; \
} while (0)

#endif /* PRIVATE_EMAIL_H */
