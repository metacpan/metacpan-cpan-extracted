#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include </System/Library/Frameworks/CoreServices.framework/Versions/A/Frameworks/Metadata.framework/Versions/A/Headers/MDItem.h>

#define MY_CXT_KEY "Mac::Spotlight::MDItem::_guts" XS_VERSION

extern SV* _org_warhound_mdi_String2SV(CFTypeRef);
extern SV* _org_warhound_mdi_ManyStrings2AVref(CFTypeRef);
extern SV* _org_warhound_mdi_Date2SV(CFTypeRef);
extern SV* _org_warhound_mdi_Number2SV(CFTypeRef);
extern SV* _org_warhound_mdi_Boolean2SV(CFTypeRef);
extern SV* _org_warhound_mdi_NOOP(CFTypeRef);

typedef struct {
    /* jumptable is initialized in the BOOT section.
     * When a kMDItem constant is used for the first time, it installs
     * its callback in the jumptable. When _get() is called, _get()
     * looks in the jumptable and calls the function to translate the
     * returned Core Foundation object into something Perl can use.
     */
    HV* jumptable;
} my_cxt_t;

START_MY_CXT    

MODULE = Mac::Spotlight::MDItem		PACKAGE = Mac::Spotlight::MDItem

BOOT:
{
    MY_CXT_INIT;
    MY_CXT.jumptable = newHV();
}

MDItemRef
_new(path)
    char* path
CODE:
    CFStringRef cpath = CFStringCreateWithCString(kCFAllocatorDefault, path, CFStringGetSystemEncoding());
    RETVAL = MDItemCreate(kCFAllocatorDefault, cpath);
    CFRelease(cpath);
OUTPUT:
    RETVAL

void
_destroy(MDItemRef item)
CODE:
    CFRelease(item);

=item Common MD keys
=cut
CFStringRef
kMDItemAttributeChangeDate()
PREINIT:
    const char* tmpptr;
CODE:
    dMY_CXT;
    tmpptr = CFStringGetCStringPtr(kMDItemAttributeChangeDate, CFStringGetSystemEncoding());
    hv_store(MY_CXT.jumptable, tmpptr, strlen(tmpptr), newSViv((IV)_org_warhound_mdi_Date2SV), 0);
    RETVAL = kMDItemAttributeChangeDate;
OUTPUT:
    RETVAL


CFStringRef
kMDItemAudiences()
PREINIT:
    const char* tmpptr;
CODE:
    dMY_CXT;
    tmpptr = CFStringGetCStringPtr(kMDItemAudiences, CFStringGetSystemEncoding());
    hv_store(MY_CXT.jumptable, tmpptr, strlen(tmpptr), newSViv((IV)_org_warhound_mdi_ManyStrings2AVref), 0);
    RETVAL = kMDItemAudiences;
OUTPUT:
    RETVAL


CFStringRef
kMDItemAuthors()
PREINIT:
    const char* tmpptr;
CODE:
    dMY_CXT;
    tmpptr = CFStringGetCStringPtr(kMDItemAuthors, CFStringGetSystemEncoding());
    hv_store(MY_CXT.jumptable, tmpptr, strlen(tmpptr), newSViv((IV)_org_warhound_mdi_ManyStrings2AVref), 0);
    RETVAL = kMDItemAuthors;
OUTPUT:
    RETVAL


CFStringRef
kMDItemCity()
PREINIT:
    const char* tmpptr;
CODE:
    dMY_CXT;
    tmpptr = CFStringGetCStringPtr(kMDItemCity, CFStringGetSystemEncoding());
    hv_store(MY_CXT.jumptable, tmpptr, strlen(tmpptr), newSViv((IV)_org_warhound_mdi_String2SV), 0);
    RETVAL = kMDItemCity;
OUTPUT:
    RETVAL


CFStringRef
kMDItemComment()
PREINIT:
    const char* tmpptr;
CODE:
    dMY_CXT;
    tmpptr = CFStringGetCStringPtr(kMDItemComment, CFStringGetSystemEncoding());
    hv_store(MY_CXT.jumptable, tmpptr, strlen(tmpptr), newSViv((IV)_org_warhound_mdi_String2SV), 0);
    RETVAL = kMDItemComment;
OUTPUT:
    RETVAL


CFStringRef
kMDItemContactKeywords()
PREINIT:
    const char* tmpptr;
CODE:
    dMY_CXT;
    tmpptr = CFStringGetCStringPtr(kMDItemContactKeywords, CFStringGetSystemEncoding());
    hv_store(MY_CXT.jumptable, tmpptr, strlen(tmpptr), newSViv((IV)_org_warhound_mdi_ManyStrings2AVref), 0);
    RETVAL = kMDItemContactKeywords;
OUTPUT:
    RETVAL


CFStringRef
kMDItemContentCreationDate()
PREINIT:
    const char* tmpptr;
CODE:
    dMY_CXT;
    tmpptr = CFStringGetCStringPtr(kMDItemContentCreationDate, CFStringGetSystemEncoding());
    hv_store(MY_CXT.jumptable, tmpptr, strlen(tmpptr), newSViv((IV)_org_warhound_mdi_Date2SV), 0);
    RETVAL = kMDItemContentCreationDate;
OUTPUT:
    RETVAL


CFStringRef
kMDItemContentModificationDate()
PREINIT:
    const char* tmpptr;
CODE:
    dMY_CXT;
    tmpptr = CFStringGetCStringPtr(kMDItemContentModificationDate, CFStringGetSystemEncoding());
    hv_store(MY_CXT.jumptable, tmpptr, strlen(tmpptr), newSViv((IV)_org_warhound_mdi_Date2SV), 0);
    RETVAL = kMDItemContentModificationDate;
OUTPUT:
    RETVAL


CFStringRef
kMDItemContentType()
PREINIT:
    const char* tmpptr;
CODE:
    dMY_CXT;
    tmpptr = CFStringGetCStringPtr(kMDItemContentType, CFStringGetSystemEncoding());
    hv_store(MY_CXT.jumptable, tmpptr, strlen(tmpptr), newSViv((IV)_org_warhound_mdi_String2SV), 0);
    RETVAL = kMDItemContentType;
OUTPUT:
    RETVAL


CFStringRef
kMDItemContributors()
PREINIT:
    const char* tmpptr;
CODE:
    dMY_CXT;
    tmpptr = CFStringGetCStringPtr(kMDItemContributors, CFStringGetSystemEncoding());
    hv_store(MY_CXT.jumptable, tmpptr, strlen(tmpptr), newSViv((IV)_org_warhound_mdi_ManyStrings2AVref), 0);
    RETVAL = kMDItemContributors;
OUTPUT:
    RETVAL


CFStringRef
kMDItemCopyright()
PREINIT:
    const char* tmpptr;
CODE:
    dMY_CXT;
    tmpptr = CFStringGetCStringPtr(kMDItemCopyright, CFStringGetSystemEncoding());
    hv_store(MY_CXT.jumptable, tmpptr, strlen(tmpptr), newSViv((IV)_org_warhound_mdi_String2SV), 0);
    RETVAL = kMDItemCopyright;
OUTPUT:
    RETVAL


CFStringRef
kMDItemCountry()
PREINIT:
    const char* tmpptr;
