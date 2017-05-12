#include "goocanvas-perl.h"

MODULE = Goo::Canvas::Group		PACKAGE = Goo::Canvas::Group   PREFIX = goo_canvas_group_

GooCanvasItem*
goo_canvas_group_new(class, ...)
   PREINIT:
    GooCanvasItem *parent;
   CODE:
    if ( items == 1 || !sv_true(ST(1)) )
        RETVAL = goo_canvas_group_new(NULL, NULL);
    else {
        parent = SvGooCanvasItem (ST(1));
        RETVAL = goo_canvas_group_new(parent, NULL);
        GOOCANVAS_PERL_ADD_PROPETIES(2);
    }
   OUTPUT:
    RETVAL

MODULE = Goo::Canvas::Group		PACKAGE = Goo::Canvas::GroupModel   PREFIX = goo_canvas_group_model_

GooCanvasItemModel*
goo_canvas_group_model_new(class, ...)
   PREINIT:
    GooCanvasItemModel *parent;
   CODE:
    if ( items == 1 || !sv_true(ST(1)) )
        RETVAL = goo_canvas_group_model_new(NULL, NULL);
    else {
        parent = SvGooCanvasItemModel (ST(1));
        RETVAL = goo_canvas_group_model_new(parent, NULL);
        GOOCANVAS_PERL_ADD_PROPETIES(2);
    }
   OUTPUT:
    RETVAL

