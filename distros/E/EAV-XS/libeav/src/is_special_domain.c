#include <stdio.h>
#include <string.h>
#include <strings.h>
#include <eav.h>
#include <eav/private.h>


typedef struct reserved_s {
    const char *domain;
    size_t length;
} reserved_t;

static const reserved_t reserved[] = {
    { "test",           5 },
    { "example",        8 },
    { "invalid",        8 },
    { "localhost",     10 },
    { "onion",          6 }
};

static const reserved_t example[] = {
    { "com", 4 },
    { "net", 4 },
    { "org", 4 },
};

/*
 * is_special_domain: checks whether a domain is reserved or special.
 *
 * RFC2606 & RFC6761:
 *
 * Special TLDs:
 *
 * test.
 * example.
 * invalid.
 * localhost.
 *
 * Reserved Example Second Level Domain Names:
 *
 * example.com.
 * example.net.
 * example.org.

 * RFC 7686:
 *
 * onion.
 *
 */
extern int
is_special_domain (const char *start, const char *end)
{
#define LABEL_SIZE (64)
    const char *cp = NULL;
    char *ch = NULL;
    char label[LABEL_SIZE];
    size_t len = 0;
    int count = 0;


#define CHECK(a,d) do { \
    for (size_t i = 0; i < ARRAY_SIZE(a); i++) \
        if (strncasecmp ((d), a[i].domain, a[i].length) == 0) \
            return (YES); \
} while (0)

    /* count labels */
    for (cp = start; (ch = strchr (cp, '.')) != 0; cp = ch + 1, count++);

    /* shortcut for non-fqdn */
    if (count == 0) {
        len = end - start;
        if (len < 4 || len > 9 || len == 6 || len == 8)
            return (NO);
        CHECK(reserved, start);
        return (NO);
    }

    /* don't take into account root */
    if (end[-1] == '.')
        --count;

    /* we're interested in last two labels only: skip the rest. */
    cp = start;

    while (count >= 2) {
        ch = strchr (cp, '.');
        cp = ch + 1;
        count--;
    }

    /* first label */
    ch = strchr (cp, '.');
    len = ch - cp;

    if (len == 7) { /* probably "example.tld" */
        memcpy (label, cp, len);
        label[len] = 0;

        if (strncasecmp ("example", label, 8) == 0) {
            cp = ch + 1;
            ch = strchr (cp, '.');

            if (ch == NULL)
                len = end - cp;
            else
                len = ch - cp;

            if (len != 3) /* there are only com, net, org */
                return (NO);

            /* probably reserved example.tld */
            memcpy (label, cp, len);
            label[len] = 0;
            CHECK(example, label);
        }
    }
    else { /* probably special or reserved */
        /* check only the last label */
        cp = ch + 1;
        ch = strchr (cp, '.');

        if (ch == NULL)
            len = end - cp;
        else
            len = ch - cp;

        if (len < 4 || len > 9 || len == 6 || len == 8)
            return (NO);

        memcpy (label, cp, len);
        label[len] = 0;
        CHECK(reserved, label);
    }

    return (NO);
}
