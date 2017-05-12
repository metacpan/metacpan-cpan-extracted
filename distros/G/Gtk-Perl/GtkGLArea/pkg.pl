
print "GtkGL\n";

add_defs 'pkg.defs';
add_typemap 'pkg.typemap';

add_xs  'GtkGdkGL.xs', 'Constants.xs';
add_boot 'Gtk::Gdk::GL', 'Gtk::GLArea::Constants';

add_headers "<gtkgl/gtkglarea.h>", "<gtkgl/gdkgl.h>"; #, "<GL/gl.h>", "<GL/glu.h>";

add_pm 'Constants.pm' => '$(INST_LIBDIR)/Gtk/GLArea/Constants.pm',
	'Glut.pm' => '$(INST_LIBDIR)/Gtk/GLArea/Glut.pm';

$libs =~ s/-l/-lgtkgl -lMesaGL -lMesaGLU -l/; #hack hack
