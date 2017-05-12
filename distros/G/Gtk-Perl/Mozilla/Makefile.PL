use ExtUtils::MakeMaker;
use Config;
use Cwd;
use blib '..';
require '../Depends.pm';

require '../tools/gendefs.pl';

mkdir('build', 0777);

$moz = new ExtUtils::Depends('Gtk::MozEmbed', 'Gtk');

$moz->add_typemaps(cwd() . '/pkg.typemap', cwd().'/build/GtkMozEmbedTypemap');

$moz->set_inc(`./mozilla-config --cflags`);
$moz->set_libs(`./mozilla-config --libs`);
$moz->save_config('build/IFiles.pm');

# push(@defines, '-Ibuild', '-I.');

$moz->add_c("mozilla.C");

$moz->add_pm('GtkMozEmbed.pm' => '$(INST_ARCHLIBDIR)/MozEmbed.pm',
	'build/GtkMozEmbedTypes.pm' => '$(INST_ARCHLIBDIR)/MozEmbed/Types.pm');

$moz->add_c ('build/GtkMozEmbedDefs.c');
$moz->add_defs ('pkg.defs');
$moz->add_headers (qw( <mozilla/gtkmozembed.h> ));

$moz->add_xs ('xs/GtkMozEmbed.xs');
@a = (	'-f', 'GtkMozEmbed', 
		'-p', 'Gtk=Gtk',
		'-p', 'GdkGL=Gtk::Gdk::GL',
		'-p', 'GdkRgb=Gtk::Gdk::Rgb',
		'-p', 'Gdk=Gtk::Gdk',
		'-p', 'Gnome=Gnome',
		'-p', 'Panel=Gnome::Panel',
		'-m', 'Gtk::MozEmbed');

foreach ($moz->get_defs) {
	push @a, '-d', $_;
}
foreach ($moz->get_headers) {
	push @a, '-i', $_;
}
#warn "Running gendefs with [@a]\n";
@a = gendefs::gendefs(@a);
#warn "Result was: @a in ",cwd(),"\n";
$moz->add_xs(@a);

$depend = { 'build/GtkMozEmbedDefs.c' => 'build/GtkMozEmbedDefs.h build/PerlGtkMozEmbedInt.h' };

$moz->install (qw( build/GtkMozEmbedDefs.h build/PerlGtkMozEmbedInt.h));

$moz->add_clean ( qw(
	build/IFiles.pm build/GtkMozEmbedDefs.c build/GtkMozEmbedDefs.h 
	build/GtkMozEmbedDefs.o build/GtkMozEmbedTypemap build/GtkMozEmbedTypes.pm 
	build/PerlGtkMozEmbedExt.c build/PerlGtkMozEmbedExt.h build/PerlGtkMozEmbedInt.h 
	build/boxed.xsh build/extension.xsh build/objects.xsh
));

# documentation
gendefs::gen_doc('gtkmozembed');
system($Config{perlpath}, "../tools/gendoc.pl", "-t", 'gtkmozembed', $moz->get_xs);

$moz->write_ext("build/extension.xsh");

WriteMakefile(
	'NAME'      => 'Gtk::MozEmbed',
	'VERSION_FROM'	=> 'GtkMozEmbed.pm',
	'XSOPT' => '-noversioncheck',
	'dist' => { COMPRESS=>"gzip", SUFFIX=>"gz" },
	$moz->get_makefile_vars,
	#'depend' => $depend,
);

sub MY::postamble {

'
Makefile: ' . join(' ',
	sort {$defs{$a} <=> $defs{$b}} keys %defs,
	<*/pkg*.pl>
	) . '

build/PerlGtkMozEmbedExt.h build/PerlGtkMozEmbedExt.c build/PerlGtkMozEmbedInt.h: build/GtkMozEmbedDefs.h ../tools/genext.pl
	$(PERL) ../tools/genext.pl GtkMozEmbed </dev/null

gendoc:
	$(PERL) ../tools/gendoc.pl -t gtkmozembed $(XS_FILES)

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

