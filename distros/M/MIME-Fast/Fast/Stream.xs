
MODULE = MIME::Fast		PACKAGE = MIME::Fast::Stream		PREFIX=g_mime_stream_

 # partial support - TODO: maybe IO:: support

 #
 # Create Stream for string or FILE
 #

MIME::Fast::Stream
g_mime_stream_new(Class, svmixed = 0, start = 0, end = 0)
    CASE: items == 1
    CODE:
    	RETVAL = g_mime_stream_mem_new();
        plist = g_list_prepend(plist, RETVAL);
    OUTPUT:
    	RETVAL
    CASE: items == 2
        const char *	Class
        SV *		svmixed
    PREINIT:
        STRLEN		len;
        char *		data;
        GMimeStream	*mime_stream = NULL;
        svtype		svvaltype;
        SV *		svval;
    CODE:
    	svval = svmixed;
        if (SvROK(svmixed)) {
          svval = SvRV(svmixed);
        }
        svvaltype = SvTYPE(svval);

        if (mime_stream == NULL) {
          if (svvaltype == SVt_PVGV) { // possible FILE * handle
#ifdef USE_PERLIO
	    PerlIO *pio;

	    pio = IoIFP(sv_2io(svval));
	    if (!pio) {
		croak("MIME::Fast::Stream::new: the argument you gave is not a FILE pointer");
	    }
	    mime_stream = g_mime_stream_perlio_new(pio);
	    g_mime_stream_perlio_set_owner(GMIME_STREAM_PERLIO(mime_stream), FALSE);
	    if (!mime_stream) {
	      XSRETURN_UNDEF;
            }
#else
	    PerlIO *pio;
	    FILE *fp;
	    int fd, fd0;

	    pio = IoIFP(sv_2io(svval));
	    if (!pio || !(fp = PerlIO_findFILE(pio)) || ((fd0 = PerlIO_fileno(pio)) < 0)) {
	      croak("MIME::Fast::Stream::new: the argument you gave is not a FILE pointer");
	    }
	    
	    fd = dup(fd0);
	    if (fd == -1)
	      croak("MIME::Fast::Stream::new: Can not duplicate a FILE pointer");

            // mime_stream = g_mime_stream_file_new(fp);
            mime_stream = g_mime_stream_fs_new(fd);
	    if (!mime_stream) {
	      close(fd);
	      XSRETURN_UNDEF;
            }
#endif
	    // g_mime_stream_file_set_owner (mime_stream, FALSE);
	  } else if (svvaltype == SVt_PVMG) { // possible STDIN/STDOUT etc.
            int fd0 = (int)SvIV( svval );
	    int fd;

	    if (fd0 < 0 || (fd = dup(fd0)) == -1)
	      croak("MIME::Fast::Stream::new: Can not duplicate a FILE pointer");

            mime_stream = g_mime_stream_fs_new(fd);
	    if (!mime_stream) {
	      close(fd);
	      XSRETURN_UNDEF;
            }
	    // g_mime_stream_fs_set_owner (mime_stream, FALSE);
          } else if (SvPOK(svval)) {
            data = (char *)SvPV(svmixed, len);
            mime_stream = g_mime_stream_mem_new_with_buffer(data,len);
	  } else {
            croak("stream_new: Unknown type: %d", (int)svvaltype);
          }
        }
    	RETVAL = mime_stream;
        plist = g_list_prepend(plist, RETVAL);
    OUTPUT:
        RETVAL
    CASE: items == 4
        const char *	Class
        SV *		svmixed
        off_t		start
        off_t		end
    PREINIT:
        GMimeStream	*mime_stream = NULL;
        svtype		svvaltype;
        SV *		svval;
    CODE:
    	svval = svmixed;
        if (SvROK(svmixed)) {
          svval = SvRV(svmixed);
        }
        svvaltype = SvTYPE(svval);

        if (mime_stream == NULL) {
          if (svvaltype == SVt_PVGV) { // possible FILE * handle
#ifdef USE_PERLIO
	    PerlIO *pio;

	    pio = IoIFP(sv_2io(svval));
	    if (!pio) {
	        croak("MIME::Fast::Stream::new: the argument you gave is not a FILE pointer");
	    }
	    mime_stream = g_mime_stream_perlio_new(pio);
	    g_mime_stream_perlio_set_owner(GMIME_STREAM_PERLIO(mime_stream), FALSE);
	    if (!mime_stream) {
	      XSRETURN_UNDEF;
            }
#else
	    PerlIO *pio;
	    FILE *fp;
	    int fd;

	    pio = IoIFP(sv_2io(svval));
	    if (!pio || !(fp = PerlIO_findFILE(pio))) {
	        croak("MIME::Fast::Stream::new: the argument you gave is not a FILE pointer");
	    }
	    
	    fd = dup(fileno(fp));
	    if (fd == -1)
	      croak("MIME::Fast::Stream::new: Can not duplicate a FILE pointer");


            // mime_stream = g_mime_stream_file_new_with_bounds(fp, start, end);
            mime_stream = g_mime_stream_fs_new_with_bounds(fd, start, end);
	    if (!mime_stream) {
	      close(fd);
	      XSRETURN_UNDEF;
            }
	    // g_mime_stream_file_set_owner (mime_stream, FALSE);
#endif
	  } else if (svvaltype == SVt_PVMG) { // possible STDIN/STDOUT etc.
            int fd0 = (int)SvIV( svval );
	    int fd;

	    if (fd0 < 0 || (fd = dup(fd0)) == -1)
	      croak("MIME::Fast::Stream::new: Can not duplicate a FILE pointer");

            mime_stream = g_mime_stream_fs_new_with_bounds(fd, start, end);
	    if (!mime_stream) {
	      close(fd);
	      XSRETURN_UNDEF;
            }
	    // g_mime_stream_fs_set_owner (mime_stream, FALSE);

          } else if (SvPOK(svval)) {
            warn ("stream_new: bounds for string are not supported");
          } else {
            croak("stream_new: Unknown type: %d", (int)svvaltype);
          }
        }
    	RETVAL = mime_stream;
        plist = g_list_prepend(plist, RETVAL);
    OUTPUT:
        RETVAL

