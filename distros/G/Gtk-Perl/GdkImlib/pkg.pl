
add_defs 'pkg.defs';
add_typemap 'pkg.typemap';

add_xs qw( GdkImlib.xs );

# we need to know what libraries are used by the
# gdk_imlib lib we are going to link to....

$gdkimlibs = `imlib-config --libs-gdk` || "-lgdk_imlib -lgdk -rdynamic -lgmodule -lglib -lz";

$libs = "$libs $gdkimlibs";
chomp($libs);

add_boot "Gtk::Gdk::ImlibImage";

add_headers '"GdkImlibTypes.h"';
