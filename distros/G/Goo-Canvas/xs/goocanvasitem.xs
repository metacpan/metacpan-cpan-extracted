#include "goocanvas-perl.h"

MODULE = Goo::Canvas::Item		PACKAGE = Goo::Canvas::Item   PREFIX = goo_canvas_item_

GooCanvas*
goo_canvas_item_get_canvas(item)
    GooCanvasItem *item

void
goo_canvas_item_set_canvas(item, canvas)
    GooCanvasItem *item
    GooCanvas *canvas

GooCanvasItem*
goo_canvas_item_get_parent(item)
    GooCanvasItem *item

void
goo_canvas_item_set_parent(item, parent)
    GooCanvasItem *item
    GooCanvasItem *parent

GooCanvasItemModel*
goo_canvas_item_get_model(item)
    GooCanvasItem *item

void
goo_canvas_item_set_model(item, model)
    GooCanvasItem *item
    GooCanvasItemModel *model

gboolean
goo_canvas_item_is_container(item)
    GooCanvasItem *item

gint
goo_canvas_item_get_n_children(item)
    GooCanvasItem *item

GooCanvasItem*
goo_canvas_item_get_child(item, child_num)
    GooCanvasItem *item
    gint child_num

gint
goo_canvas_item_find_child(item, child)
    GooCanvasItem *item
    GooCanvasItem *child

void
goo_canvas_item_add_child(item, child, position)
    GooCanvasItem *item
    GooCanvasItem *child
    gint position

void
goo_canvas_item_move_child(item, old_position, new_position)
    GooCanvasItem *item
    gint old_position
    gint new_position

void
goo_canvas_item_remove_child(item, child_num)
    GooCanvasItem *item
    gint child_num

gboolean
goo_canvas_item_get_transform_for_child(item, child, transform)
    GooCanvasItem *item
    GooCanvasItem *child
    cairo_matrix_t *transform

void
goo_canvas_item_raise(item, ...)
    GooCanvasItem *item
   CODE:
    if ( items == 1 )
        goo_canvas_item_raise(item, NULL);
    else
        goo_canvas_item_raise(item, SvGooCanvasItem (ST(1)));

void
goo_canvas_item_lower(item, ...)
    GooCanvasItem *item
   CODE:
    if ( items == 1 )
       goo_canvas_item_lower(item, NULL);
    else
       goo_canvas_item_lower(item, SvGooCanvasItem (ST(1)));

void
goo_canvas_item_get_transform(item)
    GooCanvasItem *item
   PREINIT:
    gboolean ret;
    cairo_matrix_t *transform;
   PPCODE:
    ret = goo_canvas_item_get_transform(item, transform);
    if ( ret ) {
        ST(0) = newSVCairoMatrix (transform);
        sv_2mortal(ST(0));
    }
    else {
        XSRETURN_UNDEF;
    }

void
goo_canvas_item_set_transform(item, matrix)
    GooCanvasItem *item
    cairo_matrix_t *matrix

void
goo_canvas_item_set_simple_transform(item, x, y, scale, rotation)
    GooCanvasItem *item
    gdouble x
    gdouble y
    gdouble scale
    gdouble rotation

void
goo_canvas_item_translate(item, tx, ty)
    GooCanvasItem *item
    gdouble tx
    gdouble ty

void
goo_canvas_item_scale(item, sx, sy)
    GooCanvasItem *item
    gdouble sx
    gdouble sy

void
goo_canvas_item_rotate(item, degrees, cx, cy)
    GooCanvasItem *item
    gdouble degrees
    gdouble cx
    gdouble cy

void
goo_canvas_item_skew_x(item, degrees, cx, cy)
    GooCanvasItem *item
    gdouble degrees
    gdouble cx
    gdouble cy

void
goo_canvas_item_skew_y(item, degrees, cx, cy)
    GooCanvasItem *item
    gdouble degrees
    gdouble cx
    gdouble cy

GooCanvasStyle*
goo_canvas_item_get_style(item)
    GooCanvasItem *item

void
goo_canvas_item_set_style(item, style)
    GooCanvasItem *item
    GooCanvasStyle *style

void
goo_canvas_item_animate(item, x, y, scale, degrees, absolute, duration, step_time, type)
    GooCanvasItem *item
    gdouble x
    gdouble y
    gdouble scale
    gdouble degrees
    gboolean absolute
    gint duration
    gint step_time
    GooCanvasAnimateType type

void
goo_canvas_item_stop_animation(item)
    GooCanvasItem *item

void
goo_canvas_item_request_update(item)
    GooCanvasItem *item

void
goo_canvas_item_ensure_updated(item)
    GooCanvasItem *item

