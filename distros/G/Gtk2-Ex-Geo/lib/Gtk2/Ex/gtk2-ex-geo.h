#include <gtk2perl.h>
#include <cairo-perl.h>

typedef struct {

    /** cairo image, each pixel is 4 bytes XRGB (BGRX if little endian) */
    unsigned char *image;

    /** rowstride of the cairo image */
    int image_rowstride;

    /** pixbuf data, each pixel is 3 bytes RGB, freed in gtk2_ex_geo_pixbuf_destroy_notify */
    guchar *pixbuf;

    /** needed for gdk pixbuf */
    GdkPixbufDestroyNotify destroy_fn;

    /** needed for gdk pixbuf */
    GdkColorspace colorspace;

    /** needed for gdk pixbuf */
    gboolean has_alpha;

    /** needed for gdk pixbuf */
    int rowstride;
    
    /** needed for gdk pixbuf */
    int bits_per_sample;

    int width;
    int height;

    /** geographic world */
    double world_min_x;
    double world_max_y;

    /** size of pixel in geographic space */
    double pixel_size;

} gtk2_ex_geo_pixbuf;
