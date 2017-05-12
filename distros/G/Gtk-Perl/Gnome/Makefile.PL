use ExtUtils::MakeMaker;
use Config;
use blib '../Gtk';
use blib '../GdkImlib';
use Cwd;
require '../Depends.pm';
require '../tools/gendefs.pl';

mkdir('build', 0777);

$gnome = new ExtUtils::Depends('Gnome', 'Gtk', 'Gtk::Gdk::ImlibImage');

$gnome->set_inc (`gnome-config --cflags gnomeui zvt`);
$gnome->set_libs (`gnome-config --libs gnomeui zvt`);

$gnome->add_typemaps (cwd() . '/pkg.typemap', cwd().'/build/GnomeTypemap');
#$gnome->add_headers (qw("GnomeDefs.h"));

$gnome_version = `gnome-config --version`;
if ( $gnome_version =~ /(\d+)\.(\d+)\.(\d+)/) {
	$gnome_major = $1;
	$gnome_minor = $2;
	$gnome_micro = $3;
} else {
	$gnome_major = $gnome_minor = $gnome_micro = 0;
}

$gnome_hverstr = sprintf("0x%02x%02x%02x", $gnome_major, $gnome_minor, $gnome_micro);
if ($gnome_major > 1 || ($gnome_major == 1 && $gnome_minor >= 1) || ($gnome_major == 1 && $gnome_micro >= 50)) {
	print "Using october gnome release\n";
	$gnome->add_defs ('gnome-october.defs');
}

if (grep {/--with-panel/} @ARGV) {
	do 'pkg-panel.pl';
}
$gnome->add_defines("-DGNOME_HVER=$gnome_hverstr");
$gnome->save_config('build/Files.pm');
$gnome->install('build/Files.pm');

$gnome->add_pm ('Gnome.pm' => '$(INST_ARCHLIBDIR)/Gnome.pm',
	'build/GnomeTypes.pm' => '$(INST_ARCHLIBDIR)/Gnome/Types.pm',
	'build/GnomeTypesLazy.pm' => '$(INST_ARCHLIBDIR)/Gnome/TypesLazy.pm',
	);

$gnome->add_c ('build/GnomeDefs.c');
$gnome->add_defs ('pkg.defs', 'pkg-zvt.defs');
$gnome->add_headers (qw( <zvt/zvtterm.h> <libgnome/libgnome.h> <libgnomeui/libgnomeui.h> "GnomeTypes.h" ));

$gnome->add_xs ('xs/Gnome.xs', 'xs/GnomeDialogUtil.xs', 'xs/GnomeDNS.xs', 
	'xs/GnomeGeometry.xs', 'xs/GnomeICE.xs');

@a = (	'-f', 'Gnome', 
		'-p', 'Gtk=Gtk',
		'-p', 'GdkGL=Gtk::Gdk::GL',
		'-p', 'GdkRgb=Gtk::Gdk::Rgb',
		'-p', 'Gdk=Gtk::Gdk',
		'-p', 'Gnome=Gnome',
		'-p', 'Panel=Gnome::Panel',
		'-m', 'Gnome');

foreach ($gnome->get_defs) {
	push @a, '-d', $_;
}
foreach ($gnome->get_headers) {
	push @a, '-i', $_;
}

$gnome->add_xs(gendefs::gendefs('-L', @a));

$depend = { 'build/GnomeDefs.c' => 'build/GnomeDefs.h build/PerlGnomeInt.h' };

$gnome->add_boot("Gnome::DialogUtil", "Gnome::DNS", "Gnome::Geometry", "Gnome::ICE");
$gnome->install (qw(build/GnomeDefs.h build/PerlGnomeInt.h));
$gnome->write_ext('build/extension.xsh');

$gnome->add_clean ( qw(
	build/Files.pm build/GnomeDefs.c build/GnomeDefs.h build/GnomeDefs.o 
	build/GnomeTypemap build/GnomeTypes.pm build/PerlGnomeExt.c 
	build/PerlGnomeExt.h build/PerlGnomeInt.h build/boxed.xsh 
	build/extension.xsh build/objects.xsh build/perl-gnome-ds.pod 
	build/perl-gnome-ref.xml
));

# documentation
gendefs::gen_doc('gnome');
system($Config{perlpath}, "../tools/gendoc.pl", "-t", 'gnome', $gnome->get_xs);
system($Config{perlpath}, "../tools/gpdoc2pod", "-t", 'Gnome');

WriteMakefile(
	'NAME'      => 'Gnome',
	'VERSION_FROM'	=> 'Gnome.pm',
	'XSOPT' => '-noversioncheck',
	'DEFINE'    => join(' ',@defines),
	'dist' => { COMPRESS=>"gzip", SUFFIX=>"gz" },
	'OPTIMIZE' => '-O2 -g',
	'depend' => $depend,
	'MAN3PODS' => {
		'build/perl-gnome-ref.pod' => '$(INST_MAN3DIR)/Gnome::reference.3pm',
		'Gnome.pm' => '$(INST_MAN3DIR)/Gnome.3pm',
		},
	$gnome->get_makefile_vars,
);

sub MY::postamble {

'
Makefile: ' . join(' ',
	sort {$defs{$a} <=> $defs{$b}} keys %defs,
	<*/pkg*.pl>
	) . '

build/PerlGnomeExt.h build/PerlGnomeExt.c build/PerlGnomeInt.h: build/GnomeDefs.h ../tools/genext.pl
	$(PERL) ../tools/genext.pl Gnome </dev/null

gendoc:
	$(PERL) ../tools/gendoc.pl -t gnome $(XS_FILES)

';



}

sub MY::c_o {
	package MY; # so that "SUPER" works right
	my $inherited = shift->SUPER::c_o(@_);
	$inherited =~ s/CCCMD.*$/$&\n\t\@if test -f `basename \$*.o` -a "`basename \$*.o`" != "\$*.o"; then mv `basename \$*.o` \$*.o; fi/mg;
    $inherited;
}

sub MY::const_config
{
	package MY;
	my $self = shift;
	my $flags = $self->{'CCCDLFLAGS'};
	$flags =~ s/(-[fK]?\s*)pic\b/${1}PIC/;
	$self->{'CCCDLFLAGS'} = $flags;
	return $self->SUPER::const_config;
}

	
