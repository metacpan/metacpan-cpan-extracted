
MODULE = MIME::Fast		PACKAGE = MIME::Fast::Part		PREFIX=g_mime_part_

 #
 ## CONSTRUCTION/DESCTRUCTION
 #

MIME::Fast::Part
g_mime_part_new(Class = "MIME::Fast::Part", type = "text", subtype = "plain")
        char *		Class;
        const char *		type;
        const char *		subtype;
    PROTOTYPE: $;$$
    CODE:
        RETVAL = g_mime_part_new_with_type(type, subtype);
        plist = g_list_prepend(plist, RETVAL);
        if (gmime_debug)
        warn("function g_mime_part_new (also in plist): 0x%x", RETVAL);
    OUTPUT:
        RETVAL

void
DESTROY(mime_part)
        MIME::Fast::Part	mime_part
    CODE:
        if (gmime_debug)
          warn("g_mime_part_DESTROY: 0x%x %s", mime_part,
          g_list_find(plist,mime_part) ? "(true destroy)" : "(only attempt)");
        if (g_list_find(plist,mime_part)) {
          g_mime_object_unref(GMIME_OBJECT (mime_part));
          plist = g_list_remove(plist, mime_part);
        }

 #
 ## ACCESSOR FUNCTIONS
 #

 ## INTERFACE: keyword does not work with perl v5.6.0
 ## (unknown cv variable during C compilation)
 ## oh... it is working now in 5.8.0

void
interface_p_set(mime_part, value)
	MIME::Fast::Part	mime_part
	char *			    value
    INTERFACE_MACRO:
	XSINTERFACE_FUNC
	XSINTERFACE_FUNC_MIMEFAST_PART_SET
    INTERFACE:
	set_content_description
	set_content_md5
	set_content_location
	set_content_disposition
	set_filename


const char *
interface_p_get(mime_part)
	MIME::Fast::Part	mime_part
    INTERFACE_MACRO:
	XSINTERFACE_FUNC
	XSINTERFACE_FUNC_MIMEFAST_PART_SET
    INTERFACE:
	get_content_description
	get_content_md5
	get_content_location
	get_content_disposition
	get_filename

 #
 # set_content_md5
 #
void
g_mime_part_set_content_md5(mime_part, value = 0)
    CASE: items == 1
	MIME::Fast::Part	mime_part
    CODE:
	g_mime_part_set_content_md5(mime_part, NULL);
    CASE: items == 2
	MIME::Fast::Part	mime_part
	char *			    value
    CODE:
	g_mime_part_set_content_md5(mime_part, value);

 #
 # content_header
 #
void
g_mime_part_set_content_header(mime_part, field, value)
	MIME::Fast::Part	mime_part
        const char *		field
        const char *		value

const char *
g_mime_part_get_content_header(mime_part, field)
	MIME::Fast::Part	mime_part
        const char *		field

 #
 # content_md5
 #

gboolean
g_mime_part_verify_content_md5(mime_part)
        MIME::Fast::Part	mime_part
        
 #
 # content_type
 #
void
g_mime_part_set_content_type(mime_part, content_type)
        MIME::Fast::Part		mime_part
        MIME::Fast::ContentType	content_type
    CODE:
        g_mime_part_set_content_type(mime_part, content_type);
        plist = g_list_remove(plist, content_type);

# looking for g_mime_part_get_content_type(mime_part)? it is in MIME::Fast::Object

 #
 # encoding
 #
void
g_mime_part_set_encoding(mime_part, encoding)
        MIME::Fast::Part			mime_part
        MIME::Fast::PartEncodingType		encoding
    CODE:
        g_mime_part_set_encoding(mime_part, encoding);

MIME::Fast::PartEncodingType
g_mime_part_get_encoding(mime_part)
        MIME::Fast::Part	mime_part
    CODE:
        RETVAL = g_mime_part_get_encoding(mime_part);
    OUTPUT:
    	RETVAL

 #
 # encoding<->string
 #
const char *
g_mime_part_encoding_to_string(encoding)
        MIME::Fast::PartEncodingType		encoding
    CODE:
        RETVAL = g_mime_part_encoding_to_string(encoding);
    OUTPUT:
    	RETVAL

MIME::Fast::PartEncodingType
g_mime_part_encoding_from_string(encoding)
        const char *		encoding
    CODE:
        RETVAL = g_mime_part_encoding_from_string(encoding);
    OUTPUT:
    	RETVAL

 #
 # content_disposition_parameter
 #
void
g_mime_part_add_content_disposition_parameter(mime_part, name, value)
        MIME::Fast::Part	mime_part
        const char *		name
        const char *		value
    CODE:
        g_mime_part_add_content_disposition_parameter(mime_part, name, value);

const char *
g_mime_part_get_content_disposition_parameter(mime_part, name)
        MIME::Fast::Part	mime_part
        const char *		name
    CODE:
        RETVAL = g_mime_part_get_content_disposition_parameter(mime_part, name);
    OUTPUT:
    	RETVAL

void
g_mime_part_set_content_disposition_object(mime_part, mime_disposition)
        MIME::Fast::Part		mime_part
	MIME::Fast::Disposition		mime_disposition

 #
 # content
 #
