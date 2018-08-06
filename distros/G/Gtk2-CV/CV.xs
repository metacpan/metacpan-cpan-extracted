#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <string.h>
#include <setjmp.h>
#include <math.h>

#include <magic.h>

#include <jpeglib.h>
#include <jerror.h>

#include <glib.h>
#include <gtk/gtk.h>
#include <gdk/gdkx.h>
#include <gdk-pixbuf/gdk-pixbuf.h>

#include <gperl.h>
#include <gtk2perl.h>

#include <assert.h>

#if WEBP
#include <webp/demux.h>
#include <webp/decode.h>
#endif

#include "perlmulticore.h"

#define IW 80 /* MUST match Schnauzer.pm! */
#define IH 60 /* MUST match Schnauzer.pm! */

#define RAND (seed = (seed + 7141) * 54773 % 134456)

#define LINELENGTH 240

#define ELLIPSIS "\xe2\x80\xa6"

typedef char *octet_string;

static magic_t magic_cookie[2]; /* !mime, mime */

struct jpg_err_mgr
{
  struct jpeg_error_mgr err;
  jmp_buf setjmp_buffer;
};

static void
cv_error_exit (j_common_ptr cinfo)
{
  cinfo->err->output_message (cinfo);
  longjmp (((struct jpg_err_mgr *)cinfo->err)->setjmp_buffer, 99);
}

static void
cv_error_output (j_common_ptr cinfo)
{
  char msg[JMSG_LENGTH_MAX];

  cinfo->err->format_message (cinfo, msg);

  fprintf (stderr, "JPEG decoding error: %s\n", msg);
  return;
}

static void
rgb_to_hsv (unsigned int  r, unsigned int  g, unsigned int  b,
            unsigned int *h, unsigned int *s, unsigned int *v)
{
  unsigned int mx = r; if (g > mx) mx = g; if (b > mx) mx = b;
  unsigned int mn = r; if (g < mn) mn = g; if (b < mn) mn = b;
  unsigned int delta = mx - mn;

  *v = mx;

  *s = mx ? delta * 255 / mx : 0;

  if (delta == 0)
    *h = 0;
  else
    {
      if (r == mx)
        *h = ((int)g - (int)b) * 255 / (int)(delta * 3);
      else if (g == mx)
        *h = ((int)b - (int)r) * 255 / (int)(delta * 3) + 52;
      else if (b == mx)
        *h = ((int)r - (int)g) * 255 / (int)(delta * 3) + 103;

      *h &= 255;
    }
}

struct feature {
  float v1, v2, v3; // mean, square, cube
  int n;
};

static void
feature_init (struct feature *f)
{
  f->v1 = 0.;
  f->v2 = 0.;
  f->v3 = 0.;
  f->n  = 0;
}

// didn't find an algorithm to neatly do mean, variance and skew in one pass.
// elmex ist schuld.
static void
feature_update_pass_1 (struct feature *f, unsigned int v)
{
  f->v1 += v;
  f->n  += 1;
}

static void
feature_finish_pass_1 (struct feature *f)
{
  if (f->n < 1)
    return;

  f->v1 /= f->n;
}

static void
feature_update_pass_2 (struct feature *f, unsigned int v)
{
  float d = v - f->v1;

  f->v2 += d * d;
  f->v3 += d * d * d;
}

static void
feature_finish_pass_2 (struct feature *f)
{
  if (f->n < 1)
    return;

  f->v2 /= f->n;
  f->v3 /= f->n;

  f->v1 /= 255.;
  f->v2 /= 255. * 255.;        f->v2 = sqrtf (f->v2);
  f->v3 /= 255. * 255. * 255.; f->v3 = powf (fabsf (f->v3), 1./3.);
}

static guint32 a85_val;
static guint a85_cnt;
static guchar a85_buf[LINELENGTH], *a85_ptr;

static void
a85_init (void)
{
  a85_cnt = 4;
  a85_ptr = a85_buf;
}

