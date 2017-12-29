#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <math.h>

#include "projects.h"
#include <proj_api.h>

MODULE = Geo::Proj4	PACKAGE = Geo::Proj4

#define PROJ4_NO_ERROR "no error"

int
libproj_version_proj4()
    CODE:
	RETVAL = PJ_VERSION;
    OUTPUT:
	RETVAL

void
new_proj4(defn)
	char * defn
    INIT:
	projPJ rawstruct;
    PPCODE:
	rawstruct = pj_init_plus(defn);

	if(rawstruct==NULL)
	{   EXTEND(SP, 3);
		PUSHs(&PL_sv_undef);
		PUSHs(sv_2mortal(newSViv(pj_errno)));
		PUSHs(sv_2mortal(newSVpv(pj_strerrno(pj_errno),0)));
	}
	else
	{   SV *object = newSV(0);
	    sv_setref_pv(object, "Geo::Proj4", (void *)rawstruct);

		XPUSHs(sv_2mortal(object));
	}

SV *
forward_degrees_proj4(proj, lat, lon)
	projPJ proj
	double lat
	double lon
    PROTOTYPE: $$$
    PREINIT:
	projUV in, out;
    PPCODE:
	in.u = lon * DEG_TO_RAD;
	in.v = lat * DEG_TO_RAD;
	out = pj_fwd(in, proj);
	if(out.u == HUGE_VAL && out.v == HUGE_VAL) 
	    XSRETURN_UNDEF;

	EXTEND(SP, 2);
	if(pj_is_latlong(proj))
	{   PUSHs(sv_2mortal(newSVnv(out.u * RAD_TO_DEG)));
	    PUSHs(sv_2mortal(newSVnv(out.v * RAD_TO_DEG)));
	}
	else
	{   PUSHs(sv_2mortal(newSVnv(out.u)));
	    PUSHs(sv_2mortal(newSVnv(out.v)));
	}

SV *
forward_proj4(proj, lat, lon)
	projPJ proj
	double lat
	double lon
    PROTOTYPE: $$$
    PREINIT:
	projUV in, out;
        projPJ toProj;
    PPCODE:
	in.u = lon;
	in.v = lat;
	out  = pj_fwd(in, proj);
	if (out.u == HUGE_VAL && out.v == HUGE_VAL) 
	    XSRETURN_UNDEF;

	EXTEND(SP, 2);
	PUSHs(sv_2mortal(newSVnv(out.u)));
	PUSHs(sv_2mortal(newSVnv(out.v)));

SV *
inverse_degrees_proj4(proj, x, y)
	projPJ proj
	double x
	double y
    PROTOTYPE: $$$
    PREINIT:
	projUV in, out;
    PPCODE:
	if(pj_is_latlong(proj))
	{   in.u = x * DEG_TO_RAD;
	    in.v = y * DEG_TO_RAD;
	}
	else
	{   in.u = x;
	    in.v = y;
	}

	out = pj_inv(in, proj);
	if (out.u == HUGE_VAL && out.v == HUGE_VAL) 
	    XSRETURN_UNDEF;

	EXTEND(SP, 2);
	PUSHs(sv_2mortal(newSVnv(out.v * RAD_TO_DEG)));
	PUSHs(sv_2mortal(newSVnv(out.u * RAD_TO_DEG)));

SV *
inverse_proj4(proj, x, y)
	projPJ proj
	double x
	double y
    PROTOTYPE: $$$
    PREINIT:
	projUV in, out;
    PPCODE:
	in.u = x;
	in.v = y;

	out = pj_inv(in, proj);
	if (out.u == HUGE_VAL && out.v == HUGE_VAL) 
	    XSRETURN_UNDEF;

	EXTEND(SP, 2);
	PUSHs(sv_2mortal(newSVnv(out.v)));
	PUSHs(sv_2mortal(newSVnv(out.u)));

