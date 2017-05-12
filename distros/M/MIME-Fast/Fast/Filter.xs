
MODULE = MIME::Fast		PACKAGE = MIME::Fast::Filter		PREFIX=g_mime_filter_

void
DESTROY(mime_filter)
        MIME::Fast::Filter	mime_filter
    CODE:
        if (gmime_debug)
          warn("g_mime_filter_DESTROY: 0x%x %s", mime_filter,
	  g_list_find(plist,mime_filter) ? "(true destroy)" : "(only attempt)");
	if (g_list_find(plist,mime_filter)) {
	  g_object_unref (mime_filter);
	  plist = g_list_remove(plist, mime_filter);
	}

 #
 # Copies @filter into a new GMimeFilter object.
 #
MIME::Fast::Filter
g_mime_filter_copy (filter);
	MIME::Fast::Filter	filter
    CODE:
	RETVAL = g_mime_filter_copy (filter);
	plist = g_list_prepend (plist, RETVAL);
    OUTPUT:
	RETVAL

void
g_mime_filter_reset (filter)
	MIME::Fast::Filter	filter

void
g_mime_filter_set_size (filter, size, keep)
	MIME::Fast::Filter	filter
	size_t			size
	gboolean		keep