static void
a85_push (PerlIO *fp, guchar c)
{
  a85_val = a85_val << 8 | c;

  if (!--a85_cnt)
    {
      a85_cnt = 4;
      if (a85_val)
        {
          a85_ptr[4] = (a85_val % 85) + 33; a85_val /= 85;
          a85_ptr[3] = (a85_val % 85) + 33; a85_val /= 85;
          a85_ptr[2] = (a85_val % 85) + 33; a85_val /= 85;
          a85_ptr[1] = (a85_val % 85) + 33; a85_val /= 85;
          a85_ptr[0] = (a85_val     ) + 33;

          a85_ptr += 5;
        }
      else
        *a85_ptr++ = 'z';

      if (a85_ptr >= a85_buf + sizeof (a85_buf) - 7)
        {
          *a85_ptr++ = '\n';
          PerlIO_write (fp, a85_buf, a85_ptr - a85_buf);
          a85_ptr = a85_buf;
        }
    }
    
}

static void
a85_finish (PerlIO *fp)
{
  while (a85_cnt != 4)
    a85_push (fp, 0);

  *a85_ptr++ = '~'; // probably buggy end-marker
  *a85_ptr++ = '>'; // probably buggy end-marker
  *a85_ptr++ = '\n';

  PerlIO_write (fp, a85_buf, a85_ptr - a85_buf);
}

/////////////////////////////////////////////////////////////////////////////
// memory source for libjpeg

static void cv_ms_init (j_decompress_ptr cinfo)
{
}

static void cv_ms_term (j_decompress_ptr cinfo)
{
}

static boolean cv_ms_fill (j_decompress_ptr cinfo)
{
  // unexpected EOF, warn and generate fake EOI marker

  WARNMS (cinfo, JWRN_JPEG_EOF);

  struct jpeg_source_mgr *src = (struct jpeg_source_mgr *)cinfo->src;

  static const JOCTET eoi[] = { 0xFF, JPEG_EOI };

  src->next_input_byte = eoi;
  src->bytes_in_buffer = sizeof (eoi);

  return TRUE;
}

static void cv_ms_skip (j_decompress_ptr cinfo, long num_bytes)
{
  struct jpeg_source_mgr *src = (struct jpeg_source_mgr *)cinfo->src;

  src->next_input_byte += num_bytes;
  src->bytes_in_buffer -= num_bytes;
}

static void cv_jpeg_mem_src (j_decompress_ptr cinfo, void *buf, size_t buflen)
{
  struct jpeg_source_mgr *src;

  if (!cinfo->src)
    cinfo->src = (struct jpeg_source_mgr *)
      (*cinfo->mem->alloc_small) (
        (j_common_ptr) cinfo, JPOOL_PERMANENT, sizeof (struct jpeg_source_mgr)
      );

  src = (struct jpeg_source_mgr *)cinfo->src;
  src->init_source       = cv_ms_init;
  src->fill_input_buffer = cv_ms_fill;
  src->skip_input_data   = cv_ms_skip;
  src->resync_to_restart = jpeg_resync_to_restart;
  src->term_source       = cv_ms_term;
  src->next_input_byte   = (JOCTET *)buf;
  src->bytes_in_buffer   = buflen;
}

/////////////////////////////////////////////////////////////////////////////

MODULE = Gtk2::CV PACKAGE = Gtk2::CV

PROTOTYPES: ENABLE

# calculate the common prefix length of two strings
# missing function in perl. really :)
int
common_prefix_length (a, b)
	unsigned char *a = (unsigned char *)SvPVutf8_nolen ($arg);
	unsigned char *b = (unsigned char *)SvPVutf8_nolen ($arg);
	CODE:
        RETVAL = 0;

        while (*a == *b && *a)
          {
            RETVAL += (*a & 0xc0) != 0x80;
            a++, b++;
          }

        OUTPUT:
        RETVAL

const char *
magic (SV *path_or_data)
	ALIAS:
        magic             = 0
        magic_mime        = 1
        magic_buffer      = 2
        magic_buffer_mime = 3
	CODE:
{
	STRLEN len;
	char *data = SvPVbyte (path_or_data, len);

        if (!magic_cookie[0])
	  {
            magic_cookie[0] = magic_open (MAGIC_SYMLINK);
            magic_cookie[1] = magic_open (MAGIC_SYMLINK | MAGIC_MIME_TYPE);
            magic_load (magic_cookie[0], 0);
            magic_load (magic_cookie[1], 0);
          }

        perlinterp_release ();

        RETVAL = ix & 2
          ? magic_buffer (magic_cookie[ix & 1], data, len)
          : magic_file   (magic_cookie[ix & 1], data);

        perlinterp_acquire ();
}
	OUTPUT:
        RETVAL

