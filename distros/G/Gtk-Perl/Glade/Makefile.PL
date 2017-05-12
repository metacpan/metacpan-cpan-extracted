use ExtUtils::MakeMaker;
use Config;
use blib '../Gtk';
use Cwd;
require '../Depends.pm';
require '../tools/gendefs.pl';

$glade = new ExtUtils::Depends('Gtk::GladeXML', 'Gtk');

mkdir('build', 0777);

# Gnome support is automatically loaded at runtime if the Gnome module
# is loaded too. See at the end of GladeXML.pm for more info.
#if (defined(`libglade-config --libs gnome`)) {
#	$gnome = 'gnome';
#} else {
#	$gnome = '';
#}

$gnome = '';

$glade->set_inc (`libglade-config --cflags $gnome`);
$glade->set_libs (`libglade-config --libs $gnome`);

$glade->add_typemaps (cwd() . '/pkg.typemap', cwd().'/build/GtkGladeXMLTypemap');
#$glade->add_headers ('"GtkGladeXMLDefs.h"');

$glade->save_config('build/Files.pm');
$glade->install('build/Files.pm');

$glade->add_pm ('GladeXML.pm' => '$(INST_ARCHLIBDIR)/GladeXML.pm',
	'build/GtkGladeXMLTypes.pm' => '$(INST_ARCHLIBDIR)/GladeXML/Types.pm');

$glade->add_c ('build/GtkGladeXMLDefs.c');
$glade->add_defs ('pkg.defs');
$glade->add_headers (qw( <glade/glade.h> ));

$glade->add_xs ('xs/GladeXML.xs');

@a = (	'-f', 'GtkGladeXML', 
		'-p', 'Gtk=Gtk',
		'-p', 'GdkGL=Gtk::Gdk::GL',
		'-p', 'GdkRgb=Gtk::Gdk::Rgb',
		'-p', 'Gdk=Gtk::Gdk',
		'-p', 'Gnome=Gnome',
		'-p', 'Panel=Gnome::Panel',
		'-m', 'Gtk::GladeXML');

foreach ($glade->get_defs) {
	push @a, '-d', $_;
}
foreach ($glade->get_headers) {
	push @a, '-i', $_;
}

$glade->add_xs(gendefs::gendefs(@a));

$depend = { 'build/GtkGladeXMLDefs.c' => 'build/GtkGladeXMLDefs.h build/PerlGtkGladeXMLInt.h' };

$glade->install (qw(build/GtkGladeXMLDefs.h build/PerlGtkGladeXMLInt.h));

$glade->write_ext('build/extension.xsh');

$glade->add_defines('-DGNOME_HVER=defined') if $gnome;

$glade->add_clean( qw(
	build/Files.pm build/GtkGladeXMLDefs.c build/GtkGladeXMLDefs.h 
	build/GtkGladeXMLDefs.o build/GtkGladeXMLTypemap build/GtkGladeXMLTypes.pm 
	build/PerlGtkGladeXMLExt.c build/PerlGtkGladeXMLExt.h 
	build/PerlGtkGladeXMLInt.h build/perl-glade-ds.pod build/perl-glade-ref.xml
	build/boxed.xsh build/extension.xsh build/objects.xsh
));

# documentation
gendefs::gen_doc('glade');
system($Config{perlpath}, "../tools/gendoc.pl", "-t", 'glade', $glade->get_xs);
system($Config{perlpath}, "../tools/gpdoc2pod", "-t", 'Glade');

WriteMakefile(
	'NAME'      => 'Gtk::GladeXML',
	'VERSION_FROM'	=> 'GladeXML.pm',
	'XSOPT' => '-noversioncheck',
	'dist' => { COMPRESS=>"gzip", SUFFIX=>"gz" },
	'MAN3PODS' => {
		'build/perl-glade-ref.pod' => '$(INST_MAN3DIR)/Gtk::GladeXML::reference.3pm',
		},
	$glade->get_makefile_vars,
);

sub MY::postamble {

'
Makefile: ' . join(' ',
	sort {$defs{$a} <=> $defs{$b}} keys %defs,
	<*/pkg*.pl>
	) . '

build/PerlGtkGladeXMLExt.h build/PerlGtkGladeXMLExt.c build/PerlGtkGladeXMLInt.h: build/GtkGladeXMLDefs.h ../tools/genext.pl
	$(PERL) ../tools/genext.pl GtkGladeXML </dev/null

gendoc:
	$(PERL) ../tools/gendoc.pl -t glade $(XS_FILES)

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

