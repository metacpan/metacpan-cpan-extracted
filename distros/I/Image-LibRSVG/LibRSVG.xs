/* ----------------------------------------------------------------
 * Original File Name:  LibRSVG.xs 
 * Creation Date:       04.02.2004
 * Description:         XS Glue for Perl 
 * -----------------------------------------------------------------
 * -----------------------------------------------------------------
 * Copyright (c) 2004 bestsolution.at Systemhaus GmbH
 * ----------------------------------------------------------------
*/

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"





/**
 * Methods below are copied from the librsvg2-package
 * from the file "rsvg-file-util.c"
 *
*/


#include "librsvg/rsvg.h"

#include <errno.h>
#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include <gdk-pixbuf/gdk-pixbuf-features.h>

#define SVG_BUFFER_SIZE (1024 * 8)

typedef enum {
    RSVG_SIZE_ZOOM,
    RSVG_SIZE_WH,
    RSVG_SIZE_WH_MAX,
    RSVG_SIZE_ZOOM_MAX
} RsvgSizeType;

struct RsvgSizeCallbackData
{
    RsvgSizeType type;
    double x_zoom;
    double y_zoom;
    gint width;
    gint height;
};

static void
rsvg_size_callback (int *width, int *height, gpointer  data)
{
    struct RsvgSizeCallbackData *real_data = (struct RsvgSizeCallbackData *) data;
    double zoomx, zoomy, zoom;

    switch (real_data->type) {
        case RSVG_SIZE_ZOOM:
            if (*width < 0 || *height < 0)
                return;

            *width = floor (real_data->x_zoom * *width + 0.5);
            *height = floor (real_data->y_zoom * *height + 0.5);
            return;

        case RSVG_SIZE_ZOOM_MAX:
            if (*width < 0 || *height < 0)
                return;

            *width = floor (real_data->x_zoom * *width + 0.5);
            *height = floor (real_data->y_zoom * *height + 0.5);

            if (*width > real_data->width || *height > real_data->height) {
                zoomx = (double) real_data->width / *width;
                zoomy = (double) real_data->height / *height;
                zoom = MIN (zoomx, zoomy);

                *width = floor (zoom * *width + 0.5);
                *height = floor (zoom * *height + 0.5);
            }
            return;

        case RSVG_SIZE_WH_MAX:
            if (*width < 0 || *height < 0)
                return;

            zoomx = (double) real_data->width / *width;
            zoomy = (double) real_data->height / *height;
            zoom = MIN (zoomx, zoomy);

            *width = floor (zoom * *width + 0.5);
            *height = floor (zoom * *height + 0.5);
            return;

        case RSVG_SIZE_WH:
        
        if (real_data->width != -1)
            *width = real_data->width;
            if (real_data->height != -1)
                *height = real_data->height;
            return;
    }

    g_assert_not_reached ();
}

static GdkPixbuf *
rsvg_pixbuf_from_file_with_size_data_ex (RsvgHandle * handle, const gchar * file_name, struct RsvgSizeCallbackData * data, GError ** error)
{
    guchar chars[SVG_BUFFER_SIZE];
    GdkPixbuf *retval;
    gint result;
    FILE *f = fopen (file_name, "rb");

    if (!f) {
        g_set_error (error, G_FILE_ERROR,
        g_file_error_from_errno (errno),
        g_strerror (errno));
        return NULL;
    }

    rsvg_handle_set_size_callback (handle, rsvg_size_callback, data, NULL);

    while ((result = fread (chars, 1, SVG_BUFFER_SIZE, f)) > 0)
        rsvg_handle_write (handle, chars, result, error);

    rsvg_handle_close (handle, error);
    retval = rsvg_handle_get_pixbuf (handle);

    fclose (f);	
    return retval;
}

static GdkPixbuf *
rsvg_pixbuf_from_file_with_size_data (const gchar * file_name, struct RsvgSizeCallbackData * data, GError ** error)
{
    RsvgHandle * handle = rsvg_handle_new ();
    GdkPixbuf * retval = rsvg_pixbuf_from_file_with_size_data_ex (handle, file_name, data, error);
    rsvg_handle_free (handle);
    return retval;
}


