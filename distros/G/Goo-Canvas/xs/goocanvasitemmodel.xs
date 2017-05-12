#include "goocanvas-perl.h"

MODULE = Goo::Canvas::ItemModel		PACKAGE = Goo::Canvas::ItemModel   PREFIX = goo_canvas_item_model_

GooCanvasItemModel*
goo_canvas_item_model_get_parent(model)
    GooCanvasItemModel *model

void
goo_canvas_item_model_set_parent(model, parent)
    GooCanvasItemModel *model
    GooCanvasItemModel *parent

gboolean
goo_canvas_item_model_is_container(model)
    GooCanvasItemModel *model

gint
goo_canvas_item_model_get_n_children(model)
    GooCanvasItemModel *model

GooCanvasItemModel*
goo_canvas_item_model_get_child(model, child_num)
    GooCanvasItemModel *model
    gint child_num

void
goo_canvas_item_model_add_child(model, child, position)
    GooCanvasItemModel *model
    GooCanvasItemModel *child
    gint position

void
goo_canvas_item_model_move_child(model, old_position, new_position)
    GooCanvasItemModel *model
    gint old_position
    gint new_position

void
goo_canvas_item_model_remove_child(model, child_num)
    GooCanvasItemModel *model
    gint child_num

gint
goo_canvas_item_model_find_child(model, child)
    GooCanvasItemModel *model
    GooCanvasItemModel *child

void
goo_canvas_item_model_raise(item, ...)
    GooCanvasItemModel *item
   CODE:
    if ( items == 1 )
        goo_canvas_item_model_raise(item, NULL);
    else
        goo_canvas_item_model_raise(item, SvGooCanvasItemModel (ST(1)));

void
goo_canvas_item_model_lower(item, ...)
    GooCanvasItemModel *item
   CODE:
    if ( items == 1 )
       goo_canvas_item_model_lower(item, NULL);
    else
       goo_canvas_item_model_lower(item, SvGooCanvasItemModel (ST(1)));


void
goo_canvas_item_model_get_transform(item)
    GooCanvasItemModel *item
   PREINIT:
    gboolean ret;
    cairo_matrix_t *transform;
   PPCODE:
    ret = goo_canvas_item_model_get_transform(item, transform);
    if ( ret ) {
        ST(0) = newSVCairoMatrix (transform);
        sv_2mortal(ST(0));
    }
    else {
        XSRETURN_UNDEF;
    }

void
goo_canvas_item_model_set_transform(model, matrix)
    GooCanvasItemModel *model
    cairo_matrix_t *matrix

void
goo_canvas_item_model_set_simple_transform(model, x, y, scale, rotation)
    GooCanvasItemModel *model
    gdouble x
    gdouble y
    gdouble scale
    gdouble rotation

void
goo_canvas_item_model_translate(model, tx, ty)
    GooCanvasItemModel *model
    gdouble tx
    gdouble ty

void
goo_canvas_item_model_scale(model, sx, sy)
    GooCanvasItemModel *model
    gdouble sx
    gdouble sy

void
goo_canvas_item_model_rotate(model, degrees, cx, cy)
    GooCanvasItemModel *model
    gdouble degrees
    gdouble cx
    gdouble cy

void
goo_canvas_item_model_skew_x(model, degrees, cx, cy)
    GooCanvasItemModel *model
    gdouble degrees
    gdouble cx
    gdouble cy

void
goo_canvas_item_model_skew_y(model, degrees, cx, cy)
    GooCanvasItemModel *model
    gdouble degrees
    gdouble cx
    gdouble cy

GooCanvasStyle*
goo_canvas_item_model_get_style(model)
    GooCanvasItemModel *model

void
goo_canvas_item_model_set_style(model, style)
    GooCanvasItemModel *model
    GooCanvasStyle *style

