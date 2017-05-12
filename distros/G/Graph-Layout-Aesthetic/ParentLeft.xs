#define PERL_NO_GET_CONTEXT	/* we want efficiency */
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

/* aesthetic 'parent left' - put parent to left of child */

#include "aesth.h"

#define AXIS (0)

declare_aesth(parent_left);

/* TBF - this needs to be set by the client */
#define K_PARENT_LEFT_BUFFER (5.0)

define_setup(parent_left) {
    return NULL;
}

define_cleanup(parent_left) {
    return;
}

define_aesth(parent_left) {
    aglo_unsigned i, d = state->dimensions;
    aglo_graph graph = state->graph;
    aglo_edge_record p;
    aglo_real a, b, diff, mag;

    for (i=0;i<graph->vertices;i++)
        for (p=graph->edge_table[i]; p; p= p->next)
            if (p->forward)
                if ((a = state->point[i][AXIS] + K_PARENT_LEFT_BUFFER) >= 
                    (b = state->point[p->tail][AXIS])) {
                    diff = a - b;
                    mag = sqr(diff);
                    gradient[i*d+AXIS]		+= -mag;
                    gradient[p->tail*d+AXIS]	+=  mag;
                }
}

MODULE = Graph::Layout::Aesthetic::Force::ParentLeft	PACKAGE = Graph::Layout::Aesthetic::Force::ParentLeft
PROTOTYPES: ENABLE

SV *
new(const char *class)
  PREINIT:
    aglo_force force;
  CODE:
    New(__LINE__, force, 1, struct aglo_force);
    force->aesth_gradient = ae_parent_left;
    force->aesth_setup	 = ae_setup_parent_left;
    force->aesth_cleanup  = ae_cleanup_parent_left;
    force->user_data = force->private_data = NULL;
    RETVAL = NEWSV(1, 0);
    sv_setref_pv(RETVAL, class, (void*) force);
  OUTPUT:
    RETVAL