CODE:
    dMY_CXT;
    tmpptr = CFStringGetCStringPtr(kMDItemCountry, CFStringGetSystemEncoding());
    hv_store(MY_CXT.jumptable, tmpptr, strlen(tmpptr), newSViv((IV)_org_warhound_mdi_String2SV), 0);
    RETVAL = kMDItemCountry;
OUTPUT:
    RETVAL


CFStringRef
kMDItemCoverage()
PREINIT:
    const char* tmpptr;
CODE:
    dMY_CXT;
    tmpptr = CFStringGetCStringPtr(kMDItemCoverage, CFStringGetSystemEncoding());
    hv_store(MY_CXT.jumptable, tmpptr, strlen(tmpptr), newSViv((IV)_org_warhound_mdi_String2SV), 0);
    RETVAL = kMDItemCoverage;
OUTPUT:
    RETVAL


CFStringRef
kMDItemCreator()
PREINIT:
    const char* tmpptr;
CODE:
    dMY_CXT;
    tmpptr = CFStringGetCStringPtr(kMDItemCreator, CFStringGetSystemEncoding());
    hv_store(MY_CXT.jumptable, tmpptr, strlen(tmpptr), newSViv((IV)_org_warhound_mdi_String2SV), 0);
    RETVAL = kMDItemCreator;
OUTPUT:
    RETVAL


CFStringRef
kMDItemDescription()
PREINIT:
    const char* tmpptr;
CODE:
    dMY_CXT;
    tmpptr = CFStringGetCStringPtr(kMDItemDescription, CFStringGetSystemEncoding());
    hv_store(MY_CXT.jumptable, tmpptr, strlen(tmpptr), newSViv((IV)_org_warhound_mdi_String2SV), 0);
    RETVAL = kMDItemDescription;
OUTPUT:
    RETVAL


CFStringRef
kMDItemDueDate()
PREINIT:
    const char* tmpptr;
CODE:
    dMY_CXT;
    tmpptr = CFStringGetCStringPtr(kMDItemDueDate, CFStringGetSystemEncoding());
    hv_store(MY_CXT.jumptable, tmpptr, strlen(tmpptr), newSViv((IV)_org_warhound_mdi_Date2SV), 0);
    RETVAL = kMDItemDueDate;
OUTPUT:
    RETVAL


CFStringRef
kMDItemDurationSeconds()
PREINIT:
    const char* tmpptr;
CODE:
    dMY_CXT;
    tmpptr = CFStringGetCStringPtr(kMDItemDurationSeconds, CFStringGetSystemEncoding());
    hv_store(MY_CXT.jumptable, tmpptr, strlen(tmpptr), newSViv((IV)_org_warhound_mdi_Number2SV), 0);
    RETVAL = kMDItemDurationSeconds;
OUTPUT:
    RETVAL


CFStringRef
kMDItemEmailAddresses()
PREINIT:
    const char* tmpptr;
CODE:
    dMY_CXT;
    tmpptr = CFStringGetCStringPtr(kMDItemEmailAddresses, CFStringGetSystemEncoding());
    hv_store(MY_CXT.jumptable, tmpptr, strlen(tmpptr), newSViv((IV)_org_warhound_mdi_ManyStrings2AVref), 0);
    RETVAL = kMDItemEmailAddresses;
OUTPUT:
    RETVAL


CFStringRef
kMDItemEncodingApplications()
PREINIT:
    const char* tmpptr;
CODE:
    dMY_CXT;
    tmpptr = CFStringGetCStringPtr(kMDItemEncodingApplications, CFStringGetSystemEncoding());
    hv_store(MY_CXT.jumptable, tmpptr, strlen(tmpptr), newSViv((IV)_org_warhound_mdi_ManyStrings2AVref), 0);
    RETVAL = kMDItemEncodingApplications;
OUTPUT:
    RETVAL


CFStringRef
kMDItemFinderComment()
PREINIT:
    const char* tmpptr;
CODE:
    dMY_CXT;
    tmpptr = CFStringGetCStringPtr(kMDItemFinderComment, CFStringGetSystemEncoding());
    hv_store(MY_CXT.jumptable, tmpptr, strlen(tmpptr), newSViv((IV)_org_warhound_mdi_String2SV), 0);
    RETVAL = kMDItemFinderComment;
OUTPUT:
    RETVAL


CFStringRef
kMDItemFonts()
PREINIT:
    const char* tmpptr;
CODE:
    dMY_CXT;
    tmpptr = CFStringGetCStringPtr(kMDItemFonts, CFStringGetSystemEncoding());
    hv_store(MY_CXT.jumptable, tmpptr, strlen(tmpptr), newSViv((IV)_org_warhound_mdi_ManyStrings2AVref), 0);
    RETVAL = kMDItemFonts;
OUTPUT:
    RETVAL


CFStringRef
kMDItemHeadline()
PREINIT:
    const char* tmpptr;
CODE:
    dMY_CXT;
    tmpptr = CFStringGetCStringPtr(kMDItemHeadline, CFStringGetSystemEncoding());
    hv_store(MY_CXT.jumptable, tmpptr, strlen(tmpptr), newSViv((IV)_org_warhound_mdi_String2SV), 0);
    RETVAL = kMDItemHeadline;
OUTPUT:
    RETVAL


CFStringRef
kMDItemIdentifier()
PREINIT:
    const char* tmpptr;
CODE:
    dMY_CXT;
    tmpptr = CFStringGetCStringPtr(kMDItemIdentifier, CFStringGetSystemEncoding());
    hv_store(MY_CXT.jumptable, tmpptr, strlen(tmpptr), newSViv((IV)_org_warhound_mdi_String2SV), 0);
    RETVAL = kMDItemIdentifier;
OUTPUT:
    RETVAL


CFStringRef
kMDItemInstantMessageAddresses()
PREINIT:
    const char* tmpptr;
CODE:
    dMY_CXT;
    tmpptr = CFStringGetCStringPtr(kMDItemInstantMessageAddresses, CFStringGetSystemEncoding());
    hv_store(MY_CXT.jumptable, tmpptr, strlen(tmpptr), newSViv((IV)_org_warhound_mdi_ManyStrings2AVref), 0);
    RETVAL = kMDItemInstantMessageAddresses;
OUTPUT:
    RETVAL


CFStringRef
kMDItemInstructions()
PREINIT:
    const char* tmpptr;
CODE:
    dMY_CXT;
    tmpptr = CFStringGetCStringPtr(kMDItemInstructions, CFStringGetSystemEncoding());
    hv_store(MY_CXT.jumptable, tmpptr, strlen(tmpptr), newSViv((IV)_org_warhound_mdi_String2SV), 0);
    RETVAL = kMDItemInstructions;
OUTPUT:
    RETVAL


CFStringRef
kMDItemKeywords()
PREINIT:
    const char* tmpptr;
CODE:
    dMY_CXT;
    tmpptr = CFStringGetCStringPtr(kMDItemKeywords, CFStringGetSystemEncoding());
    hv_store(MY_CXT.jumptable, tmpptr, strlen(tmpptr), newSViv((IV)_org_warhound_mdi_ManyStrings2AVref), 0);
    RETVAL = kMDItemKeywords;
OUTPUT:
    RETVAL


CFStringRef
kMDItemKind()
PREINIT:
    const char* tmpptr;
