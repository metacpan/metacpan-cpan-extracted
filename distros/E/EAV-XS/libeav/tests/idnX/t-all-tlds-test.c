#include <stdio.h>
#include <stdlib.h>
#include <locale.h>
#include <string.h>
#include <errno.h>
#include <eav.h>
#include <eav/auto_tld.h>
#include "common.h"
#ifdef HAVE_LIBIDN2
    #include <idn2.h>
#else
    #include <idna.h>
#endif


extern int
main (int argc, char *argv[])
{
    char *line = NULL;
    size_t len;
    ssize_t read;
    static int tld_count[TLD_TYPE_MAX]; /* zero everything */
    int t; /* eav result type */
    int r; /* eav result code */
    int errors = 0;
    FILE *fh;
    char *file = NULL;

    if (argc != 2) {
        msg_warn ("usage: %s FILE\n", argv[0]);
        return 2;
    }

    setlocale(LC_ALL, "en_US.UTF-8");

    file = argv[1];
    fh = fopen (file, "r");

    if (fh == NULL) {
        msg_warn ("open: %s: %s", file, strerror(errno));
        return 3;
    }

    while ((read = getline (&line, &len, fh)) != EOF) {
        remove_crlf(line, read)

        if (line[0] == '#') /* skip comments */
            continue;

        t = is_utf8_domain (&r, line, line + strlen (line), true);

        if (t >= 0)
        {
            tld_count[t]++;
        }
        else
        {
            errors++;
            printf ("FAIL: %s: type = %d error = %s\n", line, t,
#ifdef HAVE_LIBIDN2
                    idn2_strerror(r)
#else
                    idna_strerror(r)
#endif
            );
        }
    }

    if (line != NULL)
        free (line);

    fclose (fh);

    printf ("TLD statistic:\n");
    const char* fmt = "  %-18s %d\n";
    printf (fmt, "country-code", tld_count[TLD_TYPE_COUNTRY_CODE]);
    printf (fmt, "generic", tld_count[TLD_TYPE_GENERIC]);
    printf (fmt, "generic-restricted", tld_count[TLD_TYPE_GENERIC_RESTRICTED]);
    printf (fmt, "infrastructure", tld_count[TLD_TYPE_INFRASTRUCTURE]);
    printf (fmt, "not assigned", tld_count[TLD_TYPE_NOT_ASSIGNED]);
    printf (fmt, "retired", tld_count[TLD_TYPE_RETIRED]);
    printf (fmt, "special", tld_count[TLD_TYPE_SPECIAL]);
    printf (fmt, "sponsored", tld_count[TLD_TYPE_SPONSORED]);
    printf (fmt, "test", tld_count[TLD_TYPE_TEST]);

    if (tld_count[TLD_TYPE_UNUSED] != 0)
    {
        printf ("ERROR: found %d unused TLD.\n",
                tld_count[TLD_TYPE_UNUSED]);
        msg_warn ("%s: FAIL\n", argv[0]);
        return 4;
    }

    if (errors >= 1)
    {
        printf ("ERROR: there are some errors above.\n");
        msg_warn ("%s: FAIL\n", argv[0]);
        return 5;
    }

    msg_ok ("%s: PASS\n", argv[0]);
    return 0;
}
