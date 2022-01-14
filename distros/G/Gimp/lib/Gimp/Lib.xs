#include "config.h"

#include <assert.h>
#include <stdio.h>

#include <libgimp/gimp.h>

#include <pdlcore.h>

/* various functions allocate static buffers, STILL.  */
#define MAX_STRING 4096

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "gppport.h"

#ifndef pTHX_
#define pTHX_
#endif

#include "perl-intl.h"

/* dirty is used in gimp.h AND in perl < 5.005 or with PERL_POLLUTE.  */
#ifdef dirty
# undef dirty
#endif

#include "gimp-perl.h"

#define GIMP_PKG	"Gimp::"	/* the package name */

#define PKG_COLOR	GIMP_PKG "Color"
#define PKG_ITEM	GIMP_PKG "Item"
#define PKG_DISPLAY	GIMP_PKG "Display"
#define PKG_IMAGE	GIMP_PKG "Image"
#define PKG_LAYER	GIMP_PKG "Layer"
#define PKG_CHANNEL	GIMP_PKG "Channel"
#define PKG_DRAWABLE	GIMP_PKG "Drawable"
#define PKG_SELECTION	GIMP_PKG "Selection"
#define PKG_PARASITE	GIMP_PKG "Parasite"
#define PKG_VECTORS	GIMP_PKG "Vectors"

#define PKG_GDRAWABLE	GIMP_PKG "GimpDrawable"
#define PKG_TILE	GIMP_PKG "Tile"
#define PKG_PIXELRGN	GIMP_PKG "PixelRgn"

#define PKG_ANY		((char *)0)

typedef GimpPixelRgn GimpPixelRgn_PDL;

static Core* PDL; /* Structure hold core C functions */

/* get pointer to PDL structure. */
static void need_pdl (void)
{
  SV *CoreSV;
  if (!PDL) {
    require_pv("PDL/Core.pm");
    CoreSV = get_sv("PDL::SHARE", FALSE);
    if (CoreSV == NULL)
      croak("gimp-perl-pixel functions require PDL::Core module - failed");
    PDL = INT2PTR(Core*,SvIV( CoreSV ));
  }
}

static pdl *new_pdl (int a, int b, int c)
{
  pdl *p = PDL->pdlnew();
  PDL_Indx dims[3];
  int ndims = 0;

  if (c > 0) dims[ndims++] = c;
  if (b > 0) dims[ndims++] = b;
  if (a > 0) dims[ndims++] = a;

  PDL->setdims (p, dims, ndims);
  p->datatype = PDL_B;
  PDL->allocdata (p);

  return p;
}

static void old_pdl (pdl **p, short ndims, int dim0)
{
  *p = PDL->get_convertedpdl(*p, PDL_B);
  PDL->make_physical (*p);

  if ((*p)->ndims < ndims + (dim0 > 1))
    croak (__("dimension mismatch, pdl has dimension %d but at least %d dimensions required"), (*p)->ndims, ndims + (dim0 > 1));

  if ((*p)->ndims > ndims + 1)
    croak (__("dimension mismatch, pdl has dimension %d but at most %d dimensions allowed"), (*p)->ndims, ndims + 1);

  if ((*p)->ndims > ndims && (*p)->dims[0] != dim0)
    croak (__("pixel size mismatch, pdl has %d channel pixels but %d channels are required"), (*p)->dims[0], dim0);
}

static void pixel_rgn_pdl_delete_data (pdl *p, size_t param)
{
  p->data = 0;
}

static pdl *redim_pdl (pdl *p, int ndim, int newsize)
{
  pdl *r = PDL->pdlnew();
  PDL_Indx dims[p->ndims], i; /* copy so as to modify */
  for (i = 0; i < p->ndims; i++) dims[i] = p->dims[i];
  dims[ndim] = newsize;
  PDL->affine_new (p, r, 0,
		   dims, p->ndims,
		   p->dimincs, p->ndims);
  return r;
}

/* set when it's safe to call gimp functions.  */
static int gimp_is_initialized = 0;

typedef gint32 IMAGE;
typedef gint32 LAYER;
typedef gint32 CHANNEL;
typedef gint32 DRAWABLE;
typedef gint32 SELECTION;
typedef gint32 DISPLAY;
typedef gint32 ITEM;
typedef gint32 COLOR;
typedef gpointer GimpPixelRgnIterator;

#define verbose_level SvIV(get_sv("Gimp::verbose", TRUE))

#ifndef __STDC__
#error You need to compile with an ansi-c compiler!!!
#error Remove these lines to continue at your own risk!
#endif

#if __STDC_VERSION__ > 199900 || __GNUC__
#define verbose_printf(level, ...) \
	do { \
	  if (verbose_level >= level) PerlIO_printf (PerlIO_stderr (), __VA_ARGS__); \
	} while(0)

#elif defined(__STDC__)

/* sigh */
#include <stdarg.h>
static void verbose_printf (int level, char *frmt, ...)
{
  va_list args;
  char buffer[MAX_STRING]; /* sorry... */

  if (verbose_level < level) return;
  va_start (args, frmt);
#ifdef HAVE_VSNPRINTF
  vsnprintf (buffer, sizeof buffer, frmt, args);
#else
  vsprintf (buffer, frmt, args);
#endif
  PerlIO_printf (PerlIO_stderr (), "%s", buffer);
}

#endif

void throw_exception(const gchar *log_domain, GLogLevelFlags log_level, const gchar *message, gpointer user_data)
{
  char buffer[MAX_STRING];
  snprintf (buffer, sizeof buffer, "%s: %s", log_domain, message);
  croak(buffer);
}

/* new SV with len len.  There _must_ be a better way, but newSV doesn't work.  */
static SV *newSVn (STRLEN len)
{
  SV *sv = newSVpv ("", 0);

  (void) SvUPGRADE (sv, SVt_PV);
  SvGROW (sv, len);
  SvCUR_set (sv, len);

  return sv;
}

static GHashTable *gdrawable_cache;

/* magic stuff.  literally.  */
static int gdrawable_free (pTHX_ SV *obj, MAGIC *mg)
{
  GimpDrawable *gdr = (GimpDrawable *)SvIV(obj);
  g_hash_table_remove (gdrawable_cache, GINT_TO_POINTER(gdr->drawable_id));
  gimp_drawable_detach (gdr);
  return 0;
}

static MGVTBL vtbl_gdrawable = {0, 0, 0, 0, gdrawable_free};

static SV *new_gdrawable (gint32 id)
{
   static HV *stash;
   SV *sv;
   if (!gdrawable_cache)
     gdrawable_cache = g_hash_table_new (g_direct_hash, g_direct_equal);
   assert (sizeof (gpointer) >= sizeof (id));
   if ((sv = (SV*)g_hash_table_lookup (gdrawable_cache, GINT_TO_POINTER(id)))) {
     SvREFCNT_inc (sv);
   } else {
     GimpDrawable *gdr = gimp_drawable_get (id);
     if (!gdr)
       croak (__("unable to convert Gimp::Drawable into Gimp::GimpDrawable (id %d)"), id);
     if (!stash)
       stash = gv_stashpv (PKG_GDRAWABLE, 1);
     sv = newSViv ((IV) gdr);
     sv_magic (sv, 0, '~', 0, 0);
     mg_find (sv, '~')->mg_virtual = &vtbl_gdrawable;
     g_hash_table_insert (gdrawable_cache, GINT_TO_POINTER(id), (void *)sv);
   }
   return sv_bless (newRV_noinc (sv), stash);
}

static void check_object(SV *sv, char *pkg)
{
  SV *rv;
  char *name;
  if (!SvOK(sv))
    croak (__("argument is undef"));
  if (!SvROK(sv))
    croak (__("argument is not a ref: '%s'"), SvPV_nolen(sv));
  rv = SvRV(sv);
  if (!SvOBJECT (rv))
    croak (__("argument is not an object: '%s'"), SvPV_nolen(sv));
  if (!(sv_derived_from (sv, pkg)))
    {
      name = HvNAME (SvSTASH (rv));
      croak (
	__("argument is not of type %s, instead: %s='%s'"),
	pkg,
	name,
	SvPV_nolen(sv)
      );
    }
}

static GimpDrawable *old_gdrawable (SV *sv)
{
  check_object(sv, PKG_GDRAWABLE);
  /* the next line lacks any type of checking.  */
  return (GimpDrawable *)SvIV(SvRV(sv));
}

static /* drawable/tile/region stuff.  */
SV *new_tile (GimpTile *tile, SV *gdrawable)
{
  static HV *stash;
  HV *hv = newHV ();

  (void)hv_store (hv, "_gdrawable",10, SvREFCNT_inc (gdrawable), 0);

  if (!stash)
    stash = gv_stashpv (PKG_TILE, 1);

  return sv_bless (newRV_noinc ((SV*)hv), stash);
}

static GimpTile *old_tile (SV *sv)
{
  check_object(sv, PKG_TILE);

  /* the next line lacks any type of checking.  */
  return (GimpTile *)SvIV(*(hv_fetch ((HV*)SvRV(sv), "_tile", 5, 0)));
}

/* magic stuff.  literally.  */
static int gpixelrgn_free (pTHX_ SV *obj, MAGIC *mg)
{
/*  GimpPixelRgn *pr = (GimpPixelRgn *)SvPV_nolen(obj); */
/* automatically done on detach */
/*  if (pr->dirty)
     gimp_drawable_flush (pr->drawable);*/

  return 0;
}

static MGVTBL vtbl_gpixelrgn = {0, 0, 0, 0, gpixelrgn_free};

