#include <stdio.h>
#include <stdlib.h>
#include <locale.h>
#include <string.h>
#include <errno.h>
#include <eav.h>
#include <eav/auto_tld.h>
#include "common.h"


static void
init_idn (idn_resconf_t *ctx)
{
    idn_result_t r;


    r = idn_resconf_initialize ();

    if (r != idn_success) {
        msg_warn ("idn_resconf_initialize: %s\n", idn_result_tostring (r));
        exit (EXIT_FAILURE);
    }

    r = idn_resconf_create (ctx);

    if (r != idn_success) {
        msg_warn ("idn_resconf_create: %s\n", idn_result_tostring (r));
        exit (EXIT_FAILURE);
    }
}


extern int
main (int argc, char *argv[])
{
    char *line = NULL;
    size_t len;
    ssize_t read;
    idn_resconf_t ctx;
    idn_action_t actions = IDN_ENCODE_REGIST;
    idn_result_t r;
    static int tld_count[TLD_TYPE_MAX]; /* zero everything */
    int t;
    FILE *fh;
    char *file = NULL;
    int expect_tld_test = -1;   /* how many expect TLDs with test type */
    int expect_tld_na = -1;     /* how many expect not assigned TLDs */


    if (argc >= 5 || argc < 4) {
        msg_warn ("usage: %s TLD_TEST_COUNT TLD_NA_COUNT FILE\n", argv[0]);
        return 2;
    }

    setlocale(LC_ALL, "en_US.UTF-8");

    file = argv[3];
    expect_tld_test = atoi (argv[1]);
    expect_tld_na = atoi (argv[2]);

    fh = fopen (file, "r");

    if (fh == NULL) {
        msg_warn ("open: %s: %s", argv[argc], strerror(errno));
        return 3;
    }

    init_idn (&ctx);

    while ((read = getline (&line, &len, fh)) != EOF) {
        line[read-1] = '\0';

        if (line[0] == '#') /* skip comments */
            continue;

        t = is_utf8_domain (ctx, actions, &r, line, line + strlen (line), true);

        if (t >= 0 &&
            t != TLD_TYPE_NOT_ASSIGNED &&
            t != TLD_TYPE_TEST &&
            t != TLD_TYPE_SPECIAL)
        {
            printf ("PASS: %s\n", line);
        }
        else
        {
            printf ("FAIL: %s\n", line);
            printf ("      %s (%d)\n", idn_result_tostring (t), t);
        }

        if (t >= 0)
            tld_count[t]++;
    }

    if (tld_count[TLD_TYPE_TEST] != expect_tld_test) {
        msg_warn ("%s: expected %d test TLDs, but got %d [%d]\n",
                argv[0],
                expect_tld_test,
                tld_count[TLD_TYPE_TEST],
                TLD_TYPE_TEST);
        return 5;
    }

    if (tld_count[TLD_TYPE_NOT_ASSIGNED] != expect_tld_na) {
        msg_warn ("%s: expected %d not assigned TLDs, but got %d [%d]\n",
                argv[0],
                expect_tld_na,
                tld_count[TLD_TYPE_NOT_ASSIGNED],
                TLD_TYPE_NOT_ASSIGNED);
        return 6;
    }

    if (line != NULL)
        free (line);
    fclose (fh);
    idn_resconf_destroy (ctx);

    msg_ok ("%s: PASS\n", argv[0]);

    return 0;
}
