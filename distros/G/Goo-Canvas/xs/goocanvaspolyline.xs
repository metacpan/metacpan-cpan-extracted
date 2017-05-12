#include "goocanvas-perl.h"

MODULE = Goo::Canvas::Polyline		PACKAGE = Goo::Canvas::Polyline   PREFIX = goo_canvas_polyline_

=for apidoc
=for arg points (AV) The points is an array reference that contains a flat points coordinates. If you want create a polyline without points, pass an empty array refer or undef.
=cut
GooCanvasItem*
goo_canvas_polyline_new(class, parent, close_path, points, ...)
    GooCanvasItem *parent
    gboolean close_path
   PREINIT:
    GooCanvasPolylineData *polyline_data;
    int i, len;
    AV* points;                     
   CODE:
    RETVAL = goo_canvas_polyline_new(parent, close_path, 0, NULL);
    if ( SvTRUE(ST(3)) ) {
        points = (AV*)SvRV(ST(3));
        len = av_len(points) + 1;
        if ( len > 0) {
            if ( 0 != len % 2 )
                croak ("polyline new: expects point pairs"
                       "(odd number of point coordinates detected)");
            polyline_data = ((GooCanvasPolyline*)RETVAL)->polyline_data;
            polyline_data->num_points = len/2;
            polyline_data->coords = g_slice_alloc( len * sizeof (gdouble));
            for (i = 0; i < len; i++) {
                /* printf("point %e\n", SvNV(*av_fetch(points, i, FALSE))); */
                polyline_data->coords[i] = SvNV(*av_fetch(points, i, FALSE));
            }
        }
    }
    GOOCANVAS_PERL_ADD_PROPETIES(4);
   OUTPUT:
    RETVAL

GooCanvasItem*
goo_canvas_polyline_new_line(class, parent, x1, y1, x2, y2, ...)
    GooCanvasItem *parent
    gdouble x1
    gdouble y1
    gdouble x2
    gdouble y2
   CODE:
    RETVAL = goo_canvas_polyline_new_line(parent, x1, y1, x2, y2, NULL);
    GOOCANVAS_PERL_ADD_PROPETIES(6);
   OUTPUT:
    RETVAL

MODULE = Goo::Canvas::Polyline		PACKAGE = Goo::Canvas::PolylineModel   PREFIX = goo_canvas_polyline_model_

=for apidoc
=for arg points (AV) The points is an array reference that contains a flat points coordinates. If you want create a polyline without points, pass an empty array refer or undef.
=cut
GooCanvasItemModel*
goo_canvas_polyline_model_new(class, parent, close_path, points, ...)
    GooCanvasItemModel *parent
    gboolean close_path
   PREINIT:
    GooCanvasPolylineData *polyline_data;
    int i, len;
    AV* points;                     
   CODE:
    RETVAL = goo_canvas_polyline_model_new(parent, close_path, 0, NULL);
    if ( SvTRUE(ST(3)) ) {
       points = (AV*)SvRV(ST(3));
       len = av_len(points)+1;
       if ( len > 0 ) {
           if ( 0 != len % 2 )
               croak ("polyline new: expects point pairs"
                      "(odd number of point coordinates detected)");
           polyline_data = &((GooCanvasPolylineModel*)RETVAL)->polyline_data;
           polyline_data->num_points = len/2;
           polyline_data->coords = g_slice_alloc( len * sizeof (gdouble));
           for (i = 0; i < len; i++)
               polyline_data->coords[i] = SvNV(*av_fetch(points, i, FALSE));
       }
    }
    GOOCANVAS_PERL_ADD_PROPETIES(4);
   OUTPUT:
    RETVAL

GooCanvasItemModel*
goo_canvas_polyline_model_new_line(class, parent, x1, y1, x2, y2, ...)
    GooCanvasItemModel *parent
    gdouble x1
    gdouble y1
    gdouble x2
    gdouble y2
   CODE:
    RETVAL = goo_canvas_polyline_model_new_line(parent, x1, y1, x2, y2, NULL);
    GOOCANVAS_PERL_ADD_PROPETIES(6);
   OUTPUT:
    RETVAL