CODE:
    dMY_CXT;
    tmpptr = CFStringGetCStringPtr(kMDItemKind, CFStringGetSystemEncoding());
    hv_store(MY_CXT.jumptable, tmpptr, strlen(tmpptr), newSViv((IV)_org_warhound_mdi_String2SV), 0);    
    RETVAL = kMDItemKind;
OUTPUT:
    RETVAL


CFStringRef
kMDItemLanguages()
PREINIT:
    const char* tmpptr;
CODE:
    dMY_CXT;
    tmpptr = CFStringGetCStringPtr(kMDItemLanguages, CFStringGetSystemEncoding());
    hv_store(MY_CXT.jumptable, tmpptr, strlen(tmpptr), newSViv((IV)_org_warhound_mdi_ManyStrings2AVref), 0);
    RETVAL = kMDItemLanguages;
OUTPUT:
    RETVAL


CFStringRef
kMDItemLastUsedDate()
PREINIT:
    const char* tmpptr;
CODE:
    dMY_CXT;
    tmpptr = CFStringGetCStringPtr(kMDItemLastUsedDate, CFStringGetSystemEncoding());
    hv_store(MY_CXT.jumptable, tmpptr, strlen(tmpptr), newSViv((IV)_org_warhound_mdi_Date2SV), 0);
    RETVAL = kMDItemLastUsedDate;
OUTPUT:
    RETVAL


CFStringRef
kMDItemNumberOfPages()
PREINIT:
    const char* tmpptr;
CODE:
    dMY_CXT;
    tmpptr = CFStringGetCStringPtr(kMDItemNumberOfPages, CFStringGetSystemEncoding());
    hv_store(MY_CXT.jumptable, tmpptr, strlen(tmpptr), newSViv((IV)_org_warhound_mdi_Number2SV), 0);
    RETVAL = kMDItemNumberOfPages;
OUTPUT:
    RETVAL


CFStringRef
kMDItemOrganizations()
PREINIT:
    const char* tmpptr;
CODE:
    dMY_CXT;
    tmpptr = CFStringGetCStringPtr(kMDItemOrganizations, CFStringGetSystemEncoding());
    hv_store(MY_CXT.jumptable, tmpptr, strlen(tmpptr), newSViv((IV)_org_warhound_mdi_ManyStrings2AVref), 0);
    RETVAL = kMDItemOrganizations;
OUTPUT:
    RETVAL


CFStringRef
kMDItemPageHeight()
PREINIT:
    const char* tmpptr;
CODE:
    dMY_CXT;
    tmpptr = CFStringGetCStringPtr(kMDItemPageHeight, CFStringGetSystemEncoding());
    hv_store(MY_CXT.jumptable, tmpptr, strlen(tmpptr), newSViv((IV)_org_warhound_mdi_Number2SV), 0);
    RETVAL = kMDItemPageHeight;
OUTPUT:
    RETVAL


CFStringRef
kMDItemPageWidth()
PREINIT:
    const char* tmpptr;
CODE:
    dMY_CXT;
    tmpptr = CFStringGetCStringPtr(kMDItemPageWidth, CFStringGetSystemEncoding());
    hv_store(MY_CXT.jumptable, tmpptr, strlen(tmpptr), newSViv((IV)_org_warhound_mdi_Number2SV), 0);
    RETVAL = kMDItemPageWidth;
OUTPUT:
    RETVAL


CFStringRef
kMDItemPhoneNumbers()
PREINIT:
    const char* tmpptr;
CODE:
    dMY_CXT;
    tmpptr = CFStringGetCStringPtr(kMDItemPhoneNumbers, CFStringGetSystemEncoding());
    hv_store(MY_CXT.jumptable, tmpptr, strlen(tmpptr), newSViv((IV)_org_warhound_mdi_ManyStrings2AVref), 0);
    RETVAL = kMDItemPhoneNumbers;
OUTPUT:
    RETVAL


CFStringRef
kMDItemProjects()
PREINIT:
    const char* tmpptr;
CODE:
    dMY_CXT;
    tmpptr = CFStringGetCStringPtr(kMDItemProjects, CFStringGetSystemEncoding());
    hv_store(MY_CXT.jumptable, tmpptr, strlen(tmpptr), newSViv((IV)_org_warhound_mdi_ManyStrings2AVref), 0);
    RETVAL = kMDItemProjects;
OUTPUT:
    RETVAL


CFStringRef
kMDItemPublishers()
PREINIT:
    const char* tmpptr;
CODE:
    dMY_CXT;
    tmpptr = CFStringGetCStringPtr(kMDItemPublishers, CFStringGetSystemEncoding());
    hv_store(MY_CXT.jumptable, tmpptr, strlen(tmpptr), newSViv((IV)_org_warhound_mdi_ManyStrings2AVref), 0);
    RETVAL = kMDItemPublishers;
OUTPUT:
    RETVAL


CFStringRef
kMDItemRecipients()
PREINIT:
    const char* tmpptr;
CODE:
    dMY_CXT;
    tmpptr = CFStringGetCStringPtr(kMDItemRecipients, CFStringGetSystemEncoding());
    hv_store(MY_CXT.jumptable, tmpptr, strlen(tmpptr), newSViv((IV)_org_warhound_mdi_ManyStrings2AVref), 0);
    RETVAL = kMDItemRecipients;
OUTPUT:
    RETVAL


CFStringRef
kMDItemRights()
PREINIT:
    const char* tmpptr;
CODE:
    dMY_CXT;
    tmpptr = CFStringGetCStringPtr(kMDItemRights, CFStringGetSystemEncoding());
    hv_store(MY_CXT.jumptable, tmpptr, strlen(tmpptr), newSViv((IV)_org_warhound_mdi_String2SV), 0);    
    RETVAL = kMDItemRights;
OUTPUT:
    RETVAL


CFStringRef
kMDItemSecurityMethod()
PREINIT:
    const char* tmpptr;
CODE:
    dMY_CXT;
    tmpptr = CFStringGetCStringPtr(kMDItemSecurityMethod, CFStringGetSystemEncoding());
    hv_store(MY_CXT.jumptable, tmpptr, strlen(tmpptr), newSViv((IV)_org_warhound_mdi_Number2SV), 0);
    RETVAL = kMDItemSecurityMethod;
OUTPUT:
    RETVAL


CFStringRef
kMDItemStarRating()
PREINIT:
    const char* tmpptr;
CODE:
    dMY_CXT;
    tmpptr = CFStringGetCStringPtr(kMDItemStarRating, CFStringGetSystemEncoding());
    hv_store(MY_CXT.jumptable, tmpptr, strlen(tmpptr), newSViv((IV)_org_warhound_mdi_Number2SV), 0);
    RETVAL = kMDItemStarRating;
OUTPUT:
    RETVAL


CFStringRef
kMDItemStateOrProvince()
PREINIT:
    const char* tmpptr;
CODE:
    dMY_CXT;
    tmpptr = CFStringGetCStringPtr(kMDItemStateOrProvince, CFStringGetSystemEncoding());
    hv_store(MY_CXT.jumptable, tmpptr, strlen(tmpptr), newSViv((IV)_org_warhound_mdi_String2SV), 0);    
    RETVAL = kMDItemStateOrProvince;
OUTPUT:
    RETVAL


CFStringRef
kMDItemTextContent()
PREINIT:
    const char* tmpptr;
