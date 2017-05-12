package Gtk::MozEmbed;

require Gtk;
require Exporter;
require DynaLoader;

$VERSION = "0.7010";

@ISA = (@ISA, qw(Exporter DynaLoader));
# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.
@EXPORT = qw(
	
);
# Other items we are prepared to export if requested
@EXPORT_OK = qw(
);

package Gtk::MozEmbed;

#sub dl_load_flags {Gtk::dl_load_flags()}
#push @DynaLoader::dl_resolve_using, '/home/lupus/opt/gnome/gnome-perl/blib/arch/auto/Gtk/Gtk.so';

bootstrap Gtk::MozEmbed;

require Gtk::MozEmbed::Types;

# Autoload methods go after __END__, and are processed by the autosplit program.

1;
__END__
