enum pdl_datatypes { PDL_B, PDL_S, PDL_US, PDL_L, PDL_LL, PDL_F, PDL_D };

RAL_INTEGER int_from_pdl(void *x, int datatype, int i) {
    switch (datatype) {
    case PDL_L: 
    {	
	int *xx = (int *) x;
	return (RAL_INTEGER)xx[i];
    }break;
    case PDL_F:
    {   	
	float *xx = (float *) x;
	return (RAL_INTEGER)xx[i];	
    }break;    
    case PDL_S:
    {   	
	short *xx = (short *) x;
	return (RAL_INTEGER)xx[i];	
    }break;    
    case PDL_US:
    {   	
	unsigned short *xx = (unsigned short *) x;
	return (RAL_INTEGER)xx[i];	
    }break;
    case PDL_D:
    {   	
	double *xx = (double *) x;
	return (RAL_INTEGER)xx[i];	
    }break;
    case PDL_B:
    {   	
	unsigned char *xx = (unsigned char *) x;
	return (RAL_INTEGER)xx[i];	
    }break;    
    case PDL_LL:
    {   	
	long long *xx = (long long *) x;
	return (RAL_INTEGER)xx[i];	
    }break;    
    default:
	croak ("Not a known data type code=%d", datatype);
    }
}


RAL_REAL real_from_pdl(void *x, int datatype, int i) {
    switch (datatype) {
    case PDL_L:
    {	
	int *xx = (int *) x;
	return (RAL_REAL)xx[i];
    }break;
    case PDL_F:
    {   	
	float *xx = (float *) x;
	return (RAL_REAL)xx[i];	
    }break;    
    case PDL_S:
    {   	
	short *xx = (short *) x;
	return (RAL_REAL)xx[i];	
    }break;    
    case PDL_US:
    {   	
	unsigned short *xx = (unsigned short *) x;
	return (RAL_REAL)xx[i];	
    }break;
    case PDL_D:
    {   	
	double *xx = (double *) x;
	return (RAL_REAL)xx[i];	
    }break;
    case PDL_B:
    {   	
	unsigned char *xx = (unsigned char *) x;
	return (RAL_REAL)xx[i];	
    }break;    
    case PDL_LL:
    {   	
	long long *xx = (long long *) x;
	return (RAL_REAL)xx[i];	
    }break;    
    default:
	croak ("Not a known data type code=%d", datatype);
    }
}
 

IV SV2Handle(SV *sv)
{
    if (SvGMAGICAL(sv))
	mg_get(sv);
    if (!sv_isobject(sv))
	croak("parameter is not an object");
    SV *tsv = (SV*)SvRV(sv);
    if ((SvTYPE(tsv) != SVt_PVHV))
	croak("parameter is not a hashref");
    if (!SvMAGICAL(tsv))
	croak("parameter does not have magic");
    MAGIC *mg = mg_find(tsv,'P');
    if (!mg)
	croak("parameter does not have right kind of magic");
    sv = mg->mg_obj;
    if (!sv_isobject(sv))
	croak("parameter does not have really right kind of magic");
    return SvIV((SV*)SvRV(sv));
}

IV SV2Object(SV *sv, char *stash)
{
    if (!sv_isobject(sv)) {
	croak("parameter is not an object");
	return 0;
    }
    sv = (SV*)SvRV(sv);
    if (strcmp(stash,HvNAME((HV*)SvSTASH(sv)))!=0) {
	croak("parameter is not a %s",stash);
	return 0;
    }
    return SvIV(sv);
}

GDALColorEntry fetch_color(AV *a, int i)
{
    GDALColorEntry color;
    SV **s = av_fetch(a, i++, 0);
    color.c1 = s ? SvUV(*s) : 0;
    s = av_fetch(a, i++, 0);
    color.c2 = s ? SvUV(*s) : 0;
    s = av_fetch(a, i++, 0);
    color.c3 = s ? SvUV(*s) : 0;
    s = av_fetch(a, i++, 0);
    color.c4 = s ? SvUV(*s) : 0;
    return color;
}

#define RAL_FETCH(from, key, to, as)			\
    {SV **s = hv_fetch(from, key, strlen(key), 0);	\
	if (s) {					\
	    (to) = as(*s);				\
	}}

#define RAL_STORE(to, key, from, with)		\
    hv_store(to, key, strlen(key), with(from), 0);