CODE:
    dMY_CXT;
    tmpptr = CFStringGetCStringPtr(kMDItemTextContent, CFStringGetSystemEncoding());
    hv_store(MY_CXT.jumptable, tmpptr, strlen(tmpptr), newSViv((IV)_org_warhound_mdi_NOOP), 0);    
    RETVAL = kMDItemTextContent;
OUTPUT:
    RETVAL


CFStringRef
kMDItemTitle()
PREINIT:
    const char* tmpptr;
CODE:
    dMY_CXT;
    tmpptr = CFStringGetCStringPtr(kMDItemTitle, CFStringGetSystemEncoding());
    hv_store(MY_CXT.jumptable, tmpptr, strlen(tmpptr), newSViv((IV)_org_warhound_mdi_String2SV), 0);    
    RETVAL = kMDItemTitle;
OUTPUT:
    RETVAL


CFStringRef
kMDItemVersion()
PREINIT:
    const char* tmpptr;
CODE:
    dMY_CXT;
    tmpptr = CFStringGetCStringPtr(kMDItemVersion, CFStringGetSystemEncoding());
    hv_store(MY_CXT.jumptable, tmpptr, strlen(tmpptr), newSViv((IV)_org_warhound_mdi_String2SV), 0);    
    RETVAL = kMDItemVersion;
OUTPUT:
    RETVAL


CFStringRef
kMDItemWhereFroms()
PREINIT:
    const char* tmpptr;
CODE:
    dMY_CXT;
    tmpptr = CFStringGetCStringPtr(kMDItemWhereFroms, CFStringGetSystemEncoding());
    hv_store(MY_CXT.jumptable, tmpptr, strlen(tmpptr), newSViv((IV)_org_warhound_mdi_ManyStrings2AVref), 0);
    RETVAL = kMDItemWhereFroms;
OUTPUT:
    RETVAL


=item Image MD keys
=cut
CFStringRef
kMDItemPixelHeight()
PREINIT:
    const char* tmpptr;
CODE:
    dMY_CXT;
    tmpptr = CFStringGetCStringPtr(kMDItemPixelHeight, CFStringGetSystemEncoding());
    hv_store(MY_CXT.jumptable, tmpptr, strlen(tmpptr), newSViv((IV)_org_warhound_mdi_Number2SV), 0);
    RETVAL = kMDItemPixelHeight;
OUTPUT:
    RETVAL


CFStringRef
kMDItemPixelWidth()
PREINIT:
    const char* tmpptr;
CODE:
    dMY_CXT;
    tmpptr = CFStringGetCStringPtr(kMDItemPixelWidth, CFStringGetSystemEncoding());
    hv_store(MY_CXT.jumptable, tmpptr, strlen(tmpptr), newSViv((IV)_org_warhound_mdi_Number2SV), 0);
    RETVAL = kMDItemPixelWidth;
OUTPUT:
    RETVAL


CFStringRef
kMDItemColorSpace()
PREINIT:
    const char* tmpptr;
CODE:
    dMY_CXT;
    tmpptr = CFStringGetCStringPtr(kMDItemColorSpace, CFStringGetSystemEncoding());
    hv_store(MY_CXT.jumptable, tmpptr, strlen(tmpptr), newSViv((IV)_org_warhound_mdi_String2SV), 0);
    RETVAL = kMDItemColorSpace;
OUTPUT:
    RETVAL


CFStringRef
kMDItemBitsPerSample()
PREINIT:
    const char* tmpptr;
CODE:
    dMY_CXT;
    tmpptr = CFStringGetCStringPtr(kMDItemBitsPerSample, CFStringGetSystemEncoding());
    hv_store(MY_CXT.jumptable, tmpptr, strlen(tmpptr), newSViv((IV)_org_warhound_mdi_Number2SV), 0);
    RETVAL = kMDItemBitsPerSample;
OUTPUT:
    RETVAL


CFStringRef
kMDItemFlashOnOff()
PREINIT:
    const char* tmpptr;
CODE:
    dMY_CXT;
    tmpptr = CFStringGetCStringPtr(kMDItemFlashOnOff, CFStringGetSystemEncoding());
    hv_store(MY_CXT.jumptable, tmpptr, strlen(tmpptr), newSViv((IV)_org_warhound_mdi_Number2SV), 0);
    RETVAL = kMDItemFlashOnOff;
OUTPUT:
    RETVAL


CFStringRef
kMDItemFocalLength()
PREINIT:
    const char* tmpptr;
CODE:
    dMY_CXT;
    tmpptr = CFStringGetCStringPtr(kMDItemFocalLength, CFStringGetSystemEncoding());
    hv_store(MY_CXT.jumptable, tmpptr, strlen(tmpptr), newSViv((IV)_org_warhound_mdi_Number2SV), 0);
    RETVAL = kMDItemFocalLength;
OUTPUT:
    RETVAL


CFStringRef
kMDItemAcquisitionMake()
PREINIT:
    const char* tmpptr;
CODE:
    dMY_CXT;
    tmpptr = CFStringGetCStringPtr(kMDItemAcquisitionMake, CFStringGetSystemEncoding());
    hv_store(MY_CXT.jumptable, tmpptr, strlen(tmpptr), newSViv((IV)_org_warhound_mdi_String2SV), 0);
    RETVAL = kMDItemAcquisitionMake;
OUTPUT:
    RETVAL


CFStringRef
kMDItemAcquisitionModel()
PREINIT:
    const char* tmpptr;
CODE:
    dMY_CXT;
    tmpptr = CFStringGetCStringPtr(kMDItemAcquisitionModel, CFStringGetSystemEncoding());
    hv_store(MY_CXT.jumptable, tmpptr, strlen(tmpptr), newSViv((IV)_org_warhound_mdi_String2SV), 0);
    RETVAL = kMDItemAcquisitionModel;
OUTPUT:
    RETVAL


CFStringRef
kMDItemISOSpeed()
PREINIT:
    const char* tmpptr;
CODE:
    dMY_CXT;
    tmpptr = CFStringGetCStringPtr(kMDItemISOSpeed, CFStringGetSystemEncoding());
    hv_store(MY_CXT.jumptable, tmpptr, strlen(tmpptr), newSViv((IV)_org_warhound_mdi_Number2SV), 0);
    RETVAL = kMDItemISOSpeed;
OUTPUT:
    RETVAL


CFStringRef
kMDItemOrientation()
PREINIT:
    const char* tmpptr;
CODE:
    dMY_CXT;
    tmpptr = CFStringGetCStringPtr(kMDItemOrientation, CFStringGetSystemEncoding());
    hv_store(MY_CXT.jumptable, tmpptr, strlen(tmpptr), newSViv((IV)_org_warhound_mdi_Number2SV), 0);
    RETVAL = kMDItemOrientation;
OUTPUT:
    RETVAL


CFStringRef
kMDItemLayerNames()
PREINIT:
    const char* tmpptr;
CODE:
    dMY_CXT;
    tmpptr = CFStringGetCStringPtr(kMDItemLayerNames, CFStringGetSystemEncoding());
    hv_store(MY_CXT.jumptable, tmpptr, strlen(tmpptr), newSViv((IV)_org_warhound_mdi_ManyStrings2AVref), 0);
    RETVAL = kMDItemLayerNames;
OUTPUT:
    RETVAL


CFStringRef
kMDItemWhiteBalance()
PREINIT:
    const char* tmpptr;
