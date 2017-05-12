#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "Judy.h"
#include "pjudy.h"

MODULE = MAGIC PACKAGE = MAGIC PREFIX = magic_

PROTOTYPES: DISABLE

void
magic_get_Pvoid_t( x )
        Pvoid_t x
    CODE:

Pvoid_t
magic_set_Pvoid_t1()
    CODE:
        RETVAL = (Pvoid_t)3;
     OUTPUT:
        RETVAL

void
magic_set_Pvoid_t2( x )
        Pvoid_t x
    CODE:
        x = (Pvoid_t)4;
    OUTPUT:
        x

void
magic_get_IWord_t( x )
        IWord_t x
    CODE:

IWord_t
magic_set_IWord_t1()
    CODE:
        RETVAL = 6;
     OUTPUT:
        RETVAL

void
magic_set_IWord_t2( x )
        IWord_t x
    CODE:
        x = 7;
    OUTPUT:
        x

void
magic_get_UWord_t( x )
        UWord_t x
    CODE:

UWord_t
magic_set_UWord_t1()
    CODE:
        RETVAL = 6;
     OUTPUT:
        RETVAL

void
magic_set_UWord_t2( x )
        UWord_t x
    CODE:
        x = 7;
    OUTPUT:
        x

void
magic_get_PWord_t( x )
        PWord_t x
    CODE:

PWord_t
magic_set_PWord_t1()
    CODE:
        RETVAL = (PWord_t)9;
     OUTPUT:
        RETVAL

void
magic_set_PWord_t2( x )
        PWord_t x
    CODE:
        x = (PWord_t)10;
    OUTPUT:
        x

void
magic_get_Str( x )
        Str x
    CODE:
        

Str
magic_set_Str1()
    CODE:
        RETVAL.ptr = "bb\0cc";
        RETVAL.length = 5;
    OUTPUT:
        RETVAL

void
magic_set_Str2( out )
        Str out
    CODE:
        out.ptr = "cc\0dd";
        out.length = 5;
    OUTPUT:
        out

Str
magic_set_Str3()
    CODE:
        RETVAL.ptr = "ee";
        RETVAL.length = 0;
    OUTPUT:
        RETVAL

void
magic_set_Str4( out )
        Str out
    CODE:
        out.ptr = "ff";
        out.length = 0;
    OUTPUT:
        out
