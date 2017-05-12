#define PERL_NO_GET_CONTEXT	/* we want efficiency */
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

/* aesthetic 'node repulsion' - makes nodes spread apart */

#include "aesth.h"

typedef struct private {
    aglo_point delta;
    aglo_point force_delta;
    aglo_real data[1];
} *private;

declare_aesth(node_repulsion);

define_setup(node_repulsion) {
    private private;

    Newc(__LINE__, private, sizeof(struct private) + (2*state->dimensions-1) * sizeof(aglo_real), char, struct private);
    private->delta       = &private->data[0];
    private->force_delta = &private->data[state->dimensions];
    return private;
}

define_cleanup(node_repulsion) {
    Safefree(private);
    return;
}

define_aesth(node_repulsion) {
    aglo_unsigned i, j, d = state->dimensions;
    aglo_graph graph = state->graph;
    aglo_point delta 	   = PRIVATE->delta;
    aglo_point force_delta = PRIVATE->force_delta;

    for (i=1;i<graph->vertices;i++)
        for (j=0;j<i;j++) {
            aglo_real mag2;

            aglo_point_sub(d, delta, state->point[i], state->point[j]);
            mag2 = aglo_point_mag2(d, delta);
            mag2 = fmax(mag2, 1e-8); /* avoid div by 0 */

            aglo_point_scalar_mult(d, force_delta, 1/mag2, delta);

            aglo_point_add(d, &gradient[d*i], &gradient[d*i], force_delta);
            aglo_point_sub(d, &gradient[d*j], &gradient[d*j], force_delta);
        }
}

MODULE = Graph::Layout::Aesthetic::Force::NodeRepulsion	PACKAGE = Graph::Layout::Aesthetic::Force::NodeRepulsion
PROTOTYPES: ENABLE

SV *
new(const char *class)
  PREINIT:
    aglo_force force;
  CODE:
    New(__LINE__, force, 1, struct aglo_force);
    force->aesth_gradient = ae_node_repulsion;
    force->aesth_setup	 = ae_setup_node_repulsion;
    force->aesth_cleanup  = ae_cleanup_node_repulsion;
    force->user_data = force->private_data = NULL;
    RETVAL = NEWSV(1, 0);
    sv_setref_pv(RETVAL, class, (void*) force);
  OUTPUT:
    RETVAL
