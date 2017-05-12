
MODULE = MIME::Fast		PACKAGE = MIME::Fast::Filter::Charset	PREFIX=g_mime_filter_charset_

MIME::Fast::Filter::Charset
g_mime_filter_charset_new(Class, from_charset, to_charset)
	const char *		Class
	const char *		from_charset
	const char *		to_charset
    CODE:
	RETVAL = GMIME_FILTER_CHARSET(g_mime_filter_charset_new (from_charset, to_charset));
	plist = g_list_prepend (plist, RETVAL);
    OUTPUT:
	RETVAL

