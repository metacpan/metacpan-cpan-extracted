//file: Polygon/functions.c
/*

Copyright 2004 Eric L. Wilhelm

GPL / Artistic License
See Polygon.pm for details

Version 0.04

*/

#include "gpc.h"
#include "gpc.c"

/*#define DEBUG_PRINT*/

#ifdef DEBUG_PRINT
#define dbg_p(x) printf x
#else
#define dbg_p(x)
#endif

SV* new (char* class);
void add_polygon(SV* obj, SV* pg, int hole);
void DESTROY(SV* obj);
int from_file(SV* obj, char* filename, int want_hole);
void to_file(SV* obj, char* filename, int want_hole);
SV* clip_to(SV* obj, SV* clp, char* action);
void add_polygon(SV* obj, SV* pg, int hole);
void get_polygons(SV* obj);
void pts_to_vertex_list(SV* pg, gpc_vertex_list* vl);
AV* vertex_list_to_pts(gpc_vertex_list* vl);
void gpc_free_polygon2(gpc_polygon *p);

SV* new (char* class) {
	gpc_polygon* p = malloc(sizeof(gpc_polygon));
	SV* obj_ref = newSViv(0);
	SV* obj = newSVrv(obj_ref, class);  // bless it
	p->num_contours = 0;
	sv_setiv(obj, (IV)p);
	SvREADONLY_on(obj);
	return(obj_ref);
}

void DESTROY(SV* obj) {
	gpc_polygon* p = (gpc_polygon*) SvIV(SvRV(obj));
	dbg_p(("running destroy for %d contours\n", p->num_contours));
	if(p->num_contours > 0) {
		dbg_p(("free contents now\n"));
		gpc_free_polygon2(p);
	}
	dbg_p(("that's done now\n"));
	free(p);
	dbg_p(("p free... DESTROY complete\n"));
}

int from_file(SV* obj, char* filename, int want_hole) {
	gpc_polygon* p = (gpc_polygon*) SvIV(SvRV(obj));
	FILE* sfp;
	dbg_p(("from %s file\n", filename));
	sfp = fopen(filename, "r");
	if(! sfp) {
		dbg_p(("file open failed\n"));
		return(0);
	}
	gpc_read_polygon(sfp, want_hole, p);
	dbg_p(("read %d contours\n", p->num_contours));
	return(p->num_contours);
}

void to_file(SV* obj, char* filename, int want_hole) {
	gpc_polygon* p = (gpc_polygon*) SvIV(SvRV(obj));
	FILE* ofp;
	ofp = fopen(filename, "w");
	gpc_write_polygon(ofp, want_hole, p);
}

SV* clip_to(SV* obj, SV* clp, char* action) {
	gpc_polygon* p = (gpc_polygon*) SvIV(SvRV(obj));
	HV* stash = SvSTASH(SvRV(obj));
	// we need the classname to make a new object and to check on clp
	char * classname = HvNAME(stash);
	SV* result = new(classname);
	gpc_polygon* r = (gpc_polygon*) SvIV(SvRV(result));
	gpc_op op;
	gpc_polygon* c;
	if(! sv_isobject(clp)) {
		croak("not an object");
	}
	if(! sv_isa(clp, classname)) {
		croak("not a member of %s", classname);
	}
	c = (gpc_polygon*) SvIV(SvRV(clp));
	if(! strcmp(action, "INTERSECT")) {
		dbg_p(("performing INTERSECT\n"));
		op = GPC_INT;
	}
	if(! strcmp(action, "DIFFERENCE")) {
		dbg_p(("performing DIFFERENCE\n"));
		op = GPC_DIFF;
	}
	if(! strcmp(action, "UNION")) {
		dbg_p(("performing UNION\n"));
		op = GPC_UNION;
	}
	/* FIXME: need some way to integrate this:
		printf("%s is not an operation".
			" (INTERSECT|DIFFERENCE|UNION)\n", action
			);
	*/
	gpc_polygon_clip(op, p, c, r);
	return(result);
}

