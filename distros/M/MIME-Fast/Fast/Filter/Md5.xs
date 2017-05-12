
MODULE = MIME::Fast		PACKAGE = MIME::Fast::Filter::Md5	PREFIX=g_mime_filter_md5_

MIME::Fast::Filter::Md5
g_mime_filter_md5_new(Class)
	const char *		Class
    CODE:
	RETVAL = GMIME_FILTER_MD5(g_mime_filter_md5_new());
	plist = g_list_prepend (plist, RETVAL);
    OUTPUT:
	RETVAL

SV *
g_mime_filter_md5_get_digest(mime_filter_md5)
	MIME::Fast::Filter::Md5	mime_filter_md5
    PREINIT:
	unsigned char md5_digest[16];
    CODE:
	md5_digest[0] = '\0';
	g_mime_filter_md5_get_digest (mime_filter_md5, md5_digest);
	RETVAL = newSVpv(md5_digest, 0);
    OUTPUT:
	RETVAL

