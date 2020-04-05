#include <string.h>
#include <stdlib.h>


char *
strndup(const char *s, size_t n)
{
    char *p = memchr(s, 0, n);
    if (p != NULL) n = p - s;
    p = malloc(n + 1);
    if (!p) return NULL;
    memcpy(p, s, n);
    p[n] = '\0';
    return p;
}