
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "PerlGtkInt.h"

#include "GtkDefs.h"
#include "GnomeDefs.h"


MODULE = Gnome::Stock		PACKAGE = Gnome::Stock		PREFIX = gnome_stock_

#ifdef GNOME_STOCK

Gnome::Stock_Sink
new(Class)
	SV*	Class
	CODE:
	RETVAL = (GnomeStock*)(gnome_stock_new());
	OUTPUT:
	RETVAL

Gnome::Stock_Sink
new_with_icon(Class, icon)
	SV*	Class
	char*	icon
	CODE:
	RETVAL = (GnomeStock*)(gnome_stock_new_with_icon(icon));
	OUTPUT:
	RETVAL

bool
gnome_stock_set_icon(stock, icon)
	Gnome::Stock	stock
	char*	icon

Gnome::Stock_Sink
gnome_stock_pixmap_widget (Class, window, icon)
	SV *	Class
	Gtk::Widget	window
	char *	icon
	CODE:
	RETVAL = (GnomeStock*)(gnome_stock_pixmap_widget(window, icon));
	OUTPUT:
	RETVAL

Gnome::Stock_Sink
gnome_stock_pixmap_widget_at_size (Class, window, icon, width, height)
	SV *	Class
	Gtk::Widget	window
	char *	icon
	unsigned int	width
	unsigned int	height
	CODE:
	RETVAL = (GnomeStock*)(gnome_stock_pixmap_widget_at_size(window, icon, width, height));
	OUTPUT:
	RETVAL

Gtk::Button_Sink
gnome_pixmap_button(Class, pixmap, text)
	SV *	Class
	Gtk::Widget_OrNULL	pixmap
	char *	text
	CODE:
	RETVAL = (GtkButton*)(gnome_pixmap_button(pixmap, text));
	OUTPUT:
	RETVAL

Gtk::Button_Sink
gnome_stock_button (Class, type)
	SV *	Class
	char *	type
	CODE:
	RETVAL = (GtkButton*)(gnome_stock_button(type));
	OUTPUT:
	RETVAL

Gtk::Button_Sink
gnome_stock_or_ordinary_button (Class, type)
	SV *	Class
	char *	type
	CODE:
	RETVAL = (GtkButton*)(gnome_stock_or_ordinary_button(type));
	OUTPUT:
	RETVAL

Gtk::MenuItem_Sink
gnome_stock_menu_item (Class, type, text)
	SV *	Class
	char *	type
	char *	text
	CODE:
	RETVAL = (GtkMenuItem*)(gnome_stock_menu_item(type, text));
	OUTPUT:
	RETVAL

void
gnome_stock_menu_accel (Class, type)
	SV *	Class
	char *	type
	PPCODE:
	{
		gboolean result;
		guchar	key;
		guint8	mod;
		result = gnome_stock_menu_accel(type, &key, &mod);
		EXTEND(sp, 3);
		PUSHs(sv_2mortal(newSViv(result)));
		/* return symbolic names? */
		PUSHs(sv_2mortal(newSViv(key)));
		PUSHs(sv_2mortal(newSViv(mod)));
	}

void
gnome_stock_menu_accel_parse (Class, section)
	SV *	Class
	char *	section
	CODE:
	gnome_stock_menu_accel_parse (section);

Gtk::Window_Sink
gnome_stock_transparent_window (Class, icon, subtype)
	SV *	Class
	char *	icon
	char *	subtype
	CODE:
	RETVAL = GTK_WINDOW(gnome_stock_transparent_window (icon, subtype));
	OUTPUT:
	RETVAL

void
gnome_stock_pixmap_gdk (Class, icon, subtype)
	SV *	Class
	char *	icon
	char *	subtype
	PPCODE:
	{
		GdkPixmap * pixmap = NULL;
		GdkBitmap * mask = NULL;
		gnome_stock_pixmap_gdk (icon, subtype, &pixmap, &mask);
		if (pixmap) {
			EXTEND(sp,1);
			PUSHs(sv_2mortal(newSVGdkPixmap(pixmap)));
		}
		if (mask) {
			EXTEND(sp,1);
			PUSHs(sv_2mortal(newSVGdkBitmap(mask)));
		}
	}

#endif

