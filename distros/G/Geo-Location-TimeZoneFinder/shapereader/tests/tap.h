#include <stdio.h>
#include <stdlib.h>

#define plan(n)                                                              \
    do {                                                                     \
        tests_planned = n;                                                   \
        printf("1..%d\n", tests_planned);                                    \
    } while (0)

#define ok(test, name)                                                       \
    do {                                                                     \
        const char *_file = __FILE__;                                        \
        int _line = __LINE__;                                                \
        const char *_name = name;                                            \
        int _ok = test();                                                    \
        printf("%s %d - %s\n", _ok ? "ok" : "not ok", ++tests_run, _name);   \
        if (!_ok) {                                                          \
            ++tests_failed;                                                  \
            fprintf(stderr, "#   Failed test '%s'\n", _name);                \
            fprintf(stderr, "#   at %s line %d.\n", _file, _line);           \
        }                                                                    \
    } while (0)

#define done_testing()                                                       \
    do {                                                                     \
        int status = 0;                                                      \
        if (tests_run != tests_planned) {                                    \
            fprintf(stderr, "#   Ran %d of %d planned test(s).\n",           \
                    tests_run, tests_planned);                               \
            status = 1;                                                      \
        }                                                                    \
        if (tests_failed > 0) {                                              \
            fprintf(stderr, "#   %d test(s) failed\n", tests_failed);        \
            status = 1;                                                      \
        }                                                                    \
        exit(status);                                                        \
    } while (0)

extern int tests_planned;
extern int tests_run;
extern int tests_failed;
