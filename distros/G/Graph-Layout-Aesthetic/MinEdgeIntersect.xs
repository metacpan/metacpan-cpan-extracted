#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

/* aesthetic 'min edge intersect' - makes crossed edges uncross */

#include "aesth.h"

/* this doesn't make any sense except in 2D */
#define DIMENSIONS	2

typedef struct private {
    aglo_point mid1, mid2;
    aglo_point delta;
    aglo_point force_delta;
    aglo_real data[1];
} *private;

declare_aesth(min_edge_intersect);

define_setup(min_edge_intersect) {
    private private;

    if (state->dimensions != DIMENSIONS) 
        croak("MinEdgeIntersect only works in %d dimensions, not %"UVuf, 
              (int) DIMENSIONS, (UV) state->dimensions);

    Newc(__LINE__, private, sizeof(struct private) + (4*DIMENSIONS-1) * sizeof(aglo_real), char, struct private);
    private->delta       = &private->data[DIMENSIONS * 0];
    private->force_delta = &private->data[DIMENSIONS * 1];
    private->mid1        = &private->data[DIMENSIONS * 2];
    private->mid2        = &private->data[DIMENSIONS * 3];
    return private;
}

define_cleanup(min_edge_intersect) {
    Safefree(private);
    return;
}

static int ccw(aglo_real x0, aglo_real y0,
               aglo_real x1, aglo_real y1,
               aglo_real x2, aglo_real y2) {
    aglo_real dx1, dx2, dy1, dy2;
    dx1 = x1 - x0; dy1 = y1 - y0;
    dx2 = x2 - x0; dy2 = y2 - y0;
    if (dx1*dy2 > dy1*dx2) return +1;
    if (dx1*dy2 < dy1*dx2) return -1;
    if (dx1*dx2 < 0 || dy1*dy2 < 0) return -1;
    if (dx1*dx1+dy1*dy1 < dx2*dx2+dy2*dy2) return +1;
    return 0;
}

static int intersect(aglo_real x11, aglo_real y11,
                     aglo_real x12, aglo_real y12,	/* line 1 */
                     aglo_real x21, aglo_real y21,
                     aglo_real x22, aglo_real y22) {	/* line 2 */
    return 
        ccw(x11, y11, x12, y12, x21, y21) *
        ccw(x11, y11, x12, y12, x22, y22) <= 0 &&
        ccw(x21, y21, x22, y22, x11, y11) *
        ccw(x21, y21, x22, y22, x12, y12) <= 0;
}

static void ae_intersection(aglo_state state,
                            aglo_gradient gradient,
                            void *private,
                            aglo_vertex p11, aglo_vertex p12,
                            aglo_vertex p21, aglo_vertex p22) {
    if (intersect(state->point[p11][0], state->point[p11][1],
                  state->point[p12][0], state->point[p12][1],
                  state->point[p21][0], state->point[p21][1],
                  state->point[p22][0], state->point[p22][1])) {
        aglo_point mid1 = PRIVATE->mid1;
        aglo_point mid2 = PRIVATE->mid2;
        aglo_point delta = PRIVATE->delta;
        aglo_point force_delta = PRIVATE->force_delta;
        aglo_real mag;

        aglo_point_midpoint(DIMENSIONS, mid1, state->point[p11], state->point[p12]);
        aglo_point_midpoint(DIMENSIONS, mid2, state->point[p21], state->point[p22]);
        aglo_point_sub(DIMENSIONS, delta, mid2, mid1);
        mag = aglo_point_mag(DIMENSIONS, delta);
        mag = fmax(mag, 1e-8);  /* avoid div by 0 */
        aglo_point_scalar_mult(DIMENSIONS, force_delta, 1/mag, delta);

        aglo_point_dec(DIMENSIONS, &gradient[p11*DIMENSIONS], force_delta);
        aglo_point_dec(DIMENSIONS, &gradient[p12*DIMENSIONS], force_delta);
        aglo_point_inc(DIMENSIONS, &gradient[p21*DIMENSIONS], force_delta);
        aglo_point_inc(DIMENSIONS, &gradient[p22*DIMENSIONS], force_delta);
    }
}

define_aesth(min_edge_intersect) {
    aglo_unsigned i, j;
    aglo_edge_record p, q;
    aglo_graph graph = state->graph;

    /* all 4 endpoints are distinct */
    /* i p */
    /* i j q */
    for (i=0;i<graph->vertices;i++)
        for (p=graph->edge_table[i];p;p=p->next)
            if (i < p->tail)
                for (j=i+1;j<graph->vertices;j++)
                    if (j != p->tail)
                        for (q=graph->edge_table[j];q;q=q->next)
                            if (j < q->tail && p->tail != q->tail)
                                ae_intersection(state, gradient, private,
                                                i, p->tail,
                                                j, q->tail);
}

MODULE = Graph::Layout::Aesthetic::Force::MinEdgeIntersect	PACKAGE = Graph::Layout::Aesthetic::Force::MinEdgeIntersect
PROTOTYPES: ENABLE

SV *
new(const char *class)
  PREINIT:
    aglo_force force;
  CODE:
    New(__LINE__, force, 1, struct aglo_force);
    force->aesth_gradient = ae_min_edge_intersect;
    force->aesth_setup	 = ae_setup_min_edge_intersect;
    force->aesth_cleanup  = ae_cleanup_min_edge_intersect;
    force->user_data = force->private_data = NULL;
    RETVAL = NEWSV(1, 0);
    sv_setref_pv(RETVAL, class, (void*) force);
  OUTPUT:
    RETVAL
