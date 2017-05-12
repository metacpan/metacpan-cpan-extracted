
MODULE = MIME::Fast		PACKAGE = MIME::Fast::Filter::From	PREFIX=g_mime_filter_from_

MIME::Fast::Filter::From
g_mime_filter_from_new(Class, mode)
	const char *			Class
        MIME::Fast::FilterFromMode	mode
    CODE:
	RETVAL = GMIME_FILTER_FROM(g_mime_filter_from_new (mode));
	plist = g_list_prepend (plist, RETVAL);
    OUTPUT:
	RETVAL

