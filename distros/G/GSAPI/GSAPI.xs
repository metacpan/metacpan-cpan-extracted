#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include <iapi.h>
#include <gdevdsp.h>
#include <ierrors.h>

#include "const-c.inc"

typedef gs_main_instance *GSAPI__instance;

#ifndef DEBUG
#define DEBUG 0
#endif

/* -------------------------------------------------------- */
static SV *cb_io[3];
static SV *cb_display;


/* -------------------------------------------------------- */
typedef struct IMAGE_S IMAGE;
struct IMAGE_S {
    int handle;
    void *device;
    int width;
    int height;
    int raster;
    unsigned int format;
    void *pimage;
    IMAGE *next;
};

IMAGE *first_image = NULL;

static IMAGE *
image_find(void *handle, void *device)
{
    IMAGE *img;
    for (img = first_image; img != NULL; img = img->next) {
        if ((img->handle == (int)handle) && (img->device == device))
            return img;
    }
    return NULL;
}

static IMAGE *
image_new(void *handle, void *device )
{
    IMAGE *img = NULL;
    if(DEBUG) warn( "image_new" );
    Newxz( img, 1, IMAGE );

    /* add to list */
    if (first_image != NULL)
        img->next = first_image;
    first_image = img;

    /* remember device and handle */
    img->handle = (int)handle;
    img->device = device;
    img->pimage = NULL;
    if(DEBUG) warn( "image_new handle=%i device=%p img=%p", img->handle, img->device, img );

    return img;
}

static void 
image_free( void *handle, void *device )
{
    IMAGE *img, *prev=NULL;
    for (img = first_image; img != NULL; img = img->next) {
        if ((img->handle == (int)handle) && (img->device == device)) {
            if( prev != NULL ) {
                prev->next = img->next;
            }
            else {
                first_image = img->next;
            }
            if(DEBUG) warn( "image_free handle=%i device=%p img=%p", img->handle, img->device, img );
            img->pimage = NULL;
            Safefree( img );
            img = NULL;
            return;
        }
        prev = img;
    }
}


/* -------------------------------------------------------- */
/* run stdout or stderr callback */
static int
run_cb( int idx, const char *msg, int msglen)
{
  dSP;
  int cnt, rc;
  ENTER; SAVETMPS; PUSHMARK(SP);
    XPUSHs(sv_2mortal(newSVpvn(msg, msglen)));

  PUTBACK;
  cnt = call_sv(cb_io[idx], G_SCALAR);
  SPAGAIN;

  if(cnt != 1)
    croak("run_cb: function should return one argument");

        rc = POPi; 

    PUTBACK; FREETMPS; LEAVE;
    return rc;
}

/* run stdin callback */
static int
run_stdin( void *caller_handle, char *buf, int msglen)
{
    dSP;
    int cnt, rc;
        SV *sv;
        char * p;
        STRLEN len;

    if(!cb_io[0]) {
        return 0;
    }

    ENTER; SAVETMPS; PUSHMARK(SP);
    XPUSHs(sv_2mortal(newSViv(len)));
    PUTBACK;
    cnt = call_sv(cb_io[0], G_SCALAR);
    SPAGAIN;
    if(cnt != 1)
        croak("run_stdin: function should return one argument");
    
        sv = POPs;
        p = SvPV(sv, len);
        if(len > msglen)
        croak("run_stdin: too long string returned.");
    memcpy(buf, p, len);
        rc = len;

  PUTBACK; FREETMPS; LEAVE;
  return rc;
}

static int
run_stdout(void *caller_handle, const char *buf, int len)
{
    if(cb_io[1])
        return run_cb(1, buf, len);
  return 0;
}

static int
run_stderr(void *caller_handle, const char *buf, int len)
{
    if(cb_io[2])
        return run_cb(2, buf, len);
  return 0;
}


/* -------------------------------------------------------- */
/* callbacks for display */
static int display_open(void *handle, void *device);
static int display_preclose(void *handle, void *device);
static int display_close(void *handle, void *device);
static int display_presize(void *handle, void *device, int width, int height,
        int raster, unsigned int format);
