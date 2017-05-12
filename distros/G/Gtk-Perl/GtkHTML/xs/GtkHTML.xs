
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "GtkDefs.h"
#include "GtkHTMLDefs.h"

#ifdef GTKHTML_HAVE_GCONF
#include <gconf/gconf.h>
#endif

static void 
destroy_handler(gpointer data) {
        SvREFCNT_dec((AV*)data);
}

static void     callXS (void (*subaddr)(CV* cv), CV *cv, SV **mark)
{
        int items;
        dSP;
        PUSHMARK (mark);
        (*subaddr)(cv);

        PUTBACK;  /* Forget the return values */
}

#define sp (*_sp)
static int fixup_html(SV ** * _sp, int match, GtkObject * object, char * signame, int nparams, GtkArg * args, GtkType return_type)
{
	dTHR;
	XPUSHs(sv_2mortal(newSVpv(GTK_VALUE_POINTER(args[0]), 0)));
	XPUSHs(sv_2mortal(newSViv((long)GTK_VALUE_POINTER(args[1]))));
	return 1;
}
#undef sp

static bool
html_save (const HTMLEngine *engine, const char *data, guint len, gpointer user_data) {
	AV *stuff;
	SV *handler;
	int i, result;
	dSP;

	stuff = (AV*) user_data;
	handler = *av_fetch(stuff, 0, 0);

	ENTER;
	SAVETMPS;

	PUSHMARK(SP);

	XPUSHs(sv_2mortal(newSVpvn(data, len)));

	for(i=1; i <= av_len(stuff); ++i)
		XPUSHs(sv_2mortal(newSVsv(*av_fetch(stuff, i, 0))));
	
	PUTBACK;
	i = perl_call_sv(handler, G_SCALAR);
	
	SPAGAIN;

	if (i != 1)
		croak("handler failed");
	
	result = POPi;

	PUTBACK;
	FREETMPS;
	LEAVE;
	return result;
}

MODULE = Gtk::HTML	PACKAGE = Gtk::HTML	PREFIX = gtk_html_

#ifdef GTK_HTML

void
init(Class)
	CODE:
	{
		static int did_it = 0;
		static char * names[] = { "url_requested", 0 };
		if (did_it)
			return;
		did_it = 1;
		GtkHTML_InstallTypedefs();
		GtkHTML_InstallObjects();
		AddSignalHelperParts(gtk_html_get_type(), names, fixup_html, 0);
#ifdef GTKHTML_HAVE_GCONF
		/* gtkhtml is _so_ broken */
		if (!gconf_is_initialized()) {
			int argc;
			char ** argv = 0;
			AV * ARGV = perl_get_av("ARGV", FALSE);
			SV * ARGV0 = perl_get_sv("0", FALSE);
			int i;

			argc = av_len(ARGV)+2;
			if (argc) {
				argv = malloc(sizeof(char*)*argc);
				argv[0] = g_strdup(SvPV(ARGV0, PL_na));
				for(i=0;i<=av_len(ARGV);i++)
					argv[i+1] = g_strdup(SvPV(*av_fetch(ARGV, i, 0), PL_na));
			}
			gconf_init (argc, argv, NULL);
			if (argv) {
				for (i=0; i < argc; ++i)
					g_free(argv[i]);
				free(argv);
			}
		}
#endif
	}

Gtk::HTML_Sink
gtk_html_new (Class)
	SV *	Class
	CODE:
	RETVAL = (GtkHTML*)(gtk_html_new());
	OUTPUT:
	RETVAL

#if GTKHTML_HVER >= 0x001000

Gtk::HTML_Sink
gtk_html_new_from_string (Class, html_data)
	SV *	Class
	SV *	html_data
	CODE:
	{
		STRLEN len;
		char *d = SvPV (html_data, len);
		RETVAL = (GtkHTML*)(gtk_html_new_from_string(d, len));
	}
	OUTPUT:
	RETVAL

gulong
gtk_html_begin_content (html, content_type)
	Gtk::HTML	html
	char *		content_type

#endif

gulong
gtk_html_begin (html)
	Gtk::HTML	html

void
gtk_html_write (html, handle, chunk)
	Gtk::HTML	html
	guint	handle
	SV *	chunk
	CODE:
	{
		STRLEN blen;
		char *buf = SvPV(chunk, blen);
		gtk_html_write(html, handle, buf, blen);
	}

void
gtk_html_end (html, handle, status)
	Gtk::HTML	html
	guint	handle
	Gtk::HTMLStreamStatus	status

void
gtk_html_load_empty (html)
	Gtk::HTML	html

void
gtk_html_load_from_string (html, data)
	Gtk::HTML	html
	SV *		data
	CODE:
	{
		STRLEN blen;
		char *buf = SvPV(data, blen);
		gtk_html_load_from_string (html, buf, blen);
	}

void
gtk_html_set_editable (html, editable)
	Gtk::HTML	html
	bool	editable

bool
gtk_html_get_editable (html)
	Gtk::HTML	html

void
gtk_html_allow_selection (html, allow)
	Gtk::HTML	html
	bool	allow

