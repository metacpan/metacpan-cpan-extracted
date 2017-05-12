#ifdef __cplusplus
extern "C" {
#endif
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#ifdef __cplusplus
}
#endif

#include <gtk2-ex-geo.h>

#include <ral.h>

#include "arrays.h"   /* Pack functions decs */
#include "arrays.c"   /* Pack functions defs */

#define RAL_GRIDPTR "ral_gridPtr"
#define RAL_ERRSTR_OOM "Out of memory"

#include "help.c"

MODULE = Geo::Raster		PACKAGE = Geo::Raster

void
call_g_type_init()
	CODE:
	g_type_init();

int
ral_has_msg()

char *
ral_get_msg()

ral_cell *
ral_cell_create()
	POSTCALL:
		if (ral_has_msg())
			croak("%s",ral_get_msg());

NO_OUTPUT int
ral_cell_destroy(c)
	ral_cell *c
	CODE:
	ral_cell_destroy(&c);
	POSTCALL:
		if (ral_has_msg())
			croak("%s",ral_get_msg());

char *
ral_data_element_type(gd)
	ral_grid *gd
	CODE:
		switch(gd->datatype) {
		case RAL_INTEGER_GRID: RETVAL = RAL_INTEGER_TYPE_NAME;
		break;
		case RAL_REAL_GRID: RETVAL = RAL_REAL_TYPE_NAME;
		break;
		default: RETVAL = "";
		break;
		}
	OUTPUT:
		RETVAL

int
ral_sizeof_data_element(gd)
	ral_grid *gd
	CODE:
		switch(gd->datatype) {
		case RAL_INTEGER_GRID: RETVAL = sizeof(RAL_INTEGER)*CHAR_BIT;
		break;
		case RAL_REAL_GRID: RETVAL = sizeof(RAL_REAL)*CHAR_BIT;
		break;
		default: RETVAL = 0;
		break;
		}
	OUTPUT:
		RETVAL

long
ral_pointer_to_data(gd)
	ral_grid *gd
	CODE:
		RETVAL = (long)(gd->data);
	OUTPUT:
		RETVAL

void
ral_grid_set_mask(gd, mask)
	ral_grid *gd
	ral_grid *mask
    
void
ral_grid_clear_mask(gd)
	ral_grid *gd
    
void
pdl2grid(SV *datasv, int datatype, ral_grid *gd)
	CODE:
		void *x = SvPV_nolen(SvRV(datasv));
		int i,j;
		if (gd->datatype == RAL_INTEGER_GRID) {
		for (i = 0; i < gd->M; i++) for (j = 0; j < gd->N; j++) {
		    int ii = j+gd->N*i;
		    int pi = j+gd->N*(gd->M-i-1);
		    ((RAL_INTEGER*)(gd->data))[ii] = int_from_pdl(x, datatype, pi);
		}} else {
		for (i = 0; i < gd->M; i++) for (j = 0; j < gd->N; j++) {
		    int ii = j+gd->N*i;
		    int pi = j+gd->N*(gd->M-i-1);
		    ((RAL_REAL*)(gd->data))[ii] = real_from_pdl(x, datatype, pi);
		}}

void
ral_grid_flip_horizontal(ral_grid *gd)

void
ral_grid_flip_vertical(ral_grid *gd)

ral_grid *
ral_grid_get_mask(gd)
	ral_grid *gd

ral_grid *
ral_grid_create(datatype, M, N)
	int datatype
	int M
	int N
	POSTCALL:
		if (ral_has_msg())
			croak("%s",ral_get_msg());

ral_grid *
ral_grid_create_like(gd, datatype)
	ral_grid *gd
	int datatype
	POSTCALL:
		if (ral_has_msg())
			croak("%s",ral_get_msg());
			

ral_grid *
ral_grid_create_copy(gd, datatype)
	ral_grid *gd
	int datatype
	POSTCALL:
		if (ral_has_msg())
			croak("%s",ral_get_msg());

void
ral_grid_destroy(gd)
	ral_grid *gd
	CODE:
	ral_grid_destroy(&gd);

ral_grid *
ral_grid_create_using_GDAL(dataset, band, clip_xmin, clip_ymin, clip_xmax, clip_ymax, cell_size)
	SV *dataset
	int band
	double clip_xmin
	double clip_ymin
	double clip_xmax
	double clip_ymax
	double cell_size
	CODE:
		GDALDatasetH h = (GDALDatasetH)SV2Handle(dataset);
		ral_rectangle clip_region;
		clip_region.min.x = clip_xmin;
		clip_region.min.y = clip_ymin;
		clip_region.max.x = clip_xmax;
		clip_region.max.y = clip_ymax;
		RETVAL = ral_grid_create_using_GDAL(h, band, clip_region, cell_size);
	OUTPUT:
		RETVAL
	POSTCALL:
		if (ral_has_msg())
			croak("%s",ral_get_msg());

NO_OUTPUT int
ral_grid_write(gd, filename)
	ral_grid *gd
	char *filename
	POSTCALL:
		if (ral_has_msg())
			croak("%s",ral_get_msg());

int
ral_grid_get_height(gd)
	ral_grid *gd

int
ral_grid_get_width(gd)
	ral_grid *gd

int
ral_grid_get_datatype(gd)
	ral_grid *gd

int 
ral_grid_has_nodata_value(gd)
	ral_grid *gd

SV * 
ral_grid_get_nodata_value(gd)
	ral_grid *gd
	CODE:
	{
		SV *sv = &PL_sv_undef;
		if (gd->nodata_value) {
			switch (gd->datatype) {
			case RAL_INTEGER_GRID:
				sv = newSViv(RAL_INTEGER_GRID_NODATA_VALUE(gd));
				break;
			case RAL_REAL_GRID:
				sv = newSVnv(RAL_REAL_GRID_NODATA_VALUE(gd));
				break;
			}
		}
		RETVAL = sv;
	}
  OUTPUT:
    RETVAL
	POSTCALL:
		if (ral_has_msg())
			croak("%s",ral_get_msg());

NO_OUTPUT int
ral_grid_set_nodata_value(gd, x)
	ral_grid *gd
	SV *x
	CODE:
		switch (gd->datatype) {
		case RAL_INTEGER_GRID:
			{
				IV i = SvIV(x);
				if (i >= RAL_INTEGER_MIN AND i <= RAL_INTEGER_MAX)
					ral_grid_set_integer_nodata_value(gd, i);
				else
					croak("%s","ral_grid_set_nodata_value(%i): int out of bounds", i);
			}
			break;
		case RAL_REAL_GRID:
			ral_grid_set_real_nodata_value(gd, SvNV(x));
			break;
		}
	POSTCALL:
		if (ral_has_msg())
			croak("%s",ral_get_msg());

void 
ral_grid_remove_nodata_value(gd)
	ral_grid *gd

double
ral_grid_get_cell_size(gd)
	ral_grid *gd

AV *
ral_grid_get_world(gd)
	ral_grid *gd
	CODE:
	{
		ral_rectangle xy = ral_grid_get_world(gd);
		AV *av = newAV();
		sv_2mortal((SV*)av);
		if (av) {
			SV *sv = newSVnv(xy.min.x);
			av_push(av, sv);
			sv = newSVnv(xy.min.y);
			av_push(av, sv);
			sv = newSVnv(xy.max.x);
			av_push(av, sv);
			sv = newSVnv(xy.max.y);
			av_push(av, sv);
		}
		RETVAL = av;
	}
  OUTPUT:
    RETVAL

int
ral_grid_overlayable(ral_grid *g1, ral_grid *g2)

void
ral_grid_set_bounds_csnn(gd, cell_size, minX, minY)
	ral_grid *gd
	double cell_size
	double minX
	double minY

void
ral_grid_set_bounds_csnx(gd, cell_size, minX, maxY)
	ral_grid *gd
	double cell_size
	double minX
	double maxY

void
ral_grid_set_bounds_csxn(gd, cell_size, maxX, minY)
	ral_grid *gd
	double cell_size
	double maxX
	double minY

void
ral_grid_set_bounds_csxx(gd, cell_size, maxX, maxY)
	ral_grid *gd
	double cell_size
	double maxX
	double maxY

void
ral_grid_set_bounds_nxn(gd, minX, maxX, minY)
	ral_grid *gd
	double minX
	double maxX
	double minY

void
ral_grid_set_bounds_nxx(gd, minX, maxX, maxY)
	ral_grid *gd
	double minX
	double maxX
	double maxY

void
ral_grid_set_bounds_nnx(gd, minX, minY, maxY)
	ral_grid *gd
	double minX
	double minY
	double maxY

void
ral_grid_set_bounds_xnx(gd, maxX, minY, maxY)
	ral_grid *gd
	double maxX
	double minY
	double maxY

void
ral_grid_copy_bounds(from, to)
	ral_grid *from
	ral_grid *to

AV *
ral_grid_point2cell(gd, px, py)
	ral_grid *gd
	double px
	double py
	CODE:
	{
		ral_point p;
		p.x = px;
		p.y = py;
		ral_cell c = ral_grid_point2cell(gd, p);
		AV *av = newAV();
		sv_2mortal((SV*)av);
		if (av) {
			SV *sv = newSViv(c.i);
			av_push(av, sv);
			sv = newSViv(c.j);
			av_push(av, sv);
		}
		RETVAL = av;
	}
  OUTPUT:
    RETVAL

AV *
ral_grid_cell2point(gd, ci, cj)
	ral_grid *gd
	int ci
	int cj
	CODE:
	{
		ral_cell c = {ci,cj};
		ral_point p = ral_grid_cell2point(gd, c);
		AV *av = newAV();
		sv_2mortal((SV*)av);
		if (av) {
			SV *sv = newSVnv(p.x);
			av_push(av, sv);
			sv = newSVnv(p.y);
			av_push(av, sv);
		}
		RETVAL = av;
	}
  OUTPUT:
    RETVAL


SV *
ral_grid_get(gd, ci, cj)
	ral_grid *gd
	int ci
	int cj
	CODE:
	{
		ral_cell c = {ci,cj};
		SV *sv;		
		if (gd->data AND RAL_GRID_CELL_IN(gd, c)) {
			if (gd->datatype == RAL_REAL_GRID) {
				RAL_REAL x = RAL_REAL_GRID_CELL(gd, c);
				if ((gd->nodata_value) AND (x == RAL_REAL_GRID_NODATA_VALUE(gd)))
					/*sv = newSVpv("nodata",6);*/
					sv = &PL_sv_undef;
				else
					sv = newSVnv(x);
			} else {
				RAL_INTEGER x = RAL_INTEGER_GRID_CELL(gd, c);
				if ((gd->nodata_value) AND (x == RAL_INTEGER_GRID_NODATA_VALUE(gd)))
					/*sv = newSVpv("nodata",6);*/
					sv = &PL_sv_undef;
				else
					sv = newSViv(x);
			}
		} else {
			sv = &PL_sv_undef;
		}
		RETVAL = sv;
	}
  OUTPUT:
    RETVAL

void
ral_grid_set(gd, ci, cj, x)
	ral_grid *gd
	int ci
	int cj
	SV *x
	CODE:
	{
		ral_cell c = {ci,cj};
		switch (gd->datatype) {
		case RAL_INTEGER_GRID:
			{
				IV i = SvIV(x);
				if (i >= RAL_INTEGER_MIN AND i <= RAL_INTEGER_MAX)
					ral_grid_set_integer(gd, c, i);
				else
					croak("%s","ral_grid_set_integer(cell, %i): int out of bounds", i);
			}
			break;
		case RAL_REAL_GRID:
			ral_grid_set_real(gd, c, SvNV(x));
			break;
		}
		
	}
	POSTCALL:
		if (ral_has_msg())
			croak("%s",ral_get_msg());