# missing/broken in Gtk2 perl module

void
gdk_window_clear_hints (GdkWindow *window)
	CODE:
        gdk_window_set_geometry_hints (window, 0, 0);

gboolean
gdk_net_wm_supports (GdkAtom property)
	CODE:
#if defined(GDK_WINDOWING_X11) && !defined(GDK_MULTIHEAD_SAFE)
        RETVAL = gdk_net_wm_supports (property);
#else
        RETVAL = 0;
#endif
        OUTPUT:
        RETVAL

GdkPixbuf_noinc *
dealpha_expose (GdkPixbuf *pb)
	CODE:
        perlinterp_release ();
{
	int w = gdk_pixbuf_get_width (pb);
        int h = gdk_pixbuf_get_height (pb);
        int bpp = gdk_pixbuf_get_n_channels (pb);
        int x, y, i;
        guchar *src = gdk_pixbuf_get_pixels (pb), *dst;
        int sstr = gdk_pixbuf_get_rowstride (pb), dstr;

	RETVAL = gdk_pixbuf_new (GDK_COLORSPACE_RGB, 0, 8, w, h);

        dst = gdk_pixbuf_get_pixels (RETVAL);
        dstr = gdk_pixbuf_get_rowstride (RETVAL);

        for (x = 0; x < w; x++)
          for (y = 0; y < h; y++)
            for (i = 0; i < 3; i++)
              dst[x * 3 + y * dstr + i] = src[x * bpp + y * sstr + i];
}
        perlinterp_acquire ();
	OUTPUT:
        RETVAL

GdkPixbuf_noinc *
rotate (GdkPixbuf *pb, int angle)
	CODE:
        perlinterp_release ();
        if (angle < 0)
          angle += 360;
        RETVAL = gdk_pixbuf_rotate_simple (pb, angle ==   0 ? GDK_PIXBUF_ROTATE_NONE
                                             : angle ==  90 ? GDK_PIXBUF_ROTATE_COUNTERCLOCKWISE
                                             : angle == 180 ? GDK_PIXBUF_ROTATE_UPSIDEDOWN
                                             : angle == 270 ? GDK_PIXBUF_ROTATE_CLOCKWISE
                                             : angle);
        perlinterp_acquire ();
	OUTPUT:
        RETVAL

const char *
filetype (SV *image_data)
	CODE:
{
        STRLEN data_len;
        U8 *data = SvPVbyte (image_data, data_len);

        if (data_len >= 20
            && data[0] == 0xff
            && data[1] == 0xd8
            && data[2] == 0xff)
	  RETVAL = "jpg";
        else if (data_len >= 12
            && data[ 0] == (U8)'R'
            && data[ 1] == (U8)'I'
            && data[ 2] == (U8)'F'
            && data[ 3] == (U8)'F'
            && data[ 8] == (U8)'W'
            && data[ 9] == (U8)'E'
            && data[10] == (U8)'B'
            && data[11] == (U8)'P')
          RETVAL = "webp";
        else if (data_len >= 16
            && data[ 0] == 0x89
            && data[ 1] == (U8)'P'
            && data[ 2] == (U8)'N'
            && data[ 3] == (U8)'G'
            && data[ 4] == 0x0d
            && data[ 5] == 0x0a
            && data[ 6] == 0x1a
            && data[ 7] == 0x0a)
          RETVAL = "png";
        else
          RETVAL = "other";
}
	OUTPUT:
        RETVAL