GooCanvasBounds *
goo_canvas_item_update(item, entire_tree, cr)
    GooCanvasItem *item
    gboolean entire_tree
    cairo_t *cr
   CODE:
    Newx(RETVAL, 1, GooCanvasBounds);
    goo_canvas_item_update(item, entire_tree, cr, RETVAL);
   OUTPUT:
    RETVAL

GooCanvasBounds *
goo_canvas_item_get_requested_area(item, cr)
    GooCanvasItem *item
    cairo_t *cr
   PREINIT:
    gboolean ret;
   CODE:
    Newx(RETVAL, 1, GooCanvasBounds);
    ret = goo_canvas_item_get_requested_area(item, cr, RETVAL);
    if ( !ret ) {
        Safefree(RETVAL);
        RETVAL = NULL;
    }
   OUTPUT:
    RETVAL

void
goo_canvas_item_allocate_area(item, cr, requested_area, allocated_area, x_offset, y_offset)
    GooCanvasItem *item
    cairo_t *cr
    GooCanvasBounds *requested_area
    GooCanvasBounds *allocated_area
    gdouble x_offset
    gdouble y_offset

GooCanvasBounds*
goo_canvas_item_get_bounds(item)
    GooCanvasItem *item
   CODE:
    Newx(RETVAL, 1, GooCanvasBounds);
    goo_canvas_item_get_bounds(item, RETVAL);
   OUTPUT:
    RETVAL
    
AV*
goo_canvas_item_get_items_at(item, x, y, cr, is_pointer_event, parent_is_visible)
    GooCanvasItem *item
    gdouble x
    gdouble y
    cairo_t *cr
    gboolean is_pointer_event
    gboolean parent_is_visible
  PREINIT:
    GList *list, *i;
  CODE:
    list = goo_canvas_item_get_items_at(item, x, y, cr, is_pointer_event, parent_is_visible, NULL);
    RETVAL = newAV();
    for ( i = list; i != NULL; i = i->next ) {
        av_push(RETVAL, newSVGooCanvasItem((GooCanvasItem*)i->data));
    }
    sv_2mortal((SV*)RETVAL);
  OUTPUT:
    RETVAL
  CLEANUP:
    g_list_free (list);
    
gboolean
goo_canvas_item_is_visible(item)
    GooCanvasItem *item

void
goo_canvas_item_paint(item, cr, bounds, scale)
    GooCanvasItem *item
    cairo_t *cr
    GooCanvasBounds *bounds
    gdouble scale