static GdkPixbuf *
rsvg_pixbuf_from_chars_with_size_data (const guchar * svg, struct RsvgSizeCallbackData * data, GError ** error)
{
    RsvgHandle * handle = rsvg_handle_new ();
    rsvg_handle_set_size_callback (handle, rsvg_size_callback, data, NULL);
    rsvg_handle_write (handle, svg, strlen( svg ), error);
    rsvg_handle_close (handle, error);
    GdkPixbuf *retval = rsvg_handle_get_pixbuf (handle);
    rsvg_handle_free (handle);

    return retval;
}

















GdkPixbuf *
rsvg_pixbuf_from_file (const gchar *file_name, GError     **error)
{
    return rsvg_pixbuf_from_file_at_size (file_name, -1, -1, error);
}

/*GdkPixbuf *
rsvg_pixbuf_from_chars (const gchar *svg, GError     **error)
{
    return rsvg_pixbuf_from_chars_at_size (svg, -1, -1, error);
}*/


GdkPixbuf *
rsvg_pixbuf_from_file_at_zoom (const gchar *file_name, double x_zoom, double y_zoom, GError **error)
{
    struct RsvgSizeCallbackData data;

    g_return_val_if_fail (file_name != NULL, NULL);
    g_return_val_if_fail (x_zoom > 0.0 && y_zoom > 0.0, NULL);

    data.type = RSVG_SIZE_ZOOM;
    data.x_zoom = x_zoom;
    data.y_zoom = y_zoom;
    
    return rsvg_pixbuf_from_file_with_size_data (file_name, &data, error);
}

GdkPixbuf *
rsvg_pixbuf_from_chars_at_zoom (const gchar *file_name, double x_zoom, double y_zoom, GError **error)
{
    struct RsvgSizeCallbackData data;

    g_return_val_if_fail (file_name != NULL, NULL);
    g_return_val_if_fail (x_zoom > 0.0 && y_zoom > 0.0, NULL);

    data.type = RSVG_SIZE_ZOOM;
    data.x_zoom = x_zoom;
    data.y_zoom = y_zoom;
    
    return rsvg_pixbuf_from_chars_with_size_data (file_name, &data, error);
}




GdkPixbuf  *
rsvg_pixbuf_from_file_at_zoom_with_max (const gchar  *file_name, double x_zoom, double y_zoom, gint max_width, gint max_height, GError **error)
{
    struct RsvgSizeCallbackData data;

    g_return_val_if_fail (file_name != NULL, NULL);
    g_return_val_if_fail (x_zoom > 0.0 && y_zoom > 0.0, NULL);

    data.type = RSVG_SIZE_ZOOM_MAX;
    data.x_zoom = x_zoom;
    data.y_zoom = y_zoom;
    data.width = max_width;
    data.height = max_height;

    return rsvg_pixbuf_from_file_with_size_data (file_name, &data, error);
}

GdkPixbuf  *
rsvg_pixbuf_from_chars_at_zoom_with_max (const gchar  *file_name, double x_zoom, double y_zoom, gint max_width, gint max_height, GError **error)
{
    struct RsvgSizeCallbackData data;

    g_return_val_if_fail (file_name != NULL, NULL);
    g_return_val_if_fail (x_zoom > 0.0 && y_zoom > 0.0, NULL);

    data.type = RSVG_SIZE_ZOOM_MAX;
    data.x_zoom = x_zoom;
    data.y_zoom = y_zoom;
    data.width = max_width;
    data.height = max_height;

    return rsvg_pixbuf_from_chars_with_size_data (file_name, &data, error);
}




GdkPixbuf *
rsvg_pixbuf_from_file_at_size (const gchar *file_name, gint width, gint height, GError **error)
{
    struct RsvgSizeCallbackData data;

    data.type = RSVG_SIZE_WH;
    data.width = width;
    data.height = height;

    return rsvg_pixbuf_from_file_with_size_data (file_name, &data, error);
}