void add_polygon(SV* obj, SV* pg, int hole) {
	gpc_polygon* p = (gpc_polygon*) SvIV(SvRV(obj));
	dbg_p(("got my vl\n"));
	if(p->num_contours > 0) {
		gpc_vertex_list* c;
		MALLOC(c, sizeof(gpc_vertex_list), 
			"addable contour creation\n");
		pts_to_vertex_list(pg, c);
		dbg_p(("adding to existing\n"));
		gpc_add_contour(p, c, hole);
	}
	else {
		dbg_p(("adding as new\n"));
		MALLOC(p->hole, sizeof(int), "hole flag array\n");
		dbg_p(("setting hole\n"));
		p->hole[0] = hole;
		dbg_p(("making contour\n"));
		MALLOC(p->contour, sizeof(gpc_vertex_list), 
			"contour creation\n");
		pts_to_vertex_list(pg, &(p->contour[0]) );
		dbg_p(("got %d vertices\n", p->contour[0].num_vertices));
		p->num_contours = 1;
	}
	dbg_p(("added\n"));
}

void get_polygons(SV* obj) {
	Inline_Stack_Vars;
	int c;
	gpc_polygon* p = (gpc_polygon*) SvIV(SvRV(obj));
	Inline_Stack_Reset;
	if(p->num_contours < 1) {
		dbg_p(("no contours\n"));
		Inline_Stack_Done;
		return;
	}
	for(c = 0; c < p->num_contours; c++) {
		Inline_Stack_Push(newRV_noinc((SV*) vertex_list_to_pts(&(p->contour[c]))));
	}
	Inline_Stack_Done;


}

void pts_to_vertex_list(SV* pg, gpc_vertex_list* vl) {
	SV** psv;
	SV* val;
	AV* pt;
	AV* pts;
	I32 p;
	I32 num;
	if(!SvROK(pg))
		croak("polygon must be reference\n");
	pts = (AV*)SvRV(pg);
	num = av_len(pts) + 1;
	dbg_p(("going to allocate for %d pts\n", num));
	MALLOC(vl->vertex, num * sizeof(gpc_vertex), "vertex creation");
	vl->num_vertices = num;
	dbg_p(("MALLOC okay (%d vertices)\n", vl->num_vertices));
	for(p = 0; p < num; p++) {
		psv = av_fetch(pts, p, 0);
		val = *psv;
		if(! SvROK(val))
			croak("point %d not a ref", p);
		pt = (AV*)SvRV(val);
		psv = av_fetch(pt, 0, 0);
		val = *psv;
		vl->vertex[p].x = SvNV(val);
		psv = av_fetch(pt, 1, 0);
		val = *psv;
		vl->vertex[p].y = SvNV(val);
		dbg_p(("added %0.2f, %0.2f\n", 
			vl->vertex[p].x, vl->vertex[p].y
			));
	}
	dbg_p(("returning\n"));
}

AV* vertex_list_to_pts(gpc_vertex_list* vl) {
	AV* pts;
	AV* pt;
	int p;
	dbg_p(("%d vertices\n", vl->num_vertices));
	pts = newAV();
	for(p = 0; p < vl->num_vertices; p++) {
		pt = newAV();
		av_push(pts, newRV_noinc((SV*) pt));
		av_push(pt, newSVnv(vl->vertex[p].x));
		av_push(pt, newSVnv(vl->vertex[p].y));
		dbg_p(("point %d: %0.2f, %0.2f\n", 
			p, vl->vertex[p].x, vl->vertex[p].y
			));
	}
	return(pts);
}


void gpc_free_polygon2(gpc_polygon *p) {
	int c;
	for (c= 0; c < p->num_contours; c++) {
  	dbg_p(("free contour %d\n", c));
    FREE(p->contour[c].vertex);
	}
	dbg_p(("free hole\n"));
	FREE(p->hole);
	dbg_p(("free contour\n"));
	FREE(p->contour);
	p->num_contours= 0;
}


