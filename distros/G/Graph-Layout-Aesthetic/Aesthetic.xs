#define PERL_NO_GET_CONTEXT	/* we want efficiency */
#define PERL_EXT		/* For cxinc() */
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

/* Needed on systems that use drand48 for Drand01 but have no prototype */
#ifndef HAS_DRAND48_PROTO
extern double drand48(void);
#endif

#include "ppport.h"

#include "aglo.h"
#include "point.h"
#include "at_node_level.h"

/* Workaround for older perls without packWARN */
#ifndef packWARN
# define packWARN(a) (a)
#endif

/* Duplicate from perl source (since it's not exported unfortunately) */
static bool my_isa_lookup(pTHX_ HV *stash, const char *name, HV* name_stash,
                          int len, int level) {
    AV* av;
    GV* gv;
    GV** gvp;
    HV* hv = Nullhv;
    SV* subgen = Nullsv;

    /* A stash/class can go by many names (ie. User == main::User), so
       we compare the stash itself just in case */
    if ((name_stash && stash == name_stash) ||
        strEQ(HvNAME(stash), name) ||
        strEQ(name, "UNIVERSAL")) return TRUE;

    if (level > 100) croak("Recursive inheritance detected in package '%s'",
                           HvNAME(stash));

    gvp = (GV**)hv_fetch(stash, "::ISA::CACHE::", 14, FALSE);

    if (gvp && (gv = *gvp) != (GV*)&PL_sv_undef && (subgen = GvSV(gv)) &&
        (hv = GvHV(gv))) {
        if (SvIV(subgen) == (IV)PL_sub_generation) {
            SV* sv;
            SV** svp = (SV**)hv_fetch(hv, name, len, FALSE);
            if (svp && (sv = *svp) != (SV*)&PL_sv_undef) {
                DEBUG_o( Perl_deb(aTHX_ "Using cached ISA %s for package %s\n",
                                  name, HvNAME(stash)) );
                return sv == &PL_sv_yes;
            }
        } else {
            DEBUG_o( Perl_deb(aTHX_ "ISA Cache in package %s is stale\n",
                              HvNAME(stash)) );
            hv_clear(hv);
            sv_setiv(subgen, PL_sub_generation);
        }
    }

    gvp = (GV**)hv_fetch(stash,"ISA",3,FALSE);

    if (gvp && (gv = *gvp) != (GV*)&PL_sv_undef && (av = GvAV(gv))) {
	if (!hv || !subgen) {
	    gvp = (GV**)hv_fetch(stash, "::ISA::CACHE::", 14, TRUE);

	    gv = *gvp;

	    if (SvTYPE(gv) != SVt_PVGV)
		gv_init(gv, stash, "::ISA::CACHE::", 14, TRUE);

	    if (!hv)
		hv = GvHVn(gv);
	    if (!subgen) {
		subgen = newSViv(PL_sub_generation);
		GvSV(gv) = subgen;
	    }
	}
	if (hv) {
	    SV** svp = AvARRAY(av);
	    /* NOTE: No support for tied ISA */
	    I32 items = AvFILLp(av) + 1;
	    while (items--) {
		SV* sv = *svp++;
		HV* basestash = gv_stashsv(sv, FALSE);
		if (!basestash) {
		    if (ckWARN(WARN_MISC))
			Perl_warner(aTHX_ packWARN(WARN_SYNTAX),
                                    "Can't locate package %"SVf" for @%s::ISA",
                                    sv, HvNAME(stash));
		    continue;
		}
		if (my_isa_lookup(aTHX_ basestash, name, name_stash,
                                  len, level + 1)) {
		    (void)hv_store(hv,name,len,&PL_sv_yes,0);
		    return TRUE;
		}
	    }
	    (void)hv_store(hv,name,len,&PL_sv_no,0);
	}
    }
    return FALSE;
}

void *aglo_c_object(pTHX_ SV **object, const char *class,const char *context) {
    SV *sv;
    HV *stash, *class_stash;
    IV address;

    sv = *object;
    SvGETMAGIC(sv);
    if (!SvROK(sv)) {
        if (SvOK(sv)) croak("%s is not a reference", context);
        croak("%s is undefined", context);
    }
    sv = SvRV(sv);
    if (!SvOBJECT(sv)) croak("%s is not an object reference", context);
    stash = SvSTASH(sv);
    /* Is the next even possible ? */
    if (!stash) croak("%s is not a typed reference", context);
    class_stash = gv_stashpv(class, FALSE);
    if (!my_isa_lookup(aTHX_ stash, class, class_stash, strlen(class), 0))
        croak("%s is not a %s reference", context, class);
    address = SvIV(sv);
    if (!address) croak("%s object has a NULL pointer", class);
    *object = sv;
    return INT2PTR(void *, address);
}

void *aglo_c_check(pTHX_ SV *object, const char *class, const char *context) {
    HV *stash, *class_stash;
    IV address;

    if (!SvOBJECT(object)) croak("%s is not an object reference", context);
    stash = SvSTASH(object);
    /* Is the next even possible ? */
    if (!stash) croak("%s is not a typed reference", context);
    class_stash = gv_stashpv(class, FALSE);
    if (!my_isa_lookup(aTHX_ stash, class, class_stash, strlen(class), 0))
        croak("%s is not a %s reference", context, class);
    address = SvIV(object);
    if (!address) croak("%s object has a NULL pointer", class);
    return INT2PTR(void *, address);
}

