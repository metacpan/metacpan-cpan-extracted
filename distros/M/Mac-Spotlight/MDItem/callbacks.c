#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include <CoreFoundation/CoreFoundation.h>
#include </System/Library/Frameworks/CoreServices.framework/Versions/A/Frameworks/Metadata.framework/Versions/A/Headers/MDItem.h>

SV* _org_warhound_mdi_String2SV(CFTypeRef attrItem) {
    SV* retval;
    int stringSize = CFStringGetMaximumSizeForEncoding(CFStringGetLength(attrItem), kCFStringEncodingUTF8) + 1;
    char* tmpptr = (char*)malloc(sizeof(char) * stringSize);

    CFStringGetCString(attrItem, tmpptr, stringSize, kCFStringEncodingUTF8);
    /* Do not mark this as mortal! We leave that responsibility to our caller,
     * b/c XS often autogenerates the code for that and we don't want to
     * conflict with XS */
    retval = newSVpv(tmpptr, strlen(tmpptr));
    free(tmpptr);
    SvUTF8_on(retval);
    return retval;
}


SV* _org_warhound_mdi_ManyStrings2AVref(CFTypeRef attrItem) {
    CFIndex x, top;
    char* tmpptr;
    int stringSize;
    SV* midval;
    AV* retAV = newAV();

    top = CFArrayGetCount(attrItem);
    for (x = 0; x < top; x++) {
	stringSize = CFStringGetMaximumSizeForEncoding(CFStringGetLength(CFArrayGetValueAtIndex(attrItem, x)), kCFStringEncodingUTF8) + 1;
	tmpptr = (char*)malloc(sizeof(char) * stringSize);
	CFStringGetCString(CFArrayGetValueAtIndex(attrItem, x), tmpptr, stringSize, kCFStringEncodingUTF8);
	midval = newSVpv(tmpptr, strlen(tmpptr));
	SvUTF8_on(midval);
	av_push(retAV, midval);
	free(tmpptr);
    }
    return newRV((SV*)retAV);
}


SV* _org_warhound_mdi_Date2SV(CFTypeRef attrItem) {
    /* 978307200 is the number of seconds between 01 Jan 1970 GMT (the
     * Unix/Perl epoch) and 01 Jan 2001 GMT (the Core Foundation epoch) 
     */
    double perltime = 978307200;
    perltime += CFDateGetAbsoluteTime(attrItem);
    return newSVnv(perltime);
}


SV* _org_warhound_mdi_Number2SV(CFTypeRef attrItem) {
    double thisnv;
    /* FIXME: Error check? What to do if it fails? */
    CFNumberGetValue(attrItem, kCFNumberDoubleType, &thisnv);
    return newSVnv(thisnv);
}


SV* _org_warhound_mdi_Boolean2SV(CFTypeRef attrItem) {
    if (attrItem) {
	return newSViv(1);
    }
    else {
	return newSViv(0);
    }
}


SV* _org_warhound_mdi_NOOP(CFTypeRef attrItem) {
    return newSV(0);
}