/* coerce whatever was given into a gdrawable-sv */
static SV *force_gdrawable (SV *drawable)
{
  if (!(sv_derived_from (drawable, PKG_GDRAWABLE)))
    {
      if (sv_derived_from (drawable, PKG_DRAWABLE)
	  || sv_derived_from (drawable, PKG_LAYER)
	  || sv_derived_from (drawable, PKG_CHANNEL))
	drawable = sv_2mortal (new_gdrawable (SvIV (SvRV (drawable))));
      else
	croak (__("argument is not of type %s"), PKG_GDRAWABLE);
    }

  return drawable;
}

static SV *new_gpixelrgn (SV *gdrawable, int x, int y, int width, int height, int dirty, int shadow)
{
  static HV *stash;
  SV *sv = newSVn (sizeof (GimpPixelRgn));
  GimpPixelRgn *pr = (GimpPixelRgn *)SvPV_nolen(sv);
  verbose_printf (2, "new_gpixelrgn(%d, %d, %d, %d, %d, %d)\n", x, y, width, height, dirty, shadow);

  if (!stash)
    stash = gv_stashpv (PKG_PIXELRGN, 1);

  GimpDrawable *gd = old_gdrawable(gdrawable);
  gimp_pixel_rgn_init (pr, gd, x, y, width, height, dirty, shadow);
  verbose_printf (2, "gimp_pixel_rgn now={%d, %d, %d, %d, %d, %d}\n", pr->bpp, pr->rowstride, pr->x, pr->y, pr->w, pr->h, pr->dirty, pr->shadow);

  sv_magic (sv, SvRV(gdrawable), '~', 0, 0);
  mg_find (sv, '~')->mg_virtual = &vtbl_gpixelrgn;

  return sv_bless (newRV_noinc (sv), stash);
}

static GimpPixelRgn *old_pixelrgn (SV *sv)
{
  check_object(sv, PKG_PIXELRGN);

  return (GimpPixelRgn *)SvPV_nolen(SvRV(sv));
}

static GimpPixelRgn *old_pixelrgn_pdl (SV *sv)
{
  need_pdl ();
  return old_pixelrgn (sv);
}

static int
is_array (GimpPDBArgType typ)
{
  return typ == GIMP_PDB_INT32ARRAY
      || typ == GIMP_PDB_INT16ARRAY
      || typ == GIMP_PDB_INT8ARRAY
      || typ == GIMP_PDB_FLOATARRAY
      || typ == GIMP_PDB_STRINGARRAY
      || typ == GIMP_PDB_COLORARRAY;
}

static int
perl_param_count (const GimpParam *arg, int count)
{
  const GimpParam *end = arg + count;

  while (arg < end)
    if (is_array (arg++->type))
      count--;

  return count;
}

/*
 * count actual parameter number
 */
static int
perl_paramdef_count (GimpParamDef *arg, int count)
{
  GimpParamDef *end = arg + count;

  while (arg < end)
    if (is_array (arg++->type))
      count--;

  return count;
}

/* horrors!  c wasn't designed for this!  */
#define dump_printarray(args,index,ctype,datatype,frmt) {\
  int j; \
  verbose_printf (1, "["); \
  if (args[index].data.datatype || !args[index-1].data.d_int32) \
    { \
      for (j = 0; j < args[index-1].data.d_int32; j++) \
	verbose_printf (1, frmt "%s", (ctype) args[index].data.datatype[j], \
		      j < args[index-1].data.d_int32 - 1 ? ", " : ""); \
    } \
  else \
    verbose_printf (1, __("(UNINITIALIZED)")); \
  verbose_printf (1, "]"); \
}

static void
dump_params (int nparams, GimpParam *args, GimpParamDef *params)
{
  static char *ptype[GIMP_PDB_END+1] = {
    "INT32"      , "INT16"      , "INT8"      , "FLOAT"      , "STRING"     ,
    "INT32ARRAY" , "INT16ARRAY" , "INT8ARRAY" , "FLOATARRAY" , "STRINGARRAY",
    "COLOR"      , "ITEM"       , "DISPLAY"   , "IMAGE"      , "LAYER"      ,
    "CHANNEL"    , "DRAWABLE"   , "SELECTION" , "COLORARRAY" , "VECTORS"    ,
    "PARASITE"   ,
    "STATUS"     , "END"
  };
  int i;

  if (verbose_level < 1) return;
  verbose_printf (1, "(");

  verbose_printf (2, "\n\t");

  for (i = 0; i < nparams; i++)
    {
      if ((unsigned int)params[i].type < GIMP_PDB_END+1)
	verbose_printf (2, "%s ", ptype[params[i].type]);
      else
	verbose_printf (2, "T%d ", params[i].type);

      verbose_printf (2, "%s=", params[i].name);

      switch (args[i].type)
	{
	  case GIMP_PDB_INT32:		verbose_printf (1, "%d", args[i].data.d_int32); break;
	  case GIMP_PDB_INT16:		verbose_printf (1, "%d", args[i].data.d_int16); break;
	  case GIMP_PDB_INT8:		verbose_printf (1, "%d", (guint8) args[i].data.d_int8); break;
	  case GIMP_PDB_FLOAT:		verbose_printf (1, "%f", args[i].data.d_float); break;
	  case GIMP_PDB_STRING:		verbose_printf (1, "\"%s\"", args[i].data.d_string ? args[i].data.d_string : "[null]"); break;
	  case GIMP_PDB_DISPLAY:	verbose_printf (1, "%d", args[i].data.d_display); break;
	  case GIMP_PDB_IMAGE:		verbose_printf (1, "%d", args[i].data.d_image); break;
	  case GIMP_PDB_ITEM:		verbose_printf (1, "%d", args[i].data.d_item); break;
	  case GIMP_PDB_LAYER:		verbose_printf (1, "%d", args[i].data.d_layer); break;
	  case GIMP_PDB_CHANNEL:	verbose_printf (1, "%d", args[i].data.d_channel); break;
	  case GIMP_PDB_DRAWABLE:	verbose_printf (1, "%d", args[i].data.d_drawable); break;
	  case GIMP_PDB_SELECTION:	verbose_printf (1, "%d", args[i].data.d_selection); break;
	  case GIMP_PDB_COLORARRAY:
		{
		  int j;
		  verbose_printf (1, "[");
		  if (args[i].data.d_colorarray || !args[i-1].data.d_int32) {
		    for (j = 0; j < args[i-1].data.d_int32; j++)
		      verbose_printf (1, 
			"[%f,%f,%f,%f]%s",
			((GimpRGB) args[i].data.d_colorarray[j]).r,
			((GimpRGB) args[i].data.d_colorarray[j]).g,
			((GimpRGB) args[i].data.d_colorarray[j]).b,
			((GimpRGB) args[i].data.d_colorarray[j]).a,
			j < args[i-1].data.d_int32 - 1 ? ", " : ""
		      );
		  } else
		    verbose_printf (1, __("(UNINITIALIZED)"));
		  verbose_printf (1, "]");
		}
		break;
	  case GIMP_PDB_VECTORS:	verbose_printf (1, "%d", args[i].data.d_vectors); break;
	  case GIMP_PDB_STATUS:		verbose_printf (1, "%d", args[i].data.d_status); break;
	  case GIMP_PDB_INT32ARRAY:	dump_printarray (args, i, gint32, d_int32array, "%d"); break;
	  case GIMP_PDB_INT16ARRAY:	dump_printarray (args, i, gint16, d_int16array, "%d"); break;
	  case GIMP_PDB_INT8ARRAY:	dump_printarray (args, i, guint8, d_int8array , "%d"); break;
	  case GIMP_PDB_FLOATARRAY:	dump_printarray (args, i, gfloat, d_floatarray, "%f"); break;
	  case GIMP_PDB_STRINGARRAY:	dump_printarray (args, i, char* , d_stringarray, "'%s'"); break;

	  case GIMP_PDB_COLOR:
	    verbose_printf (1, "[%f,%f,%f,%f]",
			  args[i].data.d_color.r,
			  args[i].data.d_color.g,
			  args[i].data.d_color.b,
			  args[i].data.d_color.a);
	    break;

	  case GIMP_PDB_PARASITE:
	    {
	      gint32 found = 0;

	      if (args[i].data.d_parasite.name)
		{
		 verbose_printf (1, "[%s, ", args[i].data.d_parasite.name);
		 if (args[i].data.d_parasite.flags & GIMP_PARASITE_PERSISTENT)
		   {
		     verbose_printf (1, "GIMP_PARASITE_PERSISTENT");
		     found |= GIMP_PARASITE_PERSISTENT;
		   }

		 if (args[i].data.d_parasite.flags & ~found)
		   {
		     if (found)
		       verbose_printf (1, "|");
		     verbose_printf (1, "%d", args[i].data.d_parasite.flags & ~found);
		   }

		 verbose_printf (1, __(", %d bytes data]"), args[i].data.d_parasite.size);
	       }
	      else
		verbose_printf (1, __("[undefined]"));
	    }
	    break;

	  default:
	    verbose_printf (1, "(?%d?)", args[i].type);
	}

      if (verbose_level >= 2)
	verbose_printf (2, "\t\"%s\"\n\t", params[i].description);
      else if (i < nparams - 1)
	verbose_printf (1, ", ");

    }

  verbose_printf (1, ")");
}

