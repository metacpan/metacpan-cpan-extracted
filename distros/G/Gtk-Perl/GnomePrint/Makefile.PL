use ExtUtils::MakeMaker;
use Config;
use File::Basename;
use blib '..';
use blib '../Gnome';
use blib '../GdkImlib';
use blib '../GdkPixbuf';
use Cwd;
require '../Depends.pm';
require '../tools/gendefs.pl';

$gp = new ExtUtils::Depends ('Gnome::Print', 'Gtk', 'Gtk::Gdk::Pixbuf', 'Gtk::Gdk::ImlibImage', 'Gnome');

mkdir('build', 0777);

$gp->set_inc (`gnome-config --cflags print`);
$gp->set_libs (`gnome-config --libs print`);

$gp->add_typemaps (cwd() . '/pkg.typemap', cwd().'/build/GnomePrintTypemap');

$gp->save_config('build/Files.pm');
$gp->install('build/Files.pm');

$gp->add_pm('GnomePrint.pm' => '$(INST_ARCHLIBDIR)/Print.pm',
	'build/GnomePrintTypes.pm' => '$(INST_ARCHLIBDIR)/Print/Types.pm',
	'build/GnomePrintTypesLazy.pm' => '$(INST_ARCHLIBDIR)/Print/TypesLazy.pm',
	);

$gp->add_c ('build/GnomePrintDefs.c');
$gp->add_defs ('pkg.defs');
$gp->add_headers (qw( 
	<libgnome/gnome-paper.h>
	<libgnomeprint/gnome-print.h> 
	<libgnomeprint/gnome-print-dialog.h>
	<libgnomeprint/gnome-print-master-preview.h>
	<libgnomeprint/gnome-print-preview.h>
	<libgnomeprint/gnome-printer-dialog.h>
	<libgnomeprint/gnome-print-meta.h>
));

$gp->add_xs ('xs/GnomePrint.xs');

@a = (	'-f', 'GnomePrint', 
		'-p', 'Gtk=Gtk',
		'-p', 'GdkGL=Gtk::Gdk::GL',
		'-p', 'GdkRgb=Gtk::Gdk::Rgb',
		'-p', 'Gdk=Gtk::Gdk',
		'-p', 'Gnome=Gnome',
		'-p', 'Panel=Gnome::Panel',
		'-m', 'Gnome::Print');

foreach ($gp->get_defs) {
	push @a, '-d', $_;
}
foreach ($gp->get_headers) {
	push @a, '-i', $_;
}

$gp->add_xs(gendefs::gendefs('-L', @a));

$depend = { 'build/GnomePrintDefs.c' => 'build/GnomePrintDefs.h build/PerlGnomePrintInt.h' };

foreach (qw( build/GnomePrintDefs.h build/PerlGnomePrintInt.h)) {
	$gp->add_pm($_, '$(INST_ARCHLIBDIR)/Print/Install/'. basename($_));
}

$gp->write_ext("build/extension.xsh");

$gp->add_clean ( qw(
	build/Files.pm build/GnomePrintDefs.c build/GnomePrintDefs.h 
	build/GnomePrintDefs.o build/GnomePrintTypemap build/GnomePrintTypes.pm 
	build/PerlGnomePrintExt.c build/PerlGnomePrintExt.h build/PerlGnomePrintInt.h 
	build/boxed.xsh build/extension.xsh build/objects.xsh
	build/perl-gnomeprint-ds.pod  build/perl-gnomeprint-ref.xml
));

# documentation
gendefs::gen_doc('gnomeprint');
system($Config{perlpath}, "../tools/gendoc.pl", "-t", 'gnomeprint', $gp->get_xs);
system($Config{perlpath}, "../tools/gpdoc2pod", "-t", 'Gnome::Print');

WriteMakefile(
	'NAME'      => 'Gnome::Print',
	'VERSION_FROM'	=> 'GnomePrint.pm',
	'XSOPT' => '-noversioncheck',
	'dist' => { COMPRESS=>"gzip", SUFFIX=>"gz" },
	'clean' => {FILES => join(' ', @clean) },
	'MAN3PODS' => {
		'build/perl-gnomeprint-ref.pod' => '$(INST_MAN3DIR)/Gnome::Print::reference.3pm',
		},
	$gp->get_makefile_vars,
);

sub MY::postamble {

'
Makefile: ' . join(' ',
	$gp->get_defs,
	<*/pkg*.pl>
	) . '

build/PerlGnomePrintExt.h build/PerlGnomePrintExt.c build/PerlGnomePrintInt.h: build/GnomePrintDefs.h ../tools/genext.pl
	$(PERL) ../tools/genext.pl GnomePrint </dev/null

gendoc:
	$(PERL) ../tools/gendoc.pl -t gnomeprint $(XS_FILES)

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