GdkPixbuf_noinc *
decode_webp (SV *image_data, int thumbnail = 0, int iw = 0, int ih = 0)
	CODE:
{
#if WEBP
	STRLEN data_size;
        int alpha;
        WebPData data;
        WebPDemuxer *demux;
        WebPIterator iter;
        WebPDecoderConfig config;
        int inw, inh;

        data.bytes = (uint8_t *)SvPVbyte (image_data, data_size);
        data.size = data_size;

        perlinterp_release ();

        RETVAL = 0;

	if (!(demux = WebPDemux (&data)))
          goto err_demux;

        if (!WebPDemuxGetFrame (demux, 1, &iter))
          goto err_iter;

        if (!WebPInitDecoderConfig (&config))
          goto err_iter;

        config.options.use_threads = 1;

        if (WebPGetFeatures (iter.fragment.bytes, iter.fragment.size, &config.input) != VP8_STATUS_OK)
          goto err_iter;

        inw = config.input.width;
        inh = config.input.height;

	if (thumbnail)
	  {
            if (inw * ih > inh * iw)
              ih = (iw * inh + inw - 1) / inw;
            else
              iw = (ih * inw + inh - 1) / inh;

	    config.options.bypass_filtering    = 1;
	    config.options.no_fancy_upsampling = 1;

	    config.options.use_scaling   = 1;
	    config.options.scaled_width  = iw;
	    config.options.scaled_height = ih;
          }
        else
          {
            iw = inw;
            ih = inh;
          }

        alpha = !!config.input.has_alpha;

	RETVAL = gdk_pixbuf_new (GDK_COLORSPACE_RGB, alpha, 8, iw, ih);
        if (!RETVAL)
          goto err_iter;

        config.output.colorspace = alpha ? MODE_RGBA : MODE_RGB;
        config.output.u.RGBA.rgba   = gdk_pixbuf_get_pixels      (RETVAL);
        config.output.u.RGBA.stride = gdk_pixbuf_get_rowstride   (RETVAL);
        config.output.u.RGBA.size   = gdk_pixbuf_get_byte_length (RETVAL);
        config.output.is_external_memory = 1;

        if (WebPDecode (iter.fragment.bytes, iter.fragment.size, &config) != VP8_STATUS_OK)
          {
            g_object_unref (RETVAL);
            RETVAL = 0;
            goto err_iter;
          }

	err_iter:
        WebPDemuxReleaseIterator (&iter);
	err_demux:
        WebPDemuxDelete (demux);

        perlinterp_acquire ();
#else
	croak ("load_webp: webp not enabled at compile time");
#endif
}
	OUTPUT:
        RETVAL

GdkPixbuf_noinc *
decode_jpeg (SV *image_data, int thumbnail = 0, int iw = 0, int ih = 0)
	CODE:
{
        struct jpeg_decompress_struct cinfo;
        struct jpg_err_mgr jerr;
        int rs;
        volatile GdkPixbuf *pb = 0;
        STRLEN data_len;
        guchar *data = SvPVbyte (image_data, data_len);

        RETVAL = 0;

        perlinterp_release ();

        cinfo.err = jpeg_std_error (&jerr.err);

        jerr.err.error_exit     = cv_error_exit;
        jerr.err.output_message = cv_error_output;

        if ((rs = setjmp (jerr.setjmp_buffer)))
          {
            jpeg_destroy_decompress (&cinfo);

            if (pb)
              g_object_unref ((gpointer)pb);

            perlinterp_acquire ();
            XSRETURN_UNDEF;
          }

        if (!data_len)
          longjmp (jerr.setjmp_buffer, 4);

        jpeg_create_decompress (&cinfo);
        cv_jpeg_mem_src (&cinfo, data, data_len);

        jpeg_read_header (&cinfo, TRUE);

        cinfo.dct_method          = JDCT_DEFAULT;
        cinfo.do_fancy_upsampling = FALSE; /* worse quality, but nobody compained so far, and gdk-pixbuf does the same */
        cinfo.do_block_smoothing  = FALSE;
        cinfo.out_color_space     = JCS_RGB;
        cinfo.quantize_colors     = FALSE;

        cinfo.scale_num   = 1;
        cinfo.scale_denom = 1;

        jpeg_calc_output_dimensions (&cinfo);

        if (thumbnail)
          {
            cinfo.dct_method          = JDCT_FASTEST;
            cinfo.do_fancy_upsampling = FALSE;

            while (cinfo.scale_denom < 8
                   && cinfo.output_width  >= iw*4
                   && cinfo.output_height >= ih*4)
              {
                cinfo.scale_denom <<= 1;
                jpeg_calc_output_dimensions (&cinfo);
              }
          }

        if (cinfo.output_components != 3)
          longjmp (jerr.setjmp_buffer, 3);

        if (cinfo.jpeg_color_space == JCS_YCCK || cinfo.jpeg_color_space == JCS_CMYK)
          {
            cinfo.out_color_space = JCS_CMYK;
            cinfo.output_components = 4;
          }

	pb = RETVAL = gdk_pixbuf_new (GDK_COLORSPACE_RGB, cinfo.output_components == 4, 8,  cinfo.output_width, cinfo.output_height);
        if (!RETVAL)
          longjmp (jerr.setjmp_buffer, 2);

        data = gdk_pixbuf_get_pixels (RETVAL);
        rs = gdk_pixbuf_get_rowstride (RETVAL);

        jpeg_start_decompress (&cinfo);

        while (cinfo.output_scanline < cinfo.output_height)
          {
            int remaining = cinfo.output_height - cinfo.output_scanline;
            JSAMPROW rp[4];

            rp [0] = data + cinfo.output_scanline * rs;
            rp [1] = (guchar *)rp [0] + rs;
            rp [2] = (guchar *)rp [1] + rs;
            rp [3] = (guchar *)rp [2] + rs;

            jpeg_read_scanlines (&cinfo, rp, remaining < 4 ? remaining : 4);
          }

        if (cinfo.out_color_space == JCS_CMYK)
          {
            guchar *end = data + cinfo.output_height * rs;

            while (data < end)
              {
                U32 c = data [0];
                U32 m = data [1];
                U32 y = data [2];
                U32 k = data [3];

                if (0)
                if (cinfo.Adobe_transform == 2)
                  {
                    c ^= 0xff;
                    m ^= 0xff;
                    y ^= 0xff;
                    k ^= 0xff;
                  }

                data [0] = (c * k + 0x80) / 0xff;
                data [1] = (m * k + 0x80) / 0xff;
                data [2] = (y * k + 0x80) / 0xff;
                data [3] = 0xff;

                data += 4;
              }
          }

        jpeg_finish_decompress (&cinfo);
        jpeg_destroy_decompress (&cinfo);
        perlinterp_acquire ();
}
	OUTPUT:
        RETVAL