void
ral_grid_set_nodata(gd, ci, cj)
	ral_grid *gd
	int ci
	int cj
	CODE:
	{
		ral_cell c = {ci,cj};
		ral_grid_set_nodata(gd, c);
	}
	POSTCALL:
		if (ral_has_msg())
			croak("%s",ral_get_msg());

AV *
ral_grid_get_value_range(gd)
	ral_grid *gd
	CODE:
	{
		AV *av = newAV();
		sv_2mortal((SV*)av);
		switch (gd->datatype) {
		case RAL_INTEGER_GRID: {
			ral_integer_range range;
			if (ral_integer_grid_get_value_range(gd, &range)) {
				av_push(av, newSViv(range.min));
				av_push(av, newSViv(range.max));
			}
			break;
		}
		case RAL_REAL_GRID: {
			ral_real_range range;
			if (ral_real_grid_get_value_range(gd, &range)) {
				av_push(av, newSVnv(range.min));
				av_push(av, newSVnv(range.max));
			}
			break;
		}
		}
		RETVAL = av;
	}
  OUTPUT:
    RETVAL

NO_OUTPUT int
ral_grid_set_all(gd, x)
	ral_grid *gd
	SV *x
	CODE:
		switch (gd->datatype) {
		case RAL_INTEGER_GRID:
			{
				IV i = SvIV(x);
				if (i >= RAL_INTEGER_MIN AND i <= RAL_INTEGER_MAX)
					ral_grid_set_all_integer(gd, i);
				else
					croak("%s","ral_grid_set_all_integer(%i): int out of bounds", i);
			}
			break;
		case RAL_REAL_GRID:
			ral_grid_set_all_real(gd, SvNV(x));
			break;
		}
	POSTCALL:
		if (ral_has_msg())
			croak("%s",ral_get_msg());

NO_OUTPUT int
ral_grid_set_all_nodata(gd)
	ral_grid *gd
	POSTCALL:
		if (ral_has_msg())
			croak("%s",ral_get_msg());

void 
ral_grid_set_focal(gd, ci, cj, focal)
	ral_grid *gd
	int ci
	int cj
	AV *focal
	CODE:
	{
		ral_cell c = {ci,cj};
		void *x = NULL;
		int *mask = NULL;
		int d, M;
		RAL_CHECK(mask = focal2mask(focal, &d, 1));
		M = 2*d+1;
		if (gd->datatype == RAL_INTEGER_GRID) {
			RAL_CHECKM(x = (RAL_INTEGER *)calloc(M*M, sizeof(RAL_INTEGER)), RAL_ERRSTR_OOM);
			int i, j, ix = 0;
			for (i = 0; i < M; i++) {
				if (mask[ix]) {
					SV **s = av_fetch(focal, i, 0);
					for (j = 0; j < M; j++) {
						if (mask[ix]) {
							SV **t = av_fetch((AV*)SvRV(*s), j, 0);
							if (t AND *t AND SvOK(*t))
								((RAL_INTEGER *)x)[ix] = SvIV(*t);
							else
								((RAL_INTEGER *)x)[ix] = RAL_INTEGER_GRID_NODATA_VALUE(gd);
						}
						ix++;
					}
				} else 
					ix += M;
			}
			ral_grid_set_focal(gd, c, x, mask, d);			
		} else {
			RAL_CHECKM(x = (RAL_REAL *)calloc(M*M, sizeof(RAL_REAL)), RAL_ERRSTR_OOM);
			int i, j, ix = 0;
			for (i = 0; i < M; i++) {
				if (mask[ix]) {
					SV **s = av_fetch(focal, i, 0);
					for (j = 0; j < M; j++) {
						if (mask[ix]) {
							SV **t = av_fetch((AV*)SvRV(*s), j, 0);
							if (t AND *t AND SvOK(*t))
								((RAL_INTEGER *)x)[ix] = SvNV(*t);
							else
								((RAL_INTEGER *)x)[ix] = RAL_REAL_GRID_NODATA_VALUE(gd);
						}
						ix++;
					}
				} else 
					ix += M;
			}
			ral_grid_set_focal(gd, c, x, mask, d);
		}
		fail:
		if (x) free(x);
		if (mask) free(mask);
	}
	POSTCALL:
		if (ral_has_msg())
			croak("%s",ral_get_msg());

AV *
ral_grid_get_focal(gd, ci, cj, distance)
	ral_grid *gd
	int ci
	int cj
	SV *distance
	CODE:
	{
		AV *av = newAV();
		ral_cell c = {ci, cj};
		int d = SvUV(distance);
		int M = 2*d+1;
		RAL_CHECK(av);
		sv_2mortal((SV*)av);
		if (gd->datatype == RAL_INTEGER_GRID) {
			RAL_INTEGER *x = (RAL_INTEGER *)ral_grid_get_focal(gd, c, d);
			RAL_CHECK(x);
			int ix = 0, i, j;
			for (i = 0; i < M; i++) {
				AV *row = newAV();
				RAL_CHECK(row);
				for (j = 0; j < M; j++)
					av_push(row, newSViv(x[ix++]));
				av_push(av, (SV*)newRV((SV*)row));
			}
			free(x);
		} else {
			RAL_REAL *x = (RAL_REAL *)ral_grid_get_focal(gd, c, d);
			RAL_CHECK(x);
			int ix = 0, i, j;
			for (i = 0; i < M; i++) {
				AV *row = newAV();
				RAL_CHECK(row);
				for (j = 0; j < M; j++)
					av_push(row, newSVnv(x[ix++]));
				av_push(av, (SV*)newRV((SV*)row));
			}
			free(x);
		}
		fail:
		RETVAL = av;
	}
	OUTPUT:
		RETVAL
	POSTCALL:
		if (ral_has_msg())
			croak("%s",ral_get_msg());

SV *
ral_grid_focal_sum(gd, ci, cj, focal)
	ral_grid *gd
	int ci
	int cj
	AV *focal
	CODE:
	{
		ral_cell c = {ci, cj};
		int *mask = NULL;
		int d;
		SV *sv;
		RAL_CHECK(mask = focal2mask(focal, &d, 0));
		if (gd->datatype == RAL_INTEGER_GRID) {
			int sum;
			ral_integer_grid_focal_sum(gd, c, mask, d, &sum);
			sv = newSViv(sum);
		} else {
			double sum;
			ral_real_grid_focal_sum(gd, c, mask, d, &sum);
			sv = newSVnv(sum);
		}
		fail:
		if (mask) free(mask);
		RETVAL = sv;
	}
	OUTPUT:
		RETVAL
	POSTCALL:
		if (ral_has_msg())
			croak("%s",ral_get_msg());

SV *
ral_grid_focal_mean(gd, ci, cj, focal)
	ral_grid *gd
	int ci
	int cj
	AV *focal
	CODE:
	{
		ral_cell c = {ci, cj};
		int *mask = NULL;
		int d;
		SV *sv;
		RAL_CHECK(mask = focal2mask(focal, &d, 0));
		double mean;
		ral_grid_focal_mean(gd, c, mask, d, &mean);
		sv = newSVnv(mean);
		fail:
		if (mask) free(mask);
		RETVAL = sv;
	}
	OUTPUT:
		RETVAL
	POSTCALL:
		if (ral_has_msg())
			croak("%s",ral_get_msg());

SV *
ral_grid_focal_variance(gd, ci, cj, focal)
	ral_grid *gd
	int ci
	int cj
	AV *focal
	CODE:
	{
		ral_cell c = {ci, cj};
		int *mask = NULL;
		int d;
		SV *sv;
		RAL_CHECK(mask = focal2mask(focal, &d, 0));
		double variance;
		ral_grid_focal_variance(gd, c, mask, d, &variance);
		sv = newSVnv(variance);
		fail:
		if (mask) free(mask);
		RETVAL = sv;
	}
	OUTPUT:
		RETVAL
	POSTCALL:
		if (ral_has_msg())
			croak("%s",ral_get_msg());

SV *
ral_grid_focal_count(gd, ci, cj, focal)
	ral_grid *gd
	int ci
	int cj
	AV *focal
	CODE:
	{
		ral_cell c = {ci, cj};
		int *mask = NULL;
		int d;
		SV *sv;
		RAL_CHECK(mask = focal2mask(focal, &d, 0));
		int count = ral_grid_focal_count(gd, c, mask, d);
		sv = newSViv(count);
		fail:
		if (mask) free(mask);
		RETVAL = sv;
	}
	OUTPUT:
		RETVAL
	POSTCALL:
		if (ral_has_msg())
			croak("%s",ral_get_msg());

SV *
ral_grid_focal_count_of(gd, ci, cj, focal, of)
	ral_grid *gd
	int ci
	int cj
	AV *focal
	int of
	CODE:
	{
		ral_cell c = {ci, cj};
		int *mask = NULL;
		int d;
		SV *sv;
		RAL_CHECK(mask = focal2mask(focal, &d, 0));
		int count = ral_grid_focal_count_of(gd, c, mask, d, of);
		sv = newSViv(count);
		fail:
		if (mask) free(mask);
		RETVAL = sv;
	}
	OUTPUT:
		RETVAL
	POSTCALL:
		if (ral_has_msg())
			croak("%s",ral_get_msg());

AV *
ral_grid_focal_range(gd, ci, cj, focal)
	ral_grid *gd
	int ci
	int cj
	AV *focal
	CODE:
	{
		ral_cell c = {ci, cj};
		int *mask = NULL;
		int d;
		AV *av = newAV();
		sv_2mortal((SV*)av);
		RAL_CHECK(mask = focal2mask(focal, &d, 0));
		if (gd->datatype == RAL_INTEGER_GRID) {
			ral_integer_range r;
			int count = ral_integer_grid_focal_range(gd, c, mask, d, &r);
			if (count) {
				av_push(av, newSViv(r.min));
				av_push(av, newSViv(r.max));
			} else {
				av_push(av, &PL_sv_undef);
				av_push(av, &PL_sv_undef);
			}
		} else {
			ral_real_range r;
			int count = ral_real_grid_focal_range(gd, c, mask, d, &r);
			if (count) {
				av_push(av, newSVnv(r.min));
				av_push(av, newSVnv(r.max));
			} else {
				av_push(av, &PL_sv_undef);
				av_push(av, &PL_sv_undef);
			}
		}
		fail:
		if (mask) free(mask);
		RETVAL = av;
	}
	OUTPUT:
		RETVAL
	POSTCALL:
		if (ral_has_msg())
			croak("%s",ral_get_msg());

double
ral_grid_convolve(gd, ci, cj, kernel)
	ral_grid *gd
	int ci
	int cj
	AV *kernel
	CODE:
	{
		ral_cell c = {ci, cj};
		double *_kernel = NULL;
		int d;
		double g;
		RAL_CHECK(_kernel = focal2maskd(kernel, &d, 0));
		ral_grid_convolve(gd, c, _kernel, d, &g);
		fail:
		if (_kernel) free(_kernel);
		RETVAL = g;
	}
	OUTPUT:
		RETVAL

ral_grid *
ral_grid_focal_sum_grid(gd, focal)
	ral_grid *gd
	AV *focal
	CODE:
	{
		int *mask = NULL;
		int d;
		ral_grid *sum = NULL;
		RAL_CHECK(mask = focal2mask(focal, &d, 0));
		sum = ral_grid_focal_sum_grid(gd, mask, d);
		fail:
		if (mask) free(mask);
		RETVAL = sum;
	}
	OUTPUT:
		RETVAL
	POSTCALL:
		if (ral_has_msg())
			croak("%s",ral_get_msg());

ral_grid *
ral_grid_focal_mean_grid(gd, focal)
	ral_grid *gd
	AV *focal
	CODE:
	{
		int *mask = NULL;
		int d;
		ral_grid *mean = NULL;
		RAL_CHECK(mask = focal2mask(focal, &d, 0));
		mean = ral_grid_focal_mean_grid(gd, mask, d);
		fail:
		if (mask) free(mask);
		RETVAL = mean;
	}
	OUTPUT:
		RETVAL
	POSTCALL:
		if (ral_has_msg())
			croak("%s",ral_get_msg());

