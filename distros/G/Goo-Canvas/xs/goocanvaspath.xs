#include "goocanvas-perl.h"

MODULE = Goo::Canvas::Path		PACKAGE = Goo::Canvas::Path   PREFIX = goo_canvas_path_

GooCanvasItem*
goo_canvas_path_new(class, parent, path_data, ...)
    GooCanvasItem *parent
    const gchar *path_data
   CODE:
    RETVAL = goo_canvas_path_new(parent, path_data, NULL);
    GOOCANVAS_PERL_ADD_PROPETIES(3);
   OUTPUT:
    RETVAL

MODULE = Goo::Canvas::Path		PACKAGE = Goo::Canvas::PathModel   PREFIX = goo_canvas_path_model_

GooCanvasItemModel*
goo_canvas_path_model_new(class, parent, path_data, ...)
    GooCanvasItemModel *parent
    const gchar *path_data
   CODE:
    RETVAL = goo_canvas_path_model_new(parent, path_data, NULL);
    GOOCANVAS_PERL_ADD_PROPETIES(3);
   OUTPUT:
    RETVAL
