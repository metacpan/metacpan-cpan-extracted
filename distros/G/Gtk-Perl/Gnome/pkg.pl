
add_defs "pkg.defs";
add_typemap "pkg.typemap";

add_xs qw( Gnome.xs GnomeDialogUtil.xs GnomeDNS.xs GnomeGeometry.xs GnomeICE.xs);
# add_headers "<argp.h>", "<libgnome/libgnome.h>", "<libgnomeui/libgnomeui.h>", '"GnomeTypes.h"';
add_headers "<libgnome/libgnome.h>", "<libgnomeui/libgnomeui.h>", '"GnomeTypes.h"';
add_boot "Gnome", "Gnome::DialogUtil", "Gnome::DNS", "Gnome::Geometry", "Gnome::ICE";

add_pm 'Gnome.pm' => '$(INST_LIBDIR)/Gnome.pm';

# use gnomeConf.sh...
$inc = $ENV{GNOME_INCLUDEDIR} . " " . $inc;
$libs = "$libs -L$ENV{GNOME_LIBDIR} $ENV{GNOMEUI_LIBS}"; #hack hack

print "Got libs='$libs' (gn: $ENV{GNOMEUI_LIBS})\n";

$gnome_version = `gnome-config --version`;
if ( $gnome_version =~ /(\d+)\.(\d+)\.(\d+)/) {
	$gnome_major = $1;
	$gnome_minor = $2;
	$gnome_micro = $3;
} else {
	$gnome_major = $gnome_minor = $gnome_micro = 0;
}

$gnome_hverstr = sprintf("0x%02x%02x%02x", $gnome_major, $gnome_minor, $gnome_micro);

push @defines, "-DGNOME_HVER=$gnome_hverstr";

# fixme
if ($gnome_major >= 1 && $gnome_minor >= 0 && $gnome_micro >= 50) {
	print "Got October Gnome!\n";
	do "Gnome/gnome-october.pl";
} else {
	print "Got no October Gnome!\n";
}
