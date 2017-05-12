
MODULE = MIME::Fast		PACKAGE = MIME::Fast::MessageMDNDisposition	PREFIX=g_mime_message_mdn_disposition_

MIME::Fast::MessageMDNDisposition
g_mime_message_mdn_disposition_new(Class, disposition = 0)
    CASE: items == 1
        char *		Class
    CODE:
        RETVAL = g_mime_message_mdn_disposition_new ();
        plist = g_list_prepend(plist, RETVAL);
    OUTPUT:
        RETVAL
    CASE: items == 2
        char *		Class
	const char *	disposition
    CODE:
        RETVAL = g_mime_message_mdn_disposition_new_from_string (disposition);
        plist = g_list_prepend(plist, RETVAL);
    OUTPUT:
        RETVAL

# destroy(mdn_disposition)
void
DESTROY(mdn_disposition)
        MIME::Fast::MessageMDNDisposition	mdn_disposition
    CODE:
        if (gmime_debug)
          warn("g_mime_message_mdn_disposition_DESTROY: 0x%x", mdn_disposition,
	  g_list_find(plist,mdn_disposition) ? "(true destroy)" : "(only attempt)");
	if (g_list_find(plist,mdn_disposition)) {
	  g_mime_message_mdn_disposition_destroy (mdn_disposition);
	  plist = g_list_remove(plist, mdn_disposition);
	}

void
g_mime_message_mdn_disposition_set_action_mode(mdn_disposition, value)
        MIME::Fast::MessageMDNDisposition	mdn_disposition
	const char *		value

const char *
g_mime_message_mdn_disposition_get_action_mode(mdn_disposition)
        MIME::Fast::MessageMDNDisposition	mdn_disposition


void
g_mime_message_mdn_disposition_set_sending_mode(mdn_disposition, value)
        MIME::Fast::MessageMDNDisposition	mdn_disposition
	const char *		value

const char *
g_mime_message_mdn_disposition_get_sending_mode(mdn_disposition)
        MIME::Fast::MessageMDNDisposition	mdn_disposition


void
g_mime_message_mdn_disposition_set_type(mdn_disposition, value)
        MIME::Fast::MessageMDNDisposition	mdn_disposition
	const char *		value

const char *
g_mime_message_mdn_disposition_get_type(mdn_disposition)
        MIME::Fast::MessageMDNDisposition	mdn_disposition


void
g_mime_message_mdn_disposition_set_modifier(mdn_disposition, value)
        MIME::Fast::MessageMDNDisposition	mdn_disposition
	const char *		value

const char *
g_mime_message_mdn_disposition_get_modifier(mdn_disposition)
        MIME::Fast::MessageMDNDisposition	mdn_disposition


SV *
g_mime_message_mdn_disposition_header(mdn_disposition, fold = 0)
        MIME::Fast::MessageMDNDisposition	mdn_disposition
	int			fold
    PREINIT:
	char *	textdata;
    CODE:
	textdata = g_mime_message_mdn_disposition_header(mdn_disposition, fold);
	if (textdata) {
	  RETVAL = newSVpv(textdata, 0);
	  g_free (textdata);
	} else {
	  XSRETURN_UNDEF;
	}
    OUTPUT:
	RETVAL


