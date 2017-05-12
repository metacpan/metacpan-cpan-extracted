
MODULE = MIME::Fast		PACKAGE = MIME::Fast::Parser		PREFIX=g_mime_parser_

MIME::Fast::Parser
g_mime_parser_new(Class = "MIME::Fast::Parser", svmixed = 0)
    CASE: items == 1
	char *			Class
    CODE:
	RETVAL = g_mime_parser_new();
	if (gmime_debug)
          warn("g_mime_parser_new: 0x%x\n", RETVAL);
	plist = g_list_prepend(plist, RETVAL);
    OUTPUT:
        RETVAL
    CASE: items == 2
	char *			Class
	SV *			svmixed
    PREINIT:
        STRLEN		len;
        char *		data;
        GMimeStream	*mime_stream = NULL;
        GMimeParser	*parser = NULL;
        svtype		svvaltype;
        SV *		svval;
    CODE:
    	svval = svmixed;
        if (SvROK(svmixed)) {
          if (sv_derived_from(svmixed, "MIME::Fast::DataWrapper")) {
          	IV tmp = SvIV((SV*)SvRV(svmixed));
        	GMimeDataWrapper *mime_data_wrapper;

        	mime_data_wrapper = INT2PTR(MIME__Fast__DataWrapper,tmp);
        	mime_stream = g_mime_data_wrapper_get_stream(mime_data_wrapper);
                parser = g_mime_parser_new_with_stream(mime_stream);
                g_mime_stream_unref(mime_stream);
          } else if (sv_derived_from(svmixed, "MIME::Fast::Stream")) {
          	IV tmp = SvIV((SV*)SvRV(svmixed));

        	mime_stream = INT2PTR(MIME__Fast__Stream,tmp);

                parser = g_mime_parser_new_with_stream(mime_stream);
          }
          svval = SvRV(svmixed);
        }
        svvaltype = SvTYPE(svval);

        if (parser == NULL) {
          if (svvaltype == SVt_PVGV) { // possible FILE * handle
#ifdef USE_PERLIO
	    PerlIO *pio;

	    pio = IoIFP(sv_2io(svval));
	    if (!pio) {
	        croak("MIME::Fast::Parser::new: the argument you gave is not a FILE pointer");
	    }
	    mime_stream = g_mime_stream_perlio_new(pio);
	    g_mime_stream_perlio_set_owner(GMIME_STREAM_PERLIO(mime_stream), FALSE);
	    if (!mime_stream) {
	      XSRETURN_UNDEF;
            }
#else
            //FILE *  fp = PerlIO_findFILE(IoIFP(sv_2io(svval)));
	    //int fd = dup(fileno(fp));
	    PerlIO *pio;
	    FILE *fp;
	    int fd0;
	    int fd;

	    pio = IoIFP(sv_2io(svval));
	    if (!pio || !(fp = PerlIO_findFILE(pio)) || ((fd0 = PerlIO_fileno(pio)) < 0)) {
	        croak("MIME::Fast::Parser::new: the argument you gave is not a FILE pointer");
	    }
	    
	    fd = dup(fd0);
	    if (fd == -1)
	        croak("MIME::Fast::Parser::new: Can not duplicate a FILE pointer [from PVGV]");

            // mime_stream = g_mime_stream_file_new(fp);
	    // g_mime_stream_file_set_owner (mime_stream, FALSE);
            mime_stream = g_mime_stream_fs_new(fd);
	    if (!mime_stream) {
	      close(fd);
	      XSRETURN_UNDEF;
            }
#endif
            parser = g_mime_parser_new_with_stream(mime_stream);
            g_mime_stream_unref(mime_stream);
	  } else if (svvaltype == SVt_PVMG) { // possible STDIN/STDOUT etc.
            int fd0 = (int)SvIV( svval );
	    int fd;

	    if (fd0 < 0 || (fd = dup(fd0)) == -1)
	      croak("MIME::Fast::Parser::new: Can not duplicate a file descriptor [from PVMG]");
            mime_stream = g_mime_stream_fs_new(fd);
	    if (!mime_stream) {
	      close(fd);
	      XSRETURN_UNDEF;
            }
            parser = g_mime_parser_new_with_stream(mime_stream);
            g_mime_stream_unref(mime_stream);
          } else if (SvPOK(svval)) {
            data = (char *)SvPV(svval, len);
            mime_stream = g_mime_stream_mem_new_with_buffer(data,len);
            parser = g_mime_parser_new_with_stream(mime_stream);
            g_mime_stream_unref(mime_stream);
          } else {
            croak("MIME::Fast::Parser::new: Unknown type: %d", (int)svvaltype);
          }
        }
    	
        RETVAL = parser;
	if (gmime_debug)
          warn("g_mime_parser_new: 0x%x\n", RETVAL);
        plist = g_list_prepend(plist, RETVAL);
    OUTPUT:
        RETVAL


 # destroy(mime_parser)
