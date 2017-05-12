
MODULE = MIME::Fast		PACKAGE = MIME::Fast::StreamFilter	PREFIX=g_mime_stream_filter_

MIME::Fast::StreamFilter
g_mime_stream_filter_new(Class, mime_stream)
	const char *			Class
	MIME::Fast::Stream		mime_stream
    CODE:
	RETVAL = GMIME_STREAM_FILTER(g_mime_stream_filter_new_with_stream (mime_stream));
	plist = g_list_prepend(plist, RETVAL);
    OUTPUT:
	RETVAL

int
g_mime_stream_filter_add(mime_streamfilter, mime_filter)
	MIME::Fast::StreamFilter	mime_streamfilter
	MIME::Fast::Filter		mime_filter

void
g_mime_stream_filter_remove(mime_streamfilter, filter_num)
	MIME::Fast::StreamFilter	mime_streamfilter
	int				filter_num

