
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "PerlGnomePrintInt.h"

#include "GnomePrintDefs.h"
#include "GtkDefs.h"
#include "GdkPixbufDefs.h"

static void
call_line_handler(SV *handler, GnomePrintContext *context, int line, SV *data) {
	dSP ;
	ENTER;
	SAVETMPS;
	PUSHMARK(SP);

	XPUSHs(sv_2mortal(newSVGtkObjectRef(GTK_OBJECT(context), NULL)));
	XPUSHs(sv_2mortal(newSViv(line)));
	XPUSHs(sv_2mortal(newSVsv(data)));

	PUTBACK;

	call_sv(handler, G_DISCARD);
	
	FREETMPS;
	LEAVE;
}

MODULE = Gnome::PrintContext		PACKAGE = Gnome::PrintContext		PREFIX = gnome_print_

#ifdef GNOME_PRINT_CONTEXT

Gnome::PrintContext
new (Class, printer)
	SV*	Class
	Gnome::Printer	printer
	CODE:
	RETVAL = (GnomePrintContext*)(gnome_print_context_new(printer));
	OUTPUT:
	RETVAL

Gnome::PrintContext
gnome_print_context_new_with_paper_size (Class, printer, paper)
	SV*	Class
	Gnome::Printer	printer
	char*	paper
	CODE:
	RETVAL = (GnomePrintContext*)(gnome_print_context_new_with_paper_size(printer, paper));
	OUTPUT:
	RETVAL

int
gnome_print_context_close (context)
	Gnome::PrintContext	context

int
gnome_print_newpath (context)
	Gnome::PrintContext	context

int
gnome_print_moveto (context, x, y)
	Gnome::PrintContext	context
	double	x
	double	y

int
gnome_print_lineto (context, x, y)
	Gnome::PrintContext	context
	double	x
	double	y

int
gnome_print_curveto (context, x1, y1, x2, y2, x3, y3)
	Gnome::PrintContext	context
	double	x1
	double	y1
	double	x2
	double	y2
	double	x3
	double	y3

int
gnome_print_closepath (context)
	Gnome::PrintContext	context

int
gnome_print_setrgbcolor (context, r, g, b)
	Gnome::PrintContext context
	double	r
	double	g
	double	b

int
gnome_print_fill (context)
	Gnome::PrintContext	context

int
gnome_print_eofill (context)
	Gnome::PrintContext	context

int
gnome_print_setlinewidth (context, width)
	Gnome::PrintContext	context
	double	width

int
gnome_print_setmiterlimit (context, limit)
	Gnome::PrintContext	context
	double	limit

int
gnome_print_setlinejoin (context, jointype)
	Gnome::PrintContext	context
	int	jointype

int
gnome_print_setlinecap (context, linecap)
	Gnome::PrintContext	context
	int	linecap

int
gnome_print_setdash (context, offset, ...)
	Gnome::PrintContext	context
	double	offset
	CODE:
	{
		double *dashes;
		int nd = items-2;
		int i;
		dashes = g_new0(double, nd);
		for(i=2; i < items; ++i) {
			dashes[i-2] = SvNV(ST(i));
		}
		RETVAL=gnome_print_setdash (context, nd, dashes, offset);	
		g_free(dashes);
	}
	OUTPUT:
	RETVAL

int
gnome_print_strokepath (context)
	Gnome::PrintContext	context

int
gnome_print_stroke (context)
	Gnome::PrintContext	context

int
gnome_print_setfont (context, font)
	Gnome::PrintContext	context
	Gnome::Font	font

int
gnome_print_show (context, text, ...)
	Gnome::PrintContext	context
	char*	text
	CODE:
	{
		if (items > 2) {
			GnomeTextLine **lines;
			GnomeTextLayout *layout;
			GnomeTextAttrEl *attrs;
			int n, i, j;
			SV * handler = NULL;
			SV * udata = NULL;
			SV * data = ST(2);

			n = items-3;
			if (n % 3)
				croak("Atributes number must be multiple of 3");
			n /= 3;
			attrs = g_new0(GnomeTextAttrEl, n+1);
			for (j=0,i=3; i < items; j++,i+=3) {
				attrs[j].char_pos = SvIV(ST(i));
				attrs[j].attr = SvGnomeTextAttr(ST(i+1));
				switch(attrs[j].attr) {
				case GNOME_TEXT_FONT_LIST:
					attrs[j].attr_val = gnome_text_intern_font_list(SvPV(ST(i+2), PL_na));
					break;
				case GNOME_TEXT_COLOR:
					attrs[j].attr_val = SvIV(ST(i+2)); /* FIXME: use a more perlish interface */
					break;
				default:
					attrs[j].attr_val = SvIV(ST(i+2));
				}
			}
			attrs[n].char_pos = strlen(text); /* FIXME: handle utf8 */
			attrs[n].attr = GNOME_TEXT_END;
			layout = gnome_text_layout_new(text, attrs);
			if (SvOK(data) && SvROK(data) && SvTYPE(SvRV(data)) == SVt_PVHV) {
				SV **val;
				HV *hv = (HV*)SvRV(data);
				if ((val=hv_fetch(hv, "handler", 7, 0)) && SvOK(*val))
					handler = *val;
				if ((val=hv_fetch(hv, "data", 4, 0)) && SvOK(*val))
					udata = *val;
				if ((val=hv_fetch(hv, "width", 5, 0)) && SvOK(*val))
					layout->set_width = SvIV(*val);
				if ((val=hv_fetch(hv, "align", 5, 0)) && SvOK(*val))
					layout->align = SvGnomeTextAlign(*val);
				if ((val=hv_fetch(hv, "max_neg_space", 13, 0)) && SvOK(*val))
					layout->max_neg_space = SvIV(*val);
				/* leave this check last */
				if ((val=hv_fetch(hv, "justify", 7, 0)) && SvOK(*val) && SvIV(*val))
					gnome_text_hs_just(layout);
			}
			lines = gnome_text_lines_from_layout(layout);
			RETVAL = 0;
			for (i=0; lines[i]; ++i) {
				if (handler)
					call_line_handler(handler, context, i, udata);
				RETVAL += gnome_print_textline (context, lines[i]);
				gnome_text_line_free(lines[i]);
			}
			if (i==0) { /* work around bug??? */
				GnomeTextLine *line = gnome_text_line_from_layout(layout);
				if (handler)
					call_line_handler(handler, context, i, udata);
				RETVAL = gnome_print_textline (context, line);
				gnome_text_line_free(line);
			}
			gnome_text_layout_free(layout);
			g_free(attrs);
			g_free(lines);
		} else {
			RETVAL = gnome_print_show (context, text);
		}
	}
	OUTPUT:
	RETVAL

