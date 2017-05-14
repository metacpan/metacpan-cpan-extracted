use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

$libs = `gtk-config --libs`;
$libs = "-L/usr/X11R6/lib -lgtk -lgdk -lglib -lX11 -lXext" if not defined $libs;
@L = (LIBS => [$libs]);

$inc = `gtk-config --cflags`;
if (defined $inc) {
	@I = (INC => $inc);
} else {
	@I = (); #e.g, INC => -I/usr/other/include
}

$object = 'Gtk.o GtkDefs.o GtkTypes.o GdkTypes.o MiscTypes.o ' .  (do 'Objects.xpl');
$typemap = ["typemap.gtk"];
$pm = {'Gdk.pm' => '$(INST_LIBDIR)/Gtk/Gdk.pm',
	'Gtk.pm' => '$(INST_LIBDIR)/Gtk.pm',
	'GtkTypes.pm' => '$(INST_LIBDIR)/Gtk/Types.pm',
	'Atoms.pm' => '$(INST_LIBDIR)/Gtk/Atoms.pm'
};

open (EXT, ">extension.xsh");
print EXT "BOOT:\n{\n";

if (grep {/--with-gdkimlib/} @ARGV) {
	$object .= 'GdkImlib.o';
	push(@$typemap, 'typemap.gdkimlib');
	foreach (@$libs) {
		# we need to know what libraries are used by the
		# gdk_imlib lib we are going to link to....
		s/-l/-lgdk_imlib -lgif -ltiff -lpng -ljpeg -lz -l/; # hack hack
	}
	print EXT "callXS (boot_Gtk__Gdk__ImlibImage, cv, mark);\n";
}

if (grep {/--with-gnome/} @ARGV) {
	$object .= 'Gnome.o';
	push(@$typemap, 'typemap.gnome');
	$pm->{'Gnome.pm'} = '$(INST_LIBDIR)/Gnome.pm';
	# use gnomeConfig.sh...
	foreach (@$libs) {
		s/-l/-lgnome -lgnomeui -l/; #hack hack
	}
}

print EXT "}\n";
close(EXT);

WriteMakefile(
    'NAME'	=> 'Gtk',
    'VERSION'	=> '0.1.16',
    'PM' => $pm,
    'TYPEMAPS' => $typemap,
    'XSOPT' => '-noversioncheck',
    'DEFINE'	=> '',     # e.g., '-DHAVE_SOMETHING' 
    'OBJECT' => $object,
	'XSPROTOARG' => '-noprototypes',
	@I,
	@L
);
