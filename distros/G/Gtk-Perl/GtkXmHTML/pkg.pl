
print "XmHTML...\n";

add_c 'GXHTypes.c';

add_pm 'GtkXmHTML.pm' => '$(INST_LIBDIR)/Gtk/XmHTML.pm';

add_defs 'pkg.defs';
add_typemap 'pkg.typemap';

add_headers (qw( <gtk-xmhtml/gtk-xmhtml.h> "GXHTypes.h"));

$gtkxmhtmllibs = `gnome-config --libs gtkxmhtml` || $ENV{GTKXMHTML_LIBS};

$libs = "$libs $gtkxmhtmllibs";
chomp($libs);
