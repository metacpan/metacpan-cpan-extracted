
MODULE = MIME::Fast		PACKAGE = MIME::Fast::Filter::Windows	PREFIX=g_mime_filter_windows_

MIME::Fast::Filter::Windows
g_mime_filter_windows_new(Class, claimed_charset)
	const char *		Class
	const char *		claimed_charset
    CODE:
	RETVAL = GMIME_FILTER_WINDOWS(g_mime_filter_windows_new(claimed_charset));
	plist = g_list_prepend (plist, RETVAL);
    OUTPUT:
	RETVAL

gboolean
g_mime_filter_windows_is_windows_charset(mime_filter_windows)
	MIME::Fast::Filter::Windows	mime_filter_windows

const char *
g_mime_filter_windows_real_charset(mime_filter_windows)
	MIME::Fast::Filter::Windows	mime_filter_windows

