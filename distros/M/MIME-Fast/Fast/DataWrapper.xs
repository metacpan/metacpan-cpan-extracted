
MODULE = MIME::Fast		PACKAGE = MIME::Fast::DataWrapper	PREFIX=g_mime_data_wrapper_

MIME::Fast::DataWrapper
g_mime_data_wrapper_new(Class, mime_stream = 0, encoding = 0)
    CASE: items <= 1
    CODE:
    	RETVAL = g_mime_data_wrapper_new();
        plist = g_list_prepend(plist, RETVAL);
    OUTPUT:
    	RETVAL

    CASE: items == 3
        const char *		Class
        MIME::Fast::Stream	mime_stream
        MIME::Fast::PartEncodingType		encoding
    CODE:
    	RETVAL = g_mime_data_wrapper_new_with_stream(mime_stream, encoding);
        plist = g_list_prepend(plist, RETVAL);
    OUTPUT:
    	RETVAL

void
g_mime_data_wrapper_set_stream(mime_data_wrapper, mime_stream)
        MIME::Fast::DataWrapper	mime_data_wrapper
        MIME::Fast::Stream	mime_stream

MIME::Fast::Stream
g_mime_data_wrapper_get_stream(mime_data_wrapper)
        MIME::Fast::DataWrapper	mime_data_wrapper
    CODE:
        RETVAL = g_mime_data_wrapper_get_stream(mime_data_wrapper);
        if (RETVAL)
          plist = g_list_prepend(plist, RETVAL);

void
g_mime_data_wrapper_set_encoding(mime_data_wrapper, encoding)
        MIME::Fast::DataWrapper		mime_data_wrapper
        MIME::Fast::PartEncodingType	encoding

MIME::Fast::PartEncodingType
g_mime_data_wrapper_get_encoding(mime_data_wrapper)
        MIME::Fast::DataWrapper		mime_data_wrapper


