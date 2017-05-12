#include "gtkimageviewperl.h"

GType
gdk_pixbuf_draw_opts_get_type(void) {
    static GType t = 0;
    if (!t) {
        t = g_boxed_type_register_static("GdkPixbufDrawOpts",
                                         (GBoxedCopyFunc) g_boxed_copy,
                                         (GBoxedFreeFunc) g_boxed_free);
    }
    return t;
}

/*
struct _GdkPixbufDrawOpts {
    gdouble        zoom;
    GdkRectangle   zoom_rect;
    int            widget_x;
    int            widget_y;       
    GdkInterpType  interp;
    GdkPixbuf     *pixbuf;
    int            check_color1;
    int            check_color2;
};
*/

SV *
newSVGdkPixbufDrawOpts (GdkPixbufDrawOpts * opts)
{
  HV * hv = newHV();
  hv_store (hv, "zoom", 4, newSVnv (opts->zoom), 0);
  hv_store (hv, "zoom_rect", 9, newSVGdkRectangle (&opts->zoom_rect), 0);
  hv_store (hv, "widget_x", 8, newSViv (opts->widget_x), 0);
  hv_store (hv, "widget_y", 8, newSViv (opts->widget_y), 0);
  hv_store (hv, "interp", 6, newSVGdkInterpType (opts->interp), 0);
  hv_store (hv, "pixbuf", 6, newSVGdkPixbuf (opts->pixbuf), 0);
  hv_store (hv, "check_color1", 12, newSViv (opts->check_color1), 0);
  hv_store (hv, "check_color2", 12, newSViv (opts->check_color2), 0);
  return newRV_noinc ((SV *) hv);
}

/*
 * returns a pointer to a GdkPixbufDrawOpts you can use until control returns
 * to perl.
 */
GdkPixbufDrawOpts *
SvGdkPixbufDrawOpts (SV * sv)
{
  HV * hv;
  SV ** svp;
  GdkPixbufDrawOpts * opts;

/* Make sure it is what we think it is before we try to
   dereference and parse it */
  if (! gperl_sv_is_hash_ref (sv))
          croak ("Expected a hash reference for Gtk2::Gdk::Pixbuf::Draw::Opts");

  hv = (HV*) SvRV (sv);

  opts = gperl_alloc_temp (sizeof (GdkPixbufDrawOpts));

  svp = hv_fetch (hv, "zoom", 4, FALSE);
  if (svp) opts->zoom = SvNV (*svp);

  svp = hv_fetch (hv, "zoom_rect", 9, FALSE);
  if (svp) opts->zoom_rect = * (GdkRectangle *) SvGdkRectangle (*svp);

  svp = hv_fetch (hv, "widget_x", 8, FALSE);
  if (svp) opts->widget_x = SvIV (*svp);

  svp = hv_fetch (hv, "widget_y", 8, FALSE);
  if (svp) opts->widget_y = SvIV (*svp);

  svp = hv_fetch (hv, "interp", 6, FALSE);
  if (svp) opts->interp = SvGdkInterpType (*svp);

  svp = hv_fetch (hv, "pixbuf", 6, FALSE);
  if (svp) opts->pixbuf = (GdkPixbuf *) SvGdkPixbuf (*svp);

  svp = hv_fetch (hv, "check_color1", 12, FALSE);
  if (svp) opts->check_color1 = SvIV (*svp);

  svp = hv_fetch (hv, "check_color2", 12, FALSE);
  if (svp) opts->check_color2 = SvIV (*svp);

  return opts;
}

GType
gdk_pixbuf_draw_cache_get_type(void) {
    static GType t = 0;
    if (!t) {
        t = g_boxed_type_register_static("GdkPixbufDrawCache",
                                         (GBoxedCopyFunc) g_boxed_copy,
                                         (GBoxedFreeFunc) g_boxed_free);
    }
    return t;
}

/*
struct _GdkPixbufDrawCache
{
    GdkPixbuf         *last_pixbuf;
    GdkPixbufDrawOpts  old;
    int                check_size;
};
*/

