use ExtUtils::MakeMaker;
use Config;
use File::Basename;
use blib '..';
use blib '../Gnome';
use blib '../GdkImlib';
use Cwd;
require '../Depends.pm';
require '../tools/gendefs.pl';

$gp = new ExtUtils::Depends ('Gnome::Applet', 'Gtk', 'Gtk::Gdk::ImlibImage', 'Gnome');

mkdir('build', 0777);

$gp->set_inc (`gnome-config --cflags docklets applets capplet`);
$gp->set_libs (`gnome-config --libs docklets applets capplet`);

$gp->add_typemaps (cwd() . '/pkg.typemap', cwd().'/build/GnomeAppletTypemap');

$gp->save_config('build/Files.pm');
$gp->install('build/Files.pm');

$gp->add_pm('GnomeApplet.pm' => '$(INST_ARCHLIBDIR)/Applet.pm',
	'build/GnomeAppletTypes.pm' => '$(INST_ARCHLIBDIR)/Applet/Types.pm');

$gp->add_xs ('xs/Applet.xs');
$gp->add_c ('build/GnomeAppletDefs.c');
$gp->add_defs ('pkg.defs');
$gp->add_headers (qw( <applet-widget.h> <capplet-widget.h> <status-docklet.h>));

#$gp->add_xs ('xs/GnomeApplet.xs');

@a = (	'-f', 'GnomeApplet', 
		'-p', 'Gtk=Gtk',
		'-p', 'GdkGL=Gtk::Gdk::GL',
		'-p', 'GdkRgb=Gtk::Gdk::Rgb',
		'-p', 'Gdk=Gtk::Gdk',
		'-p', 'Gnome=Gnome',
		'-p', 'Panel=Gnome::Panel',
		'-m', 'Gnome::Applet');

foreach ($gp->get_defs) {
	push @a, '-d', $_;
}
foreach ($gp->get_headers) {
	push @a, '-i', $_;
}

$gp->add_xs(gendefs::gendefs(@a));

$depend = { 'build/GnomeAppletDefs.c' => 'build/GnomeAppletDefs.h build/PerlGnomeAppletInt.h' };

foreach (qw( build/GnomeAppletDefs.h build/PerlGnomeAppletInt.h)) {
	$gp->add_pm($_, '$(INST_ARCHLIBDIR)/Applet/Install/'. basename($_));
}

$gp->write_ext("build/extension.xsh");

$gp->add_clean( qw(
	build/Files.pm build/GnomeAppletDefs.c build/GnomeAppletDefs.h 
	build/GnomeAppletDefs.o build/GnomeAppletTypemap build/GnomeAppletTypes.pm 
	build/PerlGnomeAppletExt.c build/PerlGnomeAppletExt.h build/PerlGnomeAppletInt.h 
	build/boxed.xsh build/extension.xsh build/objects.xsh
	build/perl-gnomeapplet-ds.pod  build/perl-gnomeapplet-ref.xml
));

# documentation
gendefs::gen_doc('gnomeapplet');
system($Config{perlpath}, "../tools/gendoc.pl", "-t", 'gnomeapplet', $gp->get_xs);
system($Config{perlpath}, "../tools/gpdoc2pod", "-t", 'GnomeApplet');

WriteMakefile(
	'NAME'      => 'Gnome::Applet',
	'VERSION_FROM'	=> 'GnomeApplet.pm',
	'XSOPT' => '-noversioncheck',
	'dist' => { COMPRESS=>"gzip", SUFFIX=>"gz" },
	'clean' => {FILES => join(' ', @clean) },
	'MAN3PODS' => {
		'build/perl-gnomeapplet-ref.pod' => '$(INST_MAN3DIR)/Gnome::Applet::reference.3pm',
		},
	$gp->get_makefile_vars,
);

sub MY::postamble {

'
Makefile: ' . join(' ',
	$gp->get_defs,
	<*/pkg*.pl>
	) . '

build/PerlGnomeAppletExt.h build/PerlGnomeAppletExt.c build/PerlGnomeAppletInt.h: build/GnomeAppletDefs.h ../tools/genext.pl
	$(PERL) ../tools/genext.pl GnomeApplet </dev/null

gendoc:
	$(PERL) ../tools/gendoc.pl -t gnomeapplet $(XS_FILES)

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

