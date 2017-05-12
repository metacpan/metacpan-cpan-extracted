sub d_do {
#	undef $@; undef $!;
	do $_[0];
#	die("Error: $@  or  $!  when executing $_[0]") if $@ or $!;
}

add_pm 'Gdk.pm' => '$(INST_LIBDIR)/Gtk/Gdk.pm',
	   'Gtk.pm' => '$(INST_LIBDIR)/Gtk.pm',
	   'Atoms.pm' => '$(INST_LIBDIR)/Gtk/Atoms.pm',
	   'GtkColorSelectButton.pm' => '$(INST_LIBDIR)/Gtk/ColorSelectButton.pm',
	   'LogHandler.pm' => '$(INST_LIBDIR)/Gtk/LogHandler.pm';

add_c qw(GdkTypes.c   GtkTypes.c   MiscTypes.c Derived.c);
add_xs "Gtk.xs";

if ($gtk_major == 0) {

	if ($gtk_minor < 99 or $gtk_micro < 10) {
		die "Gtk+ <= 0.99.10 is not supported by this package.\n";
	} else {

		print "0.99\n";
		d_do "Gtk/gtk-0.99.pl";
		print "0.99-only\n";
		d_do "Gtk/gtk-0.99-only.pl";
	
	}

} elsif ($gtk_major == 1) {

	if ($gtk_minor == 0) {

		print "0.99\n";
		d_do "Gtk/gtk-0.99.pl";
		print "1.0\n";
		d_do "Gtk/gtk-1.0.pl";
		print "1.0-only\n";
		d_do "Gtk/gtk-1.0-only.pl";

	} elsif ($gtk_minor == 1) {

		print "0.99\n";
		d_do "Gtk/gtk-0.99.pl";
		print "1.0\n";
		d_do "Gtk/gtk-1.0.pl";
		print "1.1\n";
		d_do "Gtk/gtk-1.1.pl";
		
		if ($gtk_micro >= 1) {
			print "1.1.1\n";
			d_do "Gtk/gtk-1.1.1.pl";
		}

		if ($gtk_micro >= 3) {
			print "1.1.3\n";
			d_do "Gtk/gtk-1.1.3.pl";
		}
		
		if ($gtk_micro >= 4) {
			print "1.1.4\n";
			d_do "Gtk/gtk-1.1.4.pl";
		}

		if ($gtk_micro >= 6) {
			print "1.1.6\n";
			d_do "Gtk/gtk-1.1.6.pl";
		}
		print "1.1-only\n";
		d_do "Gtk/gtk-1.1-only.pl";
	} elsif ($gtk_minor == 2) {
		print "0.99\n";
		d_do "Gtk/gtk-0.99.pl";
		print "1.0\n";
		d_do "Gtk/gtk-1.0.pl";
		print "1.1\n";
		d_do "Gtk/gtk-1.1.pl";
		print "1.1.1\n";
		d_do "Gtk/gtk-1.1.1.pl";
		print "1.1.3\n";
		d_do "Gtk/gtk-1.1.3.pl";
		print "1.1.4\n";
		d_do "Gtk/gtk-1.1.4.pl";
		print "1.1.6\n";
		d_do "Gtk/gtk-1.1.6.pl";
		print "1.2\n";
		d_do "Gtk/gtk-1.2.pl";
	} elsif ($gtk_minor == 3) {
		print "0.99\n";
		d_do "Gtk/gtk-0.99.pl";
		print "1.0\n";
		d_do "Gtk/gtk-1.0.pl";
		print "1.1\n";
		d_do "Gtk/gtk-1.1.pl";
		print "1.1.1\n";
		d_do "Gtk/gtk-1.1.1.pl";
		print "1.1.3\n";
		d_do "Gtk/gtk-1.1.3.pl";
		print "1.1.4\n";
		d_do "Gtk/gtk-1.1.4.pl";
		print "1.1.6\n";
		d_do "Gtk/gtk-1.1.6.pl";
		print "1.2\n";
		d_do "Gtk/gtk-1.2.pl";
		print "1.3\n";
		d_do "Gtk/gtk-1.3.pl";
	} 

} elsif ($gtk_major >= 2) {
	die "I don't know where you got a version higher than 1.3 of gtk+\n";
}

