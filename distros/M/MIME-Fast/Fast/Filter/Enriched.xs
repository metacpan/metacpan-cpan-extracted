
MODULE = MIME::Fast		PACKAGE = MIME::Fast::Filter::Enriched	PREFIX=g_mime_filter_enriched_

MIME::Fast::Filter::Enriched
g_mime_filter_enriched_new(Class, flags)
	const char *		Class
	guint32			flags
    CODE:
	RETVAL = GMIME_FILTER_ENRICHED(g_mime_filter_enriched_new(flags));
	plist = g_list_prepend (plist, RETVAL);
    OUTPUT:
	RETVAL

