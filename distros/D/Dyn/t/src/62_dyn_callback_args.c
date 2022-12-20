#include "std.h"

typedef int (*f)(int);

DLLEXPORT int TakeCallback(f cb) {
    return cb(101); // Very simple... returns value from cb
}