void
compare (GdkPixbuf *a, GdkPixbuf *b)
	PPCODE:
        perlinterp_release ();
{
	int w  = gdk_pixbuf_get_width  (a);
	int h  = gdk_pixbuf_get_height (a);

        int sa = gdk_pixbuf_get_rowstride (a);
        int sb = gdk_pixbuf_get_rowstride (b);

        guchar *pa = gdk_pixbuf_get_pixels (a);
        guchar *pb = gdk_pixbuf_get_pixels (b);

	int x, y;

        assert (w == gdk_pixbuf_get_width  (b));
        assert (h == gdk_pixbuf_get_height (b));

        assert (gdk_pixbuf_get_n_channels (a) == 3);
        assert (gdk_pixbuf_get_n_channels (b) == 3);

        double diff = 0.;
        int peak = 0;

        if (w && h)
          for (y = 0; y < h; y++)
            {
              guchar *pa_ = pa + y * sa;
              guchar *pb_ = pb + y * sb;

              for (x = 0; x < w; x++)
                {
                  int d;

                  d = ((int)*pa_++) - ((int)*pb_++); diff += d*d; peak = MAX (peak, abs (d));
                  d = ((int)*pa_++) - ((int)*pb_++); diff += d*d; peak = MAX (peak, abs (d));
                  d = ((int)*pa_++) - ((int)*pb_++); diff += d*d; peak = MAX (peak, abs (d));
                }
            }

        perlinterp_acquire ();

        EXTEND (SP, 2);
        PUSHs (sv_2mortal (newSVnv (sqrt (diff / (w * h * 3. * 255. * 255.)))));
        PUSHs (sv_2mortal (newSVnv (peak / 255.)));
}

#############################################################################

MODULE = Gtk2::CV PACKAGE = Gtk2::CV::Schnauzer

# currently only works for filenames (octet strings)

