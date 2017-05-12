
use 5.008;
use ExtUtils::MakeMaker;
use Cwd;
use File::Spec;
use ExtUtils::Depends;
use ExtUtils::PkgConfig;
use Gtk2::CodeGen;

# minimum required version of dependancies we need to build
our %build_reqs = (
	'perl-ExtUtils-Depends'   => '0.1',
	'perl-ExtUtils-PkgConfig' => '0.1',
	'perl-Glib'               => '1.00',
	'perl-Gtk2'               => '1.00',
);

# Writing a fake Makefile ensures that CPAN will pick up the correct
# dependencies and install them.
unless (eval "use ExtUtils::Depends;"
           . "use ExtUtils::PkgConfig;"
	   . "use Glib::MakeHelper;"
	   . "use Gtk2::CodeGen;"
           # just seeing if Glib is available isn't enough, make sure
           # it's recent enough, too
           . "use Glib '$build_reqs{'perl-Glib'}';"
           . "use Gtk2 '$build_reqs{'perl-Gtk2'}';"
           . "1") {
   warn "$@\n";
   WriteMakefile(
         PREREQ_FATAL => 1,
         PREREQ_PM    => {
            Glib::                => $build_reqs{'perl-Glib'},
            Gtk2::                => $build_reqs{'perl-Gtk2'},
            ExtUtils::Depends::   => $build_reqs{'perl-ExtUtils-Depends'},
            ExtUtils::PkgConfig:: => $build_reqs{'perl-ExtUtils-PkgConfig'},
         },
   );
   exit 1; # not reached
}

mkdir 'build', 0777;

my %pkgcfg = ExtUtils::PkgConfig->find ('gtk+-2.0');

Gtk2::CodeGen->parse_maps ('traymanager');
Gtk2::CodeGen->write_boot;

my $genmarshal= `which glib-genmarshal`;
unless($genmarshal) {
	print STDERR "glib-genmarshal needs to be installed\n";
	exit 1;
}
chomp $genmarshal;
print STDERR "writing build/eggmarshalers.h\n";
system("$genmarshal --prefix=_egg_marshal eggmarshalers.list --header > build/eggmarshalers.h");
print STDERR "writing build/eggmarshalers.c\n";
system("$genmarshal --prefix=_egg_marshal eggmarshalers.list --body > build/eggmarshalers.c");


$traymanager = ExtUtils::Depends->new ('Gtk2::TrayManager', 'Gtk2', 'Glib');
$traymanager->set_inc ($pkgcfg{cflags} . " -DEGG_COMPILATION");
$traymanager->set_libs ($pkgcfg{libs});
$traymanager->add_c(qw(egg-marshal.c eggtraymanager.c));
$traymanager->add_xs ("TrayManager.xs");
$traymanager->add_pm ('TrayManager.pm' => '$(INST_LIBDIR)/TrayManager.pm');
my $cwd = cwd();
$traymanager->add_typemaps (map {File::Spec->catfile($cwd,$_)} 'build/traymanager.typemap');

# $traymanager->install (qw(traymanager.h build/traymanager-autogen.h));

$traymanager->install (qw(build/traymanager-autogen.h));
$traymanager->save_config ('build/IFiles.pm');

WriteMakefile(
    NAME            => 'Gtk2::TrayManager',
    VERSION_FROM    => 'TrayManager.pm', # finds $VERSION
    # ABSTRACT_FROM   => 'TrayManager.pm', # retrieve abstract from module
    XSPROTOARG      => '-noprototypes',
    $traymanager->get_makefile_vars,
    PREREQ_PM       =>  {
    	Gtk2 => $build_reqs{'perl-Gtk2'},
    },
);

package MY;
use Cwd;

sub postamble
{
	return Glib::MakeHelper->postamble_clean ()
	     . Glib::MakeHelper->postamble_docs (@main::xs_files)
	     . Glib::MakeHelper->postamble_rpms (
		'PERL_EXTUTILS_DEPENDS' =>
			$build_reqs{'perl-ExtUtils-Depends'},
		'PERL_EXTUTILS_PKGCONFIG' =>
			$build_reqs{'perl-ExtUtils-PkgConfig'},
		'PERL_GLIB' => $build_reqs{'perl-Glib'},
		'PERL_GTK' => $build_reqs{'perl-Gtk2'},
	       );
}
package MAIN;
