
MODULE = MIME::Fast		PACKAGE = MIME::Fast::MessageDelivery	PREFIX=g_mime_message_delivery_

MIME::Fast::MessageDelivery
g_mime_message_part_new(Class)
        char *			Class
    CODE:
    	RETVAL = g_mime_message_delivery_new();
        plist = g_list_prepend(plist, RETVAL);
    OUTPUT:
        RETVAL

# destroy(delivery)
void
DESTROY(delivery)
        MIME::Fast::MessageDelivery	delivery
    CODE:
        if (gmime_debug)
          warn("g_mime_message_delivery_DESTROY: 0x%x %s", delivery,
          g_list_find(plist,delivery) ? "(true destroy)" : "(only attempt)");
        if (g_list_find(plist,delivery)) {
          g_mime_object_unref (GMIME_OBJECT (delivery));
          plist = g_list_remove(plist, delivery);
	}

void
g_mime_message_delivery_set_per_message(delivery, svmixed)
        MIME::Fast::MessageDelivery	delivery
	SV *				svmixed
    PREINIT:
	SV *			svvalue;
	svtype			svvaltype;
	GMimeHeader		*header;
    CODE:
	svvalue = svmixed;
	if (SvROK(svmixed)) {
	  svvalue = SvRV(svmixed);
	}
	svvaltype = SvTYPE(svvalue);
	if (svvaltype == SVt_PVHV) {
	  HV *		hvarray;
	  I32		keylen;
	  SV *	svtmp, *svval;
	  IV tmp;
	  char *key;

	  hvarray = (HV *)svvalue;
	  header = g_mime_header_new();
	  while ((svval = hv_iternextsv(hvarray, &key, &keylen)) != NULL)
	  {
		  g_mime_header_add(header, key, (const char *)SvPV_nolen(svval));
	  }
	  g_mime_message_delivery_set_per_message(delivery, header);
	} else {
        	croak("Usage: MIME::Fast::MessageDelivery::add_per_rcpt(\%array_of_headers)");
		XSRETURN_UNDEF;
	}




SV *
g_mime_message_delivery_get_per_message(delivery)
        MIME::Fast::MessageDelivery	delivery
    PREINIT:
	GMimeHeader *		header;
	struct raw_header *	h;
	HV *			rh;
    CODE:
	header = g_mime_message_delivery_get_per_message(delivery);
	if (!header) {
		XSRETURN_UNDEF;
	}
	rh = (HV *)sv_2mortal((SV *)newHV());
	h = header->headers;
	while (h && h->name) {
		hv_store(rh, h->name, 0, newSVpv(h->value, 0), 0);
		h = h->next;
	}
	g_mime_header_destroy(header);
	RETVAL = newRV((SV *)rh);
    OUTPUT:
	RETVAL


void
g_mime_message_delivery_remove_per_message(delivery)
        MIME::Fast::MessageDelivery	delivery


void
g_mime_message_delivery_add_per_recipient(delivery, svmixed = 0)
    CASE: items == 1
        MIME::Fast::MessageDelivery	delivery
    CODE:
	g_mime_message_delivery_add_per_recipient(delivery, NULL);
    CASE: items == 2
        MIME::Fast::MessageDelivery	delivery
	SV *				svmixed
    PREINIT:
	SV *			svvalue;
	svtype			svvaltype;
	GMimeHeader		*header;
    CODE:
	svvalue = svmixed;
	if (SvROK(svmixed)) {
	  svvalue = SvRV(svmixed);
	}
	svvaltype = SvTYPE(svvalue);
	if (svvaltype == SVt_PVHV) {
	  HV *		hvarray;
	  I32		keylen;
	  SV *	svtmp, *svval;
	  IV tmp;
	  char *key;

	  hvarray = (HV *)svvalue;
	  header = g_mime_header_new();
	  while ((svval = hv_iternextsv(hvarray, &key, &keylen)) != NULL)
	  {
		  g_mime_header_add(header, key, (const char *)SvPV_nolen(svval));
	  }
	  g_mime_message_delivery_add_per_recipient(delivery, header);
	} else {
        	croak("Usage: MIME::Fast::MessageDelivery::add_per_rcpt(\%array_of_headers)");
		XSRETURN_UNDEF;
	}

SV *
g_mime_message_delivery_get_per_recipient(delivery, rcpt_index)
        MIME::Fast::MessageDelivery	delivery
	int				rcpt_index
    PREINIT:
	GMimeHeader *		header;
	struct raw_header *	h;
	HV *			rh;
    CODE:
	header = g_mime_message_delivery_get_per_recipient(delivery, rcpt_index);
	if (!header) {
		XSRETURN_UNDEF;
	}
	rh = (HV *)sv_2mortal((SV *)newHV());
	h = header->headers;
	while (h && h->name) {
		hv_store(rh, h->name, 0, newSVpv(h->value, 0), 0);
		h = h->next;
	}
	g_mime_header_destroy(header);
	RETVAL = newRV((SV *)rh);
    OUTPUT:
	RETVAL


