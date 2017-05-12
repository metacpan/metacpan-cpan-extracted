#include "goocanvas-perl.h"

MODULE = Goo::Canvas::Ellipse		PACKAGE = Goo::Canvas::Ellipse   PREFIX = goo_canvas_ellipse_

GooCanvasItem*
goo_canvas_ellipse_new(class, parent, center_x, center_y, radius_x, radius_y, ...)
    GooCanvasItem *parent
    gdouble center_x
    gdouble center_y
    gdouble radius_x
    gdouble radius_y
   CODE:
    RETVAL = goo_canvas_ellipse_new(parent, center_x, center_y, radius_x, radius_y, NULL);
    GOOCANVAS_PERL_ADD_PROPETIES(6);
   OUTPUT:
    RETVAL

MODULE = Goo::Canvas::Ellipse		PACKAGE = Goo::Canvas::EllipseModel   PREFIX = goo_canvas_ellipse_model_

GooCanvasItemModel*
goo_canvas_ellipse_model_new(class, parent, center_x, center_y, radius_x, radius_y, ...)
    GooCanvasItemModel *parent
    gdouble center_x
    gdouble center_y
    gdouble radius_x
    gdouble radius_y
   CODE:
    RETVAL = goo_canvas_ellipse_model_new(parent, center_x, center_y, radius_x, radius_y, NULL);
    GOOCANVAS_PERL_ADD_PROPETIES(6);
   OUTPUT:
    RETVAL