void aglo_frame_coordinates(aglo_state state,
                            aglo_point min_frame, aglo_point max_frame) {
    aglo_vertex i;
    aglo_unsigned j, d;
    aglo_real *here;

    aglo_graph graph = state->graph;
    if (graph->vertices <= 0) croak("No vertices in graph");

    d = state->dimensions;
    if (d <= 0) return;
    here = state->point[0];
    Copy(here, min_frame, d, aglo_real);
    Copy(here, max_frame, d, aglo_real);

    for (i=1;i<graph->vertices;i++) {
        here = state->point[i];
        for (j=0; j<d; j++, here++) {
            if (*here < min_frame[j]) min_frame[j] = *here;
            if (*here > max_frame[j]) max_frame[j] = *here;
        }
    }
}

void aglo_iso_frame_coordinates(aglo_state state,
                                aglo_point min_frame, aglo_point max_frame) {
    aglo_unsigned i, d;
    aglo_real	  frame_size;

    d = state->dimensions;

    if (d <= 0) return;

    aglo_frame_coordinates(state, min_frame, max_frame);
    frame_size = max_frame[0] - min_frame[0];
    for (i=1; i<d; i++)
        if (frame_size < max_frame[i]-min_frame[i])
            frame_size = max_frame[i]-min_frame[i];
    for (i=0; i<d; i++) {
        aglo_real extra = (frame_size - (max_frame[i]-min_frame[i]))/2;
        min_frame[i] -= extra;
        max_frame[i] += extra;
    }
}

void aglo_normalize_state(aglo_state state) {
    aglo_graph graph = state->graph;
    aglo_real *frame, frame_size;
    aglo_unsigned i, j, d;
    aglo_vertex	v;

    v = graph->vertices;
    d = state->dimensions;

    if (v <= 0 || d <= 0) return;

    New(__LINE__, frame, 2*d, aglo_real);
    aglo_frame_coordinates(state, frame, &frame[d]);
    /* frame now represents the smallest enclosing rectangle */

    frame_size = frame[d] - frame[0];
    for (i=1; i<d; i++)
        if (frame_size < frame[d+i]-frame[i]) frame_size = frame[d+i]-frame[i];
    for (i=0; i<d; i++) frame[i] -= (frame_size - (frame[d+i]-frame[i])) / 2;
    if (frame_size == 0) frame_size = 1;

    for (j=0; j<v; j++) {
        aglo_real *here = state->point[j];
        for (i=0; i<d; i++, here++) *here = (*here-frame[i])/frame_size;
    }

    Safefree(frame);
    state->sequence++;
}

/* This dumps a value wherever the stackpointer hangs out, so take care */
static void init_rand(pTHX) {
    /*
    (void) seedDrand01((Rand_seed_t) Perl_seed(aTHX));
    PL_srand_called = TRUE;
    */
    /* We call pp_rand here so that Drand01 get initialized if rand()
       or srand() has not already been called
    */
    struct op dmy_op;
    struct op *old_op = PL_op;

    memzero((char*)(&dmy_op), sizeof(struct op));
    /* we let pp_rand() borrow the TARG allocated for the XS sub */
    dmy_op.op_targ = PL_op->op_targ;
    PL_op = &dmy_op;
    (void)*(PL_ppaddr[OP_RAND])(aTHX);
    PL_op = old_op;
}

/* Jiggle a random point a bit in a random direction */
static void jitter(pTHX_ aglo_state state, aglo_real distance) {
    aglo_unsigned d;
    aglo_vertex v;
    aglo_real rand_val;

    d = state->dimensions;
    if (d <= 0) croak("Cannot jitter a 0-dimensional state");
    v = state->graph->vertices;
    if (v <= 0) croak("Cannot jitter a graph without vertices");

    if (!PL_srand_called) init_rand(aTHX);
    do {
        do {
            rand_val = Drand01();
        } while (rand_val == 0);
        rand_val = 2*rand_val-1;
    } while (rand_val == 0);
    state->point[(aglo_unsigned) (Drand01()*v)][(aglo_unsigned)(Drand01()*d)] += distance * rand_val;
    state->sequence++;
}

void aglo_randomize(pTHX_ aglo_state state, aglo_real size) {
    aglo_unsigned i, d;
    aglo_vertex p, v;
    aglo_real rand_val;

    d = state->dimensions;
    v = state->graph->vertices;
    if (!PL_srand_called) init_rand(aTHX);
    for (p=0; p<v; p++) {
        aglo_real *here = state->point[p];
        for (i=0; i<d; i++) {
            do {
                rand_val = Drand01();
            } while (rand_val == 0);
            here[i] = (rand_val*2-1)*size;
        }
    }
    state->sequence++;
}

static void zero_gradient(aglo_gradient gradient, aglo_unsigned size) {
    aglo_unsigned i;

    for (i=0; i<size; i++) gradient[i] = 0;
}

static void limit_displacement(aglo_state state, aglo_real temperature) {
    aglo_unsigned i, gradient_size;
    aglo_gradient gradient = state->gradient;
    aglo_real mag;

    gradient_size = state->graph->vertices * state->dimensions;
    mag = aglo_point_mag(gradient_size, gradient);
    if (mag <= temperature) return;
    mag = temperature / mag;
    for (i=0; i<gradient_size; i++) gradient[i] *= mag;
}