static SV *
newSVGdkPixbufDrawCache (GdkPixbufDrawCache * cache)
{
  HV * hv = newHV();
  hv_store (hv, "last_pixbuf", 11, newSVGdkPixbuf (cache->last_pixbuf), 0);
  hv_store (hv, "old", 3, newSVGdkPixbufDrawOpts (&cache->old), 0);
  hv_store (hv, "check_size", 10, newSViv (cache->check_size), 0);
  return newRV_noinc ((SV *) hv);
}

/*
 * returns a pointer to a GdkPixbufDrawCache you can use until control returns
 * to perl.
 */
static GdkPixbufDrawCache *
SvGdkPixbufDrawCache (SV * sv)
{
  HV * hv;
  SV ** svp;
  GdkPixbufDrawCache * cache;

/* Make sure it is what we think it is before we try to
   dereference and parse it */
  if (! gperl_sv_is_hash_ref (sv))
          croak ("Expected a hash reference for Gtk2::Gdk::Pixbuf::Draw::Cache");

  hv = (HV*) SvRV (sv);

  cache = gperl_alloc_temp (sizeof (GdkPixbufDrawCache));

  svp = hv_fetch (hv, "last_pixbuf", 11, FALSE);
  if (svp) cache->last_pixbuf = (GdkPixbuf *) SvGdkPixbuf (*svp);

  svp = hv_fetch (hv, "old", 3, FALSE);
  if (svp) cache->old = * (GdkPixbufDrawOpts *) SvGdkPixbufDrawOpts (*svp);

  svp = hv_fetch (hv, "check_size", 10, FALSE);
  if (svp) cache->check_size = SvIV (*svp);

  return cache;
}



MODULE = Gtk2::Gdk::Pixbuf::Draw::Cache  PACKAGE = Gtk2::Gdk::Pixbuf::Draw::Cache  PREFIX = gdk_pixbuf_draw_cache_

=for object Gtk2::Gdk::Pixbuf::Draw::Cache Cache for drawing scaled pixbufs
=cut

=for position DESCRIPTION

=head1 DESCRIPTION

Gtk2::Gdk::Pixbuf::Draw::Cache provides a cache that should be used by the
Gtk2::ImageView::Tool when redrawing the Gtk2::ImageView.

=cut

=for apidoc
Returns a new pixbuf draw cache.
=cut
GdkPixbufDrawCache *
gdk_pixbuf_draw_cache_new (class)
	C_ARGS:
		/*void*/


=for apidoc
Deallocates a pixbuf draw cache and all its data.

=cut
void
gdk_pixbuf_draw_cache_free (cache)
	GdkPixbufDrawCache *	cache


=for apidoc
Force the pixbuf draw cache to scale the pixbuf at the next draw.

Gtk2::Gdk::Pixbuf::Draw::Cache tries to minimize the number of scale operations
needed by caching the last drawn pixbuf. It would be inefficient to check the
individual pixels inside the pixbuf so it assumes that if the memory address of
the pixbuf has not changed, then the cache is good to use.

However, when the image data is modified, this assumtion breaks, which is why
this method must be used to tell draw cache about it.

=cut
void
gdk_pixbuf_draw_cache_invalidate (cache)
	GdkPixbufDrawCache *	cache


=for apidoc
Redraws the area specified in the pixbuf draw options in an efficient way by
using caching.

=over

=item cache : a GdkPixbufDrawCache

=item opts : the Gtk2::Gdk::Pixbuf::Draw::Opts to use in this draw

=item drawable : a GdkDrawable to draw on

=back

=cut
void
gdk_pixbuf_draw_cache_draw (cache, opts, drawable)
	GdkPixbufDrawCache *	cache
	GdkPixbufDrawOpts *	opts
	GdkDrawable *		drawable


=for apidoc
Gets the fastest method to draw the specified draw options. old is assumed to be
the last PixbufDrawOpts used and new is the one to use this time.
=cut
GdkPixbufDrawMethod
gdk_pixbuf_draw_cache_get_method (class, old, new)
		GdkPixbufDrawOpts *	old
		GdkPixbufDrawOpts *	new
	C_ARGS:
		old, new
