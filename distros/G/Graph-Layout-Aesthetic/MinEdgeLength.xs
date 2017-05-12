#define PERL_NO_GET_CONTEXT	/* we want efficiency */
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

/* aesthetic 'minimize edge length' - makes edges shrink in length */
/* $Id: ae_min_edge_length.c,v 1.1 1992/10/23 06:28:21 coleman Exp $ */

#include <aesth.h>

typedef struct private {
    aglo_point delta;
    aglo_point force_delta;
    aglo_real data[1];
} *private;

declare_aesth(min_edge_length);

define_setup(min_edge_length) {
    private private;

    Newc(__LINE__, private, sizeof(struct private) + (2*state->dimensions-1) * sizeof(aglo_real), char, struct private);
    private->delta       = &private->data[0];
    private->force_delta = &private->data[state->dimensions];
    return private;
}

define_cleanup(min_edge_length) {
    Safefree(private);
    return;
}

define_aesth(min_edge_length) {
    aglo_unsigned i, j, d = state->dimensions;
    aglo_edge_record p;
    aglo_graph graph = state->graph;
    aglo_point delta 	   = PRIVATE->delta;
    aglo_point force_delta = PRIVATE->force_delta;

    for (i=0;i<graph->vertices;i++)
        for (p=graph->edge_table[i];p;p=p->next)
            if (i < (j=p->tail)) {
                aglo_real mag;

                aglo_point_sub(d, delta, state->point[i], state->point[j]);
                mag = aglo_point_mag(d, delta);
                mag = fmax(mag, 1e-8); /* avoid div by 0 */

                aglo_point_scalar_mult(d, force_delta, mag, delta);

                aglo_point_dec(d, &gradient[d*i], force_delta);
                aglo_point_inc(d, &gradient[d*j], force_delta);
            }
}

MODULE = Graph::Layout::Aesthetic::Force::MinEdgeLength	PACKAGE = Graph::Layout::Aesthetic::Force::MinEdgeLength
PROTOTYPES: ENABLE

SV *
new(const char *class)
  PREINIT:
    aglo_force force;
  CODE:
    New(__LINE__, force, 1, struct aglo_force);
    force->aesth_gradient = ae_min_edge_length;
    force->aesth_setup	 = ae_setup_min_edge_length;
    force->aesth_cleanup  = ae_cleanup_min_edge_length;
    force->user_data = force->private_data = NULL;
    RETVAL = NEWSV(1, 0);
    sv_setref_pv(RETVAL, class, (void*) force);
  OUTPUT:
    RETVAL
