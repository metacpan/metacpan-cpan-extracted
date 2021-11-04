#include <stdio.h>
#include <stdlib.h>
#include <getopt.h>
#include <locale.h>
#include <string.h>
#include <errno.h>
#include <eav.h>
#include <eav/auto_tld.h>
#include "common.h"


typedef enum app_mode_e {
    APP_MODE_NORMAL,
    APP_MODE_SLURP
} app_mode_t;


typedef struct app_options_s {
    app_mode_t mode;
    int expect_pass;
    int expect_fail;
    int passed;
    int failed;
    char ignore_char;
    FILE *file;
} app_options_t;


static void
print_usage (const char *app)
{
    printf ("Usage: %s [OPTIONS] [EMAIL_1] [EMAIL_2] [EMAIL_n]\n"
            "Options:\n",
            app);
#define p(o, d) printf ("  %-28s %s\n", (o), (d))
    p("--help, -h",         "print this help");
    p("--file, -f",         "input file");
    p("--pass-checks, -P",  "expected pass checks");
    p("--fail-checks, -F",  "expected fail checks");
    p("--slurp, -s",        "enable slurp mode, defalt: off");
    p("--ignore-char, -i",  "ignore lines started with this char, default: #");
#undef p
}


static int
parse_args (int argc, char *argv[], app_options_t *result)
{
    int r;
    static struct option opts[] = {
        { "help",        no_argument,       0, 'h' },
        { "pass-checks", required_argument, 0, 'P' },
        { "fail-checks", required_argument, 0, 'F' },
        { "file",        required_argument, 0, 'f' },
        { "slurp",       no_argument,       0, 's' },
        { "ignore-char", required_argument, 0, 'i' },
        { 0, 0, 0, 0 }
    };

    while (1) {
        int index = 0;
        r = getopt_long (argc, argv, "hsP:F:f:i:", opts, &index);

        if (r == -1)
            break;

        switch (r) {
        case 0:   break;
        case 'P':
            result->expect_pass = atoi (optarg);
            break;
        case 'F':
            result->expect_fail = atoi (optarg);
            break;
        case 'f': {
            char *file = optarg;
            if (strncmp(file, "-", 2) == 0)
                result->file = stdin;
            else
                result->file = fopen (file, "r");
            if (result->file == NULL) {
                msg_warn ("%s: open: %s: %s\n", argv[0], file, strerror(errno));
                return 3;
            }
            break;
        }
        case 's':
            result->mode = APP_MODE_SLURP;
            break;
        case 'i':
            result->ignore_char = strlen (optarg) ? optarg[0] : '\0';
            break;
        case 'h': print_usage(argv[0]); return 0;
        default:  print_usage(argv[0]); return 1;
        }
    }

    return -1;
}


static char*
slurp_string (const char *s, size_t len) {
    /* no critic */
    char *email = (char*) malloc (sizeof(char) * (len + 1));
    assert (email != NULL);
    const char *cp = s;
    const char *end = s + len;
    int ch;
    int email_idx = 0;

    for (; cp < end && (ch = *(unsigned const char *) cp) != 0; cp++) {
        if (ch == '\\' && (cp + 1) <= end) {
            int replaced = 1;
            int nch = *((unsigned const char *) cp + 1);
            switch (nch) {
            case '\\': email[email_idx++] = '\\'; break;
            case 'r':  email[email_idx++] = '\r'; break;
            case 'n':  email[email_idx++] = '\n'; break;
            case 't':  email[email_idx++] = '\t'; break;
            case 'v':  email[email_idx++] = '\v'; break;
            case ' ':  email[email_idx++] = ' ';  break;
            case '0':  goto done;
            default:   replaced = 0; break;
            }

            if (replaced) {
                cp++;
                continue;
            }
        }

        email[email_idx++] = ch;
    }

done:
    email[email_idx] = '\0';

    return email;
}


static int
parse_string (app_options_t *app_opts, const char *s) {
    size_t len = strlen (s);
    int slurp = app_opts->mode == APP_MODE_SLURP;
    char *email = slurp ? slurp_string (s, len) : (char*) s;
    eav_result_t *r = is_822_email (email, strlen (email), true);

    if (slurp)
        free (email);

    if (r->rc >= 0) {
        printf ("PASS: %s\n", sanitize(s, len));
        app_opts->passed++;
    }
    else {
        printf ("FAIL: %s (%d)\n", sanitize(s, len), r->rc);
        app_opts->failed++;
    }

    eav_result_free (r);

    return -1;
}


static int
parse_file (app_options_t *app_opts) {
    char *line = NULL;
    size_t len = 0;
    ssize_t read = 0;
    eav_result_t *r;
    FILE *fh = app_opts->file;
    const char ignchar = app_opts->ignore_char;
    int slurp = app_opts->mode == APP_MODE_SLURP;

    while ((read = getline (&line, &len, fh)) != EOF) {
        remove_crlf(line, read)

        if (ignchar && line[0] == ignchar) /* skip comments */
            continue;

        len = strlen (line);

        if (slurp) {
            char *email = slurp_string (line, len);
            r = is_822_email (email, strlen (email), true);
            free (email);
        }
        else {
            r = is_822_email (line, len, true);
        }

        if (r->rc >= 0) {
            printf ("PASS: %s\n", sanitize(line, len));
            app_opts->passed++;
        }
        else {
            printf ("FAIL: %s\n", sanitize(line, len));
            app_opts->failed++;
        }

        eav_result_free (r);
    }

    if (line != NULL)
        free (line);

    fclose (fh);
    app_opts->file = NULL;

    return -1;
}


extern int
main (int argc, char *argv[])
{
    setlocale(LC_ALL, "en_US.UTF-8");

    app_options_t app_opts = { APP_MODE_NORMAL, -1, -1, 0, 0, '#', NULL };
    int rc = parse_args (argc, argv, &app_opts);
    if (rc != -1) return rc;

    if (app_opts.file != NULL)
        parse_file (&app_opts);

    int i = optind;
    while (i < argc) {
        parse_string (&app_opts, argv[i]);
        i++;
    }

    if (app_opts.passed != app_opts.expect_pass) {
        msg_warn ("%s: expected %d passed checks, but got %d\n",
                argv[0],
                app_opts.expect_pass,
                app_opts.passed);
        return 4;
    }

    if (app_opts.failed != app_opts.expect_fail) {
        msg_warn ("%s: expected %d failed checks, but got %d\n",
                argv[0],
                app_opts.expect_fail,
                app_opts.failed);
        return 5;
    }

    msg_ok ("%s: PASS\n", argv[0]);

    return 0;
}