CODE:
    dMY_CXT;
    tmpptr = CFStringGetCStringPtr(kMDItemWhiteBalance, CFStringGetSystemEncoding());
    hv_store(MY_CXT.jumptable, tmpptr, strlen(tmpptr), newSViv((IV)_org_warhound_mdi_Number2SV), 0);
    RETVAL = kMDItemWhiteBalance;
OUTPUT:
    RETVAL


CFStringRef
kMDItemAperture()
PREINIT:
    const char* tmpptr;
CODE:
    dMY_CXT;
    tmpptr = CFStringGetCStringPtr(kMDItemAperture, CFStringGetSystemEncoding());
    hv_store(MY_CXT.jumptable, tmpptr, strlen(tmpptr), newSViv((IV)_org_warhound_mdi_Number2SV), 0);
    RETVAL = kMDItemAperture;
OUTPUT:
    RETVAL


CFStringRef
kMDItemProfileName()
PREINIT:
    const char* tmpptr;
CODE:
    dMY_CXT;
    tmpptr = CFStringGetCStringPtr(kMDItemProfileName, CFStringGetSystemEncoding());
    hv_store(MY_CXT.jumptable, tmpptr, strlen(tmpptr), newSViv((IV)_org_warhound_mdi_String2SV), 0);
    RETVAL = kMDItemProfileName;
OUTPUT:
    RETVAL


CFStringRef
kMDItemResolutionWidthDPI()
PREINIT:
    const char* tmpptr;
CODE:
    dMY_CXT;
    tmpptr = CFStringGetCStringPtr(kMDItemResolutionWidthDPI, CFStringGetSystemEncoding());
    hv_store(MY_CXT.jumptable, tmpptr, strlen(tmpptr), newSViv((IV)_org_warhound_mdi_Number2SV), 0);
    RETVAL = kMDItemResolutionWidthDPI;
OUTPUT:
    RETVAL


CFStringRef
kMDItemResolutionHeightDPI()
PREINIT:
    const char* tmpptr;
CODE:
    dMY_CXT;
    tmpptr = CFStringGetCStringPtr(kMDItemResolutionHeightDPI, CFStringGetSystemEncoding());
    hv_store(MY_CXT.jumptable, tmpptr, strlen(tmpptr), newSViv((IV)_org_warhound_mdi_Number2SV), 0);
    RETVAL = kMDItemResolutionHeightDPI;
OUTPUT:
    RETVAL


CFStringRef
kMDItemExposureMode()
PREINIT:
    const char* tmpptr;
CODE:
    dMY_CXT;
    tmpptr = CFStringGetCStringPtr(kMDItemExposureMode, CFStringGetSystemEncoding());
    hv_store(MY_CXT.jumptable, tmpptr, strlen(tmpptr), newSViv((IV)_org_warhound_mdi_Number2SV), 0);
    RETVAL = kMDItemExposureMode;
OUTPUT:
    RETVAL


CFStringRef
kMDItemExposureTimeSeconds()
PREINIT:
    const char* tmpptr;
CODE:
    dMY_CXT;
    tmpptr = CFStringGetCStringPtr(kMDItemExposureTimeSeconds, CFStringGetSystemEncoding());
    hv_store(MY_CXT.jumptable, tmpptr, strlen(tmpptr), newSViv((IV)_org_warhound_mdi_Number2SV), 0);
    RETVAL = kMDItemExposureTimeSeconds;
OUTPUT:
    RETVAL


CFStringRef
kMDItemEXIFVersion()
PREINIT:
    const char* tmpptr;
CODE:
    dMY_CXT;
    tmpptr = CFStringGetCStringPtr(kMDItemEXIFVersion, CFStringGetSystemEncoding());
    hv_store(MY_CXT.jumptable, tmpptr, strlen(tmpptr), newSViv((IV)_org_warhound_mdi_String2SV), 0);
    RETVAL = kMDItemEXIFVersion;
OUTPUT:
    RETVAL


CFStringRef
kMDItemAlbum()
PREINIT:
    const char* tmpptr;
CODE:
    dMY_CXT;
    tmpptr = CFStringGetCStringPtr(kMDItemAlbum, CFStringGetSystemEncoding());
    hv_store(MY_CXT.jumptable, tmpptr, strlen(tmpptr), newSViv((IV)_org_warhound_mdi_String2SV), 0);
    RETVAL = kMDItemAlbum;
OUTPUT:
    RETVAL


CFStringRef
kMDItemHasAlphaChannel()
PREINIT:
    const char* tmpptr;
CODE:
    dMY_CXT;
    tmpptr = CFStringGetCStringPtr(kMDItemHasAlphaChannel, CFStringGetSystemEncoding());
    hv_store(MY_CXT.jumptable, tmpptr, strlen(tmpptr), newSViv((IV)_org_warhound_mdi_Boolean2SV), 0);
    RETVAL = kMDItemHasAlphaChannel;
OUTPUT:
    RETVAL


CFStringRef
kMDItemRedEyeOnOff()
PREINIT:
    const char* tmpptr;
CODE:
    dMY_CXT;
    tmpptr = CFStringGetCStringPtr(kMDItemRedEyeOnOff, CFStringGetSystemEncoding());
    hv_store(MY_CXT.jumptable, tmpptr, strlen(tmpptr), newSViv((IV)_org_warhound_mdi_Boolean2SV), 0);
    RETVAL = kMDItemRedEyeOnOff;
OUTPUT:
    RETVAL


CFStringRef
kMDItemMeteringMode()
PREINIT:
    const char* tmpptr;
CODE:
    dMY_CXT;
    tmpptr = CFStringGetCStringPtr(kMDItemMeteringMode, CFStringGetSystemEncoding());
    hv_store(MY_CXT.jumptable, tmpptr, strlen(tmpptr), newSViv((IV)_org_warhound_mdi_String2SV), 0);
    RETVAL = kMDItemMeteringMode;
OUTPUT:
    RETVAL


CFStringRef
kMDItemMaxAperture()
PREINIT:
    const char* tmpptr;
CODE:
    dMY_CXT;
    tmpptr = CFStringGetCStringPtr(kMDItemMaxAperture, CFStringGetSystemEncoding());
    hv_store(MY_CXT.jumptable, tmpptr, strlen(tmpptr), newSViv((IV)_org_warhound_mdi_Number2SV), 0);
    RETVAL = kMDItemMaxAperture;
OUTPUT:
    RETVAL


CFStringRef
kMDItemFNumber()
PREINIT:
    const char* tmpptr;
CODE:
    dMY_CXT;
    tmpptr = CFStringGetCStringPtr(kMDItemFNumber, CFStringGetSystemEncoding());
    /* The ADC reference doesn't actually say what this is. But it's
     * probably a CFNumber. I hope. */
    hv_store(MY_CXT.jumptable, tmpptr, strlen(tmpptr), newSViv((IV)_org_warhound_mdi_Number2SV), 0);
    RETVAL = kMDItemFNumber;
OUTPUT:
    RETVAL


CFStringRef
kMDItemExposureProgram()
PREINIT:
    const char* tmpptr;
CODE:
    dMY_CXT;
    tmpptr = CFStringGetCStringPtr(kMDItemExposureProgram, CFStringGetSystemEncoding());
    hv_store(MY_CXT.jumptable, tmpptr, strlen(tmpptr), newSViv((IV)_org_warhound_mdi_String2SV), 0);
    RETVAL = kMDItemExposureProgram;
OUTPUT:
    RETVAL