static void calculate_aesth_forces(pTHX_ aglo_state state) {
    aglo_unsigned i, gradient_size;
    use_force force, old_base;
    aglo_gradient gradient	 = state->gradient;
    aglo_gradient force_gradient = state->force_gradient;

    gradient_size = state->graph->vertices * state->dimensions;
    zero_gradient(gradient, gradient_size);

    for (force = old_base = state->forces; force; force = force->next) {
        zero_gradient(force_gradient, gradient_size);
        force->force->aesth_gradient(aTHX_ state, force_gradient, force->private);
        for (i=0;i<gradient_size;i++)
            gradient[i] += force_gradient[i] * force->weight;
        /* Check if someone called clear_forces */
        if (state->forces != old_base) {
            warn("Forces were cleared during an actual forcing calculation");
            break;
        }
    }
}

static void make_move(aglo_state state) {
    aglo_unsigned i, gradient_size;
    aglo_gradient gradient, point;

    gradient_size = state->graph->vertices * state->dimensions;
    gradient = state->gradient;
    /* Here I abuse the fact that I know points are allocated as a block */
    point = state->point[0];

    for (i=0;i<gradient_size;i++) point[i] += gradient[i];
    state->sequence++;
}

void aglo_step(pTHX_ aglo_state state, aglo_real temperature, aglo_real jitter_size) {
    if (jitter_size) jitter(aTHX_ state, jitter_size);

    calculate_aesth_forces(aTHX_ state);
    limit_displacement(state, temperature);
    make_move(state);
}

XS(boot_Graph__Layout__Aesthetic__Force__Centripetal);
XS(boot_Graph__Layout__Aesthetic__Force__NodeRepulsion);
XS(boot_Graph__Layout__Aesthetic__Force__NodeEdgeRepulsion);
XS(boot_Graph__Layout__Aesthetic__Force__MinEdgeLength);
XS(boot_Graph__Layout__Aesthetic__Force__ParentLeft);
XS(boot_Graph__Layout__Aesthetic__Force__MinEdgeIntersect);
XS(boot_Graph__Layout__Aesthetic__Force__MinEdgeIntersect2);
XS(boot_Graph__Layout__Aesthetic__Force__MinLevelVariance);
XS(boot_Graph__Layout__Aesthetic__Force__Perl);

MODULE = Graph::Layout::Aesthetic		PACKAGE = Graph::Layout::Aesthetic::Topology
PROTOTYPES: ENABLE

SV *
new_vertices(char *class, aglo_vertex nr_vertices)
  PREINIT:
    aglo_vertex i;
    aglo_graph topology;
  CODE:
    Newc(__LINE__, topology, sizeof(struct aglo_graph)+(nr_vertices-1)*sizeof(aglo_edge_record),
         char, struct aglo_graph);
    topology->done = false;
    topology->vertices = nr_vertices;
    for (i=0; i<nr_vertices; i++) topology->edge_table[i] = NULL;
        /* topology->edge_table[u] = f_edge; */
    topology->level_sequence = 0;
    topology->at_level = NULL;
    topology->level_sorted_vertex = NULL;
    topology->level2nodes = NULL;
    topology->user_data = topology->private_data = NULL;
    RETVAL = NEWSV(1, 0);
    sv_setref_pv(RETVAL, class, (void*) topology);
  OUTPUT:
    RETVAL

aglo_vertex
nr_vertices(aglo_graph topology)
  CODE:
    RETVAL = topology->vertices;
  OUTPUT:
    RETVAL

void
neighbors(aglo_graph topology, aglo_vertex vertex)
  PREINIT:
    aglo_edge_record here, next;
  PPCODE:
    if (vertex >= topology->vertices)
        croak("Vertex number %"UVuf" is invalid, there are only %"UVuf" in the topology",
              (UV) vertex, (UV) topology->vertices);
    here = topology->edge_table[vertex];
    while (here) {
        next = here->next;
        XPUSHs(sv_2mortal(newSVuv(here->tail)));
        here = next;
    }

void
forward_neighbors(aglo_graph topology, aglo_vertex vertex)
  PREINIT:
    aglo_edge_record here, next;
  PPCODE:
    if (vertex >= topology->vertices)
        croak("Vertex number %"UVuf" is invalid, there are only %"UVuf" in the topology",
        (UV) vertex, (UV) topology->vertices);
    here = topology->edge_table[vertex];
    while (here) {
        next = here->next;
        if (here->forward) XPUSHs(sv_2mortal(newSVuv(here->tail)));
        here = next;
    }

void
edges(aglo_graph topology)
  PREINIT:
    aglo_vertex i;
  PPCODE:
    for (i=0; i<topology->vertices; i++) {
        aglo_edge_record here, next;
        for (here = topology->edge_table[i]; here; here = next) {
            next = here->next;
            if (here->forward) {
                AV *av = newAV();
                av_extend(av, 2-1);
                av_push(av, newSVuv(i));
                av_push(av, newSVuv(here->tail));
                XPUSHs(sv_2mortal(newRV_noinc((SV *) av)));
            }
        }
    }

