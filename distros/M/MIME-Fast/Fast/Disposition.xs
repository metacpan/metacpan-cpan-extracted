
MODULE = MIME::Fast		PACKAGE = MIME::Fast::Disposition	PREFIX=g_mime_disposition_

MIME::Fast::Disposition
g_mime_disposition_new(Class, disposition)
        char *		Class
	const char *	disposition
    CODE:
        RETVAL = g_mime_disposition_new (disposition);
        plist = g_list_prepend(plist, RETVAL);
    OUTPUT:
        RETVAL

# destroy(mime_disposition)
void
DESTROY(mime_disposition)
        MIME::Fast::Disposition	mime_disposition
    CODE:
        if (gmime_debug)
          warn("g_mime_disposition_DESTROY: 0x%x %s", mime_disposition,
	  g_list_find(plist,mime_disposition) ? "(true destroy)" : "(only attempt)");
	if (g_list_find(plist,mime_disposition)) {
	  g_mime_disposition_destroy (mime_disposition);
	  plist = g_list_remove(plist, mime_disposition);
	}

void
g_mime_disposition_set(mime_disposition, value)
	MIME::Fast::Disposition	mime_disposition
	const char *		value

const char *
g_mime_disposition_get(mime_disposition)
	MIME::Fast::Disposition	mime_disposition

void
g_mime_disposition_add_parameter(mime_disposition, attribute, value)
	MIME::Fast::Disposition	mime_disposition
	const char *		attribute
	const char *		value

const char *
g_mime_disposition_get_parameter(mime_disposition, attribute)
	MIME::Fast::Disposition	mime_disposition
	const char *		attribute

SV *
g_mime_disposition_header(mime_disposition, fold)
	MIME::Fast::Disposition	mime_disposition
	gboolean		fold
    PREINIT:
        char *		out = NULL;
    CODE:
        out = g_mime_disposition_header(mime_disposition, fold);
        if (out) {
          RETVAL = newSVpvn(out,0);
          g_free(out);
        } else
          RETVAL = &PL_sv_undef;
    OUTPUT:
        RETVAL