CFStringRef
kMDItemExposureTimeString()
PREINIT:
    const char* tmpptr;
CODE:
    dMY_CXT;
    tmpptr = CFStringGetCStringPtr(kMDItemExposureTimeString, CFStringGetSystemEncoding());
    hv_store(MY_CXT.jumptable, tmpptr, strlen(tmpptr), newSViv((IV)_org_warhound_mdi_String2SV), 0);
    RETVAL = kMDItemExposureTimeString;
OUTPUT:
    RETVAL


=item Video MD keys
=cut
CFStringRef
kMDItemAudioBitRate()
PREINIT:
    const char* tmpptr;
CODE:
    dMY_CXT;
    tmpptr = CFStringGetCStringPtr(kMDItemAudioBitRate, CFStringGetSystemEncoding());
    hv_store(MY_CXT.jumptable, tmpptr, strlen(tmpptr), newSViv((IV)_org_warhound_mdi_Number2SV), 0);
    RETVAL = kMDItemAudioBitRate;
OUTPUT:
    RETVAL


CFStringRef
kMDItemCodecs()
PREINIT:
    const char* tmpptr;
CODE:
    dMY_CXT;
    tmpptr = CFStringGetCStringPtr(kMDItemCodecs, CFStringGetSystemEncoding());
    hv_store(MY_CXT.jumptable, tmpptr, strlen(tmpptr), newSViv((IV)_org_warhound_mdi_ManyStrings2AVref), 0);
    RETVAL = kMDItemCodecs;
OUTPUT:
    RETVAL


CFStringRef
kMDItemDeliveryType()
PREINIT:
    const char* tmpptr;
CODE:
    dMY_CXT;
    tmpptr = CFStringGetCStringPtr(kMDItemDeliveryType, CFStringGetSystemEncoding());
    hv_store(MY_CXT.jumptable, tmpptr, strlen(tmpptr), newSViv((IV)_org_warhound_mdi_String2SV), 0);
    RETVAL = kMDItemDeliveryType;
OUTPUT:
    RETVAL


CFStringRef
kMDItemMediaTypes()
PREINIT:
    const char* tmpptr;
CODE:
    dMY_CXT;
    tmpptr = CFStringGetCStringPtr(kMDItemMediaTypes, CFStringGetSystemEncoding());
    hv_store(MY_CXT.jumptable, tmpptr, strlen(tmpptr), newSViv((IV)_org_warhound_mdi_ManyStrings2AVref), 0);
    RETVAL = kMDItemMediaTypes;
OUTPUT:
    RETVAL


CFStringRef
kMDItemStreamable()
PREINIT:
    const char* tmpptr;
CODE:
    dMY_CXT;
    tmpptr = CFStringGetCStringPtr(kMDItemStreamable, CFStringGetSystemEncoding());
    hv_store(MY_CXT.jumptable, tmpptr, strlen(tmpptr), newSViv((IV)_org_warhound_mdi_Boolean2SV), 0);
    RETVAL = kMDItemStreamable;
OUTPUT:
    RETVAL


CFStringRef
kMDItemTotalBitRate()
PREINIT:
    const char* tmpptr;
CODE:
    dMY_CXT;
    tmpptr = CFStringGetCStringPtr(kMDItemTotalBitRate, CFStringGetSystemEncoding());
    hv_store(MY_CXT.jumptable, tmpptr, strlen(tmpptr), newSViv((IV)_org_warhound_mdi_Number2SV), 0);
    RETVAL = kMDItemTotalBitRate;
OUTPUT:
    RETVAL


CFStringRef
kMDItemVideoBitRate()
PREINIT:
    const char* tmpptr;
CODE:
    dMY_CXT;
    tmpptr = CFStringGetCStringPtr(kMDItemVideoBitRate, CFStringGetSystemEncoding());
    hv_store(MY_CXT.jumptable, tmpptr, strlen(tmpptr), newSViv((IV)_org_warhound_mdi_Number2SV), 0);
    RETVAL = kMDItemVideoBitRate;
OUTPUT:
    RETVAL


=item Audio MD keys
=cut
CFStringRef
kMDItemAppleLoopDescriptors()
PREINIT:
    const char* tmpptr;
CODE:
    dMY_CXT;
    tmpptr = CFStringGetCStringPtr(kMDItemAppleLoopDescriptors, CFStringGetSystemEncoding());
    hv_store(MY_CXT.jumptable, tmpptr, strlen(tmpptr), newSViv((IV)_org_warhound_mdi_ManyStrings2AVref), 0);
    RETVAL = kMDItemAppleLoopDescriptors;
OUTPUT:
    RETVAL


CFStringRef
kMDItemAppleLoopsKeyFilterType()
PREINIT:
    const char* tmpptr;
CODE:
    dMY_CXT;
    tmpptr = CFStringGetCStringPtr(kMDItemAppleLoopsKeyFilterType, CFStringGetSystemEncoding());
    hv_store(MY_CXT.jumptable, tmpptr, strlen(tmpptr), newSViv((IV)_org_warhound_mdi_String2SV), 0);
    RETVAL = kMDItemAppleLoopsKeyFilterType;
OUTPUT:
    RETVAL


CFStringRef
kMDItemAppleLoopsLoopMode()
PREINIT:
    const char* tmpptr;
CODE:
    dMY_CXT;
    tmpptr = CFStringGetCStringPtr(kMDItemAppleLoopsLoopMode, CFStringGetSystemEncoding());
    hv_store(MY_CXT.jumptable, tmpptr, strlen(tmpptr), newSViv((IV)_org_warhound_mdi_String2SV), 0);
    RETVAL = kMDItemAppleLoopsLoopMode;
OUTPUT:
    RETVAL


CFStringRef
kMDItemAppleLoopsRootKey()
PREINIT:
    const char* tmpptr;
CODE:
    dMY_CXT;
    tmpptr = CFStringGetCStringPtr(kMDItemAppleLoopsRootKey, CFStringGetSystemEncoding());
    hv_store(MY_CXT.jumptable, tmpptr, strlen(tmpptr), newSViv((IV)_org_warhound_mdi_String2SV), 0);
    RETVAL = kMDItemAppleLoopsRootKey;
OUTPUT:
    RETVAL


CFStringRef
kMDItemAudioChannelCount()
PREINIT:
    const char* tmpptr;
CODE:
    dMY_CXT;
    tmpptr = CFStringGetCStringPtr(kMDItemAudioChannelCount, CFStringGetSystemEncoding());
    hv_store(MY_CXT.jumptable, tmpptr, strlen(tmpptr), newSViv((IV)_org_warhound_mdi_Number2SV), 0);
    RETVAL = kMDItemAudioChannelCount;
OUTPUT:
    RETVAL


CFStringRef
kMDItemAudioEncodingApplication()
PREINIT:
    const char* tmpptr;
CODE:
    dMY_CXT;
    tmpptr = CFStringGetCStringPtr(kMDItemAudioEncodingApplication, CFStringGetSystemEncoding());
    hv_store(MY_CXT.jumptable, tmpptr, strlen(tmpptr), newSViv((IV)_org_warhound_mdi_String2SV), 0);
    RETVAL = kMDItemAudioEncodingApplication;
OUTPUT:
    RETVAL


CFStringRef
kMDItemAudioSampleRate()
PREINIT:
    const char* tmpptr;
