/*
 * SimpleModule::Bar - Another simple test module with C code
 */

#include <string.h>
#include <stdlib.h>

/* C helper functions */
static char *bar_reverse(const char *str) {
    size_t len = strlen(str);
    char *result = (char *)malloc(len + 1);
    if (!result) return NULL;

    for (size_t i = 0; i < len; i++) {
        result[i] = str[len - 1 - i];
    }
    result[len] = '\0';
    return result;
}

static int bar_strlen(const char *str) {
    return (int)strlen(str);
}

static int bar_is_palindrome(const char *str) {
    size_t len = strlen(str);
    for (size_t i = 0; i < len / 2; i++) {
        if (str[i] != str[len - 1 - i]) {
            return 0;
        }
    }
    return 1;
}

MODULE = SimpleModule    PACKAGE = SimpleModule::Bar

PROTOTYPES: DISABLE

SV *
reverse_string(str)
    const char *str
CODE:
    char *reversed = bar_reverse(str);
    if (reversed) {
        RETVAL = newSVpv(reversed, 0);
        free(reversed);
    } else {
        RETVAL = &PL_sv_undef;
    }
OUTPUT:
    RETVAL

int
string_length(str)
    const char *str
CODE:
    RETVAL = bar_strlen(str);
OUTPUT:
    RETVAL

int
is_palindrome(str)
    const char *str
CODE:
    RETVAL = bar_is_palindrome(str);
OUTPUT:
    RETVAL