GdkPixbuf *
rsvg_pixbuf_from_chars_at_size (const gchar *svg, gint width, gint height, GError **error)
{
    struct RsvgSizeCallbackData data;

    data.type = RSVG_SIZE_WH;
    data.width = width;
    data.height = height;

    return rsvg_pixbuf_from_chars_with_size_data (svg, &data, error);
}

GdkPixbuf *
rsvg_pixbuf_from_chars (const gchar *svg, GError     **error)
{
    return rsvg_pixbuf_from_chars_at_size (svg, -1, -1, error);
}




GdkPixbuf  *
rsvg_pixbuf_from_file_at_max_size (const gchar *file_name, gint max_width, gint max_height, GError **error)
{
    struct RsvgSizeCallbackData data;

    data.type = RSVG_SIZE_WH_MAX;
    data.width = max_width;
    data.height = max_height;
        
    return rsvg_pixbuf_from_file_with_size_data (file_name, &data, error);
}

GdkPixbuf  *
rsvg_pixbuf_from_chars_at_max_size (const gchar *file_name, gint max_width, gint max_height, GError **error)
{
    struct RsvgSizeCallbackData data;

    data.type = RSVG_SIZE_WH_MAX;
    data.width = max_width;
    data.height = max_height;
        
    return rsvg_pixbuf_from_chars_with_size_data (file_name, &data, error);
}




int
save( int quality, char * format, GdkPixbuf * pixbuf, char * filename ) {
    char * quality_str;
    int rv;
    
    if (strcmp (format, "jpeg") != 0 || (quality < 1 || quality > 100)) /* is a png or is an invalid quality */
    {
        rv = gdk_pixbuf_save (pixbuf, filename, format, NULL, NULL);
    }
    else 
    {
        quality_str = g_strdup_printf ("%d", quality);
        rv = gdk_pixbuf_save (pixbuf, filename, format, NULL, "quality", quality_str, NULL);
        g_free (quality_str);
    }
    
    return rv;
}

void add_if_writable(GdkPixbufFormat *data, AV *formats) {
    
    if (gdk_pixbuf_format_is_writable (data)) {
        av_push( formats, newSVpv( gdk_pixbuf_format_get_name ( data ), 0 ) );
    }
}

void add_to_formats_list(GdkPixbufFormat *data, AV *formats){
    av_push( formats, newSVpv( gdk_pixbuf_format_get_name ( data ), 0 ) );
}


/*void add_mimetypes_to_formats(GdkPixbufFormat *data, HV *formats){
    char *name = gdk_pixbuf_format_get_name ( data );
    
    // gchar **mime_types  = gdk_pixbuf_format_get_mime_types(data);
    // AV *mime_types = (AV *)newAV();
    
    // g_strfreev( mime_types );
    
    // hv_store(  );
}

void add_mime_type_to_list(  ){
    
}

*/

typedef struct {
  GdkPixbuf *pixbuf;
} SVGLibRSVG;

MODULE = Image::LibRSVG		PACKAGE = Image::LibRSVG		

PROTOTYPES: ENABLE


## -------------------------------------------------------
## CONSTRUCTOR AND DESTRUCTOR
## -------------------------------------------------------
SVGLibRSVG *
new( CLASS )
        char *CLASS
    CODE:
        Newz(0, RETVAL, 1, SVGLibRSVG);
        RETVAL->pixbuf = NULL;
    OUTPUT:
        RETVAL

void
SVGLibRSVG::DESTROY()
    CODE:
        if( THIS->pixbuf ) {
            g_object_unref ( G_OBJECT (THIS->pixbuf) );
            THIS->pixbuf = NULL;
        }


## -------------------------------------------------------
## SOME STATIC METHODS
## -------------------------------------------------------
static SV *
SVGLibRSVG::getSupportedFormats()
    CODE:
        GSList *formats = gdk_pixbuf_get_formats ();
        AV * results = (AV *)sv_2mortal( (SV *)newAV() );
        
        g_slist_foreach ( formats, add_if_writable, results );
        g_slist_free (formats);
        RETVAL = newRV((SV *)results);
    OUTPUT:
        RETVAL

        