void
add_edge(aglo_graph topology, aglo_vertex u, aglo_vertex v, aglo_boolean forward=1)
  PREINIT:
    aglo_edge_record f_edge, b_edge;
  PPCODE:
    if (topology->done) croak("Cannot add nodes to a finished topology");
    if (u >= topology->vertices)
        croak("Vertex number %"UVuf" is invalid, there are only %"UVuf" in the topology",
              (UV) u, (UV) topology->vertices);
    if (v >= topology->vertices)
        croak("Vertex number %"UVuf" is invalid, there are only %"UVuf" in the topology",
              (UV) v, (UV) topology->vertices);
    if (u == v) croak("Vertex %"UVuf" connects to itself", (UV) u);

    New(_LINE__, f_edge, 1, struct aglo_edge_record);
    f_edge->tail = v;
    f_edge->forward = forward;
    f_edge->next = topology->edge_table[u];
    topology->edge_table[u] = f_edge;

    New(__LINE__, b_edge, 1, struct aglo_edge_record);
    b_edge->tail = u;
    b_edge->forward = !forward;
    b_edge->next = topology->edge_table[v];
    topology->edge_table[v] = b_edge;

void
finish(aglo_graph topology)
  PPCODE:
    if (topology->done) croak("Topology is already finished");
    topology->done = true;

aglo_boolean
finished(aglo_graph topology)
  CODE:
    RETVAL = topology->done;
  OUTPUT:
    RETVAL

void
levels(aglo_graph topology)
  PREINIT:
    aglo_vertex i;
  PPCODE:
    at_setup_node_level(topology);
    EXTEND(SP, topology->vertices);
    for (i=0; i<topology->vertices; i++)
        PUSHs(sv_2mortal(newSVnv(topology->at_level[i])));

void
user_data(aglo_graph topology, SV *new_user_data=0)
  PPCODE:
    if (GIMME_V != G_VOID)
        XPUSHs(topology->user_data ? topology->user_data : &PL_sv_undef);
    if (new_user_data) {
        if (topology->user_data) sv_2mortal(topology->user_data);
        topology->user_data = newSVsv(new_user_data);
    }

void
_private_data(aglo_graph topology, SV *new_private_data=0)
  PPCODE:
    if (GIMME_V != G_VOID)
        XPUSHs(topology->private_data ? topology->private_data : &PL_sv_undef);
    if (new_private_data) {
        if (topology->private_data) sv_2mortal(topology->private_data);
        topology->private_data = newSVsv(new_private_data);
    }

void
DESTROY(aglo_graph topology)
  PREINIT:
    aglo_vertex i;
  PPCODE:
    if (topology->user_data)	sv_2mortal(topology->user_data);
    if (topology->private_data) sv_2mortal(topology->private_data);
    if (topology->at_level) Safefree(topology->at_level);
    if (topology->level_sorted_vertex) Safefree(topology->level_sorted_vertex);
    if (topology->level2nodes) Safefree(topology->level2nodes);
    for (i=0; i<topology->vertices; i++) {
        aglo_edge_record next, here = topology->edge_table[i];
        while (here) {
            next = here->next;
            Safefree(here);
            here = next;
        }
    }
    Safefree(topology);

MODULE = Graph::Layout::Aesthetic		PACKAGE = Graph::Layout::Aesthetic::Force

void
user_data(aglo_force force, SV *new_user_data=0)
  PPCODE:
    if (GIMME_V != G_VOID)
        XPUSHs(force->user_data ? force->user_data : &PL_sv_undef);
    if (new_user_data) {
        if (force->user_data) sv_2mortal(force->user_data);
        force->user_data = newSVsv(new_user_data);
    }

void
_private_data(aglo_force force, SV *new_private_data=0)
  PPCODE:
    if (GIMME_V != G_VOID)
        XPUSHs(force->private_data ? force->private_data : &PL_sv_undef);
    if (new_private_data) {
        if (force->private_data) sv_2mortal(force->private_data);
        force->private_data = newSVsv(new_private_data);
    }

void
DESTROY(aglo_force force)
  PPCODE:
    if (force->private_data) sv_2mortal(force->private_data);
    if (force->user_data)    sv_2mortal(force->user_data);
    Safefree(force);

MODULE = Graph::Layout::Aesthetic		PACKAGE = Graph::Layout::Aesthetic

SV *
new_state(char *class, SV *topology, aglo_signed nr_dimensions=2)
  PREINIT:
    aglo_graph  gr;
    aglo_state  state;
    aglo_real  *here;
    aglo_vertex i;
  CODE:
    /* This replaces topology by what it references */
    gr = C_OBJECT(topology, "Graph::Layout::Aesthetic::Topology", "topology");
    if (!gr->done) croak("Topology hasn't been finished");
    if (nr_dimensions < 0) croak("Nr_dimensions must not be negative");

    Newc(__LINE__, state, sizeof(struct aglo_state)+
                   (gr->vertices-1)*sizeof(aglo_point),
         char, struct aglo_state);
    New(__LINE__, here, (3*gr->vertices+1) * nr_dimensions, aglo_real);
    for (i=0; i<gr->vertices; i++) {
        state->point[i] = here;
        here += nr_dimensions;
    }

    state->centroid_sequence = 0;
    state->cached_centroid = here;
    here += nr_dimensions;

    state->gradient = here;
    here += nr_dimensions * gr->vertices;
    state->force_gradient = here;
    here += nr_dimensions * gr->vertices;

    state->forces = 0;
    state->dimensions = nr_dimensions;
    state->graph = gr;
    state->graph_sv = newRV(topology);
    /* so it's out of sequence with things that are 0 */
    state->sequence = 1;

    state->temperature = 1e2;
    state->end_temperature = 1e-3;
    state->iterations = 1000;

    state->paused = 0;

    RETVAL = NEWSV(1, 0);
    sv_setref_pv(RETVAL, class, (void*) state);
  OUTPUT:
    RETVAL