ral_grid *
ral_grid_focal_variance_grid(gd, focal)
	ral_grid *gd
	AV *focal
	CODE:
	{
		int *mask = NULL;
		int d;
		ral_grid *variance = NULL;
		RAL_CHECK(mask = focal2mask(focal, &d, 0));
		variance = ral_grid_focal_variance_grid(gd, mask, d);
		fail:
		if (mask) free(mask);
		RETVAL = variance;
	}
	OUTPUT:
		RETVAL
	POSTCALL:
		if (ral_has_msg())
			croak("%s",ral_get_msg());

ral_grid *
ral_grid_focal_count_grid(gd, focal)
	ral_grid *gd
	AV *focal
	CODE:
	{
		int *mask = NULL;
		int d;
		ral_grid *count = NULL;
		RAL_CHECK(mask = focal2mask(focal, &d, 0));
		count = ral_grid_focal_count_grid(gd, mask, d);
		fail:
		if (mask) free(mask);
		RETVAL = count;
	}
	OUTPUT:
		RETVAL
	POSTCALL:
		if (ral_has_msg())
			croak("%s",ral_get_msg());

ral_grid *
ral_grid_focal_count_of_grid(gd, focal, value)
	ral_grid *gd
	AV *focal
	int value
	CODE:
	{
		int *mask = NULL;
		int d;
		ral_grid *count = NULL;
		RAL_CHECK(mask = focal2mask(focal, &d, 0));
		count = ral_grid_focal_count_of_grid(gd, mask, d, value);
		fail:
		if (mask) free(mask);
		RETVAL = count;
	}
	OUTPUT:
		RETVAL
	POSTCALL:
		if (ral_has_msg())
			croak("%s",ral_get_msg());

ral_grid *
ral_grid_spread(grid, mask)
	ral_grid *grid
	AV *mask
	CODE:
	{
		double *_mask = NULL;
		int i, d;
		double s = 0;
		RAL_CHECK(_mask = focal2maskd(mask, &d, 0));
		for (i = 0; i < (2*d+1)*(2*d+1); i++)
		    s += _mask[i];
		for (i = 0; i < (2*d+1)*(2*d+1); i++)
		    _mask[i] /= s;
		ral_grid *ret = ral_grid_spread(grid, _mask, d);
		fail:
		if (_mask) free(_mask);
		RETVAL = ret;
	}
	OUTPUT:
		RETVAL
	POSTCALL:
		if (ral_has_msg())
			croak("%s",ral_get_msg());

ral_grid *
ral_grid_spread_random(grid, mask)
	ral_grid *grid
	AV *mask
	CODE:
	{
		double *_mask = NULL;
		int i, d;
		double s = 0;
		RAL_CHECK(_mask = focal2maskd(mask, &d, 0));
		for (i = 0; i < (2*d+1)*(2*d+1); i++)
		    s += _mask[i];
		for (i = 0; i < (2*d+1)*(2*d+1); i++)
		    _mask[i] /= s;
		ral_grid *ret = ral_grid_spread_random(grid, _mask, d);
		fail:
		if (_mask) free(_mask);
		RETVAL = ret;
	}
	OUTPUT:
		RETVAL
	POSTCALL:
		if (ral_has_msg())
			croak("%s",ral_get_msg());

ral_grid *
ral_grid_convolve_grid(gd, kernel)
	ral_grid *gd
	AV *kernel
	CODE:
	{
		double *_kernel = NULL;
		int d;
		RAL_CHECK(_kernel = focal2maskd(kernel, &d, 0));
		ral_grid *g = NULL;
		g = ral_grid_convolve_grid(gd, _kernel, d);
		fail:
		if (_kernel) free(_kernel);
		RETVAL = g;
	}
	OUTPUT:
		RETVAL

NO_OUTPUT int
ral_grid_data(gd)
	ral_grid *gd
	POSTCALL:
		if (ral_has_msg())
			croak("%s",ral_get_msg());

NO_OUTPUT int
ral_grid_not(gd)
	ral_grid *gd
	POSTCALL:
		if (ral_has_msg())
			croak("%s",ral_get_msg());

NO_OUTPUT int
ral_grid_and_grid(gd1, gd2)
	ral_grid *gd1
	ral_grid *gd2
	POSTCALL:
		if (ral_has_msg())
			croak("%s",ral_get_msg());

NO_OUTPUT int
ral_grid_or_grid(gd1, gd2)
	ral_grid *gd1
	ral_grid *gd2
	POSTCALL:
		if (ral_has_msg())
			croak("%s",ral_get_msg());

NO_OUTPUT int
ral_grid_add_real(gd, x)
	ral_grid *gd
	RAL_REAL x
	POSTCALL:
		if (ral_has_msg())
			croak("%s",ral_get_msg());

NO_OUTPUT int
ral_grid_add_integer(gd, x)
	ral_grid *gd
	RAL_INTEGER x
	POSTCALL:
		if (ral_has_msg())
			croak("%s",ral_get_msg());

NO_OUTPUT int
ral_grid_add_grid(gd1, gd2)
	ral_grid *gd1
	ral_grid *gd2
	POSTCALL:
		if (ral_has_msg())
			croak("%s",ral_get_msg());

NO_OUTPUT int
ral_grid_sub_grid(gd1, gd2)
	ral_grid *gd1
	ral_grid *gd2
	POSTCALL:
		if (ral_has_msg())
			croak("%s",ral_get_msg());

NO_OUTPUT int
ral_grid_mult_real(gd, x)
	ral_grid *gd
	RAL_REAL x
	POSTCALL:
		if (ral_has_msg())
			croak("%s",ral_get_msg());

NO_OUTPUT int
ral_grid_mult_integer(gd, x)
	ral_grid *gd
	RAL_INTEGER x
	POSTCALL:
		if (ral_has_msg())
			croak("%s",ral_get_msg());

NO_OUTPUT int
ral_grid_mult_grid(gd1, gd2)
	ral_grid *gd1
	ral_grid *gd2
	POSTCALL:
		if (ral_has_msg())
			croak("%s",ral_get_msg());

NO_OUTPUT int
ral_grid_div_real(gd, x)
	ral_grid *gd
	RAL_REAL x
	POSTCALL:
		if (ral_has_msg())
			croak("%s",ral_get_msg());

NO_OUTPUT int
ral_grid_div_integer(gd, x)
	ral_grid *gd
	RAL_INTEGER x
	POSTCALL:
		if (ral_has_msg())
			croak("%s",ral_get_msg());

NO_OUTPUT int
ral_real_div_grid(x, gd)
	RAL_REAL x
	ral_grid *gd
	POSTCALL:
		if (ral_has_msg())
			croak("%s",ral_get_msg());

NO_OUTPUT int
ral_integer_div_grid(x, gd)
	RAL_INTEGER x
	ral_grid *gd
	POSTCALL:
		if (ral_has_msg())
			croak("%s",ral_get_msg());

NO_OUTPUT int
ral_grid_div_grid(gd1, gd2)
	ral_grid *gd1
	ral_grid *gd2
	POSTCALL:
		if (ral_has_msg())
			croak("%s",ral_get_msg());

NO_OUTPUT int
ral_grid_modulus_integer(gd, x)
	ral_grid *gd
	RAL_REAL x
	POSTCALL:
		if (ral_has_msg())
			croak("%s",ral_get_msg());

NO_OUTPUT int
ral_integer_modulus_grid(x, gd)
	RAL_INTEGER x
	ral_grid *gd
	POSTCALL:
		if (ral_has_msg())
			croak("%s",ral_get_msg());

NO_OUTPUT int
ral_grid_modulus_grid(gd1, gd2)
	ral_grid *gd1
	ral_grid *gd2
	POSTCALL:
		if (ral_has_msg())
			croak("%s",ral_get_msg());

NO_OUTPUT int
ral_grid_power_real(gd, x)
	ral_grid *gd
	RAL_REAL x
	POSTCALL:
		if (ral_has_msg())
			croak("%s",ral_get_msg());

NO_OUTPUT int
ral_real_power_grid(x, gd)
	RAL_REAL x
	ral_grid *gd
	POSTCALL:
		if (ral_has_msg())
			croak("%s",ral_get_msg());

NO_OUTPUT int
ral_grid_power_grid(gd1, gd2)
	ral_grid *gd1
	ral_grid *gd2
	POSTCALL:
		if (ral_has_msg())
			croak("%s",ral_get_msg());

NO_OUTPUT int
ral_grid_abs(gd)
	ral_grid *gd
	POSTCALL:
		if (ral_has_msg())
			croak("%s",ral_get_msg());

NO_OUTPUT int
ral_grid_acos(gd)
	ral_grid *gd
	POSTCALL:
		if (ral_has_msg())
			croak("%s",ral_get_msg());

NO_OUTPUT int
ral_grid_atan(gd)
	ral_grid *gd
	POSTCALL:
		if (ral_has_msg())
			croak("%s",ral_get_msg());

NO_OUTPUT int
ral_grid_atan2(gd1, gd2)
	ral_grid *gd1
	ral_grid *gd2
	POSTCALL:
		if (ral_has_msg())
			croak("%s",ral_get_msg());

NO_OUTPUT int
ral_grid_ceil(gd)
	ral_grid *gd
	POSTCALL:
		if (ral_has_msg())
			croak("%s",ral_get_msg());

NO_OUTPUT int
ral_grid_cos(gd)
	ral_grid *gd
	POSTCALL:
		if (ral_has_msg())
			croak("%s",ral_get_msg());

NO_OUTPUT int
ral_grid_cosh(gd)
	ral_grid *gd
	POSTCALL:
		if (ral_has_msg())
			croak("%s",ral_get_msg());

NO_OUTPUT int
ral_grid_exp(gd)
	ral_grid *gd
	POSTCALL:
		if (ral_has_msg())
			croak("%s",ral_get_msg());

NO_OUTPUT int
ral_grid_floor(gd)
	ral_grid *gd
	POSTCALL:
		if (ral_has_msg())
			croak("%s",ral_get_msg());

NO_OUTPUT int
ral_grid_log(gd)
	ral_grid *gd
	POSTCALL:
		if (ral_has_msg())
			croak("%s",ral_get_msg());

NO_OUTPUT int
ral_grid_log10(gd)
	ral_grid *gd
	POSTCALL:
		if (ral_has_msg())
			croak("%s",ral_get_msg());

NO_OUTPUT int
ral_grid_sin(gd)
	ral_grid *gd
	POSTCALL:
		if (ral_has_msg())
			croak("%s",ral_get_msg());

NO_OUTPUT int
ral_grid_sinh(gd)
	ral_grid *gd
	POSTCALL:
		if (ral_has_msg())
			croak("%s",ral_get_msg());

NO_OUTPUT int
ral_grid_sqrt(gd)
	ral_grid *gd
	POSTCALL:
		if (ral_has_msg())
			croak("%s",ral_get_msg());

NO_OUTPUT int
ral_grid_tan(gd)
	ral_grid *gd
	POSTCALL:
		if (ral_has_msg())
			croak("%s",ral_get_msg());

NO_OUTPUT int
ral_grid_tanh(gd)
	ral_grid *gd
	POSTCALL:
		if (ral_has_msg())
			croak("%s",ral_get_msg());

ral_grid *
ral_grid_round(gd)
	ral_grid *gd
	POSTCALL:
		if (ral_has_msg())
			croak("%s",ral_get_msg());
			

NO_OUTPUT int
ral_grid_lt_real(gd, x)
	ral_grid *gd
	RAL_REAL x
	POSTCALL:
		if (ral_has_msg())
			croak("%s",ral_get_msg());

