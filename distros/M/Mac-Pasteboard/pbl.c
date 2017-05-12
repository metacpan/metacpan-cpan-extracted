
/*
 * gcc -c pbl.c
 * -or-
 * gcc -o pbl -DTEST pbl.c -framework ApplicationServices
 *
 * See http://developer.apple.com/documentation/Carbon/Conceptual/Pasteboard_Prog_Guide/
 * for pasteboard programming info, and
 * http://developer.apple.com/documentation/Carbon/Reference/Pasteboard_Reference/Reference/reference.html
 * for the programming reference. See
 * http://developer.apple.com/documentation/CoreFoundation/Conceptual/CFStrings/
 * for information on manipulating CFStrings.
 *
 * http://developer.apple.com/documentation/Carbon/Reference/Pasteboard_Reference/Reference/reference.html#//apple_ref/doc/uid/TP40001413-CH5g-105037
 * says the result codes are:
 *  badPasteboardSyncErr = -25130:
 *    The pasteboard has been modified and must be synchronized before use.
 *  badPasteboardIndexErr = -25131:
 *    The specified item does not exist.
 *  badPasteboardItemErr = -25132:
 *    The item reference does not exist.
 *  badPasteboardFlavorErr = -25133:
 *    The item flavor does not exist.
 *  duplicatePasteboardFlavorErr = -25134:
 *    The item flavor already exists.
 *  notPasteboardOwnerErr = -25135:
 *    The application did not clear the pasteboard before attempting to
 *    add flavor data.
 *  noPasteboardPromiseKeeperErr = -25136:
 *    The application attempted to add promised data without previously
 *    registering a promise keeper callback.
 */

#include <string.h>

#ifdef TEST
#include <stdio.h>
#endif

#include <ApplicationServices/ApplicationServices.h>
#include "pbl.h"

#define ENCODING kCFStringEncodingASCII

/*
 * char *pblx_get_cstring (CFStringRef data)
 *
 * This function returns the string contained in the data. It returns
 * NULL if the operation fails for any reason. If the result is not
 * NULL, you must free() the returned string.
 */

char * pblx_get_cstring (CFStringRef data) {
    const char *bytes;
    char *chars;
    size_t len;
    if (data == NULL) {
	chars = NULL;
    } else {
	bytes = CFStringGetCStringPtr (data, ENCODING);
	if (bytes == NULL) {
	    len = (size_t) CFStringGetLength (data) + 1;
	    chars = (char *) MALLOC ("pblx_get_cstring chars 1",
		    len * sizeof (char));
	    if (chars != NULL) {
		if (!CFStringGetCString (data, chars, (CFIndex) len, ENCODING)) {
		    FREE ("pblx_get_cstring chars", chars);
		    chars = NULL;
		}
	    }
	} else {
	    len = strlen (bytes) + 1;
	    chars = (char *) MALLOC ("pblx_get_cstring chars 2",
		    len * sizeof (char));
	    if (chars != NULL)
		strcpy (chars, bytes);
	}
    }
    return chars;
}

#ifdef DEBUG_PBL
#include <execinfo.h>
#include <stdlib.h>
#define CHECK(sub,var) \
    fprintf (stderr, "Debug %s - %s returned %ld\n", ROUTINE, sub, var); \
    if (var) goto cleanup;
#define LOG_C(var,dta) { \
    if ((dta) == NULL) { \
	fprintf (stderr, "Debug %s - %s is NULL\n", ROUTINE, var); \
    } else { \
	fprintf (stderr, "Debug %s - %s is '%s'\n", ROUTINE, var, dta); \
    } \
}
#define LOG_CF(var,dta) pblx_log (ROUTINE, var, dta);
#define LOG_L(var,dta) fprintf (stderr, "Debug %s - %s is %ld\n", ROUTINE, var, (long) dta)
#define LOG_P(var,dta) fprintf (stderr, "Debug %s - %s is %p\n", ROUTINE, var, dta)
#define LOG_TEXT(txt) fprintf (stderr, "Debug %s - %s\n", ROUTINE, txt)
#define LOG_ENTRY fprintf (stderr, "Debug %s (", ROUTINE);
#define LOG_ARG(data,punc) fprintf (stderr, "%s%s", data, punc)
#define LOG_ARG_L(var,punc) fprintf (stderr, "%ld%s", (long) var, punc)
#define LOG_ARG_P(var,punc) fprintf (stderr, "%p%s", var, punc)
#define LOG_ARG_S(var,punc) { \
	if (var == NULL) \
	    fprintf (stderr, "NULL%s", punc); \
	else \
	    fprintf (stderr, "\"%s\"%s", var, punc); \
    }

