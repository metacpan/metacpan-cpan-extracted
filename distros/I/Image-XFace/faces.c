/*
 * faces.c:
 * Wrapper for compface/uncompface.
 *
 * Copyright (c) 2002 Chris Lightfoot. All rights reserved.
 * Email: chris@ex-parrot.com; WWW: http://www.ex-parrot.com/~chris/
 *
 */

static const char rcsid[] = "$Id: faces.c,v 1.1.1.1 2002/02/17 23:09:57 chris Exp $";

#include <compface.h>
#include <string.h>

/* compface and uncompface present a foul interface. */
char *do_compface(const char *face) {
    static char buf[4096];  /* XXX */
    strcpy(buf, face);
    if (compface(buf) < 0)
        return NULL;
    else
        return buf;
}

char *do_uncompface(const char *face) {
    static char buf[4096];  /* XXX */
    strcpy(buf, face);
    if (uncompface(buf) < 0)
        return NULL;
    else
        return buf;
}
