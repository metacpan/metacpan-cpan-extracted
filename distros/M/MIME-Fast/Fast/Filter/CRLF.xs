
MODULE = MIME::Fast		PACKAGE = MIME::Fast::Filter::CRLF	PREFIX=g_mime_filter_crlf_

MIME::Fast::Filter::CRLF
g_mime_filter_crlf_new(Class, direction, mode)
	const char *		Class
        int			direction
        int			mode
    CODE:
	RETVAL = GMIME_FILTER_CRLF(g_mime_filter_crlf_new (direction, mode));
	plist = g_list_prepend (plist, RETVAL);
    OUTPUT:
	RETVAL

