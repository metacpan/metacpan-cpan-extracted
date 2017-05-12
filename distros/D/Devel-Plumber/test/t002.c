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
    struct foo *left;
    struct foo *right;
    int x;
    char y[12];
};

struct foo *dataptr = (struct foo *)0x100;
struct foo *bssptr;
struct foo *bssarray[5];
struct foo *dataarray[5] = {
	(struct foo *)0x100,
	(struct foo *)0x100,
	(struct foo *)0x100,
	(struct foo *)0x100,
	(struct foo *)0x100
};
struct foo **ptrarray = (struct foo **)0x100;
struct foo *dataloop = (struct foo *)0x100;
struct foo *bssloop;

static struct foo *new_foo(void)
{
    struct foo *f = (struct foo *)malloc(sizeof(struct foo));
    static int nextx = 1;
    assert(f);
    memset(f, 0, sizeof(*f));
    f->x = nextx++;
    return f;
}

static struct foo *new_foo_loop(int n, enum block_state state)
{
    int i;
    struct foo *loop = NULL;
    struct foo *f = NULL;

    for (i = 0 ; i < n ; i++)
	f = *(f ? &f->left : &loop) = EXPECT(new_foo(), state);
    f->left = loop;
    return loop;
}

int main(int argc, char **argv)
{
    /* allocate some memory and free it again */
    free(new_foo());

    /* block never freed, reached from .data */
    dataptr = EXPECT_REACHED(new_foo());

    /* block never freed, reached from .bss */
    bssptr = EXPECT_REACHED(new_foo());

    /* block never freed, not reached */
    EXPECT_LEAKED(new_foo());

    /* blocks never freed, reached from .data */
    dataarray[0] = EXPECT_REACHED(new_foo());
    dataarray[1] = EXPECT_REACHED(new_foo());
    dataarray[2] = EXPECT_REACHED(new_foo());
    dataarray[4] = EXPECT_REACHED(new_foo());
    dataarray[4]->left = EXPECT_REACHED(new_foo());
    dataarray[4]->left->left = EXPECT_REACHED(new_foo());

    /* blocks never freed, reached from .bss */
    bssarray[0] = EXPECT_REACHED(new_foo());
    bssarray[0]->left = EXPECT_REACHED(new_foo());
    bssarray[0]->left->left = EXPECT_REACHED(new_foo());
    bssarray[0]->left->right = EXPECT_REACHED(new_foo());
    bssarray[1] = EXPECT_REACHED(new_foo());
    bssarray[2] = EXPECT_REACHED(new_foo());
    bssarray[4] = EXPECT_REACHED(new_foo());
    bssarray[4]->left = EXPECT_REACHED(new_foo());

    /* blocks never freed, reached from allocated array
     * which is reached from .data */
    ptrarray = (struct foo **)malloc(6*sizeof(struct foo*));
    assert(ptrarray);
    expect_state(ptrarray, 6*sizeof(struct foo*), REACHED);
    memset(ptrarray, 0, 6*sizeof(struct foo*));
    ptrarray[0] = EXPECT_REACHED(new_foo());
    ptrarray[0]->left = EXPECT_REACHED(new_foo());
    ptrarray[0]->left->left = EXPECT_REACHED(new_foo());
    ptrarray[0]->left->right = EXPECT_REACHED(new_foo());
    ptrarray[1] = EXPECT_REACHED(new_foo());
    ptrarray[2] = EXPECT_REACHED(new_foo());
    ptrarray[4] = EXPECT_REACHED(new_foo());
    ptrarray[4]->left = EXPECT_REACHED(new_foo());

    /* loop of blocks never freed, reached from .data */
    dataloop = new_foo_loop(5, REACHED);

    /* loop of blocks never freed, reached from .bss */
    bssloop = new_foo_loop(5, REACHED);

    /* loop of blocks never freed, not reached */
    new_foo_loop(5, LEAKED);

    FINISH_TEST;
    return 0;
}
