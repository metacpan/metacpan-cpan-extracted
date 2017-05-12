
MODULE = MIME::Fast		PACKAGE = MIME::Fast::MessagePart	PREFIX=g_mime_message_part_

 # new(subtype)
 # new(subtype, message)
MIME::Fast::MessagePart
g_mime_message_part_new(Class, subtype = "rfc822", message = NULL)
    CASE: items <= 1
    CODE:
    	RETVAL = g_mime_message_part_new(NULL);
        plist = g_list_prepend(plist, RETVAL);
    CASE: items == 2
        char *			Class
        char *			subtype
    CODE:
    	RETVAL = g_mime_message_part_new(subtype);
        plist = g_list_prepend(plist, RETVAL);
    CASE: items == 3
        char *			Class
        char *			subtype
	MIME::Fast::Message	message
    CODE:
        RETVAL = g_mime_message_part_new_with_message(subtype, message);
        plist = g_list_prepend(plist, RETVAL);
    OUTPUT:
        RETVAL

# destroy(messagepart)
void
DESTROY(messagepart)
        MIME::Fast::MessagePart	messagepart
    CODE:
        if (gmime_debug)
          warn("g_mime_message_part_DESTROY: 0x%x %s", messagepart,
          g_list_find(plist,messagepart) ? "(true destroy)" : "(only attempt)");
        if (g_list_find(plist,messagepart)) {
          g_mime_object_unref (GMIME_OBJECT (messagepart));
          plist = g_list_remove(plist, messagepart);
	}

# sender
void
g_mime_message_part_set_message(messagepart, message)
        MIME::Fast::MessagePart	messagepart
        MIME::Fast::Message	message

MIME::Fast::Message
g_mime_message_part_get_message(messagepart)
        MIME::Fast::MessagePart	messagepart
    CODE:
	RETVAL = g_mime_message_part_get_message(messagepart);
	if (gmime_debug)
          warn("g_mime_message_part_get_message: 0x%x\n", RETVAL);
        plist = g_list_prepend(plist, RETVAL);
	g_mime_object_ref(GMIME_OBJECT(RETVAL));
    OUTPUT:
	RETVAL


