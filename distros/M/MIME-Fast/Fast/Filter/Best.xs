
MODULE = MIME::Fast		PACKAGE = MIME::Fast::Filter::Best	PREFIX=g_mime_filter_best_

MIME::Fast::Filter::Best
g_mime_filter_best_new(Class, flags)
	const char *		Class
	unsigned int		flags
    CODE:
	RETVAL = GMIME_FILTER_BEST(g_mime_filter_best_new (flags));
	plist = g_list_prepend (plist, RETVAL);
    OUTPUT:
	RETVAL

const char *
g_mime_filter_best_charset(mime_filter_best)
	MIME::Fast::Filter::Best	mime_filter_best

MIME::Fast::PartEncodingType
g_mime_filter_best_encoding(mime_filter_best, required)
	MIME::Fast::Filter::Best	mime_filter_best
	MIME::Fast::BestEncoding	required

