#ifdef USE_PBL_BACKEND
#define PBL_LONG(x) pbl_##x ()
#define PBL_SV(sv,x) sv = newSVpv( pbl_##x(), 0 )
#else	/* ifdef USE_PBL_BACKEND */
#define PBL_LONG(x) x
#define PBL_SV(sv,x) CF_TO_SV( sv, x )
#endif	/* ifdef USE_PBL_BACKEND */


long
badPasteboardFlavorErr ()
    CODE:
	RETVAL = PBL_LONG( badPasteboardFlavorErr );
    OUTPUT:
	RETVAL

long
badPasteboardIndexErr ()
    CODE:
	RETVAL = PBL_LONG( badPasteboardIndexErr );
    OUTPUT:
	RETVAL

long
badPasteboardItemErr ()
    CODE:
	RETVAL = PBL_LONG( badPasteboardItemErr );
    OUTPUT:
	RETVAL

long
badPasteboardSyncErr ()
    CODE:
	RETVAL = PBL_LONG( badPasteboardSyncErr );
    OUTPUT:
	RETVAL

long
coreFoundationUnknownErr ()
    CODE:
	RETVAL = PBL_LONG( coreFoundationUnknownErr );
    OUTPUT:
	RETVAL

long
duplicatePasteboardFlavorErr ()
    CODE:
	RETVAL = PBL_LONG( duplicatePasteboardFlavorErr );
    OUTPUT:
	RETVAL

unsigned long
kPasteboardClientIsOwner ()
    CODE:
	RETVAL = PBL_LONG( kPasteboardClientIsOwner );
    OUTPUT:
	RETVAL

SV *
kPasteboardClipboard ()
    CODE:
	SV *sv;
	PBL_SV( sv, kPasteboardClipboard );
	RETVAL = sv;
    OUTPUT:
	RETVAL

SV *
kPasteboardFind ()
    CODE:
	SV *sv;
	PBL_SV( sv, kPasteboardFind );
	RETVAL = sv;
    OUTPUT:
	RETVAL

unsigned long
kPasteboardFlavorNoFlags ()
    CODE:
	RETVAL = PBL_LONG( kPasteboardFlavorNoFlags );
    OUTPUT:
	RETVAL

unsigned long
kPasteboardFlavorNotSaved ()
    CODE:
	RETVAL = PBL_LONG( kPasteboardFlavorNotSaved );
    OUTPUT:
	RETVAL

unsigned long
kPasteboardFlavorPromised ()
    CODE:
	RETVAL = PBL_LONG( kPasteboardFlavorPromised );
    OUTPUT:
	RETVAL

unsigned long
kPasteboardFlavorRequestOnly ()
    CODE:
	RETVAL = PBL_LONG( kPasteboardFlavorRequestOnly );
    OUTPUT:
	RETVAL

unsigned long
kPasteboardFlavorSenderOnly ()
    CODE:
	RETVAL = PBL_LONG( kPasteboardFlavorSenderOnly );
    OUTPUT:
	RETVAL

unsigned long
kPasteboardFlavorSenderTranslated ()
    CODE:
	RETVAL = PBL_LONG( kPasteboardFlavorSenderTranslated );
    OUTPUT:
	RETVAL

unsigned long
kPasteboardFlavorSystemTranslated ()
    CODE:
	RETVAL = PBL_LONG( kPasteboardFlavorSystemTranslated );
    OUTPUT:
	RETVAL

unsigned long
kPasteboardModified ()
    CODE:
	RETVAL = PBL_LONG( kPasteboardModified );
    OUTPUT:
	RETVAL

SV *
kPasteboardUniqueName ()
    CODE:
	SV *sv;
	PBL_SV( sv, kPasteboardUniqueName );
	RETVAL = sv;
    OUTPUT:
	RETVAL

long
noPasteboardPromiseKeeperErr ()
    CODE:
	RETVAL = PBL_LONG( noPasteboardPromiseKeeperErr );
    OUTPUT:
	RETVAL

long
notPasteboardOwnerErr ()
    CODE:
	RETVAL = PBL_LONG( notPasteboardOwnerErr );
    OUTPUT:
	RETVAL

# ex: set filetype=xs :