void pblx_log (char * routine, char * var, CFStringRef data) {
    char *buffer;
    buffer = pblx_get_cstring (data);
    if (buffer == NULL) {
	fprintf (stderr, "Debug %s - %s is NULL\n", routine, var);
    } else {
	fprintf (stderr, "Debug %s - %s is \"%s\"\n", routine, var, buffer);
	FREE ("pblx_log buffer", buffer);
    }
}

#ifdef DEBUG_PBL_BACKTRACE
#define BACKTRACE_CALLSTACK 128
void pblx_backtrace () {
    void *callstack[BACKTRACE_CALLSTACK];
    int inx;
    int frames;
    char **strs;
    frames = backtrace (callstack, BACKTRACE_CALLSTACK);
    strs = backtrace_symbols (callstack, frames);
    for (inx = 1; inx < frames; inx++) {
	fprintf (stderr, "    %s\n", strs[inx]);
    }
    free (strs);
}
#else
#define pblx_backtrace()
#endif

void pblx_free (char *mod, void *mem) {
    fprintf (stderr, "Debug %s - free %p\n", mod, mem);
    pblx_backtrace ();
    free (mem);
}

void * pblx_malloc (char *mod, size_t size) {
    void *mem = malloc (size);
    fprintf (stderr, "Debug %s - %p = malloc (%ld)\n", mod, mem, size);
    pblx_backtrace ();
    return mem;
}

#else
#define CHECK(sub,var) if (var) goto cleanup;
#define LOG_C(var,dta)
#define LOG_CF(var,dta)
#define LOG_L(var,dta)
#define LOG_P(var,dta)
#define LOG_TEXT(txt)
#define LOG_ENTRY
#define LOG_ARG(data,punc)
#define LOG_ARG_L(var,punc)
#define LOG_ARG_P(var,punc)
#define LOG_ARG_S(var,punc)
#endif

/*
 * CFStringRef = pblx_cfstr (const char *cstr, CFStringRef dflt)
 *
 * This subroutine converts the null-terminated string in cstr into a
 * CoreFoundation string reference and returns it. If cfstr is NULL or
 * the empty string, the dflt is returned instead.
 *
 * The returned string must be released with CFRelease when you are
 * done with it. If the default is taken, CFRetain is called on the
 * default, to prevent premature deallocation of (perhaps) a program
 * constant.
 */

#undef ROUTINE
#define ROUTINE "pblx_cfstr"
CFStringRef pblx_cfstr (const char *cstr, CFStringRef dflt) {
    CFStringRef cfstr;
    if (cstr == NULL || *cstr == '\0') {
	cfstr = dflt;
	if (dflt != NULL)
	    CFRetain (dflt);	/* since it will be released elsewhere */
    } else {
	cfstr = CFStringCreateWithCString (NULL, cstr, ENCODING);
    }
    return cfstr;
}

#define PBLX_PBNAME(cname) pblx_cfstr (cname, kPasteboardClipboard)
#define PBLX_FLAVOR(flav) pblx_cfstr (flav, CFSTR(DEFAULT_FLAVOR))

#undef ROUTINE
#define ROUTINE "pbl_create"
OSStatus pbl_create (
	const char * cname, void **pbref, char **created_name) {
    CFStringRef sname = NULL;
    OSStatus stat;

    *pbref = NULL;
    if (created_name != NULL)
	*created_name = NULL;
    LOG_ENTRY;
    LOG_ARG_S (cname, ", ");
    LOG_ARG ("*pbref", ")\n");

    if (cname == NULL) {
	sname = (CFStringRef) NULL;
	LOG_TEXT ("Pasteboard name is null");
    } else {
	sname = PBLX_PBNAME (cname);
	LOG_CF ("Pasteboard name", sname)
    }

    stat = PasteboardCreate (sname, (PasteboardRef *) pbref);
    LOG_P ("Pastebord reference", *pbref);
    CHECK ("PasteboardCreate", stat);

    if (created_name != NULL) {

#ifdef TIGER

	CFStringRef pbname;
	if (PasteboardCopyName ((PasteboardRef) *pbref, &pbname)) {
	    *created_name = pblx_get_cstring (sname);
	} else {
	    *created_name = pblx_get_cstring (pbname);
	    CFRelease (pbname);
	}

#else

	*created_name = pblx_get_cstring (sname);

#endif


	LOG_C ("Created name", *created_name);
    }


cleanup:

    if (sname != NULL) CFRelease (sname);

    return stat;
}

