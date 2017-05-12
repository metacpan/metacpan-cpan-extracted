package KinoSearch1::Util::MemManager;

1;

__END__

__H__

#ifndef H_KINO_MEM_MANAGER
#define H_KINO_MEM_MANAGER 1

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "KinoSearch1UtilCarp.h"

/* Set this to 1 to enable debugging.  */
#define KINO_MEM_LEAK_DEBUG 0

#if KINO_MEM_LEAK_DEBUG
    #define Kino1_New(x,v,n,t) \
        (v = (t*)Kino1_New_wrapper(x,(n*sizeof(t))))
    #define Kino1_Newz(x,v,n,t) \
        (v = (t*)Kino1_Newz_wrapper(x,(n*sizeof(t))))
    #define Kino1_Renew(v,n,t) \
        (v = (t*)Kino1_Renew_wrapper(v, n*sizeof(t)))
    #define Kino1_Safefree(x) \
        Kino1_Safefree_wrapper(x)
    #define Kino1_savepvn(p,n) \
        Kino1_savepvn_wrapper(p,n)
#else
    #define Kino1_New(x,v,n,t) New(x,v,n,t)
    #define Kino1_Newz(x,v,n,t) Newz(x,v,n,t)
    #define Kino1_Renew(v,n,t) Renew(v,n,t)
    #define Kino1_Safefree(v) Safefree(v)
    #define Kino1_savepvn(p,n) savepvn(p,n)
#endif

void* Kino1_New_wrapper(int, size_t);
void* Kino1_Newz_wrapper(int, size_t);
void* Kino1_Renew_wrapper(void*, size_t);
void  Kino1_Safefree_wrapper(void*);
char* Kino1_savepvn_wrapper(const char*, I32);

#endif /* include guard */

__C__

#include "KinoSearch1UtilMemManager.h"

void*
Kino1_New_wrapper(int x, size_t num) {
    void* ptr;
    ptr = malloc(num); 
    return ptr;
}

void*
Kino1_Newz_wrapper(int x, size_t num) {
    char* ptr;
    ptr = (char*)malloc(num); 
    memset(ptr, 0, num);
    return (void*)ptr;
}

void*
Kino1_Renew_wrapper(void* ptr, size_t num) {
    void* new_ptr;
    new_ptr = realloc(ptr, num);
    return new_ptr;
}

void
Kino1_Safefree_wrapper(void* ptr) {
    /* Safefree(ptr); */
    free(ptr);
}

char* 
Kino1_savepvn_wrapper(const char* pv, I32 len) {
    char* ptr;
    ptr = (char*)malloc(len + 1);
    if (ptr == NULL) 
        Kino1_confess("Out of memory");
    ptr[len] = '\0';
    memcpy(ptr, pv, len);
    return ptr;
}

__POD__

==begin devdocs

==head1 NAME

KinoSearch1::Util::MemManager - wrappers which aid memory debugging

==head1 DESCRIPTION

In normal mode, the C functions in this module are macro aliases for Perl's
memory management tools.  In debug mode, memory management passes through
local functions which make hunting down bugs with Valgrind easier.

No Perl interface.

==head1 COPYRIGHT

Copyright 2005-2010 Marvin Humphrey

==head1 LICENSE, DISCLAIMER, BUGS, etc.

See L<KinoSearch1> version 1.01.

==end devdocs
==cut
