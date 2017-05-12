/*
 * Copyright (C) 2011 by Opera Software Australia Pty Ltd
 *
 * This library is free software; you can redistribute it and/or modify
 * it under the same terms as Perl itself.
 */
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <fcntl.h>
#include <stdint.h>
#include "framework.h"

#define ROUNDUP(x, n) ((((x) + (n) - 1) / (n)) * (n))

void *expect_state(void *p, size_t sz, enum block_state state)
{
    static int fd = -1;
    static const char filename[] = "expected-blocks.dat";
    struct {
	uint64_t ptr;
	uint32_t sz;
	uint32_t state;
    } __attribute__((packed)) rec;
    if (fd < 0)
    {
	fd = open(filename, O_WRONLY|O_CREAT|O_TRUNC, 0644);
	if (fd < 0)
	{
	    perror(filename);
	    exit(1);
	}
    }
    rec.ptr = (uint64_t)p;
    rec.sz = (uint32_t)ROUNDUP(sz, 2*sizeof(void*));
    rec.state = (uint32_t)state;
    write(fd, &rec, sizeof(rec));
    return p;
}


