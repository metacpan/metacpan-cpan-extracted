use ExtUtils::MakeMaker;
use Config;
use File::Basename;
use blib '..';
use Cwd;
require '../Depends.pm';
require '../tools/gendefs.pl';

$xm = new ExtUtils::Depends('Gtk::XmHTML', 'Gtk');

mkdir('build', 0777);

$xm->set_inc (`gnome-config --cflags gnomeui`);
$xm->set_libs (`gnome-config --libs gtkxmhtml`);

$xm->add_typemaps (cwd() . '/pkg.typemap', cwd().'/build/GtkXmHTMLTypemap');
#$xm->add_headers ('"GXHTypes.h"'); #, 'build/GtkXmHTMLDefs.h');

$xm->save_config('build/Files.pm');
$xm->install('build/Files.pm');

$xm->add_pm ('GtkXmHTML.pm' => '$(INST_ARCHLIBDIR)/XmHTML.pm',
	'build/GtkXmHTMLTypes.pm' => '$(INST_ARCHLIBDIR)/XmHTML/Types.pm');

$xm->add_c ('GXHTypes.c', 'build/GtkXmHTMLDefs.c');
$xm->add_defs ('pkg.defs');
$xm->add_headers (qw( <gtk-xmhtml/gtk-xmhtml.h> "GXHTypes.h"));

$xm->add_xs ('xs/GtkXmHTML.xs');
@a = (	'-f', 'GtkXmHTML', 
		'-p', 'Gtk=Gtk',
		'-p', 'GdkGL=Gtk::Gdk::GL',
		'-p', 'GdkRgb=Gtk::Gdk::Rgb',
		'-p', 'Gdk=Gtk::Gdk',
		'-p', 'Gnome=Gnome',
		'-p', 'Panel=Gnome::Panel',
		'-m', 'Gtk::XmHTML');

# FIXME: use defs and headers from ExtUtils::Depends....
foreach ($xm->get_defs) {
	push @a, '-d', $_;
}
foreach ($xm->get_headers) {
	push @a, '-i', $_;
}

$xm->add_xs(gendefs::gendefs(@a));

$depend = { 'build/GtkXmHTMLDefs.c' => 'build/GtkXmHTMLDefs.h build/PerlGtkXmHTMLInt.h' };

foreach (qw(GXHTypes.h build/GtkXmHTMLDefs.h build/PerlGtkXmHTMLInt.h)) {
	$xm->add_pm($_ => '$(INST_ARCHLIBDIR)/XmHTML/Install/'. basename($_));
}

$xm->write_ext('build/extension.xsh');

$xm->add_clean ( qw(
	build/Files.pm build/GtkXmHTMLDefs.c build/GtkXmHTMLDefs.h 
	build/GtkXmHTMLDefs.o build/GtkXmHTMLTypemap build/GtkXmHTMLTypes.pm 
	build/PerlGtkXmHTMLExt.c build/PerlGtkXmHTMLExt.h build/PerlGtkXmHTMLInt.h 
	build/boxed.xsh build/extension.xsh build/objects.xsh
	build/perl-gtkxmhtml-ds.pod  build/perl-gtkxmhtml-ref.xml
));

# documentation
gendefs::gen_doc('gtkxmhtml');
system($Config{perlpath}, "../tools/gendoc.pl", "-t", 'gtkxmhtml', $xm->get_xs);

WriteMakefile(
	'NAME'      => 'Gtk::XmHTML',
	'VERSION_FROM'	=> 'GtkXmHTML.pm',
	'XSOPT' => '-noversioncheck',
	'dist' => { COMPRESS=>"gzip", SUFFIX=>"gz" },
	$xm->get_makefile_vars,
);

sub MY::postamble {

'
Makefile: ' . join(' ',
	$xm->get_defs,
	<pkg*.pl>
	) . '

build/PerlGtkXmHTMLExt.h build/PerlGtkXmHTMLExt.c build/PerlGtkXmHTMLInt.h: build/GtkXmHTMLDefs.h ../tools/genext.pl
	$(PERL) ../tools/genext.pl GtkXmHTML </dev/null

gendoc:
	$(PERL) ../tools/gendoc.pl -t gtkxmhtml $(XS_FILES)

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

