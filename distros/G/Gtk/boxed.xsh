	
MODULE = Gtk	PACKAGE = Gtk::Gdk::Bitmap

void
DESTROY(self)
	Gtk::Gdk::Bitmap	self
	CODE:
	UnregisterMisc((HV*)SvRV(ST(0)), (void*)self);
	gdk_window_unref(self);

	
MODULE = Gtk	PACKAGE = Gtk::Gdk::Colormap

void
DESTROY(self)
	Gtk::Gdk::Colormap	self
	CODE:
	UnregisterMisc((HV*)SvRV(ST(0)), (void*)self);
	gdk_colormap_unref(self);

	
MODULE = Gtk	PACKAGE = Gtk::Gdk::Font

void
DESTROY(self)
	Gtk::Gdk::Font	self
	CODE:
	UnregisterMisc((HV*)SvRV(ST(0)), (void*)self);
	gdk_font_unref(self);

	
MODULE = Gtk	PACKAGE = Gtk::Gdk::Pixmap

void
DESTROY(self)
	Gtk::Gdk::Pixmap	self
	CODE:
	UnregisterMisc((HV*)SvRV(ST(0)), (void*)self);
	gdk_window_unref(self);

	
MODULE = Gtk	PACKAGE = Gtk::Gdk::Visual

void
DESTROY(self)
	Gtk::Gdk::Visual	self
	CODE:
	UnregisterMisc((HV*)SvRV(ST(0)), (void*)self);
	gdk_visual_unref(self);

	
MODULE = Gtk	PACKAGE = Gtk::Gdk::Window

void
DESTROY(self)
	Gtk::Gdk::Window	self
	CODE:
	UnregisterMisc((HV*)SvRV(ST(0)), (void*)self);
	gdk_window_unref(self);

	
MODULE = Gtk	PACKAGE = Gtk::AcceleratorTable

void
DESTROY(self)
	Gtk::AcceleratorTable	self
	CODE:
	UnregisterMisc((HV*)SvRV(ST(0)), (void*)self);
	gtk_accelerator_table_unref(self);

	
MODULE = Gtk	PACKAGE = Gtk::Style

void
DESTROY(self)
	Gtk::Style	self
	CODE:
	UnregisterMisc((HV*)SvRV(ST(0)), (void*)self);
	gtk_style_unref(self);

