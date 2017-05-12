
MODULE = MIME::Fast		PACKAGE = MIME::Fast::Utils		PREFIX=g_mime_utils_

# date
time_t
g_mime_utils_header_decode_date(in, saveoffset)
        const char *	in
        gint 		&saveoffset
    OUTPUT:
        saveoffset

SV *
g_mime_utils_header_format_date(time, offset)
        time_t		time
        gint		offset
    PREINIT:
        char *		out = NULL;
    CODE:
        out = g_mime_utils_header_format_date(time, offset);
        if (out) {
          RETVAL = newSVpvn(out,0);
          g_free(out);
        } else
          RETVAL = &PL_sv_undef;
    OUTPUT:
        RETVAL


SV *
g_mime_utils_generate_message_id(fqdn)
	const char *	fqdn
    PREINIT:
        char *		out = NULL;
    CODE:
	out = g_mime_utils_generate_message_id(fqdn);
	if (!out)
	  XSRETURN_UNDEF;
	RETVAL = newSVpv(out, 0);
	g_free(out);
    OUTPUT:
        RETVAL


SV *
g_mime_utils_decode_message_id(message_id)
	const char *	message_id
    PREINIT:
        char *		out = NULL;
    CODE:
	out = g_mime_utils_decode_message_id(message_id);
	if (!out)
	  XSRETURN_UNDEF;
	RETVAL = newSVpv(out, 0);
	g_free(out);
    OUTPUT:
        RETVAL

# headers
SV *
g_mime_utils_header_fold(in)
        const char *	in
    PREINIT:
        char *		out = NULL;
    CODE:
        out = g_mime_utils_header_fold(in);
        if (out) {
          RETVAL = newSVpvn(out,0);
          g_free(out);
        } else
          RETVAL = &PL_sv_undef;
    OUTPUT:
        RETVAL
        				    

# not implemented g_mime_utils_header_printf()

# quote
SV *
g_mime_utils_quote_string(in)
        const char *	in
    PREINIT:
        char *		out = NULL;
    CODE:
        out = g_mime_utils_quote_string(in);
	if (gmime_debug)
          warn("In=%s Out=%s\n", in, out);
        if (out) {
          RETVAL = newSVpv(out, 0);
          g_free(out);
        } else
          RETVAL = &PL_sv_undef;
    OUTPUT:
        RETVAL

void
g_mime_utils_unquote_string(str)
        char *		str
    OUTPUT:
        str

# encoding
gboolean
g_mime_utils_text_is_8bit(str)
        SV *		str
    PREINIT:
        char *	data;
        STRLEN	len;
    CODE:
        data = SvPV(str, len);
        RETVAL = g_mime_utils_text_is_8bit(data, len);
    OUTPUT:
        RETVAL

MIME::Fast::PartEncodingType
g_mime_utils_best_encoding(str)
        SV *		str
    PREINIT:
        char *	data;
        STRLEN	len;
    CODE:
        data = SvPV(str, len);
        RETVAL = g_mime_utils_best_encoding(data, len);
    OUTPUT:
        RETVAL

char *
g_mime_utils_header_decode_text(in)
        const unsigned char *	in

char *
g_mime_utils_header_decode_phrase(in)
        const unsigned char *	in

char *
g_mime_utils_header_encode_text(in)
        const unsigned char *	in

char *
g_mime_utils_header_encode_phrase(in)
        const unsigned char *	in

# not implemented - incremental base64:
#	g_mime_utils_base64_decode_step()
#	g_mime_utils_base64_encode_step()
#	g_mime_utils_base64_encode_close()
#gint
#g_mime_utils_base64_decode_step(in, out, state, save)
#	SV *		in
#	unsigned char *	out
#	gint		state
#	gint		&save
#    PREINIT:
#	char *	data;
#	STRLEN	len;
#    CODE:
#	data = SvPV(in, len);
#	RETVAL = g_mime_utils_base64_decode_step(data, len, state, save);
#    OUTPUT:
#	RETVAL
#	save

# not implemented:
# g_mime_utils_uudecode_step
# g_mime_utils_quoted_decode_step
# g_mime_utils_quoted_encode_step
# g_mime_utils_quoted_encode_close