void
g_mime_part_set_content(mime_part, svmixed)
        MIME::Fast::Part	mime_part
        SV *		        svmixed
    PREINIT:
        char *	data;
        STRLEN	len;
        SV*     svval;
        GMimeStream	        *mime_stream = NULL;
        GMimeDataWrapper	*mime_data_wrapper = NULL;
        svtype	svvaltype;
    CODE:
    	svval = svmixed;
        if (SvROK(svmixed)) {
          if (sv_derived_from(svmixed, "MIME::Fast::DataWrapper")) {
          	IV tmp = SvIV((SV*)SvRV(svmixed));
        	GMimeDataWrapper *mime_data_wrapper;

        	mime_data_wrapper = INT2PTR(MIME__Fast__DataWrapper,tmp);
        	g_mime_part_set_content_object(mime_part, mime_data_wrapper);
            return;
          } else if (sv_derived_from(svmixed, "MIME::Fast::Stream")) {
          	IV tmp = SvIV((SV*)SvRV(svmixed));

        	mime_stream = INT2PTR(MIME__Fast__Stream,tmp);
            mime_data_wrapper = g_mime_data_wrapper_new_with_stream(mime_stream, GMIME_PART_ENCODING_BASE64);
            g_mime_part_set_content_object(mime_part, mime_data_wrapper);
            return;
          }
          svval = SvRV(svmixed);
        }
        svvaltype = SvTYPE(svval);

        if (svvaltype == SVt_PVGV) { // possible FILE * handle
	  PerlIO *pio;
	  FILE *fp;
	  int fd;

	  pio = IoIFP(sv_2io(svval));
	  if (!pio || !(fp = PerlIO_findFILE(pio))) {
	    croak("MIME::Fast::Part::set_content: the argument you gave is not a FILE pointer");
	  }
	    
	  fd = dup(fileno(fp));
	  if (fd == -1)
	    croak("MIME::Fast::Part::set_content: Can not duplicate a FILE pointer");

          // mime_stream = g_mime_stream_file_new(fp);
          mime_stream = g_mime_stream_fs_new(fd);
	  if (!mime_stream) {
	    close(fd);
	    XSRETURN_UNDEF;
          }
	  // g_mime_stream_file_set_owner (mime_stream, FALSE);
          mime_data_wrapper = g_mime_data_wrapper_new_with_stream(mime_stream, GMIME_PART_ENCODING_BASE64);
          g_mime_part_set_content_object(mime_part, mime_data_wrapper);

          g_mime_stream_unref(mime_stream);
	} else if (svvaltype == SVt_PVMG) { // possible STDIN/STDOUT etc.
          int fd0 = (int)SvIV( svval );
	  int fd;

	  if (fd0 < 0 || (fd = dup(fd0)) == -1)
	    croak("MIME::Fast::Part::set_content: Can not duplicate a FILE pointer");

          mime_stream = g_mime_stream_fs_new(fd);
	  if (!mime_stream) {
	    close(fd);
	    XSRETURN_UNDEF;
          }
          mime_data_wrapper = g_mime_data_wrapper_new_with_stream(mime_stream, GMIME_PART_ENCODING_BASE64);
          g_mime_part_set_content_object(mime_part, mime_data_wrapper);

          g_mime_stream_unref(mime_stream);
        } else if (SvPOK(svval)) {
          data = (char *)SvPV(svval, len);
          g_mime_part_set_content(mime_part, data, len);
        } else {
          croak("mime_set_content: Unknown type: %d", (int)svvaltype);
        }
 
 # g_mime_part_set_content_byte_array is not supported

void
g_mime_part_set_pre_encoded_content(mime_part, content, encoding)
        MIME::Fast::Part	mime_part
        SV *		content
        MIME::Fast::PartEncodingType	encoding
    PREINIT:
        char *	data;
        STRLEN	len;
    CODE:
        data = SvPV(content, len);
        g_mime_part_set_pre_encoded_content(mime_part, data, len, encoding);

MIME::Fast::DataWrapper
g_mime_part_get_content_object(mime_part)
        MIME::Fast::Part	mime_part
    CODE:
        RETVAL = g_mime_part_get_content_object(mime_part);
    OUTPUT:
    	RETVAL

 #
 # get_content
 #
SV *
g_mime_part_get_content(mime_part)
        MIME::Fast::Part	mime_part
    PREINIT:
        guint len;
        const char * content_char;
        SV * content;
    CODE:
    /*
        content_char = g_mime_part_get_content(mime_part, &len);
        if (content_char)
          content = newSVpv(content_char, len);
        RETVAL = content;
     */
        ST(0) = &PL_sv_undef;
        if (!(mime_part->content) || !(mime_part->content->stream) ||
             (content_char = g_mime_part_get_content(mime_part, &len)) == NULL)
          return;
        content = sv_newmortal();
        SvUPGRADE(content, SVt_PV);
        SvREADONLY_on(content);
        SvPVX(content) = (char *) (content_char);
        SvCUR_set(content, len);
        SvLEN_set(content, 0);
        SvPOK_only(content);
        ST(0) = content;

