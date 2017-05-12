
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "GtkDefs.h"
#include "GnomeDefs.h"


MODULE = Gnome::Less		PACKAGE = Gnome::Less		PREFIX = gnome_less_

#ifdef GNOME_LESS

Gnome::Less_Sink
new(Class)
	SV *	Class
	CODE:
	RETVAL = (GnomeLess*)(gnome_less_new());
	OUTPUT:
	RETVAL

void
gnome_less_clear(gl)
	Gnome::Less	gl

void
gnome_less_reshow(gl)
	Gnome::Less	gl

void
gnome_less_show_file(gl, path)
	Gnome::Less	gl
	char *	path

void
gnome_less_show_command(gl, command)
	Gnome::Less	gl
	char *	command

void
gnome_less_show_string(gl, string)
	Gnome::Less	gl
	char *	string

void
gnome_less_show_filestream(gl, stream)
	Gnome::Less	gl
	FILE *	stream

void
gnome_less_show_fd(gl, fd)
	Gnome::Less	gl
	int	fd

void
gnome_less_fixed_font(gl)
	Gnome::Less	gl

void
gnome_less_set_fixed_font (gl, fixed)
	Gnome::Less	gl
	bool	fixed

void
gnome_less_set_font (gl, font)
	Gnome::Less	gl
	Gtk::Gdk::Font	font

#endif

