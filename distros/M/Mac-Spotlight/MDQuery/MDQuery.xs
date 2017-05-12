#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include </System/Library/Frameworks/CoreServices.framework/Versions/A/Frameworks/Metadata.framework/Versions/A/Headers/MDQuery.h>


MODULE = Mac::Spotlight::MDQuery		PACKAGE = Mac::Spotlight::MDQuery		


CFStringRef
kMDQueryScopeHome()
=item Would it be more efficient to do a PPCODE that pushes the object
      pointer? Do we care?
=cut
CODE:
    RETVAL = kMDQueryScopeHome;
OUTPUT:
    RETVAL


CFStringRef
kMDQueryScopeComputer()
CODE:
    RETVAL = kMDQueryScopeComputer;
OUTPUT:
    RETVAL


CFStringRef
kMDQueryScopeNetwork()
CODE:
    RETVAL = kMDQueryScopeNetwork;
OUTPUT:
    RETVAL


MDQueryRef
_new(queryString)
    char*    queryString
CODE:
    CFStringRef query = CFStringCreateWithCString(kCFAllocatorDefault, queryString, CFStringGetSystemEncoding());
    RETVAL = (MDQueryRef)MDQueryCreate(kCFAllocatorDefault, query, NULL, NULL);
    CFRelease(query);
    if (RETVAL == NULL)
        RETVAL = nil;
OUTPUT:
    RETVAL


void
_setSearchScope(query, scopes)
    MDQueryRef    query
    AV*           scopes
PREINIT:
    int x;
    void** itemsList;
    SV** itemPtr;
    IV cfItem;
CODE:
    itemsList = (void**)malloc(sizeof(void*) * (av_len(scopes)+1));
    for (x = 0; x <= av_len(scopes); x++) {
        itemPtr = av_fetch(scopes, x, 0);
        if (sv_derived_from(*itemPtr, "CFStringRef")) {
            cfItem = SvIV((SV*)SvRV(*itemPtr));
            cfItem = INT2PTR(CFStringRef, cfItem);
            if (CFGetTypeID(cfItem) != CFStringGetTypeID())
                Perl_croak(aTHX_ "setScope was passed something not a string!");
            itemsList[x] = cfItem;
        }
        else if (SvPOK(*itemPtr))
            itemsList[x] = CFStringCreateWithCString(kCFAllocatorDefault,
                                                     SvPV_nolen(*itemPtr),
                                                     CFStringGetSystemEncoding());
        else
            Perl_croak(aTHX_ "setScope was passed something not a string!");
    }
    CFArrayRef scopesList = CFArrayCreate(kCFAllocatorDefault,
                                          (const void**)itemsList,
					  av_len(scopes) + 1, 
                                          NULL);
    MDQuerySetSearchScope(query, scopesList, 0);
    CFRelease(scopesList);
    free(itemsList);

SV*
_execute(query)
    MDQueryRef    query
CODE:
    if (!MDQueryExecute(query, kMDQuerySynchronous))
        RETVAL = newSV(0);
    else
        RETVAL = newSV(1);
OUTPUT:
    RETVAL 


void
_stop(query)
    MDQueryRef    query
CODE:
    MDQueryStop(query);


void
_getResults(query)
    MDQueryRef    query
PPCODE:
    CFIndex x;
    SV* tmpHash;
    SV* tmpScalar;
    int i = MDQueryGetResultCount(query);
    for (x = 0; x < i; x++) {
        tmpHash = sv_2mortal((SV*)newHV());
	tmpScalar = newSVsv(&PL_sv_undef);
	sv_setref_pv(tmpScalar, "MDItemRef", (void*)MDQueryGetResultAtIndex(query, x));
	hv_store((HV*)tmpHash, "mdiObj", 6, tmpScalar, 0);
	XPUSHs(sv_bless(sv_2mortal(newRV(tmpHash)), gv_stashpv("Mac::Spotlight::MDItem", FALSE)));
    }
    XSRETURN(i);


void
_destroy(query)
    MDQueryRef    query
CODE:
    CFRelease(query);

