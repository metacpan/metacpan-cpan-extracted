#include "goocanvas-perl.h"
typedef SV* SVREF;

static GQuark
get_property_id(char* property)
{
    GQuark property_id;
    if ( gperl_str_eq(property, "stroke_pattern") ) {
        property_id = goo_canvas_style_stroke_pattern_id;
    } else if ( gperl_str_eq(property, "fill-pattern") ) {
        property_id = goo_canvas_style_fill_pattern_id;
    } else if ( gperl_str_eq(property, "fill-rule") ) {
        property_id = goo_canvas_style_fill_rule_id;
    } else if ( gperl_str_eq(property, "operator") ) {
        property_id = goo_canvas_style_operator_id;
    } else if ( gperl_str_eq(property, "antialias") ) {
        property_id = goo_canvas_style_antialias_id;
    } else if ( gperl_str_eq(property, "line-width") ) {
        property_id = goo_canvas_style_line_width_id;
    } else if ( gperl_str_eq(property, "line-cap") ) {
        property_id = goo_canvas_style_line_cap_id;
    } else if ( gperl_str_eq(property, "line-join") ) {
        property_id = goo_canvas_style_line_join_id;
    } else if ( gperl_str_eq(property, "line-join-miter-limit") ) {
        property_id = goo_canvas_style_line_join_miter_limit_id;
    } else if ( gperl_str_eq(property, "line-dash") ) {
        property_id = goo_canvas_style_line_dash_id;
    } else if ( gperl_str_eq(property, "font-desc") ) {
        property_id = goo_canvas_style_font_desc_id;
    }
    else {
        croak ("Unknown style: %s, should be one of stroke_pattern/fill_pattern/fill_rule/operator/antialias/line_width/line_cap/line_join/line_join_miter_limit/line_dash/font_desc", property);
    }
    return property_id;
}


MODULE = Goo::Canvas::Style		PACKAGE = Goo::Canvas::Style   PREFIX = goo_canvas_style_

GooCanvasStyle*
goo_canvas_style_new(class)
    C_ARGS:
    /* void */

GooCanvasStyle*
goo_canvas_style_copy(style)
    GooCanvasStyle *style

GooCanvasStyle*
goo_canvas_style_get_parent(style)
    GooCanvasStyle *style

void
goo_canvas_style_set_parent(style, parent)
    GooCanvasStyle *style
    GooCanvasStyle *parent


void
goo_canvas_style_set_property(style, property, val)
    GooCanvasStyle *style
    char* property
    SV* val
   PREINIT:
    GQuark property_id;
    GType type;
    GValue value;
   CODE:
    property_id = get_property_id(property);
    type = gperl_type_from_package(sv_reftype(SvRV(val), TRUE));
    if ( !type )
        croak ("set_property: Unknown type of the value!");
    g_value_init(&value, type);
    gperl_value_from_sv (&value, val);
    goo_canvas_style_set_property(style, property_id, &value);
    g_value_unset(&value);

SV*
goo_canvas_style_get_property(style, property)
    GooCanvasStyle *style
    char* property
   PREINIT:
    GQuark property_id;
    GValue* value;
   CODE:
    property_id = get_property_id(property);
    value = goo_canvas_style_get_property(style, property_id);
    RETVAL = gperl_sv_from_value(value);
   OUTPUT:
    RETVAL
    
gboolean
goo_canvas_style_set_fill_options(style, cr)
    GooCanvasStyle *style
    cairo_t *cr

gboolean
goo_canvas_style_set_stroke_options(style, cr)
    GooCanvasStyle *style
    cairo_t *cr