static int
convert_array2paramdef (AV *av, GimpParamDef **res)
{
  int count = 0;
  GimpParamDef *def = 0;

  if (av_len (av) >= 0)
    for(;;) {
      int idx;

      for (idx = 0; idx <= av_len (av); idx++) {
	SV *sv = *av_fetch (av, idx, 0);
	SV *type = 0;
	SV *name = 0;
	SV *help = 0;

	if (SvROK (sv) && SvTYPE (SvRV (sv)) == SVt_PVAV) {
	  AV *av = (AV *)SvRV(sv);
	  SV **x;

	  if ((x = av_fetch (av, 0, 0))) type = *x;
	  if ((x = av_fetch (av, 1, 0))) name = *x;
	  if ((x = av_fetch (av, 2, 0))) help = *x;
	} else
	  croak("Each parameter to a plugin must be an array-ref");

	if (type) {
	  if (def) {
	    if (is_array (SvIV (type))) {
	      def->type = GIMP_PDB_INT32;
	      def->name = "array_size";
	      def->description = "the size of the following array";
	      def++;
	    }

	    def->type = SvIV (type);
	    def->name = name ? SvPV_nolen (name) : 0;
	    def->description = help ? SvPV_nolen (help) : 0;
	    def++;
	  }
	  else
	    count += 1 + !!is_array (SvIV (type));
	} else
	  croak (__("malformed paramdef, expected [PARAM_TYPE,\"NAME\",\"DESCRIPTION\"] or PARAM_TYPE"));
      }

      if (def)
	break;

      *res = def = g_new (GimpParamDef, count);
    }
  else
    *res = 0;

  return count;
}

static SV *
newSV_paramdefs (GimpParamDef *p, int n)
{
   int i;
   AV *av = newAV ();

   av_extend (av, n-1);
   for (i=0; i<n; i++)
     {
       AV *a = newAV ();
       av_extend (a, 3-1);
       av_store (a, 0, newSViv (p->type));
       av_store (a, 1, newSVpv (p->name,0));
       av_store (a, 2, newSVpv (p->description,0));
       p++;

       av_store (av, i, newRV_noinc ((SV*)a));
     }

   return newRV_noinc ((SV*)av);
}

static HV *
param_stash (GimpPDBArgType type)
{
  static HV *bless_hv[GIMP_PDB_END]; /* initialized to zero */
  static char *bless[GIMP_PDB_END] = {
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    PKG_COLOR,
    PKG_ITEM,
    PKG_DISPLAY,
    PKG_IMAGE,
    PKG_LAYER,
    PKG_CHANNEL,
    PKG_DRAWABLE,
    PKG_SELECTION,
    0,
    PKG_VECTORS,
    PKG_PARASITE,
    0
  };

  if (bless [type] && !bless_hv [type])
    bless_hv [type] = gv_stashpv (bless [type], 1);

  return bless_hv [type];
}

/* automatically bless SV into PARAM_type.  */
/* for what it's worth, we cache the stashes.  */
static SV *
autobless (SV *sv, int type)
{
  HV *stash = param_stash (type);

  if (stash)
    sv = sv_bless (newRV_noinc (sv), stash);

  if (stash && !SvOBJECT(SvRV(sv)))
    croak ("jupp\n");

  return sv;
}

/* return gint32 from object, whether iv or rv.  */
static gint32
unbless (SV *sv, char *type, char *croak_str)
{
  if (!sv_isobject (sv)) return SvIV (sv);
  if (type == PKG_ANY || sv_derived_from (sv, type)) {
    if (SvTYPE (SvRV (sv)) == SVt_PVMG)
      return SvIV (SvRV (sv));
    else
      strcpy (croak_str, __("only blessed scalars accepted here"));
  } else
    sprintf (croak_str, __("argument type %s expected (not %s)"), type, HvNAME(SvSTASH(SvRV(sv))));

  return -1;
}

static gint32
unbless_croak (SV *sv, char *type)
{
   char croak_str[MAX_STRING];
   gint32 r;
   croak_str[0] = 0;

   r = unbless (sv, type, croak_str);

   if (croak_str [0])
      croak (croak_str);

   return r;
}

static void
canonicalize_colour (char *err, SV *sv, GimpRGB *c)
{
  dSP;

  ENTER;
  SAVETMPS;

  PUSHMARK(SP);
  XPUSHs (sv);
  PUTBACK;

  if (perl_call_pv ("Gimp::canonicalize_colour", G_SCALAR) != 1)
    croak (__("FATAL: canonicalize_colour did not return a value!"));

  SPAGAIN;

  sv = POPs;
  if (SvROK(sv)) {
    if (SvTYPE(SvRV(sv)) == SVt_PVAV) {
      AV *av = (AV *)SvRV(sv);

      c->r = SvNV (*av_fetch (av, 0, 0));
      c->g = SvNV (*av_fetch (av, 1, 0));
      c->b = SvNV (*av_fetch (av, 2, 0));

      if (av_len(av) == 2)
	c->a = 1.0;
      else if (av_len(av) == 3)
	c->a = SvNV (*av_fetch (av, 3, 0));
      else
	sprintf (err, __("a color must have three (RGB) or four (RGBA) components (array elements)"));
    } else
      sprintf (err, __("illegal type for colour specification"));
  } else
    sprintf (err, __("unable to grok colour specification"));

  PUTBACK;
  FREETMPS;
  LEAVE;
}

/* check for common typoes.  */
static void check_for_typoe (char *croak_str, char *p)
{
  char b[80];

  g_snprintf (b, sizeof b, "%s_MODE", p);	if (perl_get_cv (b, 0)) goto gotit;
  g_snprintf (b, sizeof b, "%s_MASK", p);	if (perl_get_cv (b, 0)) goto gotit;
  g_snprintf (b, sizeof b, "SELECTION_%s", p);	if (perl_get_cv (b, 0)) goto gotit;
  g_snprintf (b, sizeof b, "%s_IMAGE", p);	if (perl_get_cv (b, 0)) goto gotit;
  return;

gotit:
  sprintf (croak_str, __("Expected a number but got '%s'. Maybe you meant '%s' instead and forgot to 'use strict'"), p, b);
}

/* check for 'enumeration types', i.e. integer constants. do not allow
   string constants here, and check for common typoes. */
static int check_num (char *croak_str, SV *sv)
{
  if (SvIOKp(sv) || SvNOKp(sv)) return 1;
  if (SvTYPE (sv) == SVt_PV)
    {
      char *p = SvPV_nolen (sv);
      if (*p
	  && *p != '0' && *p != '1' && *p != '2' && *p != '3' && *p != '4'
	  && *p != '5' && *p != '6' && *p != '7' && *p != '8' && *p != '9'
	  && *p != '-')
	{
	  sprintf (croak_str, __("Expected a number but got '%s'. Add '*1' if you really intend to pass in a string."), p);
	  check_for_typoe (croak_str, p);
	  return 0;
	}
    }
  return 1;
}

/* replacement newSVpv with only one argument.  */
#define neuSVpv(arg) ((arg) ? newSVpv((arg),0) : newSVsv (&PL_sv_undef))

/* replacement newSViv which casts to unsigned char.  */
#define newSVu8(arg) newSViv((unsigned char)(arg))

/* create sv's using newsv, from the array arg.  */
#define push_gimp_av(arg,datatype,newsv,as_ref) {		\
  int j;							\
  AV *av;							\
  if (as_ref)							\
    av = newAV ();						\
  else								\
    { av = 0; EXTEND (SP, arg[-1].data.d_int32); }		\
  for (j = 0; j < arg[-1].data.d_int32; j++)			\
    if (as_ref)							\
      av_push (av, newsv (arg->data.datatype[j]));		\
    else							\
      PUSHs (sv_2mortal (newsv (arg->data.datatype[j])));	\
  if (as_ref)							\
    PUSHs (sv_2mortal (newRV_noinc ((SV *)av)));		\
}

