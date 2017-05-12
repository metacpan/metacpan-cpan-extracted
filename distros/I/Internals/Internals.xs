

/*****************************************************************************/
/*                                                                           */
/*    Copyright (c) 2001 by Steffen Beyer.                                   */
/*    All rights reserved.                                                   */
/*                                                                           */
/*    This package is free software; you can redistribute it                 */
/*    and/or modify it under the same terms as Perl itself.                  */
/*                                                                           */
/*****************************************************************************/


#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"


#define INTERNALS_REFERENCE(ref,obj) ( ref && SvROK(ref) && (obj = SvRV(ref)) )

#define INTERNALS_NUMBER(ref,val)    ( ref && !(SvROK(ref)) && ((val = (U32)SvIV(ref)) | 1) )

#define INTERNALS_ERROR(name,error)  croak("Internals::" name "(): " error)

#define INTERNALS_NO_REFERENCE(name) INTERNALS_ERROR(name,"argument is not a reference")

#define INTERNALS_NO_NUMBER(name)    INTERNALS_ERROR(name,"argument is not a number")


MODULE = Internals		PACKAGE = Internals


PROTOTYPES: DISABLE


void
IsWriteProtected(ref)
SV *	ref
PPCODE:
{
    SV *obj;

    if ( INTERNALS_REFERENCE(ref,obj) )
    {
        PUSHs(sv_2mortal(newSViv((IV)( SvREADONLY(obj) ? 1 : 0 ))));
    }
    else INTERNALS_NO_REFERENCE("IsWriteProtected");
}


void
SetReadOnly(ref)
SV *	ref
PPCODE:
{
    SV *obj;

    if ( INTERNALS_REFERENCE(ref,obj) )
    {
        SvREADONLY_on(obj);
        PUSHs(sv_mortalcopy(ref));
    }
    else INTERNALS_NO_REFERENCE("SetReadOnly");
}


void
SetReadWrite(ref)
SV *	ref
PPCODE:
{
    SV *obj;

    if ( INTERNALS_REFERENCE(ref,obj) )
    {
        SvREADONLY_off(obj);
        PUSHs(sv_mortalcopy(ref));
    }
    else INTERNALS_NO_REFERENCE("SetReadWrite");
}


void
GetRefCount(ref)
SV *	ref
PPCODE:
{
    SV *obj;

    if ( INTERNALS_REFERENCE(ref,obj) )
    {
        PUSHs(sv_2mortal(newSViv((IV)( obj->sv_refcnt ))));
    }
    else INTERNALS_NO_REFERENCE("GetRefCount");
}


void
SetRefCount(ref,val)
SV *	ref
SV *	val
PPCODE:
{
    SV *obj;
    U32 cnt;

    if ( INTERNALS_REFERENCE(ref,obj) )
    {
        if ( INTERNALS_NUMBER(val,cnt) )
        {
            obj->sv_refcnt = cnt;
        }
        else INTERNALS_NO_NUMBER("SetRefCount");
    }
    else INTERNALS_NO_REFERENCE("SetRefCount");
}


