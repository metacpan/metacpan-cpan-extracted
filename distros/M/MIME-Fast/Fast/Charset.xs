
MODULE = MIME::Fast		PACKAGE = MIME::Fast			PREFIX=g_mime_

const char *
g_mime_locale_charset()

const char *
g_mime_locale_language()

MODULE = MIME::Fast		PACKAGE = MIME::Fast::Charset		PREFIX=g_mime_charset_

void
g_mime_charset_init(mime_charset)
    MIME::Fast::Charset mime_charset

 # needed only for non iso8859-1 locales
void
g_mime_charset_map_init()

const char *
g_mime_charset_language(charset)
	const char *	charset
	
const char *
g_mime_charset_best_name(mime_charset)
	MIME::Fast::Charset mime_charset

const char *
g_mime_charset_best(svtext)
        SV *	svtext
    PREINIT:
	char *	data;
	STRLEN	len;
    CODE:
        data = (char *)SvPV(svtext, len);
	RETVAL = g_mime_charset_best(data, len);
    OUTPUT:
	RETVAL