void
DESTROY(mime_parser)
        MIME::Fast::Parser	mime_parser
    CODE:
        if (gmime_debug)
          warn("g_mime_parser_DESTROY: 0x%x %s", mime_parser,
	  g_list_find(plist,mime_parser) ? "(true destroy)" : "(only attempt)");
	if (g_list_find(plist,mime_parser)) {
	  g_object_unref (mime_parser);
	  plist = g_list_remove(plist, mime_parser);
	}


MIME::Fast::Message
g_mime_parser_construct_message(svmixed)
        SV *		svmixed
    PREINIT:
        STRLEN		len;
        char *		data;
        GMimeMessage	*mime_msg = NULL;
        GMimeStream	*mime_stream = NULL;
        GMimeParser *parser = NULL;
        svtype		svvaltype;
        SV *		svval;
    CODE:
    	svval = svmixed;
        if (SvROK(svmixed)) {
          if (sv_derived_from(svmixed, "MIME::Fast::DataWrapper")) {
          	IV tmp = SvIV((SV*)SvRV(svmixed));
        	GMimeDataWrapper *mime_data_wrapper;

        	mime_data_wrapper = INT2PTR(MIME__Fast__DataWrapper,tmp);
        	mime_stream = g_mime_data_wrapper_get_stream(mime_data_wrapper);
                parser = g_mime_parser_new_with_stream(mime_stream);
          	mime_msg = g_mime_parser_construct_message(parser);
                g_mime_stream_unref(mime_stream);
		g_object_unref (parser);
          } else if (sv_derived_from(svmixed, "MIME::Fast::Stream")) {
          	IV tmp = SvIV((SV*)SvRV(svmixed));

        	mime_stream = INT2PTR(MIME__Fast__Stream,tmp);

                parser = g_mime_parser_new_with_stream(mime_stream);
          	mime_msg = g_mime_parser_construct_message(parser);
		g_object_unref (parser);
          } else if (sv_derived_from(svmixed, "MIME::Fast::Parser")) {
          	IV tmp = SvIV((SV*)SvRV(svmixed));

        	parser = INT2PTR(MIME__Fast__Parser,tmp);
          	mime_msg = g_mime_parser_construct_message(parser);
          }
          svval = SvRV(svmixed);
        }
        svvaltype = SvTYPE(svval);

        if (mime_msg == NULL) {
          if (svvaltype == SVt_PVGV) { // possible FILE * handle
#ifdef USE_PERLIO
	    PerlIO *pio;

	    pio = IoIFP(sv_2io(svval));
	    if (!pio) {
	        croak("MIME::Fast::Parser::construct_message: the argument you gave is not a FILE pointer");
	    }
	    mime_stream = g_mime_stream_perlio_new(pio);
	    g_mime_stream_perlio_set_owner(GMIME_STREAM_PERLIO(mime_stream), FALSE);
	    if (!mime_stream) {
	      XSRETURN_UNDEF;
            }
#else
            //FILE *  fp = PerlIO_findFILE(IoIFP(sv_2io(svval)));
	    //int fd = dup(fileno(fp));
	    PerlIO *pio;
	    FILE *fp;
	    int fd0;
	    int fd;

	    pio = IoIFP(sv_2io(svval));
	    if (!pio || !(fp = PerlIO_findFILE(pio)) || ((fd0 = PerlIO_fileno(pio)) < 0)) {
	        croak("MIME::Fast::Parser::construct_message: the argument you gave is not a FILE pointer");
	    }
	    
	    fd = dup(fd0);
	    if (fd == -1)
	        croak("MIME::Fast::Parser::construct_message: Can not duplicate a FILE pointer [from PVGV]");

            // mime_stream = g_mime_stream_file_new(fp);
	    // g_mime_stream_file_set_owner (mime_stream, FALSE);
            mime_stream = g_mime_stream_fs_new(fd);
	    if (!mime_stream) {
	      close(fd);
	      XSRETURN_UNDEF;
            }
#endif
            parser = g_mime_parser_new_with_stream(mime_stream);
            mime_msg = g_mime_parser_construct_message(parser);
            g_mime_stream_unref(mime_stream);
	    g_object_unref (parser);
	  } else if (svvaltype == SVt_PVMG) { // possible STDIN/STDOUT etc.
            int fd0 = (int)SvIV( svval );
	    int fd;

	    if (fd0 < 0 || (fd = dup(fd0)) == -1)
	      croak("MIME::Fast::Parser::construct_message: Can not duplicate a file descriptor [from PVMG]");
            mime_stream = g_mime_stream_fs_new(fd);
	    if (!mime_stream) {
	      close(fd);
	      XSRETURN_UNDEF;
            }
            parser = g_mime_parser_new_with_stream(mime_stream);
            mime_msg = g_mime_parser_construct_message(parser);
            g_mime_stream_unref(mime_stream);
	    g_object_unref (parser);
          } else if (SvPOK(svval)) {
            data = (char *)SvPV(svval, len);
            mime_stream = g_mime_stream_mem_new_with_buffer(data,len);
            parser = g_mime_parser_new_with_stream(mime_stream);
            mime_msg = g_mime_parser_construct_message(parser);
            g_mime_stream_unref(mime_stream);
	    g_object_unref (parser);
          } else {
            croak("construct_message: Unknown type: %d", (int)svvaltype);
          }
        }
    	
        RETVAL = mime_msg;
	if (gmime_debug)
          warn("g_mime_parser_construct_message: 0x%x\n", RETVAL);
        plist = g_list_prepend(plist, RETVAL);
    OUTPUT:
        RETVAL