#undef ROUTINE
#define ROUTINE "pbl_clear"
OSStatus pbl_clear (void * pbref) {
    OSStatus stat;

    LOG_ENTRY;
    LOG_ARG_P (pbref, ")\n");

    stat = PasteboardClear (pbref);
    CHECK ("PasteboardClear", stat);

cleanup:

    return stat;
}

#undef ROUTINE
#define ROUTINE "pbl_copy"
OSStatus pbl_copy (
	void * pbref,
	const unsigned char * cdata,
	size_t size,
	unsigned long id,
	const char * cflavor,
	PB_FLAVOR_FLAGS flags
	) {

    CFDataRef pbdata = NULL;
    CFStringRef sflavor = NULL;
    OSStatus stat;
    PasteboardSyncFlags sync;

    LOG_ENTRY;
    LOG_ARG_P (pbref, ", ");
    LOG_ARG_S (cdata, ", ");
    LOG_ARG_L (size, ", ");
    LOG_ARG_L (id, ", ");
    LOG_ARG_S (cflavor, ")\n");

    /*
     * It seems that I _can_ in fact get rid of the following, but
     * I must do a clear _somewhere_ in the code to put data on the
     * pasteboard.
    stat = PasteboardClear (pbref);
    CHECK ("PasteboardClear", stat)
     *
     * The other thing I could do here is a synchronize (q.v.), and
     * then clear if we do not own the pasteboard.
     */

    /* The synch is really only needed if we have two objects
     * representing the same pasteboard. */

    sync = PasteboardSynchronize (pbref);

    if (cdata == NULL) {
	pbdata = CFDataCreate (NULL, (const unsigned char *) "", 0);
    } else {
	pbdata = CFDataCreate (NULL, cdata, size);
    }


    sflavor = PBLX_FLAVOR (cflavor);
    LOG_CF ("Flavor", sflavor);

    stat = PasteboardPutItemFlavor (pbref, (PasteboardItemID) id,
	    sflavor, pbdata, (PasteboardFlavorFlags) flags);
    CHECK ("PasteboardPutItemFlavor", stat)


cleanup:

    if (sflavor != NULL) CFRelease (sflavor);
    if (pbdata != NULL) CFRelease (pbdata);

    return stat;
}

#undef ROUTINE
#define ROUTINE "pbl_paste"
OSStatus pbl_paste (
	void *pbref,
	int any,
	unsigned long id,
	const char *flavor,
	unsigned char **data,
	size_t *size,
	PB_FLAVOR_FLAGS *flags
	) {
    CFArrayRef	flavor_array = NULL;
    CFDataRef	flavor_data = NULL;
    ItemCount	item_inx;
    ItemCount	pb_items;
    PasteboardSyncFlags sync;
    OSStatus	stat;
    CFStringRef	want_flavor = NULL;

    LOG_ENTRY;
    LOG_ARG_P (pbref, ", ");
    LOG_ARG_L (any, ", ");
    LOG_ARG_L (id, ", ");
    LOG_ARG_S (flavor, ", ");
    LOG_ARG_P (data, ", ");
    LOG_ARG_P (size, ")\n");

    *data = NULL;
    *size = 0;
    *flags = 0;

    sync = PasteboardSynchronize (pbref);
    stat = PasteboardGetItemCount (pbref, &pb_items);
    CHECK ("PasteboardGetItemCount", stat);

    want_flavor = PBLX_FLAVOR (flavor);

    for (item_inx = pb_items; item_inx > 0; --item_inx) {

	PasteboardItemID item_id;

	stat = PasteboardGetItemIdentifier (pbref, item_inx, &item_id);
	CHECK ("PasteboardGetItemIdentifier", stat);

	if (!any && item_id != (PasteboardItemID) id)
	    continue;

	stat = PasteboardCopyItemFlavorData (
		pbref, item_id, want_flavor, &flavor_data);
	if (any && stat == badPasteboardFlavorErr)
	    continue;
	CHECK ("PasteboardCopyItemFlavorData", stat);

	stat = PasteboardGetItemFlavorFlags (
		pbref, item_id, want_flavor,
		(PasteboardFlavorFlags *) flags);
	CHECK ("PasteboardGetItemFlavorFlags", stat);

	*size = (size_t) CFDataGetLength (flavor_data);
	*data = (unsigned char *) MALLOC ("pbl_paste data",
		*size * sizeof (UInt8));

	if (*data == NULL) {
	    *size = 0;
	    stat = cNoMemErr;
	} else {
	    CFDataGetBytes (
		    flavor_data,
		    CFRangeMake (0, (CFIndex) *size), *data);
	}

	goto cleanup;

    }

    stat = badPasteboardFlavorErr;

cleanup:

    if (flavor_array != NULL) CFRelease (flavor_array);
    if (flavor_data != NULL) CFRelease (flavor_data);
    if (want_flavor != NULL) CFRelease (want_flavor);

    return stat;
}

