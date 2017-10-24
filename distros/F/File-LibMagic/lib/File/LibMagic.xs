#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"
#define NEED_sv_2pv_flags
#include <magic.h>
#include <string.h>
#include <stdio.h>

#include "const/inc.c"

/* This is how much data libmagic reads from an fd, so we'll emulate that. */
#define BUFSIZE (256 * 1024)

MODULE = File::LibMagic     PACKAGE = File::LibMagic

INCLUDE: ../../const/inc.xs

PROTOTYPES: ENABLE

# First the two :easy functions
SV *MagicBuffer(buffer)
   SV *buffer
   PREINIT:
       char *ret;
       STRLEN len;
       int ret_i;
       char *buffer_value;
       magic_t m;
   CODE:
       /* First make sure they actually gave us a defined scalar */
       if ( !SvOK(buffer) ) {
          croak("MagicBuffer requires defined content");
       }

       m = magic_open(MAGIC_NONE);
       if ( m == NULL ) {
           croak("libmagic out of memory");
       }
       ret_i = magic_load(m, NULL);
       if ( ret_i < 0 ) {
           croak("libmagic %s", magic_error(m));
       }
       buffer_value = SvPV(buffer, len);
       ret = (char*) magic_buffer(m, buffer_value, len);
       if ( ret == NULL ) {
           croak("libmagic %s", magic_error(m));
       }
       RETVAL = newSVpvn(ret, strlen(ret));
       magic_close(m);
   OUTPUT:
       RETVAL

SV *MagicFile(file)
   SV *file
   PREINIT:
       char *ret;
       int ret_i;
       magic_t m;
       char *file_value;
   CODE:
       /* First make sure they actually gave us a defined scalar */
       if ( !SvOK(file) ) {
          croak("MagicFile requires a filename");
       }

       m = magic_open(MAGIC_NONE);
       if ( m == NULL ) {
           croak("libmagic out of memory");
       }
       ret_i = magic_load(m, NULL);
       if ( ret_i < 0 ) {
           croak("libmagic %s", magic_error(m));
       }
       file_value = SvPV_nolen(file);
       ret = (char*) magic_file(m, file_value);
       if ( ret == NULL ) {
           croak("libmagic %s", magic_error(m));
       }
       RETVAL = newSVpvn(ret, strlen(ret));
       magic_close(m);
   OUTPUT:
       RETVAL

magic_t magic_open(flags)
   int flags
   PREINIT:
        magic_t m;
   CODE:
        m = magic_open(flags);
        if ( m == NULL ) {
            croak( "libmagic out of memory" );
        }
        RETVAL = m;
   OUTPUT:
        RETVAL

void magic_close(m)
    magic_t m
    CODE:
        if ( !m ) {
            croak( "magic_close requires a defined handle" );
        }
        magic_close(m);

IV magic_load(m, dbnames)
    magic_t m
    SV *dbnames
    PREINIT:
        STRLEN len = 0;
        char *dbnames_value;
        int ret;
    CODE:
        if ( !m ) {
            croak( "magic_load requires a defined handle" );
        }
        if ( SvOK(dbnames) ) {  /* is dbnames defined? */
            dbnames_value = SvPV(dbnames, len);
        }
        /* FIXME
         *manpage says 0 = success, any other failure
         *thus does the following line correctly reflect this? */
        ret = magic_load(m, len > 0 ? dbnames_value : NULL);
        /*
         *printf("Ret %d, \"%s\"\n", ret, dbnames_value);
         */
        RETVAL = ! ret;
        if ( RETVAL < 0 ) {
            croak( "libmagic %s", magic_error(m) );
        }
    OUTPUT:
        RETVAL

SV *magic_buffer(m, buffer)
    magic_t m
    SV *buffer
    PREINIT:
        char *ret;
        STRLEN len;
        char *buffer_value;
    CODE:
        if ( !m ) {
            croak( "magic_buffer requires a defined handle" );
        }
        /* First make sure they actually gave us a defined scalar */
        if ( !SvOK(buffer) ) {
            croak("magic_buffer requires defined content");
        }

        buffer_value = SvROK(buffer) ? SvPV(SvRV(buffer), len) : SvPV(buffer, len);
        ret = (char*) magic_buffer(m, buffer_value, len);
        if ( ret == NULL ) {
            croak("libmagic %s", magic_error(m));
        }
        RETVAL = newSVpvn(ret, strlen(ret));
    OUTPUT:
        RETVAL

SV *magic_file(m, file)
    magic_t m
    SV *file
    PREINIT:
        char *ret;
        char *file_value;
    CODE:
        if ( !m ) {
            croak( "magic_file requires a defined handle" );
        }
        /* First make sure they actually gave us a defined scalar */
        if ( !SvOK(file) ) {
            croak("magic_file requires a filename");
        }

        file_value = SvPV_nolen(file);
        ret = (char*) magic_file(m, file_value);
        if ( ret == NULL ) {
            croak("libmagic %s", magic_error(m));
        }
        RETVAL = newSVpvn(ret, strlen(ret));
    OUTPUT:
        RETVAL

