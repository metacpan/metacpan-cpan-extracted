#include <stdio.h>
#include <stdlib.h>
#include <locale.h>
#include <string.h>
#include <errno.h>
#include <eav.h>
#include <eav/auto_tld.h>
#include "common.h"


/* how many expect TLDs with test type */
#define TEST_CHECK          (11)
/* how many expect not assigned TLDs */
#define NOT_ASSIGNED_CHECK  (49)


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


    if (argc >= 3 || argc < 2) {
        msg_warn ("usage: %s FILE\n", argv[0]);
        return 2;
    }

    setlocale(LC_ALL, "");
    init_idn (&ctx);

    fh = fopen (argv[--argc], "r");

    if (fh == NULL) {
        msg_warn ("open: %s: %s", argv[argc], strerror(errno));
        return 3;
    }

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

    if (tld_count[TLD_TYPE_TEST] != TEST_CHECK) {
        msg_warn ("%s: expected %d test TLDs, but got %d [%d]\n",
                argv[0],
                TEST_CHECK,
                tld_count[TLD_TYPE_TEST],
                TLD_TYPE_TEST);
        return 5;
    }

    if (tld_count[TLD_TYPE_NOT_ASSIGNED] != NOT_ASSIGNED_CHECK) {
        msg_warn ("%s: expected %d not assigned TLDs, but got %d [%d]\n",
                argv[0],
                NOT_ASSIGNED_CHECK,
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