void
g_mime_message_delivery_remove_per_recipient(delivery, rcpt_index)
        MIME::Fast::MessageDelivery	delivery
	int				rcpt_index


const char *
g_mime_message_delivery_get_original_envelope_id(delivery)
        MIME::Fast::MessageDelivery	delivery


void
g_mime_message_delivery_set_original_envelope_id(delivery, value)
        MIME::Fast::MessageDelivery	delivery
	const char *			value

const char *
g_mime_message_delivery_get_reporting_mta(delivery)
        MIME::Fast::MessageDelivery	delivery

void
g_mime_message_delivery_set_reporting_mta(delivery, value)
        MIME::Fast::MessageDelivery	delivery
	const char *			value

const char *
g_mime_message_delivery_get_dsn_gateway(delivery)
        MIME::Fast::MessageDelivery	delivery

void
g_mime_message_delivery_set_dsn_gateway(delivery, value)
        MIME::Fast::MessageDelivery	delivery
	const char *			value

const char *
g_mime_message_delivery_get_received_from_mta(delivery)
        MIME::Fast::MessageDelivery	delivery

void
g_mime_message_delivery_set_received_from_mta(delivery, value)
        MIME::Fast::MessageDelivery	delivery
	const char *			value

void
g_mime_message_delivery_set_arrival_date_string(delivery, value)
        MIME::Fast::MessageDelivery	delivery
	const char *			value

 #
 # returns scalar string or array (date, gmt_offset)
 #
void
g_mime_message_delivery_get_arrival_date(delivery)
        MIME::Fast::MessageDelivery	delivery
    PREINIT:
        time_t		date;
        int		gmt_offset;
        I32		gimme = GIMME_V;
	char *		str;
    PPCODE:
        if (gimme == G_SCALAR) {
          str = g_mime_message_delivery_get_arrival_date_string(delivery);
	  if (str) {
            XPUSHs(sv_2mortal(newSVpv(str,0)));
	    g_free (str);
	  }
        } else if (gimme == G_ARRAY) {
          g_mime_message_delivery_get_arrival_date(delivery, &date, &gmt_offset);
          XPUSHs(sv_2mortal(newSVnv(date)));
          XPUSHs(sv_2mortal(newSViv(gmt_offset)));
        }

void
g_mime_message_delivery_set_arrival_date(delivery, date, gmt_offset)
        MIME::Fast::MessageDelivery	delivery
        time_t		date
        int		gmt_offset

const char *
g_mime_message_delivery_get_msg_header(delivery, name)
        MIME::Fast::MessageDelivery	delivery
	const char *			name

void
g_mime_message_delivery_set_msg_header(delivery, name, value)
        MIME::Fast::MessageDelivery	delivery
	const char *			name
	const char *			value

void
g_mime_message_delivery_remove_msg_header(delivery, name)
        MIME::Fast::MessageDelivery	delivery
	const char *			name

int
g_mime_message_delivery_get_rcpt_length(delivery)
        MIME::Fast::MessageDelivery	delivery

const char *
g_mime_message_delivery_get_rcpt_original_recipient(delivery, rcpt_index)
        MIME::Fast::MessageDelivery	delivery
	int				rcpt_index

void
g_mime_message_delivery_set_rcpt_original_recipient(delivery, rcpt_index, value)
        MIME::Fast::MessageDelivery	delivery
	int				rcpt_index
	const char *			value

const char *
g_mime_message_delivery_get_rcpt_final_recipient(delivery, rcpt_index)
        MIME::Fast::MessageDelivery	delivery
	int				rcpt_index

void
g_mime_message_delivery_set_rcpt_final_recipient(delivery, rcpt_index, value)
        MIME::Fast::MessageDelivery	delivery
	int				rcpt_index
	const char *			value

const char *
g_mime_message_delivery_get_rcpt_action(delivery, rcpt_index)
        MIME::Fast::MessageDelivery	delivery
	int				rcpt_index

void
g_mime_message_delivery_set_rcpt_action(delivery, rcpt_index, value)
        MIME::Fast::MessageDelivery	delivery
	int				rcpt_index
	const char *			value

SV *
g_mime_message_delivery_get_rcpt_status(delivery, rcpt_index)
        MIME::Fast::MessageDelivery	delivery
	int				rcpt_index
    PREINIT:
	char *	textdata;
    CODE:
	textdata = g_mime_message_delivery_get_rcpt_status(delivery, rcpt_index);
	if (textdata) {
	  RETVAL = newSVpv(textdata, 0);
	  g_free (textdata);
	} else {
	  XSRETURN_UNDEF;
	}
    OUTPUT:
	RETVAL


