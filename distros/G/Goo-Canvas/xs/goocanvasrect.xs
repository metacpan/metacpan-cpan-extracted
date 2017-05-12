#include "goocanvas-perl.h"

MODULE = Goo::Canvas::Rect		PACKAGE = Goo::Canvas::Rect   PREFIX = goo_canvas_rect_

GooCanvasItem*
goo_canvas_rect_new(class, parent, x, y, width, height, ...)
    GooCanvasItem *parent
    gdouble x
    gdouble y
    gdouble width
    gdouble height
   CODE:
    RETVAL = goo_canvas_rect_new(parent, x, y, width, height, NULL);
    GOOCANVAS_PERL_ADD_PROPETIES(6);
   OUTPUT:
     RETVAL
        
MODULE = Goo::Canvas::Rect		PACKAGE = Goo::Canvas::RectModel   PREFIX = goo_canvas_rect_model_

GooCanvasItemModel*
goo_canvas_rect_model_new(class, parent, x, y, width, height, ...)
    GooCanvasItemModel *parent
    gdouble x
    gdouble y
    gdouble width
    gdouble height
   CODE:
    RETVAL = goo_canvas_rect_model_new(parent, x, y, width, height, NULL);
    GOOCANVAS_PERL_ADD_PROPETIES(6);
   OUTPUT:
    RETVAL
