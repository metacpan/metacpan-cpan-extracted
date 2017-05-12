/*
 * Copyright (C) 2011 by Opera Software Australia Pty Ltd
 *
 * This library is free software; you can redistribute it and/or modify
 * it under the same terms as Perl itself.
 */

/* this matches up with Plumber's internal states */
enum block_state { FREE, LEAKED, MAYBE, REACHED };

extern void *expect_state(void *p, size_t sz, enum block_state state);

#define EXPECT(p, state) \
    ({ \
	typeof(p) _p = (p); \
	(typeof(p)) expect_state((void *)_p, sizeof(*_p), (state)); \
    })
#define EXPECT_FREE(p)	    EXPECT(p, FREE)
#define EXPECT_LEAKED(p)    EXPECT(p, LEAKED)
#define EXPECT_MAYBE(p)	    EXPECT(p, MAYBE)
#define EXPECT_REACHED(p)   EXPECT(p, REACHED)

    /* dump core */
#define FINISH_TEST \
    *((char *)0) = 0
