#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include <functions.h>


MODULE = Math::Geometry::Planar::GPC::PolygonXS		PACKAGE = Math::Geometry::Planar::GPC::PolygonXS		

SV* 
new(class)
char* class;

void add_polygon(obj, pg, hole);
SV* obj;
SV* pg;
int hole;


void DESTROY(obj);
SV* obj;

int from_file(obj, filename, want_hole);
SV* obj;
char* filename;
int want_hole;

void to_file(obj, filename, want_hole);
SV* obj;
char* filename;
int want_hole;


SV* clip_to(obj, clp, action);
SV* obj; 
SV* clp; 
char* action

void get_polygons(obj);
    SV* obj
    INIT:
    int c;
    gpc_polygon* p;

    PPCODE:
	p = (gpc_polygon*) SvIV(SvRV(obj));
	PUSHMARK(SP);
	if(p->num_contours < 1) {
		PUTBACK;
		return;
	}
	for(c = 0; c < p->num_contours; c++) {
		XPUSHs(newRV_noinc((SV*) vertex_list_to_pts(&(p->contour[c]))));
	}


#void pts_to_vertex_list(pg, vl);
#SV* pg;
#gpc_vertex_list* vl;

#AV* vertex_list_to_pts(vl);
#gpc_vertex_list* vl;

#void gpc_free_polygon2(p);
#gpc_polygon *p;