static void
push_gimp_sv (const GimpParam *arg, int array_as_ref)
{
  dSP;
  SV *sv = 0;

  switch (arg->type)
    {
      case GIMP_PDB_INT32:	sv = newSViv(arg->data.d_int32	); break;
      case GIMP_PDB_INT16:	sv = newSViv(arg->data.d_int16	); break;
      case GIMP_PDB_INT8:	sv = newSVu8(arg->data.d_int8	); break;
      case GIMP_PDB_FLOAT:	sv = newSVnv(arg->data.d_float	); break;
      case GIMP_PDB_STRING:	sv = neuSVpv(arg->data.d_string ); break;

      case GIMP_PDB_DISPLAY:
      case GIMP_PDB_IMAGE:
      case GIMP_PDB_LAYER:
      case GIMP_PDB_CHANNEL:
      case GIMP_PDB_DRAWABLE:
      case GIMP_PDB_ITEM:
      case GIMP_PDB_SELECTION:
      case GIMP_PDB_VECTORS:
      case GIMP_PDB_STATUS:

	{
	  int id;

	  switch (arg->type) {
	    case GIMP_PDB_DISPLAY:	id = arg->data.d_display; break;
	    case GIMP_PDB_IMAGE:	id = arg->data.d_image; break;
	    case GIMP_PDB_LAYER:	id = arg->data.d_layer; break;
	    case GIMP_PDB_CHANNEL:	id = arg->data.d_channel; break;
	    case GIMP_PDB_DRAWABLE:	id = arg->data.d_drawable; break;
	    case GIMP_PDB_ITEM:		id = arg->data.d_item; break;
	    case GIMP_PDB_SELECTION:	id = arg->data.d_selection; break;
	    case GIMP_PDB_VECTORS:	id = arg->data.d_vectors; break;
	    case GIMP_PDB_STATUS:	id = arg->data.d_status; break;
	    default:			abort ();
	  }

	  if (id == -1)
	    PUSHs (newSVsv (&PL_sv_undef));
	  else
	    sv = newSViv (id);
	}
	break;

      case GIMP_PDB_COLOR:
	{
	  /* difficult */
	  AV *av = newAV ();

	  av_push (av, newSVnv (arg->data.d_color.r));
	  av_push (av, newSVnv (arg->data.d_color.g));
	  av_push (av, newSVnv (arg->data.d_color.b));
	  av_push (av, newSVnv (arg->data.d_color.a));

	  sv = (SV *)av; /* no newRV_inc, since we're getting autoblessed! */
	}
	break;

      case GIMP_PDB_PARASITE:
	if (arg->data.d_parasite.name)
	  {
	    AV *av = newAV ();
	    av_push (av, neuSVpv (arg->data.d_parasite.name));
	    av_push (av, newSViv (arg->data.d_parasite.flags));
	    av_push (av, newSVpv (arg->data.d_parasite.data, arg->data.d_parasite.size));
	    sv = (SV *)av;
	  }

	break;

      /* did I say difficult before????  */
      case GIMP_PDB_INT32ARRAY:		push_gimp_av (arg, d_int32array , newSViv, array_as_ref); break;
      case GIMP_PDB_INT16ARRAY:		push_gimp_av (arg, d_int16array , newSViv, array_as_ref); break;
      case GIMP_PDB_INT8ARRAY:		push_gimp_av (arg, d_int8array  , newSVu8, array_as_ref); break;
      case GIMP_PDB_FLOATARRAY:		push_gimp_av (arg, d_floatarray , newSVnv, array_as_ref); break;
      case GIMP_PDB_STRINGARRAY:	push_gimp_av (arg, d_stringarray, neuSVpv, array_as_ref); break;
      case GIMP_PDB_COLORARRAY:
	{
	  int j;
	  AV *av;
	  if (array_as_ref)
	    av = newAV ();
	  else
	    { av = 0; EXTEND (SP, arg[-1].data.d_int32); }
	  for (j = 0; j < arg[-1].data.d_int32; j++) {
	    AV *color = newAV ();
	    av_push (color, newSVnv (((GimpRGB) arg->data.d_colorarray[j]).r));
	    av_push (color, newSVnv (((GimpRGB) arg->data.d_colorarray[j]).g));
	    av_push (color, newSVnv (((GimpRGB) arg->data.d_colorarray[j]).b));
	    av_push (color, newSVnv (((GimpRGB) arg->data.d_colorarray[j]).a));
	    SV *color_ref = newRV_noinc ((SV *)color);
	    if (array_as_ref)
	      av_push (av, color_ref);
	    else
	      PUSHs (sv_2mortal (color_ref));
	  }
	  if (array_as_ref)
	    PUSHs (sv_2mortal (newRV_noinc ((SV *)av)));
	}
	break;

      default:
	croak (__("dunno how to return param type %d"), arg->type);
    }

  if (sv)
    PUSHs (sv_2mortal (autobless (sv, arg->type)));

  PUTBACK;
}

#define SvPv(sv) (SvOK(sv) ? SvPV_nolen(sv) : 0)
#define Sv32(sv) unbless ((sv), PKG_ANY, croak_str)

#define av2gimp(arg,sv,datatype,type,svxv) { \
  if (SvROK (sv) && SvTYPE(SvRV(sv)) == SVt_PVAV) \
    { \
      int i; \
      AV *av = (AV *)SvRV(sv); \
      arg[-1].data.d_int32 = av_len (av) + 1; \
      arg->data.datatype = g_new (type, av_len (av) + 1); \
      for (i = 0; i <= av_len (av); i++) \
	arg->data.datatype[i] = svxv (*av_fetch (av, i, 0)); \
    } \
  else \
    { \
      sprintf (croak_str, __("perl-arrayref required as datatype for a gimp-array")); \
      arg->data.datatype = 0; \
    } \
}

#define sv_croak_ref(sv, str) \
	if (SvROK(sv)) \
	  sprintf (croak_str, __("Unable to convert a reference to type '%s'"), str);
#define sv_getnum(sv, func, lvalue, typestr) \
	sv_croak_ref(sv, typestr); if (*croak_str) return 1; \
	check_num(croak_str, sv); if (*croak_str) return 1; \
	lvalue = func(sv);

/*
 * convert a perl scalar into a GimpParam, return true if
 * the argument has been consumed.
 */
static int
convert_sv2gimp (char *croak_str, GimpParam *arg, SV *sv)
{
  switch (arg->type)
    {
      case GIMP_PDB_INT32: sv_getnum(sv, SvIV, arg->data.d_int32, "INT32"); break;
      case GIMP_PDB_INT16: sv_getnum(sv, SvIV, arg->data.d_int16, "INT16"); break;
      case GIMP_PDB_INT8: sv_getnum(sv, SvIV, arg->data.d_int8, "INT8"); break;
      case GIMP_PDB_FLOAT: sv_getnum(sv, SvNV, arg->data.d_float, "FLOAT"); break;
      case GIMP_PDB_STRING: {
	sv_croak_ref(sv, "STRING");
	arg->data.d_string = g_strdup (SvPv(sv));
	break;
      }

      case GIMP_PDB_ITEM:
      case GIMP_PDB_DISPLAY:
      case GIMP_PDB_IMAGE:
      case GIMP_PDB_LAYER:
      case GIMP_PDB_CHANNEL:
      case GIMP_PDB_DRAWABLE:
      case GIMP_PDB_VECTORS:
      case GIMP_PDB_STATUS:

	if (SvOK(sv))
	  switch (arg->type) {
	    case GIMP_PDB_ITEM:		arg->data.d_item	= unbless(sv, PKG_ITEM  , croak_str); break;
	    case GIMP_PDB_DISPLAY:	arg->data.d_display	= unbless(sv, PKG_DISPLAY  , croak_str); break;
	    case GIMP_PDB_LAYER:	arg->data.d_layer	= unbless(sv, PKG_ITEM  , croak_str); break;
	    case GIMP_PDB_CHANNEL:	arg->data.d_channel	= unbless(sv, PKG_ITEM  , croak_str); break;
	    case GIMP_PDB_DRAWABLE:	arg->data.d_drawable	= unbless(sv, PKG_ITEM  , croak_str); break;
	    case GIMP_PDB_VECTORS:	arg->data.d_vectors	= unbless(sv, PKG_ITEM  , croak_str); break;
	    case GIMP_PDB_STATUS: sv_getnum(sv, SvIV, arg->data.d_status, "STATUS"); break;
	    case GIMP_PDB_IMAGE:
	      {
		if (sv_derived_from (sv, PKG_ITEM))
		  arg->data.d_image = gimp_item_get_image(
		    unbless(sv, PKG_ITEM, croak_str)
		  );
		else if (sv_derived_from (sv, PKG_IMAGE) || !SvROK (sv)) {
		  arg->data.d_image = unbless(sv, PKG_IMAGE, croak_str);
		  break;
		} else
		  strcpy (croak_str, __("argument incompatible with type IMAGE"));

		return 0;
	      }

	    default:
	      abort ();
	  }
	else
	  switch (arg->type) {
	    case GIMP_PDB_ITEM:		arg->data.d_item	= -1; break;
	    case GIMP_PDB_DISPLAY:	arg->data.d_display	= -1; break;
	    case GIMP_PDB_LAYER:	arg->data.d_layer	= -1; break;
	    case GIMP_PDB_CHANNEL:	arg->data.d_channel	= -1; break;
	    case GIMP_PDB_DRAWABLE:	arg->data.d_drawable	= -1; break;
	    case GIMP_PDB_VECTORS:	arg->data.d_vectors	= -1; break;
	    case GIMP_PDB_STATUS:	arg->data.d_status	= -1; break;
	    case GIMP_PDB_IMAGE:	arg->data.d_image	= -1; return 0; break;
	    default:			abort ();
	  }

	break;

      case GIMP_PDB_COLOR:
	canonicalize_colour (croak_str, sv, &arg->data.d_color);
	break;

      case GIMP_PDB_PARASITE:
	if (SvROK(sv))
	  {
	    if (SvTYPE(SvRV(sv)) == SVt_PVAV)
	      {
		AV *av = (AV *)SvRV(sv);
		if (av_len(av) == 2)
		  {
		    STRLEN size;

		    arg->data.d_parasite.name  = SvPv(*av_fetch(av, 0, 0));
		    arg->data.d_parasite.flags = SvIV(*av_fetch(av, 1, 0));
		    arg->data.d_parasite.data  = SvPV(*av_fetch(av, 2, 0), size);

		    arg->data.d_parasite.size = size;
		  }
		else
		  sprintf (croak_str, __("illegal parasite specification, expected three array members"));
	      }
	    else
	      sprintf (croak_str, __("illegal parasite specification, arrayref expected"));
	  }
	else
	  sprintf (croak_str, __("illegal parasite specification, reference expected"));

	break;

      case GIMP_PDB_INT32ARRAY:	av2gimp (arg, sv, d_int32array , gint32 , Sv32); break;
      case GIMP_PDB_INT16ARRAY:	av2gimp (arg, sv, d_int16array , gint16 , SvIV); break;
      case GIMP_PDB_INT8ARRAY:	av2gimp (arg, sv, d_int8array  , guint8 , SvIV); break;
      case GIMP_PDB_FLOATARRAY:	av2gimp (arg, sv, d_floatarray , gdouble, SvNV); break;
      case GIMP_PDB_STRINGARRAY: {
	if (SvROK (sv) && SvTYPE(SvRV(sv)) != SVt_PVAV) {
	  sprintf (croak_str, __("perl-arrayref required as d_stringarray for a gimp-array"));
	  arg->data.d_stringarray = 0;
	  break;
	}
	int i;
	AV *av = (AV *)SvRV(sv);
	int len = av_len (av) + 1;
	arg[-1].data.d_int32 = len;
	arg->data.d_stringarray = g_new (gchar *, len);
	for (i = 0; i <= av_len (av); i++) {
	  char *p = SvPv (*av_fetch (av, i, 0));
	  arg->data.d_stringarray[i] = g_strdup (p);
	}
	break;
      }

      case GIMP_PDB_COLORARRAY:
	if (SvROK (sv) && SvTYPE(SvRV(sv)) != SVt_PVAV) {
	  sprintf (croak_str, __("perl-arrayref required as datatype for a gimp-array"));
	  arg->data.d_colorarray = 0;
	  break;
	}
	int i;
	AV *av = (AV *)SvRV(sv);
	arg[-1].data.d_int32 = av_len (av) + 1;
	arg->data.d_colorarray = g_new (GimpRGB, av_len (av) + 1);
	for (i = 0; i <= av_len (av); i++)
	  canonicalize_colour (
	    croak_str,
	    *av_fetch (av, i, 0),
	    &arg->data.d_colorarray[i]
	  );
	break;

      default:
	croak (
	  __("tried to convert '%s' to unknown type %d"),
	  SvPV_nolen(sv),
	  arg->type
	);
    }

  return 1;
}