NO_OUTPUT int
ral_grid_gt_real(gd, x)
	ral_grid *gd
	RAL_REAL x
	POSTCALL:
		if (ral_has_msg())
			croak("%s",ral_get_msg());

NO_OUTPUT int
ral_grid_le_real(gd, x)
	ral_grid *gd
	RAL_REAL x
	POSTCALL:
		if (ral_has_msg())
			croak("%s",ral_get_msg());

NO_OUTPUT int
ral_grid_ge_real(gd, x)
	ral_grid *gd
	RAL_REAL x
	POSTCALL:
		if (ral_has_msg())
			croak("%s",ral_get_msg());

NO_OUTPUT int
ral_grid_eq_real(gd, x)
	ral_grid *gd
	RAL_REAL x
	POSTCALL:
		if (ral_has_msg())
			croak("%s",ral_get_msg());

NO_OUTPUT int
ral_grid_ne_real(gd, x)
	ral_grid *gd
	RAL_REAL x
	POSTCALL:
		if (ral_has_msg())
			croak("%s",ral_get_msg());

NO_OUTPUT int
ral_grid_cmp_real(gd, x)
	ral_grid *gd
	RAL_REAL x
	POSTCALL:
		if (ral_has_msg())
			croak("%s",ral_get_msg());

NO_OUTPUT int
ral_grid_lt_integer(gd, x)
	ral_grid *gd
	RAL_INTEGER x
	POSTCALL:
		if (ral_has_msg())
			croak("%s",ral_get_msg());

NO_OUTPUT int
ral_grid_gt_integer(gd, x)
	ral_grid *gd
	RAL_INTEGER x
	POSTCALL:
		if (ral_has_msg())
			croak("%s",ral_get_msg());

NO_OUTPUT int
ral_grid_le_integer(gd, x)
	ral_grid *gd
	RAL_INTEGER x
	POSTCALL:
		if (ral_has_msg())
			croak("%s",ral_get_msg());

NO_OUTPUT int
ral_grid_ge_integer(gd, x)
	ral_grid *gd
	RAL_INTEGER x
	POSTCALL:
		if (ral_has_msg())
			croak("%s",ral_get_msg());

NO_OUTPUT int
ral_grid_eq_integer(gd, x)
	ral_grid *gd
	RAL_INTEGER x
	POSTCALL:
		if (ral_has_msg())
			croak("%s",ral_get_msg());

NO_OUTPUT int
ral_grid_ne_integer(gd, x)
	ral_grid *gd
	RAL_INTEGER x
	POSTCALL:
		if (ral_has_msg())
			croak("%s",ral_get_msg());

NO_OUTPUT int
ral_grid_cmp_integer(gd, x)
	ral_grid *gd
	RAL_INTEGER x
	POSTCALL:
		if (ral_has_msg())
			croak("%s",ral_get_msg());

NO_OUTPUT int
ral_grid_lt_grid(gd1, gd2)
	ral_grid *gd1
	ral_grid *gd2
	POSTCALL:
		if (ral_has_msg())
			croak("%s",ral_get_msg());

NO_OUTPUT int
ral_grid_gt_grid(gd1, gd2)
	ral_grid *gd1
	ral_grid *gd2
	POSTCALL:
		if (ral_has_msg())
			croak("%s",ral_get_msg());

NO_OUTPUT int
ral_grid_le_grid(gd1, gd2)
	ral_grid *gd1
	ral_grid *gd2
	POSTCALL:
		if (ral_has_msg())
			croak("%s",ral_get_msg());

NO_OUTPUT int
ral_grid_ge_grid(gd1, gd2)
	ral_grid *gd1
	ral_grid *gd2
	POSTCALL:
		if (ral_has_msg())
			croak("%s",ral_get_msg());

NO_OUTPUT int
ral_grid_eq_grid(gd1, gd2)
	ral_grid *gd1
	ral_grid *gd2
	POSTCALL:
		if (ral_has_msg())
			croak("%s",ral_get_msg());

NO_OUTPUT int
ral_grid_ne_grid(gd1, gd2)
	ral_grid *gd1
	ral_grid *gd2
	POSTCALL:
		if (ral_has_msg())
			croak("%s",ral_get_msg());

NO_OUTPUT int
ral_grid_cmp_grid(gd1, gd2)
	ral_grid *gd1
	ral_grid *gd2
	POSTCALL:
		if (ral_has_msg())
			croak("%s",ral_get_msg());

NO_OUTPUT int
ral_grid_min_real(gd, x)
	ral_grid *gd
	RAL_REAL x
	POSTCALL:
		if (ral_has_msg())
			croak("%s",ral_get_msg());

NO_OUTPUT int
ral_grid_min_integer(gd, x)
	ral_grid *gd
	RAL_INTEGER x
	POSTCALL:
		if (ral_has_msg())
			croak("%s",ral_get_msg());

NO_OUTPUT int
ral_grid_max_real(gd, x)
	ral_grid *gd
	RAL_REAL x
	POSTCALL:
		if (ral_has_msg())
			croak("%s",ral_get_msg());

NO_OUTPUT int
ral_grid_max_integer(gd, x)
	ral_grid *gd
	RAL_INTEGER x
	POSTCALL:
		if (ral_has_msg())
			croak("%s",ral_get_msg());

NO_OUTPUT int
ral_grid_min_grid(gd1, gd2)
	ral_grid *gd1
	ral_grid *gd2
	POSTCALL:
		if (ral_has_msg())
			croak("%s",ral_get_msg());

NO_OUTPUT int
ral_grid_max_grid(gd1, gd2)
	ral_grid *gd1
	ral_grid *gd2
	POSTCALL:
		if (ral_has_msg())
			croak("%s",ral_get_msg());

void
ral_grid_random(ral_grid *gd)

ral_grid *
ral_grid_cross(a, b)
	ral_grid *a
	ral_grid *b
	POSTCALL:
		if (ral_has_msg())
			croak("%s",ral_get_msg());
			

NO_OUTPUT int
ral_grid_if_then_real(a, b, c)
	ral_grid *a
	ral_grid *b
	RAL_REAL c
	POSTCALL:
		if (ral_has_msg())
			croak("%s",ral_get_msg());

NO_OUTPUT int
ral_grid_if_then_integer(a, b, c)
	ral_grid *a
	ral_grid *b
	RAL_INTEGER c
	POSTCALL:
		if (ral_has_msg())
			croak("%s",ral_get_msg());

NO_OUTPUT int
ral_grid_if_then_else_real(a, b, c, d)
	ral_grid *a
	ral_grid *b
	RAL_REAL c
	RAL_REAL d
	POSTCALL:
		if (ral_has_msg())
			croak("%s",ral_get_msg());

NO_OUTPUT int
ral_grid_if_then_else_integer(a, b, c, d)
	ral_grid *a
	ral_grid *b
	RAL_INTEGER c
	RAL_INTEGER d
	POSTCALL:
		if (ral_has_msg())
			croak("%s",ral_get_msg());

NO_OUTPUT int
ral_grid_if_then_grid(a, b, c)
	ral_grid *a
	ral_grid *b
	ral_grid *c
	POSTCALL:
		if (ral_has_msg())
			croak("%s",ral_get_msg());

NO_OUTPUT int
ral_grid_zonal_if_then_real(a, b, k, v, n)
	ral_grid *a
	ral_grid *b
	RAL_INTEGER *k
	RAL_REAL *v
	int n
	POSTCALL:
		if (ral_has_msg())
			croak("%s",ral_get_msg());

NO_OUTPUT int
ral_grid_zonal_if_then_integer(a, b, k, v, n)
	ral_grid *a
	ral_grid *b
	RAL_INTEGER *k
	RAL_INTEGER *v
	int n
	POSTCALL:
		if (ral_has_msg())
			croak("%s",ral_get_msg());

NO_OUTPUT int
ral_grid_apply_templ(gd, templ, new_val)
	ral_grid *gd
	int *templ
	int new_val
	POSTCALL:
		if (ral_has_msg())
			croak("%s",ral_get_msg());

ral_grid *
ral_ca_step(gd, k)
	ral_grid *gd
	AV* k
	CODE:
		if (gd->datatype == RAL_INTEGER_GRID) {
			RAL_INTEGER a[9];
			int i;
			for (i = 0; i < 9; i++) {
				if (i <= av_len(k)) {
					SV **s = av_fetch(k, i, 0);
					a[i] = SvIV(*s);
				} else
					a[i] = 0;
			}
			RETVAL = ral_grid_ca_step(gd, a);
		} else {
			RAL_REAL a[9];
			int i;
			for (i = 0; i < 9; i++) {
				if (i <= av_len(k)) {
					SV **s = av_fetch(k, i, 0);
					a[i] = SvNV(*s);
				} else
					a[i] = 0;
			}
			RETVAL = ral_grid_ca_step(gd, a);
		}
	OUTPUT:
		RETVAL
	POSTCALL:
		if (ral_has_msg())
			croak("%s",ral_get_msg());

NO_OUTPUT int
ral_grid_map(gd, s, d, n)
	ral_grid *gd
	int *s
	int *d
	int n
	POSTCALL:
		if (ral_has_msg())
			croak("%s",ral_get_msg());

NO_OUTPUT int 
ral_grid_map_integer_grid(gd, s_min, s_max, d, n, deflt)
	ral_grid *gd
	int *s_min
	int *s_max
	int *d
	int n
	SV *deflt
	CODE:
		if (SvOK(deflt)) {
			int df = SvIV(deflt);
			ral_grid_map_integer_grid(gd, s_min, s_max, d, n, &df);
		} else 
			ral_grid_map_integer_grid(gd, s_min, s_max, d, n, NULL);
	POSTCALL:
		if (ral_has_msg())
			croak("%s",ral_get_msg());

NO_OUTPUT int 
ral_grid_map_real_grid(gd, s_min, s_max, d, n, deflt)
	ral_grid *gd
	double *s_min
	double *s_max
	double *d
	int n
	SV *deflt
	CODE:
		if (SvOK(deflt)) {
			double df = SvNV(deflt);
			ral_grid_map_real_grid(gd, s_min, s_max, d, n, &df);
		} else 
			ral_grid_map_real_grid(gd, s_min, s_max, d, n, NULL);
	POSTCALL:
		if (ral_has_msg())
			croak("%s",ral_get_msg());

double
ral_grid_zonesize(gd, i, j)
	ral_grid *gd
	int i
	int j
	CODE:
	{	
		ral_cell c = {i, j};
		RETVAL = ral_grid_zonesize(gd, c);
  	}
  OUTPUT:
    RETVAL
	POSTCALL:
		if (ral_has_msg())
			croak("%s",ral_get_msg());

ral_grid *
ral_grid_borders(gd)
	ral_grid *gd
	POSTCALL:
		if (ral_has_msg())
			croak("%s",ral_get_msg());
			

ral_grid *
ral_grid_borders_recursive(gd)
	ral_grid *gd
	POSTCALL:
		if (ral_has_msg())
			croak("%s",ral_get_msg());
			

ral_grid *
ral_grid_areas(gd, k)
	ral_grid *gd
	int k
	POSTCALL:
		if (ral_has_msg())
			croak("%s",ral_get_msg());
			

NO_OUTPUT int
ral_grid_connect(gd) 
	ral_grid *gd
	POSTCALL:
		if (ral_has_msg())
			croak("%s",ral_get_msg());

NO_OUTPUT int
ral_grid_number_of_areas(gd,connectivity)
	ral_grid *gd
	int connectivity
	POSTCALL:
		if (ral_has_msg())
			croak("%s",ral_get_msg());

ral_grid *
ral_grid_clip(gd, i1, j1, i2, j2)
	ral_grid *gd
	int i1
	int j1
	int i2
	int j2
	CODE:
	{
		ral_window w;
		w.up_left.i = i1;
		w.up_left.j = j1;
		w.down_right.i = i2;
		w.down_right.j = j2;
		RETVAL = ral_grid_clip(gd, w);
			
	}
  OUTPUT:
    RETVAL
	POSTCALL:
		if (ral_has_msg())
			croak("%s",ral_get_msg());