static SV *
SVGLibRSVG::getKnownFormats()
    CODE:
        GSList *formats = gdk_pixbuf_get_formats ();
        AV * results = (AV *)sv_2mortal( (SV *)newAV() );
        
        g_slist_foreach ( formats, add_to_formats_list, results );
        g_slist_free (formats);
        RETVAL = newRV((SV *)results);
    OUTPUT:
        RETVAL

static int
SVGLibRSVG::isFormatSupported( format_string )
        char *format_string
    CODE:
        I32 formatsi = 0;
        int i;
        
        AV * results = (AV *)sv_2mortal( (SV *)newAV() );
        GSList *formats = gdk_pixbuf_get_formats ();
        
        g_slist_foreach ( formats, add_if_writable, results );
        g_slist_free (formats);
        
        formatsi = av_len( results );
        
        RETVAL = 0;
        
        for( i = 0; i <= formatsi; i++ ){
            STRLEN l;
            char * fn = SvPV( *av_fetch(results, i, 0), l);
            
            if( strcmp( fn, format_string ) == 0 ) {
                RETVAL = 1;
                break;
            }
        }
    OUTPUT:
        RETVAL

static bool
SVGLibRSVG::isGzCompressionSupported()
        CODE:
            RETVAL = 1;
        OUTPUT:
            RETVAL

        
## -------------------------------------------------------
## CONVERT FUNCTIONS
## -------------------------------------------------------
int
SVGLibRSVG::convert( svgfile, bitmapfile, dpi=0, format="png", quality=100  )
        char   * svgfile
        char   * bitmapfile
        double   dpi
        char   * format 
        int      quality
    CODE:
        GdkPixbuf *pixbuf;
        
        g_type_init ();
        
        if (dpi > 0.) {
            rsvg_set_default_dpi (dpi);
        }
        
        pixbuf = rsvg_pixbuf_from_file( svgfile, NULL );
        
        if( pixbuf ) {
            RETVAL = save( quality, format, pixbuf, bitmapfile );
            g_object_unref ( G_OBJECT (pixbuf) );
        } else {
            RETVAL = 0;
        }
    OUTPUT:
        RETVAL

        
int
SVGLibRSVG::convertAtZoom( svgfile, bitmapfile, x_zoom, y_zoom, dpi=0, format="png", quality=100 )
        char   * svgfile
        char   * bitmapfile
        double   x_zoom
        double   y_zoom
        double   dpi
        char   * format 
        int      quality
    CODE: 
        GdkPixbuf *pixbuf;
        
        g_type_init ();
        
        if (dpi > 0.) {
            rsvg_set_default_dpi (dpi);
        }

        pixbuf = rsvg_pixbuf_from_file_at_zoom( svgfile, x_zoom, y_zoom, NULL );
        
        if( pixbuf ){
            RETVAL = save( quality, format, pixbuf, bitmapfile );
            g_object_unref ( G_OBJECT (pixbuf) );
        } else {
            RETVAL = 0;
        }
    OUTPUT:
        RETVAL

int
SVGLibRSVG::convertAtMaxSize( svgfile, bitmapfile, width, height, dpi=0, format="png", quality=100 )
        char   * svgfile
        char   * bitmapfile
        int      width
        int      height
        double   dpi
        char   * format 
        int      quality
    CODE: 
        GdkPixbuf *pixbuf;
        
        g_type_init ();
        
        if (dpi > 0.) {
            rsvg_set_default_dpi (dpi);
        }

        pixbuf = rsvg_pixbuf_from_file_at_max_size( svgfile, width, height, NULL );
        
        if( pixbuf ){
            RETVAL = save( quality, format, pixbuf, bitmapfile );
            g_object_unref ( G_OBJECT (pixbuf) );
        } else {
            RETVAL = 0;
        }
    OUTPUT:
        RETVAL