SV *
g_mime_parser_construct_part(svmixed)
        SV *		svmixed
    PREINIT:
        STRLEN		len;
        char *		data;
        GMimeObject	*mime_object = NULL;
        GMimeStream	*mime_stream = NULL;
        GMimeParser *parser = NULL;
        svtype		svvaltype;
        SV *		svval;
    CODE:
    	svval = svmixed;
        if (SvROK(svmixed)) {
          if (sv_derived_from(svmixed, "MIME::Fast::DataWrapper")) {
          	IV tmp = SvIV((SV*)SvRV(svmixed));
        	GMimeDataWrapper *mime_data_wrapper;

        	mime_data_wrapper = INT2PTR(MIME__Fast__DataWrapper,tmp);
        	mime_stream = g_mime_data_wrapper_get_stream(mime_data_wrapper);
                parser = g_mime_parser_new_with_stream(mime_stream);
          	mime_object = g_mime_parser_construct_part(parser);
                g_mime_stream_unref(mime_stream);
		g_object_unref (parser);
          } else if (sv_derived_from(svmixed, "MIME::Fast::Stream")) {
          	IV tmp = SvIV((SV*)SvRV(svmixed));

        	mime_stream = INT2PTR(MIME__Fast__Stream,tmp);
                parser = g_mime_parser_new_with_stream(mime_stream);
          	mime_object = g_mime_parser_construct_part(parser);
		g_object_unref (parser);
          } else if (sv_derived_from(svmixed, "MIME::Fast::Parser")) {
          	IV tmp = SvIV((SV*)SvRV(svmixed));

        	parser = INT2PTR(MIME__Fast__Parser,tmp);
          	mime_object = g_mime_parser_construct_part(parser);
          }
          svval = SvRV(svmixed);
        }
        svvaltype = SvTYPE(svval);

        if (mime_object == NULL) {
          if (svvaltype == SVt_PVGV) { // possible FILE * handle
#ifdef USE_PERLIO
	    PerlIO *pio;

	    pio = IoIFP(sv_2io(svval));
	    if (!pio) {
	        croak("MIME::Fast::Parser::construct_part: the argument you gave is not a FILE pointer");
	    }
	    mime_stream = g_mime_stream_perlio_new(pio);
	    g_mime_stream_perlio_set_owner(GMIME_STREAM_PERLIO(mime_stream), FALSE);
	    if (!mime_stream) {
	      XSRETURN_UNDEF;
            }
#else
	    PerlIO *pio;
	    FILE *fp;
	    int fd0;
	    int fd;

	    pio = IoIFP(sv_2io(svval));
	    if (!pio || !(fp = PerlIO_findFILE(pio)) || ((fd0 = PerlIO_fileno(pio)) < 0)) {
	        croak("MIME::Fast::Parser::construct_part: the argument you gave is not a FILE pointer");
	    }
	    
	    fd = dup(fd0);
	    if (fd == -1)
	        croak("MIME::Fast::Parser::construct_part: Can not duplicate a FILE pointer [from PVGV]");
            //mime_stream = g_mime_stream_file_new(fp);
            mime_stream = g_mime_stream_fs_new(fd);
	    if (!mime_stream) {
	      close(fd);
	      XSRETURN_UNDEF;
            }
#endif
	    // g_mime_stream_file_set_owner (mime_stream, FALSE);
            parser = g_mime_parser_new_with_stream(mime_stream);
            mime_object = g_mime_parser_construct_part(parser);
            g_mime_stream_unref(mime_stream);
	    g_object_unref (parser);
	  } else if (svvaltype == SVt_PVMG) { // possible STDIN/STDOUT etc.
            int fd0 = (int)SvIV( svval );
	    int fd;

	    if (fd0 < 0 || (fd = dup(fd0)) == -1)
	      croak("MIME::Fast::Parser::construct_part: Can not duplicate a file descriptor [from PVMG]");

            mime_stream = g_mime_stream_fs_new(fd);
	    if (!mime_stream) {
		close(fd);
		XSRETURN_UNDEF;
	    }
            parser = g_mime_parser_new_with_stream(mime_stream);
            mime_object = g_mime_parser_construct_part(parser);
            g_mime_stream_unref(mime_stream);
	    g_object_unref (parser);
          } else if (SvPOK(svval)) {
            data = (char *)SvPV(svmixed, len);
            mime_stream = g_mime_stream_mem_new_with_buffer(data,len);
            parser = g_mime_parser_new_with_stream(mime_stream);
            mime_object = g_mime_parser_construct_part(parser);
            g_mime_stream_unref(mime_stream);
	    g_object_unref (parser);
          } else {
            croak("construct_part: Unknown type: %d", (int)svvaltype);
          }
        }
    	
	RETVAL = newSViv(0);

        if (GMIME_IS_MULTIPART(mime_object))
	  sv_setref_pv(RETVAL, "MIME::Fast::MultiPart", (MIME__Fast__MultiPart)mime_object);
	else if (GMIME_IS_MESSAGE_PART(mime_object))
	  sv_setref_pv(RETVAL, "MIME::Fast::MessagePart", (MIME__Fast__MessagePart)mime_object);
	else if (GMIME_IS_MESSAGE_PARTIAL(mime_object))
	  sv_setref_pv(RETVAL, "MIME::Fast::MessagePartial", (MIME__Fast__MessagePartial)mime_object);
	else if (GMIME_IS_PART(mime_object))
	  sv_setref_pv(RETVAL, "MIME::Fast::Part", (MIME__Fast__Part)mime_object);
	else
	  die("g_mime_parser_construct_part: unknown type of object: 0x%x", mime_object);
        
	if (gmime_debug)
          warn("g_mime_parser_construct_part: 0x%x mo=%p\n", RETVAL, mime_object);
        plist = g_list_prepend(plist, mime_object);
    OUTPUT:
        RETVAL