ral_grid *
ral_grid_join(g1, g2)
	ral_grid *g1
	ral_grid *g2
	POSTCALL:
		if (ral_has_msg())
			croak("%s",ral_get_msg());

int
ral_grid_pick(dest, src)
	ral_grid *dest
	ral_grid *src
			

ral_grid *
ral_grid_transform(gd, tr, M, N, pick, value)
	ral_grid *gd
	double *tr
	int M
	int N
	int pick
	int value
	POSTCALL:
		if (ral_has_msg())
			croak("%s",ral_get_msg());


void
ral_grid_line(gd, i1, j1, i2, j2, pen)
	ral_grid *gd
	int i1
	int j1
	int i2
	int j2
	SV *pen
	CODE:
	{	
		ral_cell c1 = {i1, j1};
		ral_cell c2 = {i2, j2};
		switch (gd->datatype) {
		case RAL_INTEGER_GRID:
			ral_integer_grid_line(gd, c1, c2, SvIV(pen));
			break;
		case RAL_REAL_GRID:
			ral_real_grid_line(gd, c1, c2, SvNV(pen));
			break;
		}
  	}
	POSTCALL:
		if (ral_has_msg())
			croak("%s",ral_get_msg());

void
ral_grid_filled_rect(gd, i1, j1, i2, j2, pen)
	ral_grid *gd
	int i1
	int j1
	int i2
	int j2
	SV *pen
	CODE:
	{	
		ral_cell c1 = {i1, j1};
		ral_cell c2 = {i2, j2};
		switch (gd->datatype) {
		case RAL_INTEGER_GRID:
			ral_integer_grid_filled_rect(gd, c1, c2, SvIV(pen));
			break;
		case RAL_REAL_GRID:
			ral_real_grid_filled_rect(gd, c1, c2, SvNV(pen));
			break;
		}
  	}
	POSTCALL:
		if (ral_has_msg())
			croak("%s",ral_get_msg());

void
ral_grid_filled_circle(gd, i, j, r, pen)
	ral_grid *gd
	int i
	int j
	int r
	SV *pen
	CODE:
	{	
		ral_cell c = {i, j};
		switch (gd->datatype) {
		case RAL_INTEGER_GRID:
			RAL_FILLED_CIRCLE(gd, c, r, SvIV(pen), RAL_INTEGER_GRID_SET_CELL);
			break;
		case RAL_REAL_GRID:
			RAL_FILLED_CIRCLE(gd, c, r, SvNV(pen), RAL_REAL_GRID_SET_CELL);
			break;
		}
		
  	}
	POSTCALL:
		if (ral_has_msg())
			croak("%s",ral_get_msg());

void 
ral_grid_filled_polygon(gd, g, pen_integer, pen_real)
	ral_grid *gd
	ral_geometry *g
	RAL_INTEGER pen_integer
	RAL_REAL pen_real
	POSTCALL:
		if (ral_has_msg())
			croak("%s",ral_get_msg());

AV *
ral_grid_get_line(gd, i1, j1, i2, j2)
	ral_grid *gd
	int i1
	int j1
	int i2
	int j2
	CODE:
	{
		AV *av;
		ral_cell c1 = {i1, j1};
		ral_cell c2 = {i2, j2};
		av = newAV();
		sv_2mortal((SV*)av);
		switch (gd->datatype) {
		case RAL_INTEGER_GRID:
		{
			ral_cell_integer_values *data  = NULL;
			RAL_CHECK(data = ral_integer_grid_get_line(gd, c1, c2));
			int i;
			for (i=0; i<data->size; i++) {
				AV *a = newAV();
				av_push(a, newSViv(data->cells[i].i));
				av_push(a, newSViv(data->cells[i].j));
				av_push(a, newSViv(data->values[i]));
				av_push(av, newRV_noinc((SV*)a));
			}
			ral_cell_integer_values_destroy(&data);
			break;
		}
		case RAL_REAL_GRID:
		{
			ral_cell_real_values *data  = NULL;
			RAL_CHECK(data = ral_real_grid_get_line(gd, c1, c2));
			int i;
			for (i=0; i<data->size; i++) {
				AV *a = newAV();
				av_push(a, newSViv(data->cells[i].i));
				av_push(a, newSViv(data->cells[i].j));
				av_push(a, newSVnv(data->values[i]));
				av_push(av, newRV_noinc((SV*)a));
			}
			ral_cell_real_values_destroy(&data);
			break;
		}
		}
		fail:	
		RETVAL = av;
  	}
  OUTPUT:
    RETVAL
	POSTCALL:
		if (ral_has_msg())
			croak("%s",ral_get_msg());

AV *
ral_grid_get_rect(gd, i1, j1, i2, j2)
	ral_grid *gd
	int i1
	int j1
	int i2
	int j2
	CODE:
	{
		AV *av;
		ral_cell c1 = {i1, j1};
		ral_cell c2 = {i2, j2};
		av = newAV();
		sv_2mortal((SV*)av);
		switch (gd->datatype) {
		case RAL_INTEGER_GRID:
		{
			ral_cell_integer_values *data  = NULL;
			RAL_CHECK(data = ral_integer_grid_get_rect(gd, c1, c2));
			int i;
			for (i=0; i<data->size; i++) {
				AV *a = newAV();
				av_push(a, newSViv(data->cells[i].i));
				av_push(a, newSViv(data->cells[i].j));
				av_push(a, newSViv(data->values[i]));
				av_push(av, newRV_noinc((SV*)a));
			}
			ral_cell_integer_values_destroy(&data);
			break;
		}
		case RAL_REAL_GRID:
		{
			ral_cell_real_values *data  = NULL;
			RAL_CHECK(data = ral_real_grid_get_rect(gd, c1, c2));
			int i;
			for (i=0; i<data->size; i++) {
				AV *a = newAV();
				av_push(a, newSViv(data->cells[i].i));
				av_push(a, newSViv(data->cells[i].j));
				av_push(a, newSVnv(data->values[i]));
				av_push(av, newRV_noinc((SV*)a));
			}
			ral_cell_real_values_destroy(&data);
			break;
		}
		}
		fail:
		RETVAL = av;
  	}
  OUTPUT:
    RETVAL
	POSTCALL:
		if (ral_has_msg())
			croak("%s",ral_get_msg());

AV *
ral_grid_get_circle(gd, i, j, r)
	ral_grid *gd
	int i
	int j
	int r
	CODE:
	{
		AV *av;
		ral_cell c = {i, j};
		av = newAV();
		sv_2mortal((SV*)av);
		switch (gd->datatype) {
		case RAL_INTEGER_GRID:
		{
			ral_cell_integer_values *data  = NULL;
			RAL_CHECK(data = ral_integer_grid_get_circle(gd, c, r));
			int i;
			for (i=0; i<data->size; i++) {
				AV *a = newAV();
				av_push(a, newSViv(data->cells[i].i));
				av_push(a, newSViv(data->cells[i].j));
				av_push(a, newSViv(data->values[i]));
				av_push(av, newRV_noinc((SV*)a));
			}
			ral_cell_integer_values_destroy(&data);
			break;
		}
		case RAL_REAL_GRID:
		{
			ral_cell_real_values *data  = NULL;
			RAL_CHECK(data = ral_real_grid_get_circle(gd, c, r));
			int i;
			for (i=0; i<data->size; i++) {
				AV *a = newAV();
				av_push(a, newSViv(data->cells[i].i));
				av_push(a, newSViv(data->cells[i].j));
				av_push(a, newSVnv(data->values[i]));
				av_push(av, newRV_noinc((SV*)a));
			}
			ral_cell_real_values_destroy(&data);
			break;
		}
		}
		fail:
		RETVAL = av;
  	}
  OUTPUT:
    RETVAL
	POSTCALL:
		if (ral_has_msg())
			croak("%s",ral_get_msg());

void
ral_grid_floodfill(gd, i, j, pen, connectivity)
	ral_grid *gd
	int i
	int j
	SV *pen
	int connectivity
	CODE:
	{	
		ral_cell c = {i, j};
		switch (gd->datatype) {
		case RAL_INTEGER_GRID:
			ral_integer_grid_floodfill(gd, NULL, c, SvIV(pen), connectivity);
			break;
		case RAL_REAL_GRID:
			ral_real_grid_floodfill(gd, NULL, c, SvNV(pen), connectivity);
			break;	
		}
  	}
	POSTCALL:
		if (ral_has_msg())
			croak("%s",ral_get_msg());

NO_OUTPUT int
ral_grid_print(gd)
	ral_grid *gd
	POSTCALL:
		if (ral_has_msg())
			croak("%s",ral_get_msg());

NO_OUTPUT int
ral_grid_save_ascii(gd, outfile)
	ral_grid *gd
	char *outfile
	POSTCALL:
		if (ral_has_msg())
			croak("%s",ral_get_msg());


AV *
ral_grid2list(gd)
	ral_grid *gd
	CODE:
	{
		AV *av;
		ral_cell *c = NULL;
		RAL_INTEGER *ivalue = NULL;
		RAL_REAL *rvalue = NULL;
		av = newAV();
		sv_2mortal((SV*)av);
		switch (gd->datatype) {
		case RAL_INTEGER_GRID: {
			size_t size;
			if (ral_integer_grid2list(gd, &c, &ivalue, &size)) {
				int i;
				for (i=0; i<size; i++) {
					AV *a = newAV();
					av_push(a, newSViv(c[i].i));
					av_push(a, newSViv(c[i].j));
					av_push(a, newSViv(ivalue[i]));
					av_push(av, newRV_noinc((SV*)a));
				}
				
			}
			break;
		}
		case RAL_REAL_GRID: {
			size_t size;
			if (ral_real_grid2list(gd, &c, &rvalue, &size)) {
				int i;
				for (i=0; i<size; i++) {
					AV *a = newAV();
					av_push(a, newSViv(c[i].i));
					av_push(a, newSViv(c[i].j));
					av_push(a, newSVnv(rvalue[i]));
					av_push(av, newRV_noinc((SV*)a));
				}
			}
			break;
		}
		}
		if (c) free(c);
		if (ivalue) free(ivalue);
		if (rvalue) free(rvalue);			
		RETVAL = av;
  	}
  OUTPUT:
    RETVAL
	POSTCALL:
		if (ral_has_msg())
			croak("%s",ral_get_msg());

AV *
ral_grid_histogram(gd, bin, n)
	ral_grid *gd
	double *bin
	int n
	CODE:
	{
		int i, *c = NULL;
		AV *counts = newAV();
		sv_2mortal((SV*)counts);
		RAL_CHECKM(c = (int *)calloc(n+1,sizeof(int)), RAL_ERRSTR_OOM);		
		ral_grid_histogram(gd, bin, c, n);
		for (i=0; i<n+1; i++) {
			av_push(counts, newSViv(c[i]));
		}
	fail:
		if (c) free(c);
		RETVAL = counts;
	}
  OUTPUT:
    RETVAL
	POSTCALL:
		if (ral_has_msg())
			croak("%s",ral_get_msg());

HV *
ral_grid_contents(gd)
	ral_grid *gd
	CODE:
	{
		ral_hash *table = NULL;
		int i;
		HV *h = newHV();
		sv_2mortal((SV*)h);
		RAL_CHECK(table = ral_grid_contents(gd));
		for (i = 0; i < table->size; i++) {
			ral_hash_int_item *a = (ral_hash_int_item *)table->table[i];
			while (a) {
				U32 klen;
				char key[10];
				SV *sv = newSViv(a->value);
				snprintf(key, 10, "%i", a->key);
				klen = strlen(key);
				hv_store(h, key, klen, sv, 0);
				a = a->next;
			}
		}
	fail:
		ral_hash_destroy(&table);
		RETVAL = h;
	}
  OUTPUT:
    RETVAL
	POSTCALL:
		if (ral_has_msg())
			croak("%s",ral_get_msg());

