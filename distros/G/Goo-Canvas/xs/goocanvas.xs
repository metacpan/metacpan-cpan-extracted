#include "goocanvas-perl.h"

MODULE = Goo::Canvas		PACKAGE = Goo::Canvas   PREFIX = goo_canvas_
=head1 SYNOPSIS

    use Goo::Canvas;
    use Gtk2 '-init';
    use Glib qw(TRUE FALSE);

    my $window = Gtk2::Window->new('toplevel');
    $window->signal_connect('delete_event' => sub { Gtk2->main_quit; });
    $window->set_default_size(640, 600);

    my $swin = Gtk2::ScrolledWindow->new;
    $swin->set_shadow_type('in');
    $window->add($swin);

    my $canvas = Goo::Canvas->new();
    $canvas->set_size_request(600, 450);
    $canvas->set_bounds(0, 0, 1000, 1000);
    $swin->add($canvas);

    my $root = $canvas->get_root_item();
    my $rect = Goo::Canvas::Rect->new(
        $root, 100, 100, 400, 400,
        'line-width' => 10,
        'radius-x' => 20,
        'radius-y' => 10,
        'stroke-color' => 'yellow',
        'fill-color' => 'red'
    );
    $rect->signal_connect('button-press-event',
                          \&on_rect_button_press);

    my $text = Goo::Canvas::Text->new(
        $root, "Hello World", 300, 300, -1, 'center',
        'font' => 'Sans 24',
    );
    $text->rotate(45, 300, 300);
    $window->show_all();
    Gtk2->main;

    sub on_rect_button_press {
        print "Rect item pressed!\n";
        return TRUE;
    }

=head1 DESCRIPTION

GTK+ doesn't has an built-in canvas widget. GooCanvas is wonderful.
It is easy to use and has powerful and extensible methods to create items
in canvas. Just try it.

For more documents, please read GooCanvas Manual and the demo programs
provided in the source distribution in both perl-Goo::Canvas and
GooCanvas.

=cut

GtkWidget*
goo_canvas_new(class)
    C_ARGS:
     /* void */

GooCanvasItem*
goo_canvas_get_root_item(canvas)
    GooCanvas *canvas

void
goo_canvas_set_root_item(canvas, item)
    GooCanvas *canvas
    GooCanvasItem *item

GooCanvasItemModel*
goo_canvas_get_root_item_model(canvas)
    GooCanvas *canvas

void
goo_canvas_set_root_item_model(canvas, model)
    GooCanvas *canvas
    GooCanvasItemModel *model

void
goo_canvas_get_bounds(canvas)
    GooCanvas *canvas
   PREINIT:
    gdouble left;
    gdouble top;
    gdouble right;
    gdouble bottom;
   PPCODE:
    goo_canvas_get_bounds(canvas, &left, &top, &right, &bottom);
    mXPUSHn(left);
    mXPUSHn(top);
    mXPUSHn(right);
    mXPUSHn(bottom);

void
goo_canvas_set_bounds(canvas, left, top, right, bottom)
    GooCanvas *canvas
    gdouble left
    gdouble top
    gdouble right
    gdouble bottom

gdouble
goo_canvas_get_scale(canvas)
    GooCanvas *canvas

void
goo_canvas_set_scale(canvas, scale)
    GooCanvas *canvas
    gdouble scale

GooCanvasItem*
goo_canvas_get_item(canvas, model)
    GooCanvas *canvas
    GooCanvasItemModel *model

GooCanvasItem*
goo_canvas_get_item_at(canvas, x, y, is_pointer_event)
    GooCanvas *canvas
    gdouble x
    gdouble y
    gboolean is_pointer_event

AV*
goo_canvas_get_items_at(canvas, x, y, is_pointer_event)
    GooCanvas *canvas
    gdouble x
    gdouble y
    gboolean is_pointer_event
  PREINIT:
    GList *list, *i;
  CODE:
    list = goo_canvas_get_items_at(canvas, x, y, is_pointer_event);
    RETVAL = newAV();
    for ( i = list; i != NULL; i = i->next ) {
        av_push(RETVAL, newSVGooCanvasItem((GooCanvasItem*)i->data));
    }
    sv_2mortal((SV*)RETVAL);
  OUTPUT:
    RETVAL
  CLEANUP:
    g_list_free (list);

AV*
goo_canvas_get_items_in_area(canvas, area, inside_area, allow_overlaps, include_containers)
    GooCanvas *canvas
    GooCanvasBounds *area
    gboolean inside_area
    gboolean allow_overlaps
    gboolean include_containers
  PREINIT:
    GList *list, *i;
  CODE:
    list = goo_canvas_get_items_in_area(canvas, area, inside_area, allow_overlaps, include_containers);
    RETVAL = newAV();
    for ( i = list; i != NULL; i = i->next ) {
        av_push(RETVAL, newSVGooCanvasItem((GooCanvasItem*)i->data));
    }
    sv_2mortal((SV*)RETVAL);
  OUTPUT:
    RETVAL
  CLEANUP:
    g_list_free (list);

void
goo_canvas_scroll_to(canvas, left, top)
    GooCanvas *canvas
    gdouble left
    gdouble top

void
goo_canvas_render(canvas, cr, bounds, scale)
    GooCanvas *canvas
    cairo_t *cr
    GooCanvasBounds *bounds
    gdouble scale

void
goo_canvas_convert_to_pixels(canvas, x, y)
    GooCanvas *canvas
    gdouble x
    gdouble y
   C_ARGS:
    canvas, &x, &y
   OUTPUT:
    x
    y