void
goo_canvas_item_model_animate(model, x, y, scale, degrees, absolute, duration, step_time, type)
    GooCanvasItemModel *model
    gdouble x
    gdouble y
    gdouble scale
    gdouble degrees
    gboolean absolute
    gint duration
    gint step_time
    GooCanvasAnimateType type

void
goo_canvas_item_model_stop_animation(model)
    GooCanvasItemModel *model

void
goo_canvas_item_model_set_child_properties(model, child, ...)
    GooCanvasItemModel *model
    GooCanvasItemModel *child
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
        pspec = goo_canvas_item_model_class_find_child_property(
            (GObjectClass*)g_type_class_peek(G_OBJECT_TYPE (G_OBJECT(model))),  name);
        if ( !pspec ) {
            const char* classname =
                gperl_object_package_from_type(G_OBJECT_TYPE (G_OBJECT(model)));
            if ( !classname )
                classname = G_OBJECT_TYPE_NAME(G_OBJECT(model)); 
            croak("type %s does not support property '%s'",
                  classname, name);
        }
        g_value_init (&value, G_PARAM_SPEC_VALUE_TYPE (pspec));
        gperl_value_from_sv (&value, newval);                     
        if ( G_IS_PARAM_SPEC_BOOLEAN(pspec) ) {
            goo_canvas_item_model_set_child_properties(model, child, name, g_value_get_boolean(&value), NULL);
        } else if ( G_IS_PARAM_SPEC_CHAR(pspec) ) {
            goo_canvas_item_model_set_child_properties(model, child, name, g_value_get_char(&value), NULL);
        } else if ( G_IS_PARAM_SPEC_UCHAR(pspec) ) {
            goo_canvas_item_model_set_child_properties(model, child, name, g_value_get_uchar(&value), NULL);
        } else if ( G_IS_PARAM_SPEC_INT(pspec) ) {
            goo_canvas_item_model_set_child_properties(model, child, name, g_value_get_int(&value), NULL);
        } else if ( G_IS_PARAM_SPEC_UINT(pspec) ) {
            goo_canvas_item_model_set_child_properties(model, child, name, g_value_get_uint(&value), NULL);
        } else if ( G_IS_PARAM_SPEC_LONG(pspec) ) {
            goo_canvas_item_model_set_child_properties(model, child, name, g_value_get_long(&value), NULL);
        } else if ( G_IS_PARAM_SPEC_ULONG(pspec) ) {
            goo_canvas_item_model_set_child_properties(model, child, name, g_value_get_ulong(&value), NULL);
        } else if ( G_IS_PARAM_SPEC_INT64(pspec) ) {
            goo_canvas_item_model_set_child_properties(model, child, name, g_value_get_int64(&value), NULL);
        } else if ( G_IS_PARAM_SPEC_UINT64(pspec) ) {
            goo_canvas_item_model_set_child_properties(model, child, name, g_value_get_uint64(&value), NULL);
        } else if ( G_IS_PARAM_SPEC_FLOAT(pspec) ) {
            goo_canvas_item_model_set_child_properties(model, child, name, g_value_get_float(&value), NULL);
        } else if ( G_IS_PARAM_SPEC_DOUBLE(pspec) ) {
            goo_canvas_item_model_set_child_properties(model, child, name, g_value_get_double(&value), NULL);
        } else if ( G_IS_PARAM_SPEC_ENUM(pspec) ) {
            goo_canvas_item_model_set_child_properties(model, child, name, g_value_get_enum(&value), NULL);
        } else if ( G_IS_PARAM_SPEC_FLAGS(pspec) ) {
            goo_canvas_item_model_set_child_properties(model, child, name, g_value_get_flags(&value), NULL);
        } else if ( G_IS_PARAM_SPEC_STRING(pspec) ) {
            goo_canvas_item_model_set_child_properties(model, child, name, g_value_get_string(&value), NULL);
        } else if ( G_IS_PARAM_SPEC_PARAM(pspec) ) {
            goo_canvas_item_model_set_child_properties(model, child, name, g_value_get_param(&value), NULL);
        } else if ( G_IS_PARAM_SPEC_BOXED(pspec) ) {
            goo_canvas_item_model_set_child_properties(model, child, name, g_value_get_boxed(&value), NULL);
        } else if ( G_IS_PARAM_SPEC_POINTER(pspec) ) {
            goo_canvas_item_model_set_child_properties(model, child, name, g_value_get_pointer(&value), NULL);
        } else if ( G_IS_PARAM_SPEC_OBJECT(pspec) ) {
            goo_canvas_item_model_set_child_properties(model, child, name, g_value_get_object(&value), NULL);
        } else if ( G_IS_PARAM_SPEC_UNICHAR(pspec) ) {
            goo_canvas_item_model_set_child_properties(model, child, name, g_value_get_uint(&value), NULL);
        } else if ( G_IS_PARAM_SPEC_VALUE_ARRAY(pspec) ) {
            goo_canvas_item_model_set_child_properties(model, child, name, g_value_get_boxed(&value), NULL);
        } else if ( G_IS_PARAM_SPEC_GTYPE(pspec) ) {
            goo_canvas_item_model_set_child_properties(model, child, name, g_value_get_gtype(&value), NULL);
        }
        g_value_unset (&value);
    }

