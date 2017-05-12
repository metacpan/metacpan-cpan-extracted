
MODULE = MIME::Fast		PACKAGE = MIME::Fast::Filter::Basic	PREFIX=g_mime_filter_basic_

MIME::Fast::Filter::Basic
g_mime_filter_basic_new(Class, type)
	const char *			Class
        int			type
    CODE:
	RETVAL = GMIME_FILTER_BASIC(g_mime_filter_basic_new_type (type));
	plist = g_list_prepend (plist, RETVAL);
    OUTPUT:
	RETVAL