void
paused(aglo_state state, aglo_boolean new_paused=0)
  PPCODE:
    if (GIMME_V != G_VOID) XPUSHs(state->paused ? &PL_sv_yes : &PL_sv_no);
    if (items > 1) state->paused = new_paused;

aglo_unsigned
nr_dimensions(aglo_state state)
  CODE:
    RETVAL = state->dimensions;
  OUTPUT:
    RETVAL

aglo_real
temperature(aglo_state state, aglo_real temperature=0, aglo_boolean warner=1)
  CODE:
    RETVAL = state->temperature;
    if (items > 1) {
        if (temperature <= 0)
            croak("Temperature %"NVff" should be > 0", (NV) temperature);
        if (warner && temperature < state->end_temperature)
            warn("Temperature %"NVff" should probably be >= end_temperature %"NVff,
                 (NV) temperature, (NV) state->end_temperature);
        state->temperature = temperature;
    }
  OUTPUT:
    RETVAL

aglo_real
end_temperature(aglo_state state, aglo_real end_temperature=0, aglo_boolean warner=1)
  CODE:
    RETVAL = state->end_temperature;
    if (items > 1) {
        if (end_temperature <= 0)
            croak("End_temperature %"NVff" should be > 0", (NV) end_temperature);
        if (warner && state->temperature < end_temperature)
            warn("Temperature %"NVff" should probably be >= end_temperature %"NVff,
                 (NV) state->temperature, (NV) end_temperature);
        state->end_temperature = end_temperature;
    }
  OUTPUT:
    RETVAL

void
coordinates(aglo_state state, aglo_vertex vertex, ...)
  PREINIT:
    aglo_unsigned i, d;
    aglo_point v;
  PPCODE:
    if (vertex >= state->graph->vertices)
        croak("Vertex number %"UVuf" is invalid, there are only %"UVuf" in the topology",
              (UV) vertex, (UV) state->graph->vertices);
    d = state->dimensions;
    v = state->point[vertex];

    /* First push the result */
    switch(GIMME_V) {
        AV *av;
      case G_ARRAY:
        EXTEND(SP, d);
        for (i=0; i<d; i++) PUSHs(sv_2mortal(newSVnv(v[i])));
        break;
      case G_SCALAR:
        av = newAV();
	XPUSHs(sv_2mortal(newRV_noinc((SV *) av)));

	av_extend(av, d-1);
        for (i=0; i<d; i++) av_push(av, newSVnv(v[i]));
        break;
      default:
        break;
    }

    /* next see if there are arguments */
    if (items > 2) {
        state->sequence++;
        SvGETMAGIC(ST(2));
        if (items == 3 && SvROK(ST(2))) {
            AV *av = (AV*) SvRV(ST(2));
            if (SvTYPE(av) != SVt_PVAV)
                croak("Coordinates reference is not an array reference");
            if (av_len(av)+1 != d)
                croak("Expected %"UVuf" coordinates (dimension), but got %"UVuf,
                      (UV) d, (UV) (av_len(av)+1));
            for (i=0; i<d; i++) {
                SV **sp, *sv;
                sp = av_fetch(av, i, 0);
                if (!sp) croak("Vertex %"UVuf", coordinate %"UVuf" is unset",
                               (UV) vertex, (UV) i);
                sv = *sp;
                v[i] = (aglo_real) SvNV(sv);
            }
        } else {
            if (items-2 != d)
                croak("Expected %"UVuf" coordinates (dimension), but got %"UVuf,
                      (UV) d, (UV) (items-2));
            for (i=0; i<d; i++) v[i] = (aglo_real) SvNV(ST(2+i));
        }
    }

