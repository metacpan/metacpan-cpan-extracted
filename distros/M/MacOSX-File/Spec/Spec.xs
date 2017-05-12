#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

static int
not_here(char *s)
{
    croak("%s not implemented on this architecture", s);
    return -1;
}

#undef I_POLL
#include <Finder.h>
#include "common/util.c"

#define ClassName "MacOSX::File::Spec"

static SV *
new(char *class, char *path){
    OSErr   err;
    FSRef   ref;
    FSSpec  spec;
    FSSpec  *sp = &spec;
    SV      *self;

    if (strcmp(class, ClassName) != 0){ return NULL; };
    if (err = FSPathMakeRef(path, &ref, NULL)){ 
	seterr(err); return NULL;
    };
    if (err = FSGetCatalogInfo(&ref, kFSCatInfoNone,
			       NULL, NULL, 
			       &spec,  NULL)){
	seterr(err); return NULL;
    }
    self = newRV_noinc(newSVpv((char *)sp, sizeof(spec)));
    return sv_bless(self, gv_stashpv(ClassName, 1));

}

static SV *
vRefNum(SV *self){
    FSSpec *sp;
    if (self == NULL){ return NULL; }
    if (!SvROK(self)){ return NULL; }
    if (!sv_isa(self, ClassName)){ return NULL; };
    sp = (FSSpec *)SvPV_nolen(SvRV(self));
    return newSViv(sp->vRefNum);
}

static SV *
parID(SV *self){
    FSSpec *sp;
    if (self == NULL){ return NULL; }
    if (!SvROK(self)){ return NULL; }
    if (!sv_isa(self, ClassName)){ return NULL; };
    sp = (FSSpec *)SvPV_nolen(SvRV(self));
    return newSViv(sp->parID);
}

static SV *
name(SV *self){
    FSSpec *sp;
    if (self == NULL){ return NULL; }
    if (!SvROK(self)){ return NULL; }
    if (!sv_isa(self, ClassName)){ return NULL; };
    sp = (FSSpec *)SvPV_nolen(SvRV(self));
    return newSVpv((sp->name)+1, sp->name[0]);
}

char *
path(SV *self){
    FSSpec *sp;
    FSRef  ref;
    static char path[1024];
    if (self == NULL){ return NULL; }
    if (!SvROK(self)){ return NULL; }
    if (!sv_isa(self, ClassName)){ return NULL; };
    sp = (FSSpec *)SvPV_nolen(SvRV(self));
    FSpMakeFSRef(sp, &ref);
    FSRefMakePath(&ref, path, 1024);
    return path;
}


MODULE = MacOSX::File::Spec		PACKAGE = MacOSX::File::Spec	

PROTOTYPES: ENABLE

SV *
new(class, path)
    char *class;
    char *path;
    CODE:
        RETVAL = new(class, path);
    OUTPUT:
	RETVAL

SV *
vRefNum(self)
    SV *self;
    CODE:
        RETVAL = vRefNum(self);
    OUTPUT:
	RETVAL

SV *
parID(self)
    SV *self;
    CODE:
        RETVAL = parID(self);
    OUTPUT:
	RETVAL

SV *
name(self)
    SV *self;
    CODE:
        RETVAL = name(self);
    OUTPUT:
	RETVAL

char *
path(self)
    SV *self;
    CODE:
        RETVAL = path(self);
    OUTPUT:
	RETVAL

void
as_array(self)
    SV *self;
    PPCODE:
	if (SvROK(self) && sv_isa(self, ClassName)){
	    EXTEND(SP, 3);
	    PUSHs(sv_2mortal(vRefNum(self)));
	    PUSHs(sv_2mortal(parID(self)));
	    PUSHs(sv_2mortal(name(self)));
	}

