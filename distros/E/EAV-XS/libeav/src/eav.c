#include <stdio.h>
#include <stdlib.h>
#include <eav.h>
#ifdef HAVE_LIBIDN2
    #include <idn2.h>
#elif defined HAVE_LIBIDN
    #include <idna.h>
#else
    #include <idn/api.h>
#endif
#include <eav/private.h>
#include <eav/auto_tld.h>


static const char * const errors[EEAV_MAX] = {
    "no error"                              /* EEAV_NO_ERROR */,
    "invalid RFC specified"                 /* EEAV_INVALID_RFC */,
    "idn internal error"                    /* EEAV_IDN_ERROR */,
    "empty email address"                   /* EEAV_EMAIL_EMPTY */,
    "local-part is empty"                   /* EEAV_LPART_EMPTY */,
    "local-part is too long"                /* EEAV_LPART_TOO_LONG */,
    "local-part has non-ascii characters"   /* EEAV_LPART_NOT_ASCII */,
    "local-part has special characters"     /* EEAV_LPART_SPECIAL */,
    "local-part has control characters"     /* EEAV_LPART_CTRL_CHAR */,
    "local-part has misplaced double quote" /* EEAV_LPART_MISPLACED_QUOTE */,
    "local-part has open double quote"      /* EEAV_LPART_UNQUOTED */,
    "local-part has too many dots"          /* EEAV_LPART_TOO_MANY_DOTS */,
    "local-part has unquoted characters"    /* EEAV_LPART_UNQUOTED_FWS */,
    "local-part has invalid UTF-8 data"     /* EEAV_LPART_INVALID_UTF8 */,
    "domain is empty"                       /* EEAV_DOMAIN_EMPTY */,
    "domain label is too long"              /* EEAV_DOMAIN_LABEL_TOO_LONG */,
    "domain has misplaced hyphen"           /* EEAV_DOMAIN_MISPLACED_HYPHEN */,
    "domain has misplaced delimiter"        /* EEAV_DOMAIN_MISPLACED_DELIMITER */,
    "domain has invalid characters"         /* EEAV_DOMAIN_INVALID_CHAR */,
    "domain is too long"                    /* EEAV_DOMAIN_TOO_LONG */,
    "domain is all-numeric"                 /* EEAV_DOMAIN_NUMERIC */,
    "domain is not FQDN"                    /* EEAV_DOMAIN_NOT_FQDN */,
    "ip-addr is incorrect"                  /* EEAV_IPADDR_INVALID */,
    "ip-addr has unpaired bracket"          /* EEAV_IPADDR_BRACKET_UNPAIR */,
    "invalid TLD"                           /* EEAV_TLD_INVALID */,
    "not assigned TLD"                      /* EEAV_TLD_NOT_ASSIGNED */,
    "country-code TLD"                      /* EEAV_TLD_COUNTRY_CODE */,
    "generic TLD"                           /* EEAV_TLD_GENERIC */,
    "generic-restricted TLD"                /* EEAV_TLD_GENERIC_RESTRICTED */,
    "infrastructure TLD"                    /* EEAV_TLD_INFRASTRUCTURE */,
    "sponsored TLD"                         /* EEAV_TLD_SPONSORED */,
    "test TLD"                              /* EEAV_TLD_TEST */,
    "special TLD"                           /* EEAV_TLD_SPECIAL */
};


extern const char *
eav_errstr (eav_t *eav)
{
    if (eav->errcode == EEAV_IDN_ERROR)
        return eav->idnmsg;
    else
        return errors[ eav->errcode ];
}