void
all_coordinates(aglo_state state, ...)
  PREINIT:
    aglo_unsigned j, d;
    aglo_vertex i, v;
    AV *coords;
    aglo_point p;
  PPCODE:
    d = state->dimensions;
    v = state->graph->vertices;

    /* First push the result */
    switch(GIMME_V) {
        AV *av;
      case G_ARRAY:
        EXTEND(SP, v);
        for (i=0; i<v; i++) {
            AV *pav = newAV();
            PUSHs(sv_2mortal(newRV_noinc((SV *) pav)));

            p = state->point[i];
            av_extend(pav, d-1);
            for (j=0; j<d; j++) av_push(pav, newSVnv(p[j]));
        }
        break;
      case G_SCALAR:
        av = newAV();
	XPUSHs(sv_2mortal(newRV_noinc((SV *) av)));

	av_extend(av, v-1);
        for (i=0; i<v; i++) {
            AV *pav = newAV();
            av_push(av, newRV_noinc((SV *) pav));

            p = state->point[i];
            av_extend(pav, d-1);
            for (j=0; j<d; j++) av_push(pav, newSVnv(p[j]));
        }
        break;
      default:
        break;
    }

    /* next see if there are arguments */
    if (items > 1) {
        state->sequence++;
        if (items == 2) {
            AV *av;
            /* Must be ref ref */
            SvGETMAGIC(ST(1));
            if (!SvROK(ST(1)))
                croak("First coordinate is not a reference");
            av = (AV*) SvRV(ST(1));
            if (SvTYPE(av) != SVt_PVAV)
                croak("First coordinate is not an array reference");
            if (av_len(av)+1 != v) {
                if (v == 1) {
                    i=0;
                    coords = av;
                    goto COORD;
                }
                croak("Expected %"UVuf" coordinate references (number of vertices), but got %"UVuf, (UV) v, (UV) (av_len(av)+1));
            }
            if (v == 1 && d == 1) {
                /* We are still undecided here, look one level deeper */
                SV **sp, *s;

                sp = av_fetch(av, 0, 0);
                if (!sp) croak("Vertex 0 is unset");
                s = *sp;
                SvGETMAGIC(s);
                if (SvROK(s)) {
                    coords = (AV*) SvRV(s);
                    if (SvTYPE(coords) != SVt_PVAV)
                        croak("Vertex 0 is not an array reference");
                    if (av_len(coords)+1 != d)
                        croak("Vertex 0 has %"UVuf" coordinates, but I expected 1 (the dimension)", (UV) (av_len(coords)+1));
                    sp = av_fetch(coords, 0, 0);
                    if (!sp) croak("Vertex 0, coordinate 0 is unset");
                    s = *sp;
                }
                state->point[0][0] = (aglo_real) SvNV(s);
            } else {
                for (i=0; i<v; i++) {
                    SV **sp, *s;

                    sp = av_fetch(av, i, 0);
                    if (!sp) croak("Vertex %"UVuf" is unset", (UV) i);
                    s = *sp;
                    SvGETMAGIC(s);
                    if (!SvROK(s))
                        croak("Vertex %"UVuf" is not a reference", (UV) i);
                    coords = (AV*) SvRV(s);
                    if (SvTYPE(coords) != SVt_PVAV)
                        croak("Vertex %"UVuf" is not an array reference", (UV) i);
                    if (av_len(coords)+1 != d)
                        croak("Vertex %"UVuf" has %"UVuf" coordinates, but I expected %"UVuf" (the dimension)", (UV) i, (UV) (av_len(coords)+1), (UV) d);
                    p = state->point[i];
                    for (j=0; j<d; j++) {
                        SV *s, **sv = av_fetch(coords, j, 0);
                        if (!sv) croak("Vertex %"UVuf", coordinate %"UVuf" is unset",
                                       (UV) i, (UV) j);
                        s = *sv;
                        p[j] = (aglo_real) SvNV(s);
                    }
                }
            }
        } else {
            if (items-1 != v)
                croak("Expected %"UVuf" coordinate references (number of vertices), but got %"UVuf, (UV) v, (UV) (items-1));
            for (i=0; i<v; i++) {
                SvGETMAGIC(ST(i+1));
                if (!SvROK(ST(i+1))) croak("Vertex %"UVuf" is not a reference", (UV) i);
                coords = (AV*) SvRV(ST(i+1));
                if (SvTYPE(coords) != SVt_PVAV)
                    croak("Vertex %"UVuf" is not an array reference", (UV) i);
              COORD:
                if (av_len(coords)+1 != d)
                    croak("Vertex %"UVuf" has %"UVuf" coordinates, but I expected %"UVuf" (the dimension)", (UV) i, (UV) (av_len(coords)+1), (UV) d);
                p = state->point[i];
                for (j=0; j<d; j++) {
                    SV *s, **sv = av_fetch(coords, j, 0);
                    if (!sv) croak("Vertex %"UVuf", coordinate %"UVuf" is unset",
                                   (UV) i, (UV) j);
                    s = *sv;
                    p[j] = (aglo_real) SvNV(s);
                }
            }
        }
    }

void
increasing_edges(aglo_state state)
  PREINIT:
    aglo_vertex i;
    aglo_unsigned j, d;
    aglo_graph graph;
    aglo_point p;
    aglo_edge_record here;
    AV *rav, *av, *av_from, *av_to;
  PPCODE:
    d = state->dimensions;
    graph = state->graph;
    switch(GIMME_V) {
      case G_ARRAY:
        for (i=0; i<graph->vertices; i++) {
            for (here = graph->edge_table[i]; here; here = here->next) {
                if (i < here->tail) {
                    av = newAV();
                    av_extend(av, 2-1);
                    XPUSHs(sv_2mortal(newRV_noinc((SV *) av)));

                    av_from = newAV();
                    av_push(av, newRV_noinc((SV *) av_from));
                    av_extend(av_from, d-1);
                    p = state->point[i];
                    for (j=0; j<d; j++) av_push(av_from, newSVnv(p[j]));

                    av_to = newAV();
                    av_push(av, newRV_noinc((SV *) av_to));
                    av_extend(av_to, d-1);
                    p = state->point[here->tail];
                    for (j=0; j<d; j++) av_push(av_to, newSVnv(p[j]));
                }
            }
        }
        break;
      case G_SCALAR:
        rav = newAV();
	XPUSHs(sv_2mortal(newRV_noinc((SV *) rav)));

        for (i=0; i<graph->vertices; i++) {
            for (here = graph->edge_table[i]; here; here = here->next) {
                if (i < here->tail) {
                    av = newAV();
                    av_extend(av, 2-1);
                    av_push(rav, newRV_noinc((SV *) av));

                    av_from = newAV();
                    av_push(av, newRV_noinc((SV *) av_from));
                    av_extend(av_from, d-1);
                    p = state->point[i];
                    for (j=0; j<d; j++) av_push(av_from, newSVnv(p[j]));

                    av_to = newAV();
                    av_push(av, newRV_noinc((SV *) av_to));
                    av_extend(av_to, d-1);
                    p = state->point[here->tail];
                    for (j=0; j<d; j++) av_push(av_to, newSVnv(p[j]));
                }
            }
        }
        break;
      default:
        break;
    }

