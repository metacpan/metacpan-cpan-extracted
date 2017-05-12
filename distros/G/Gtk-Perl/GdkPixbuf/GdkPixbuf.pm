
package Gtk::Gdk::Pixbuf;

require Gtk;
require Exporter;
require DynaLoader;
require Gtk::Gdk::Pixbuf::Types;

$VERSION = "0.7010";

@ISA = qw(Exporter DynaLoader);
@EXPORT = qw();
@EXPORT_OK = qw();

sub dl_load_flags {Gtk::dl_load_flags()}

bootstrap Gtk::Gdk::Pixbuf;

Gtk->mod_init_add('Gtk', sub {
	init Gtk::Gdk::Rgb;
	init Gtk::Gdk::Pixbuf;
});

#Gtk->mod_init_add('Gnome', sub {
#	my $libname = DynaLoader::dl_findfile("libgnomecanvaspixbuf");
#	return unless $libname;
#	my $libref = DynaLoader::dl_load_file($libname, 1);
#	return unless $libname;
#	my $symbol = DynaLoader::dl_find_symbol($libref, "gnome_canvas_pixbuf_get_type");
#	return unless $symbol;
#	my $parent = Gtk::Object->_register('Gnome::CanvasPixbuf', $symbol);
#	return unless $parent;
#	@Gnome::CanvasPixbuf = $parent;
#});

1;
