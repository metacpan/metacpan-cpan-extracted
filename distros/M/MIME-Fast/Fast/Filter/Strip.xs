
MODULE = MIME::Fast		PACKAGE = MIME::Fast::Filter::Strip	PREFIX=g_mime_filter_strip_

MIME::Fast::Filter::Strip
g_mime_filter_strip_new(Class)
	const char *		Class
    CODE:
	RETVAL = GMIME_FILTER_STRIP(g_mime_filter_strip_new());
	plist = g_list_prepend (plist, RETVAL);
    OUTPUT:
	RETVAL