void
transform_proj4(proj_from, proj_to, points, degrees)
	projPJ   proj_from
	projPJ   proj_to
	SV     * points
	bool     degrees
    PROTOTYPE: $$$$

    INIT:
	double *x;
	double *y;
	double *z;
	AV  *  res;
	AV  *  retlist;
	I32    nrpoints = 0;
	I32    p;

	if(   (!SvROK(points))
           || (SvTYPE(SvRV(points)) != SVt_PVAV)
           || ((nrpoints = av_len((AV *)SvRV(points))) < 0)
	  )
	{   XSRETURN_UNDEF;
	} 
	nrpoints += 1;  /* XS returns last index, not size */

    PPCODE:
	New(0, x, nrpoints, double);
	New(0, y, nrpoints, double);
	New(0, z, nrpoints, double);

	/* fprintf(stderr, "%d points\n", nrpoints); */
	for(p = 0; p < nrpoints; p++)
	{   AV * point = (AV *)SvRV(*av_fetch((AV *)SvRV(points), p, 0));

	    x[p] = SvNV(*av_fetch(point, 0, 0));
	    y[p] = SvNV(*av_fetch(point, 1, 0));
	    z[p] = av_len(point) < 2 ? 0.0 : SvNV(*av_fetch(point, 2, 0));
	    /* fprintf(stderr, "point=%f %f %f\n", x[p], y[p], z[p]); */

	    if(degrees && pj_is_latlong(proj_from))
	    {   x[p] *= DEG_TO_RAD;
	        y[p] *= DEG_TO_RAD;
	    }
	}

	if(pj_transform(proj_from, proj_to, nrpoints, 0, x, y, z)==0)
	{
		XPUSHs(sv_2mortal(newSViv(0)));
		XPUSHs(sv_2mortal(newSVpv(PROJ4_NO_ERROR, 0)));

	    retlist = (AV *)sv_2mortal((SV *)newAV());

	    for(p=0; p < nrpoints; p++)
	    {   AV * res = (AV *)sv_2mortal((SV *)newAV());

	        if(degrees && pj_is_latlong(proj_to))
	        {   x[p] *= RAD_TO_DEG;
	            y[p] *= RAD_TO_DEG;
	        }
	        av_push(res, newSVnv(x[p]));
	        av_push(res, newSVnv(y[p]));

	        if(z[p]!=0.0) av_push(res, newSVnv(z[p]));
	        av_push(retlist, newRV((SV *)res));
	    }

	    XPUSHs(newRV_noinc((SV *)retlist));
	}
	else
	{   XPUSHs(sv_2mortal(newSViv(pj_errno)));
	    XPUSHs(sv_2mortal(newSVpv(pj_strerrno(pj_errno),0)));
	}

	Safefree(x);
	Safefree(y);
	Safefree(z);


int
has_inverse_proj4(proj)
	projPJ proj
    PROTOTYPE: $
    CODE:
	RETVAL = (proj->inv ? 1 : 0);
    OUTPUT:
	RETVAL

int
is_latlong_proj4(proj)
	projPJ proj
    PROTOTYPE: $
    CODE:
	RETVAL = (pj_is_latlong(proj) ? 1 : 0);
    OUTPUT:
	RETVAL

int
is_geocentric_proj4(proj)
	projPJ proj
    PROTOTYPE: $
    CODE:
	RETVAL = (pj_is_geocent(proj) ? 1 : 0);
    OUTPUT:
	RETVAL

SV *
def_types_proj4(void)
    PREINIT:
	struct PJ_LIST *type;
    PPCODE:
#if PJ_VERSION >= 449
	for(type = pj_get_list_ref(); type->id; type++)
	{   /* same as "proj -l" does */
            if(   strcmp(type->id,"latlong")==0
               || strcmp(type->id,"longlat")==0
               || strcmp(type->id,"geocent")==0
              ) continue;

            XPUSHs(sv_2mortal(newSVpv(type->id, 0)));
	}
