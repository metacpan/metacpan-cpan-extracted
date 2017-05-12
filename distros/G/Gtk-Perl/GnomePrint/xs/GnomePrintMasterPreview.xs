
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "PerlGnomePrintInt.h"

#include "GnomePrintDefs.h"

MODULE = Gnome::PrintMasterPreview		PACKAGE = Gnome::PrintMasterPreview		PREFIX = gnome_print_master_preview_

#ifdef GNOME_PRINT_MASTER_PREVIEW

Gnome::PrintMasterPreview_Sink
gnome_print_master_preview_new (Class, gpm, title)
	SV	*Class
	Gnome::PrintMaster	gpm
	char*	title
	CODE:
	RETVAL = (GnomePrintMasterPreview*)(gnome_print_master_preview_new(gpm, title));
	OUTPUT:
	RETVAL

Gnome::PrintMasterPreview_Sink
gnome_print_master_preview_new_with_orientation (Class, gpm, title, landscape)
	SV	*Class
	Gnome::PrintMaster	gpm
	char*	title
	bool	landscape
	CODE:
	RETVAL = (GnomePrintMasterPreview*)(gnome_print_master_preview_new_with_orientation(gpm, title, landscape));
	OUTPUT:
	RETVAL



#endif

