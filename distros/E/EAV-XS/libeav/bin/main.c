#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <locale.h>
#include <errno.h>
#include <eav.h>
#include <time.h>
#include "main.h"


static void
parse_file (const char *file, eav_t *eav)
{
    FILE *fh;
    char *line = NULL;
    char *cp = line;
    size_t len = 0;
    ssize_t read = 0;
    int passed = 0;
    int failed = 0;


    fh = fopen (file, "r");

    if (fh == NULL) {
        msg_warn ("open: %s: %s", file, strerror(errno));
        return;
    }

    while ((read = getline (&line, &len, fh)) != EOF) {
        /* XXX no critic; some dirty hacks */
        if (line[read - 2] == '\r')
            line[read - 2] = '\0';
        else
            line[read - 1] = '\0';

        if (line[0] == '#') /* skip comments */
            continue;

        if (line[0] == ' ')
            cp = line + 1;
        else
            cp = line;

        len = strlen (cp);

        /* remove white-space in the end */
        if (cp[len - 1] == ' ' || cp[len - 1] == '\t')
            cp[--len] = '\0';

        if (eav_is_email (eav, cp, len)) {
            msg_ok ("PASS: %s\n", sanitize_utf8(cp, len));
            passed++;
        }
        else {
            msg_ok ("FAIL: %s\n", sanitize_utf8(cp, len));
            msg_ok ("      %s\n", eav_errstr(eav));
            failed++;
        }
    }

    if (line != NULL)
        free (line);
    fclose (fh);
    msg_warn ("%s: pass = %d fail = %d\n", file, passed, failed);
}


extern int
main (int argc, char *argv[])
{
    eav_t eav;
#ifdef _DEBUG
    const struct timespec ts = { 5, 0 };
#endif


    if (argc < 2) {
        msg_warn ("usage: %s FILE [FILE2 FILE3 ...]\n", argv[0]);
        return 1;
    }

    setlocale(LC_ALL, "");
    eav_init (&eav);

    /* set own options */
    //eav.tld_check = false;

    /* apply new settigns */
    if (eav_setup (&eav) != EEAV_NO_ERROR) {
        msg_warn ("eav_setup: %s\n", eav_errstr (&eav));
        return 2;
    }

    while (argc-- >= 2)
        parse_file (argv[argc], &eav);

#ifdef _DEBUG
    for (;;)
        (void) nanosleep (&ts, NULL);
#endif

    eav_free (&eav);
    return 0;
}