void _magic_setflags(m, flags)
    magic_t m
    int flags
    CODE:
        magic_setflags(m, flags);

SV *magic_buffer_offset(m, buffer, offset, BuffLen)
    magic_t m
    char *buffer
    long offset
    long BuffLen
    PREINIT:
        char *ret;
        STRLEN len;
        long MyLen;
    CODE:
        if ( !m ) {
            croak( "magic_buffer requires a defined handle" );
        }
        /* FIXME check length for out of bound errors */
        MyLen = (long) BuffLen;
        ret = (char*) magic_buffer(m, (char *) &buffer[ (long) offset], MyLen);
        if ( ret == NULL ) {
            croak("libmagic %s", magic_error(m));
        }
        RETVAL = newSVpvn(ret, strlen(ret));
    OUTPUT:
        RETVAL

IV magic_version()
    CODE:
#ifdef HAVE_MAGIC_VERSION
        RETVAL = magic_version();
#else
        RETVAL = 0;
#endif
    OUTPUT:
        RETVAL

#define RETURN_INFO(self, magic_func, ...) \
        magic = (magic_t)SvIV(*( hv_fetchs((HV *)SvRV(self), "magic", 0))); \
        flags = (int)SvIV(*( hv_fetchs((HV *)SvRV(self), "flags", 0))); \
        magic_setflags(magic, flags);                     \
        description = magic_func(magic, __VA_ARGS__);     \
        if ( NULL == description ) {                      \
            croak("error calling %s: %s", #magic_func, magic_error(magic)); \
        }                                                 \
        d = newSVpvn(description, strlen(description)); \
        magic_setflags(magic, flags|MAGIC_MIME_TYPE);     \
        mime = magic_func(magic, __VA_ARGS__);            \
        if ( NULL == mime ) {                             \
            croak("error calling %s: %s", #magic_func, magic_error(magic)); \
        }                                                 \
        m = newSVpvn(mime, strlen(mime));                 \
        magic_setflags(magic, flags|MAGIC_MIME_ENCODING); \
        encoding = magic_func(magic, __VA_ARGS__);        \
        if ( NULL == encoding ) {                         \
            croak("error calling %s: %s", #magic_func, magic_error(magic)); \
        }                                                 \
        e = newSVpvn(encoding, strlen(encoding));         \
        EXTEND(SP, 3);                                    \
        mPUSHs(d);                                        \
        mPUSHs(m);                                        \
        mPUSHs(e);

SV *_info_from_string(self, buffer)
        SV *self
        SV *buffer
    PREINIT:
        magic_t magic;
        int flags;
        SV *content;
        STRLEN len;
        char *string;
        const char *description;
        const char *mime;
        const char *encoding;
        SV *d;
        SV *m;
        SV *e;
    PPCODE:
        if (SvROK(buffer)) {
            content = SvRV(buffer);
        }
        else {
            content = buffer;
        }

        if ( ! SvPOK(content) ) {
            croak("info_from_string requires a scalar or reference to a scalar as its argument");
        }

        string = SvPV(content, len);

        RETURN_INFO(self, magic_buffer, string, len);

SV *_info_from_filename(self, filename)
        SV *self
        SV *filename
    PREINIT:
        magic_t magic;
        int flags;
        char *file;
        char *string;
        const char *description;
        const char *mime;
        const char *encoding;
        SV *d;
        SV *m;
        SV *e;
    PPCODE:
        if ( ! SvPOK(filename) ) {
            croak("info_from_filename requires a scalar as its argument");
        }

        file = SvPV_nolen(filename);

        RETURN_INFO(self, magic_file, file);

SV *_info_from_handle(self, handle)
        SV *self
        SV *handle
    PREINIT:
        magic_t magic;
        int flags;
        PerlIO *io;
        char buf[BUFSIZE];
        Off_t pos;
        SSize_t read;
        const char *description;
        const char *mime;
        const char *encoding;
        SV *d;
        SV *m;
        SV *e;
    PPCODE:
        if ( ! SvOK(handle) ) {
            croak("info_from_handle requires a scalar filehandle as its argument");
        }

        io = IoIFP(sv_2io(handle));
        if ( ! io ) {
            croak("info_from_handle requires a scalar filehandle as its argument");
        }

        pos = PerlIO_tell(io);
        if ( pos < 0 ) {
            croak("info_from_handle could not call tell() on the filehandle provided: %s", strerror(errno));
        }

        read = PerlIO_read(io, buf, BUFSIZE);
        if ( read < 0 ) {
            croak("info_from_handle could not read data from the filehandle provided: %s", strerror(errno));
        }
        else if ( 0 == read ) {
            croak("info_from_handle could not read data from the filehandle provided - is the file empty?");
        }

        PerlIO_seek(io, pos, SEEK_SET);

        RETURN_INFO(self, magic_buffer, buf, read);