/* do not free actual string or parasite data */
static void
destroy_params (GimpParam *arg, int count)
{
  int i;

  for (i = 0; i < count; i++)
    switch (arg[i].type)
      {
	case GIMP_PDB_INT32ARRAY:	g_free (arg[i].data.d_int32array); break;
	case GIMP_PDB_INT16ARRAY:	g_free (arg[i].data.d_int16array); break;
	case GIMP_PDB_INT8ARRAY:	g_free (arg[i].data.d_int8array); break;
	case GIMP_PDB_FLOATARRAY:	g_free (arg[i].data.d_floatarray); break;
	case GIMP_PDB_STRINGARRAY:	g_free (arg[i].data.d_stringarray); break;

	default: ;
      }

  g_free (arg);
}

static void simple_perl_call (char *function, char *arg1)
{
   dSP;

   ENTER;
   SAVETMPS;

   PUSHMARK (SP);
   XPUSHs (sv_2mortal (newSVpv (arg1, 0)));

   PUTBACK;
   perl_call_pv (function, G_VOID);
   SPAGAIN;

   FREETMPS;
   LEAVE;
}

#define try_call(cb)      simple_perl_call ("Gimp::callback", (cb) )

static void pii_init (void) { try_call ("-init" ); }
static void pii_query(void) { try_call ("-query"); }
static void pii_quit (void) { try_call ("-quit" ); }

static void pii_run(const gchar *name,
		    gint nparams,
		    const GimpParam *param,
		    gint *xnreturn_vals,
		    GimpParam **xreturn_vals)
{
  // static as need to leave allocated until finished with; freed on next entry
  static GimpParam *return_vals;
  static int nreturn_vals;

  dSP;

  int i, count;
  char *err_msg = 0;

  char *proc_blurb;
  char *proc_help;
  char *proc_author;
  char *proc_copyright;
  char *proc_date;
  GimpPDBProcType proc_type;
  int _nparams;
  GimpParamDef *params;
  GimpParamDef *return_defs;

  // freeing these if currently allocated - libgimp requirement
  if (return_vals) {
    destroy_params (return_vals, nreturn_vals);
    return_vals = NULL;
    nreturn_vals = 0;
  }

  // do this here as at BOOT causes error
  gimp_plugin_set_pdb_error_handler (GIMP_PDB_ERROR_HANDLER_PLUGIN);
  if (
    gimp_procedural_db_proc_info (
      name, &proc_blurb, &proc_help, &proc_author,
      &proc_copyright, &proc_date, &proc_type, &_nparams, &nreturn_vals,
      &params, &return_defs
    ) != TRUE
  ) {
    err_msg = g_strdup_printf (__("being called as '%s', but '%s' not registered in the pdb"), name, name);
    goto error;
  }

  g_free (proc_blurb);
  g_free (proc_help);
  g_free (proc_author);
  g_free (proc_copyright);
  g_free (proc_date);
  gimp_destroy_paramdefs (params, _nparams);

  // from here stops meaning "number of values returned from proc call" and
  // starts meaning "number of values to be returned up chain"
  nreturn_vals++; // since we're inserting the STATUS "value" in 0-th place.

  ENTER;
  SAVETMPS;
  PUSHMARK(SP);

  EXTEND (SP, 3);
  PUSHs (sv_2mortal (newSVpv ("-run", 4)));
  PUSHs (sv_2mortal (newSVpv (name, 0)));

  if (nparams) {
    EXTEND (SP, perl_param_count (param, nparams));
    PUTBACK;
    for (i = 0; i < nparams; i++) {
      if (i < nparams-1 && is_array (param[i+1].type))
	i++;

      push_gimp_sv (param+i, nparams > 2);
    }

    SPAGAIN;
  } else
    PUTBACK;

  count = perl_call_pv (
    "Gimp::callback",
    G_EVAL | G_ARRAY
  );
  SPAGAIN;

  if (SvTRUE (ERRSV)) {
    err_msg = g_strdup (SvPV_nolen (ERRSV));
  } else {
    char errmsg [MAX_STRING];
    errmsg [0] = 0;

    return_vals = (GimpParam *) g_new0 (GimpParam, nreturn_vals);
    return_vals[0].type = GIMP_PDB_STATUS;
    return_vals[0].data.d_status = GIMP_PDB_SUCCESS;
    *xnreturn_vals = nreturn_vals;
    *xreturn_vals = return_vals;

    for (i = nreturn_vals - 1; i > 0; i--) {
      return_vals[i].type = return_defs[i - 1].type;
      if (i < nreturn_vals - 1 && is_array(return_defs[i].type))
	// if one above is an array, this will be count, already set
	// by convert_sv2gimp (and no perl-stack var supplied) so skip
	continue;
      if (--count < 0) {
	err_msg = g_strdup_printf(
	  __("function '%s' got back too few return values; expected %d"),
	  name,
	  nreturn_vals - 1
	);
	goto error;
      }
      convert_sv2gimp (errmsg, return_vals + i, POPs);
      if (errmsg [0]) {
	err_msg = g_strdup (errmsg);
	goto error;
      }
    }

    if (count) err_msg = g_strdup_printf(
      __("function '%s' got back %d too many return values; expected %d"),
      name,
      count,
      nreturn_vals - 1
    );
  }

  gimp_destroy_paramdefs (return_defs, nreturn_vals - 1);

  PUTBACK;
  FREETMPS;
  LEAVE;

  if (!err_msg)
    return;

  error:

  if (return_vals)
    destroy_params (return_vals, nreturn_vals);

  nreturn_vals = 2;
  return_vals = g_new (GimpParam, nreturn_vals);
  return_vals[0].type = GIMP_PDB_STATUS;
  return_vals[0].data.d_status = GIMP_PDB_EXECUTION_ERROR;
  return_vals[1].type = GIMP_PDB_STRING;
  return_vals[1].data.d_string = err_msg;
  *xnreturn_vals = nreturn_vals;
  *xreturn_vals = return_vals;
}

#define pii_init 0 /* init gets called on every startup, so disable it for the time being. */
GimpPlugInInfo PLUG_IN_INFO = { pii_init, pii_quit, pii_query, pii_run };

MODULE = Gimp::Lib	PACKAGE = Gimp::Lib

PROTOTYPES: ENABLE

SV *
_autobless (sv,type)
	SV *	sv
	gint32	type
	CODE:
	RETVAL = autobless (newSVsv (sv), type);
	OUTPUT:
	RETVAL

PROTOTYPES: DISABLE

int
gimp_main(...)
	PREINIT:
	CODE:
		SV *sv;

		if ((sv = perl_get_sv ("Gimp::help", FALSE)) && SvTRUE (sv))
		  RETVAL = 0;
		else
		  {
		    char *argv [10];
		    int argc = 0;

		    if (items != 0)
		      croak (__("arguments to main not yet supported!"));
		    AV *av = perl_get_av ("ARGV", FALSE);

		    argv [argc++] = SvPV_nolen (perl_get_sv ("0", FALSE));
		    if (!(av && av_len (av) < 10-1))
		      croak ("internal error (please report): too many arguments to main");
		    while (argc-1 <= av_len (av))
		      argv [argc] = SvPV_nolen (*av_fetch (av, argc-1, 0)),
		      argc++;

		    gimp_is_initialized = 1;
		    RETVAL = gimp_main (&PLUG_IN_INFO, argc, argv);
		    gimp_is_initialized = 0;
		    /*exit (0);*/ /*D*//* shit, some memory problem here, so just exit */
		  }
	OUTPUT:
	RETVAL

PROTOTYPES: ENABLE

int
initialized()
	CODE:
	RETVAL = gimp_is_initialized;
	OUTPUT:
	RETVAL

int
gimp_major_version()
	CODE:
	RETVAL = gimp_major_version;
	OUTPUT:
	RETVAL

int
gimp_minor_version()
	CODE:
	RETVAL = gimp_minor_version;
	OUTPUT:
	RETVAL

int
gimp_micro_version()
	CODE:
	RETVAL = gimp_micro_version;
	OUTPUT:
	RETVAL

void
gimp_enums_get_type_names()
INIT:
  gimp_enums_init ();
  gint n_type_names;
  const gchar **etn;
  int i;
PPCODE:
  etn = gimp_enums_get_type_names (&n_type_names);
  if (!etn) XSRETURN_EMPTY;
  EXTEND(SP, n_type_names);
  for (i = 0; i < n_type_names; i++) {
    PUSHs(sv_2mortal(newSVpv(etn[i], 0)));
  }

# return list of pair => value, ...
void
gimp_enums_list_type(name)
  const char *name
INIT:
  GType enum_type;
  GEnumClass *enum_class;
  GEnumValue *value;
