#include "goocanvas-perl.h"

MODULE = Goo::Canvas::Table		PACKAGE = Goo::Canvas::Table   PREFIX = goo_canvas_table_

GooCanvasItem*
goo_canvas_table_new(class, parent, ...)
    GooCanvasItem *parent
   CODE:
    RETVAL = goo_canvas_table_new(parent, NULL);
    GOOCANVAS_PERL_ADD_PROPETIES(2);
   OUTPUT:
    RETVAL

MODULE = Goo::Canvas::Table		PACKAGE = Goo::Canvas::TableModel   PREFIX = goo_canvas_table_model_

GooCanvasItemModel*
goo_canvas_table_model_new(class, parent, ...)
    GooCanvasItemModel *parent
   CODE:
    RETVAL = goo_canvas_table_model_new(parent, NULL);
    GOOCANVAS_PERL_ADD_PROPETIES(2);
   OUTPUT:
    RETVAL
