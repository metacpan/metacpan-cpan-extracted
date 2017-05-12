/*
 * $Id: Catalog.xs,v 0.70 2005/08/09 15:47:00 dankogai Exp $
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

static SV *
xs_getcatalog(char *path){
    FSRef  Ref;
    FSCatalogInfo Catalog;
    FInfo  *fip = (FInfo *)&Catalog.finderInfo;
    FXInfo *fxp = (FXInfo *)&Catalog.extFinderInfo;
    SV*   ret[21];
    SV*   permissions[4];
    SV*   finderInfo[5];
    SV*   fdLocation[2];
    SV*   extFinderInfo[5];
    OSErr err;
    int i;

    if (err = FSPathMakeRef(path, &Ref, NULL)){
	seterr(err) ; return &PL_sv_undef;
    }

    if (err = FSGetCatalogInfo(&Ref,
			       kFSCatInfoGettableInfo,
			       &Catalog,
			       NULL, NULL, NULL))
    
    {
	seterr(err) ; return &PL_sv_undef;
    }

    ret[0] = sv_2mortal(newSVpv((char *)&Ref, sizeof(Ref)));
    ret[1] = sv_2mortal(newSVuv(Catalog.nodeFlags));
    ret[2] = sv_2mortal(newSViv(Catalog.volume));
    ret[3] = sv_2mortal(newSVuv(Catalog.parentDirID));
    ret[4] = sv_2mortal(newSVuv(Catalog.nodeID));
    ret[5] = sv_2mortal(newSVuv(Catalog.sharingFlags));
    ret[6] = sv_2mortal(newSVuv(Catalog.userPrivileges));

    /*
    ret[] = sv_2mortal(newSViv(Catalog.reserved1));
    ret[] = sv_2mortal(newSViv(Catalog.reserved2));
    */

    /* dates are converted to double */

    ret[7]  = sv_2mortal(newSVnv(UDT2D(&Catalog.createDate)));
    ret[8]  = sv_2mortal(newSVnv(UDT2D(&Catalog.contentModDate)));
    ret[9]  = sv_2mortal(newSVnv(UDT2D(&Catalog.attributeModDate)));
    ret[10] = sv_2mortal(newSVnv(UDT2D(&Catalog.accessDate)));
    ret[11] = sv_2mortal(newSVnv(UDT2D(&Catalog.backupDate)));

    /* permission is stored as arrayref */
    for (i = 0; i < 4; i++){
	permissions[i] = sv_2mortal(newSVuv(Catalog.permissions[i]));
    }
    ret[12] = sv_2mortal(newRV_noinc((SV*)av_make(4, permissions)));

    /* finder info too, is stored as arrayref */

    finderInfo[0] = sv_2mortal(newSVpv((char *)&fip->fdType, 4));
    finderInfo[1] = sv_2mortal(newSVpv((char *)&fip->fdCreator, 4));
    finderInfo[2] = sv_2mortal(newSVuv(fip->fdFlags));

    fdLocation[0] = sv_2mortal(newSViv(fip->fdLocation.v));
    fdLocation[1] = sv_2mortal(newSViv(fip->fdLocation.h));
    finderInfo[3] = sv_2mortal(newRV_noinc((SV*)av_make(2, fdLocation)));

    finderInfo[4] = sv_2mortal(newSViv(fip->fdFldr));
    ret[13] = sv_2mortal(newRV_noinc((SV*)av_make(5,finderInfo)));

    /* extra finder info is stored as arraryref */

    extFinderInfo[0] = sv_2mortal(newSViv(fxp->fdIconID));
    extFinderInfo[1] = sv_2mortal(newSViv(fxp->fdScript));
    extFinderInfo[2] = sv_2mortal(newSViv(fxp->fdXFlags));
    extFinderInfo[3] = sv_2mortal(newSViv(fxp->fdComment));
    extFinderInfo[4] = sv_2mortal(newSViv(fxp->fdPutAway));
    ret[14] = sv_2mortal(newRV_noinc((SV*)av_make(5, extFinderInfo)));

    /* size of forks are stored in IV */
    /* to store 64bit value, we use NV instead of IV */

    ret[15] = sv_2mortal(newSVnv(Catalog.dataLogicalSize));
    ret[16] = sv_2mortal(newSVnv(Catalog.dataPhysicalSize));
    ret[17] = sv_2mortal(newSVnv(Catalog.rsrcLogicalSize));
    ret[18] = sv_2mortal(newSVnv(Catalog.rsrcPhysicalSize));
    
    /* these are UInt32 */
    ret[19] = sv_2mortal(newSVuv(Catalog.valence));
    ret[20] = sv_2mortal(newSVuv(Catalog.textEncodingHint));

    /* now return the result */
    return newRV_noinc((SV *)(av_make(21, ret)));
 }