void
zero(aglo_state state)
  PREINIT:
    aglo_unsigned i, d;
    aglo_vertex p, v;
  PPCODE:
    d = state->dimensions;
    v = state->graph->vertices;
    for (p=0; p<v; p++) {
        aglo_real *here = state->point[p];
        for (i=0; i<d; i++) here[i] = 0;
    }
    state->sequence++;

void
randomize(aglo_state state, aglo_real size = 1)
  PPCODE:
    aglo_randomize(aTHX_ state, size);

void
frame(aglo_state state)
  PREINIT:
    aglo_real *frame;
    aglo_unsigned i, d;
    AV *av;
  PPCODE:
    if (state->graph->vertices > 0) {
        d = state->dimensions;

        New(__LINE__, frame, 2*d, aglo_real);
        aglo_frame_coordinates(state, frame, &frame[d]);

        EXTEND(SP, 2);

        av = newAV();
	av_extend(av, d-1);
        for (i=0; i<d; i++) av_push(av, newSVnv(frame[i]));
	PUSHs(sv_2mortal(newRV_noinc((SV *) av)));

        av = newAV();
	av_extend(av, d-1);
        for (i=0; i<d; i++) av_push(av, newSVnv(frame[i+d]));
	PUSHs(sv_2mortal(newRV_noinc((SV *) av)));

        Safefree(frame);
    }

void
iso_frame(aglo_state state)
  PREINIT:
    aglo_real *frame;
    aglo_unsigned i, d;
    AV *av;
  PPCODE:
    if (state->graph->vertices > 0) {
        d = state->dimensions;

        New(__LINE__, frame, 2*d, aglo_real);
        aglo_iso_frame_coordinates(state, frame, &frame[d]);

        EXTEND(SP, 2);

        av = newAV();
	av_extend(av, d-1);
        for (i=0; i<d; i++) av_push(av, newSVnv(frame[i]));
	PUSHs(sv_2mortal(newRV_noinc((SV *) av)));

        av = newAV();
	av_extend(av, d-1);
        for (i=0; i<d; i++) av_push(av, newSVnv(frame[i+d]));
	PUSHs(sv_2mortal(newRV_noinc((SV *) av)));

        Safefree(frame);
    }

void
normalize(aglo_state state)
  PPCODE:
    aglo_normalize_state(state);

void
jitter(aglo_state state, aglo_real distance=1e-5)
  PPCODE:
    jitter(aTHX_ state, distance);

void
_add_force(SV *state, SV *force, aglo_real weight=1)
  PREINIT:
    aglo_state st;
    aglo_force fo;
    use_force  use;
    void *private;
  PPCODE:
    /* This replaces force by what it references */
    fo = C_OBJECT(force, "Graph::Layout::Aesthetic::Force", "force");
    /* This replaces state by what it references */
    st = C_OBJECT(state, "Graph::Layout::Aesthetic", "state");

    sv_2mortal(SvREFCNT_inc(force));
    # Make sure we do this test before allocating anything (permanently)
    private = fo->aesth_setup(aTHX_ force, state, st);

    New(__LINE__, use, 1, struct use_force);

    use->weight = weight;
    use->force = fo;
    use->force_sv = newRV(force);
    use->private = private;
    use->next = st->forces;

    st->forces = use;

void
forces(aglo_state state)
  PREINIT:
    use_force force;
  PPCODE:
    switch(GIMME_V) {
        AV *rav;
      case G_ARRAY:
        for (force = state->forces; force; force = force->next) {
            AV *av = newAV();
            XPUSHs(sv_2mortal(newRV_noinc((SV *) av)));
            av_extend(av, 2-1);
            SvREFCNT_inc(force->force_sv);
            av_push(av, force->force_sv);
            av_push(av, newSVnv(force->weight));
        }
        break;
      case G_SCALAR:
        rav = newAV();
	XPUSHs(sv_2mortal(newRV_noinc((SV *) rav)));
        for (force = state->forces; force; force = force->next) {
            AV *av = newAV();
            av_push(rav, newRV_noinc((SV *) av));

            av_extend(av, 2-1);
            SvREFCNT_inc(force->force_sv);
            av_push(av, force->force_sv);
            av_push(av, newSVnv(force->weight));
        }
        break;
      default:
        break;
    }


void
init_gloss(aglo_state state, aglo_real temperature, aglo_real end_temperature, aglo_signed iterations, aglo_real randomize_size=1)
  PPCODE:
    if (temperature <= 0)
        croak("Temperature %"NVff" should be > 0", (NV) temperature);
    if (end_temperature <= 0)
        croak("End_temperature %"NVff" should be > 0", (NV) end_temperature);
    if (temperature < end_temperature)
        warn("Temperature %"NVff" should probably be >= end_temperature %"NVff,
              (NV) temperature, (NV) end_temperature);
    if (iterations < 0)
        croak("Iterations %"IVdf" should be >= 0", (IV) iterations);
    state->temperature = temperature;
    state->end_temperature = end_temperature;
    state->iterations = iterations;
    if (randomize_size > 0) aglo_randomize(aTHX_ state, randomize_size);

void
_gloss(aglo_state state, aglo_real pause_time=1e50)
  PREINIT:
    time_t now;
    aglo_real lambda;
  PPCODE:
    if (state->iterations <= 0) croak("No more iterations left");
    lambda = pow(state->temperature / state->end_temperature, 1.0 / state->iterations);
    state->paused = 0;
    while (state->iterations > 0 && !state->paused) {
        aglo_step(aTHX_ state, state->temperature,
                  state->temperature < 1e-5 ? state->temperature : 1e-5);

        state->temperature /= lambda;
        state->iterations--;

        if (items > 1) {
            time(&now);
            if (pause_time <= now) break;
        }
    }
    /* We lose the value anyways on exception in gradient,
       but restore is just a nicity, not part of the API */