static int display_size(void *handle, void *device, int width, int height,
        int raster, unsigned int format, unsigned char *pimage);
static int display_sync(void *handle, void *device);
static int display_page(void *handle, void *device, int copies, int flush);
static int display_update(void *handle, void *device, int x, int y,
        int w, int h);

#define CB_PREFIX dSP; int rv; IMAGE *image; \
                  ENTER; SAVETMPS; PUSHMARK(SP); \
                  image = image_find( handle, device );

#define CB_PIMAGE if( image && image->pimage ) { \
                        if(DEBUG) warn( "pimage=%p", image->pimage ); \
                        XPUSHs(sv_2mortal(newSVpvn(image->pimage, image->height * image->raster ))); \
                  }

#define CB_CALL   PUTBACK; rv = call_sv(cb_display, G_SCALAR); \
                  SPAGAIN; if( rv != 1 ) \
                        croak( "%s must only return one value\n", name );
#define CB_SUFFIX PUTBACK; FREETMPS; LEAVE;

/* Call the display callback w/o any params beyond the "normal" 2 */
static int 
display_0( const char *name, void *handle, void *device)
{
    CB_PREFIX;

    if(DEBUG) 
        warn( "name=%s", name );
    XPUSHs(sv_2mortal(newSVpvn( name, strlen( name ) )));
    XPUSHs(sv_2mortal(newSVuv((unsigned int)handle)));
    XPUSHs(sv_2mortal(newSVuv((unsigned int)device)));
    CB_PIMAGE;

    CB_CALL;
    rv = POPi;
    CB_SUFFIX;
    return rv;
}

/* New device has been opened */
/* This is the first event from this device. */
static int
display_open(void *handle, void *device)
{
    image_new( handle, device );

    return display_0( "display_open", handle, device );
}

/* Device is about to be closed. */
/* Device will not be closed until this function returns. */
static int 
display_preclose(void *handle, void *device)
{
    IMAGE *image = image_find( handle, device );
    image->pimage = NULL;
    return display_0( "display_preclose", handle, device );
}

/* Device has been closed. */
/* This is the last event from this device. */
static int 
display_close(void *handle, void *device)
{
    int rv = display_0( "display_close", handle, device );
    image_free( handle, device );
    return rv;
}

/* Device is about to be resized. */
/* Resize will only occur if this function returns 0. */
/* raster is byte count of a row. */
static int 
display_presize(void *handle, void *device,
                int width, int height, int raster, unsigned int format)
{
    const char *name = "display_presize";
    CB_PREFIX;
    image = image;

    XPUSHs(sv_2mortal(newSVpvn( name, strlen( name ) )));
    XPUSHs(sv_2mortal(newSVuv( (unsigned int) handle )));
    XPUSHs(sv_2mortal(newSVuv((unsigned int)device)));
    XPUSHs(sv_2mortal(newSViv(width)));
    XPUSHs(sv_2mortal(newSViv(height)));
    XPUSHs(sv_2mortal(newSViv(raster)));
    XPUSHs(sv_2mortal(newSVuv(format)));

    CB_CALL;
    rv = POPi;

    CB_SUFFIX;
    return rv;
}

/* Device has been resized. */
/* New pointer to raster returned in pimage */
static int 
display_size(void *handle, void *device,
        int width, int height, int raster, unsigned int format, 
        unsigned char *pimage)
{
    const char *name = "display_size";
    CB_PREFIX;

    if(DEBUG) warn( "name=%s", name );

    XPUSHs(sv_2mortal(newSVpv( name, strlen( name ) )));
    XPUSHs(sv_2mortal(newSVuv( (unsigned int) handle )));
    XPUSHs(sv_2mortal(newSVuv((unsigned int)device)));
    XPUSHs(sv_2mortal(newSViv(width)));
    XPUSHs(sv_2mortal(newSViv(height)));
    XPUSHs(sv_2mortal(newSViv(raster)));
    XPUSHs(sv_2mortal(newSVuv(format)));

    if(DEBUG) warn( "pimage=%x", pimage );
    image->pimage = pimage;
    image->width = width;
    image->height = height;
    image->raster = raster;
    image->format = format;

    CB_CALL;
    rv = POPi;
    CB_SUFFIX;
    return rv;
}

