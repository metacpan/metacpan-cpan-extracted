#include "goocanvas-perl.h"

MODULE = Goo::Canvas::Widget		PACKAGE = Goo::Canvas::Widget   PREFIX = goo_canvas_widget_

GooCanvasItem*
goo_canvas_widget_new(class, parent, widget, x, y, width, height, ...)
    GooCanvasItem *parent
    GtkWidget *widget
    gdouble x
    gdouble y
    gdouble width
    gdouble height
   CODE:
    RETVAL = goo_canvas_widget_new(parent, widget, x, y, width, height, NULL);
    GOOCANVAS_PERL_ADD_PROPETIES(7);
   OUTPUT:
    RETVAL