=for apidoc
Not like the original C function, which call as
goo_canvas_item_model_get_child_properties(model, child, key1, &val1, key2,
&val2, ..., NULL). This function call as
$model->get_child_properties($child, $key1, $key2, ...) and return a list
($key1, $val1, $key2, $val2, ...) instead. So you can call like
%pair = $model->get_child_properties($child, $key1, $key2) and use $pair{$key1} and $pair{$key2} to access the value for the property.
=cut
void
goo_canvas_item_model_get_child_properties(model, child, ...)
    GooCanvasItemModel *model
    GooCanvasItemModel *child
   PREINIT:
    GParamSpec *pspec;
    GValue value = {0,};
    int i;
   PPCODE:
    for ( i = 2; i < items; i++ ) {
        char* name = SvPV_nolen(ST(i));
        SV* pval;
        pspec = goo_canvas_item_model_class_find_child_property(
            (GObjectClass*)g_type_class_peek(G_OBJECT_TYPE (G_OBJECT(model))),  name);
        if ( !pspec ) {
            const char* classname =
                gperl_object_package_from_type(G_OBJECT_TYPE (G_OBJECT(model)));
            if ( !classname )
                classname = G_OBJECT_TYPE_NAME(G_OBJECT(model)); 
            croak("type %s does not support property '%s'",
                  classname, name);
        }
        g_value_init (&value, G_PARAM_SPEC_VALUE_TYPE (pspec));
        if ( G_IS_PARAM_SPEC_BOOLEAN(pspec) ) {
           gboolean val;
           goo_canvas_item_model_get_child_properties(model, child, name, &val, NULL);
           g_value_set_boolean(&value, val);
        } else if ( G_IS_PARAM_SPEC_CHAR(pspec) ) {
           gchar val;
           goo_canvas_item_model_get_child_properties(model, child, name, &val, NULL);
           g_value_set_char(&value, val);
        } else if ( G_IS_PARAM_SPEC_UCHAR(pspec) ) {
           guchar val;
           goo_canvas_item_model_get_child_properties(model, child, name, &val, NULL);
           g_value_set_uchar(&value, val);
        } else if ( G_IS_PARAM_SPEC_INT(pspec) ) {
           gint val;
           goo_canvas_item_model_get_child_properties(model, child, name, &val, NULL);
           g_value_set_int(&value, val);
        } else if ( G_IS_PARAM_SPEC_UINT(pspec) ) {
           guint val;
           goo_canvas_item_model_get_child_properties(model, child, name, &val, NULL);
           g_value_set_uint(&value, val);
        } else if ( G_IS_PARAM_SPEC_LONG(pspec) ) {
           glong val;
           goo_canvas_item_model_get_child_properties(model, child, name, &val, NULL);
           g_value_set_long(&value, val);
        } else if ( G_IS_PARAM_SPEC_ULONG(pspec) ) {
           gulong val;
           goo_canvas_item_model_get_child_properties(model, child, name, &val, NULL);
           g_value_set_ulong(&value, val);
        } else if ( G_IS_PARAM_SPEC_INT64(pspec) ) {
           gint64 val;
           goo_canvas_item_model_get_child_properties(model, child, name, &val, NULL);
           g_value_set_int64(&value, val);
        } else if ( G_IS_PARAM_SPEC_UINT64(pspec) ) {
           guint64 val;
           goo_canvas_item_model_get_child_properties(model, child, name, &val, NULL);
           g_value_set_uint64(&value, val);
        } else if ( G_IS_PARAM_SPEC_FLOAT(pspec) ) {
           gfloat val;
           goo_canvas_item_model_get_child_properties(model, child, name, &val, NULL);
           g_value_set_float(&value, val);
        } else if ( G_IS_PARAM_SPEC_DOUBLE(pspec) ) {
           gdouble val;
           goo_canvas_item_model_get_child_properties(model, child, name, &val, NULL);
           g_value_set_double(&value, val);
        } else if ( G_IS_PARAM_SPEC_ENUM(pspec) ) {
           gint val;
           goo_canvas_item_model_get_child_properties(model, child, name, &val, NULL);
           g_value_set_enum(&value, val);
        } else if ( G_IS_PARAM_SPEC_FLAGS(pspec) ) {
           guint val;
           goo_canvas_item_model_get_child_properties(model, child, name, &val, NULL);
           g_value_set_flags(&value, val);
        } else if ( G_IS_PARAM_SPEC_STRING(pspec) ) {
           gchar* val;
           goo_canvas_item_model_get_child_properties(model, child, name, &val, NULL);
           g_value_set_string(&value, val);
        } else if ( G_IS_PARAM_SPEC_PARAM(pspec) ) {
           GParamSpec* val;
           goo_canvas_item_model_get_child_properties(model, child, name, &val, NULL);
           g_value_set_param(&value, val);
        } else if ( G_IS_PARAM_SPEC_BOXED(pspec) ) {
           gpointer val;
           goo_canvas_item_model_get_child_properties(model, child, name, &val, NULL);
           g_value_set_boxed(&value, val);
        } else if ( G_IS_PARAM_SPEC_POINTER(pspec) ) {
           gpointer val;
           goo_canvas_item_model_get_child_properties(model, child, name, &val, NULL);
           g_value_set_pointer(&value, val);
        } else if ( G_IS_PARAM_SPEC_OBJECT(pspec) ) {
           gpointer val;
           goo_canvas_item_model_get_child_properties(model, child, name, &val, NULL);
           g_value_set_object(&value, val);
        } else if ( G_IS_PARAM_SPEC_UNICHAR(pspec) ) {
           guint val;
           goo_canvas_item_model_get_child_properties(model, child, name, &val, NULL);
           g_value_set_uint(&value, val);
        } else if ( G_IS_PARAM_SPEC_VALUE_ARRAY(pspec) ) {
           gpointer val;
           goo_canvas_item_model_get_child_properties(model, child, name, &val, NULL);
           g_value_set_boxed(&value, val);
        } else if ( G_IS_PARAM_SPEC_GTYPE(pspec) ) {
           GType val;
           goo_canvas_item_model_get_child_properties(model, child, name, &val, NULL);
           g_value_set_gtype(&value, val);
        }
        pval = gperl_sv_from_value(&value);
        g_value_unset (&value);
        mXPUSHp(name, strlen(name));
        XPUSHs(pval);
    }