void
g_mime_message_delivery_set_rcpt_status(delivery, rcpt_index, value)
        MIME::Fast::MessageDelivery	delivery
	int				rcpt_index
	const char *			value

const char *
g_mime_message_delivery_get_rcpt_remote_mta(delivery, rcpt_index)
        MIME::Fast::MessageDelivery	delivery
	int				rcpt_index

void
g_mime_message_delivery_set_rcpt_remote_mta(delivery, rcpt_index, value)
        MIME::Fast::MessageDelivery	delivery
	int				rcpt_index
	const char *			value

const char *
g_mime_message_delivery_get_rcpt_diagnostic_code(delivery, rcpt_index)
        MIME::Fast::MessageDelivery	delivery
	int				rcpt_index


void
g_mime_message_delivery_set_rcpt_diagnostic_code(delivery, rcpt_index, value)
        MIME::Fast::MessageDelivery	delivery
	int				rcpt_index
	const char *			value


 #
 # returns scalar string or array (date, gmt_offset)
 #
void
g_mime_message_delivery_get_rcpt_last_attempt_date(delivery, rcpt_index)
        MIME::Fast::MessageDelivery	delivery
	int				rcpt_index
    PREINIT:
        time_t		date;
        int		gmt_offset;
        I32		gimme = GIMME_V;
	char *		str;
    PPCODE:
        if (gimme == G_SCALAR) {
          str = g_mime_message_delivery_get_rcpt_last_attempt_date_string(delivery, rcpt_index);
	  if (str) {
            XPUSHs(sv_2mortal(newSVpv(str,0)));
	    g_free (str);
	  }
        } else if (gimme == G_ARRAY) {
          g_mime_message_delivery_get_rcpt_last_attempt_date(delivery, rcpt_index, &date, &gmt_offset);
          XPUSHs(sv_2mortal(newSVnv(date)));
          XPUSHs(sv_2mortal(newSViv(gmt_offset)));
        }


void
g_mime_message_delivery_set_rcpt_last_attempt_date_string(delivery, rcpt_index, value)
        MIME::Fast::MessageDelivery	delivery
	int				rcpt_index
	const char *			value

void
g_mime_message_delivery_set_rcpt_last_attempt_date(delivery, rcpt_index, date, gmt_offset)
        MIME::Fast::MessageDelivery	delivery
	int				rcpt_index
	time_t				date
	int				gmt_offset


void
g_mime_message_delivery_set_rcpt_will_retry_until_string(delivery, rcpt_index, value)
        MIME::Fast::MessageDelivery	delivery
	int				rcpt_index
	const char *			value


 #
 # returns scalar string or array (date, gmt_offset)
 #
void
g_mime_message_delivery_get_rcpt_will_retry_until(delivery, rcpt_index)
        MIME::Fast::MessageDelivery	delivery
	int				rcpt_index
    PREINIT:
        time_t		date;
        int		gmt_offset;
        I32		gimme = GIMME_V;
	char *		str;
    PPCODE:
        if (gimme == G_SCALAR) {
          str = g_mime_message_delivery_get_rcpt_will_retry_until_string(delivery, rcpt_index);
	  if (str) {
            XPUSHs(sv_2mortal(newSVpv(str,0)));
	    g_free (str);
	  }
        } else if (gimme == G_ARRAY) {
          g_mime_message_delivery_get_rcpt_will_retry_until(delivery, rcpt_index, &date, &gmt_offset);
          XPUSHs(sv_2mortal(newSVnv(date)));
          XPUSHs(sv_2mortal(newSViv(gmt_offset)));
        }




void
g_mime_message_delivery_set_rcpt_will_retry_until(delivery, rcpt_index, date, gmt_offset)
        MIME::Fast::MessageDelivery	delivery
	int				rcpt_index
	time_t				date
	int				gmt_offset


const char *
g_mime_message_delivery_get_rcpt_header(delivery, rcpt_index, name)
        MIME::Fast::MessageDelivery	delivery
	int				rcpt_index
	const char *			name


void
g_mime_message_delivery_set_rcpt_header(delivery, rcpt_index, name, value)
        MIME::Fast::MessageDelivery	delivery
	int				rcpt_index
	const char *			name
	const char *			value


void
g_mime_message_delivery_remove_rcpt_header(delivery, rcpt_index, name)
        MIME::Fast::MessageDelivery	delivery
	int				rcpt_index
	const char *			name



void
g_mime_message_delivery_status_to_string(status)
	const char *			status
    PREINIT:
	const char *	class_code;
	const char *	class_detail;
    PPCODE:
	class_detail = g_mime_message_delivery_status_to_string(status, &class_code);
	XPUSHs(sv_2mortal(newSVpv(class_code, 0)));
	XPUSHs(sv_2mortal(newSVpv(class_detail, 0)));


