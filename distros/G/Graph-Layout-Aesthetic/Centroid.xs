#define PERL_NO_GET_CONTEXT	/* we want efficiency */
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include "at_centroid.h"
#include "point.h"

aglo_const_point at_centroid(aglo_state state) {
    if (state->centroid_sequence != state->sequence) {
        aglo_unsigned i, v, d;
        aglo_point centroid;
        d = state->dimensions;

        centroid = state->cached_centroid;
        aglo_point_zero(d, centroid);

        v = state->graph->vertices;
        for (i=0;i<v;i++) 
            aglo_point_add(d, centroid, centroid, state->point[i]);
        aglo_point_scalar_mult(d, centroid, 1.0L / v, centroid);

        state->centroid_sequence = state->sequence;
    }
    return state->cached_centroid;
}

MODULE = Graph::Layout::Aesthetic::Dummy::Centroid	PACKAGE = Graph::Layout::Aesthetic::Dummy
