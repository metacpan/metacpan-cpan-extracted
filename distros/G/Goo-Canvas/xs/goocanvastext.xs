#include "goocanvas-perl.h"

MODULE = Goo::Canvas::Text		PACKAGE = Goo::Canvas::Text   PREFIX = goo_canvas_text_

GooCanvasItem*
goo_canvas_text_new(class, parent, string, x, y, width, anchor, ...)
    GooCanvasItem *parent
    const char *string
    gdouble x
    gdouble y
    gdouble width
    GtkAnchorType anchor
   CODE:
    RETVAL = goo_canvas_text_new(parent, string, x, y, width, anchor, NULL);
    GOOCANVAS_PERL_ADD_PROPETIES(7);
   OUTPUT:
    RETVAL

MODULE = Goo::Canvas::Text		PACKAGE = Goo::Canvas::TextModel   PREFIX = goo_canvas_text_model_

GooCanvasItemModel*
goo_canvas_text_model_new(class, parent, string, x, y, width, anchor, ...)
    GooCanvasItemModel *parent
    const char *string
    gdouble x
    gdouble y
    gdouble width
    GtkAnchorType anchor
   CODE:
    RETVAL = goo_canvas_text_model_new(parent, string, x, y, width, anchor, NULL);
    GOOCANVAS_PERL_ADD_PROPETIES(7);
   OUTPUT:
    RETVAL
