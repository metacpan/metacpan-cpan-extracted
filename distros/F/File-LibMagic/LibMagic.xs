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

INCLUDE: ./const/inc.xs

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
            croak( "magic_close requires a defined magic handle" );
        }
        magic_close(m);

IV magic_load(m, dbnames)
    magic_t m
    SV *dbnames
    PREINIT:
        STRLEN len = 0;
        char *dbnames_value = NULL;
        int ret;
    CODE:
        if ( !m ) {
            croak( "magic_load requires a defined magic handle" );
        }
        if ( SvOK(dbnames) ) {  /* is dbnames defined? */
            dbnames_value = SvPV(dbnames, len);
        }
        ret = magic_load(m, len > 0 ? dbnames_value : NULL);
        if ( ret == -1 ) {
            croak( "magic_load(%s): libmagic %s", dbnames_value, magic_error(m) );
        }
        /* We already croaked on errors but we'll return true for
         * backcompat. */
        RETVAL = 1;
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
            croak( "magic_buffer requires a defined magic handle" );
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
            croak( "magic_file requires a defined magic handle" );
        }
        /* First make sure they actually gave us a defined scalar */
        if ( !SvOK(file) ) {
            croak("magic_file requires a filename");
        }

        file_value = SvPV_nolen(file);
        ret = (char*) magic_file(m, file_value);
        if ( ret == NULL ) {
            croak("magic_file: libmagic %s", magic_error(m));
        }
        RETVAL = newSVpvn(ret, strlen(ret));
    OUTPUT:
        RETVAL

IV _magic_setflags(m, flags)
    magic_t m
    int flags
    PREINIT:
        int ret;
    CODE:
        if ( !m ) {
            croak( "magic_setflags requires a defined magic handle" );
        }
        ret = magic_setflags(m, flags);
        RETVAL = !ret;
    OUTPUT:
        RETVAL

IV _magic_setparam(m, param, value)
    magic_t m
    int param
    size_t value
    PREINIT:
        int ret;
    CODE:
#ifdef HAVE_MAGIC_SETPARAM
        if ( !m ) {
            croak( "magic_setparam requires a defined magic handle" );
        }
        ret = magic_setparam(m, param, &value);
        RETVAL = !ret;
#else
        croak( "your libmagic library does not provide magic_setparam" );
#endif
    OUTPUT:
        RETVAL

IV _magic_param_exists(m, param, value)
    magic_t m
    int param
    size_t value
    PREINIT:
        int ret;
    CODE:
#ifdef HAVE_MAGIC_GETPARAM
        if ( !m ) {
            croak( "magic_getparam requires a defined magic handle" );
        }
        ret = magic_getparam(m, param, &value);
        RETVAL = !ret;
#else
        croak( "your libmagic library does not provide magic_getparam" );
#endif
    OUTPUT:
        RETVAL

SV *magic_buffer_offset(m, buffer, offset, BuffLen)
    magic_t m
    char *buffer
    long offset
    long BuffLen
    PREINIT:
        char *ret;
        long MyLen;
    CODE:
        if ( !m ) {
            croak( "magic_buffer requires a defined magic handle" );
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

#define MAGIC_SETFLAGS_OR_CROAK(magic, flags) \
        if ( magic_setflags(magic, flags) == -1 ) {       \
            croak( "error setting flags to %d", flags );  \
        }                                                 \

#define MAYBE_CROAK_ERROR(retval, magic, magic_func) \
        if ( NULL == retval ) {                   \
            const char *err = magic_error(magic); \
            croak("error calling %s: %s", #magic_func, err != NULL ? err : "magic_error() returned NULL"); \
        }

#define RETURN_INFO(self, magic_func, ...) \
        magic = (magic_t)SvIV(*( hv_fetchs((HV *)SvRV(self), "magic", 0))); \
        flags = (int)SvIV(*( hv_fetchs((HV *)SvRV(self), "flags", 0))); \
        MAGIC_SETFLAGS_OR_CROAK(magic, flags)                     \
        description = magic_func(magic, __VA_ARGS__);             \
        MAYBE_CROAK_ERROR(description, magic, magic_func)         \
        d = newSVpvn(description, strlen(description));           \
        MAGIC_SETFLAGS_OR_CROAK(magic, flags|MAGIC_MIME_TYPE)     \
        magic_setflags(magic, flags|MAGIC_MIME_TYPE);             \
        mime = magic_func(magic, __VA_ARGS__);                    \
        MAYBE_CROAK_ERROR(mime, magic, magic_func)                \
        m = newSVpvn(mime, strlen(mime));                         \
        MAGIC_SETFLAGS_OR_CROAK(magic, flags|MAGIC_MIME_ENCODING) \
        encoding = magic_func(magic, __VA_ARGS__);                \
        MAYBE_CROAK_ERROR(encoding, magic, magic_func)            \
        e = newSVpvn(encoding, strlen(encoding));                 \
        EXTEND(SP, 3);                                            \
        mPUSHs(d);                                                \
        mPUSHs(m);                                               \
        mPUSHs(e);

void _info_from_string(self, buffer)
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

void _info_from_filename(self, filename)
        SV *self
        SV *filename
    PREINIT:
        magic_t magic;
        int flags;
        char *file;
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

void _info_from_handle(self, handle)
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
