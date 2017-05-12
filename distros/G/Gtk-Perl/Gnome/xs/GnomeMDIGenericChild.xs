
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "PerlGtkInt.h"

#include "GtkDefs.h"
#include "GnomeDefs.h"

/*#include "MiscTypes.h"*/

extern void pgtk_generic_handler(GtkObject * object, gpointer data, guint n_args, GtkArg * args);
extern void pgtk_destroy_handler(gpointer data);

MODULE = Gnome::MDIGenericChild		PACKAGE = Gnome::MDIGenericChild		PREFIX = gnome_mdi_generic_child_

#ifdef GNOME_MDI_GENERIC_CHILD

Gnome::MDIGenericChild_Sink
new (Class, name)
	SV *	Class
	char *	name
	CODE:
	RETVAL = (GnomeMDIGenericChild*)(gnome_mdi_generic_child_new(name));
	OUTPUT:
	RETVAL

void
gnome_mdi_generic_child_set_view_creator (mdi_child, handler, ...)
	Gnome::MDIGenericChild	mdi_child
	SV *	handler
	CODE:
	{
		AV * args;

		args = newAV();
		PackCallbackST(args, 1);
		gnome_mdi_generic_child_set_view_creator_full (mdi_child, NULL, 
			pgtk_generic_handler, (gpointer)args, pgtk_destroy_handler);
	}

void
gnome_mdi_generic_child_set_menu_creator (mdi_child, handler, ...)
	Gnome::MDIGenericChild	mdi_child
	SV *	handler
	CODE:
	{
		AV * args;

		args = newAV();
		PackCallbackST(args, 1);
		gnome_mdi_generic_child_set_menu_creator_full (mdi_child, NULL, 
			pgtk_generic_handler, (gpointer)args, pgtk_destroy_handler);
	}

void
gnome_mdi_generic_child_set_config_func (mdi_child, handler, ...)
	Gnome::MDIGenericChild	mdi_child
	SV *	handler
	CODE:
	{
		AV * args;

		args = newAV();
		PackCallbackST(args, 1);
		gnome_mdi_generic_child_set_config_func_full (mdi_child, NULL, 
			pgtk_generic_handler, (gpointer)args, pgtk_destroy_handler);
	}

void
gnome_mdi_generic_child_set_label_func (mdi_child, handler, ...)
	Gnome::MDIGenericChild	mdi_child
	SV *	handler
	CODE:
	{
		AV * args;

		args = newAV();
		PackCallbackST(args, 1);
		gnome_mdi_generic_child_set_label_func_full (mdi_child, NULL, 
			pgtk_generic_handler, (gpointer)args, pgtk_destroy_handler);
	}


#endif