HV *
ral_grid_zonal_count(gd, zones)
	ral_grid *gd
	ral_grid *zones
	CODE:
	{
		ral_hash *table = NULL;
		int i;
		HV* h = newHV();
		sv_2mortal((SV*)h);
		RAL_CHECK(table = ral_grid_zonal_count(gd, zones));
		for (i = 0; i < table->size; i++) {
			ral_hash_int_item *a = (ral_hash_int_item *)table->table[i];
			while (a) {
				U32 klen;
				char key[10];
				SV *sv = newSViv(a->value);
				snprintf(key, 10, "%i", a->key);
				klen = strlen(key);
				hv_store(h, key, klen, sv, 0);
				a = a->next;
			}
		}
	fail:
		ral_hash_destroy(&table);
		RETVAL = h;
	}
  OUTPUT:
    RETVAL
	POSTCALL:
		if (ral_has_msg())
			croak("%s",ral_get_msg());

HV *
ral_grid_zonal_sum(gd, zones)
	ral_grid *gd
	ral_grid *zones
	CODE:
	{
		ral_hash *table = NULL;
		int i;
		HV* h = newHV();
		sv_2mortal((SV*)h);
		RAL_CHECK(table = ral_grid_zonal_sum(gd, zones));
		for (i = 0; i < table->size; i++) {
			ral_hash_double_item *a = (ral_hash_double_item *)table->table[i];
			while (a) {
				U32 klen;
				char key[10];
				SV *sv = newSVnv(a->value);
				snprintf(key, 10, "%i", a->key);
				klen = strlen(key);
				hv_store(h, key, klen, sv, 0);
				a = a->next;
			}
		}
	fail:
		ral_hash_destroy(&table);
		RETVAL = h;
	}
  OUTPUT:
    RETVAL
	POSTCALL:
		if (ral_has_msg())
			croak("%s",ral_get_msg());

HV *
ral_grid_zonal_min(gd, zones)
	ral_grid *gd
	ral_grid *zones
	CODE:
	{
		ral_hash *table = NULL;
		int i;
		HV* h = newHV();		
		sv_2mortal((SV*)h);
		RAL_CHECK(table = ral_grid_zonal_min(gd, zones));
		for (i = 0; i < table->size; i++) {
			ral_hash_double_item *a = (ral_hash_double_item *)table->table[i];
			while (a) {
				U32 klen;
				char key[10];
				SV *sv = newSVnv(a->value);
				snprintf(key, 10, "%i", a->key);
				klen = strlen(key);
				hv_store(h, key, klen, sv, 0);
				a = a->next;
			}
		}
	fail:
		ral_hash_destroy(&table);
		RETVAL = h;
	}
  OUTPUT:
    RETVAL
	POSTCALL:
		if (ral_has_msg())
			croak("%s",ral_get_msg());

HV *
ral_grid_zonal_max(gd, zones)
	ral_grid *gd
	ral_grid *zones
	CODE:
	{
		ral_hash *table = NULL;
		int i;
		HV* h = newHV();
		sv_2mortal((SV*)h);
		RAL_CHECK(table = ral_grid_zonal_max(gd, zones));
		for (i = 0; i < table->size; i++) {
			ral_hash_double_item *a = (ral_hash_double_item *)table->table[i];
			while (a) {
				U32 klen;
				char key[10];
				SV *sv = newSVnv(a->value);
				snprintf(key, 10, "%i", a->key);
				klen = strlen(key);
				hv_store(h, key, klen, sv, 0);
				a = a->next;
			}
		}
	fail:
		ral_hash_destroy(&table);
		RETVAL = h;
	}
  OUTPUT:
    RETVAL
	POSTCALL:
		if (ral_has_msg())
			croak("%s",ral_get_msg());

HV *
ral_grid_zonal_mean(gd, zones)
	ral_grid *gd
	ral_grid *zones
	CODE:
	{
		ral_hash *table = NULL;
		int i;
		HV* h = newHV();	
		sv_2mortal((SV*)h);
		RAL_CHECK(table = ral_grid_zonal_mean(gd, zones));
		for (i = 0; i < table->size; i++) {
			ral_hash_double_item *a = (ral_hash_double_item *)table->table[i];
			while (a) {
				U32 klen;
				char key[10];
				SV *sv = newSVnv(a->value);
				snprintf(key, 10, "%i", a->key);
				klen = strlen(key);
				hv_store(h, key, klen, sv, 0);
				a = a->next;
			}
		}
	fail:
		ral_hash_destroy(&table);
		RETVAL = h;
	}
  OUTPUT:
    RETVAL
	POSTCALL:
		if (ral_has_msg())
			croak("%s",ral_get_msg());

HV *
ral_grid_zonal_variance(gd, zones)
	ral_grid *gd
	ral_grid *zones
	CODE:
	{
		ral_hash *table = NULL;
		int i;
		HV* h = newHV();
		sv_2mortal((SV*)h);
		RAL_CHECK(table = ral_grid_zonal_variance(gd, zones));
		for (i = 0; i < table->size; i++) {
			ral_hash_double_item *a = (ral_hash_double_item *)table->table[i];
			while (a) {
				U32 klen;
				char key[10];
				SV *sv = newSVnv(a->value);
				snprintf(key, 10, "%i", a->key);
				klen = strlen(key);
				hv_store(h, key, klen, sv, 0);
				a = a->next;
			}
		}
	fail:
		ral_hash_destroy(&table);
		RETVAL = h;
	}
  OUTPUT:
    RETVAL
	POSTCALL:
		if (ral_has_msg())
			croak("%s",ral_get_msg());

NO_OUTPUT int
ral_grid_grow_zones(zones, grow, connectivity)
	ral_grid *zones
	ral_grid *grow
	int connectivity
	POSTCALL:
		if (ral_has_msg())
			croak("%s",ral_get_msg());

HV *
ral_grid_neighbors(gd)
	ral_grid *gd
	CODE:
	{
		ral_hash **b = NULL;
		int *c = NULL, i, n;
		HV* h = newHV();		
		sv_2mortal((SV*)h);
		RAL_CHECK(ral_grid_neighbors(gd, &b, &c, &n));
		for (i = 0; i < n; i++) {
			char key[10];
			AV*  av = newAV();
			U32 klen;
			int j;
			snprintf(key, 10, "%i", c[i]);
			klen = strlen(key);
			for (j = 0; j < b[i]->size; j++) {
				ral_hash_int_item *a = (ral_hash_int_item *)b[i]->table[j];
				while (a) {
					SV *sv = newSViv(a->key);
					av_push(av, sv);
					a = a->next;
				}				
			}
			hv_store(h, key, klen, newRV_inc((SV*) av), 0);
		}
	fail:
		ral_hash_array_destroy(&b, n);
		if (c) free(c);
		RETVAL = h;
	}
  OUTPUT:
    RETVAL
	POSTCALL:
		if (ral_has_msg())
			croak("%s",ral_get_msg());

ral_grid *
ral_grid_bufferzone(gd, z, w)
	ral_grid *gd
	int z
	double w
	POSTCALL:
		if (ral_has_msg())
			croak("%s",ral_get_msg());
			

long
ral_grid_count(gd)
	ral_grid *gd
	POSTCALL:
		if (ral_has_msg())
			croak("%s",ral_get_msg());

double 
ral_grid_sum(gd)
	ral_grid *gd
	POSTCALL:
		if (ral_has_msg())
			croak("%s",ral_get_msg());

double 
ral_grid_mean(gd)
	ral_grid *gd
	POSTCALL:
		if (ral_has_msg())
			croak("%s",ral_get_msg());

double 
ral_grid_variance(gd)
	ral_grid *gd
	POSTCALL:
		if (ral_has_msg())
			croak("%s",ral_get_msg());

ral_grid *
ral_grid_distances(gd)
	ral_grid *gd
	POSTCALL:
		if (ral_has_msg())
			croak("%s",ral_get_msg());
			

ral_grid *
ral_grid_directions(gd)
	ral_grid *gd
	POSTCALL:
		if (ral_has_msg())
			croak("%s",ral_get_msg());
			

ral_grid *
ral_grid_nn(gd)
	ral_grid *gd
	POSTCALL:
		if (ral_has_msg())
			croak("%s",ral_get_msg());
			

HV *
ral_grid_zones(gd, z)
	ral_grid *gd
	ral_grid *z
	CODE:
	{
		double **tot = NULL;
		int *c = NULL;
		int *k = NULL;
		int i, n;
		HV* hv = newHV();
		sv_2mortal((SV*)hv);
		if (ral_grid_zones(gd, z, &tot, &c, &k, &n)) {
			for (i = 0; i < n; i++) if (k[i]) {
				int j;
				char key[10];
				U32 klen;
				AV *av;
				SV **sv = (SV **)calloc(k[i], sizeof(SV *));
				for (j = 0; j < k[i]; j++) {
					sv[j] = newSVnv(tot[i][j]);
					if (!sv[j]) goto fail;
				}
				av = av_make(k[i], sv);
				snprintf(key, 10, "%i", c[i]);
				klen = strlen(key);
				hv_store(hv, key, klen, newRV_inc((SV*)av), 0);
			}
		}
	fail:
		if (tot) {
			for (i = 0; i < n; i++)
				if (tot[i]) free(tot[i]);
			free(tot);
		}
		if (c) free(c);
		if (k) free(k);
		RETVAL = hv;
	}
  OUTPUT:
    RETVAL
	POSTCALL:
		if (ral_has_msg())
			croak("%s",ral_get_msg());

ral_grid *
ral_grid_dijkstra(w, ci, cj)
	ral_grid *w
	int ci
	int cj
	CODE:
	{
		ral_cell c = {ci, cj};
		RETVAL = ral_grid_dijkstra(w, c);			
	}
  OUTPUT:
    RETVAL
	POSTCALL:
		if (ral_has_msg())
			croak("%s",ral_get_msg());

ral_grid *
ral_dem_aspect(dem)
	ral_grid *dem
	POSTCALL:
		if (ral_has_msg())
			croak("%s",ral_get_msg());

AV *
ral_dem_fit_surface(dem, z_factor)
	ral_grid *dem
	double z_factor
	CODE:
		ral_grid **params;
		AV *surface = newAV();
		HV *stash = gv_stashpv(RAL_GRIDPTR, 1);
		RETVAL = surface;
		sv_2mortal((SV*)surface);
		if (ral_dem_fit_surface(dem, z_factor, &params)) {
			int i;
			for (i = 0; i < 9; i++) {
				SV *sv = newSViv(params[i]);
				sv = newRV(sv);
				sv = sv_bless(sv, stash);
				av_push(surface, sv);
			}
		}
	OUTPUT:
		RETVAL
	POSTCALL:
		if (ral_has_msg())
			croak("%s",ral_get_msg());
			

ral_grid *
ral_dem_slope(dem, z_factor)
	ral_grid *dem
	double z_factor
	POSTCALL:
		if (ral_has_msg())
			croak("%s",ral_get_msg());
			

ral_grid *
ral_dem_fdg(dem, method)
	ral_grid *dem
	int method
	POSTCALL:
		if (ral_has_msg())
			croak("%s",ral_get_msg());

AV *
ral_fdg_outlet(fdg, streams, i, j)
	ral_grid *fdg
	ral_grid *streams
	int i
	int j
	CODE:
	{
		ral_cell c = {i, j};
		c = ral_fdg_outlet(fdg, streams, c);
		AV *av = newAV();
		sv_2mortal((SV*)av);
		if (av) {
			SV *sv = newSViv(c.i);
			av_push(av, sv);
			sv = newSViv(c.j);
			av_push(av, sv);
		}
		RETVAL = av;
	}
	OUTPUT:
		RETVAL
	POSTCALL:
		if (ral_has_msg())
			croak("%s",ral_get_msg());

