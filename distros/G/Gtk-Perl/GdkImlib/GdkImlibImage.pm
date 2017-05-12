

package Gtk::Gdk::ImlibImage;

require Gtk;
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

# Autoload methods go after __END__, and are processed by the autosplit program.

sub dl_load_flags {Gtk::dl_load_flags()}

bootstrap Gtk::Gdk::ImlibImage;

Gtk->mod_init_add('Gtk', sub {
	init Gtk::Gdk::ImlibImage;
});

1;
__END__
