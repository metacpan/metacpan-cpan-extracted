
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "GtkDefs.h"
#include "GnomeDefs.h"

#include <zvt/zvtterm.h>

MODULE = Gnome::ZvtTerm		PACKAGE = Gnome::ZvtTerm		PREFIX = zvt_term_

#ifdef ZVT_TERM

Gnome::ZvtTerm_Sink
new(Class)
	SV *	Class
	CODE:
	RETVAL = (ZvtTerm*)(zvt_term_new());
	OUTPUT:
	RETVAL

Gnome::ZvtTerm_Sink
new_with_size(Class, cols, rows)
	SV *	Class
	int	cols
	int	rows
	CODE:
	RETVAL = (ZvtTerm*)(zvt_term_new_with_size(cols, rows));
	OUTPUT:
	RETVAL

void
zvt_term_reset (term, hard)
	Gnome::ZvtTerm	term
	int	hard


#if GNOME_HVER >= 0x010200

void
zvt_term_feed(term, text, len)
	Gnome::ZvtTerm	term
	char *	text
	int	len

#endif

int
zvt_term_forkpty(term, do_uwtmp_log)
	Gnome::ZvtTerm	term
	int do_uwtmp_log;

void
zvt_term_closepty(term)
	Gnome::ZvtTerm	term

void
zvt_term_killchild(term, signal)
	Gnome::ZvtTerm	term
	int	signal

void
zvt_term_bell(term)
	Gnome::ZvtTerm	term

void
zvt_term_set_scrollback(term, scrollback)
	Gnome::ZvtTerm	term
	int	scrollback

void
zvt_term_get_buffer (term, type, sx, sy, ex, ey)
	Gnome::ZvtTerm	term
	int	type
	int	sx
	int	sy
	int	ex
	int	ey
	PPCODE:
	{
		char* res;
		int len=0;

		res = zvt_term_get_buffer (term, &len, type, sx, sy, ex, ey);
		EXTEND(sp, 2);
		PUSHs(sv_2mortal(newSVpv(res, 0)));
		PUSHs(sv_2mortal(newSViv(len)));
		g_free(res);
	}

void
zvt_term_set_font_name(term, name)
	Gnome::ZvtTerm	term
	char *	name

void
zvt_term_set_fonts(term, font, font_bold)
	Gnome::ZvtTerm	term
	Gtk::Gdk::Font	font
	Gtk::Gdk::Font	font_bold

void
zvt_term_hide_pointer(term)
	Gnome::ZvtTerm	term

void
zvt_term_show_pointer(term)
	Gnome::ZvtTerm	term

void
zvt_term_set_bell (term, state)
	Gnome::ZvtTerm	term
	int	state

gboolean
zvt_term_get_bell (term)
	Gnome::ZvtTerm	term

void
zvt_term_set_blink(term, state)
	Gnome::ZvtTerm	term
	int	state

void
zvt_term_set_scroll_on_keystroke(term, state)
	Gnome::ZvtTerm	term
	int	state

void
zvt_term_set_scroll_on_output(term, state)
	Gnome::ZvtTerm	term
	int	state

void
zvt_term_set_color_scheme (term, red, green, blue)
	Gnome::ZvtTerm	term
	SV *red
	SV *green
	SV *blue
	CODE:
	{
		gushort r[18], g[18], b[18];
		AV *ra, *ga, *ba;
		int i;
		SV **s;

		if (!red || !SvOK(red) || !SvROK(red) || SvTYPE(SvRV(red)) != SVt_PVAV )
			croak("need an array ref in set_color_scheme");
		ra = (AV*)SvRV(red);
		if (!green || !SvOK(green) || !SvROK(green) || SvTYPE(SvRV(green)) != SVt_PVAV )
			croak("need an array ref in set_color_scheme");
		ga = (AV*)SvRV(green);
		if (!blue || !SvOK(blue) || !SvROK(blue) || SvTYPE(SvRV(blue)) != SVt_PVAV )
			croak("need an array ref in set_color_scheme");
		ba = (AV*)SvRV(blue);
		for (i=0; i < 18; ++i) {
			r[i] = (s=av_fetch(ra, i, 0)) && SvOK(*s)? SvIV(*s): 0;
			g[i] = (s=av_fetch(ga, i, 0)) && SvOK(*s)? SvIV(*s): 0;
			b[i] = (s=av_fetch(ba, i, 0)) && SvOK(*s)? SvIV(*s): 0;
		}
		zvt_term_set_color_scheme (term, r, g, b);
	}


void
zvt_term_set_default_color_scheme(term)
	Gnome::ZvtTerm	term

void
zvt_term_set_del_key_swap (term, state)
	Gnome::ZvtTerm	term
	int	state

void
zvt_term_set_wordclass (term ,klass)
	Gnome::ZvtTerm	term
	char*	klass

#if 0

void
zvt_term_set_auto_window_hint (term, state)
	Gnome::ZvtTerm	term
	int	state

#endif

int
zvt_term_match_add (term, regexp, highlight_mask, data)
	Gnome::ZvtTerm	term
	char*	regexp
	unsigned int highlight_mask
	SV *data

void
zvt_term_match_clear (term, regexp)
	Gnome::ZvtTerm	term
	char*	regexp

char*
zvt_term_match_check (term, x, y)
	Gnome::ZvtTerm	term
	int	x
	int	y
	CODE:
	{
		gpointer data = NULL;
		RETVAL = zvt_term_match_check (term, x, y, &data);
	}

void
zvt_term_set_background (term, pixmap_file, transparent, shaded)
	Gnome::ZvtTerm	term
	char*	pixmap_file
	int	transparent
	int	shaded

void
zvt_term_set_shadow_type (term, type)
	Gnome::ZvtTerm	term
	Gtk::ShadowType	type

void
zvt_term_set_size (term, width, height)
	Gnome::ZvtTerm	term
	int	width
	int	height

int
writechild (term, text)
	Gnome::ZvtTerm	term
	SV *text
	CODE:
	{
		STRLEN len;
		char *p = SvPV(text, len);
		RETVAL = zvt_term_writechild(term, p, len);
	}
	OUTPUT:
	RETVAL


Gtk::Adjustment
adjustment(term)
	Gnome::ZvtTerm	term
	CODE:
	RETVAL = term->adjustment;
	OUTPUT:
	RETVAL

#endif

