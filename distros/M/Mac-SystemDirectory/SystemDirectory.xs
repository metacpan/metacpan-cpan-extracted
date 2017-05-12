#include <mach-o/dyld.h>
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#ifdef Move
#  undef Move
#endif Move

#ifdef I_POLL
#  undef I_POLL
#endif I_POLL

#import <Foundation/Foundation.h>

#define newSV_NSString(s) \
    newSVpvn([s UTF8String], (STRLEN)[s lengthOfBytesUsingEncoding:NSUTF8StringEncoding])

MODULE = Mac::SystemDirectory		PACKAGE = Mac::SystemDirectory		

PROTOTYPES: DISABLE

BOOT:
{
#define const_uv(name)                                      \
STMT_START {                                                \
    newCONSTSUB(stash, #name, newSVuv((UV)name));           \
    av_push(export, newSVpvn(#name, sizeof(#name) - 1));    \
} STMT_END

    HV *stash  = gv_stashpv("Mac::SystemDirectory", TRUE);
    AV *export = get_av("Mac::SystemDirectory::EXPORT_OK", TRUE);

    /* NSSearchPathDomainMask */
    const_uv(NSUserDomainMask);
    const_uv(NSLocalDomainMask);
    const_uv(NSNetworkDomainMask);
    const_uv(NSSystemDomainMask);
    const_uv(NSAllDomainsMask);

    /* NSSearchPathDirectory */
    const_uv(NSApplicationDirectory);
    const_uv(NSDemoApplicationDirectory);
    const_uv(NSDeveloperApplicationDirectory);
    const_uv(NSAdminApplicationDirectory);
    const_uv(NSLibraryDirectory);
    const_uv(NSDeveloperDirectory);
    const_uv(NSUserDirectory);
    const_uv(NSDocumentationDirectory);
#if defined(MAC_OS_X_VERSION_10_2)
    const_uv(NSDocumentDirectory);
#endif
#if defined(MAC_OS_X_VERSION_10_3)
    const_uv(NSCoreServiceDirectory);
#endif
#if defined(MAC_OS_X_VERSION_10_4)
    const_uv(NSDesktopDirectory);
    const_uv(NSCachesDirectory);
    const_uv(NSApplicationSupportDirectory);
#endif
#if (defined(MAC_OS_X_VERSION_10_5) && (MAC_OS_X_VERSION_MIN_REQUIRED >= MAC_OS_X_VERSION_10_5))
    const_uv(NSDownloadsDirectory);
#endif
    const_uv(NSAllApplicationsDirectory);
    const_uv(NSAllLibrariesDirectory);
#if (defined(MAC_OS_X_VERSION_10_6) && (MAC_OS_X_VERSION_MIN_REQUIRED >= MAC_OS_X_VERSION_10_6))
    const_uv(NSInputMethodsDirectory);
    const_uv(NSMoviesDirectory);
    const_uv(NSMusicDirectory);
    const_uv(NSPicturesDirectory);
    const_uv(NSPrinterDescriptionDirectory);
    const_uv(NSSharedPublicDirectory);
    const_uv(NSPreferencePanesDirectory);
    const_uv(NSItemReplacementDirectory);
#endif
}

void
FindDirectory(constant, mask=NSUserDomainMask)
   UV constant
   UV mask

  PREINIT:
     NSSearchPathDirectory directory;
     NSSearchPathDomainMask domainMask;

  INIT:
    directory = (NSSearchPathDirectory)constant;
    domainMask = (NSSearchPathDomainMask)mask;

  PPCODE:
    switch(directory) {
        case NSApplicationDirectory:
        case NSDemoApplicationDirectory:
        case NSAdminApplicationDirectory:
        case NSDeveloperApplicationDirectory:
        case NSLibraryDirectory:
        case NSDeveloperDirectory:
        case NSUserDirectory:
        case NSDocumentationDirectory:
#if defined(MAC_OS_X_VERSION_10_2)
        case NSDocumentDirectory:
#endif
#if defined(MAC_OS_X_VERSION_10_3)
        case NSCoreServiceDirectory:
#endif
#if defined(MAC_OS_X_VERSION_10_4)
        case NSDesktopDirectory:
        case NSCachesDirectory:
        case NSApplicationSupportDirectory:
#endif
#if (defined(MAC_OS_X_VERSION_10_5) && (MAC_OS_X_VERSION_MIN_REQUIRED >= MAC_OS_X_VERSION_10_5))
        case NSDownloadsDirectory:
#endif
        case NSAllApplicationsDirectory:
        case NSAllLibrariesDirectory:
#if (defined(MAC_OS_X_VERSION_10_6) && (MAC_OS_X_VERSION_MIN_REQUIRED >= MAC_OS_X_VERSION_10_6))
        case NSInputMethodsDirectory:
        case NSMoviesDirectory:
        case NSMusicDirectory:
        case NSPicturesDirectory:
        case NSPrinterDescriptionDirectory:
        case NSSharedPublicDirectory:
        case NSPreferencePanesDirectory:
        case NSItemReplacementDirectory:
#endif
        {
            NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
            NSArray *paths = NSSearchPathForDirectoriesInDomains(directory, domainMask, YES);
            int count = [paths count];

            if (count > 0) {
                NSString *path;

                if (count > 1 && GIMME_V == G_ARRAY) {
                    int i;
                    count = [paths count];

                    EXTEND(SP, count);
                    for (i=0; i < count; i++) {
                        path = [paths objectAtIndex:i];
                        PUSHs(sv_2mortal(newSV_NSString(path)));
                    }
                }
                else {
                    count = 1;
                    path = [paths objectAtIndex:0];
                    EXTEND(SP, 1);
                    PUSHs(sv_2mortal(newSV_NSString(path)));
                }
            }

            [pool release];

            if (count > 0)
                XSRETURN(count);
        }
        /* FALLTHROUGH */
    }
    XSRETURN_EMPTY;

void
HomeDirectory()

  ALIAS:
    Mac::SystemDirectory::HomeDirectory      = 0
    Mac::SystemDirectory::TemporaryDirectory = 1

  PREINIT:
    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
    NSString *path;

  PPCODE:
    switch (ix) {
        case 0:
            path = NSHomeDirectory();
            break;
        case 1:
            path = NSTemporaryDirectory();
            break;
        default:
            [pool release];
            croak("panic: unexpected ix: %d", (int)ix);
    }

    ST(0) = path ? sv_2mortal(newSV_NSString(path)) : &PL_sv_undef;

    [pool release];
    XSRETURN(1);

