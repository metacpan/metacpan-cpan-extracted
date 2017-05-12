use ExtUtils::MakeMaker;
use Config;
use Cwd;
use blib '../Gtk';
require '../Depends.pm';

$imlib = new ExtUtils::Depends ('Gtk::Gdk::ImlibImage', 'Gtk');

mkdir('build', 0777);

$imlib->set_inc(`imlib-config --cflags-gdk`);
$imlib->set_libs(`imlib-config --libs-gdk`);
$imlib->add_typemaps (cwd() . '/pkg.typemap');
$imlib->add_headers ('"GdkImlibTypes.h"');
$imlib->add_xs ('xs/GdkImlib.xs');

$imlib->save_config('build/IFiles.pm');

$imlib->add_pm(
	'build/IFiles.pm' => '$(INST_ARCHLIBDIR)/ImlibImage/Install/Files.pm', 
	'GdkImlibImage.pm' => '$(INST_ARCHLIBDIR)/ImlibImage.pm');

$imlib->add_clean( qw(
	build/IFiles.pm  build/perl-gdkimlib-ref.xml
));

# documentation
#gendefs::gen_doc('gdkimlib');
system($Config{perlpath}, "../tools/gendoc.pl", "-t", 'gdkimlib', $imlib->get_xs);
system($Config{perlpath}, "../tools/gpdoc2pod", "-t", 'GdkImlib');

WriteMakefile(
	'NAME'      => 'Gtk::Gdk::ImlibImage',
	'VERSION_FROM'	=> 'GdkImlibImage.pm',
	'XSOPT' => '-noversioncheck',
	'dist' => { COMPRESS=>"gzip", SUFFIX=>"gz" },
	'MAN3PODS' => {
		'build/perl-gdkimlib-ref.pod' => '$(INST_MAN3DIR)/Gtk::Gdk::ImlibImage::reference.3pm',
		},
	$imlib->get_makefile_vars,
);

sub MY::c_o {
	package MY; # so that "SUPER" works right
	my $inherited = shift->SUPER::c_o(@_);
	$inherited =~ s/CCCMD.*$/$&\n\t\@if test -f `basename \$*.o` -a "`basename \$*.o`" != "\$*.o"; then mv `basename \$*.o` \$*.o; fi/mg;
    $inherited;
}
