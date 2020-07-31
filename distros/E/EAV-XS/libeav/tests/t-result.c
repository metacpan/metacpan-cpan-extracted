#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <locale.h>
#include <errno.h>
#include <eav.h>
#include "common.h"


#define VALID_IPv4   (2)
#define VALID_IPv6   (2)
/* including special TLDs, which the test is consider as fail */
#define VALID_DOMAIN (11)


extern int
main (int argc, char *argv[])
{
    eav_t eav;
    char *line = NULL;
    size_t len = 0;
    ssize_t read = 0;
    FILE *fh;
    char *file = NULL;
    int expect_pass = -1;
    int expect_fail = -1;
    int passed = 0;
    int failed = 0;
    int ipv4 = 0;
    int ipv6 = 0;
    int domain = 0;


    if (argc >= 5 || argc < 4) {
        msg_warn ("usage: %s PASS_COUNT FAIL_COUNT FILE\n", argv[0]);
        return 2;
    }

    setlocale(LC_ALL, "en_US.UTF-8");
    eav_init (&eav);
    eav.rfc = EAV_RFC_6531;
    eav.allow_tld &= ~EAV_TLD_SPECIAL;
    eav_setup (&eav);

    expect_pass = atoi (argv[1]);
    expect_fail = atoi (argv[2]);
    file = argv[3];

    fh = fopen (file, "r");

    if (fh == NULL) {
        msg_warn ("open: %s: %s", file, strerror(errno));
        return 3;
    }

    while ((read = getline (&line, &len, fh)) != EOF) {
        line[read-1] = '\0';
        if (read >= 2 && line[read-2] == '\r') line[read-2] = '\0';

        if (line[0] == '#') /* skip comments */
            continue;

        len = strlen (line);

        if (eav_is_email (&eav, line, len)) {
#ifdef EAV_EXTRA
            printf ("PASS: %s\n      lpart: %s\tdomain: %s\n",
                    sanitize_utf8(line, len),
                    eav.result->lpart,
                    eav.result->domain);
#else
            printf ("PASS: %s\n", sanitize_utf8(line, len));
#endif
            passed++;
        }
        else {
            printf ("FAIL: %s\n", sanitize_utf8(line, len));
            printf ("      %s\n", eav_errstr(&eav));
            failed++;
        }

        /* No matter if the test fail because of allow_tld filter,
         * the domain/ip validation are always successful.
         */
        if (eav.result->is_domain)
            domain++;
        else if (eav.result->is_ipv4)
            ipv4++;
        else if (eav.result->is_ipv6)
            ipv6++;
    }

    if (passed != expect_pass) {
        msg_warn ("%s: expected %d passed checks, but got %d\n",
                argv[0],
                expect_pass,
                passed);
        return 4;
    }

    if (failed != expect_fail) {
        msg_warn ("%s: expected %d failed checks, but got %d\n",
                argv[0],
                expect_fail,
                failed);
        return 5;
    }

    if (domain != VALID_DOMAIN) {
        msg_warn ("%s: expected %d valid domains, but got %d\n",
                argv[0],
                VALID_DOMAIN,
                domain);
        return 6;
    }

    if (ipv4 != VALID_IPv4) {
        msg_warn ("%s: expected %d valid IPv4, but got %d\n",
                argv[0],
                VALID_IPv4,
                ipv4);
        return 7;
    }

    if (ipv6 != VALID_IPv6) {
        msg_warn ("%s: expected %d valid IPv6, but got %d\n",
                argv[0],
                VALID_IPv6,
                ipv6);
        return 8;
    }

    if (line != NULL)
        free (line);
    eav_free (&eav);
    msg_ok ("%s: PASS\n", argv[0]);

    return 0;
}
