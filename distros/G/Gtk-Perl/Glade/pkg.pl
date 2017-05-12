
if (`libglade-config --version`) {
	my ($gnome, $version);

	$version = `libglade-config --version`;
	if ($version =~ /(\d+)\.(\d+)(\.(\d+))?/) {
		push @defines, "-DGLADE_HVER=" . sprintf("0x%02x%02x%02x", $1, $2, $4?$4:0);
	}
	if (exists $defaultpack{'gnome'}) {
		$gnome = "gnome";
		print "Glade with gnome support\n";
	} else {
		$gnome = '';
		print "Glade\n";
	}

	add_defs 'pkg.defs';
	add_typemap 'pkg.typemap';

	add_xs  'GladeXML.xs';
	#add_boot 'Gtk::GladeXML';
	add_pm 'GladeXML.pm' => '$(INST_LIBDIR)/Gtk/GladeXML.pm';

	add_headers "<glade/glade.h>";

	$libs .= " " . `libglade-config --libs $gnome`;
	chomp($libs);
	$inc .= " " . `libglade-config --cflags $gnome`;
	chomp($inc);
} else {
	print "Cannot find libglade\n";
}

