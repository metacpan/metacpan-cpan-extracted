#define PERL_NO_GET_CONTEXT	/* we want efficiency */
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

/* aesthetic 'centripetal' - makes nodes move away from the centroid */

#include "aesth.h"
#include "at_centroid.h"

typedef struct private {
    aglo_point delta;
    aglo_point force_delta;
    aglo_real data[1];
} *private;

declare_aesth(centripetal);

define_setup(centripetal) {
    private private;

    Newc(__LINE__, private, sizeof(struct private) + (2*state->dimensions-1) * sizeof(aglo_real), char, struct private);
    private->delta       = &private->data[0];
    private->force_delta = &private->data[state->dimensions];
    return private;
}

define_cleanup(centripetal) {
    Safefree(private);
    return;
}

define_aesth(centripetal) {
    aglo_unsigned i, d = state->dimensions;
    aglo_graph graph = state->graph;
    aglo_point delta 	   = PRIVATE->delta;
    aglo_point force_delta = PRIVATE->force_delta;
    aglo_const_point centroid;

    centroid = at_centroid(state);

    for (i=0;i<graph->vertices;i++) {
        aglo_real mag2;

        aglo_point_sub(d, delta, state->point[i], centroid);
        mag2 = aglo_point_mag2(d, delta);
        mag2 = fmax(mag2, 1e-8); /* avoid div by 0 */

        aglo_point_scalar_mult(d, force_delta, 1/mag2, delta);

        aglo_point_add(d, &gradient[d*i], &gradient[d*i], force_delta);
    }
}

MODULE = Graph::Layout::Aesthetic::Force::Centripetal	PACKAGE = Graph::Layout::Aesthetic::Force::Centripetal
PROTOTYPES: ENABLE

SV *
new(const char *class)
  PREINIT:
    aglo_force force;
  CODE:
    New(__LINE__, force, 1, struct aglo_force);
    force->aesth_gradient = ae_centripetal;
    force->aesth_setup	  = ae_setup_centripetal;
    force->aesth_cleanup  = ae_cleanup_centripetal;
    force->user_data = force->private_data = NULL;
    RETVAL = NEWSV(1, 0);
    sv_setref_pv(RETVAL, class, (void*) force);
  OUTPUT:
    RETVAL