/* showpage */
/* If you want to pause on showpage, then don't return immediately */
static int 
display_page(void *handle, void *device, int copies, int flush)
{
    const char *name = "display_page";
    CB_PREFIX;

    if(DEBUG) warn( "name=%s", name );

    XPUSHs(sv_2mortal(newSVpvn( name, strlen( name ) )));
    XPUSHs(sv_2mortal(newSVuv( (unsigned int) handle )));
    XPUSHs(sv_2mortal(newSVuv((unsigned int)device)));
    XPUSHs(sv_2mortal(newSViv(copies)));
    XPUSHs(sv_2mortal(newSViv(flush)));
    CB_PIMAGE;

    CB_CALL;
    rv = POPi;
    CB_SUFFIX;

    return rv;
}

/* flushpage */
static int 
display_sync(void *handle, void *device)
{
    return display_0( "display_sync", handle, device );
}



/* Notify the caller whenever a portion of the raster is updated. */
/* This can be used for cooperative multitasking or for
 * progressive update of the display.
 * This function pointer may be set to NULL if not required.
 */
static int 
display_update(void *handle, void *device,
    int x, int y, int w, int h)
{
  return 0;
    /* Calling into perl from here is straggeringly slow.  So we don't */

#if 0
    const char *name = "display_update";
    CB_PREFIX;

/*    if(DEBUG) warn( "name=%s", name ); */

    XPUSHs(sv_2mortal(newSVpvn( name, strlen( name ) )));
    XPUSHs(sv_2mortal(newSVuv( (unsigned int) handle )));
    XPUSHs(sv_2mortal(newSVuv((unsigned int)device)));
    XPUSHs(sv_2mortal(newSViv(x)));
    XPUSHs(sv_2mortal(newSViv(y)));
    XPUSHs(sv_2mortal(newSViv(w)));
    XPUSHs(sv_2mortal(newSViv(h)));

    CB_PIMAGE;

    CB_CALL;
    rv = POPi;
    CB_SUFFIX;
    return rv;
#endif
}

/* Allocate memory for bitmap */
static void *display_memalloc(void *handle, void *device, 
                        unsigned long size) 
{
    void *mem;
    if(DEBUG) warn( "memalloc %i", size );
    Newx( mem, size, void );
    if(DEBUG) warn( "memalloc %x", mem );
    return mem;
}

/* Free memory for bitmap */
static int 
display_memfree(void *handle, void *device, void *mem )
{
    if(DEBUG) warn( "memfree %x", mem );
    Safefree( mem );
    return 0;
}


/* callback structure for "display" device */
display_callback display_cb = {
    sizeof(display_callback),
    DISPLAY_VERSION_MAJOR,
    DISPLAY_VERSION_MINOR,
    display_open,
    display_preclose,
    display_close,
    display_presize,
    display_size,
    display_sync,
    display_page,
    display_update,
    display_memalloc,
    display_memfree
};

/* -------------------------------------------------------- */



MODULE = GSAPI		PACKAGE = GSAPI		


INCLUDE: const-xs.inc

void
revision()
  PROTOTYPE:
  PREINIT:
     gsapi_revision_t rev;
  PPCODE:
     gsapi_revision(&rev, sizeof(rev));
     EXTEND(SP, 4);
     PUSHs(sv_2mortal(newSVpv(rev.product,0)));
     PUSHs(sv_2mortal(newSVpv(rev.copyright, 0)));
     PUSHs(sv_2mortal(newSViv(rev.revision)));
     PUSHs(sv_2mortal(newSViv(rev.revisiondate)));

GSAPI::instance
new_instance()
  PROTOTYPE:
  PREINIT:
      gs_main_instance *inst = 0;
  CODE:
       gsapi_new_instance(&inst, 0); // we don't need to check rc.
       RETVAL = inst;
  OUTPUT:
       RETVAL

