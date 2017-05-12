
MODULE = MIME::Fast		PACKAGE = MIME::Fast::Object		PREFIX=g_mime_object_

 # unsupported:
 #  g_mime_object_register_type
 #  g_mime_object_new_type
 #  g_mime_object_ref
 #  g_mime_object_unref

 #
 # content_type
 #
void
g_mime_object_set_content_type(mime_object, content_type)
        MIME::Fast::Object	mime_object
        MIME::Fast::ContentType	content_type
    CODE:
        g_mime_object_set_content_type(mime_object, content_type);
        plist = g_list_remove(plist, content_type);

MIME::Fast::ContentType
g_mime_object_get_content_type(mime_object)
        MIME::Fast::Object	mime_object
    PREINIT:
	char *			textdata;
	const GMimeContentType	*ct;
    CODE:
	ct = g_mime_object_get_content_type(mime_object);
	textdata = g_mime_content_type_to_string(ct);
        RETVAL = g_mime_content_type_new_from_string(textdata);
	plist = g_list_prepend(plist, RETVAL);
	g_free (textdata);
    OUTPUT:
    	RETVAL

 #
 # content_type_parameter
 #
void
g_mime_object_set_content_type_parameter(mime_object, name, value)
        MIME::Fast::Object	mime_object
	const char *		name
	const char *		value

const char *
g_mime_object_get_content_type_parameter(mime_object, name)
        MIME::Fast::Object	mime_object
	const char *		name

 #
 # content_id
 #
void
g_mime_object_set_content_id(mime_object, content_id)
        MIME::Fast::Object	mime_object
	const char *		content_id

const char *
g_mime_object_get_content_id(mime_object)
        MIME::Fast::Object	mime_object

 #
 # header
 #
void
g_mime_object_add_header(mime_object, field, value)
        MIME::Fast::Object	mime_object
        const char *	field
        const char *	value

void
g_mime_object_set_header(mime_object, field, value)
        MIME::Fast::Object	mime_object
        const char *	field
        const char *	value

const char *
g_mime_object_get_header(mime_object, field)
        MIME::Fast::Object	mime_object
        const char *	field

void
g_mime_object_remove_header(mime_object, field)
        MIME::Fast::Object	mime_object
        const char *	field

SV *
g_mime_object_get_headers(mime_object)
        MIME::Fast::Object	mime_object
    PREINIT:
	char *		textdata;
    CODE:
	textdata = g_mime_object_get_headers(mime_object);
	if (textdata == NULL)
	  XSRETURN_UNDEF;
        RETVAL = newSVpv(textdata, 0);
	g_free (textdata);
    OUTPUT:
        RETVAL

ssize_t
g_mime_object_write_to_stream(mime_object, mime_stream)
        MIME::Fast::Object	mime_object
	MIME::Fast::Stream		mime_stream
    CODE:
	RETVAL = g_mime_object_write_to_stream (mime_object, mime_stream);
    OUTPUT:
	RETVAL

SV *
g_mime_object_to_string(mime_object)
        MIME::Fast::Object	mime_object
    PREINIT:
	char *	textdata;
    CODE:
	textdata = g_mime_object_to_string (mime_object);
	if (textdata) {
	  RETVAL = newSVpv(textdata, 0);
	  g_free (textdata);
	} else {
	  XSRETURN_UNDEF;
	}
    OUTPUT:
	RETVAL

 #
 # * NOT IN C gmime: content_length
 #
guint
g_mime_object_get_content_length(mime_object, method = GMIME_LENGTH_CUMULATIVE)
        MIME::Fast::Object	mime_object
        int			method
    CODE:
        RETVAL = get_content_length (mime_object, method);
    OUTPUT:
    	RETVAL