xs_setcatalog(SV* self, char *path){
    SV**   svh;
    FSRef  Ref, *rp;
    FSSpec Spec;
    FSCatalogInfo Catalog;
    FInfo  *fip = (FInfo *)&Catalog.finderInfo;
    FXInfo *fxp = (FXInfo *)&Catalog.extFinderInfo;
    AV*    arg = (AV *)SvRV(self);
    AV*    permissions;
    AV*    finderInfo;
    AV*    fdLocation;
    AV*    extFinderInfo;
    OSErr err;
    int i;

    if (path != NULL && strlen(path) != 0){
	if (err = FSPathMakeRef(path, &Ref, NULL)){
	    return seterr(err);
	}else{
	    rp = &Ref;
	}
    }else{
	if (svh = av_fetch(arg, 0, 0)) rp = (FSRef *)SvPV_nolen(*svh);
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

    /* Now Let's set Catalog one by one */

    if (svh = av_fetch(arg, 1, 0)) Catalog.nodeFlags = SvUV(*svh);

    /* dates */
    if (svh = av_fetch(arg, 7, 0))
	D2UDT(SvNV(*svh), &Catalog.createDate);
    if (svh = av_fetch(arg, 8, 0))
	D2UDT(SvNV(*svh), &Catalog.contentModDate);
    if (svh = av_fetch(arg, 9, 0))
	D2UDT(SvNV(*svh),&Catalog.attributeModDate);
    if (svh = av_fetch(arg, 10, 0))
	D2UDT(SvNV(*svh), &Catalog.accessDate);
    if (svh = av_fetch(arg, 11, 0))
	D2UDT(SvNV(*svh), &Catalog.backupDate);

    /* permissions is stored as arrayref */
    if (svh = av_fetch(arg, 12, 0)){
	permissions = (AV *)SvRV(*svh);
	for (i = 0; i < 4; i++){
	    if (svh = av_fetch(permissions, i, 0))
		Catalog.permissions[i] = SvUV(*svh);
	}
    }

    /* finder info too, is stored as arrayref */

    if (svh = av_fetch(arg, 13, 0)){
	finderInfo = (AV *)SvRV(*svh);
	if (svh = av_fetch(finderInfo, 0, 0)) 
	    fip->fdType = char2OSType(SvPVX(*svh));
	if (svh = av_fetch(finderInfo, 1, 0))
	    fip->fdCreator = char2OSType(SvPVX(*svh));
	if (svh = av_fetch(finderInfo, 2, 0)) 
	    fip->fdFlags = SvUV(*svh);
	/* fdLocation */
	if (svh = av_fetch(finderInfo, 3, 0)){
	    fdLocation = (AV *)SvRV(*svh); 
	    if (svh = av_fetch(fdLocation, 0, 0))
		fip->fdLocation.v = SvIV(*svh);
	    if (svh = av_fetch(fdLocation, 1, 0))
		fip->fdLocation.h = SvIV(*svh);
	}
	/* and fdFldr */
	if (svh = av_fetch(finderInfo, 4, 0)) fip->fdFldr = SvIV(*svh);
    }

    /* extra finder info is stored as arraryref */
    if (svh = av_fetch(arg, 14, 0)){
	extFinderInfo = (AV *)SvRV(*svh);
	if (svh = av_fetch(extFinderInfo, 0, 0)) fxp->fdIconID = SvIV(*svh);
	if (svh = av_fetch(extFinderInfo, 1, 0)) fxp->fdScript = SvIV(*svh);
	if (svh = av_fetch(extFinderInfo, 2, 0)) fxp->fdXFlags = SvIV(*svh);
	if (svh = av_fetch(extFinderInfo, 3, 0)) fxp->fdComment = SvIV(*svh);
    }

    /* And at last, textEncodingHint */
    if (svh = av_fetch(arg, 20, 0)) Catalog.textEncodingHint = SvUV(*svh);

    /* now set it! */
    if (err = FSSetCatalogInfo(rp,
			       kFSCatInfoSettableInfo,
			       &Catalog))
    {
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

static char *
xs_fsref2path(SV *svref){
    static char path[1024];
    FSRef *rp = (FSRef *)SvPV_nolen(svref);
    FSRefMakePath(rp, path, 1024);
    return path;
}

MODULE = MacOSX::File::Catalog		PACKAGE = MacOSX::File::Catalog	

PROTOTYPES: ENABLE

SV *
xs_getcatalog(path)
    char *path;
    CODE:
        RETVAL = xs_getcatalog(path);
    OUTPUT:
	RETVAL

SV *
xs_setcatalog(self, path)
    SV*   self;
    char* path;
    CODE:
        RETVAL = xs_setcatalog(self, path);
    OUTPUT:
	RETVAL

char *
xs_fsref2path(svref)
    SV *svref;
    CODE:
	RETVAL = xs_fsref2path(svref);
    OUTPUT:
	RETVAL
