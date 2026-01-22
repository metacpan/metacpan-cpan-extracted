/*
 * SimpleModule::Foo - Simple test module with C code
 */

#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <math.h>

/* C helper functions */
static int foo_add(int a, int b) {
    return a + b;
}

static int foo_multiply(int a, int b) {
    return a * b;
}

static double foo_sqrt(double x) {
    return sqrt(x);
}

MODULE = SimpleModule    PACKAGE = SimpleModule::Foo

PROTOTYPES: DISABLE

int
add(a, b)
    int a
    int b
CODE:
    RETVAL = foo_add(a, b);
OUTPUT:
    RETVAL

int
multiply(a, b)
    int a
    int b
CODE:
    RETVAL = foo_multiply(a, b);
OUTPUT:
    RETVAL

double
sqrt_val(x)
    double x
CODE:
    RETVAL = foo_sqrt(x);
OUTPUT:
    RETVAL
