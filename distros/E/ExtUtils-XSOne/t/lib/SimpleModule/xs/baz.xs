/*
 * SimpleModule::Baz - Array operations with C code
 */

#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include <stdlib.h>

/* C helper functions */
static int baz_sum_array(int *arr, int len) {
    int sum = 0;
    for (int i = 0; i < len; i++) {
        sum += arr[i];
    }
    return sum;
}

static int baz_max_array(int *arr, int len) {
    if (len == 0) return 0;
    int max = arr[0];
    for (int i = 1; i < len; i++) {
        if (arr[i] > max) max = arr[i];
    }
    return max;
}

static int baz_min_array(int *arr, int len) {
    if (len == 0) return 0;
    int min = arr[0];
    for (int i = 1; i < len; i++) {
        if (arr[i] < min) min = arr[i];
    }
    return min;
}

MODULE = SimpleModule    PACKAGE = SimpleModule::Baz

PROTOTYPES: DISABLE

int
sum(...)
CODE:
    int *arr = (int *)malloc(items * sizeof(int));
    if (!arr) croak("Memory allocation failed");

    for (int i = 0; i < items; i++) {
        arr[i] = SvIV(ST(i));
    }

    RETVAL = baz_sum_array(arr, items);
    free(arr);
OUTPUT:
    RETVAL

int
max(...)
CODE:
    if (items == 0) {
        RETVAL = 0;
    } else {
        int *arr = (int *)malloc(items * sizeof(int));
        if (!arr) croak("Memory allocation failed");

        for (int i = 0; i < items; i++) {
            arr[i] = SvIV(ST(i));
        }

        RETVAL = baz_max_array(arr, items);
        free(arr);
    }
OUTPUT:
    RETVAL

int
min(...)
CODE:
    if (items == 0) {
        RETVAL = 0;
    } else {
        int *arr = (int *)malloc(items * sizeof(int));
        if (!arr) croak("Memory allocation failed");

        for (int i = 0; i < items; i++) {
            arr[i] = SvIV(ST(i));
        }

        RETVAL = baz_min_array(arr, items);
        free(arr);
    }
OUTPUT:
    RETVAL
