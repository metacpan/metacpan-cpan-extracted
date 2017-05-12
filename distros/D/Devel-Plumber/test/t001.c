/*
 * Copyright (C) 2011 by Opera Software Australia Pty Ltd
 *
 * This library is free software; you can redistribute it and/or modify
 * it under the same terms as Perl itself.
 */
#include <malloc.h>
#include <memory.h>
#include <assert.h>
#include "framework.h"

struct foo
{
    struct foo *left;	    /* 8 */
    struct foo *right;	    /* 8 */
    int x;		    /* 4 */
    char y[124];	    /* 124 */
};			    /* 144 = 0x90 */

/* gcc is smart; initialising to 0 is like not initialising
 * and results in a BSS symbol */
struct foo *dataptr = (struct foo *)0x100;
struct foo *bssptr;

static struct foo *new_foo(void)
{
    struct foo *f = (struct foo *)malloc(sizeof(struct foo));
    static int nextx = 1;
    assert(f);
    memset(f, 0, sizeof(*f));
    f->x = nextx++;
    return f;
}

int main(int argc, char **argv)
{
    struct foo *f;

    /* block allocated then freed - note, to ensure this actually
     * gets to be seen as free, we need to a) do no more allocations
     * so malloc() does not (sensibly) reuse it, and b) ensure it
     * is not the topmost block, which will be be merged when freed. */
    f = EXPECT_FREE(new_foo());

    /* block never freed, reached from .data */
    dataptr = EXPECT_REACHED(new_foo());

    /* block never freed, reached from .bss */
    bssptr = EXPECT_REACHED(new_foo());

    /* block never freed, not reached */
    EXPECT_LEAKED(new_foo());

    free(f);
    f = NULL;

    FINISH_TEST;
    return 0;
}