#undef ROUTINE
#define ROUTINE "pbl_synch"
unsigned long pbl_synch (void *pbref) {

    LOG_ENTRY;
    LOG_ARG_P (pbref, ")\n");

    return (unsigned long) PasteboardSynchronize (pbref);
}

#undef ROUTINE
#define ROUTINE "pbl_uti_tags"
void pbl_uti_tags (char * c_uti, pbl_uti_tags_t * tags) {
    CFStringRef cf_uti = NULL;
    CFStringRef cf_tag = NULL;

    cf_uti = pblx_cfstr (c_uti, NULL);

    cf_tag = UTTypeCopyPreferredTagWithClass (cf_uti,
	    kUTTagClassFilenameExtension);
    if (cf_tag == NULL) {
	tags->extension = NULL;
    } else {
	tags->extension = pblx_get_cstring (cf_tag);
	CFRelease (cf_tag);
    }

    cf_tag = UTTypeCopyPreferredTagWithClass (cf_uti,
	    kUTTagClassMIMEType);
    if (cf_tag == NULL) {
	tags->mime = NULL;
    } else {
	tags->mime = pblx_get_cstring (cf_tag);
	CFRelease (cf_tag);
    }

    cf_tag = UTTypeCopyPreferredTagWithClass (cf_uti,
	    kUTTagClassNSPboardType);
    if (cf_tag == NULL) {
	tags->pboard = NULL;
    } else {
	tags->pboard = pblx_get_cstring (cf_tag);
	CFRelease (cf_tag);
    }

    cf_tag = UTTypeCopyPreferredTagWithClass (cf_uti,
	    kUTTagClassOSType);
    if (cf_tag == NULL) {
	tags->os = NULL;
    } else {
	tags->os = pblx_get_cstring (cf_tag);
	CFRelease (cf_tag);
    }

cleanup:

    if (cf_uti != NULL) CFRelease (cf_uti);

}

