
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "PerlGtkInt.h"

#include "GtkDefs.h"
#include "GnomeDefs.h"


MODULE = Gnome::PaperSelector		PACKAGE = Gnome::PaperSelector		PREFIX = gnome_paper_selector_

#ifdef GNOME_PAPER_SELECTOR

Gnome::PaperSelector_Sink
new (Class)
	SV *	Class
	CODE:
	RETVAL = (GnomePaperSelector*)(gnome_paper_selector_new());
	OUTPUT:
	RETVAL

char*
gnome_paper_selector_get_name (gspaper)
	Gnome::PaperSelector	gspaper

gfloat
gnome_paper_selector_get_width (gspaper)
	Gnome::PaperSelector	gspaper

gfloat
gnome_paper_selector_get_height (gspaper)
	Gnome::PaperSelector	gspaper

gfloat
gnome_paper_selector_get_left_margin (gspaper)
	Gnome::PaperSelector	gspaper

gfloat
gnome_paper_selector_get_right_margin (gspaper)
	Gnome::PaperSelector	gspaper

gfloat
gnome_paper_selector_get_top_margin (gspaper)
	Gnome::PaperSelector	gspaper

gfloat
gnome_paper_selector_get_bottom_margin (gspaper)
	Gnome::PaperSelector	gspaper

void
gnome_paper_selector_set_name (gspaper, name)
	Gnome::PaperSelector	gspaper
	char *	name

void
gnome_paper_selector_set_width (gspaper, width)
	Gnome::PaperSelector	gspaper
	gfloat	width

void
gnome_paper_selector_set_height (gspaper, height)
	Gnome::PaperSelector	gspaper
	gfloat	height

#endif

