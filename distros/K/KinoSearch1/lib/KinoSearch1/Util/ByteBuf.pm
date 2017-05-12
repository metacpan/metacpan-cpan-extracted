package KinoSearch1::Util::ByteBuf;
use strict;
use warnings;
use KinoSearch1::Util::ToolSet;
use base qw( KinoSearch1::Util::CClass );

1;

__END__

__H__

#ifndef H_KINOSEARCH_UTIL_BYTEBUF
#define H_KINOSEARCH_UTIL_BYTEBUF 1

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "KinoSearch1UtilCarp.h"
#include "KinoSearch1UtilMemManager.h"

typedef struct bytebuf {
    char *ptr;
    I32   size; /* number of valid chars */
    I32   cap;  /* allocated bytes, including any null termination */
    U32   flags;
} ByteBuf;


ByteBuf* Kino1_BB_new(I32);
ByteBuf* Kino1_BB_new_string(char*, I32);
ByteBuf* Kino1_BB_new_view(char*, I32);
ByteBuf* Kino1_BB_clone(ByteBuf*);
void     Kino1_BB_assign_view(ByteBuf*, char*, I32);
void     Kino1_BB_assign_string(ByteBuf*, char*, I32);
void     Kino1_BB_cat_string(ByteBuf*, char*, I32);
void     Kino1_BB_grow(ByteBuf*, I32);
I32      Kino1_BB_compare(ByteBuf*, ByteBuf*);
void     Kino1_BB_destroy(ByteBuf*);

#endif /* include guard */

__C__

#include "KinoSearch1UtilByteBuf.h"

#define KINO_BB_VIEW 0x1

/* Return a pointer to a new ByteBuf capable of holding a string of [size]
 * bytes.  Though the ByteBuf's size member is set, none of the allocated
 * memory is initialized. 
 */
ByteBuf*
Kino1_BB_new(I32 size) {
    ByteBuf *bb;

    /* allocate */
    Kino1_New(0, bb, 1, ByteBuf);
    Kino1_New(0, bb->ptr, size + 1, char);

    /* assign */
    bb->size  = size;
    bb->cap   = size + 1;
    bb->flags = 0;
    
    return bb;
}

/* Return a pointer to a new ByteBuf which holds a copy of the passed in
 * string.
 */
ByteBuf*
Kino1_BB_new_string(char *ptr, I32 size) {
    ByteBuf *bb;

    /* allocate */
    Kino1_New(0, bb, 1, ByteBuf);
    Kino1_New(0, bb->ptr, size + 1, char);

    /* copy */
    Copy(ptr, bb->ptr, size, char);

    /* assign */
    bb->size      = size;
    bb->cap       = size + 1; 
    bb->ptr[size] = '\0'; /* null terminate */
    bb->flags     = 0;
    
    return bb;
}

/* Return a pointer to a new "view" ByteBuf, offing a persective on the passed
 * in string.
 */
ByteBuf*
Kino1_BB_new_view(char *ptr, I32 size) {
    ByteBuf *bb;

    /* allocate */
    Kino1_New(0, bb, 1, ByteBuf);

    /* assign */
    bb->ptr   = ptr;
    bb->size  = size;
    bb->cap   = 0; 
    bb->flags = 0 | KINO_BB_VIEW;
    
    return bb;
}

/* Return a "real" copy of the ByteBuf (regardless of whether it was a "view"
 * ByteBuf before).
 */
ByteBuf*
Kino1_BB_clone(ByteBuf *bb) {
    if (bb == NULL)
        return NULL;
    else 
        return Kino1_BB_new_string(bb->ptr, bb->size);
}

/* Assign the ptr and size members to the passed in values.  Downgrade the
 * ByteBuf to a "view" ByteBuf and free any existing assigned memory if
 * necessary.
 */
void
Kino1_BB_assign_view(ByteBuf *bb, char*ptr, I32 size) {
    /* downgrade the ByteBuf to a view */
    if (!bb->flags & KINO_BB_VIEW) {
        Kino1_Safefree(bb->ptr);
        bb->flags |= KINO_BB_VIEW;
    }

    /* assign */
    bb->ptr = ptr;
    bb->size = size;
}

/* Copy the passed-in string into the ByteBuf.  Allocate more memory if
 * necessary. 
 */
void
Kino1_BB_assign_string(ByteBuf *bb, char* ptr, I32 size) {
    Kino1_BB_grow(bb, size);
    Copy(ptr, bb->ptr, size, char);
    bb->size = size;
}

/* Concatenate the passed-in string onto the end of the ByteBuf. Allocate more
 * memory as needed.
 */
void 
Kino1_BB_cat_string(ByteBuf *bb, char* ptr, I32 size) {
    I32 new_size;
    new_size = bb->size + size;
    Kino1_BB_grow(bb, new_size);
    Copy(ptr, (bb->ptr + bb->size), size, char);
    bb->size = new_size;
}

/* Assign more memory to the ByteBuf, if it doesn't already have enough room
 * to hold a string of [size] bytes.  Cannot shrink the allocation.
 */
void 
Kino1_BB_grow(ByteBuf *bb, I32 new_size) {
    if (bb->flags & KINO_BB_VIEW)
        Kino1_confess("grow called on 'view' ByteBuf");

    /* bail out if the buffer's already at least as big as required */
    if (bb->cap > new_size)
        return;

    Kino1_Renew(bb->ptr, (new_size + 1), char);
    bb->cap = new_size;
}

void 
Kino1_BB_destroy(ByteBuf *bb) {
    if (bb == NULL)
        return;
    
    if (!(bb->flags & KINO_BB_VIEW))
        Kino1_Safefree(bb->ptr);
    Kino1_Safefree(bb);
}

/* Lexically compare two ByteBufs.
 */
I32 
Kino1_BB_compare(ByteBuf *a, ByteBuf *b) {
    I32 size;
    I32 comparison;

    size       = a->size < b->size ? a->size : b->size;
    comparison = memcmp(a->ptr, b->ptr, size);

    if (comparison == 0 && a->size != b->size) 
        comparison = a->size < b->size ? -1 : 1;

    return comparison;
}

__POD__

==begin devdocs

==head1 NAME

KinoSearch1::Util::ByteBuf - stripped down scalar

==head1 DESCRIPTION

The ByteBuf is a C struct that's essentially a growable string of char.  It's
like a stripped down scalar that can only deal with strings.  It knows its own
size and capacity, so it can contain arbitrary binary data.

"View" ByteBufs don't own their own strings.  

==head1 COPYRIGHT

Copyright 2005-2010 Marvin Humphrey

==head1 LICENSE, DISCLAIMER, BUGS, etc.

See L<KinoSearch1> version 1.01.

==end devdocs
==cut