void
goo_canvas_item_set_child_properties(item, child, ...)
    GooCanvasItem *item
    GooCanvasItem *child
   PREINIT:
    GParamSpec *pspec;
    GValue value = {0,};
    int i;
   CODE:
    if ( 0 != items % 2 )
        croak ("set_child_properties: expects name => value pairs"
               "(odd number of arguments detected)");
    for ( i = 2; i < items; i+= 2 ) {
        char* name = SvPV_nolen(ST(i));
        SV *newval = ST(i+1);
        pspec = goo_canvas_item_class_find_child_property(
            (GObjectClass*)g_type_class_peek(G_OBJECT_TYPE (G_OBJECT(item))),  name);
        if ( !pspec ) {
            const char* classname =
                gperl_object_package_from_type(G_OBJECT_TYPE (G_OBJECT(item)));
            if ( !classname )
                classname = G_OBJECT_TYPE_NAME(G_OBJECT(item)); 
            croak("type %s does not support property '%s'",
                  classname, name);
        }
        g_value_init (&value, G_PARAM_SPEC_VALUE_TYPE (pspec));
        gperl_value_from_sv (&value, newval);                     
        if ( G_IS_PARAM_SPEC_BOOLEAN(pspec) ) {
            goo_canvas_item_set_child_properties(item, child, name, g_value_get_boolean(&value), NULL);
        } else if ( G_IS_PARAM_SPEC_CHAR(pspec) ) {
            goo_canvas_item_set_child_properties(item, child, name, g_value_get_char(&value), NULL);
        } else if ( G_IS_PARAM_SPEC_UCHAR(pspec) ) {
            goo_canvas_item_set_child_properties(item, child, name, g_value_get_uchar(&value), NULL);
        } else if ( G_IS_PARAM_SPEC_INT(pspec) ) {
            goo_canvas_item_set_child_properties(item, child, name, g_value_get_int(&value), NULL);
        } else if ( G_IS_PARAM_SPEC_UINT(pspec) ) {
            goo_canvas_item_set_child_properties(item, child, name, g_value_get_uint(&value), NULL);
        } else if ( G_IS_PARAM_SPEC_LONG(pspec) ) {
            goo_canvas_item_set_child_properties(item, child, name, g_value_get_long(&value), NULL);
        } else if ( G_IS_PARAM_SPEC_ULONG(pspec) ) {
            goo_canvas_item_set_child_properties(item, child, name, g_value_get_ulong(&value), NULL);
        } else if ( G_IS_PARAM_SPEC_INT64(pspec) ) {
            goo_canvas_item_set_child_properties(item, child, name, g_value_get_int64(&value), NULL);
        } else if ( G_IS_PARAM_SPEC_UINT64(pspec) ) {
            goo_canvas_item_set_child_properties(item, child, name, g_value_get_uint64(&value), NULL);
        } else if ( G_IS_PARAM_SPEC_FLOAT(pspec) ) {
            goo_canvas_item_set_child_properties(item, child, name, g_value_get_float(&value), NULL);
        } else if ( G_IS_PARAM_SPEC_DOUBLE(pspec) ) {
            goo_canvas_item_set_child_properties(item, child, name, g_value_get_double(&value), NULL);
        } else if ( G_IS_PARAM_SPEC_ENUM(pspec) ) {
            goo_canvas_item_set_child_properties(item, child, name, g_value_get_enum(&value), NULL);
        } else if ( G_IS_PARAM_SPEC_FLAGS(pspec) ) {
            goo_canvas_item_set_child_properties(item, child, name, g_value_get_flags(&value), NULL);
        } else if ( G_IS_PARAM_SPEC_STRING(pspec) ) {
            goo_canvas_item_set_child_properties(item, child, name, g_value_get_string(&value), NULL);
        } else if ( G_IS_PARAM_SPEC_PARAM(pspec) ) {
            goo_canvas_item_set_child_properties(item, child, name, g_value_get_param(&value), NULL);
        } else if ( G_IS_PARAM_SPEC_BOXED(pspec) ) {
            goo_canvas_item_set_child_properties(item, child, name, g_value_get_boxed(&value), NULL);
        } else if ( G_IS_PARAM_SPEC_POINTER(pspec) ) {
            goo_canvas_item_set_child_properties(item, child, name, g_value_get_pointer(&value), NULL);
        } else if ( G_IS_PARAM_SPEC_OBJECT(pspec) ) {
            goo_canvas_item_set_child_properties(item, child, name, g_value_get_object(&value), NULL);
        } else if ( G_IS_PARAM_SPEC_UNICHAR(pspec) ) {
            goo_canvas_item_set_child_properties(item, child, name, g_value_get_uint(&value), NULL);
        } else if ( G_IS_PARAM_SPEC_VALUE_ARRAY(pspec) ) {
            goo_canvas_item_set_child_properties(item, child, name, g_value_get_boxed(&value), NULL);
        } else if ( G_IS_PARAM_SPEC_GTYPE(pspec) ) {
            goo_canvas_item_set_child_properties(item, child, name, g_value_get_gtype(&value), NULL);
        }
        g_value_unset (&value);
    }