ral_grid *
ral_dem_ucg(dem) 
	ral_grid *dem
	POSTCALL:
		if (ral_has_msg())
			croak("%s",ral_get_msg());

int
ral_fdg_drain_flat_areas1(fdg, dem)
	ral_grid *fdg
	ral_grid *dem
	POSTCALL:
		if (ral_has_msg())
			croak("%s",ral_get_msg());

int
ral_fdg_drain_flat_areas2(fdg, dem)
	ral_grid *fdg
	ral_grid *dem
	POSTCALL:
		if (ral_has_msg())
			croak("%s",ral_get_msg());

int
ral_dem_raise_pits(dem, z_limit)
	ral_grid *dem
	double z_limit
	POSTCALL:
		if (ral_has_msg())
			croak("%s",ral_get_msg());

int
ral_dem_lower_peaks(dem, z_limit)
	ral_grid *dem
	double z_limit
	POSTCALL:
		if (ral_has_msg())
			croak("%s",ral_get_msg());

ral_grid *
ral_fdg_depressions(fdg, inc_m)
	ral_grid *fdg
	int inc_m
	POSTCALL:
		if (ral_has_msg())
			croak("%s",ral_get_msg());	

int
ral_dem_fill_depressions(dem, fdg)
	ral_grid *dem
	ral_grid *fdg
	POSTCALL:
		if (ral_has_msg())
			croak("%s",ral_get_msg());

NO_OUTPUT int
ral_dem_breach(dem, fdg, limit)
	ral_grid *dem
	ral_grid *fdg
	int limit
	POSTCALL:
		if (ral_has_msg())
			croak("%s",ral_get_msg());

int
ral_fdg_drain_depressions(fdg, dem)
	ral_grid *fdg
	ral_grid *dem
	POSTCALL:
		if (ral_has_msg())
			croak("%s",ral_get_msg());

ral_grid *
ral_water_route(water, dem, fdg, k, r)
	ral_grid *water
	ral_grid *dem
	ral_grid *fdg
	ral_grid *k
	double r
	POSTCALL:
		if (ral_has_msg())
			croak("%s",ral_get_msg());

ral_grid *
ral_water_route2(water, dem, k, r)
	ral_grid *water
	ral_grid *dem
	ral_grid *k
	double r
	CODE:
		RETVAL = ral_water_route(water, dem, NULL, k, r);
  	OUTPUT:	
		RETVAL
	POSTCALL:
		if (ral_has_msg())
			croak("%s",ral_get_msg());

ral_grid *
ral_fdg_path(fdg, i, j, stop)
	ral_grid *fdg
	int i
	int j
	SV *stop
	CODE:
		ral_cell c = {i, j};
		ral_grid *s = NULL;
		if (SvOK(stop))
			s = (ral_grid*)SV2Object(stop, RAL_GRIDPTR);
		RETVAL = ral_fdg_path(fdg, c, s);
  	OUTPUT:	
		RETVAL
	POSTCALL:
		if (ral_has_msg())
			croak("%s",ral_get_msg());

ral_grid *
ral_fdg_path_length(fdg, stop, op)
	ral_grid *fdg
	SV *stop
	SV *op
	CODE:
		ral_grid *s = NULL;
		ral_grid *o = NULL;
		if (SvOK(stop))
			s = (ral_grid*)SV2Object(stop, RAL_GRIDPTR);
		if (SvOK(op))
			o = (ral_grid*)SV2Object(op, RAL_GRIDPTR);
		RETVAL = ral_fdg_path_length(fdg, s, o);
  	OUTPUT:	
		RETVAL
	POSTCALL:
		if (ral_has_msg())
			croak("%s",ral_get_msg());

ral_grid *
ral_fdg_path_sum(fdg, stop, op)
	ral_grid *fdg
	SV *stop
	ral_grid *op
	CODE:
		ral_grid *s = NULL;
		if (SvOK(stop))
			s = (ral_grid*)SV2Object(stop, RAL_GRIDPTR);
		RETVAL = ral_fdg_path_sum(fdg, s, op);
  	OUTPUT:	
		RETVAL
	POSTCALL:
		if (ral_has_msg())
			croak("%s",ral_get_msg());

ral_grid *
ral_fdg_upslope_sum(fdg, op, include_self)
	ral_grid *fdg
	ral_grid *op
	int include_self
	POSTCALL:
		if (ral_has_msg())
			croak("%s",ral_get_msg());

ral_grid *
ral_fdg_upslope_count(fdg, op, include_self)
	ral_grid *fdg
	ral_grid *op
	int include_self
	POSTCALL:
		if (ral_has_msg())
			croak("%s",ral_get_msg());

ral_grid *
ral_fdg_upslope_count_without_op(fdg, include_self)
	ral_grid *fdg
	int include_self
	CODE:
		RETVAL = ral_fdg_upslope_count(fdg, NULL, include_self);
  	OUTPUT:	
		RETVAL
	POSTCALL:
		if (ral_has_msg())
			croak("%s",ral_get_msg());

long
ral_fdg_catchment(fdg, mark, i, j, m)
	ral_grid *fdg
	ral_grid *mark
	int i
	int j
	int m
	CODE:
		ral_pour_point_struct pp;
		ral_cell c = {i, j};
		RETVAL = ral_fdg_catchment(fdg, mark, c, m);
		fail:
	OUTPUT:
		RETVAL
	POSTCALL:
		if (ral_has_msg())
			croak("%s",ral_get_msg());

NO_OUTPUT int
ral_streams_vectorize(streams, fdg, i, j)
	ral_grid *streams
	ral_grid *fdg
	int i
	int j
	POSTCALL:
		if (ral_has_msg())
			croak("%s",ral_get_msg());

NO_OUTPUT int
ral_compare_dem_derived_ws_attribs(str, uag, dem, dir, basename, iname, ielev, idarea)
	ral_grid *str
	ral_grid *uag
	ral_grid *dem
	char *dir	
	char *basename		
	int iname
	int ielev
	int idarea
	POSTCALL:
		if (ral_has_msg())
			croak("%s",ral_get_msg());

NO_OUTPUT int
ral_fdg_kill_extra_outlets(fdg, lakes, uag)
	ral_grid *fdg
	ral_grid *lakes
	ral_grid *uag
	POSTCALL:
		if (ral_has_msg())
			croak("%s",ral_get_msg());

NO_OUTPUT int
ral_streams_prune(streams, fdg, lakes, i, j, min_l)
	ral_grid *streams
	ral_grid *fdg
	ral_grid *lakes
	int i
	int j
	double min_l
	CODE:
		ral_cell c = {i, j};
		if (i >= 0)
			ral_streams_prune(streams, fdg, lakes, c, min_l);
		else
			ral_streams_prune2(streams, fdg, lakes, min_l);
	POSTCALL:
		if (ral_has_msg())
			croak("%s",ral_get_msg());

NO_OUTPUT int
ral_streams_prune_without_lakes(streams, fdg, i, j, min_l)
	ral_grid *streams
	ral_grid *fdg
	int i
	int j
	double min_l
	CODE:
		ral_cell c = {i, j};
		if (i >= 0)
			ral_streams_prune(streams, fdg, NULL, c, min_l);
		else
			ral_streams_prune2(streams, fdg, NULL, min_l);
	POSTCALL:
		if (ral_has_msg())
			croak("%s",ral_get_msg());

NO_OUTPUT int
ral_streams_number(streams, fdg, i, j, sid0)
	ral_grid *streams
	ral_grid *fdg
	int i
	int j
	int sid0
	CODE:
		ral_cell c = {i, j};
		if (i >= 0)
			ral_streams_number(streams, fdg, c, sid0);
		else
			ral_streams_number2(streams, fdg, sid0);
	POSTCALL:
		if (ral_has_msg())
			croak("%s",ral_get_msg());

NO_OUTPUT int
ral_streams_break(streams, fdg, lakes, nsid)
	ral_grid *streams
	ral_grid *fdg
	ral_grid *lakes
	int nsid
	POSTCALL:
		if (ral_has_msg())
			croak("%s",ral_get_msg());

ral_grid *
ral_streams_subcatchments(streams, fdg, i, j)
	ral_grid *streams
	ral_grid *fdg
	int i
	int j
	CODE:
	{
		ral_cell c = {i, j};
		if (i >= 0)
			RETVAL = ral_streams_subcatchments(streams, fdg, c);
		else
			RETVAL = ral_streams_subcatchments2(streams, fdg);
	}
	OUTPUT:	
		RETVAL
	POSTCALL:
		if (ral_has_msg())
			croak("%s",ral_get_msg());

HV *
ral_catchment_create(sheds, streams, fdg, lakes, i, j, headwaters)
	ral_grid *sheds
	ral_grid *streams
	ral_grid *fdg
	ral_grid *lakes
	int i
	int j
	int headwaters
	CODE:
	{
		ral_catchment *catchment;
		ral_cell outlet = {i, j};
		HV *h = newHV();
		sv_2mortal((SV*)h);
		if (i >= 0) {
			RAL_CHECK(catchment = ral_catchment_create(sheds, streams, fdg, lakes, outlet, headwaters));
		} else {
			RAL_CHECK(catchment = ral_catchment_create_complete(sheds, streams, fdg, lakes, headwaters));
		}
		for (i = 0; i < catchment->n; i++) {
			char key[21];
			U32 klen;
			snprintf(key, 20, "%i,%i", catchment->down[i].i, catchment->down[i].j);
			klen = strlen(key);
			SV *sv = newSVpv(key, klen);
			snprintf(key, 20, "%i,%i", catchment->outlet[i].i, catchment->outlet[i].j);
			klen = strlen(key);
			hv_store(h, key, klen, sv, 0);
		}
	fail:
		ral_catchment_destroy(&catchment);
		RETVAL = h;
	}
	OUTPUT:
		RETVAL
	POSTCALL:
		if (ral_has_msg())
			croak("%s",ral_get_msg());

AV *
ral_grid_variogram(ral_grid *gd, double max_lag, int lags)
	CODE:
	{
		ral_variogram *variogram = ral_grid_variogram(gd, max_lag, lags);
		if (variogram) {
			AV *av = newAV();
			int i;
			sv_2mortal((SV*)av);
			RETVAL = av;
			for (i = 0; i < variogram->size; i++) {
				AV *row = newAV();
				av_push(row, newSVnv(variogram->lag[i]));
				av_push(row, newSVnv(variogram->y[i]));
				av_push(row, newSVnv(variogram->n[i]));
				av_push(av, (SV*)newRV((SV*)row));
			}
			ral_variogram_destroy(&variogram);
		}
	}
	OUTPUT:
		RETVAL
	POSTCALL:
		if (ral_has_msg())
			croak("%s",ral_get_msg());

AV *
ral_grid_krige(ral_grid *gd, int i, int j, char *S, double param, double range)
	CODE:
	{
		ral_cell p;
		p.i = i;
		p.j = j;
		ral_grid_krige(gd, p, ral_spherical, &param, range);
	}
	OUTPUT:
		RETVAL
	POSTCALL:
		if (ral_has_msg())
			croak("%s",ral_get_msg());

ral_pixbuf *
gtk2_ex_geo_pixbuf_create(int width, int height, double minX, double maxY, double pixel_size, int bgc1, int bgc2, int bgc3)
	CODE:
		GDALColorEntry background = {bgc1, bgc2, bgc3, 255};
		ral_pixbuf *pb = ral_pixbuf_create(width, height, minX, maxY, pixel_size, background);
		RETVAL = pb;
  OUTPUT:
    RETVAL
	POSTCALL:
		if (ral_has_msg())
			croak("%s",ral_get_msg());