int
SVGLibRSVG::convertAtSize( svgfile, bitmapfile, width, height, dpi=0, format="png", quality=100 )
        char   * svgfile
        char   * bitmapfile
        int      width
        int      height
        double   dpi
        char   * format 
        int      quality
    CODE: 
        GdkPixbuf *pixbuf;
        
        g_type_init ();
        
        if (dpi > 0.) {
            rsvg_set_default_dpi (dpi);
        }

        pixbuf = rsvg_pixbuf_from_file_at_size( svgfile, width, height, NULL );
        
        if( pixbuf ){
            RETVAL = save( quality, format, pixbuf, bitmapfile );
            g_object_unref ( G_OBJECT (pixbuf) );
        } else {
            RETVAL = 0;
        }
    OUTPUT:
        RETVAL

int
SVGLibRSVG::convertAtZoomWithMax( svgfile, bitmapfile, x_zoom, y_zoom, width, height, dpi=0, format="png", quality=100  )
        char   * svgfile
        char   * bitmapfile
        double   x_zoom
        double   y_zoom
        int      width
        int      height
        double   dpi
        char   * format 
        int      quality
    CODE: 
        GdkPixbuf *pixbuf;
        
        g_type_init ();
        
        if (dpi > 0.) {
            rsvg_set_default_dpi (dpi);
        }

        pixbuf = rsvg_pixbuf_from_file_at_zoom_with_max( svgfile, x_zoom, y_zoom, width, height, NULL );
        
        if( pixbuf ){
            RETVAL = save( quality, format, pixbuf, bitmapfile );
            g_object_unref ( G_OBJECT (pixbuf) );
        } else {
            RETVAL = 0;
        }
    OUTPUT:
        RETVAL

        
## -------------------------------------------------------
## LOAD FUNCTIONS
## -------------------------------------------------------
int
SVGLibRSVG::loadFromFile( svgfile, dpi=0 )
        char   * svgfile
        double   dpi
    CODE:
        g_type_init ();
        
        if (dpi > 0.) {
            rsvg_set_default_dpi (dpi);
        }
        
        if( THIS->pixbuf ) {
            g_object_unref ( G_OBJECT (THIS->pixbuf) );
        }
        
        THIS->pixbuf = rsvg_pixbuf_from_file( svgfile, NULL );
        
        if( THIS->pixbuf ) {
            RETVAL = 1;
        } else {
            RETVAL = 0;
        }
    OUTPUT:
        RETVAL

int
SVGLibRSVG::loadFromString( svg, dpi=0  )
        char   * svg
        double   dpi
    CODE:
        
        g_type_init ();
        
        if (dpi > 0.) {
            rsvg_set_default_dpi (dpi);
        }
        
        if( THIS->pixbuf ) {
            g_object_unref ( G_OBJECT (THIS->pixbuf) );
        }
        
        THIS->pixbuf = rsvg_pixbuf_from_chars( svg, NULL );
        
        if( THIS->pixbuf ) 
        {
            RETVAL = 1;
        } 
        else 
        {
            RETVAL = 0;
        }
    OUTPUT:
        RETVAL

## -------------------------------------------------------
## -------------------------------------------------------

        
int
SVGLibRSVG::loadFromFileAtZoom( svgfile, x_zoom, y_zoom, dpi=0 )
        char   * svgfile
        double   x_zoom
        double   y_zoom
        double   dpi
    CODE: 
        g_type_init ();
        
        if (dpi > 0.) {
            rsvg_set_default_dpi (dpi);
        }

        if( THIS->pixbuf ) {
            g_object_unref ( G_OBJECT (THIS->pixbuf) );
        }
        
        THIS->pixbuf = rsvg_pixbuf_from_file_at_zoom( svgfile, x_zoom, y_zoom, NULL );
        
        if( THIS->pixbuf ) {
            RETVAL = 1;
        } else {
            RETVAL = 0;
        }
    OUTPUT:
        RETVAL