void
goo_canvas_convert_from_pixels(canvas, x, y)
    GooCanvas *canvas
    gdouble x
    gdouble y
   C_ARGS:
    canvas, &x, &y
   OUTPUT:
    x
    y

void
goo_canvas_convert_to_item_space(canvas, item, x, y)
    GooCanvas *canvas
    GooCanvasItem *item
    gdouble x
    gdouble y
   C_ARGS:
    canvas, item, &x, &y
   OUTPUT:
    x
    y

void
goo_canvas_convert_from_item_space(canvas, item, x, y)
    GooCanvas *canvas
    GooCanvasItem *item
    gdouble x
    gdouble y
   C_ARGS:
    canvas, item, &x, &y
   OUTPUT:
    x
    y

=for apidoc
=for arg cursor (GdkCursor) the cursor to display during the grab, or undef means no change
=cut
GdkGrabStatus
goo_canvas_pointer_grab(canvas, item, event_mask, cursor, time)
    GooCanvas *canvas
    GooCanvasItem *item
    GdkEventMask event_mask
    guint32 time
   CODE:
    if ( SvTRUE(ST(3)) )
        RETVAL = goo_canvas_pointer_grab(canvas, item, event_mask, SvGdkCursor (ST(3)), time);
    else
        RETVAL = goo_canvas_pointer_grab(canvas, item, event_mask, NULL, time);
   OUTPUT:
    RETVAL

void
goo_canvas_pointer_ungrab(canvas, item, time)
    GooCanvas *canvas
    GooCanvasItem *item
    guint32 time

void
goo_canvas_grab_focus(canvas, item)
    GooCanvas *canvas
    GooCanvasItem *item

GdkGrabStatus
goo_canvas_keyboard_grab(canvas, item, owner_events, time)
    GooCanvas *canvas
    GooCanvasItem *item
    gboolean owner_events
    guint32 time

void
goo_canvas_keyboard_ungrab(canvas, item, time)
    GooCanvas *canvas
    GooCanvasItem *item
    guint32 time

GooCanvasItem*
goo_canvas_create_item(canvas, model)
    GooCanvas *canvas
    GooCanvasItemModel *model

void
goo_canvas_unregister_item(canvas, model)
    GooCanvas *canvas
    GooCanvasItemModel *model

void
goo_canvas_register_widget_item(canvas, witem)
    GooCanvas *canvas
    GooCanvasWidget *witem

void
goo_canvas_unregister_widget_item(canvas, witem)
    GooCanvas *canvas
    GooCanvasWidget *witem

void
goo_canvas_update(canvas)
    GooCanvas *canvas

void
goo_canvas_request_update(canvas)
    GooCanvas *canvas

void
goo_canvas_request_redraw(canvas, bounds)
    GooCanvas *canvas
    GooCanvasBounds *bounds

gdouble
goo_canvas_get_default_line_width(canvas)
    GooCanvas *canvas

GArray*
goo_canvas_parse_path_data(path_data)
    const gchar *path_data

void
goo_canvas_create_path(commands, cr)
    GArray *commands
    cairo_t *cr

cairo_surface_t*
goo_canvas_cairo_surface_from_pixbuf(pixbuf)
    GdkPixbuf* pixbuf

BOOT:
#include "register.xsh"
#include "boot.xsh"

MODULE = Goo::Canvas		PACKAGE = Goo::Canvas::Points   PREFIX = goo_canvas_points_

=for apidoc
Create GooCanvasPoints from a Perl array. The points is an array reference
that contain data like [x1, y1, x2, y2, ...]
=cut
GooCanvasPoints*
goo_canvas_points_new(class, points)
    AV* points
  PREINIT:
    int len;
    int i;
  CODE:
    len = av_len(points) + 1;
    if ( 0 != len % 2 )
        croak ("points new: expects point pairs"
               "(odd number of point coordinates detected)");
    RETVAL = goo_canvas_points_new(len/2);
    for ( i = 0; i < len; i++ )
        RETVAL->coords[i] = SvNV(*av_fetch(points, i, FALSE));
  OUTPUT:
    RETVAL

MODULE = Goo::Canvas		PACKAGE = Goo::Canvas::LineDash   PREFIX = goo_canvas_line_dash_

=for apidoc
Create GooCanvasLineDash from a perl array. The dashes is an array reference
contains numbers.
=cut
GooCanvasLineDash*
goo_canvas_line_dash_new(class, dashes)
    AV *dashes
   PREINIT:
    int len;
    gdouble *dashes_ary;
    int i;
   CODE:
    len = av_len(dashes) + 1;
    Newx(dashes_ary, len, gdouble);
    for ( i = 0; i < len; i++ )
        dashes_ary[i] = SvNV(*(av_fetch(dashes, i, FALSE)));
    RETVAL = goo_canvas_line_dash_newv(len, dashes_ary);
   OUTPUT:
    RETVAL

MODULE = Goo::Canvas		PACKAGE = Goo::Cairo::Pattern

GooCairoPattern_copy*
new(class, pattern)
  cairo_pattern_t* pattern
  CODE:
    RETVAL = pattern;
  OUTPUT:
    RETVAL

GooCairoPattern_copy*
new_from_pixbuf(class, pixbuf)
    GdkPixbuf *pixbuf
   CODE:
    RETVAL = goo_canvas_cairo_pattern_from_pixbuf(pixbuf);
   OUTPUT:
    RETVAL

MODULE = Goo::Canvas		PACKAGE = Goo::Cairo::Matrix

GooCairoMatrix_copy*
new(class, mat)
  cairo_matrix_t* mat
  CODE:
    RETVAL = (GooCairoMatrix*)mat;
  OUTPUT:
    RETVAL
