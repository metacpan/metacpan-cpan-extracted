
MODULE = MIME::Fast		PACKAGE = MIME::Fast::Filter::Yenc	PREFIX=g_mime_filter_yenc_

MIME::Fast::Filter::Yenc
g_mime_filter_yenc_new(Class, direction)
	const char *			Class
	Mime::Fast::FilterYencDirection	direction
    CODE:
	RETVAL = GMIME_FILTER_YENC(g_mime_filter_yenc_new(direction));
	plist = g_list_prepend (plist, RETVAL);
    OUTPUT:
	RETVAL

 # unsupported (yet):
 # g_mime_filter_yenc_get_crc etc.