int
SVGLibRSVG::loadFromStringAtZoom( svg, x_zoom, y_zoom, dpi=0 )
        char   * svg
        double   x_zoom
        double   y_zoom
        double   dpi
    CODE: 
        g_type_init ();
        
        if (dpi > 0.) {
            rsvg_set_default_dpi (dpi);
        }

        if( THIS->pixbuf ) {
            g_object_unref ( G_OBJECT (THIS->pixbuf) );
        }
        
        THIS->pixbuf = rsvg_pixbuf_from_chars_at_zoom( svg, x_zoom, y_zoom, NULL );
        
        if( THIS->pixbuf ) {
            RETVAL = 1;
        } else {
            RETVAL = 0;
        }
    OUTPUT:
        RETVAL

        
## -------------------------------------------------------
## -------------------------------------------------------
        
        
int
SVGLibRSVG::loadFromFileAtMaxSize( svgfile, width, height, dpi=0 )
        char   * svgfile
        int      width
        int      height
        double   dpi
    CODE: 
        g_type_init ();
        
        if (dpi > 0.) {
            rsvg_set_default_dpi (dpi);
        }
        
        if( THIS->pixbuf ) {
            g_object_unref ( G_OBJECT (THIS->pixbuf) );
        }

        THIS->pixbuf = rsvg_pixbuf_from_file_at_max_size( svgfile, width, height, NULL );
        
        if( THIS->pixbuf ) {
            RETVAL = 1;
        } else {
            RETVAL = 0;
        }
    OUTPUT:
        RETVAL

        
int
SVGLibRSVG::loadFromStringAtMaxSize( svgfile, width, height, dpi=0 )
        char   * svgfile
        int      width
        int      height
        double   dpi
    CODE: 
        g_type_init ();
        
        if (dpi > 0.) {
            rsvg_set_default_dpi (dpi);
        }
        
        if( THIS->pixbuf ) {
            g_object_unref ( G_OBJECT (THIS->pixbuf) );
        }

        THIS->pixbuf = rsvg_pixbuf_from_chars_at_max_size( svgfile, width, height, NULL );
        
        if( THIS->pixbuf ) {
            RETVAL = 1;
        } else {
            RETVAL = 0;
        }
    OUTPUT:
        RETVAL


## -------------------------------------------------------
## -------------------------------------------------------

       
int
SVGLibRSVG::loadFromFileAtSize( svgfile, width, height, dpi=0 )
        char   * svgfile
        int      width
        int      height
        double   dpi
    CODE: 
        g_type_init ();
        
        if (dpi > 0.) {
            rsvg_set_default_dpi (dpi);
        }
        
        if( THIS->pixbuf ) {
            g_object_unref ( G_OBJECT (THIS->pixbuf) );
        }

        THIS->pixbuf = rsvg_pixbuf_from_file_at_size( svgfile, width, height, NULL );
        
        if( THIS->pixbuf ) {
            RETVAL = 1;
        } else {
            RETVAL = 0;
        }
    OUTPUT:
        RETVAL


int
SVGLibRSVG::loadFromStringAtSize( svgfile, width, height, dpi=0 )
        char   * svgfile
        int      width
        int      height
        double   dpi
    CODE: 
        g_type_init ();
        
        if (dpi > 0.) {
            rsvg_set_default_dpi (dpi);
        }
        
        if( THIS->pixbuf ) {
            g_object_unref ( G_OBJECT (THIS->pixbuf) );
        }

        THIS->pixbuf = rsvg_pixbuf_from_chars_at_size( svgfile, width, height, NULL );
        
        if( THIS->pixbuf ) {
            RETVAL = 1;
        } else {
            RETVAL = 0;
        }
    OUTPUT:
        RETVAL

                
## -------------------------------------------------------
## -------------------------------------------------------

        

