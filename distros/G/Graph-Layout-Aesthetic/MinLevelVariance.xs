#define PERL_NO_GET_CONTEXT	/* we want efficiency */
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

/* aesthetic 'min level variance' - put nodes on same level on same X coord */

#include "aesth.h"
#include "at_node_level.h"

#define AXIS (0)

declare_aesth(min_level_variance);

define_setup(min_level_variance) {
    aglo_real *level_distance_sum;

    at_setup_node_level(state->graph);
    New(__LINE__, level_distance_sum, state->graph->nr_levels, aglo_real);
    return level_distance_sum;
}

define_cleanup(min_level_variance) {
    Safefree(private);
    return;
}

define_aesth(min_level_variance) {
    aglo_unsigned d = state->dimensions;
    aglo_real *sum;
    aglo_vertex **l, *i;
    aglo_graph graph = state->graph;
    aglo_real *level_distance_sum = private;

    for (l=graph->level2nodes, sum = level_distance_sum; 
         l[0] < l[1]; 
         l++, sum++) {
        *sum = 0;
        for (i=l[0]; i<l[1]; i++) *sum += state->point[*i][AXIS];
        *sum /= i-l[0];
    }

    for (l=graph->level2nodes, sum = level_distance_sum; 
         l[0] < l[1]; 
         l++, sum++)
        for (i=l[0]; i<l[1]; i++) {
            aglo_real delta = *sum - state->point[*i][AXIS];
            aglo_real mag = fabs(delta);
            if (mag > 0.0L) {                   /* check this */
                aglo_real force_delta = mag * mag * delta;
                gradient[*i*d+AXIS] += force_delta;
            }
        }
}

MODULE = Graph::Layout::Aesthetic::Force::MinLevelVariance	PACKAGE = Graph::Layout::Aesthetic::Force::MinLevelVariance
PROTOTYPES: ENABLE

SV *
new(const char *class)
  PREINIT:
    aglo_force force;
  CODE:
    New(__LINE__, force, 1, struct aglo_force);
    force->aesth_gradient = ae_min_level_variance;
    force->aesth_setup	 = ae_setup_min_level_variance;
    force->aesth_cleanup  = ae_cleanup_min_level_variance;
    force->user_data = force->private_data = NULL;
    RETVAL = NEWSV(1, 0);
    sv_setref_pv(RETVAL, class, (void*) force);
  OUTPUT:
    RETVAL