PPCODE:
  if (!(enum_type = g_type_from_name (name)))
    croak (__("gimp_enums_list_type(%s) invalid name"), name);
  if (!(enum_class = g_type_class_peek (enum_type)))
    croak (__("gimp_enums_list_type(%s) invalid class"), name);
  for (value = enum_class->values; value->value_name; value++) {
    XPUSHs(sv_2mortal(newSVpv(value->value_name,0)));
    XPUSHs(sv_2mortal(newSViv(value->value)));
  }

# checks whether a gimp procedure exists
int
gimp_procedural_db_proc_exists(char *proc_name)
CODE:
  if (!gimp_is_initialized)
    croak (__("gimp_procedural_db_proc_exists(%s) called without an active connection"), proc_name);
  RETVAL = gimp_procedural_db_proc_exists(proc_name);
OUTPUT:
RETVAL

# get gimp procedure info
void
gimp_procedural_db_proc_info(proc_name)
char * proc_name
PPCODE:
{
  char *proc_blurb;
  char *proc_help;
  char *proc_author;
  char *proc_copyright;
  char *proc_date;
  GimpPDBProcType proc_type;
  int nparams;
  int nreturn_vals;
  GimpParamDef *params;
  GimpParamDef *return_vals;

  if (!gimp_is_initialized)
    croak("gimp_procedural_db_proc_info called without an active connection");

  if (
    gimp_procedural_db_proc_info(
      proc_name, &proc_blurb, &proc_help, &proc_author,
      &proc_copyright, &proc_date, &proc_type, &nparams, &nreturn_vals,
      &params, &return_vals
    ) != TRUE
  )
    XSRETURN_EMPTY;
  EXTEND(SP,8);
  PUSHs(newSVpv(proc_blurb,0));		g_free(proc_blurb);
  PUSHs(newSVpv(proc_help,0));		g_free(proc_help);
  PUSHs(newSVpv(proc_author,0));	g_free(proc_author);
  PUSHs(newSVpv(proc_copyright,0));	g_free(proc_copyright);
  PUSHs(newSVpv(proc_date,0));		g_free(proc_date);
  PUSHs(newSViv(proc_type));
  PUSHs(newSV_paramdefs(params, nparams));
    gimp_destroy_paramdefs(params, nparams);
  PUSHs(newSV_paramdefs(return_vals, nreturn_vals));
    gimp_destroy_paramdefs(return_vals, nreturn_vals);
}

void
gimp_procedural_db_query(name, blurb, help, author, copyright, date, proc_type)
  const char *name
  const char *blurb
  const char *help
  const char *author
  const char *copyright
  const char *date
  const char *proc_type
INIT:
  gint num_matches;
  gchar **procedure_names;
  int i;
PPCODE:
  if (!gimp_procedural_db_query (
    name, blurb, help, author, copyright, date, proc_type, &num_matches,
    &procedure_names
  )) croak (__("gimp_procedural_db_proc_query failed"));
  if (!num_matches) XSRETURN_EMPTY;
  EXTEND (SP, num_matches);
  for (i = 0; i < num_matches; i++) {
    PUSHs (sv_2mortal(newSVpv(procedure_names[i], 0)));
  }

void
gimp_call_procedure (proc_name, ...)
  utf8_str	proc_name
PPCODE:
{
  char croak_str[MAX_STRING] = "";
  char *proc_blurb;
  char *proc_help;
  char *proc_author;
  char *proc_copyright;
  char *proc_date;
  GimpPDBProcType proc_type;
  int nparams;
  int nreturn_vals;
  GimpParam *args = 0;
  GimpParam *values = 0;
  int nvalues;
  GimpParamDef *params;
  GimpParamDef *return_vals;
  int i=0, j=0;

  if (!gimp_is_initialized)
    croak (__("gimp_call_procedure(%s,...) called without an active connection"), proc_name);
  // do this here as at BOOT causes error
  gimp_plugin_set_pdb_error_handler (GIMP_PDB_ERROR_HANDLER_PLUGIN);

  verbose_printf (1, "%s", proc_name);

  if (
    gimp_procedural_db_proc_info(
      proc_name, &proc_blurb, &proc_help, &proc_author,
      &proc_copyright, &proc_date, &proc_type, &nparams, &nreturn_vals,
      &params, &return_vals
    ) != TRUE
  )
    croak (__("gimp procedure '%s' not found"), proc_name);

  try_call ("-proc");

  int runmode_firstparam = nparams
		&& params[0].type == GIMP_PDB_INT32
		&& (!strcmp (params[0].name, "run_mode") || !strcmp (params[0].name, "run-mode"));
  g_free (proc_blurb);
  g_free (proc_help);
  g_free (proc_author);
  g_free (proc_copyright);
  g_free (proc_date);

  if (nparams)
    args = (GimpParam *) g_new0 (GimpParam, nparams);

  if (runmode_firstparam) {
    /* If it's a valid value for the run mode, and # of parameters
       are consistent with this, we assume the user explicitly passed the run
       mode parameter */
    args[0].type = params[0].type;
    if (
      nparams==(items-1) && (
	SvIV(ST(1))==GIMP_RUN_INTERACTIVE ||
	SvIV(ST(1))==GIMP_RUN_NONINTERACTIVE ||
	SvIV(ST(1))==GIMP_RUN_WITH_LAST_VALS
      )
    ) {
      args->data.d_int32 = SvIV(ST(1)); // ST(0) = proc_name
      j = 2; // because ST(0) is proc_name, ST(1) is runmode
    } else {
      args->data.d_int32 = GIMP_RUN_NONINTERACTIVE;
      j = 1; // because ST(0) is proc_name
    }
    i = 1; // first proc input param to put stack entries into
  } else {
    i = 0; // first proc input param to put stack entries into
    j = 1; // because ST(0) is proc_name
  }

  for (; i < nparams && j < items; i++) {
    args[i].type = params[i].type;
    if (
      (!SvROK(ST(j)) || i >= nparams-1 || !is_array (params[i+1].type))
    ) {
      convert_sv2gimp(croak_str, &args[i], ST(j)) && j++;
    }

    if (croak_str [0]) {
      dump_params (i, args, params);
      verbose_printf (1, __(" = [argument error]\n"));
      goto error;
    }
  }

  dump_params (i, args, params);
  verbose_printf (1, " = ");

  if (i < nparams || j < items) {
    verbose_printf (1, __("[unfinished]\n"));

    sprintf(
      croak_str,
      __("%s arguments for function '%s', wanted %d, got %d"),
      i < nparams ? __("not enough") : __("too many"),
      proc_name,
      nparams,
      items - 1 /* -1 because 0th is proc_name */
    );

    if (nparams)
      destroy_params (args, nparams);
    goto error;
  }

  values = gimp_run_procedure2 (proc_name, &nvalues, nparams, args);

  if (nparams)
    destroy_params (args, nparams);

  if (values && values[0].type != GIMP_PDB_STATUS) {
    sprintf (croak_str, __("gimp didn't return an execution status, fatal error"));
    goto error;
  }
  if (
    values[0].data.d_status == GIMP_PDB_EXECUTION_ERROR ||
    values[0].data.d_status == GIMP_PDB_CALLING_ERROR
  ) {
    if (nvalues > 1 && values[1].type == GIMP_PDB_STRING) {
      // values[1] ought to be the error string
      sprintf (croak_str, "%s", values[1].data.d_string);
    } else
      // just try gimp_get_pdb_error()
      sprintf (croak_str, "%s: %s", proc_name, gimp_get_pdb_error ());
    verbose_printf (1, "(");
    verbose_printf (2, "\n\t");
    verbose_printf (1, __("EXCEPTION: \"%s\""), croak_str);
    verbose_printf (2, "\n\t");
    verbose_printf (1, ")\n");
    goto error;
  }
  if (values[0].data.d_status != GIMP_PDB_SUCCESS) {
    sprintf (croak_str, __("unsupported status code: %d, fatal error\n"), values[0].data.d_status);
    goto error;
  }

  dump_params (nvalues-1, values+1, return_vals);
  verbose_printf (1, "\n");

  EXTEND(SP, perl_paramdef_count (return_vals, nvalues-1));
  PUTBACK;
  for (i = 0; i < nvalues-1; i++) {
    if (i < nvalues-2 && is_array (values[i+2].type))
      i++;
    push_gimp_sv (values+i+1, nvalues > 2+1);
  }
  SPAGAIN;

  error:

  if (values)
    gimp_destroy_params (values, nreturn_vals);

  gimp_destroy_paramdefs (params, nparams);
  gimp_destroy_paramdefs (return_vals, nreturn_vals);

  if (croak_str[0])
    croak (croak_str);
}

void
gimp_install_procedure(name, blurb, help, author, copyright, date, menu_path, image_types, type, params, return_vals)
  utf8_str	name
  utf8_str	blurb
  utf8_str	help
  utf8_str	author
  utf8_str	copyright
  utf8_str	date
  SV *		menu_path
  SV *		image_types
  int		type
  SV *		params
  SV *		return_vals
ALIAS:
  gimp_install_temp_proc = 1