int
SVGLibRSVG::loadFromFileAtZoomWithMax( svgfile, x_zoom, y_zoom, width, height, dpi=0 )
        char   * svgfile
        double   x_zoom
        double   y_zoom
        int      width
        int      height
        double   dpi
    CODE: 
        GdkPixbuf *pixbuf;
        
        g_type_init ();
        
        if (dpi > 0.) {
            rsvg_set_default_dpi (dpi);
        }
        
        if( THIS->pixbuf ) {
            g_object_unref ( G_OBJECT (THIS->pixbuf) );
        }

        THIS->pixbuf = rsvg_pixbuf_from_file_at_zoom_with_max( svgfile, x_zoom, y_zoom, width, height, NULL );
        
        if( THIS->pixbuf ) {
            RETVAL = 1;
        } else {
            RETVAL = 0;
        }
    OUTPUT:
        RETVAL

int
SVGLibRSVG::loadFromStringAtZoomWithMax( svgfile, x_zoom, y_zoom, width, height, dpi=0 )
        char   * svgfile
        double   x_zoom
        double   y_zoom
        int      width
        int      height
        double   dpi
    CODE: 
        GdkPixbuf *pixbuf;
        
        g_type_init ();
        
        if (dpi > 0.) {
            rsvg_set_default_dpi (dpi);
        }
        
        if( THIS->pixbuf ) {
            g_object_unref ( G_OBJECT (THIS->pixbuf) );
        }

        THIS->pixbuf = rsvg_pixbuf_from_chars_at_zoom_with_max( svgfile, x_zoom, y_zoom, width, height, NULL );
        
        if( THIS->pixbuf ) {
            RETVAL = 1;
        } else {
            RETVAL = 0;
        }
    OUTPUT:
        RETVAL
        

## -------------------------------------------------------
## SAVE-FUNCTIONS
## -------------------------------------------------------
int
SVGLibRSVG::saveAs( bitmapfile, format="png", quality=100 )
        char * bitmapfile
        char * format
        int    quality
    CODE:
        if( THIS->pixbuf ) {
            RETVAL = save( quality, format, THIS->pixbuf, bitmapfile );
        } else {
            ## carp( "There's no image loaded into memory. Maybe you forgot to load or last loading returned with an error" );
            RETVAL = 0;
        }
    OUTPUT:
        RETVAL


        


## -------------------------------------------------------
## getImageBitmap
##    !!!! This is only available from GDK-PIXBUF 2.4 !!!!
## -------------------------------------------------------
#if GDK_PIXBUF_MAJOR > 2 || ( GDK_PIXBUF_MAJOR == 2 && GDK_PIXBUF_MINOR >= 4 )
SV * 
SVGLibRSVG::getImageBitmap( format="png", quality=100 )
        char * format
        int    quality
    CODE:
        GError *      my_error_p = NULL;
        gboolean      ret;
        gsize         buffer_size;
        gchar *       buffer;
        
        buffer_size = SVG_BUFFER_SIZE;
        
        char * quality_str;
        
        if (strcmp (format, "jpeg") != 0 || (quality < 1 || quality > 100)) 
        {
            if( ! gdk_pixbuf_save_to_buffer (THIS->pixbuf, &buffer, &buffer_size, format, &my_error_p, "tEXt::Software", "testpixbuf-save",NULL) ) {
                fprintf (stderr, "%s", my_error_p->message);
                g_error_free (my_error_p);
            } else {
                RETVAL = newSVpv( buffer, buffer_size );
                g_free( buffer );
            }
        }
        else 
        {
            quality_str = g_strdup_printf ("%d", quality);
            if( ! gdk_pixbuf_save_to_buffer (THIS->pixbuf, &buffer, &buffer_size, format, &my_error_p, "quality", quality_str, NULL) ) {
                fprintf (stderr, "%s", my_error_p->message);
                g_error_free (my_error_p);
            } else {
                RETVAL = newSVpv( buffer, buffer_size );
                g_free( buffer );
            }
            g_free (quality_str);
        }
    OUTPUT:
        RETVAL

#else
SV * 
SVGLibRSVG::getImageBitmap( format="png", quality=100 )
        char * format
        int    quality
    CODE:
        RETVAL = NULL;
    OUTPUT:
        RETVAL

#endif