void
step(aglo_state state, aglo_real temperature = state->temperature, aglo_real jitter_size = 1e-5)
  PPCODE:
    if (items < 3 && temperature < jitter_size) jitter_size = temperature;
    aglo_step(aTHX_ state, temperature, jitter_size);

void gradient(aglo_state state)
  PREINIT:
    aglo_unsigned i, d;
    aglo_vertex p, v;
    aglo_gradient gradient;
  PPCODE:
    calculate_aesth_forces(aTHX_ state);

    gradient = state->gradient;
    d = state->dimensions;
    v = state->graph->vertices;
    switch(GIMME_V) {
        AV *rav, *av;
      case G_ARRAY:
        EXTEND(SP, v);
        for (p=0; p<v; p++) {
            av = newAV();
            av_extend(av, d-1);
            PUSHs(sv_2mortal(newRV_noinc((SV *) av)));
            for (i=0; i<d; i++, gradient++) av_push(av, newSVnv(*gradient));
        }
        break;
      case G_SCALAR:
        rav = newAV();
	XPUSHs(sv_2mortal(newRV_noinc((SV *) rav)));

	av_extend(rav, v-1);
        for (p=0; p<v; p++) {
            av = newAV();
            av_extend(av, d-1);
            av_push(rav, newRV_noinc((SV *) av));
            for (i=0; i<d; i++, gradient++) av_push(av, newSVnv(*gradient));
        }
        break;
      default:
        break;
    }

aglo_real
stress(aglo_state state)
  CODE:
    calculate_aesth_forces(aTHX_ state);
    RETVAL = aglo_point_mag(state->dimensions*state->graph->vertices, state->gradient);
  OUTPUT:
    RETVAL

aglo_unsigned
iterations(aglo_state state, aglo_signed iterations=0)
  CODE:
    RETVAL = state->iterations;
    if (items > 1) {
        if (iterations < 0)
            croak("Iterations %"IVdf" should be >= 0", (IV) iterations);
        state->iterations = iterations;
    }
  OUTPUT:
    RETVAL

SV *
topology(aglo_state state)
  CODE:
    SvREFCNT_inc(state->graph_sv);
    RETVAL = state->graph_sv;
  OUTPUT:
    RETVAL

void
DESTROY(SV *state)
  PREINIT:
    use_force here;
    aglo_state st;
    aglo_boolean warned;
  PPCODE:
    /* This replaces state by what it references */
    st = C_OBJECT(state, "Graph::Layout::Aesthetic", "state");

    warned = 0;
    ENTER;
    EXTEND(SP, 1);
    while (st->forces) {
        I32 count;
        here = st->forces;
        SAVETMPS;

        PUSHMARK(SP);
        PUSHs(sv_2mortal(newRV(state)));
        PUTBACK ;

        /* This is an infinite loop if clear_forces makes no progress.
           So be it, it will indicate a bug anyways, and it's better than
           leaking memory */
        count = call_method("clear_forces", G_EVAL|G_KEEPERR|G_VOID);
        SPAGAIN;
        if (count) {
            if (count < 0) croak("Forced void context call 'clear_forces' succeeded in returning %d values. This is impossible", (int) count);
            SP -= count;
        }
        FREETMPS;
        if (here == st->forces && !warned) {
            warned = 1;
            warn("clear_forces is making no progress during DESTROY");
        }
    }
    LEAVE;
    sv_2mortal(st->graph_sv);
    Safefree(st->point[0]);
    Safefree(st);

void
clear_forces(aglo_state state)
  PREINIT:
    use_force here;
    aglo_aesth_cleanup_fx *cleanup;
    void *private;
  PPCODE:
    while (state->forces) {
        here = state->forces;
        /* Keep datastructure valid in case the cleanup call dies */
        state->forces = here->next;
        cleanup = here->force->aesth_cleanup;
        private = here->private;
        sv_2mortal(here->force_sv);
        Safefree(here);
        cleanup(aTHX_ state, private);
    }

BOOT:
  PUSHMARK(SP);
  boot_Graph__Layout__Aesthetic__Force__Centripetal(aTHX_ cv);

  PUSHMARK(SP);
  boot_Graph__Layout__Aesthetic__Force__NodeRepulsion(aTHX_ cv);

  PUSHMARK(SP);
  boot_Graph__Layout__Aesthetic__Force__NodeEdgeRepulsion(aTHX_ cv);

  PUSHMARK(SP);
  boot_Graph__Layout__Aesthetic__Force__MinEdgeLength(aTHX_ cv);

  PUSHMARK(SP);
  boot_Graph__Layout__Aesthetic__Force__ParentLeft(aTHX_ cv);

  PUSHMARK(SP);
  boot_Graph__Layout__Aesthetic__Force__MinEdgeIntersect(aTHX_ cv);

  PUSHMARK(SP);
  boot_Graph__Layout__Aesthetic__Force__MinEdgeIntersect2(aTHX_ cv);

  PUSHMARK(SP);
  boot_Graph__Layout__Aesthetic__Force__MinLevelVariance(aTHX_ cv);

  PUSHMARK(SP);
  boot_Graph__Layout__Aesthetic__Force__Perl(aTHX_ cv);