CODE:
    dMY_CXT;
    tmpptr = CFStringGetCStringPtr(kMDItemAudioSampleRate, CFStringGetSystemEncoding());
    hv_store(MY_CXT.jumptable, tmpptr, strlen(tmpptr), newSViv((IV)_org_warhound_mdi_Number2SV), 0);
    RETVAL = kMDItemAudioSampleRate;
OUTPUT:
    RETVAL


CFStringRef
kMDItemAudioTrackNumber()
PREINIT:
    const char* tmpptr;
CODE:
    dMY_CXT;
    tmpptr = CFStringGetCStringPtr(kMDItemAudioTrackNumber, CFStringGetSystemEncoding());
    hv_store(MY_CXT.jumptable, tmpptr, strlen(tmpptr), newSViv((IV)_org_warhound_mdi_Number2SV), 0);
    RETVAL = kMDItemAudioTrackNumber;
OUTPUT:
    RETVAL


CFStringRef
kMDItemComposer()
PREINIT:
    const char* tmpptr;
CODE:
    dMY_CXT;
    tmpptr = CFStringGetCStringPtr(kMDItemComposer, CFStringGetSystemEncoding());
    hv_store(MY_CXT.jumptable, tmpptr, strlen(tmpptr), newSViv((IV)_org_warhound_mdi_String2SV), 0);
    RETVAL = kMDItemComposer;
OUTPUT:
    RETVAL


CFStringRef
kMDItemIsGeneralMIDISequence()
PREINIT:
    const char* tmpptr;
CODE:
    dMY_CXT;
    tmpptr = CFStringGetCStringPtr(kMDItemIsGeneralMIDISequence, CFStringGetSystemEncoding());
    hv_store(MY_CXT.jumptable, tmpptr, strlen(tmpptr), newSViv((IV)_org_warhound_mdi_Boolean2SV), 0);
    RETVAL = kMDItemIsGeneralMIDISequence;
OUTPUT:
    RETVAL


CFStringRef
kMDItemKeySignature()
PREINIT:
    const char* tmpptr;
CODE:
    dMY_CXT;
    tmpptr = CFStringGetCStringPtr(kMDItemKeySignature, CFStringGetSystemEncoding());
    hv_store(MY_CXT.jumptable, tmpptr, strlen(tmpptr), newSViv((IV)_org_warhound_mdi_String2SV), 0);
    RETVAL = kMDItemKeySignature;
OUTPUT:
    RETVAL


CFStringRef
kMDItemLyricist()
PREINIT:
    const char* tmpptr;
CODE:
    dMY_CXT;
    tmpptr = CFStringGetCStringPtr(kMDItemLyricist, CFStringGetSystemEncoding());
    hv_store(MY_CXT.jumptable, tmpptr, strlen(tmpptr), newSViv((IV)_org_warhound_mdi_String2SV), 0);
    RETVAL = kMDItemLyricist;
OUTPUT:
    RETVAL


CFStringRef
kMDItemMusicalGenre()
PREINIT:
    const char* tmpptr;
CODE:
    dMY_CXT;
    tmpptr = CFStringGetCStringPtr(kMDItemMusicalGenre, CFStringGetSystemEncoding());
    hv_store(MY_CXT.jumptable, tmpptr, strlen(tmpptr), newSViv((IV)_org_warhound_mdi_String2SV), 0);
    RETVAL = kMDItemMusicalGenre;
OUTPUT:
    RETVAL


CFStringRef
kMDItemMusicalInstrumentCategory()
PREINIT:
    const char* tmpptr;
CODE:
    dMY_CXT;
    tmpptr = CFStringGetCStringPtr(kMDItemMusicalInstrumentCategory, CFStringGetSystemEncoding());
    hv_store(MY_CXT.jumptable, tmpptr, strlen(tmpptr), newSViv((IV)_org_warhound_mdi_String2SV), 0);
    RETVAL = kMDItemMusicalInstrumentCategory;
OUTPUT:
    RETVAL


CFStringRef
kMDItemMusicalInstrumentName()
PREINIT:
    const char* tmpptr;
CODE:
    dMY_CXT;
    tmpptr = CFStringGetCStringPtr(kMDItemMusicalInstrumentName, CFStringGetSystemEncoding());
    hv_store(MY_CXT.jumptable, tmpptr, strlen(tmpptr), newSViv((IV)_org_warhound_mdi_String2SV), 0);
    RETVAL = kMDItemMusicalInstrumentName;
OUTPUT:
    RETVAL


CFStringRef
kMDItemRecordingDate()
PREINIT:
    const char* tmpptr;
CODE:
    dMY_CXT;
    tmpptr = CFStringGetCStringPtr(kMDItemRecordingDate, CFStringGetSystemEncoding());
    hv_store(MY_CXT.jumptable, tmpptr, strlen(tmpptr), newSViv((IV)_org_warhound_mdi_Date2SV), 0);
    RETVAL = kMDItemRecordingDate;
OUTPUT:
    RETVAL


CFStringRef
kMDItemRecordingYear()
PREINIT:
    const char* tmpptr;
CODE:
    dMY_CXT;
    tmpptr = CFStringGetCStringPtr(kMDItemRecordingYear, CFStringGetSystemEncoding());
    hv_store(MY_CXT.jumptable, tmpptr, strlen(tmpptr), newSViv((IV)_org_warhound_mdi_Number2SV), 0);
    RETVAL = kMDItemRecordingYear;
OUTPUT:
    RETVAL


CFStringRef
kMDItemTempo()
PREINIT:
    const char* tmpptr;
CODE:
    dMY_CXT;
    tmpptr = CFStringGetCStringPtr(kMDItemTempo, CFStringGetSystemEncoding());
    hv_store(MY_CXT.jumptable, tmpptr, strlen(tmpptr), newSViv((IV)_org_warhound_mdi_Number2SV), 0);
    RETVAL = kMDItemTempo;
OUTPUT:
    RETVAL


CFStringRef
kMDItemTimeSignature()
PREINIT:
    const char* tmpptr;
CODE:
    dMY_CXT;
    tmpptr = CFStringGetCStringPtr(kMDItemTimeSignature, CFStringGetSystemEncoding());
    hv_store(MY_CXT.jumptable, tmpptr, strlen(tmpptr), newSViv((IV)_org_warhound_mdi_String2SV), 0);
    RETVAL = kMDItemTimeSignature;
OUTPUT:
    RETVAL


=item Filesystem MD Keys
=cut
CFStringRef
kMDItemDisplayName()
PREINIT:
    const char* tmpptr;
CODE:
    dMY_CXT;
    tmpptr = CFStringGetCStringPtr(kMDItemDisplayName, CFStringGetSystemEncoding());
    hv_store(MY_CXT.jumptable, tmpptr, strlen(tmpptr), newSViv((IV)_org_warhound_mdi_String2SV), 0);
    RETVAL = kMDItemDisplayName;
OUTPUT:
    RETVAL


CFStringRef
kMDItemFSContentChangeDate()
PREINIT:
    const char* tmpptr;
CODE:
    dMY_CXT;
    tmpptr = CFStringGetCStringPtr(kMDItemFSContentChangeDate, CFStringGetSystemEncoding());
    hv_store(MY_CXT.jumptable, tmpptr, strlen(tmpptr), newSViv((IV)_org_warhound_mdi_Date2SV), 0);
    RETVAL = kMDItemFSContentChangeDate;
