#ifndef _PBL_H_LOADED

/* I would love to include ApplicationSupport/HISupport/Pastboard.h here
 * so that I could use type PasteboardFlavorFlags in pb_resp_t. But *&#@
 * Apple does not let me include subframeworks, so I have to use type
 * OptionBits from OSTypes.h, since that is what PastboardFlavorFlags is
 * defined in terms of. I could have included
 * ApplicationSupport/ApplicationSupport.h, but that drags in the world,
 * and more to the point causes compile errors under Mac OS 10.3
 * Panther, which I support (possibly through sheer, bone-headed
 * stupidity).
 */

#ifdef USE_MACTYPES
#include <MacTypes.h>
#else
#include <Kernel/libkern/OSTypes.h>
#endif

#define PB_FLAVOR_FLAGS OptionBits

#include <CoreFoundation/CFBase.h>

/* this could also credibly be "public.plain-text", but in point
 * of fact the text programs I could bring easily to bear (pbpaste,
 * AppleWorks, vim, and PasteboardPeeker) could not see this.
 */
#ifdef UTF_8_PLAIN_TEXT
#define DEFAULT_FLAVOR "public.utf8-plain-text"
#define DEFAULT_ENCODE 1
#else
#define DEFAULT_FLAVOR "com.apple.traditional-mac-plain-text"
#define DEFAULT_ENCODE 0
#endif /* def UTF_8_PLAIN_TEXT */

#ifdef DEBUG_PBL
void pblx_free (char *mod, void *mem);
#define FREE(mod,x) pblx_free (mod, x)
void *pblx_malloc (char *mod, size_t size);
#define MALLOC(mod,x) pblx_malloc (mod, x)
#else
#define FREE(mod,x) free(x)
#define MALLOC(mod,x) malloc(x)
#endif

/*
 * the pbl_rqst_t data type describes the request to pbl_all.
 */

typedef struct {
    int all;		/* return all items if true */
    unsigned long id;	/* item id to return if all is false */
    char * conforms_to;	/* flavor to conform to if not NULL */
    int want_data;	/* return flavor data if true */
} pbl_rqst_t;

/*
 * The pbl_resp_t data type describes the response from pbl_all.
 */

typedef struct {
    unsigned long id;		/* id of item data is from */
    char *flavor;		/* flavor of data */
    PB_FLAVOR_FLAGS flags;	/* flavor flags */
    unsigned char *data;	/* only returned if want_data is true */
    size_t size;		/* only returned if want_data is true */
} pbl_resp_t;

/*
 * The pbl_uti_tags_t data type holds preferred tags associated with
 * UTIs.
 */

typedef struct {
    char * extension;		/* for kUTTagClassFilenameExtension */
    char * mime;		/* for kUTTagClassMIMEType */
    char * pboard;		/* for kUTTagClassNSPboardType */
    char * os;			/* for kUTTagClassOSType */
} pbl_uti_tags_t;

/*
 * pbl_create creates the named pasteboard, returning a reference to it
 * in the second argument. If the name is NULL or the empty string, a
 * reference to the system pasteboard is returned.
 */

OSStatus pbl_create (
	const char * pbname,
	void ** pbref,
	char ** created_name
	);

/*
 * pbl_clear clears the pasteboard indicated by the reference. This MUST
 * be done before writing to the pasteboard.
 */

OSStatus pbl_clear (
	void * pbref
	);

/*
 * pbl_copy puts the given data on the pasteboard indicated by the
 * reference. The size argument indicates how much data to move, and
 * must not be greater than the actual amount of data available. If the
 * flavor of the data is NULL or an empty string, it defaults to the
 * defined DEFAULT_FLAVOR. The data on the pasteboard is NOT cleared
 * first.
 */

OSStatus pbl_copy (
	void *pbref,
	const unsigned char *data,
	size_t size,
	unsigned long id,
	const char *pbflavor,
	PB_FLAVOR_FLAGS flags
	);

/*
 * pbl_paste returns the desired flavor of pasteboard data from the
 * pasteboard item with the given id (or the first one encountered if
 * the 'any' argument is true), and the size of the data.  You must
 * free() the data after use.
 */

OSStatus pbl_paste (
	void *pbref,
	int any,
	unsigned long id,
	const char *pbflavor,
	unsigned char **data,
	size_t *size,
	PB_FLAVOR_FLAGS *flags
	);

/*
 * pbl_release releases the pasteboard indicated by the reference. This
 * reference must not be used subsequent to the release. This routine
 * always succeeds.
 */

OSStatus pbl_release (
	void * pbref
	);

/*
 * pbl_retain retains the pasteboard indicated by the reference. Since
 * CoreFoundation uses a reference-count garbage collection system,
 * calling this will cause the next pbl_release NOT to release the
 * pasteboard. The only valid use of this I can think of is when cloning
 * an object.
 */

OSStatus pbl_retain (
	void * pbref
	);

/*
 * pbl_synch calls PasteboardSynchronize, and returns the
 * synchronization flags.
 */

unsigned long pbl_synch (void * pbref);

/*
 * pbl_uti_tags returns the preferred tags associated with the given
 * UTI in the given structure. On return, the elements of the structure
 * will contain either strings (which must be freed), or NULL.
 */

void pbl_uti_tags (char * c_uti, pbl_uti_tags_t * tags);

/*
 * pbl_all returns everything on the clipboard, subject to the settings
 * in the rqst argument, to wit:
 *     if rqst.all is false, only data matching the given id is
 *         returned.
 *     if rqst.want_data is false, the actual flavor data is not
 *         returned.
 */

OSStatus pbl_all (
	void * pbref,
	pbl_rqst_t *rqst,
	pbl_resp_t **resp,
	size_t * num_resp
	);

/*
 * pbl_free_all frees the structure returned by pbl_all.
 */

void pbl_free_all (pbl_resp_t *data, size_t size);

#define _PBL_H_LOADED

#endif