CODE:
  if (
    !(
      SvROK(params) &&
      SvTYPE(SvRV(params)) == SVt_PVAV &&
      SvROK(return_vals) &&
      SvTYPE(SvRV(return_vals)) == SVt_PVAV
    )
  )
    croak (__("params and return_vals must be array refs (even if empty)!"));

  GimpParamDef *apd; int nparams;
  GimpParamDef *rpd; int nreturn_vals;
  nparams      = convert_array2paramdef ((AV *)SvRV(params)     , &apd);
  nreturn_vals = convert_array2paramdef ((AV *)SvRV(return_vals), &rpd);
  /* 3 cases: no path, no slash, yes slash */
  char *menu_location = SvPv(menu_path) ? g_strdup(SvPv(menu_path)) : NULL;
  char *slash_ptr = menu_location ? g_strrstr(menu_location, "/") : NULL;
  char *menu_name;
  if (slash_ptr) {
    *slash_ptr++ = '\0';
    menu_name = slash_ptr;
  } else {
    menu_name = menu_location;
  }
  if (ix)
    gimp_install_temp_proc(
      name,
      blurb,
      help,
      author,
      copyright,
      date,
      menu_name,
      SvPv(image_types),
      type,
      nparams,
      nreturn_vals,
      apd,
      rpd,
      pii_run
    );
  else {
    gimp_plugin_domain_register ("gimp-perl", datadir "/locale");
    gimp_install_procedure(
      name,
      blurb,
      help,
      author,
      copyright,
      date,
      menu_name,
      SvPv(image_types),
      type,
      nparams,
      nreturn_vals,
      apd,
      rpd
    );
  }
  g_free (rpd);
  g_free (apd);
  if (slash_ptr) gimp_plugin_menu_register(name, menu_location);
  if (menu_location) g_free(menu_location);

void
gimp_uninstall_temp_proc(name)
	utf8_str	name

void
gimp_lib_quit()
	CODE:
	gimp_quit ();

void
gimp_extension_process(timeout)
  guint timeout

void
gimp_extension_enable()

void
gimp_extension_ack()

void
gimp_set_data(id, data)
	SV *	id
	SV *	data;
	CODE:
	{
		STRLEN dlen;
		void *dta = SvPV (data, dlen);
		gimp_set_data (SvPV_nolen (id), dta, dlen);
	}

void
gimp_get_data(id)
	SV *	id;
	PPCODE:
	{
		SV *data;
		STRLEN dlen;

		dlen = gimp_get_data_size (SvPV_nolen (id));
		/* I count on dlen being zero if "id" doesn't exist.  */
		data = newSVpv ("", 0);
		gimp_get_data (SvPV_nolen (id), SvGROW (data, dlen+1));
		SvCUR_set (data, dlen);
		*((char *)SvPV_nolen (data) + dlen) = 0;
		XPUSHs (sv_2mortal (data));
	}

gdouble
gimp_gamma()

gint
gimp_install_cmap()

const char *
gimp_gtkrc()

const char *
gimp_directory()

const char *
gimp_get_pdb_error()

const char *
gimp_data_directory()

SV *
gimp_personal_rc_file(basename)
	char *	basename
	CODE:
	basename = gimp_personal_rc_file (basename);
	RETVAL = sv_2mortal (newSVpv (basename, 0));
	g_free (basename);
	OUTPUT:
	RETVAL

guint
gimp_tile_width()

guint
gimp_tile_height()

void
gimp_tile_cache_size(kilobytes)
	gulong	kilobytes

void
gimp_tile_cache_ntiles(ntiles)
	gulong	ntiles

SV *
gimp_drawable_get(drawable_ID)
	DRAWABLE	drawable_ID
	CODE:
	RETVAL = new_gdrawable (drawable_ID);
	OUTPUT:
	RETVAL

void
gimp_gdrawable_flush(gdrawable)
	GimpDrawable *	gdrawable
	CODE:
	gimp_drawable_flush(gdrawable);

SV *
gimp_pixel_rgn_init(gdrawable, x, y, width, height, dirty, shadow)
	SV *	gdrawable
	int	x
	int	y
	int	width
	int	height
	int	dirty
	int	shadow
	CODE:
	RETVAL = new_gpixelrgn (force_gdrawable (gdrawable),x,y,width,height,dirty,shadow);
	OUTPUT:
	RETVAL

void
gimp_pixel_rgn_resize(pr, x, y, width, height)
	GimpPixelRgn *	pr
	int	x
	int	y
	int	width
	int	height
	CODE:
	gimp_pixel_rgn_resize (pr, x, y, width, height);

GimpPixelRgnIterator
gimp_pixel_rgns_register(...)
	CODE:
	if (items == 1)
	  RETVAL = gimp_pixel_rgns_register (1, old_pixelrgn (ST (0)));
	else if (items == 2)
	  RETVAL = gimp_pixel_rgns_register (2, old_pixelrgn (ST (0)), old_pixelrgn (ST (1)));
	else if (items == 3)
	  RETVAL = gimp_pixel_rgns_register (3, old_pixelrgn (ST (0)), old_pixelrgn (ST (1)), old_pixelrgn (ST (2)));
	else
	  croak (__("gimp_pixel_rgns_register supports only 1, 2 or 3 arguments, upgrade to gimp-1.1 and report this error"));
	OUTPUT:
	RETVAL

SV *
gimp_pixel_rgns_process(pri_ptr)
	GimpPixelRgnIterator	pri_ptr
	CODE:
	RETVAL = boolSV (gimp_pixel_rgns_process (pri_ptr));
	OUTPUT:
	RETVAL

# struct accessor functions

guint
gimp_gdrawable_width(gdrawable)
	GimpDrawable *gdrawable
	CODE:
	RETVAL = gdrawable->width;
	OUTPUT:
	RETVAL

guint
gimp_gdrawable_height(gdrawable)
	GimpDrawable *gdrawable
	CODE:
	RETVAL = gdrawable->height;
	OUTPUT:
	RETVAL

guint
gimp_gdrawable_ntile_rows(gdrawable)
	GimpDrawable *gdrawable
	CODE:
	RETVAL = gdrawable->ntile_rows;
	OUTPUT:
	RETVAL

guint
gimp_gdrawable_ntile_cols(gdrawable)
	GimpDrawable *gdrawable
	CODE:
	RETVAL = gdrawable->ntile_cols;
	OUTPUT:
	RETVAL

guint
gimp_gdrawable_bpp(gdrawable)
	GimpDrawable *gdrawable
	CODE:
	RETVAL = gdrawable->bpp;
	OUTPUT:
	RETVAL

gint32
gimp_gdrawable_id(gdrawable)
	GimpDrawable *gdrawable
	CODE:
	RETVAL = gdrawable->drawable_id;
	OUTPUT:
	RETVAL

guint
gimp_pixel_rgn_x(pr)
	GimpPixelRgn *pr
	CODE:
	RETVAL = pr->x;
	OUTPUT:
	RETVAL

guint
gimp_pixel_rgn_y(pr)
	GimpPixelRgn *pr
	CODE:
	RETVAL = pr->y;
	OUTPUT:
	RETVAL

guint
gimp_pixel_rgn_w(pr)
	GimpPixelRgn *pr
	CODE:
	RETVAL = pr->w;
	OUTPUT:
	RETVAL

guint
gimp_pixel_rgn_h(pr)
	GimpPixelRgn *pr
	CODE:
	RETVAL = pr->h;
	OUTPUT:
	RETVAL

guint
gimp_pixel_rgn_rowstride(pr)
	GimpPixelRgn *pr
	CODE:
	RETVAL = pr->rowstride;
	OUTPUT:
	RETVAL

guint
gimp_pixel_rgn_bpp(pr)
	GimpPixelRgn *pr
	CODE:
	RETVAL = pr->bpp;
	OUTPUT:
	RETVAL

guint
gimp_pixel_rgn_shadow(pr)
	GimpPixelRgn *pr
	CODE:
	RETVAL = pr->shadow;
	OUTPUT:
	RETVAL

gint32
gimp_pixel_rgn_drawable(pr)
	GimpPixelRgn *pr
	CODE:
	RETVAL = pr->drawable->drawable_id;
	OUTPUT:
	RETVAL

guint
gimp_tile_ewidth(tile)
	GimpTile *tile
	CODE:
	RETVAL = tile->ewidth;
	OUTPUT:
	RETVAL

guint
gimp_tile_eheight(tile)
	GimpTile *tile
	CODE:
	RETVAL = tile->eheight;
	OUTPUT:
	RETVAL

guint
gimp_tile_bpp(tile)
	GimpTile *tile
	CODE:
	RETVAL = tile->bpp;
	OUTPUT:
	RETVAL

guint
gimp_tile_shadow(tile)
	GimpTile *tile
	CODE:
	RETVAL = tile->shadow;
	OUTPUT:
	RETVAL

guint
gimp_tile_dirty(tile)
	GimpTile *tile
	CODE:
	RETVAL = tile->dirty;
	OUTPUT:
	RETVAL

DRAWABLE
gimp_tile_drawable(tile)
	GimpTile *tile
	CODE:
	RETVAL = tile->drawable->drawable_id;
	OUTPUT:
	RETVAL

SV *
gimp_pixel_rgn_get_row2(pr, x, y, width)
	GimpPixelRgn *	pr
	int	x
	int	y
	int	width
	CODE:
	RETVAL = newSVn (width * pr->bpp);
	gimp_pixel_rgn_get_row (pr, (guchar *)SvPV_nolen(RETVAL), x, y, width);
	OUTPUT:
	RETVAL

SV *
gimp_pixel_rgn_get_col2(pr, x, y, height)
	GimpPixelRgn *	pr
	int	x
	int	y
	int	height
	CODE:
	RETVAL = newSVn (height * pr->bpp);
	gimp_pixel_rgn_get_col (pr, (guchar *)SvPV_nolen(RETVAL), x, y, height);
	OUTPUT:
	RETVAL

SV *
gimp_pixel_rgn_get_rect2(pr, x, y, width, height)
	GimpPixelRgn *	pr
	int	x
	int	y
	int	width
	int	height
	CODE:
	RETVAL = newSVn (width * height * pr->bpp);
	gimp_pixel_rgn_get_rect (pr, (guchar *)SvPV_nolen(RETVAL), x, y, width, height);
	OUTPUT:
	RETVAL

void
gimp_pixel_rgn_set_rect2(pr, data, x, y, w=pr->w)
	GimpPixelRgn *	pr
	SV *	data
	int	x
	int	y
	int	w
	CODE:
{
	STRLEN dlen; guchar *dta = (guchar *)SvPV (data, dlen);
	gimp_pixel_rgn_set_rect (pr, dta, x, y, w, dlen / (w*pr->bpp));
}