OUTPUT:
    RETVAL


CFStringRef
kMDItemFSCreationDate()
PREINIT:
    const char* tmpptr;
CODE:
    dMY_CXT;
    tmpptr = CFStringGetCStringPtr(kMDItemFSContentChangeDate, CFStringGetSystemEncoding());
    hv_store(MY_CXT.jumptable, tmpptr, strlen(tmpptr), newSViv((IV)_org_warhound_mdi_Date2SV), 0);
    RETVAL = kMDItemFSContentChangeDate;
OUTPUT:
    RETVAL


CFStringRef
kMDItemFSExists()
PREINIT:
    const char* tmpptr;
CODE:
    dMY_CXT;
    tmpptr = CFStringGetCStringPtr(kMDItemFSExists, CFStringGetSystemEncoding());
    hv_store(MY_CXT.jumptable, tmpptr, strlen(tmpptr), newSViv((IV)_org_warhound_mdi_Boolean2SV), 0);
    RETVAL = kMDItemFSExists;
OUTPUT:
    RETVAL


CFStringRef
kMDItemFSInvisible()
PREINIT:
    const char* tmpptr;
CODE:
    dMY_CXT;
    tmpptr = CFStringGetCStringPtr(kMDItemFSInvisible, CFStringGetSystemEncoding());
    hv_store(MY_CXT.jumptable, tmpptr, strlen(tmpptr), newSViv((IV)_org_warhound_mdi_Boolean2SV), 0);
    RETVAL = kMDItemFSInvisible;
OUTPUT:
    RETVAL


CFStringRef
kMDItemFSIsExtensionHidden()
PREINIT:
    const char* tmpptr;
CODE:
    dMY_CXT;
    tmpptr = CFStringGetCStringPtr(kMDItemFSIsExtensionHidden, CFStringGetSystemEncoding());
    hv_store(MY_CXT.jumptable, tmpptr, strlen(tmpptr), newSViv((IV)_org_warhound_mdi_Boolean2SV), 0);
    RETVAL = kMDItemFSIsExtensionHidden;
OUTPUT:
    RETVAL


CFStringRef
kMDItemFSIsReadable()
PREINIT:
    const char* tmpptr;
CODE:
    dMY_CXT;
    tmpptr = CFStringGetCStringPtr(kMDItemFSIsReadable, CFStringGetSystemEncoding());
    hv_store(MY_CXT.jumptable, tmpptr, strlen(tmpptr), newSViv((IV)_org_warhound_mdi_Boolean2SV), 0);
    RETVAL = kMDItemFSIsReadable;
OUTPUT:
    RETVAL


CFStringRef
kMDItemFSIsWriteable()
PREINIT:
    const char* tmpptr;
CODE:
    dMY_CXT;
    tmpptr = CFStringGetCStringPtr(kMDItemFSIsWriteable, CFStringGetSystemEncoding());
    hv_store(MY_CXT.jumptable, tmpptr, strlen(tmpptr), newSViv((IV)_org_warhound_mdi_Boolean2SV), 0);
    RETVAL = kMDItemFSIsWriteable;
OUTPUT:
    RETVAL


CFStringRef
kMDItemFSLabel()
PREINIT:
    const char* tmpptr;
CODE:
    dMY_CXT;
    tmpptr = CFStringGetCStringPtr(kMDItemFSLabel, CFStringGetSystemEncoding());
    hv_store(MY_CXT.jumptable, tmpptr, strlen(tmpptr), newSViv((IV)_org_warhound_mdi_Number2SV), 0);
    RETVAL = kMDItemFSLabel;
OUTPUT:
    RETVAL


CFStringRef
kMDItemFSName()
PREINIT:
    const char* tmpptr;
CODE:
    dMY_CXT;
    tmpptr = CFStringGetCStringPtr(kMDItemFSName, CFStringGetSystemEncoding());
    hv_store(MY_CXT.jumptable, tmpptr, strlen(tmpptr), newSViv((IV)_org_warhound_mdi_String2SV), 0);
    RETVAL = kMDItemFSName;
OUTPUT:
    RETVAL


CFStringRef
kMDItemFSNodeCount()
PREINIT:
    const char* tmpptr;
CODE:
    dMY_CXT;
    tmpptr = CFStringGetCStringPtr(kMDItemFSNodeCount, CFStringGetSystemEncoding());
    hv_store(MY_CXT.jumptable, tmpptr, strlen(tmpptr), newSViv((IV)_org_warhound_mdi_Number2SV), 0);
    RETVAL = kMDItemFSNodeCount;
OUTPUT:
    RETVAL


CFStringRef
kMDItemFSOwnerGroupID()
PREINIT:
    const char* tmpptr;
CODE:
    dMY_CXT;
    tmpptr = CFStringGetCStringPtr(kMDItemFSOwnerGroupID, CFStringGetSystemEncoding());
    hv_store(MY_CXT.jumptable, tmpptr, strlen(tmpptr), newSViv((IV)_org_warhound_mdi_Number2SV), 0);
    RETVAL = kMDItemFSOwnerGroupID;
OUTPUT:
    RETVAL


CFStringRef
kMDItemFSOwnerUserID()
PREINIT:
    const char* tmpptr;
CODE:
    dMY_CXT;
    tmpptr = CFStringGetCStringPtr(kMDItemFSOwnerUserID, CFStringGetSystemEncoding());
    hv_store(MY_CXT.jumptable, tmpptr, strlen(tmpptr), newSViv((IV)_org_warhound_mdi_Number2SV), 0);
    RETVAL = kMDItemFSOwnerUserID;
OUTPUT:
    RETVAL


CFStringRef
kMDItemFSSize()
PREINIT:
    const char* tmpptr;
CODE:
    dMY_CXT;
    tmpptr = CFStringGetCStringPtr(kMDItemFSSize, CFStringGetSystemEncoding());
    hv_store(MY_CXT.jumptable, tmpptr, strlen(tmpptr), newSViv((IV)_org_warhound_mdi_Number2SV), 0);
    RETVAL = kMDItemFSSize;
OUTPUT:
    RETVAL


CFStringRef
kMDItemPath()
PREINIT:
    const char* tmpptr;
CODE:
    dMY_CXT;
    tmpptr = CFStringGetCStringPtr(kMDItemPath, CFStringGetSystemEncoding());
    hv_store(MY_CXT.jumptable, tmpptr, strlen(tmpptr), newSViv((IV)_org_warhound_mdi_String2SV), 0);
    RETVAL = kMDItemPath;
OUTPUT:
    RETVAL


SV*
_get(item, attr)
    MDItemRef item
    CFStringRef attr
PREINIT:
    const char* tmpptr;
    SV** tmp;
    SV* (*callback_ptr)(CFTypeRef);
    CFTypeRef attrVal;
CODE:
    dMY_CXT;
    tmpptr =  CFStringGetCStringPtr(attr, CFStringGetSystemEncoding());
    tmp = hv_fetch(MY_CXT.jumptable, tmpptr, strlen(tmpptr), FALSE);
    callback_ptr = SvIV(*tmp);
    attrVal = MDItemCopyAttribute(item, attr);
    if (attrVal == NULL) {
        RETVAL = newSV(0);
    } else {
        RETVAL = (*callback_ptr)(attrVal);
        CFRelease(attrVal);
    }
OUTPUT:
    RETVAL

