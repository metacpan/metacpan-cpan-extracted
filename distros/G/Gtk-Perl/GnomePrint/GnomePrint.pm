
package Gnome::Print;

require Gtk;
require Gtk::Gdk::ImlibImage;
require Gtk::Gdk::Pixbuf;
require Gnome;
require Exporter;
require DynaLoader;

$VERSION = "0.7010";

@ISA = qw(Exporter DynaLoader);
# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.
@EXPORT = qw(
        
);
# Other items we are prepared to export if requested
@EXPORT_OK = qw(
);

sub dl_load_flags {Gtk::dl_load_flags()}

bootstrap Gnome::Print $VERSION;

if ($Gnome::Print::lazy) {
	require Gnome::Print::TypesLazy;
} else {
	require Gnome::Print::Types;
	&Gnome::Print::_boot_all();
}

# Autoload methods go after __END__, and are processed by the autosplit program.

Gtk->mod_init_add('Gnome', sub {
	init Gnome::Print;
});

1;
__END__