SV *
foldcase (SV *pathsv)
	PROTOTYPE: $
	CODE:
{
	STRLEN plen;
        U8 *path = (U8 *)SvPV (pathsv, plen);
        U8 *pend = path + plen;
        U8 dst [plen * 6 * 3], *dstp = dst;

        while (path < pend)
          {
            U8 ch = *path;

            if (ch >= 'a' && ch <= 'z')
              *dstp++ = *path++;
            else if (ch >= 'A' && ch <= 'Z')
              *dstp++ = *path++ + ('a' - 'A');
            else if (ch >= '0' && ch <= '9')
              {
                STRLEN el, nl = 0;
                while (*path >= '0' && *path <= '9' && path < pend)
                  path++, nl++;

                for (el = nl; el < 6; el++)
                  *dstp++ = '0';

                memcpy (dstp, path - nl, nl);
                dstp += nl;
              }
            else
              *dstp++ = *path++;
#if 0
            else
              {
                STRLEN cl;
                to_utf8_fold (path, dstp, &cl);
                dstp += cl;
                path += is_utf8_char (path);
              }
#endif
          }

        RETVAL = newSVpvn ((const char *)dst, dstp - dst);
}
	OUTPUT:
        RETVAL

GdkPixbuf_noinc *
p7_to_pb (int w, int h, SV *src_sv)
        PROTOTYPE: @
	CODE:
{
	int x, y;
        guchar *dst, *d;
        int dstr;
        guchar *src = (guchar *)SvPVbyte_nolen (src_sv);

	RETVAL = gdk_pixbuf_new (GDK_COLORSPACE_RGB, 0, 8,  w, h);
        dst = gdk_pixbuf_get_pixels (RETVAL);
        dstr = gdk_pixbuf_get_rowstride (RETVAL);

        for (y = 0; y < h; y++)
          for (d = dst + y * dstr, x = 0; x < w; x++)
            {
              *d++ = (((*src >> 5) & 7) * 255 + 4) / 7;
              *d++ = (((*src >> 2) & 7) * 255 + 4) / 7;
              *d++ = (((*src >> 0) & 3) * 255 + 2) / 3;

              src++;
            }
}
	OUTPUT:
        RETVAL

#############################################################################

MODULE = Gtk2::CV PACKAGE = Gtk2::CV::PostScript

void
dump_ascii85 (PerlIO *fp, GdkPixbuf *pb)
	CODE:
{
	int w = gdk_pixbuf_get_width  (pb);
	int h = gdk_pixbuf_get_height (pb);
	int x, y, i;
        guchar *dst;
        int bpp = gdk_pixbuf_get_n_channels (pb);
        guchar *src = gdk_pixbuf_get_pixels (pb);
        int sstr = gdk_pixbuf_get_rowstride (pb);

        a85_init ();

        for (y = 0; y < h; y++)
          for (x = 0; x < w; x++)
            for (i = 0; i < (bpp < 3 ? 1 : 3); i++)
              a85_push (fp, src [x * bpp + y * sstr + i]);

        a85_finish (fp);
}

void
dump_binary (PerlIO *fp, GdkPixbuf *pb)
	CODE:
{
	int w = gdk_pixbuf_get_width  (pb);
	int h = gdk_pixbuf_get_height (pb);
	int x, y, i;
        guchar *dst;
        int bpp = gdk_pixbuf_get_n_channels (pb);
        guchar *src = gdk_pixbuf_get_pixels (pb);
        int sstr = gdk_pixbuf_get_rowstride (pb);

        for (y = 0; y < h; y++)
          for (x = 0; x < w; x++)
            for (i = 0; i < (bpp < 3 ? 1 : 3); i++)
              PerlIO_putc (fp, src [x * bpp + y * sstr + i]);
}

#############################################################################

MODULE = Gtk2::CV PACKAGE = Gtk2::CV

