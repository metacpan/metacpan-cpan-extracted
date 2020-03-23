#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <locale.h>
#include <errno.h>
#include <eav.h>
#include "common.h"


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


    if (argc >= 5 || argc < 4) {
        msg_warn ("usage: %s PASS_COUNT FAIL_COUNT FILE\n", argv[0]);
        return 2;
    }

    setlocale(LC_ALL, "");
    eav_init (&eav);
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

        if (line[0] == '#') /* skip comments */
            continue;

        len = strlen (line);

        if (eav_is_email (&eav, line, len)) {
            printf ("PASS: %s\n", sanitize_utf8(line, len));
            passed++;
        }
        else {
            printf ("FAIL: %s\n", sanitize_utf8(line, len));
            printf ("      %s\n", eav_errstr(&eav));
            failed++;
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

    if (line != NULL)
        free (line);
    eav_free (&eav);
    msg_ok ("%s: PASS\n", argv[0]);
    return 0;
}