void
delete_instance(inst)
        GSAPI::instance inst
   PROTOTYPE: $
   CODE:
        gsapi_delete_instance(inst);
        

IV
set_stdio(inst, Fstdin, Fstdout, Fstderr)
        GSAPI::instance inst
        SV *Fstdin
        SV *Fstdout
        SV *Fstderr
    PROTOTYPE: $$$$
    PREINIT:
        int i;
    CODE:
        for(i = 0; i < 3; i++) {
            if( cb_io[i] == NULL)
                cb_io[i] = NEWSV(0, 0);
        }
        sv_setsv(cb_io[0], Fstdin);
        sv_setsv(cb_io[1], Fstdout);
        sv_setsv(cb_io[2], Fstderr);
        RETVAL = gsapi_set_stdio(inst, run_stdin, run_stdout, run_stderr);
    OUTPUT:
        RETVAL
        
IV
set_display_callback(inst, Fdisplay)
        GSAPI::instance inst
        SV *Fdisplay
    PROTOTYPE: $$
    CODE:
        cb_display = NEWSV(0,0);
        sv_setsv( cb_display, Fdisplay );
        RETVAL = gsapi_set_display_callback(inst, &display_cb);
    OUTPUT:
        RETVAL


        
IV
init_with_args(inst, ...)
        GSAPI::instance inst
  PROTOTYPE: $;@
  PREINIT:
        int i;
        char **argv;
  CODE:
        Newx( argv, items, char* );
        for(i = 0; i < (items-1); i++) {
            argv[i] = SvPV_nolen( ST(i+1) );
            if(DEBUG) warn( "argv[%i] = %s", i, argv[i] );
        }
        argv[i] = NULL;
        RETVAL = gsapi_init_with_args( inst, items-1, argv );
        Safefree( argv );
OUTPUT:
        RETVAL
        
IV
exit(inst)
        GSAPI::instance inst
   PROTOTYPE: $
   PREINIT:
        int i = 0;
   CODE:
        i = i;
#if 0
        /* How does one free something allocated by NEWSV()?  Until
           we find out, the SVs are reused until the process exits. */
        for(i = 0; i < 3; i++) {
            if( cb_io[i] ) {
                Safefree( cb_io[i] );
                cb_io[i] = NULL;
            }
        }
        if( cb_display ) {
            Safefree( cb_display );
            cb_display = NULL;
        }
#endif
        RETVAL = gsapi_exit(inst);
   OUTPUT:
        RETVAL

IV
run_string(inst, sv, ...)
        GSAPI::instance inst
        SV *sv
     ALIAS:
       run_file = 1
       run_string_continue = 2
   PROTOTYPE: $$;$
   PREINIT:
        int user_errors = 0; // ??
        int pexit_code; // ??
        char *p;
        STRLEN len;
   CODE:
        p = SvPV(sv, len);
        if(items > 2)
                user_errors = SvIV(ST(2));
        RETVAL = 0;
        switch(ix) {
          case 0:
                RETVAL = gsapi_run_string_with_length(inst, p, len, user_errors, &pexit_code);
                break;
          case 1:
                RETVAL = gsapi_run_file(inst, p, user_errors, &pexit_code);
                break;
          case 2:
                RETVAL = gsapi_run_string_continue(inst, p, len, user_errors, &pexit_code);
                break;
        }
     OUTPUT:
        RETVAL

IV
run_string_begin(inst, ...)
        GSAPI::instance inst
      ALIAS:
        run_string_end = 1
      PROTOTYPE: $;$
      PREINIT:
        int user_errors = 0;
        int pexit_code;
      CODE:
        if(items >1)
                user_errors = SvIV(ST(1));
        RETVAL = 0;
        switch(ix) {
          case 0:
            RETVAL = gsapi_run_string_begin(inst, user_errors, &pexit_code);
            break;
          case 1:
            RETVAL = gsapi_run_string_end(inst, user_errors, &pexit_code);
            break;
        }
     OUTPUT:
        RETVAL

