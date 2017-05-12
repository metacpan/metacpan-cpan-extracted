
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "PerlGnomePrintInt.h"

#include "GtkDefs.h"
#include "GnomePrintDefs.h"

MODULE = Gnome::PrintMeta		PACKAGE = Gnome::PrintMeta		PREFIX = gnome_print_meta_

#ifdef GNOME_PRINT_META

Gnome::PrintMeta
gnome_print_meta_new (Class)
	SV	*Class
	CODE:
	RETVAL = (GnomePrintMeta*)(gnome_print_meta_new());
	OUTPUT:
	RETVAL

# missing buffer stuff

int
gnome_print_meta_pages (meta)
	Gnome::PrintMeta	meta

SV*
gnome_print_meta_access_buffer (meta)
	Gnome::PrintMeta	meta
	CODE:
	{
		void *data;
		int len;
		gnome_print_meta_access_buffer (meta, &data, &len);
		sv_setpvn(RETVAL, data, len);
	}
	OUTPUT:
	RETVAL

MODULE = Gnome::PrintMeta		PACKAGE = Gnome::PrintContext		PREFIX = gnome_print_meta_

bool
gnome_print_meta_render_from_object (context, source)
	Gnome::PrintContext	context
	Gnome::PrintMeta	source

bool
gnome_print_meta_render_from_object_page (context, source, page)
	Gnome::PrintContext	context
	Gnome::PrintMeta	source
	int	page


#endif

