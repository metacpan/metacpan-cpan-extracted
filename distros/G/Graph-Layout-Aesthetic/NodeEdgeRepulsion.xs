#define PERL_NO_GET_CONTEXT	/* we want efficiency */
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

/* aesthetic 'node edge repulsion' - makes node and edges spread apart */

#include "aesth.h"

typedef struct private {
    aglo_point e1p, e2p, e1e2, e2e1, e1part, e2part, e, half_force_delta;
    aglo_point delta;
    aglo_point force_delta;
    aglo_real data[1];
} *private;

declare_aesth(node_edge_repulsion);

define_setup(node_edge_repulsion) {
    private private;

    Newc(__LINE__, private, sizeof(struct private) + (10*state->dimensions-1) * sizeof(aglo_real), char, struct private);
    private->delta       = &private->data[0];
    private->force_delta = &private->data[state->dimensions];
    private->e1p	 = &private->data[state->dimensions * 2];
    private->e2p	 = &private->data[state->dimensions * 3];
    private->e1e2	 = &private->data[state->dimensions * 4];
    private->e2e1	 = &private->data[state->dimensions * 5];
    private->e1part	 = &private->data[state->dimensions * 6];
    private->e2part	 = &private->data[state->dimensions * 7];
    private->e		 = &private->data[state->dimensions * 8];
    private->half_force_delta = &private->data[state->dimensions * 9];
    return private;
}

define_cleanup(node_edge_repulsion) {
    Safefree(private);
    return;
}

/* distance from point pn to edge determined by e1n and e2n */	
static void ae_point_linesegment_distance_2(aglo_state state,
                                            aglo_gradient gradient,
                                            void *private,
                                            aglo_vertex pn, 
                                            aglo_vertex e1n, 
                                            aglo_vertex e2n) {
    aglo_unsigned d = state->dimensions;
    aglo_real dp_e2e1p, dp_e1e2p;
    aglo_point e1p  = PRIVATE->e1p;
    aglo_point e2p  = PRIVATE->e2p;
    aglo_point e1e2 = PRIVATE->e1e2;
    aglo_point e2e1 = PRIVATE->e2e1;

    aglo_point_sub(d, e1p,  state->point[pn],  state->point[e1n]);
    aglo_point_sub(d, e1e2, state->point[e2n], state->point[e1n]);
    dp_e2e1p = aglo_point_dot_product(d, e1p, e1e2);

    if (dp_e2e1p >= 0) {	/* acute */
        aglo_point_sub(d, e2p, state->point[pn], state->point[e2n]);
        aglo_point_scalar_mult(d, e2e1, -1, e1e2);
        dp_e1e2p = aglo_point_dot_product(d, e2p, e2e1);
        if (dp_e1e2p >= 0) {	/* acute */
            aglo_point delta	= PRIVATE->delta;
            aglo_point e1part	= PRIVATE->e1part;
            aglo_point e2part	= PRIVATE->e2part;
            aglo_point e		= PRIVATE->e;
            aglo_point force_delta	= PRIVATE->force_delta;
            aglo_point half_force_delta = PRIVATE->half_force_delta;
            aglo_real mag2;
	
            mag2 = aglo_point_mag2(d, e1e2);
            mag2 = fmax(mag2, 1e-8); /* avoid div by 0 */
            aglo_point_scalar_mult(d, e1part, dp_e1e2p/mag2, state->point[e1n]);
            aglo_point_scalar_mult(d, e2part, dp_e2e1p/mag2, state->point[e2n]);
            /* e is the point on e1e2 closest to p */
            aglo_point_add(d, e, e1part, e2part);
            aglo_point_sub(d, delta, state->point[pn], e); 

            mag2 = aglo_point_mag2(d, delta);
            mag2 = fmax(mag2, 1e-8); /* avoid div by 0 */

            aglo_point_scalar_mult(d, force_delta, 1/mag2, delta);
            aglo_point_scalar_mult(d, half_force_delta, 0.5, force_delta);

            aglo_point_inc(d, &gradient[pn*d],  force_delta);
            aglo_point_dec(d, &gradient[e1n*d], half_force_delta);
            aglo_point_dec(d, &gradient[e2n*d], half_force_delta);
        }
    }
    /* really should handle the case when not both acute TBF */
}

define_aesth(node_edge_repulsion) {
    aglo_unsigned i, j;
    aglo_edge_record p;
    aglo_graph graph = state->graph;

    /* i < p */
    /* j != i; j != p */
    for (j=0; j<graph->vertices; j++)
        for (i=0; i<graph->vertices; i++)
            if (i != j)
                for (p=graph->edge_table[i]; p; p=p->next)
                    if (i < p->tail && j != p->tail)
                        ae_point_linesegment_distance_2(state, gradient,
                                                        private, 
                                                        j, i, p->tail);
}

MODULE = Graph::Layout::Aesthetic::Force::NodeEdgeRepulsion	PACKAGE = Graph::Layout::Aesthetic::Force::NodeEdgeRepulsion
PROTOTYPES: ENABLE

SV *
new(const char *class)
  PREINIT:
    aglo_force force;
  CODE:
    New(__LINE__, force, 1, struct aglo_force);
    force->aesth_gradient = ae_node_edge_repulsion;
    force->aesth_setup	 = ae_setup_node_edge_repulsion;
    force->aesth_cleanup  = ae_cleanup_node_edge_repulsion;
    force->user_data = force->private_data = NULL;
    RETVAL = NEWSV(1, 0);
    sv_setref_pv(RETVAL, class, (void*) force);
  OUTPUT:
    RETVAL