/* convert a focal area expressed as an array of arrays to a simple int array 
   the focal area is a M x M square, where M is an odd number and the center of the
   square is the cell of interest 
   d is defined by 2*d+1 = M
   the length of the returned array is M x M
   M is >= 1
*/
int *focal2mask(AV *focal, int *d, int defined_is_enough)
{
    int *mask = NULL;
    int i, j, m = av_len(focal)+1, M = -1, ix;
    /* get the M */
    for (i = 0; i < m; i++) {
	SV **s = av_fetch(focal, i, 0);
	RAL_CHECKM(SvROK(*s) AND SvTYPE(SvRV(*s)) == SVt_PVAV, 
		   "the focal area parameter must be a reference to an array of arrays");
	M = M < 0 ? av_len((AV*)SvRV(*s))+1 : max(M, av_len((AV*)SvRV(*s))+1);
    }
    M = max(max(m, M), 1);
    *d = (M-1)/2;
    M = 2*(*d)+1;
    ix = 0;
    SV *sv;
    RAL_CHECKM(mask = (int *)calloc(M*M, sizeof(int)), RAL_ERRSTR_OOM);
    for (i = 0; i < M; i++) {
	if (i < m) {
	    SV **s = av_fetch(focal, i, 0);
	    int n = av_len((AV*)SvRV(*s))+1;
	    for (j = 0; j < M; j++) {
		if (j < n) {
		    SV **t = av_fetch((AV*)SvRV(*s), j, 0);
		    if (t AND *t AND SvOK(*t)) {
			if (defined_is_enough)
			    mask[ix] = 1;
			else
			    mask[ix] = SvIV(*t) ? 1 : 0;
		    } else
			mask[ix] = 0;
		} else
		    mask[ix] = 0;
		ix++;
	    }
	} else 
	    for (j = 0; j < M; j++) {
		mask[ix] = 0;
		ix++;
	    }
    }
    return mask;
fail:
    if(mask) free(mask);
    return NULL;
}

/* convert a focal area expressed as an array of arrays to a simple double array 
   the focal area is a M x M square, where M is an odd number and the center of the
   square is the cell of interest 
   d is defined by 2*d+1 = M
   the length of the returned array is M x M
   M is >= 1
*/
double *focal2maskd(AV *focal, int *d, int defined_is_enough)
{
    double *mask = NULL;
    int i, j, m = av_len(focal)+1, M = -1, ix;
    /* get the M */
    for (i = 0; i < m; i++) {
	SV **s = av_fetch(focal, i, 0);
	RAL_CHECKM(SvROK(*s) AND SvTYPE(SvRV(*s)) == SVt_PVAV, 
		   "the focal area parameter must be a reference to an array of arrays");
	M = M < 0 ? av_len((AV*)SvRV(*s))+1 : max(M, av_len((AV*)SvRV(*s))+1);
    }
    M = max(max(m, M), 1);
    *d = (M-1)/2;
    M = 2*(*d)+1;
    ix = 0;
    SV *sv;
    RAL_CHECKM(mask = (double *)calloc(M*M, sizeof(double)), RAL_ERRSTR_OOM);
    for (i = 0; i < M; i++) {
	if (i < m) {
	    SV **s = av_fetch(focal, i, 0);
	    int n = av_len((AV*)SvRV(*s))+1;
	    for (j = 0; j < M; j++) {
		if (j < n) {
		    SV **t = av_fetch((AV*)SvRV(*s), j, 0);
		    if (t AND *t AND SvOK(*t)) {
			if (defined_is_enough)
			    mask[ix] = 1;
			else
			    mask[ix] = SvNV(*t) ? 1 : 0;
		    } else
			mask[ix] = 0;
		} else
		    mask[ix] = 0;
		ix++;
	    }
	} else 
	    for (j = 0; j < M; j++) {
		mask[ix] = 0;
		ix++;
	    }
    }
    return mask;
fail:
    if(mask) free(mask);
    return NULL;
}