ral_pixbuf *
ral_pixbuf_create_from_grid(gd)
	ral_grid *gd
	POSTCALL:
		if (ral_has_msg())
			croak("%s",ral_get_msg());

void 
gtk2_ex_geo_pixbuf_destroy(pb)
	ral_pixbuf *pb
	CODE:
	ral_pixbuf_destroy(&pb);

void
ral_pixbuf_save(pb, filename, type, option_keys, option_values)
	ral_pixbuf *pb
	const char *filename
	const char *type
	AV* option_keys
	AV* option_values
	CODE:
		GdkPixbuf *gpb;
		GError *error = NULL;
		int i;
		char **ok = NULL;
		char **ov = NULL;
		int size = av_len(option_keys)+1;
		gpb = ral_gdk_pixbuf(pb);
		RAL_CHECKM(ok = (char **)calloc(size, sizeof(char *)), RAL_ERRSTR_OOM);
		RAL_CHECKM(ov = (char **)calloc(size, sizeof(char *)), RAL_ERRSTR_OOM);
		for (i = 0; i < size; i++) {
			STRLEN len;
			SV **s = av_fetch(option_keys, i, 0);
			ok[i] = SvPV(*s, len);
			s = av_fetch(option_values, i, 0);
			ov[i] = SvPV(*s, len);
		}
		gdk_pixbuf_savev(gpb, filename, type, ok, ov, &error);
		fail:
		if (ok) {
			for (i = 0; i < size; i++) {
				if (ok[i]) free (ok[i]);
			}
			free(ok);
		}
		if (ov) {
			for (i = 0; i < size; i++) {
				if (ov[i]) free (ov[i]);
			}
			free(ov);
		}
		if (error) {
			croak("%s",error->message);
			g_error_free(error);
		}
	POSTCALL:
		if (ral_has_msg())
			croak("%s",ral_get_msg());

ral_integer_grid_layer *
ral_make_integer_grid_layer(perl_layer)
	HV *perl_layer
	CODE:
		ral_visual visual;
		ral_visual_initialize(&visual);
		visual.symbol_field_type = visual.color_field_type = OFTInteger;
		ral_integer_grid_layer *layer = NULL;
		RAL_CHECK(fetch2visual(perl_layer, &visual, NULL));
		RAL_CHECK(layer = ral_integer_grid_layer_create());

		SV **s = hv_fetch(perl_layer, "ALPHA", strlen("ALPHA"), 0);
		if (s && sv_isobject(*s))
		   RAL_CHECK(layer->alpha_grid = (ral_grid*)SV2Object(*s, RAL_GRIDPTR));

		layer->alpha = visual.alpha;
		layer->palette_type = visual.palette_type;
		layer->symbol = visual.symbol;
		layer->symbol_pixel_size = visual.symbol_pixel_size;
		layer->symbol_size_scale = visual.symbol_size_scale_int;
		layer->single_color = visual.single_color;		
		layer->hue_at = visual.hue_at;
		layer->invert = visual.invert;
		layer->scale = visual.scale;
		layer->grayscale_base_color = visual.grayscale_base_color;
		layer->color_scale = visual.color_scale_int;
		layer->color_table = visual.color_table;
		visual.color_table = NULL;
		layer->color_bins = visual.int_bins;
		visual.int_bins = NULL;

		goto ok;
		fail:
		ral_integer_grid_layer_destroy(&layer);
		layer = NULL;
		ok:
		ral_visual_finalize(visual);
		RETVAL = layer;
  OUTPUT:
    RETVAL
	POSTCALL:
		if (ral_has_msg())
			croak("%s",ral_get_msg());


void
ral_destroy_integer_grid_layer(layer)
	ral_integer_grid_layer *layer
	CODE:
		ral_integer_grid_layer_destroy(&layer);


ral_real_grid_layer *
ral_make_real_grid_layer(perl_layer)
	HV *perl_layer
	CODE:
		ral_visual visual;
		ral_visual_initialize(&visual);
		visual.symbol_field_type = visual.color_field_type = OFTReal;
		ral_real_grid_layer *layer = NULL;
		RAL_CHECK(fetch2visual(perl_layer, &visual, NULL));
		RAL_CHECK(layer = ral_real_grid_layer_create());

		SV **s = hv_fetch(perl_layer, "ALPHA", strlen("ALPHA"), 0);
		if (s && sv_isobject(*s))
		   RAL_CHECK(layer->alpha_grid = (ral_grid*)SV2Object(*s, RAL_GRIDPTR));

		layer->alpha = visual.alpha;
		layer->palette_type = visual.palette_type;
		layer->symbol = visual.symbol;
		layer->symbol_pixel_size = visual.symbol_pixel_size;
		layer->symbol_size_scale = visual.symbol_size_scale_double;
		layer->single_color = visual.single_color;
		layer->hue_at = visual.hue_at;
		layer->invert = visual.invert;
		layer->scale = visual.scale;
		layer->grayscale_base_color = visual.grayscale_base_color;
		layer->color_scale = visual.color_scale_double;
		layer->color_bins = visual.double_bins;
		visual.double_bins = NULL;

		goto ok;
		fail:
		ral_real_grid_layer_destroy(&layer);
		layer = NULL;
		ok:
		ral_visual_finalize(visual);
		RETVAL = layer;
  OUTPUT:
    RETVAL
	POSTCALL:
		if (ral_has_msg())
			croak("%s",ral_get_msg());


void
ral_destroy_real_grid_layer(layer);
	ral_real_grid_layer *layer
	CODE:
		ral_real_grid_layer_destroy(&layer);


void 
ral_render_igrid(pb, gd, layer)
	gtk2_ex_geo_pixbuf *pb
	ral_grid *gd
	ral_integer_grid_layer *layer
	CODE:
		ral_pixbuf rpb;
		gtk2_ex_geo_pixbuf_2_ral_pixbuf(pb, &rpb);
		layer->gd = gd;
		ral_render_integer_grid(&rpb, layer);
	POSTCALL:
		if (ral_has_msg())
			croak("%s",ral_get_msg());


void 
ral_render_rgrid(pb, gd, layer)
	gtk2_ex_geo_pixbuf *pb
	ral_grid *gd
	ral_real_grid_layer *layer
	CODE:
		ral_pixbuf rpb;
		gtk2_ex_geo_pixbuf_2_ral_pixbuf(pb, &rpb);
		layer->gd = gd;
		ral_render_real_grid(&rpb, layer);
	POSTCALL:
		if (ral_has_msg())
			croak("%s",ral_get_msg());

void 
ral_render_grids(pb, b1, b2, b3, alpha, color_interpretation)
	ral_pixbuf *pb
	ral_grid *b1
	ral_grid *b2
	ral_grid *b3
	SV *alpha
	int color_interpretation
	CODE:
		short a = 255;
		ral_grid *a_gd = NULL;
		if (SvIOK(alpha))
			a = SvIV(alpha);
		else if (sv_isobject(alpha)) {
			RAL_CHECK(a_gd = (ral_grid*)SV2Object(alpha, RAL_GRIDPTR));
		} else {
			croak("%s","alpha is not integer nor a grid");
			goto fail;
		}
		/*ral_render_grids(pb, b1, b2, b3, a, a_gd, color_interpretation);*/
		fail:
	POSTCALL:
		if (ral_has_msg())
			croak("%s","%s",ral_get_msg());


ral_visual_layer *
ral_visual_layer_create(perl_layer, ogr_layer)
	HV *perl_layer
	OGRLayerH ogr_layer
	CODE:
		ral_visual_layer *layer = ral_visual_layer_create();
		layer->layer = ogr_layer;
		RAL_CHECK(fetch2visual(perl_layer, &layer->visualization, OGR_L_GetLayerDefn(layer->layer)));
		goto ok;
		fail:
		ral_visual_layer_destroy(&layer);
		layer = NULL;
		ok:
		RETVAL = layer;
  OUTPUT:
    RETVAL
	POSTCALL:
		if (ral_has_msg())
			croak("%s",ral_get_msg());

void
ral_visual_layer_destroy(layer)
	ral_visual_layer *layer
	CODE:
		ral_visual_layer_destroy(&layer);

void
ral_visual_layer_render(layer, pb)
	ral_visual_layer *layer
	ral_pixbuf *pb
	CODE:
		ral_render_visual_layer(pb, layer);
	POSTCALL:
	if (ral_has_msg())
		croak("%s",ral_get_msg());

ral_visual_feature_table *
ral_visual_feature_table_create(perl_layer, features)
	HV *perl_layer
	AV *features
	CODE:
		ral_visual_feature_table *layer = ral_visual_feature_table_create(av_len(features)+1);
		RAL_CHECK(layer);
		char *color_field_name = NULL, *symbol_size_field_name = NULL;;

		RAL_FETCH(perl_layer, "COLOR_FIELD", color_field_name, SvPV_nolen);
		RAL_FETCH(perl_layer, "SYMBOL_FIELD", symbol_size_field_name, SvPV_nolen);

		int i;
		for (i = 0; i <= av_len(features); i++) {
			SV** sv = av_fetch(features,i,0);
			OGRFeatureH f = SV2Handle(*sv);
			layer->features[i].feature = f;
			OGRFeatureDefnH fed = OGR_F_GetDefnRef(f);

			int field = -1;
			if (color_field_name) {
				field = OGR_FD_GetFieldIndex(fed, color_field_name);
				if (field >= 0) {
					OGRFieldDefnH fid = OGR_FD_GetFieldDefn(fed, field);
					OGRFieldType fit = OGR_Fld_GetType(fid);
					if (!(fit == OFTInteger OR fit == OFTReal))
						field = -1;
				}
			}
			RAL_STORE(perl_layer, "COLOR_FIELD_VALUE", field, newSViv);

			field = -2;
			if (symbol_size_field_name) {
				field = OGR_FD_GetFieldIndex(fed, symbol_size_field_name);
				if (field >= 0) {
					OGRFieldDefnH fid = OGR_FD_GetFieldDefn(fed, field);
					OGRFieldType fit = OGR_Fld_GetType(fid);
					if (!(fit == OFTInteger OR fit == OFTReal))
						field = -2;
				} else
					field = -2;
			}
			RAL_STORE(perl_layer, "SYMBOL_FIELD_VALUE", field, newSViv);

			RAL_CHECK(fetch2visual(perl_layer, &layer->features[i].visualization, OGR_F_GetDefnRef(f)));
			
		}

		goto ok;
		fail:
		ral_visual_feature_table_destroy(&layer);
		layer = NULL;
		ok:
		RETVAL = layer;
  OUTPUT:
    RETVAL
	POSTCALL:
		if (ral_has_msg())
			croak("%s",ral_get_msg());

void
ral_visual_feature_table_destroy(layer)
	ral_visual_feature_table *layer
	CODE:
		ral_visual_feature_table_destroy(&layer);

void
ral_visual_feature_table_render(layer, pb)
	ral_visual_feature_table *layer
	ral_pixbuf *pb
	CODE:
		ral_render_visual_feature_table(pb, layer);
	POSTCALL:
	if (ral_has_msg())
		croak("%s",ral_get_msg());

GdkPixbuf_noinc *
gtk2_ex_geo_pixbuf_get_pixbuf(ral_pixbuf *pb)
	CODE:
		if (ral_cairo_to_pixbuf(pb))
			RETVAL = ral_gdk_pixbuf(pb);
	OUTPUT:
		RETVAL
	POSTCALL:
		if (ral_has_msg())
			croak("%s",ral_get_msg());

cairo_surface_t_noinc *
gtk2_ex_geo_pixbuf_get_cairo_surface(pb)
	ral_pixbuf *pb
    CODE:
	RETVAL = cairo_image_surface_create_for_data
		(pb->image, CAIRO_FORMAT_ARGB32, pb->N, pb->M, pb->image_rowstride);
    OUTPUT:
	RETVAL
