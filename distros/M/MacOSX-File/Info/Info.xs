/*
 * $Id: Info.xs,v 0.70 2005/08/09 15:47:00 dankogai Exp $
 */

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

static int
not_here(char *s)
{
    croak("%s not implemented on this architecture", s);
    return -1;
}

#include "common/util.c"
#include "common/macdate.c"
#include <Finder.h>

/* #define CATALOGINFONEEDED kFSCatInfoGettableInfo */
#define CATALOGINFONEEDED (kFSCatInfoNodeFlags|kFSCatInfoCreateDate|kFSCatInfoContentMod|kFSCatInfoFinderInfo)

#define NUMMEMBERSINFO 7

static SV *
xs_getfinfo(char *path){
    FSRef  Ref;
    FSSpec Spec;
    FSCatalogInfo Catalog;
    FInfo  *finfo = (FInfo *)(&Catalog.finderInfo);

    SV*   sva[NUMMEMBERSINFO];
    OSErr err;

    if (err = FSPathMakeRef(path, &Ref, NULL)){
	seterr(err);
	return &PL_sv_undef;
    }
    
    /* 
     * to make it work with both directory and file, we
     * use FSGetCatalogInfo() instead of FSGetFInfo()
     */

    if (err = FSGetCatalogInfo(&Ref,
			       CATALOGINFONEEDED,
			       &Catalog,
			       NULL,
			       NULL,
			       NULL))
    {
	seterr(err);
	return &PL_sv_undef;
    }

    sva[0] =  sv_2mortal(newSVpv((char *)&Ref, sizeof(Ref)));
    sva[1] =  sv_2mortal(newSViv(Catalog.nodeFlags));

    if (kFSNodeIsDirectoryMask & Catalog.nodeFlags){
	sva[2] =  sv_2mortal(newSVpv("", 0));
	sva[3] =  sv_2mortal(newSVpv("", 0));
    }else{
	sva[2] =  sv_2mortal(newSVpv(Catalog.finderInfo, 4));
	sva[3] =  sv_2mortal(newSVpv(Catalog.finderInfo+4, 4));
    }

    sva[4] =  sv_2mortal(newSVuv(finfo->fdFlags));

    sva[5] =  sv_2mortal(newSVnv(UDT2D(&Catalog.createDate)));
    sva[6] =  sv_2mortal(newSVnv(UDT2D(&Catalog.contentModDate)));

    return newRV_noinc((SV *)av_make(NUMMEMBERSINFO, sva));
 }

static int
xs_setfinfo(
    SV   *svref,
    unsigned int  nodeFlags,
    unsigned char *type,
    unsigned char *creator,
    unsigned int  fdFlags,
    double        ctime,
    double        mtime,
    char          *path
    )
{
    FSRef  Ref, *rp;
    FSSpec Spec;
    FSCatalogInfo Catalog;
    FInfo  *finfo = (FInfo *)(&Catalog.finderInfo);
    OSErr err;

    if (path != NULL && strlen(path) != 0){
	if (err = FSPathMakeRef(path, &Ref, NULL)){
	    return seterr(err);
	}else{
	    rp = &Ref;
	}
    }else{
	rp = (FSRef *)SvPV_nolen(svref);
    }

    /* prefetch destination catalog; may be used for file locks */
    if (err = FSGetCatalogInfo(rp,
			       kFSCatInfoSettableInfo|kFSCatInfoNodeFlags,
			       &Catalog,
			       NULL, NULL, NULL))
    {
	return seterr(err);
    }
    
    /* 
     * unlock the file first.
     * Note FSp(Rst|Set)FLock dies with segfault when applied to
     * directories! 
     */

    FSRef2FSSpec(rp, &Spec);

    if (!(Catalog.nodeFlags & kFSNodeIsDirectoryMask)){
	if (err = FSpRstFLock(&Spec)){
	    return seterr(err);
	}
    }

    /* now set Catalog */

    Catalog.nodeFlags = nodeFlags;
    finfo->fdType    = char2OSType(type);
    finfo->fdCreator = char2OSType(creator);
    finfo->fdFlags =  fdFlags;
    D2UDT(ctime, &Catalog.createDate);
    D2UDT(mtime, &Catalog.contentModDate);

    if (err = FSSetCatalogInfo(rp, CATALOGINFONEEDED, &Catalog)){
	return seterr(err);
    }

    /* Lock the File if neccesary */

    if (!(Catalog.nodeFlags & kFSNodeIsDirectoryMask)){
	if (Catalog.nodeFlags & kFSNodeLockedMask){
	    err = FSpSetFLock(&Spec);
	}
    }

    return seterr(err);
}

MODULE = MacOSX::File::Info		PACKAGE = MacOSX::File::Info	

PROTOTYPES: ENABLE

SV *
xs_getfinfo(path)
    char *path;
    CODE:
        RETVAL = xs_getfinfo(path);
    OUTPUT:
	RETVAL

int
xs_setfinfo(svref, nodeFlags, type, creator, fdFlags, ctime, mtime, path)
    SV   *svref;
    unsigned int  nodeFlags;
    unsigned char *type;
    unsigned char *creator;
    unsigned int  fdFlags;
    double        ctime;
    double        mtime;
    char          *path;
    CODE:
        RETVAL = xs_setfinfo(svref, nodeFlags, type, creator, 
			     fdFlags, ctime, mtime, path);
    OUTPUT:
        RETVAL
