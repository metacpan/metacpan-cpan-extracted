#ifndef EAV_H
#define EAV_H
#include <stdbool.h>
#include <stddef.h>
#ifdef HAVE_IDNKIT
    #include <idn/api.h>
#endif


/* high-level API modes */
typedef enum {
    EAV_RFC_822,
    EAV_RFC_5321,
    EAV_RFC_5322,
    EAV_RFC_6531
} EAV_RFC;

/* TLD types */
typedef enum {
    EAV_TLD_INVALID             = 1 << 1, /* internal usage only */
    EAV_TLD_NOT_ASSIGNED        = 1 << 2,
    EAV_TLD_COUNTRY_CODE        = 1 << 3,
    EAV_TLD_GENERIC             = 1 << 4,
    EAV_TLD_GENERIC_RESTRICTED  = 1 << 5,
    EAV_TLD_INFRASTRUCTURE      = 1 << 6,
    EAV_TLD_SPONSORED           = 1 << 7,
    EAV_TLD_TEST                = 1 << 8,
    EAV_TLD_SPECIAL             = 1 << 9,
    EAV_TLD_RETIRED             = 1 << 10
} EAV_TLD;


/* result information from callbacks */
typedef struct eav_result_s {
    bool is_ipv4;
    bool is_ipv6;
    bool is_domain;
    int rc;
#ifdef HAVE_IDNKIT
    idn_result_t idn_rc;
#else
    int idn_rc;
#endif
#ifdef EAV_EXTRA
    char *lpart;
    char *domain;
#endif
} eav_result_t;


/* eav.c utf-8 callback */
#ifdef HAVE_IDNKIT
typedef eav_result_t *
(*eav_utf8_f)  (idn_resconf_t,
                idn_action_t,
                const char *,
                size_t,
                bool tld_check);
#else
typedef eav_result_t *
(*eav_utf8_f) (const char *, size_t, bool);
#endif


/* eav.c ascii callback */
typedef eav_result_t * (*eav_ascii_f) (const char *,
                                     size_t,
                                     bool);


typedef struct eav_s {
    EAV_RFC         rfc;            /* mode */
    int             allow_tld;      /* flags: allow only these TLDs */
    bool            tld_check;      /* do fqdn & tld checks */
    /* XXX private */
    bool            utf8;
    int             errcode;
    const char      *idnmsg;        /* idn error message */
    bool            initialized;    /* true when idn is initialized */
#ifdef HAVE_IDNKIT
    idn_resconf_t   idn;
    idn_action_t    actions;
#endif
    eav_utf8_f      utf8_cb;
    eav_ascii_f     ascii_cb;
    eav_result_t    *result;
} eav_t;


/* low-level API: error codes */
enum {
    EEAV_NO_ERROR,
    EEAV_INVALID_RFC,
    EEAV_IDN_ERROR,
    EEAV_EMAIL_EMPTY,
    EEAV_LPART_EMPTY,
    EEAV_LPART_TOO_LONG,
    EEAV_LPART_NOT_ASCII,
    EEAV_LPART_SPECIAL,
    EEAV_LPART_CTRL_CHAR,
    EEAV_LPART_MISPLACED_QUOTE,
    EEAV_LPART_UNQUOTED, /* 10 */
    EEAV_LPART_TOO_MANY_DOTS,
    EEAV_LPART_MISPLACED_DOT,
    EEAV_LPART_UNQUOTED_FWS,
    EEAV_LPART_INVALID_UTF8,
    EEAV_DOMAIN_EMPTY,
    EEAV_DOMAIN_LABEL_TOO_LONG,
    EEAV_DOMAIN_MISPLACED_HYPHEN,
    EEAV_DOMAIN_MISPLACED_DELIMITER,
    EEAV_DOMAIN_INVALID_CHAR,
    EEAV_DOMAIN_TOO_LONG, /* 20 */
    EEAV_DOMAIN_NUMERIC,
    EEAV_DOMAIN_NOT_FQDN,
    EEAV_IPADDR_INVALID,
    EEAV_IPADDR_BRACKET_UNPAIR,
    EEAV_TLD_INVALID,
    EEAV_TLD_NOT_ASSIGNED,
    EEAV_TLD_COUNTRY_CODE,
    EEAV_TLD_GENERIC,
    EEAV_TLD_GENERIC_RESTRICTED,
    EEAV_TLD_INFRASTRUCTURE, /* 30 */
    EEAV_TLD_SPONSORED,
    EEAV_TLD_TEST,
    EEAV_TLD_SPECIAL,
    EEAV_TLD_RETIRED,
    EEAV_MAX
};


