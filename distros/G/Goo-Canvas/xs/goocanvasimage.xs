#include "goocanvas-perl.h"

MODULE = Goo::Canvas::Image		PACKAGE = Goo::Canvas::Image   PREFIX = goo_canvas_image_

GooCanvasItem*
goo_canvas_image_new(class, parent, pixbuf, x, y, ...)
    GooCanvasItem *parent
    gdouble x
    gdouble y
   CODE:
    if ( SvTRUE( ST(2) ) )
        RETVAL = goo_canvas_image_new(parent, SvGdkPixbuf (ST(2)), x, y, NULL);
    else
        RETVAL = goo_canvas_image_new(parent, NULL, x, y, NULL);
    GOOCANVAS_PERL_ADD_PROPETIES(5);
   OUTPUT:
    RETVAL

MODULE = Goo::Canvas::Image		PACKAGE = Goo::Canvas::ImageModel   PREFIX = goo_canvas_image_model_

GooCanvasItemModel*
goo_canvas_image_model_new(class, parent, pixbuf, x, y, ...)
    GooCanvasItemModel *parent
    gdouble x
    gdouble y
   CODE:
    if ( SvTRUE( ST(2) ) )
        RETVAL = goo_canvas_image_model_new(parent, SvGdkPixbuf (ST(2)), x, y, NULL);
    else
        RETVAL = goo_canvas_image_model_new(parent, NULL, x, y, NULL);
    GOOCANVAS_PERL_ADD_PROPETIES(5);
   OUTPUT:
    RETVAL