#undef ROUTINE
#define ROUTINE "pbl_all"
OSStatus pbl_all (void * pbref, pbl_rqst_t * rqst, pbl_resp_t **resp, size_t *num_resp) {
    CFArrayRef	flavor_array = NULL;
    CFDataRef	flavor_data = NULL;
    pbl_resp_t *rs;
    ItemCount	item_inx;
    size_t	nr;
    ItemCount	pb_items;
    PasteboardSyncFlags sync;
    OSStatus	stat;
    CFStringRef	conforms;

    LOG_ENTRY;
    LOG_ARG_P (pbref, ", ");
    LOG_ARG_P (rqst, ",");
    LOG_ARG_P (resp, ")\n");

    LOG_L ("rqst->all", (long) rqst->all);
    LOG_L ("rqst->id", (long) rqst->id);
    LOG_C ("rqst->conforms_to", rqst->conforms_to);
    LOG_L ("rqst->want_data", (long) rqst->want_data);

    *resp = rs = NULL;
    *num_resp = nr = 0;

    conforms = pblx_cfstr (rqst->conforms_to, NULL);

    sync = PasteboardSynchronize (pbref);
    stat = PasteboardGetItemCount (pbref, &pb_items);
    CHECK ("PasteboardGetItemCount", stat);

    for (item_inx = 1; item_inx <= pb_items; item_inx++) {

	PasteboardItemID item_id;
	CFIndex	flavor_count;
	CFIndex	flavor_inx;

	stat = PasteboardGetItemIdentifier (pbref, item_inx, &item_id);
	CHECK ("PasteboardGetItemIdentifier", stat);

	if (!rqst->all && item_id != (PasteboardItemID) rqst->id)
	    continue;

	stat = PasteboardCopyItemFlavors (pbref, item_id, &flavor_array);
	CHECK ("PasteboardCopyItemFlavors", stat);

	flavor_count = CFArrayGetCount (flavor_array);

	/* Note that if we specify conformance we're over-allocating,
	 * but not by much, and I don't know an easy way out of it.
	 */

	if (rs == NULL) {
	    rs = MALLOC ("pbl_all rs",
		    (size_t) flavor_count * sizeof (pbl_resp_t));
	} else {
	    pbl_resp_t * temp;
	    temp = realloc (rs,
		    (size_t) (flavor_count + nr) * sizeof (pbl_resp_t));
	    if (temp == NULL) {
		goto no_memory;
	    } else {
		rs = temp;
	    }
	}	

	for (flavor_inx = 0; flavor_inx < flavor_count; flavor_inx++) {

	    CFStringRef flavor_type;

	    rs[nr].flavor = NULL;
	    rs[nr].data = NULL;

	    flavor_type = (CFStringRef) CFArrayGetValueAtIndex (
		    flavor_array, flavor_inx);
	    LOG_CF ("flavor_type", flavor_type);

	    if (conforms == NULL || UTTypeConformsTo (
			flavor_type, conforms)) {
		size_t inx;

		rs[nr].id = (unsigned long) item_id;
		inx = nr++;

		stat = PasteboardGetItemFlavorFlags (
			pbref, item_id, flavor_type, &rs[inx].flags);
		CHECK ("PasteboardGetItemFlavorFlags", stat);

		rs[inx].flavor = pblx_get_cstring (flavor_type);
		if (rs[inx].flavor == NULL) {
/*		    CFRelease (flavor_type);	Do not release */
		    goto no_memory;
		}

		if (rqst->want_data) {

		    stat = PasteboardCopyItemFlavorData (
			    pbref, item_id, flavor_type, &flavor_data);
		    CHECK ("PasteboardCopyItemFlavorData", stat);

		    rs[inx].size = (size_t) CFDataGetLength (flavor_data);
		    rs[inx].data = (unsigned char *) MALLOC (
			    "bpl_all rs[inx].data",
			    rs[inx].size * sizeof (UInt8));
		    if (rs[inx].data == NULL)
			goto no_memory;

		    CFDataGetBytes (
			    flavor_data,
			    CFRangeMake (0, (CFIndex) rs[inx].size),
			    rs[inx].data);
		}

	    }

/*	    CFRelease (flavor_type);	Do not release */

	}

	if (flavor_array != NULL) {
	    CFRelease (flavor_array);
	    flavor_array = NULL;
	}
    }

    goto cleanup;

no_memory:

    pbl_free_all (rs, nr);
    rs = NULL;
    nr = 0;
    stat = cNoMemErr;
    goto cleanup;

cleanup:

    if (flavor_array != NULL) CFRelease (flavor_array);
    if (flavor_data != NULL) CFRelease (flavor_data);
    *resp = rs;
    *num_resp = nr;

    return stat;
}

#undef ROUTINE
#define ROUTINE "pbl_free_all"
void pbl_free_all (pbl_resp_t *data, size_t size) {
    size_t	inx;
    for (inx = 0; inx < size; inx++) {
	if (data[inx].flavor != NULL)
	    FREE ("pbl_free_all data[inx].flavor", data[inx].flavor);
	if (data[inx].data != NULL)
	    FREE ("pbl_free_all data[inx].data", data[inx].data);
    }
    FREE ("pbl_free_all data", data);
}

#undef ROUTINE
#define ROUTINE "pbl_release"
OSStatus pbl_release (void * pbref) {

    LOG_ENTRY;
    LOG_ARG_P (pbref, ")\n");

    if (pbref != NULL) CFRelease (pbref);

    return (OSStatus) 0;
}

#undef ROUTINE
#define ROUTINE "pbl_retain"
OSStatus pbl_retain (void * pbref) {

    LOG_ENTRY;
    LOG_ARG_P (pbref, ")\n");

    if (pbref != NULL) CFRetain (pbref);

    return (OSStatus) 0;
}

#include "constant-h.inc"
#include "constant-c.inc"

#ifdef TEST

#define ARGUMENT(x) (argc > x ? argv[x] : NULL)
#define ARGUMENT_D(x,y) (argc > x ? argv[x] : y )