int fetch2visual(HV *perl_layer, ral_visual *visual, OGRFeatureDefnH defn)
{
    /* these are mostly from the Geo::Layer object */
    SV **s = hv_fetch(perl_layer, "ALPHA", strlen("ALPHA"), 0);
    if (s && SvIOK(*s))
	visual->alpha = SvIV(*s);
    RAL_FETCH(perl_layer, "PALETTE_VALUE", visual->palette_type, SvIV);
    RAL_FETCH(perl_layer, "SYMBOL_VALUE", visual->symbol, SvIV);
    RAL_FETCH(perl_layer, "SYMBOL_SIZE", visual->symbol_pixel_size, SvIV);
    RAL_FETCH(perl_layer, "HUE_AT_MIN", visual->hue_at.min, SvIV);
    RAL_FETCH(perl_layer, "HUE_AT_MAX", visual->hue_at.max, SvIV);
    RAL_FETCH(perl_layer, "INVERT", visual->invert, SvIV);
    RAL_FETCH(perl_layer, "GRAYSCALE_SUBTYPE_VALUE", visual->scale, SvIV);
    s = hv_fetch(perl_layer, "SINGLE_COLOR", strlen("SINGLE_COLOR"), 0);
    if (s AND SvROK(*s)) {
	AV *a = (AV*)SvRV(*s);
	if (a)
	    visual->single_color = fetch_color(a, 0);
    }
    s = hv_fetch(perl_layer, "GRAYSCALE_COLOR", strlen("GRAYSCALE_COLOR"), 0);
    if (s AND SvROK(*s)) {
	AV *a = (AV*)SvRV(*s);
	if (a)
	    visual->grayscale_base_color = fetch_color(a, 0);
    }
    if (defn) {
	RAL_FETCH(perl_layer, "SYMBOL_FIELD_VALUE", visual->symbol_field, SvIV);
	if (visual->symbol_field >= 0) {
	    RAL_CHECK(ral_get_field_type(defn, visual->symbol_field, &(visual->symbol_field_type)));
	} else /* FID or fixed size */
	    visual->symbol_field_type = OFTInteger;
    } else
	visual->symbol_field = RAL_FIELD_UNDEFINED;
	
    switch (visual->symbol_field_type) {
    case OFTInteger:
	RAL_FETCH(perl_layer, "SYMBOL_SCALE_MIN", visual->symbol_size_scale_int.min, SvIV);
	RAL_FETCH(perl_layer, "SYMBOL_SCALE_MAX", visual->symbol_size_scale_int.max, SvIV);
	break;
    case OFTReal:
	RAL_FETCH(perl_layer, "SYMBOL_SCALE_MIN", visual->symbol_size_scale_double.min, SvNV);
	RAL_FETCH(perl_layer, "SYMBOL_SCALE_MAX", visual->symbol_size_scale_double.max, SvNV);
	break;
    default:
	RAL_CHECKM(0, ral_msg("Invalid field type for symbol scale: %s", OGR_GetFieldTypeName(visual->symbol_field_type)));
	break;
    }    
    
    if (defn) {
	RAL_FETCH(perl_layer, "COLOR_FIELD_VALUE", visual->color_field, SvIV);
	if (visual->color_field >= 0) {
	    RAL_CHECK(ral_get_field_type(defn, visual->color_field, &(visual->color_field_type)));
	} else /* FID */
	    visual->color_field_type = OFTInteger;
    } else
	visual->color_field = RAL_FIELD_UNDEFINED;
    
    switch (visual->color_field_type) {
    case OFTInteger:
	RAL_FETCH(perl_layer, "COLOR_SCALE_MIN", visual->color_scale_int.min, SvIV);
	RAL_FETCH(perl_layer, "COLOR_SCALE_MAX", visual->color_scale_int.max, SvIV);
	break;
    case OFTReal:
	RAL_FETCH(perl_layer, "COLOR_SCALE_MIN", visual->color_scale_double.min, SvNV);
	RAL_FETCH(perl_layer, "COLOR_SCALE_MAX", visual->color_scale_double.max, SvNV);
	break;
    case OFTString:
	break;
    default:
	RAL_CHECKM(0, ral_msg("Invalid field type for color scale: %s", OGR_GetFieldTypeName(visual->color_field_type)));
	break;
    }
	
    RAL_FETCH(perl_layer, "RENDER_AS_VALUE", visual->render_as, SvIV);
    s = hv_fetch(perl_layer, "COLOR_TABLE", strlen("COLOR_TABLE"), 0);
    if (visual->palette_type == RAL_PALETTE_COLOR_TABLE AND s AND SvROK(*s)) {
	AV *a = (AV*)SvRV(*s);
	int i, n = a ? av_len(a)+1 : 0;
	if (n > 0) {
	    switch (visual->color_field_type) {
	    case OFTInteger:
		RAL_CHECK(visual->color_table = ral_color_table_create(n));
		for (i = 0; i < n; i++) {
		    SV **s = av_fetch(a, i, 0);
		    AV *c;
		    RAL_CHECKM(s AND SvROK(*s) AND (c = (AV*)SvRV(*s)), "Bad color table data");
		    s = av_fetch(c, 0, 0);
		    visual->color_table->keys[i] = s ? SvIV(*s) : 0;
		    visual->color_table->colors[i] = fetch_color(c, 1);
		}
		break;
	    case OFTString:
		RAL_CHECK(visual->string_color_table = ral_string_color_table_create(n));
		for (i = 0; i < n; i++) {
		    STRLEN len;
		    SV **s = av_fetch(a, i, 0);
		    AV *c;
		    RAL_CHECKM(s AND SvROK(*s) AND (c = (AV*)SvRV(*s)), "Bad color table data");
		    s = av_fetch(c, 0, 0);
		    if (s)
			ral_string_color_table_set(visual->string_color_table, SvPV(*s, len), i, fetch_color(c, 1));
		}
		break;
	    default:
		RAL_CHECKM(0, ral_msg("Invalid field type for color table: %s", OGR_GetFieldTypeName(visual->color_field_type)));
	    }
	}
    }
    s = hv_fetch(perl_layer, "COLOR_BINS", strlen("COLOR_BINS"), 0);
    if (visual->palette_type == RAL_PALETTE_COLOR_BINS AND s AND SvROK(*s)) {
	AV *a = (AV*)SvRV(*s);
	int i, n = a ? av_len(a)+1 : 0;
	if (n > 0) {
	    switch (visual->color_field_type) {
	    case OFTInteger:
		RAL_CHECK(visual->int_bins = ral_int_color_bins_create(n));
		for (i = 0; i < n; i++) {
		    SV **s = av_fetch(a, i, 0);
		    AV *c;
		    RAL_CHECKM(s AND SvROK(*s) AND (c = (AV*)SvRV(*s)), "Bad color bins data");
		    s = av_fetch(c, 0, 0);
		    if (i < n-1)
			visual->int_bins->bins[i] = s ? SvIV(*s) : 0;
		    visual->int_bins->colors[i] = fetch_color(c, 1);
		}
		break;
	    case OFTReal:
		RAL_CHECK(visual->double_bins = ral_double_color_bins_create(n));
		for (i = 0; i < n; i++) {
		    SV **s = av_fetch(a, i, 0);
		    AV *c;
		    RAL_CHECKM(s AND SvROK(*s) AND (c = (AV*)SvRV(*s)), "Bad color bins data");
		    s = av_fetch(c, 0, 0);
		    if (i < n-1)
			visual->double_bins->bins[i] = s ? SvNV(*s) : 0;
		    visual->double_bins->colors[i] = fetch_color(c, 1);
		}
		break;
	    default:
		RAL_CHECKM(0, ral_msg("Invalid field type for color bins: %s", OGR_GetFieldTypeName(visual->color_field_type)));
	    }
	}
    }
    return 1;
fail:
    return 0;
}

void gtk2_ex_geo_pixbuf_2_ral_pixbuf(gtk2_ex_geo_pixbuf *pb, ral_pixbuf *rpb)
{
    rpb->image = pb->image;
    rpb->image_rowstride = pb->image_rowstride;
    rpb->pixbuf = pb->pixbuf;
    rpb->destroy_fn = pb->destroy_fn;
    rpb->colorspace = pb->colorspace;
    rpb->has_alpha = pb->has_alpha;
    rpb->rowstride = pb->rowstride;
    rpb->bits_per_sample = pb->bits_per_sample;
    rpb->N = pb->width;
    rpb->M = pb->height;
    rpb->world.min.x = pb->world_min_x;
    rpb->world.min.y = pb->world_max_y-pb->height*pb->pixel_size;
    rpb->world.max.x = pb->world_min_x+pb->width*pb->pixel_size;
    rpb->world.max.y = pb->world_max_y;
    rpb->pixel_size = pb->pixel_size;
}
