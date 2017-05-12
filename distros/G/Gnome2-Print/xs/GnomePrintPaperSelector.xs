#include "gnomeprintperl.h"

MODULE = Gnome2::Print::PaperSelector PACKAGE = Gnome2::Print::PaperSelector PREFIX = gnome_paper_selector_


GtkWidget *
gnome_paper_selector_news (class, config, flags=0)
	GnomePrintConfig *config
	gint flags
    ALIAS:
	Gnome2::Print::PaperSelector::new = 0
	Gnome2::Print::PaperSelector::new_with_flags = 1
    CODE:
    	switch (ix) {
		case 1: 
			RETVAL = gnome_paper_selector_new (config);
			break;
		case 0: 
			RETVAL = gnome_paper_selector_new_with_flags (config, flags);
			break;

		default: RETVAL = NULL;
	}
    OUTPUT:
    	RETVAL
