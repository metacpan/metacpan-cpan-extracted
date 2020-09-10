#include <stdio.h>
#include <stdlib.h>
#include <locale.h>
#include <string.h>
#include <errno.h>
#include <eav.h>
#include <eav/auto_tld.h>
#include "common.h"


/* how many times idn library should fail */
#define IDN_ERRORS    (2)


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
    idn_result_t r = idn_success;
    static int error_count[EEAV_MAX]; /* zero everything */
    int t;
    FILE *fh;
    char *file = NULL;
    int expect_pass = -1;
    int expect_fail = -1;
    int passed = 0;
    int failed = 0;


    if (argc >= 5 || argc < 4) {
        msg_warn ("usage: %s PASS_COUNT FAIL_COUNT FILE\n", argv[0]);
        return 2;
    }

    setlocale(LC_ALL, "en_US.UTF-8");
    init_idn (&ctx);

    file = argv[3];
    expect_pass = atoi (argv[1]);
    expect_fail = atoi (argv[2]);

    fh = fopen (file, "r");

    if (fh == NULL) {
        msg_warn ("error: open %s: %s", file, strerror(errno));
        return 3;
    }

    while ((read = getline (&line, &len, fh)) != EOF) {
        remove_crlf(line, read)

        if (line[0] == '#') /* skip comments */
            continue;

        r = idn_success; /* reset */
        t = is_utf8_domain (ctx, actions, &r, line, line + strlen (line), false);

        if (t >= 0) {
            if (t != TLD_TYPE_NOT_ASSIGNED && t != TLD_TYPE_TEST) {
                printf ("PASS: %s\n", line);
                passed++;
            }
            else {
                printf ("FAIL: %s\n", line);
                failed++;
                printf ("\t t = %d; r = %d; idnerr = %s\n",
                        t, r, idn_result_tostring (r));
            }
        }
        else {
            printf ("FAIL: %s\n", line);
            error_count[-1 * t]++;
            failed++;
            printf ("\t t = %d; r = %d; idnerr = %s\n",
                    t, r, idn_result_tostring (r));
        }
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

    if (error_count[EEAV_IDN_ERROR] != IDN_ERRORS) {
        msg_warn ("%s: expected %d idn error(s), but got %d\n",
                argv[0],
                IDN_ERRORS,
                error_count[EEAV_IDN_ERROR]);
        return 6;
    }

#ifdef _DEBUG
    for (int i = 0; i < EEAV_MAX; i++) {
        printf ("error #%d: count = %d\n", i, error_count[i]);
    }
#endif

    if (line != NULL)
        free (line);

    fclose (fh);
    idn_resconf_destroy (ctx);

    msg_ok ("%s: PASS\n", argv[0]);

    return 0;
}