int
gnome_print_concat (context, d0, d1, d2, d3, d4, d5)
	Gnome::PrintContext	context
	double	d0
	double	d1
	double	d2
	double	d3
	double	d4
	double	d5
	CODE:
	{
		double m[6];
		m[0] = d0; m[1] = d1; m[2] = d2;
		m[3] = d3; m[4] = d4; m[5] = d5;
		RETVAL = gnome_print_concat(context, m);
	}
	OUTPUT:
	RETVAL

int
gnome_print_gsave (context)
	Gnome::PrintContext	context

int
gnome_print_grestore (context)
	Gnome::PrintContext	context

int
gnome_print_clip (context)
	Gnome::PrintContext	context

int
gnome_print_eoclip (context)
	Gnome::PrintContext	context

int
gnome_print_showpage (context)
	Gnome::PrintContext	context

int
gnome_print_beginpage (context, page_name)
	Gnome::PrintContext	context
	char*	page_name

int
gnome_print_setopacity (context, opacity)
	Gnome::PrintContext	context
	double	opacity

int
gnome_print_grayimage (pc, data, width, height, rowstride=0)
	Gnome::PrintContext	pc
	SV *	data
	int	width
	int	height
	int	rowstride
	CODE:
	{
		STRLEN l;
		char *p = SvPV(data, l);
		if (!rowstride)
			rowstride = width;
		if (l < rowstride*height)
			croak("Too little data in grayimage (expected %d)", rowstride*height);
		RETVAL = gnome_print_grayimage (pc, p, width, height, rowstride);
	}
	OUTPUT:
	RETVAL

int
gnome_print_rgbimage (pc, data, width, height, rowstride=0)
	Gnome::PrintContext	pc
	SV *	data
	int	width
	int	height
	int	rowstride
	CODE:
	{
		STRLEN l;
		char *p = SvPV(data, l);
		if (!rowstride)
			rowstride = width*3;
		if (l < rowstride*height)
			croak("Too little data in rgbimage (expected %d)", rowstride*height);
		RETVAL = gnome_print_rgbimage (pc, p, width, height, rowstride);
	}
	OUTPUT:
	RETVAL

int
gnome_print_rgbaimage (pc, data, width, height, rowstride=0)
	Gnome::PrintContext	pc
	SV *	data
	int	width
	int	height
	int	rowstride
	CODE:
	{
		STRLEN l;
		char *p = SvPV(data, l);
		if (!rowstride)
			rowstride = width*4;
		if (l < rowstride*height)
			croak("Too little data in rgbaimage (expected %d)", rowstride*height);
		RETVAL = gnome_print_rgbaimage (pc, p, width, height, rowstride);
	}
	OUTPUT:
	RETVAL

int
gnome_print_pixbuf (pc, pixbuf)
	Gnome::PrintContext	pc
	Gtk::Gdk::Pixbuf	pixbuf

# missing textline (implemented in _show)
# missing v/bpath

int
gnome_print_scale (context, sx, sy)
	Gnome::PrintContext	context
	double	sx
	double	sy

int
gnome_print_rotate (context, theta)
	Gnome::PrintContext	context
	double	theta

int
gnome_print_translate (context, x, y)
	Gnome::PrintContext	context
	double	x
	double	y

#if 0

int
gnome_print_context_open_file (context, filename)
	Gnome::PrintContext	context
	char	*filename

int
gnome_print_context_write_file (context, data)
	Gnome::PrintContext	context
	SV *data
	CODE:
	{
		STRLEN len;
		char *buf = SvPV(data, len);
		RETVAL = gnome_print_context_write_file (context, buf, len);
	}
	OUTPUT:
	RETVAL

int
gnome_print_context_close_file (context)
	Gnome::PrintContext	context

#endif

#endif

