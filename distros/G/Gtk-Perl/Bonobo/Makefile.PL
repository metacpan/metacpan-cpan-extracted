use ExtUtils::MakeMaker;
use Config;
use blib '..';
use blib '../GdkImlib';
use blib '../Gnome';
use Cwd;
require '../Depends.pm';
require '../tools/gendefs.pl';

$bonobo = new ExtUtils::Depends('Bonobo', 'Gtk', 'Gtk::Gdk::ImlibImage', 'Gnome');

mkdir('build', 0777);

$bonobo->set_inc ("-Ibuild ".`gnome-config --cflags bonobox_print`);
$bonobo->set_libs (`gnome-config --libs bonobox_print`);

$bonobo->add_typemaps (cwd() . '/pkg.typemap', cwd().'/orbit.typemap', cwd().'/build/BonoboTypemap');
$bonobo->add_headers ('"build/BonoboDefs.h"');

$bonobo->save_config('build/IFiles.pm');

$bonobo->add_pm ('Bonobo.pm' => '$(INST_ARCHLIBDIR)/Bonobo.pm',
	'build/BonoboTypes.pm' => '$(INST_ARCHLIBDIR)/Bonobo/Types.pm');

$bonobo->add_c ('build/BonoboDefs.c');
$bonobo->add_defs ('pkg.defs');
$bonobo->add_headers (qw( <bonobo.h> "bonobo-perl.h"));
$bonobo->add_xs('xs/Bonobo.xs');

@a = (	'-f', 'Bonobo', 
		'-p', 'Gtk=Gtk',
		'-p', 'GdkGL=Gtk::Gdk::GL',
		'-p', 'GdkRgb=Gtk::Gdk::Rgb',
		'-p', 'Gdk=Gtk::Gdk',
		'-p', 'Gnome=Gnome',
		'-p', 'Bonobo=Bonobo',
		'-p', 'Panel=Gnome::Panel',
		'-m', 'Bonobo');

foreach ($bonobo->get_defs) {
	push @a, '-d', $_;
}
foreach ($bonobo->get_headers) {
	push @a, '-i', $_;
}

$bonobo->add_xs(gendefs::gendefs(@a));

$depend = { 'build/BonoboDefs.c' => 'build/BonoboDefs.h build/PerlBonoboInt.h' };

$bonobo->install (qw(build/BonoboDefs.h build/PerlBonoboInt.h));

$bonobo->write_ext('build/extension.xsh');

$bonobo->add_clean(qw(
	build/IFiles.pm build/BonoboDefs.c build/BonoboDefs.h 
	build/BonoboTypemap build/BonoboTypes.pm 
	build/PerlBonoboExt.c build/PerlBonoboExt.h 
	build/PerlBonoboInt.h build/boxed.xsh build/extension.xsh 
	build/objects.xsh build/perl-bonobo-ds.pod build/perl-bonobo-ref.pod
));

# documentation
gendefs::gen_doc('bonobo');
system($Config{perlpath}, "../tools/gendoc.pl", "-t", 'bonobo', $bonobo->get_xs);
system($Config{perlpath}, "../tools/gpdoc2pod", "-t", 'Bonobo');

WriteMakefile(
	'NAME'      => 'Bonobo',
	'VERSION_FROM'	=> 'Bonobo.pm',
	'XSOPT' => '-noversioncheck',
	'dist' => { COMPRESS=>"gzip", SUFFIX=>"gz" },
	'depend' => $depend,
	OPTIMIZE =>'-g -O2',
	'MAN3PODS' => {
		'build/perl-bonobo-ref.pod' => '$(INST_MAN3DIR)/Bonobo::reference.3pm',
		},
	$bonobo->get_makefile_vars,
);

sub MY::postamble {

'
Makefile: ' . join(' ',
	sort {$defs{$a} <=> $defs{$b}} keys %defs,
	<*/pkg*.pl>
	) . '

build/PerlBonoboExt.h build/PerlBonoboExt.c build/PerlBonoboInt.h: build/BonoboDefs.h ../tools/genext.pl
	$(PERL) ../tools/genext.pl Bonobo </dev/null

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