#if GTKHTML_HVER < 0x000a00
	
int
gtk_html_request_paste (html, type, time)
	Gtk::HTML	html
	int	type
	int	time

#else

int
gtk_html_request_paste (html, selection, type, time)
	Gtk::HTML	html
	Gtk::Gdk::Atom	selection
	int	type
	int	time

#endif

#if GTKHTML_HVER >= 0x001000

void
gtk_html_select_word (html)
	Gtk::HTML	html

void
gtk_html_select_line (html)
	Gtk::HTML	html

void
gtk_html_select_paragraph (html)
	Gtk::HTML	html

void
gtk_html_select_paragraph_extended (html)
	Gtk::HTML	html

void
gtk_html_select_all (html)
	Gtk::HTML	html

void
gtk_html_modify_indent_by_delta (html, delta)
	Gtk::HTML	html
	int	delta

Gtk::HTMLParagraphStyle
gtk_html_get_paragraph_style (html)
	Gtk::HTML	html

void
gtk_html_set_color (html, color)
	Gtk::HTML	html
	Gtk::Gdk::Color	color
	CODE:
	{
		HTMLColor *c = html_color_new_from_gdk_color (color);
		gtk_html_set_color (html, c);
		html_color_unref (color);
	}

void
gtk_html_insert_html (html, html_src)
	Gtk::HTML	html
	char *	html_src

void
gtk_html_append_html (html, html_src)
	Gtk::HTML	html
	char *	html_src

void
gtk_html_set_default_content_type (html, content_type)
	Gtk::HTML	html
	char *	content_type

bool
gtk_html_command (html, command_name)
	Gtk::HTML	html
	char *	command_name

bool
gtk_html_edit_make_cursor_visible (html)
	Gtk::HTML	html

bool
gtk_html_build_with_gconf (Class)
	SV *	Class
	CODE:
	RETVAL = gtk_html_build_with_gconf ();
	OUTPUT:
	RETVAL

void
gtk_html_set_magnification (html, magnification)
	Gtk::HTML	html
	gdouble	magnification

void
gtk_html_zoom_in (html)
	Gtk::HTML	html

void
gtk_html_zoom_out (html)
	Gtk::HTML	html

void
gtk_html_zoom_reset (html)
	Gtk::HTML	html

void
gtk_html_update_styles (html)
	Gtk::HTML	html

void
gtk_html_set_allow_frameset (html, allow)
	Gtk::HTML	html
	bool	allow

bool
gtk_html_get_allow_frameset (html)
	Gtk::HTML	html

void
gtk_html_set_base (html, url)
	Gtk::HTML	html
	char *	url

char*
gtk_html_get_base (html)
	Gtk::HTML	html

void
gtk_html_set_indent (html, delta)
	Gtk::HTML	html
	int	delta

#else

void
gtk_html_indent (html, delta)
	Gtk::HTML	html
	int	delta

#endif

void
gtk_html_set_paragraph_style (html, style)
	Gtk::HTML	html
	Gtk::HTMLParagraphStyle	style

void
gtk_html_set_font_style (html, and_mask, or_mask)
	Gtk::HTML	html
	Gtk::HTMLFontStyle	and_mask
	Gtk::HTMLFontStyle	or_mask

void
gtk_html_set_paragraph_alignment (html, alignment)
	Gtk::HTML	html
	Gtk::HTMLParagraphAlignment	alignment

Gtk::HTMLParagraphAlignment
gtk_html_get_paragraph_alignment (html)
	Gtk::HTML	html

void
gtk_html_cut (html)
	Gtk::HTML	html

void
gtk_html_paste (html)
	Gtk::HTML	html

void
gtk_html_copy (html)
	Gtk::HTML	html

void
gtk_html_undo (html)
	Gtk::HTML	html

void
gtk_html_redo (html)
	Gtk::HTML	html

void
gtk_html_set_default_background_color (html, color)
	Gtk::HTML	html
	Gtk::Gdk::Color color

void
gtk_html_enable_debug (html, debug)
	Gtk::HTML	html
	bool	debug

char*
gtk_html_get_title (html)
	Gtk::HTML	html

bool
gtk_html_jump_to_anchor (html, anchor)
	Gtk::HTML	html
	char*	anchor

bool
gtk_html_save (html, handler, ...)
	Gtk::HTML	html
	SV	*handler
	CODE:
	{
		AV *args;

		args = newAV();

		PackCallbackST(args, 1);
		RETVAL = gtk_html_save(html, html_save, args);
		SvREFCNT_dec(args);
	}
	OUTPUT:
	RETVAL

bool
gtk_html_export (html, type, handler, ...)
	Gtk::HTML	html
	char *type
	SV	*handler
	CODE:
	{
		AV *args;

		args = newAV();

		PackCallbackST(args, 2);
		RETVAL = gtk_html_export(html, type, html_save, args);
		SvREFCNT_dec(args);
	}
	OUTPUT:
	RETVAL

#endif

INCLUDE: ../build/boxed.xsh

INCLUDE: ../build/objects.xsh

INCLUDE: ../build/extension.xsh

