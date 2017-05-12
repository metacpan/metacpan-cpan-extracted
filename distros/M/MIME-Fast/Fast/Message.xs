
MODULE = MIME::Fast		PACKAGE = MIME::Fast::Message	PREFIX=g_mime_message_

# new(pretty_headers)
MIME::Fast::Message
g_mime_message_new(Class, pretty_headers = FALSE)
        char *		Class
        gboolean	pretty_headers
    CODE:
        RETVAL = g_mime_message_new(pretty_headers);
	if (gmime_debug)
          warn("g_mime_message_NEW: 0x%x\n", RETVAL);
        plist = g_list_prepend(plist, RETVAL);
    OUTPUT:
        RETVAL

# destroy(message)
void
DESTROY(message)
        MIME::Fast::Message	message
    CODE:
        if (gmime_debug)
          warn("g_mime_message_DESTROY: 0x%x %s", message,
            g_list_find(plist,message) ? "(true destroy)" : "(only attempt)");
        if (g_list_find(plist,message)) {
          g_mime_object_unref (GMIME_OBJECT (message));
          plist = g_list_remove(plist, message);
	}

# recipient
void
g_mime_message_add_recipient(message, type, name, address)
        MIME::Fast::Message	message
        char *		type
        const char *	name
        const char *	address

void
g_mime_message_add_recipients_from_string(message, type, recipients)
 	MIME::Fast::Message	message
        char *		type
        const char *	recipients

AV *
g_mime_message_get_recipients(message, type)
        MIME::Fast::Message	message
        const char *	type
    PREINIT:
        InternetAddressList *		rcpt;
        AV * 		retav;
    CODE:
        retav = newAV();
        rcpt = g_mime_message_get_recipients(message, type);
        while (rcpt) {
          SV * address = newSViv(0);
          sv_setref_pv(address, "MIME::Fast::InternetAddress", (MIME__Fast__InternetAddress)(rcpt->address));
          av_push(retav, address);
          rcpt = rcpt->next;
        }
        RETVAL = retav;
    OUTPUT:
        RETVAL


void
interface_m_set(message, value)
        MIME::Fast::Message	message
	char *			value
    INTERFACE_MACRO:
	XSINTERFACE_FUNC
	XSINTERFACE_FUNC_MIMEFAST_MESSAGE_SET
    INTERFACE:
	set_subject
	set_message_id
	set_reply_to
	set_sender

const char *
interface_m_get(message)
        MIME::Fast::Message	message
    INTERFACE_MACRO:
	XSINTERFACE_FUNC
	XSINTERFACE_FUNC_MIMEFAST_MESSAGE_SET
    INTERFACE:
	get_subject
	get_message_id
	get_reply_to
	get_sender
        
 # date
void
g_mime_message_set_date(message, date, gmt_offset)
        MIME::Fast::Message	message
        time_t		date
        int		gmt_offset

void
g_mime_message_set_date_from_string(message, str)
        MIME::Fast::Message	message
        const char *	str
    PREINIT:
	time_t		date;
	int		offset = 0;
    CODE:
	date = g_mime_utils_header_decode_date (str, &offset);
	g_mime_message_set_date (message, date, offset);


 #
 # returns scalar string or array (date, gmt_offset)
 #
void
g_mime_message_get_date(message)
        MIME::Fast::Message	message
    PREINIT:
        time_t		date;
        int		gmt_offset;
        I32		gimme = GIMME_V;
	char *		str;
    PPCODE:
        if (gimme == G_SCALAR) {
          str = g_mime_message_get_date_string(message);
	  if (str) {
            XPUSHs(sv_2mortal(newSVpv(str,0)));
	    g_free (str);
	  }
        } else if (gimme == G_ARRAY) {
          g_mime_message_get_date(message, &date, &gmt_offset);
          XPUSHs(sv_2mortal(newSVnv(date)));
          XPUSHs(sv_2mortal(newSViv(gmt_offset)));
        }

# the other headers
void
g_mime_message_set_header(message, field, value)
        MIME::Fast::Message	message
        const char *	field
        const char *	value
    CODE:
        g_mime_message_set_header(message, field, value);
        // message_set_header(message, field, value);
    	

void
g_mime_message_remove_header(message, field)
        MIME::Fast::Message	message
        const char *	field
    CODE:
        g_mime_object_remove_header(GMIME_OBJECT (message), field);

 # add arbitrary header
void
g_mime_message_add_header(message, field, value)
        MIME::Fast::Message	message
        const char *	field
        const char *	value

# CODE:
#	message_set_header(message, field, value);

const char *
g_mime_message_get_header(message, field)
        MIME::Fast::Message	message
        const char *	field