/* ---[ high-level API functions ] --- */


/*
 * eav_init: initialize eav structure.
 */
extern void
eav_init (eav_t *eav);

/*
 * eav_free: free internal resources, but does not free eav structure itself.
 */
extern void
eav_free (eav_t *eav);

/*
 * eav_setup: confirms choosen user options.
 *
 * Returns 0 on success. Otherwise returns EEAV_INVALID_RFC.
 */
extern int
eav_setup (eav_t *eav);

/*
 * eav_is_email: validates the email and its length.
 *
 * Returns 1 if the email is valid. Otherwise returns 0.
 */
extern int
eav_is_email (eav_t *eav, const char *email, size_t length);


/*
 * eav_errstr: returns the error message for the last checked email address.
 */
extern const char *
eav_errstr (eav_t *eav);


/* ---[ low-level API functions ] --- */


/*
 * is_822_local: check local-part as defined in RFC 822.
 */
extern int
is_822_local (const char *start, const char *end);

/*
 * is_5321_local: check local-part as defined in RFC 5321.
 */
extern int
is_5321_local (const char *start, const char *end);

/*
 * is_5322_local: check local-part as defined in RFC 5322.
 */
extern int
is_5322_local (const char *start, const char *end);

/*
 * is_6531_local: check local-part as defined in RFC 6531.
 */
extern int
is_6531_local (const char *start, const char *end);

/*
 * is_ipv4: validate IPv4 address.
 */
extern int
is_ipv4 (const char *start, const char *end);

/*
 * is_ipv6: validate IPv6 address.
 */
extern int
is_ipv6 (const char *start, const char *end);

/*
 * is_ipaddr: validates if the address IPv4 or IPv6
 */
extern int
is_ipaddr (const char *start, const char *end);

/*
 * is_ascii_domain: validates if the domain is all-ASCII.
 */
extern int
is_ascii_domain (const char *start, const char *end);


/*
 * is_utf8_domain: validates UTF-8 domain.
 */
#ifdef HAVE_IDNKIT
extern int
is_utf8_domain (idn_resconf_t ctx,
                idn_action_t actions,
                idn_result_t *r,
                const char *start,
                const char *end,
                bool tld_check);
#else
extern int
is_utf8_domain (int *r,
                const char *start,
                const char *end,
                bool tld_check);
#endif

/*
 * is_tld: validates if the domain has correct TLD.
 */
extern int
is_tld (const char *start, const char *end);

/*
 * is_special_domain: validates if the domain is special or reserved.
 */
extern int
is_special_domain (const char *start, const char *end);

/*
 * is_822_email: check email address as defined in RFC 822.
 */
extern eav_result_t *
is_822_email (const char *email, size_t length, bool tld_check);

/*
 * is_5321_email: check email address as defined in RFC 5321.
 */
extern eav_result_t *
is_5321_email (const char *email, size_t length, bool tld_check);

/*
 * is_5322_email: check email address as defined in RFC 5322.
 */
extern eav_result_t *
is_5322_email (const char *email, size_t length, bool tld_check);

/*
 * is_6531_email: check email address as defined in RFC 6531.
 */
#ifdef HAVE_IDNKIT
extern eav_result_t *
is_6531_email  (idn_resconf_t ctx,
                idn_action_t actions,
                const char *email,
                size_t length,
                bool tld_check);
#else
extern eav_result_t *
is_6531_email  (const char *email,
                size_t length,
                bool tld_check);
#endif /* HAVE_IDNKIT */

/*
 * eav_result_free: free eav_result_t structure.
 */
extern void
eav_result_free (eav_result_t *result);


#endif /* EAV_H */
