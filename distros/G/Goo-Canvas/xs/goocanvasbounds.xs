#include "goocanvas-perl.h"

MODULE = Goo::Canvas::Bounds		PACKAGE = Goo::Canvas::Bounds		PREFIX = goo_canvas_bounds_

GooCanvasBounds*
new(class, x1, y1, x2, y2)
    double x1
    double y1
    double x2
    double y2
    CODE:
     Newx(RETVAL, 1, GooCanvasBounds);
     RETVAL->x1 = x1;
     RETVAL->x2 = x2;
     RETVAL->y1 = y1;
     RETVAL->y2 = y2;
    OUTPUT:
     RETVAL

double
x1 (self, ...)
     GooCanvasBounds* self
    CODE:
     RETVAL = self->x1;
     if (items ==2)
        self->x1 = SvNV(ST(1));
    OUTPUT:
     RETVAL

double
x2 (self, ...)
     GooCanvasBounds* self
    CODE:
     RETVAL = self->x2;
     if (items ==2)
        self->x2 = SvNV(ST(1));
    OUTPUT:
     RETVAL

double
y1 (self, ...)
     GooCanvasBounds* self
    CODE:
     RETVAL = self->y1;
     if (items ==2)
        self->y1 = SvNV(ST(1));
    OUTPUT:
     RETVAL

double
y2 (self, ...)
     GooCanvasBounds* self
    CODE:
     RETVAL = self->y2;
     if (items ==2)
        self->y2 = SvNV(ST(1));
    OUTPUT:
     RETVAL

void
DESTROY(self)
    GooCanvasBounds* self
    CODE:
    Safefree(self);
