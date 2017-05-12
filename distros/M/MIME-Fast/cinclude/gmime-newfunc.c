
/*
 * Returns content length of the given mime part and its descendants
 */
static guint
get_content_length(GMimeObject *mime_object, int method)
{
        guint			lsize = 0;
	GMimePart *		mime_part;
	GMimeMultipart *	mime_multipart;

        if (mime_object) {
		if (GMIME_IS_MULTIPART(mime_object)) {
		    mime_multipart = GMIME_MULTIPART(mime_object);
        	    if ((method & GMIME_LENGTH_CUMULATIVE)) {
        		GList *child = GMIME_MULTIPART (mime_multipart)->subparts;
        		while (child) {
        			lsize += get_content_length ( GMIME_OBJECT(child->data), method );
        			child = child->next;
        		}
        	    }
		} else if (GMIME_IS_PART(mime_object)) { // also MESSAGE_PARTIAL
		    mime_part = GMIME_PART(mime_object);
        	    lsize = (mime_part->content && mime_part->content->stream) ?
        	      g_mime_stream_length(mime_part->content->stream) : 0; 
        	    if ((method & GMIME_LENGTH_ENCODED) && lsize) {
        		GMimePartEncodingType	enc;

        		enc = g_mime_part_get_encoding(mime_part);
        		switch (enc) {
        		  case GMIME_PART_ENCODING_BASE64:
        		    lsize = BASE64_ENCODE_LEN(lsize);
        		    break;
        		  case GMIME_PART_ENCODING_QUOTEDPRINTABLE:
        		    lsize = QP_ENCODE_LEN(lsize);
        		    break;
        		}
        	    }
		} else if (GMIME_IS_MESSAGE_PART(mime_object)) {
		    lsize += get_content_length(GMIME_OBJECT((g_mime_message_part_get_message(GMIME_MESSAGE_PART(mime_object)))), method);
		} else if (GMIME_IS_MESSAGE(mime_object)) {
		    if (GMIME_MESSAGE(mime_object)->mime_part != NULL)
        	        lsize += get_content_length ( GMIME_OBJECT(GMIME_MESSAGE(mime_object)->mime_part), method );
		}
        }
        return lsize;
}