void
g_mime_parser_init_with_stream(parser, mime_stream)
	MIME::Fast::Parser	parser
	MIME::Fast::Stream	mime_stream

void
g_mime_parser_set_scan_from(parser, scan_from)
	MIME::Fast::Parser	parser
	gboolean		scan_from

gboolean
g_mime_parser_get_scan_from(parser)
	MIME::Fast::Parser	parser

void
g_mime_parser_set_persist_stream(parser, persist)
	MIME::Fast::Parser	parser
	gboolean		persist

gboolean
g_mime_parser_get_persist_stream(parser)
	MIME::Fast::Parser	parser

void
g_mime_parser_set_header_regex(parser, regex, callback, svdata)
	MIME::Fast::Parser	parser
	const char *		regex
	SV *			callback
	SV *			svdata
    PREINIT:
	HV *			rh;
    CODE:
	// rh = (HV *)sv_2mortal((SV *)newHV());
	rh = newHV();
	hv_store(rh, "user_data", 9, newSVsv(svdata), 0);
	hv_store(rh, "func", 4, newSVsv(callback), 0);
        g_mime_parser_set_header_regex(parser, regex, call_sub_header_regex, newRV((SV *)rh));

 # position
off_t
g_mime_parser_tell(parser)
	MIME::Fast::Parser	parser

gboolean
g_mime_parser_eos(parser)
	MIME::Fast::Parser	parser

SV *
g_mime_parser_get_from(parser)
	MIME::Fast::Parser	parser
    PREINIT:
	char *		textdata = NULL;
    CODE:
	textdata = g_mime_parser_get_from(parser);
	if (textdata == NULL)
	  XSRETURN_UNDEF;
	RETVAL = newSVpv(textdata, 0);
    OUTPUT:
	RETVAL

off_t
g_mime_parser_get_from_offset(parser)
	MIME::Fast::Parser	parser


