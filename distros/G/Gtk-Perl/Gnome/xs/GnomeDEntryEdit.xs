
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "GtkDefs.h"
#include "GnomeDefs.h"


MODULE = Gnome::DEntryEdit		PACKAGE = Gnome::DEntryEdit		PREFIX = gnome_dentry_edit_

#ifdef GNOME_DENTRY_EDIT

MODULE = Gnome::DEntryEdit		PACKAGE = Gtk::Notebook

Gnome::DEntryEdit
gnome_dentry_edit_new_notebook(notebook)
	Gtk::Notebook	notebook
	CODE:
#if GNOME_HVER >= 0x010200
	RETVAL = (GnomeDEntryEdit*)(gnome_dentry_edit_new_notebook(notebook));
#else
	RETVAL = (GnomeDEntryEdit*)(gnome_dentry_edit_new(notebook));
#endif
	OUTPUT:
	RETVAL

MODULE = Gnome::DEntryEdit		PACKAGE = Gnome::DEntryEdit		PREFIX = gnome_dentry_edit_

Gnome::DEntryEdit
gnome_dentry_edit_new(notebook=0)
	Gtk::Notebook	notebook
	ALIAS:
		Gnome::DEntryEdit::new = 0
		Gnome::DEntryEdit::new_notebook = 1
	CODE:
#if GNOME_HVER >= 0x010200
	RETVAL = (GnomeDEntryEdit*)(gnome_dentry_edit_new());
#else
	RETVAL = (GnomeDEntryEdit*)(gnome_dentry_edit_new(notebook));
#endif
	OUTPUT:
	RETVAL

void
gnome_dentry_edit_clear(dee)
	Gnome::DEntryEdit	dee

void
gnome_dentry_edit_load_file(dee, path)
	Gnome::DEntryEdit	dee
	char *	path

void
gnome_dentry_edit_set_dentry(dee, dentry)
	Gnome::DEntryEdit	dee
	Gnome::DesktopEntry	dentry

Gnome::DesktopEntry
gnome_dentry_get_dentry(dee)
	Gnome::DEntryEdit	dee

char *
gnome_dentry_edit_get_icon(dee)
	Gnome::DEntryEdit	dee

char *
gnome_dentry_edit_get_name(dee)
	Gnome::DEntryEdit	dee

#endif

