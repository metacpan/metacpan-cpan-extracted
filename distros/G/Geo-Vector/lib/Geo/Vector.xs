#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <gtk2-ex-geo.h>

#include <ral.h>

#define RAL_GRIDPTR "ral_gridPtr"
#define RAL_ERRSTR_OOM "Out of memory"

#include "../../const-c.inc"

#include "help.c"

MODULE = Geo::Vector		PACKAGE = Geo::Vector

INCLUDE: ../../const-xs.inc

OGRDataSourceH
OGRDataSourceH(ogr)
	SV *ogr
	CODE:
	{
		OGRDataSourceH h = (OGRDataSourceH)0;
		IV tmp = SV2Handle(ogr);
		h = (OGRDataSourceH)tmp;
		RETVAL = h;
	}
  OUTPUT:
    RETVAL

OGRLayerH
OGRLayerH(layer)
	SV *layer
	CODE:
	{
		OGRLayerH h = (OGRLayerH)0;
		IV tmp = SV2Handle(layer);
		h = (OGRLayerH)tmp;
		RETVAL = h;
	}
  OUTPUT:
    RETVAL

SV *
field_index(field)
	char *field
	CODE:
		if (strcmp(field, ".FID") == 0)
		   RETVAL = newSViv(RAL_FIELD_FID);
		else if (strcmp(field, ".Z") == 0)
		   RETVAL = newSViv(RAL_FIELD_Z);
		else if (strcmp(field, "Fixed size") == 0)
		   RETVAL = newSViv(RAL_FIELD_FIXED_SIZE);
		else
		   RETVAL = &PL_sv_undef;
	OUTPUT:
	    RETVAL

int
undefined_field_index()
	CODE:
            RETVAL = RAL_FIELD_UNDEFINED;
	OUTPUT:
	    RETVAL

void
xs_rasterize(l, gd, render_override, fid_to_rasterize, value_field)
	OGRLayerH l
	ral_grid *gd
	int render_override
	int fid_to_rasterize
	int value_field
	CODE:
	if (fid_to_rasterize > -1 ) {

		OGRFieldType ft = 0;
		OGRFeatureH f = OGR_L_GetFeature(l, fid_to_rasterize);
		if (value_field >= 0)
		   RAL_CHECK(ral_get_field_type(l, value_field, &ft));
		ral_grid_rasterize_feature(gd, f, value_field, ft, render_override);

	} else {

		ral_grid_rasterize_layer(gd, l, value_field, render_override);
	}
	fail:
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
	gtk2_ex_geo_pixbuf *pb
	CODE:
		ral_pixbuf rpb;
		gtk2_ex_geo_pixbuf_2_ral_pixbuf(pb, &rpb);
		ral_render_visual_layer(&rpb, layer);
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
		int i;
		for (i = 0; i <= av_len(features); i++) {
			SV** sv = av_fetch(features,i,0);
			if (!SvGMAGICAL(*sv) AND SvROK(*sv))			    
			    sv = hv_fetch((HV*)SvRV(*sv), "OGRGeometry", 10, 0);
			OGRGeometryH f = SV2Handle(*sv);
			layer->features[i].feature = f;
			OGRFeatureDefnH fed = OGR_F_GetDefnRef(f);
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
	gtk2_ex_geo_pixbuf *pb
	CODE:
		ral_pixbuf rpb;
		gtk2_ex_geo_pixbuf_2_ral_pixbuf(pb, &rpb);
		ral_render_visual_feature_table(&rpb, layer);
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

