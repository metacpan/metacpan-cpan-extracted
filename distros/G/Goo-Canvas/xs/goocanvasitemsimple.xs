#include "goocanvas-perl.h"

MODULE = Goo::Canvas::ItemSimple		PACKAGE = Goo::Canvas::ItemSimple   PREFIX = goo_canvas_itemsimple_

void
goo_canvas_item_simple_check_style(item)
    GooCanvasItemSimple *item

GooCanvasBounds*
goo_canvas_item_simple_get_path_bounds(item, cr)
    GooCanvasItemSimple *item
    cairo_t *cr
   CODE:
    Newx(RETVAL, 1, GooCanvasBounds);
    goo_canvas_item_simple_get_path_bounds(item, cr, RETVAL);
   OUTPUT:
    RETVAL

GooCanvasBounds*
goo_canvas_item_simple_user_bounds_to_device(item, cr)
    GooCanvasItemSimple *item
    cairo_t *cr
   CODE:
    Newx(RETVAL, 1, GooCanvasBounds);
    goo_canvas_item_simple_user_bounds_to_device(item, cr, RETVAL);
   OUTPUT:
    RETVAL

GooCanvasBounds*
goo_canvas_item_simple_user_bounds_to_parent(item, cr)
    GooCanvasItemSimple *item
    cairo_t *cr
   CODE:
    Newx(RETVAL, 1, GooCanvasBounds);
    goo_canvas_item_simple_user_bounds_to_parent(item, cr, RETVAL);
   OUTPUT:
    RETVAL

gboolean
goo_canvas_item_simple_check_in_path (item, x, y, cr, pointer_events)
    GooCanvasItemSimple *item
    gdouble x
    gdouble y
    cairo_t *cr
    GooCanvasPointerEvents pointer_events

void
goo_canvas_item_simple_paint_path(item, cr)
    GooCanvasItemSimple *item
    cairo_t *cr

void
goo_canvas_item_simple_changed(item, recompute_bounds)
    GooCanvasItemSimple *item
    gboolean recompute_bounds

void
goo_canvas_item_simple_set_model(item, model)
    GooCanvasItemSimple *item
    GooCanvasItemModel *model