SV *
pb_to_hv84 (GdkPixbuf *pb)
	CODE:
{
	int w = gdk_pixbuf_get_width  (pb);
	int h = gdk_pixbuf_get_height (pb);
	int x, y;
        guchar *dst;
        int bpp = gdk_pixbuf_get_n_channels (pb);
        guchar *src = gdk_pixbuf_get_pixels (pb);
        int sstr = gdk_pixbuf_get_rowstride (pb);

	RETVAL = newSV (6 * 8 * 12 / 8);
        SvPOK_only (RETVAL);
        SvCUR_set (RETVAL, 6 * 8 * 12 / 8);

        dst = (guchar *)SvPVX (RETVAL);

        /* some primitive error distribution + random dithering */

        for (y = 0; y < h; y++)
          {
            guchar *p = src + y * sstr;

            for (x = 0; x < w; x += 2)
              {
                unsigned int r, g, b, h, s, v, H, V1, V2;

                if (bpp == 3)
                  r = *p++, g = *p++, b = *p++;
                else if (bpp == 1)
                  r = g = b = *p++;
                else
                  abort ();

                rgb_to_hsv (r, g, b, &h, &s, &v);

                H = (h * 15 / 255) << 4;
                V1 = v;

                if (bpp == 3)
                  r = *p++, g = *p++, b = *p++;
                else if (bpp == 1)
                  r = g = b = *p++;
                else
                  abort ();

                rgb_to_hsv (r, g, b, &h, &s, &v);

                H |= h * 15 / 255;
                V2 = v;

                *dst++ = H;
                *dst++ = V1;
                *dst++ = V2;
              }
          }
}
	OUTPUT:
        RETVAL

SV *
hv84_to_av (unsigned char *hv84)
	CODE:
{
        int i = 72 / 3;
        AV *av = newAV ();

        RETVAL = (SV *)newRV_noinc ((SV *)av);
        while (i--)
          {
            int h  = *hv84++;
            int v1 = *hv84++;
            int v2 = *hv84++;

            av_push (av, newSViv (v1));
            av_push (av, newSViv ((h >> 4) * 255 / 15));
            av_push (av, newSViv (v2));
            av_push (av, newSViv ((h & 15) * 255 / 15));
          }
}
	OUTPUT:
        RETVAL

#############################################################################

MODULE = Gtk2::CV PACKAGE = Gtk2::CV::Plugin::RCluster

SV *
extract_features (SV *ar)
	CODE:
{
        int i;
        AV *av, *result;

        if (!SvROK (ar) || SvTYPE (SvRV (ar)) != SVt_PVAV)
          croak ("Not an array ref as first argument to extract_features");

        av = (AV *) SvRV (ar);
        result = newAV ();

        for (i = 0; i <= av_len (av); ++i)
          {
            SV *sv = *av_fetch (av, i, 1);
            SV *histsv = newSV (9 * sizeof (float) + 1);

            SvPOK_on (histsv);
            SvCUR_set (histsv, 9 * sizeof (float));
            float *hist = (float *)SvPVX (histsv);

            struct feature f_h, f_s, f_v;
            feature_init (&f_h);
            feature_init (&f_s);
            feature_init (&f_v);

            {
              STRLEN len;
              unsigned char *buf = (unsigned char *)SvPVbyte (sv, len);
              while (len >= 3)
                {
                  unsigned int r, g, b, h, s, v;
                  r = *buf++; g = *buf++; b = *buf++;
                  rgb_to_hsv (r, g, b, &h, &s, &v);

                  feature_update_pass_1 (&f_h, h);
                  feature_update_pass_1 (&f_s, s);
                  feature_update_pass_1 (&f_v, v);

                  len -= 3;
                }

              feature_finish_pass_1 (&f_h);
              feature_finish_pass_1 (&f_s);
              feature_finish_pass_1 (&f_v);
            }

            {
              STRLEN len;
              unsigned char *buf = (unsigned char *)SvPVbyte (sv, len);
              while (len >= 3)
                {
                  unsigned int r, g, b, h, s, v;
                  r = *buf++; g = *buf++; b = *buf++;
                  rgb_to_hsv (r, g, b, &h, &s, &v);

                  feature_update_pass_2 (&f_h, h);
                  feature_update_pass_2 (&f_s, s);
                  feature_update_pass_2 (&f_v, v);

                  len -= 3;
                }

              feature_finish_pass_2 (&f_h);
              feature_finish_pass_2 (&f_s);
              feature_finish_pass_2 (&f_v);
            }

            hist [0] = f_h.v1 * 2.; hist [1] = f_h.v2 * 2.; hist [2] = f_h.v3 * 2.;
            hist [3] = f_s.v1     ; hist [4] = f_s.v2     ; hist [5] = f_s.v3     ;
            hist [6] = f_v.v1 * .5; hist [7] = f_v.v2 * .5; hist [8] = f_v.v3 * .5;

            av_push (result, histsv);
          }

        RETVAL = newRV_noinc ((SV *)result);
}
        OUTPUT:
        RETVAL