#endif

SV *
type_proj4(id)
	char * id
    PREINIT:
	struct PJ_LIST *type;
    PPCODE:
#if PJ_VERSION >= 449
	for(type = pj_get_list_ref(); type->id; type++)
	{   if(strcmp(id, type->id)!=0)
			continue;

		XPUSHs(sv_2mortal(newSVpv(*type->descr, 0)));
		break;
	}
#endif
 
SV *
def_ellps_proj4(void)
    PREINIT:
	struct PJ_ELLPS *ellps;
    PPCODE:
#if PJ_VERSION >= 449
	for(ellps = pj_get_ellps_ref(); ellps->id; ellps++)
	{   XPUSHs(sv_2mortal(newSVpv(ellps->id, 0)));
    }
#endif

SV *
ellps_proj4(id)
	char * id
    PREINIT:
	struct PJ_ELLPS *ellps;
    PPCODE:
#if PJ_VERSION >= 449
	for(ellps = pj_get_ellps_ref(); ellps->id; ellps++)
	{   if(strcmp(id, ellps->id)!=0)
                continue;

		XPUSHs(sv_2mortal(newSVpv(ellps->major, 0)));
		XPUSHs(sv_2mortal(newSVpv(ellps->ell, 0)));
		XPUSHs(sv_2mortal(newSVpv(ellps->name, 0)));
		break;
	}
#endif
 
SV *
def_units_proj4(void)
    PREINIT:
	struct PJ_UNITS *unit;
    PPCODE:
#if PJ_VERSION >= 449
	for(unit = pj_get_units_ref(); unit->id; unit++)
	{   XPUSHs(sv_2mortal(newSVpv(unit->id, 0)));
    }
#endif

SV *
unit_proj4(id)
	char * id
    PREINIT:
	struct PJ_UNITS *units;
    PPCODE:
#if PJ_VERSION >= 449
	for(units = pj_get_units_ref(); units->id; units++)
	{   if(strcmp(id, units->id)!=0)
			continue;

    	XPUSHs(sv_2mortal(newSVpv(units->to_meter, 0)));
		XPUSHs(sv_2mortal(newSVpv(units->name, 0)));
		break;
	}
#endif
 
SV *
def_datums_proj4(void)
    PREINIT:
	struct PJ_DATUMS *datum;
    PPCODE:
#if PJ_VERSION >= 449
	for(datum = pj_get_datums_ref(); datum->id; datum++)
	{   XPUSHs(sv_2mortal(newSVpv(datum->id, 0)));
	}
#endif

SV *
datum_proj4(id)
	char * id
    PREINIT:
	struct PJ_DATUMS *datum;
    PPCODE:
#if PJ_VERSION >= 449
	for(datum = pj_get_datums_ref(); datum->id; datum++)
	{   if(strcmp(id, datum->id)!=0)
			continue;

		XPUSHs(sv_2mortal(newSVpv(datum->ellipse_id, 0)));
		XPUSHs(sv_2mortal(newSVpv(datum->defn, 0)));

	    if(datum->comments!=NULL && strlen(datum->comments))
        {   XPUSHs(sv_2mortal(newSVpv(datum->comments, 0)));
	    }

		break;
	}
#endif
 
void
dump_proj4(proj)
	projPJ proj
    PROTOTYPE: $
    CODE:
        pj_pr_list(proj);

SV *
normalized_proj4(proj)
	projPJ proj
    PROTOTYPE: $
    CODE:
	RETVAL = newSVpv(pj_get_def(proj, 0), 0);
    OUTPUT:
	RETVAL
	

void
DESTROY(proj)
	projPJ proj
    PROTOTYPE: $
    CODE:
	/* cloned objects also call DESTROY, which is a very   */
	/* bad idea.  Therefore, the memory will not  be freed */
	/* until a major rewrite avoids this problem.          */
	/* pj_free(proj); */