# mime_part
void
g_mime_message_set_mime_part(message, mime_part)
        MIME::Fast::Message	message
        MIME::Fast::Object	mime_part
    CODE:
        g_mime_message_set_mime_part(message, GMIME_OBJECT (mime_part));
        plist = g_list_remove(plist, mime_part);

## UTILITY FUNCTIONS

SV *
g_mime_message_get_body(message, want_plain = 1, is_html = 0)
    CASE: items == 1
        MIME::Fast::Message	message
    PREINIT:
        gboolean	want_plain = 1;
        gboolean	is_html;
	char *		textdata;
    CODE:
        textdata = g_mime_message_get_body(message, want_plain, &is_html);
	if (textdata == NULL)
	  XSRETURN_UNDEF;
        RETVAL = newSVpv(textdata, 0);
	g_free (textdata);
    OUTPUT:
        RETVAL
    CASE: items == 2
        MIME::Fast::Message	message
        gboolean	want_plain
    PREINIT:
        gboolean	is_html;
	char *		textdata;
    CODE:
        textdata = g_mime_message_get_body(message, want_plain, &is_html);
	if (textdata == NULL)
	  XSRETURN_UNDEF;
        RETVAL = newSVpv(textdata, 0);
	g_free (textdata);
    OUTPUT:
        RETVAL
    CASE: items == 3
        MIME::Fast::Message	message
        gboolean	want_plain
        gboolean	&is_html
    PREINIT:
	char *		textdata;
    CODE:
        textdata = g_mime_message_get_body(message, want_plain, &is_html);
	if (textdata == NULL)
	  XSRETURN_UNDEF;
        RETVAL = newSVpv(textdata, 0);
	g_free (textdata);
    OUTPUT:
        is_html
        RETVAL
        

SV *
g_mime_message_get_headers(message)
        MIME::Fast::Message	message
    PREINIT:
	char *		textdata;
    CODE:
	textdata = g_mime_message_get_headers(message);
	if (textdata == NULL)
	  XSRETURN_UNDEF;
        RETVAL = newSVpv(textdata, 0);
	g_free (textdata);
    OUTPUT:
        RETVAL

# callback function
void
g_mime_message_foreach_part(message, callback, svdata)
        MIME::Fast::Message	message
        SV *			callback
        SV *			svdata
    PREINIT:
	struct _user_data_sv    *data;

    CODE:
	data = g_new0 (struct _user_data_sv, 1);
	data->svuser_data = newSVsv(svdata);
	data->svfunc = newSVsv(callback);
        g_mime_message_foreach_part(message, call_sub_foreach, data);
	g_free (data);

## "OBJECTS" FUNCTION

 # returns Part or MultiPart
SV *
get_mime_part(message)
        MIME::Fast::Message	message
    PREINIT:
    	GMimeObject *	mime_object;
    CODE:
        if (message->mime_part != NULL) {
	  RETVAL = newSViv(4);
          mime_object = GMIME_OBJECT(message->mime_part);
          if (GMIME_IS_MULTIPART(mime_object))
	    sv_setref_pv(RETVAL, "MIME::Fast::MultiPart", (MIME__Fast__MultiPart)mime_object);
	  else if (GMIME_IS_MESSAGE_PARTIAL(mime_object))
	    sv_setref_pv(RETVAL, "MIME::Fast::MessagePartial", (MIME__Fast__MessagePartial)mime_object);
#if GMIME_CHECK_VERSION_UNSUPPORTED
	  else if (GMIME_IS_MESSAGE_MDN(mime_object))
	    sv_setref_pv(RETVAL, "MIME::Fast::MessageMDN", (MIME__Fast__MessageMDN)mime_object);
	  else if (GMIME_IS_MESSAGE_DELIVERY(mime_object))
	    sv_setref_pv(RETVAL, "MIME::Fast::MessageDelivery", (MIME__Fast__MessageDelivery)mime_object);
#endif
	  else if (GMIME_IS_PART(mime_object))
	    sv_setref_pv(RETVAL, "MIME::Fast::Part", (MIME__Fast__Part)mime_object);
	  else if (GMIME_IS_MESSAGE_PART(mime_object))
	    sv_setref_pv(RETVAL, "MIME::Fast::MessagePart", (MIME__Fast__MessagePart)mime_object);
	  else
	    die("get_mime_part: unknown type of object: 0x%x", mime_object);
          plist = g_list_prepend(plist, RETVAL);
	  g_mime_object_ref( mime_object );
          if (gmime_debug)
            warn("function message->mime_part returns (not in plist): 0x%x", RETVAL);
	} else {
	  RETVAL = &PL_sv_undef;
	}
    OUTPUT:
        RETVAL


