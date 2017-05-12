
long
badPasteboardFlavorErr ()
    CODE:
	RETVAL = pbl_badPasteboardFlavorErr ();
    OUTPUT:
	RETVAL

long
badPasteboardIndexErr ()
    CODE:
	RETVAL = pbl_badPasteboardIndexErr ();
    OUTPUT:
	RETVAL

long
badPasteboardItemErr ()
    CODE:
	RETVAL = pbl_badPasteboardItemErr ();
    OUTPUT:
	RETVAL

long
badPasteboardSyncErr ()
    CODE:
	RETVAL = pbl_badPasteboardSyncErr ();
    OUTPUT:
	RETVAL

long
coreFoundationUnknownErr ()
    CODE:
	RETVAL = pbl_coreFoundationUnknownErr ();
    OUTPUT:
	RETVAL

long
duplicatePasteboardFlavorErr ()
    CODE:
	RETVAL = pbl_duplicatePasteboardFlavorErr ();
    OUTPUT:
	RETVAL

unsigned long
kPasteboardClientIsOwner ()
    CODE:
	RETVAL = pbl_kPasteboardClientIsOwner ();
    OUTPUT:
	RETVAL

SV *
kPasteboardClipboard ()
    PPCODE:
	{
	    char * text;
	    text = pbl_kPasteboardClipboard ();
	    EXTEND (SP, 3);
	    if (text == NULL) {
		PUSHs (sv_2mortal (newSV (0)));
	    } else {
		PUSHs (sv_2mortal (newSVpv (text, 0)));
	    }
	}

SV *
kPasteboardFind ()
    PPCODE:
	{
	    char * text;
	    text = pbl_kPasteboardFind ();
	    EXTEND (SP, 3);
	    if (text == NULL) {
		PUSHs (sv_2mortal (newSV (0)));
	    } else {
		PUSHs (sv_2mortal (newSVpv (text, 0)));
	    }
	}

unsigned long
kPasteboardFlavorNoFlags ()
    CODE:
	RETVAL = pbl_kPasteboardFlavorNoFlags ();
    OUTPUT:
	RETVAL

unsigned long
kPasteboardFlavorNotSaved ()
    CODE:
	RETVAL = pbl_kPasteboardFlavorNotSaved ();
    OUTPUT:
	RETVAL

unsigned long
kPasteboardFlavorPromised ()
    CODE:
	RETVAL = pbl_kPasteboardFlavorPromised ();
    OUTPUT:
	RETVAL

unsigned long
kPasteboardFlavorRequestOnly ()
    CODE:
	RETVAL = pbl_kPasteboardFlavorRequestOnly ();
    OUTPUT:
	RETVAL

unsigned long
kPasteboardFlavorSenderOnly ()
    CODE:
	RETVAL = pbl_kPasteboardFlavorSenderOnly ();
    OUTPUT:
	RETVAL

unsigned long
kPasteboardFlavorSenderTranslated ()
    CODE:
	RETVAL = pbl_kPasteboardFlavorSenderTranslated ();
    OUTPUT:
	RETVAL

unsigned long
kPasteboardFlavorSystemTranslated ()
    CODE:
	RETVAL = pbl_kPasteboardFlavorSystemTranslated ();
    OUTPUT:
	RETVAL

unsigned long
kPasteboardModified ()
    CODE:
	RETVAL = pbl_kPasteboardModified ();
    OUTPUT:
	RETVAL

SV *
kPasteboardUniqueName ()
    PPCODE:
	{
	    char * text;
	    text = pbl_kPasteboardUniqueName ();
	    EXTEND (SP, 3);
	    if (text == NULL) {
		PUSHs (sv_2mortal (newSV (0)));
	    } else {
		PUSHs (sv_2mortal (newSVpv (text, 0)));
	    }
	}

long
noPasteboardPromiseKeeperErr ()
    CODE:
	RETVAL = pbl_noPasteboardPromiseKeeperErr ();
    OUTPUT:
	RETVAL

long
notPasteboardOwnerErr ()
    CODE:
	RETVAL = pbl_notPasteboardOwnerErr ();
    OUTPUT:
	RETVAL
