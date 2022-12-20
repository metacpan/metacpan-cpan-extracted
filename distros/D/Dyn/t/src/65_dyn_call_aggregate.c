#include "std.h"

typedef struct
{ // {ifdcj}
    int i;
    float f;
    double d;
    char c;
    long j;
} structure;

DLLEXPORT int offset(char elm) {
    switch (elm) {
    case 'i':
        return offsetof(structure, i);
    case 'f':
        return offsetof(structure, f);
    case 'd':
        return offsetof(structure, d);
    case 'c':
        return offsetof(structure, c);
    case 'j':
        return offsetof(structure, j);
    }
}
