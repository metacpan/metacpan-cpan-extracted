#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"

typedef struct Math_Fractal_Julia {
    double limit;
    unsigned int max_iter;
    double x_const;
    double y_const;
    double x_min;
    double y_min;
    double x_max;
    double y_max;
    unsigned int width;
    unsigned int height;
} Math_Fractal_Julia;

unsigned int _point(Math_Fractal_Julia *j, unsigned int x, unsigned int y) {
    unsigned int n;
    double x1, y1, x2, y2, xtemp;
    n = 0;
    x1 = x * (j->x_max - j->x_min) / j->width  + j->x_min;
    y1 = y * (j->y_max - j->y_min) / j->height + j->y_min;
    while (++n < j->max_iter) {
        x2 = x1 * x1;
        y2 = y1 * y1;
        if (x2 + y2 > j->limit) {
            break;
        }
        xtemp = x2 - y2 + j->x_const;
        y1 = 2 * x1 * y1 + j->y_const;
        x1 = xtemp;
    }
    if (n == j->max_iter) {
        n = 0;
    }
    return n;
}

static Math_Fractal_Julia julia = {
    5,       /* limit */
    600,     /* max_iter */
    0.0,     /* x_const */
    0.0,     /* y_const */
    -2.2,    /* x_min */
    -1.1,    /* y_min */
    1.0,     /* x_max */
    1.1,     /* y_max */
    640,     /* width */
    480      /* height */
};

MODULE = Math::Fractal::Julia	PACKAGE = Math::Fractal::Julia	PREFIX = julia_
PROTOTYPES: ENABLE

Math_Fractal_Julia *
julia__new(CLASS)
        char* CLASS
    CODE:
        Newx(RETVAL, 1, Math_Fractal_Julia);
        RETVAL->limit    = julia.limit;
        RETVAL->max_iter = julia.max_iter;
        RETVAL->x_const  = julia.x_const;
        RETVAL->y_const  = julia.y_const;
        RETVAL->x_min    = julia.x_min;
        RETVAL->y_min    = julia.y_min;
        RETVAL->x_max    = julia.x_max;
        RETVAL->y_max    = julia.y_max;
        RETVAL->width    = julia.width;
        RETVAL->height   = julia.height;
    OUTPUT:
        RETVAL

unsigned int
julia_set_max_iter(self, max_iter)
        Math_Fractal_Julia *self
        unsigned int max_iter
    CODE:
        self->max_iter = max_iter;
        RETVAL = self->max_iter;
    OUTPUT:
        RETVAL

double
julia_set_limit(self, limit)
        Math_Fractal_Julia *self
        double limit
    CODE:
        self->limit = limit;
        RETVAL = self->limit;
    OUTPUT:
        RETVAL

void
julia_set_bounds(self, x_min, y_min, x_max, y_max, width, height)
        Math_Fractal_Julia *self
        double x_min
        double y_min
        double x_max
        double y_max
        unsigned int width
        unsigned int height
    CODE:
        self->x_min = x_min;
        self->y_min = y_min;
        self->x_max = x_max;
        self->y_max = y_max;
        self->width = width;
        self->height = height;

void
julia_set_constant(self, x_const, y_const)
        Math_Fractal_Julia *self
        double x_const
        double y_const
    CODE:
        self->x_const = x_const;
        self->y_const = y_const;

double
julia_point(self, x, y)
        Math_Fractal_Julia *self
        unsigned int x
        unsigned int y
    CODE:
        RETVAL = _point(self, x, y);
    OUTPUT:
        RETVAL

void
julia_DESTROY(self)
        Math_Fractal_Julia *self
    CODE:
        Safefree(self);

