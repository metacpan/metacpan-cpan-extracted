
MODULE = MIME::Fast		PACKAGE = MIME::Fast::MessageMDN	PREFIX=g_mime_message_mdn_

MIME::Fast::MessageMDN
g_mime_message_part_new(Class)
        char *			Class
    CODE:
    	RETVAL = g_mime_message_mdn_new();
        plist = g_list_prepend(plist, RETVAL);
    OUTPUT:
        RETVAL

# destroy(mdn)
void
DESTROY(mdn)
        MIME::Fast::MessageMDN	mdn
    CODE:
        if (gmime_debug)
          warn("g_mime_message_mdn_DESTROY: 0x%x %s", mdn,
          g_list_find(plist,mdn) ? "(true destroy)" : "(only attempt)");
        if (g_list_find(plist,mdn)) {
          g_mime_object_unref (GMIME_OBJECT (mdn));
          plist = g_list_remove(plist, mdn);
	}

void
g_mime_message_mdn_set_mdn_headers(mdn, svmixed)
        MIME::Fast::MessageMDN	mdn
	SV *			svmixed
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
	  g_mime_message_mdn_set_mdn_headers(mdn, header);
	} else {
        	croak("Usage: MIME::Fast::MessageDelivery::set_mdn_headers(\%array_of_headers)");
		XSRETURN_UNDEF;
	}


SV *
g_mime_message_mdn_get_mdn_headers(mdn)
        MIME::Fast::MessageMDN	mdn
    PREINIT:
	GMimeHeader *		header;
	struct raw_header *	h;
	HV *			rh;
    CODE:
	header = g_mime_message_mdn_get_mdn_headers(mdn);
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
g_mime_message_mdn_set_mdn_header(mdn, name, value)
        MIME::Fast::MessageMDN	mdn
	const char *			name
	const char *			value

const char *
g_mime_message_mdn_get_mdn_header(mdn, name)
        MIME::Fast::MessageMDN	mdn
	const char *			name

void
g_mime_message_mdn_remove_mdn_header(mdn, name)
        MIME::Fast::MessageMDN	mdn
	const char *			name


void
g_mime_message_mdn_set_reporting_ua(mdn, value)
        MIME::Fast::MessageMDN	mdn
	const char *			value

const char *
g_mime_message_mdn_get_reporting_ua(mdn)
        MIME::Fast::MessageMDN	mdn


void
g_mime_message_mdn_set_mdn_gateway(mdn, value)
        MIME::Fast::MessageMDN	mdn
	const char *			value

const char *
g_mime_message_mdn_get_mdn_gateway(mdn)
        MIME::Fast::MessageMDN	mdn


void
g_mime_message_mdn_set_original_recipient(mdn, value)
        MIME::Fast::MessageMDN	mdn
	const char *			value

const char *
g_mime_message_mdn_get_original_recipient(mdn)
        MIME::Fast::MessageMDN	mdn


void
g_mime_message_mdn_set_final_recipient(mdn, value)
        MIME::Fast::MessageMDN	mdn
	const char *			value

const char *
g_mime_message_mdn_get_final_recipient(mdn)
        MIME::Fast::MessageMDN	mdn


void
g_mime_message_mdn_set_original_message_id(mdn, value)
        MIME::Fast::MessageMDN	mdn
	const char *			value

const char *
g_mime_message_mdn_get_original_message_id(mdn)
        MIME::Fast::MessageMDN	mdn


void
g_mime_message_mdn_set_disposition(mdn, value)
        MIME::Fast::MessageMDN	mdn
	const char *			value

SV *
g_mime_message_mdn_get_disposition(mdn)
        MIME::Fast::MessageMDN	mdn
    PREINIT:
	char *	textdata;
    CODE:
	textdata = g_mime_message_mdn_get_disposition(mdn);
	if (textdata) {
	  RETVAL = newSVpv(textdata, 0);
	  g_free (textdata);
	} else {
	  XSRETURN_UNDEF;
	}
    OUTPUT:
	RETVAL

# unsupported because const MIME::Fast::MessageMDNDisposition is useless
# g_mime_message_mdn_get_disposition_object(mdn)

void
g_mime_message_mdn_set_disposition_object(mdn, mdn_disposition)
        MIME::Fast::MessageMDN	mdn
	MIME::Fast::MessageMDNDisposition	mdn_disposition
    CODE:
	g_mime_message_mdn_set_disposition_object(mdn, mdn_disposition);
        plist = g_list_remove(plist, mdn_disposition);


void
g_mime_message_mdn_set_failure(mdn, value)
        MIME::Fast::MessageMDN	mdn
	const char *			value

const char *
g_mime_message_mdn_get_failure(mdn)
        MIME::Fast::MessageMDN	mdn


void
g_mime_message_mdn_set_error(mdn, value)
        MIME::Fast::MessageMDN	mdn
	const char *			value

const char *
g_mime_message_mdn_get_error(mdn)
        MIME::Fast::MessageMDN	mdn


void
g_mime_message_mdn_set_warning(mdn, value)
        MIME::Fast::MessageMDN	mdn
	const char *			value

const char *
g_mime_message_mdn_get_warning(mdn)
        MIME::Fast::MessageMDN	mdn


