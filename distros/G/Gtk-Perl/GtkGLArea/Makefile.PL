use ExtUtils::MakeMaker;
use Config;
use blib '../Gtk';
use Cwd;
require '../Depends.pm';

require '../tools/gendefs.pl';

mkdir('build', 0777);

$gl = new ExtUtils::Depends ('Gtk::GLArea', 'Gtk');

$gl->set_inc (`gtk-config --cflags`);
$libs = "-lgtkgl  -lMesaGL -lMesaGLU " . `gtk-config --libs`;
chomp($libs);
$nomesa = $libs;
$nomesa =~ s/Mesa//g;

$gl->add_typemaps (cwd() . '/pkg.typemap', cwd().'/build/GtkGLAreaTypemap');
$gl->add_headers ( '"build/GtkGLAreaDefs.h"', '"build/PerlGtkGLAreaInt.h"');

$gl->add_boot ('Gtk::Gdk::GL', 'Gtk::GLArea::Constants');

$gl->save_config('build/Files.pm');
$gl->install('build/Files.pm');

$gl->add_pm(
	'GtkGLArea.pm' => '$(INST_ARCHLIBDIR)/GLArea.pm',
	'build/GtkGLAreaTypes.pm' => '$(INST_ARCHLIBDIR)/GLArea/Types.pm');

$gl->add_c ( 'build/GtkGLAreaDefs.c');
$gl->add_defs ('pkg.defs');
$gl->add_headers (qw( <gtkgl/gtkglarea.h> ));

$gl->add_xs ('xs/GtkGdkGL.xs', 'xs/Constants.xs');
@a = (	'-f', 'GtkGLArea', 
		'-p', 'Gtk=Gtk',
		'-p', 'GdkGL=Gtk::Gdk::GL',
		'-p', 'GdkRgb=Gtk::Gdk::Rgb',
		'-p', 'Gdk=Gtk::Gdk',
		'-p', 'Gnome=Gnome',
		'-p', 'Panel=Gnome::Panel',
		'-m', 'Gtk::GLArea');

foreach ($gl->get_defs) {
	push @a, '-d', $_;
}
foreach ($gl->get_headers) {
	push @a, '-i', $_;
}

$gl->add_xs(gendefs::gendefs(@a));

$depend = { 'build/GtkGLAreaDefs.c' => 'build/GtkGLAreaDefs.h build/PerlGtkGLAreaInt.h' };

$gl->install (qw( build/GtkGLAreaDefs.h build/PerlGtkGLAreaInt.h));
$gl->add_pm('Constants.pm' => '$(INST_LIBDIR)/GLArea/Constants.pm',
	'Glut.pm' => '$(INST_LIBDIR)/GLArea/Glut.pm');

$gl->write_ext('build/extension.xsh');

$gl->add_clean ( qw(
	build/Files.pm build/GtkGLAreaDefs.c build/GtkGLAreaDefs.h 
	build/GtkGLAreaDefs.o build/GtkGLAreaTypemap build/GtkGLAreaTypes.pm 
	build/PerlGtkGLAreaExt.c build/PerlGtkGLAreaExt.h build/PerlGtkGLAreaInt.h 
	build/boxed.xsh build/extension.xsh build/objects.xsh
	build/perl-gtkglarea-ds.pod  build/perl-gtkglarea-ref.xml
));

# documentation
gendefs::gen_doc('gtkglarea');
system($Config{perlpath}, "../tools/gendoc.pl", "-t", 'gtkglarea', $gl->get_xs);

WriteMakefile(
	'NAME'      => 'Gtk::GLArea',
	'VERSION_FROM'	=> 'GtkGLArea.pm',
	'XSOPT' => '-noversioncheck',
	'dist' => { COMPRESS=>"gzip", SUFFIX=>"gz" },
	'depend' => $depend,
	$gl->get_makefile_vars,
	'LIBS' => [$nomesa, $libs],
);

sub MY::postamble {

'
Makefile: ' . join(' ',
	sort {$defs{$a} <=> $defs{$b}} keys %defs,
	<*/pkg*.pl>
	) . '

build/PerlGtkGLAreaExt.h build/PerlGtkGLAreaExt.c build/PerlGtkGLAreaInt.h: build/GtkGLAreaDefs.h ../tools/genext.pl
	$(PERL) ../tools/genext.pl GtkGLArea </dev/null

gendoc:
	$(PERL) ../tools/gendoc.pl -t gtkglarea $(XS_FILES)

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

	
