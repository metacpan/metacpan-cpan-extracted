#ifndef aglo_h
# define aglo_h 1

#define C_OBJECT(object, class, context)	\
	aglo_c_object(aTHX_ &(object), class, context)
extern void *aglo_c_object(pTHX_ SV **object, const char *class,
                           const char *context);

#define C_CHECK(object, class, context)	\
	aglo_c_check(aTHX_ object, class, context)
extern void *aglo_c_check(pTHX_ SV *object, const char *class, 
                          const char *context);
typedef UV aglo_unsigned;
typedef IV aglo_signed;
typedef double aglo_real;

typedef enum aglo_boolean { 
    false=0, 
    true=!false
} aglo_boolean;

typedef aglo_unsigned aglo_vertex;

typedef struct aglo_edge_record {
    aglo_vertex	 tail;		/* edge: head -> tail */
    aglo_boolean forward;	/* not tail -> head */
    struct aglo_edge_record *next;
} *aglo_edge_record;

typedef struct aglo_graph {
    aglo_boolean	done;
    aglo_vertex		vertices;
    aglo_signed		level_sequence;	/* abused as a boolean currently, 
                                           later drop finish test and do a real
                                           sequence number check */
    aglo_vertex		nr_levels;
    aglo_signed	       *at_level;
    aglo_vertex	       *level_sorted_vertex;
    aglo_vertex       **level2nodes;
    void	       *private_data;
    void	       *user_data;
    aglo_edge_record	edge_table[1];	/* must be last */
} *aglo_graph;

typedef aglo_real  *aglo_point;
typedef const aglo_real *aglo_const_point;
typedef aglo_real *aglo_gradient;

typedef struct aglo_state {
    aglo_graph graph;		/* Topology */
    SV *graph_sv;		/* perl object reference for graph */
    struct use_force *forces;
    aglo_real		temperature;
    aglo_real		end_temperature;
    aglo_unsigned	iterations;
    aglo_unsigned	dimensions;	/* e.g. 2 means 2-dimensional space */
    aglo_signed		sequence;	/* bumped when state changed */
    aglo_signed		centroid_sequence;
    aglo_gradient	gradient, force_gradient;
    aglo_boolean	paused;
    aglo_point		cached_centroid;
    aglo_point		point[1];	/* State vector, must be last */
} *aglo_state;

typedef void aglo_aesth_gradient_fx(pTHX_ aglo_state state,
                                    aglo_gradient gradient, void *private);
typedef aglo_aesth_gradient_fx *aglo_aesth_gradient;
typedef void *aglo_aesth_setup_fx(pTHX_ SV *force_sv, SV *state_sv, 
                                  aglo_state state);
typedef aglo_aesth_setup_fx *aglo_aesth_setup;
typedef void aglo_aesth_cleanup_fx(pTHX_ aglo_state state, 
                                   void *private);
typedef aglo_aesth_cleanup_fx *aglo_aesth_cleanup;

typedef struct aglo_force {
    aglo_aesth_gradient	aesth_gradient;
    aglo_aesth_setup	aesth_setup;
    aglo_aesth_cleanup	aesth_cleanup;
    void	       *private_data;
    void	       *user_data;
} *aglo_force;

typedef struct use_force {
    aglo_real		weight;
    aglo_force		force;
    SV		       *force_sv;
    void               *private;
    struct use_force    *next;
} *use_force;

extern void aglo_frame_coordinates(aglo_state state,
                                   aglo_point min_frame, 
                                   aglo_point max_frame);
extern void aglo_iso_frame_coordinates(aglo_state state,
                                       aglo_point min_frame, 
                                       aglo_point max_frame);
extern void aglo_normalize_state(aglo_state state);
extern void aglo_randomize(pTHX_ aglo_state state, aglo_real size);
#endif /* aglo_h */
