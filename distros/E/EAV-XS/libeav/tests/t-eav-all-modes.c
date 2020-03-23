#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <locale.h>
#include <errno.h>
#include <eav.h>
#include "common.h"


static int expect_pass;
static int expect_fail;
static int passed;
static int failed;
static char *line;
static size_t len;


static void
test_mode(eav_t *eav, int mode, FILE *fh)
{
    ssize_t read;

    switch(mode) {
    case EAV_RFC_822:
        printf (">>> Switch to RFC 822 mode\n");
        break;
    case EAV_RFC_5321:
        printf (">>> Switch to RFC 5321 mode\n");
        break;
    case EAV_RFC_5322:
        printf (">>> Switch to RFC 5322 mode\n");
        break;
    case EAV_RFC_6531:
        printf (">>> Switch to RFC 6531 mode\n");
        break;
    default:
        printf (">>> Switch to UNKNOWN mode\n");
        break;
    }

    eav->rfc = mode;

    if (eav_setup(eav) != 0) {
        msg_warn("error: %s\n", eav_errstr(eav));
        exit(EXIT_FAILURE);
    }

    rewind(fh);
    while ((read = getline (&line, &len, fh)) != EOF) {
        line[read-1] = '\0';

        if (line[0] == '#') /* skip comments */
            continue;

        len = strlen (line);

        if (eav_is_email (eav, line, len)) {
            printf ("PASS: %s\n", sanitize_utf8(line, len));
            passed++;
        }
        else {
            printf ("FAIL: %s\n", sanitize_utf8(line, len));
            printf ("      %s\n", eav_errstr(eav));
            failed++;
        }
    }
}


extern int
main (int argc, char *argv[])
{
    eav_t eav;
    FILE *fh;
    char *file = NULL;
    int modes[] = {
        EAV_RFC_6531,
        EAV_RFC_822,
        EAV_RFC_5321,
        EAV_RFC_5322,
        EAV_RFC_6531
    };

    setlocale(LC_ALL, "");

    if (argc >= 5 || argc < 4) {
        msg_warn ("usage: %s PASS_COUNT FAIL_COUNT FILE\n", argv[0]);
        return 2;
    }

    eav_init (&eav);

    expect_pass = atoi (argv[1]);
    expect_fail = atoi (argv[2]);
    file = argv[3];

    fh = fopen (file, "r");
    if (fh == NULL) {
        msg_warn ("open: %s: %s", file, strerror(errno));
        return 3;
    }

    for (size_t i = 0; i < ARRAY_SIZE(modes); i++)
        test_mode(&eav, modes[i], fh);

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
