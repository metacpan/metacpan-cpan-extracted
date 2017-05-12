
MODULE = MIME::Fast		PACKAGE = MIME::Fast::Filter::HTML	PREFIX=g_mime_filter_html_

MIME::Fast::Filter::HTML
g_mime_filter_html_new(Class, flags, colour)
	const char *		Class
	guint32			flags
	guint32			colour
    CODE:
	RETVAL = GMIME_FILTER_HTML(g_mime_filter_html_new(flags, colour));
	plist = g_list_prepend (plist, RETVAL);
    OUTPUT:
	RETVAL

