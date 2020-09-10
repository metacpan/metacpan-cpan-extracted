#include <stdio.h>
#include <stdlib.h>
#include <locale.h>
#include <string.h>
#include <errno.h>
#include <eav.h>
#include <eav/auto_tld.h>
#include "common.h"

/* how many times idn library should fail */
#ifdef HAVE_LIBIDN2
#define IDNKIT_CHECK    (6)
#else
#define IDNKIT_CHECK    (0)
#endif


extern int
main (int argc, char *argv[])
{
    char *line = NULL;
    size_t len;
    ssize_t read;
    static int tld_count[TLD_TYPE_MAX];
    static int error_count[EEAV_MAX]; /* zero everything */
    int t;
    int r;
    FILE *fh;


    if (argc >= 3 || argc < 2) {
        msg_warn ("usage: %s FILE\n", argv[0]);
        return 2;
    }

    setlocale(LC_ALL, "en_US.UTF-8");

    fh = fopen (argv[--argc], "r");

    if (fh == NULL) {
        msg_warn ("open: %s: %s", argv[argc], strerror(errno));
        return 3;
    }

    while ((read = getline (&line, &len, fh)) != EOF) {
        remove_crlf(line, read)

        if (line[0] == '#') /* skip comments */
            continue;

        t = is_utf8_domain (&r, line, line + strlen (line), true);

        if (t >= 0) {
            if (t != TLD_TYPE_NOT_ASSIGNED && t != TLD_TYPE_TEST)
                printf ("PASS: %s\n", line);
            else
                printf ("FAIL: %s\n", line);

            tld_count[t]++;
        }
        else {
            printf ("FAIL: %s\n", line);
            error_count[-1 * t]++;
        }
    }

    if (error_count[EEAV_IDN_ERROR] != IDNKIT_CHECK) {
        msg_warn ("expected %d IDN test fails, but got %d\n",
                IDNKIT_CHECK,
                error_count[EEAV_IDN_ERROR]);
        return 4;
    }

#ifdef _DEBUG
    for (int i = 0; i < EEAV_MAX; i++) {
        printf ("error #%d: count = %d\n", i, error_count[i]);
    }
#endif

    if (line != NULL)
        free (line);
    fclose (fh);

    msg_ok ("%s: PASS\n", argv[0]);

    return 0;
}