void help () {
    fprintf( stderr, "Valid commands are:\n" );
    fprintf( stderr, "clear [pasteboard_name]\n" );
    fprintf( stderr, "copy data [flavor [pasteboard_name]]\n" );
    fprintf( stderr, "create [pasteboard_name]\n" );
    fprintf( stderr, "paste [pasteboard_name [flavor]]\n" );
    fprintf( stderr, "pbl_all [pasteboard_name]\n" );
}

int main (int argc, char **argv) {
    OSStatus stat = 1;
    if (argc > 1) {
	if (!strcmp (argv[1], "clear")) {
	    PasteboardRef pbref;
	    stat = pbl_create (ARGUMENT(2), (void **) &pbref, NULL);
	    if (!stat && pbref != NULL) {
		stat = pbl_clear (pbref);
		CFRelease (pbref);
	    }
	} else if (!strcmp (argv[1], "copy")) {
	    if (ARGUMENT(2) == NULL) {
		fprintf (stderr, "You must supply an argument to 'copy'\n");
	    } else {
		PasteboardRef pbref;
		stat = pbl_create(
			ARGUMENT_D( 4, "com.apple.pasteboard.clipboard" ),
			(void **) &pbref, NULL );
		if (!stat && pbref != NULL) {
		    stat = pbl_clear (pbref);
		    if (!stat)
			stat = pbl_copy (
				pbref,
				(const unsigned char *) ARGUMENT(2),
				strlen (ARGUMENT(2)),
				1, ARGUMENT(3), 0);
		    CFRelease (pbref);
		}
	    }
	} else if (!strcmp (argv[1], "create")) {
	    PasteboardRef pbref = NULL;
	    char *pbname = NULL;
	    stat = pbl_create (
		    ARGUMENT_D( 2, "com.apple.pasteboard.clipboard" ),
		    (void **) &pbref, &pbname);
	    if (pbname != NULL) {
		fprintf (stderr, "Created pasteboard \"%s\"\n", pbname);
		FREE ("main pbname", pbname);
	    }
	    if (pbref != NULL)
		CFRelease (pbref);
	} else if (!strcmp (argv[1], "paste")) {
	    PasteboardRef pbref;
	    stat = pbl_create(
		    ARGUMENT_D( 2, "com.apple.pasteboard.clipboard" ),
		    (void **) &pbref, NULL );
	    if (!stat && pbref != NULL) {
		unsigned char* data;
		size_t size;
		PB_FLAVOR_FLAGS flags;
		stat = pbl_paste( pbref, 1, 0UL, ARGUMENT( 3 ),
			&data, &size, &flags );
		if ( data != NULL ) {
		    data[size] = '\0';
		    printf( "data: '%s'\n", data );
		    printf( "size: %lu\n", size );
		    printf( "flags: %#lx\n", flags );
		}
		CFRelease (pbref);
	    }
	} else if (!strcmp (argv[1], "pbl_all")) {
	    PasteboardRef pbref;
	    stat = pbl_create(
		    ARGUMENT_D( 2, "com.apple.pasteboard.clipboard" ),
		    (void **) &pbref, NULL );
	    if (!stat && pbref != NULL) {
		pbl_rqst_t rqst = {
		    1,
		    0,
		    NULL,
		    1,
		};
		pbl_resp_t *resp;
		size_t num_resp;
		int inx;
		stat = pbl_all( pbref, &rqst, &resp, &num_resp );
		for ( inx = 0; inx < num_resp; inx++ ) {
		    printf( "\nid: %lu\n", resp[inx].id );
		    printf( "flavor: %s\n", resp[inx].flavor );
		    printf( "flavor flags: %#lx\n", resp[inx].flags );
		    if ( resp[inx].data != NULL ) {
			printf( "data: %s\n", resp[inx].data );
			printf( "size: %lu\n", resp[inx].size );
		    }
		}
		pbl_free_all( resp, num_resp );
		CFRelease (pbref);
	    }
	} else {
	    fprintf (stderr, "%s command %s not recognized.\n", argv[0],
		    argv[1]);
	    help ();
	}
    } else {
	fprintf (stderr, "%s needs at least one argument.\n", argv[0]);
	help ();
    }
    if (stat) {
	fprintf (stderr, "Error - Status = %li\n", stat);
    }
    return stat ? 1 : 0;
}

#endif
