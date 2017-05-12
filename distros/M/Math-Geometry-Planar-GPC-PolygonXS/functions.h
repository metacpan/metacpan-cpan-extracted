#ifndef __ff_h
#define __ff_h

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "gpc.h"

#define MALLOC(p, b, s, t) {if ((b) > 0) { \
                            p= (t*)malloc(b); if (!(p)) { \
                            fprintf(stderr, "gpc malloc failure: %s\n", s); \
                            exit(0);}} else p= NULL;}

#define FREE(p)            {if (p) {free(p); (p)= NULL;}}


//#define DEBUG_PRINT

#ifdef DEBUG_PRINT
#define dbg_p(x) printf x
#else
#define dbg_p(x)
#endif

extern SV* new(char* class);
extern void add_polygon(SV* obj, SV* pg, int hole);
extern void DESTROY(SV* obj);
extern int from_file(SV* obj, char* filename, int want_hole);
extern void to_file(SV* obj, char* filename, int want_hole);
extern SV* clip_to(SV* obj, SV* clp, char* action);
extern void add_polygon(SV* obj, SV* pg, int hole);
extern void get_polygons(SV* obj);
extern void pts_to_vertex_list(SV* pg, gpc_vertex_list* vl);
extern AV* vertex_list_to_pts(gpc_vertex_list* vl);
extern void gpc_free_polygon2(gpc_polygon *p);
#endif