=for apidoc
Not like the original C function, which call as
goo_canvas_item_get_child_properties(item, child, key1, &val1, key2,
&val2, ..., NULL). This function call as
$item->get_child_properties($child, $key1, $key2, ...) and return a list
($key1, $val1, $key2, $val2, ...) instead. So you can call like
%pair = $item->get_child_properties($child, $key1, $key2) and use $pair{$key1} and $pair{$key2} to access the value for the property.
=cut
void
goo_canvas_item_get_child_properties(item, child, ...)
    GooCanvasItem *item
    GooCanvasItem *child
   PREINIT:
    GParamSpec *pspec;
    GValue value = {0,};
    int i;
   PPCODE:
    for ( i = 2; i < items; i++ ) {
        char* name = SvPV_nolen(ST(i));
        SV* pval;
        pspec = goo_canvas_item_class_find_child_property(
            (GObjectClass*)g_type_class_peek(G_OBJECT_TYPE (G_OBJECT(item))),  name);
        if ( !pspec ) {
            const char* classname =
                gperl_object_package_from_type(G_OBJECT_TYPE (G_OBJECT(item)));
            if ( !classname )
                classname = G_OBJECT_TYPE_NAME(G_OBJECT(item)); 
            croak("type %s does not support property '%s'",
                  classname, name);
        }
        g_value_init (&value, G_PARAM_SPEC_VALUE_TYPE (pspec));
        if ( G_IS_PARAM_SPEC_BOOLEAN(pspec) ) {
           gboolean val;
           goo_canvas_item_get_child_properties(item, child, name, &val, NULL);
           g_value_set_boolean(&value, val);
        } else if ( G_IS_PARAM_SPEC_CHAR(pspec) ) {
           gchar val;
           goo_canvas_item_get_child_properties(item, child, name, &val, NULL);
           g_value_set_char(&value, val);
        } else if ( G_IS_PARAM_SPEC_UCHAR(pspec) ) {
           guchar val;
           goo_canvas_item_get_child_properties(item, child, name, &val, NULL);
           g_value_set_uchar(&value, val);
        } else if ( G_IS_PARAM_SPEC_INT(pspec) ) {
           gint val;
           goo_canvas_item_get_child_properties(item, child, name, &val, NULL);
           g_value_set_int(&value, val);
        } else if ( G_IS_PARAM_SPEC_UINT(pspec) ) {
           guint val;
           goo_canvas_item_get_child_properties(item, child, name, &val, NULL);
           g_value_set_uint(&value, val);
        } else if ( G_IS_PARAM_SPEC_LONG(pspec) ) {
           glong val;
           goo_canvas_item_get_child_properties(item, child, name, &val, NULL);
           g_value_set_long(&value, val);
        } else if ( G_IS_PARAM_SPEC_ULONG(pspec) ) {
           gulong val;
           goo_canvas_item_get_child_properties(item, child, name, &val, NULL);
           g_value_set_ulong(&value, val);
        } else if ( G_IS_PARAM_SPEC_INT64(pspec) ) {
           gint64 val;
           goo_canvas_item_get_child_properties(item, child, name, &val, NULL);
           g_value_set_int64(&value, val);
        } else if ( G_IS_PARAM_SPEC_UINT64(pspec) ) {
           guint64 val;
           goo_canvas_item_get_child_properties(item, child, name, &val, NULL);
           g_value_set_uint64(&value, val);
        } else if ( G_IS_PARAM_SPEC_FLOAT(pspec) ) {
           gfloat val;
           goo_canvas_item_get_child_properties(item, child, name, &val, NULL);
           g_value_set_float(&value, val);
        } else if ( G_IS_PARAM_SPEC_DOUBLE(pspec) ) {
           gdouble val;
           goo_canvas_item_get_child_properties(item, child, name, &val, NULL);
           g_value_set_double(&value, val);
        } else if ( G_IS_PARAM_SPEC_ENUM(pspec) ) {
           gint val;
           goo_canvas_item_get_child_properties(item, child, name, &val, NULL);
           g_value_set_enum(&value, val);
        } else if ( G_IS_PARAM_SPEC_FLAGS(pspec) ) {
           guint val;
           goo_canvas_item_get_child_properties(item, child, name, &val, NULL);
           g_value_set_flags(&value, val);
        } else if ( G_IS_PARAM_SPEC_STRING(pspec) ) {
           gchar* val;
           goo_canvas_item_get_child_properties(item, child, name, &val, NULL);
           g_value_set_string(&value, val);
        } else if ( G_IS_PARAM_SPEC_PARAM(pspec) ) {
           GParamSpec* val;
           goo_canvas_item_get_child_properties(item, child, name, &val, NULL);
           g_value_set_param(&value, val);
        } else if ( G_IS_PARAM_SPEC_BOXED(pspec) ) {
           gpointer val;
           goo_canvas_item_get_child_properties(item, child, name, &val, NULL);
           g_value_set_boxed(&value, val);
        } else if ( G_IS_PARAM_SPEC_POINTER(pspec) ) {
           gpointer val;
           goo_canvas_item_get_child_properties(item, child, name, &val, NULL);
           g_value_set_pointer(&value, val);
        } else if ( G_IS_PARAM_SPEC_OBJECT(pspec) ) {
           gpointer val;
           goo_canvas_item_get_child_properties(item, child, name, &val, NULL);
           g_value_set_object(&value, val);
        } else if ( G_IS_PARAM_SPEC_UNICHAR(pspec) ) {
           guint val;
           goo_canvas_item_get_child_properties(item, child, name, &val, NULL);
           g_value_set_uint(&value, val);
        } else if ( G_IS_PARAM_SPEC_VALUE_ARRAY(pspec) ) {
           gpointer val;
           goo_canvas_item_get_child_properties(item, child, name, &val, NULL);
           g_value_set_boxed(&value, val);
        } else if ( G_IS_PARAM_SPEC_GTYPE(pspec) ) {
           GType val;
           goo_canvas_item_get_child_properties(item, child, name, &val, NULL);
           g_value_set_gtype(&value, val);
        }
        pval = gperl_sv_from_value(&value);
        g_value_unset (&value);
        mXPUSHp(name, strlen(name));
        XPUSHs(pval);
    }