void
DESTROY(mime_stream)
        MIME::Fast::Stream	mime_stream
    CODE:
        if (g_list_find(plist,mime_stream)) {
            g_mime_stream_unref(mime_stream);
            plist = g_list_remove(plist, mime_stream);
        }

long
g_mime_stream_write_string(mime_stream, str)
        MIME::Fast::Stream	mime_stream
        char *			str
    CODE:
        RETVAL = g_mime_stream_write_string(mime_stream, str);
    OUTPUT:
        RETVAL

ssize_t
g_mime_stream_write_to_stream(mime_stream_src, svstream)
        MIME::Fast::Stream	mime_stream_src
	SV *			svstream
    PREINIT:
        GMimeStream *		mime_stream_dst;
    CODE:
	if (sv_derived_from(svstream, "MIME::Fast::Stream")) {
	    IV tmp = SvIV((SV*)SvRV(svstream));
	    mime_stream_dst = INT2PTR(MIME__Fast__Stream,tmp);
	}
	else
	    Perl_croak(aTHX_ "mime_stream is not of type MIME::Fast::Stream");
	
        RETVAL = g_mime_stream_write_to_stream(mime_stream_src, mime_stream_dst);
    OUTPUT:
        RETVAL

 # raw stream methods

ssize_t
g_mime_stream_read(mime_stream, buf, len)
        MIME::Fast::Stream	mime_stream
	SV *			buf
	size_t			len
    PREINIT:
	char			*str;
    CODE: 
    	if (SvREADONLY(buf) && PL_curcop != &PL_compiling)
	    croak("MIME::Fast::Stream->read: buffer parameter is read-only");
	else
	if (!SvUPGRADE(buf, SVt_PV))
	    croak("MIME::Fast::Stream->read: cannot use buf argument as lvalue");
	SvPOK_only(buf);
	SvCUR_set(buf, 0);
	
	str = (char *)SvGROW(buf, len + 1);
	RETVAL = g_mime_stream_read(mime_stream, str, len);
	if (RETVAL > 0)
	{
	    SvCUR_set(buf, RETVAL);
	    *SvEND(buf) = '\0';
	}
    OUTPUT:
	buf
	RETVAL

ssize_t
g_mime_stream_write(mime_stream, buf, len)
        MIME::Fast::Stream	mime_stream
	char			*buf
	size_t			len

int
g_mime_stream_flush(mime_stream)
        MIME::Fast::Stream	mime_stream

int
g_mime_stream_close(mime_stream)
        MIME::Fast::Stream	mime_stream

gboolean
g_mime_stream_eos(mime_stream)
        MIME::Fast::Stream	mime_stream

int
g_mime_stream_reset(mime_stream)
        MIME::Fast::Stream	mime_stream

off_t
g_mime_stream_seek(mime_stream, offset, whence)
        MIME::Fast::Stream	mime_stream
	off_t			offset
	MIME::Fast::SeekWhence	whence

off_t
g_mime_stream_tell(mime_stream)
        MIME::Fast::Stream	mime_stream

ssize_t
g_mime_stream_length(mime_stream)
        MIME::Fast::Stream	mime_stream

MIME::Fast::Stream
g_mime_stream_substream(mime_stream, start, end)
        MIME::Fast::Stream	mime_stream
        off_t			start
        off_t			end
    CODE:
        RETVAL = g_mime_stream_substream(mime_stream, start, end);
        plist = g_list_prepend(plist, RETVAL);
    OUTPUT:
        RETVAL

void
g_mime_stream_set_bounds(mime_stream, start, end)
        MIME::Fast::Stream	mime_stream
	off_t			start
	off_t			end

