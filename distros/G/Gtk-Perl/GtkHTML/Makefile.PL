use ExtUtils::MakeMaker;
use Config;
use Cwd;
use blib '..';
require '../Depends.pm';

require '../tools/gendefs.pl';

mkdir('build', 0777);

$html = new ExtUtils::Depends('Gtk::HTML', 'Gtk');

$html->add_typemaps(cwd() . '/pkg.typemap', cwd().'/build/GtkHTMLTypemap');

$html->set_inc(`gnome-config --cflags gtkhtml`);
$html->set_libs(`gnome-config --libs gtkhtml`);
$html->save_config('build/Files.pm');
$html->install('build/Files.pm');

my $version = `gnome-config --modversion gtkhtml`;
warn "GOT $version";
if ($version =~ /-(\d+)\.(\d+)(\.(\d+))?/) {
	$version = sprintf("0x%02x%02x%02x", $1, $2, $4 || 0);
} else {
	$version = "0x000800";
}
$html->add_defines("-DGTKHTML_HVER=$version");
# push(@defines, '-Ibuild', '-I.');

$html->add_pm('GtkHTML.pm' => '$(INST_ARCHLIBDIR)/HTML.pm',
	'Simple.pm' => '$(INST_ARCHLIBDIR)/HTML/Simple.pm',
	'build/GtkHTMLTypes.pm' => '$(INST_ARCHLIBDIR)/HTML/Types.pm');

$html->add_c ('build/GtkHTMLDefs.c');
$html->add_defs ('pkg.defs');
$html->add_headers (qw( <gtkhtml/gtkhtml.h> ));

$html->add_xs ('xs/GtkHTML.xs');
@a = (	'-f', 'GtkHTML', 
		'-p', 'Gtk=Gtk',
		'-p', 'GdkGL=Gtk::Gdk::GL',
		'-p', 'GdkRgb=Gtk::Gdk::Rgb',
		'-p', 'Gdk=Gtk::Gdk',
		'-p', 'Gnome=Gnome',
		'-p', 'Panel=Gnome::Panel',
		'-m', 'Gtk::HTML');

foreach ($html->get_defs) {
	push @a, '-d', $_;
}
foreach ($html->get_headers) {
	push @a, '-i', $_;
}
#warn "Running gendefs with [@a]\n";
@a = gendefs::gendefs(@a);
#warn "Result was: @a in ",cwd(),"\n";
$html->add_xs(@a);

$depend = { 'build/GtkHTMLDefs.c' => 'build/GtkHTMLDefs.h build/PerlGtkHTMLInt.h' };

$html->install (qw( build/GtkHTMLDefs.h build/PerlGtkHTMLInt.h));

$html->add_clean ( qw(
	build/Files.pm build/GtkHTMLDefs.c build/GtkHTMLDefs.h 
	build/GtkHTMLDefs.o build/GtkHTMLTypemap build/GtkHTMLTypes.pm 
	build/PerlGtkHTMLExt.c build/PerlGtkHTMLExt.h build/PerlGtkHTMLInt.h 
	build/boxed.xsh build/extension.xsh build/objects.xsh
	build/perl-gtkhtml-ds.pod  build/perl-gtkhtml-ref.xml
));

# documentation
gendefs::gen_doc('gtkhtml');
system($Config{perlpath}, "../tools/gendoc.pl", "-t", 'gtkhtml', $html->get_xs);
system($Config{perlpath}, "../tools/gpdoc2pod", "-t", 'GtkHTML');

$html->write_ext("build/extension.xsh");

WriteMakefile(
	'NAME'      => 'Gtk::HTML',
	'VERSION_FROM'	=> 'GtkHTML.pm',
	'XSOPT' => '-noversioncheck',
	'dist' => { COMPRESS=>"gzip", SUFFIX=>"gz" },
	'MAN3PODS' => {
		'build/perl-gtkhtml-ref.pod' => '$(INST_MAN3DIR)/Gtk::HTML::reference.3pm',
		},
	$html->get_makefile_vars,
	#'depend' => $depend,
);

sub MY::postamble {

'
Makefile: ' . join(' ',
	sort {$defs{$a} <=> $defs{$b}} keys %defs,
	<*/pkg*.pl>
	) . '

build/PerlGtkHTMLExt.h build/PerlGtkHTMLExt.c build/PerlGtkHTMLInt.h: build/GtkHTMLDefs.h ../tools/genext.pl
	$(PERL) ../tools/genext.pl GtkHTML </dev/null

gendoc:
	$(PERL) ../tools/gendoc.pl -t gtkhtml $(XS_FILES)

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