SV *
gimp_gdrawable_get_tile(gdrawable, shadow, row, col)
	SV *	gdrawable
	gint	shadow
	gint	row
	gint	col
	CODE:
	RETVAL = new_tile (gimp_drawable_get_tile (old_gdrawable (gdrawable), shadow, row, col), gdrawable);
	OUTPUT:
	RETVAL

SV *
gimp_gdrawable_get_tile2(gdrawable, shadow, x, y)
	SV *	gdrawable
	gint	shadow
	gint	x
	gint	y
	CODE:
	RETVAL = new_tile (gimp_drawable_get_tile2 (old_gdrawable (gdrawable), shadow, x, y), gdrawable);
	OUTPUT:
	RETVAL

pdl *
gimp_pixel_rgn_get_pixel(pr, x, y)
	GimpPixelRgn_PDL *	pr
	int	x
	int	y
	CODE:
	RETVAL = new_pdl (0, 0, pr->bpp);
	gimp_pixel_rgn_get_pixel (pr, RETVAL->data, x, y);
	OUTPUT:
	RETVAL

pdl *
gimp_pixel_rgn_get_row(pr, x, y, width)
	GimpPixelRgn_PDL *	pr
	int	x
	int	y
	int	width
	CODE:
	RETVAL = new_pdl (0, width, pr->bpp);
	gimp_pixel_rgn_get_row (pr, RETVAL->data, x, y, width);
	OUTPUT:
	RETVAL

pdl *
gimp_pixel_rgn_get_col(pr, x, y, height)
	GimpPixelRgn_PDL *	pr
	int	x
	int	y
	int	height
	CODE:
	RETVAL = new_pdl (height, 0, pr->bpp);
	gimp_pixel_rgn_get_col (pr, RETVAL->data, x, y, height);
	OUTPUT:
	RETVAL

pdl *
gimp_pixel_rgn_get_rect(pr, x, y, width, height)
	GimpPixelRgn_PDL *	pr
	int	x
	int	y
	int	width
	int	height
	CODE:
	RETVAL = new_pdl (height, width, pr->bpp);
	gimp_pixel_rgn_get_rect (pr, RETVAL->data, x, y, width, height);
	OUTPUT:
	RETVAL

void
gimp_pixel_rgn_set_pixel(pr, pdl, x, y)
	GimpPixelRgn_PDL *	pr
	pdl *	pdl
	int	x
	int	y
	CODE:
	old_pdl (&pdl, 0, pr->bpp);
	gimp_pixel_rgn_set_pixel (pr, pdl->data, x, y);

void
gimp_pixel_rgn_set_row(pr, pdl, x, y)
	GimpPixelRgn_PDL *	pr
	pdl *	pdl
	int	x
	int	y
	CODE:
	old_pdl (&pdl, 1, pr->bpp);
	gimp_pixel_rgn_set_row (pr, pdl->data, x, y, pdl->dims[pdl->ndims-1]);

void
gimp_pixel_rgn_set_col(pr, pdl, x, y)
	GimpPixelRgn_PDL *	pr
	pdl *	pdl
	int	x
	int	y
	CODE:
	old_pdl (&pdl, 1, pr->bpp);
	gimp_pixel_rgn_set_col (pr, pdl->data, x, y, pdl->dims[pdl->ndims-1]);

void
gimp_pixel_rgn_set_rect(pr, pdl, x, y)
	GimpPixelRgn_PDL *	pr
	pdl *	pdl
	int	x
	int	y
	CODE:
	old_pdl (&pdl, 2, pr->bpp);
	gimp_pixel_rgn_set_rect (pr, pdl->data, x, y, pdl->dims[pdl->ndims-2], pdl->dims[pdl->ndims-1]);

pdl *
gimp_pixel_rgn_data(pr,newdata=0)
	GimpPixelRgn_PDL *	pr
	pdl * newdata
	CODE:
	verbose_printf (2, "gimp_pixel_rgn_data(%lx, %lx)\n", (long)pr, (long)newdata);
	if (!pr->rowstride)
	  croak("gimp_pixel_rgn_data called, rowstride == 0; only call within an iterator!");
	if (newdata)
	  {
	    guchar *src;
	    guchar *dst;
	    int y, stride;

	    old_pdl (&newdata, 2, pr->bpp);
	    stride = pr->bpp * newdata->dims[newdata->ndims-2];

	    if ((int)pr->h != newdata->dims[newdata->ndims-1])
	      croak (__("pdl height != region height"));

	    for (y   = 0, src = newdata->data, dst = pr->data;
		 y < (int)pr->h;
		 y++    , src += stride      , dst += pr->rowstride)
	      Copy (src, dst, stride, char);

	    RETVAL = newdata;
	  }
	else
	  {
	    pdl *p = PDL->pdlnew();
	    PDL_Indx dims[3];

	    dims[0] = pr->bpp;
	    dims[1] = pr->rowstride / pr->bpp;
	    dims[2] = pr->h;

	    PDL->setdims (p, dims, 3);
	    p->datatype = PDL_B;
	    p->data = pr->data;
	    p->state |= PDL_DONTTOUCHDATA | PDL_ALLOCATED;
	    PDL->add_deletedata_magic(p, pixel_rgn_pdl_delete_data, 0);

	    if ((int)pr->w != dims[1])
	      p = redim_pdl (p, 1, pr->w);

	    RETVAL = p;
	  }
	OUTPUT:
	RETVAL

# ??? optimize these two functions so tile_*ref will only be called once on
# construction/destruction.

SV *
gimp_tile_get_data(tile)
	GimpTile *	tile
	CODE:
	need_pdl ();
	croak (__("gimp_tile_get_data is not yet implemented\n"));
	gimp_tile_ref (tile);
	gimp_tile_unref (tile, 0);
	OUTPUT:
	RETVAL

void
gimp_tile_set_data(tile,data)
	GimpTile *	tile
	SV *	data
	CODE:
	data = data; // to suppress "unused var" warning
	croak (__("gimp_tile_set_data is not yet implemented\n")); /*(void *)data;*/
	gimp_tile_ref_zero (tile);
	gimp_tile_unref (tile, 1);

BOOT:
#if (GLIB_MAJOR_VERSION < 2 || (GLIB_MAJOR_VERSION == 2 && GLIB_MINOR_VERSION < 36))
	g_type_init();
#endif
	g_log_set_handler(
	  "LibGimp",
	  G_LOG_LEVEL_CRITICAL | G_LOG_LEVEL_ERROR | G_LOG_FLAG_FATAL,
	  throw_exception,
	  NULL
	);

#
# this function overrides a pdb function for speed
#

void
gimp_patterns_get_pattern_data(name)
	SV *	name
	PPCODE:
	{
		GimpParam *return_vals;
		int nreturn_vals;

		return_vals = gimp_run_procedure ("gimp_patterns_get_pattern_data",
						  &nreturn_vals,
						  GIMP_PDB_STRING, SvPV_nolen (name),
						  GIMP_PDB_END);

		if (nreturn_vals == 7
		    && return_vals[0].data.d_status == GIMP_PDB_SUCCESS)
		  {
		    EXTEND (SP, 5);

		    PUSHs (sv_2mortal (newSVpv (        return_vals[1].data.d_string, 0)));
		    PUSHs (sv_2mortal (newSViv (        return_vals[2].data.d_int32)));
		    PUSHs (sv_2mortal (newSViv (        return_vals[3].data.d_int32)));
		    PUSHs (sv_2mortal (newSViv (        return_vals[4].data.d_int32)));
		    PUSHs (sv_2mortal (newSVpvn((char *)return_vals[6].data.d_int8array, return_vals[5].data.d_int32)));
		  }

		gimp_destroy_params (return_vals, nreturn_vals);
	}

void
_gimp_progress_init (message)
	utf8_str	message
	CODE:
	gimp_progress_init (message);

DISPLAY
gimp_default_display()

const char *
gimp_display_name()

# functions using different calling conventions:
#void
#gimp_channel_get_color(channel_ID, red, green, blue)
#	CHANNEL	channel_ID
#	guchar *	red
#	guchar *	green
#	guchar *	blue
#gint32 *
#gimp_image_get_channels(image_ID, nchannels)
#	IMAGE	image_ID
#	gint *	nchannels
#guchar *
#gimp_image_get_cmap(image_ID, ncolors)
#	IMAGE	image_ID
#	gint *	ncolors
#gint32 *
#gimp_image_get_layers(image_ID, nlayers)
#	IMAGE	image_ID
#	gint *	nlayers
#gint32
#gimp_layer_new(image_ID, name, width, height, type, opacity, mode)
#	gint32	image_ID
#	char *	name
#	guint	width
#	guint	height
#	GimpImageType	type
#	gdouble	opacity
#	GimpLayerModeEffects	mode
#gint32
#gimp_layer_copy(layer_ID)
#	gint32	layer_ID
#void
#gimp_channel_set_color(channel_ID, red, green, blue)
#	gint32	channel_ID
#	guchar	red
#	guchar	green
#	guchar	blue
#gint
#gimp_drawable_mask_bounds(drawable_ID, x1, y1, x2, y2)
#	DRAWABLE	drawable_ID
#	gint *	x1
#	gint *	y1
#	gint *	x2
#	gint *	y2
#void
#gimp_drawable_offsets(drawable_ID, offset_x, offset_y)
#	DRAWABLE	drawable_ID
#	gint *	offset_x
#	gint *	offset_y

# ??? almost synonymous to gimp_list_images

#gint32 *
#gimp_image_list(nimages)
#	int *	nimages

