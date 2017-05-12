#
# $Header: /cvsroot/gtk2-perl/gtk2-perl-xs/Glade/Makefile.PL,v 1.21 2008/09/07 20:05:50 kaffeetisch Exp $
#

use strict;
use 5.008;
use Cwd;
use File::Spec;
use ExtUtils::MakeMaker;

# minimum required version of dependancies we need to build
our %build_reqs = (
	'perl-ExtUtils-Depends'   => '0.300',
	'perl-ExtUtils-PkgConfig' => '1.000',
	'perl-Glib'               => '1.020', # for Glib::MakeHelper
	'perl-Gtk2'               => '1.000',
	'Glade'                   => '2.0.0',
);

our %pre_reqs = (
	Glib::                => $build_reqs{'perl-Glib'},
	Gtk2::                => $build_reqs{'perl-Gtk2'},
	ExtUtils::Depends::   => $build_reqs{'perl-ExtUtils-Depends'},
	ExtUtils::PkgConfig:: => $build_reqs{'perl-ExtUtils-PkgConfig'},
);

# Writing a fake Makefile ensures that CPAN will pick up the correct
# dependencies and install them.
unless (eval "use ExtUtils::Depends '$build_reqs{'perl-ExtUtils-Depends'}';"
           . "use ExtUtils::PkgConfig '$build_reqs{'perl-ExtUtils-PkgConfig'}';"
           . "use Glib::MakeHelper;"
           # just seeing if Glib is available isn't enough, make sure
           # it's recent enough, too 
           . "use Glib '$build_reqs{'perl-Glib'}';"
           . "use Gtk2 '$build_reqs{'perl-Gtk2'}';"
           . "1") {
   warn "$@\n";
   WriteMakefile(
         PREREQ_FATAL => 1,
         PREREQ_PM    => \%pre_reqs,
   );
   exit 1; # not reached
}

# If the package can't be found, warn and exit with status 0 to indicate to
# CPAN testers that their system is not supported.
our %pkgcfg;
unless (eval { %pkgcfg = ExtUtils::PkgConfig->find ('libglade-2.0 >= '.$build_reqs{Glade});
	       1; })
{
	warn $@;
	exit 0;
}

mkdir 'build', 0777;

my $gladexml = ExtUtils::Depends->new ('GladeXML', 'Gtk2', 'Glib');
$gladexml->set_inc ($pkgcfg{cflags});
$gladexml->set_libs ($pkgcfg{libs});
$gladexml->add_pm ('GladeXML.pm' => '$(INST_LIBDIR)/GladeXML.pm');
$gladexml->add_xs ('GladeXML.xs');
my $cwd = cwd();
$gladexml->add_typemaps (map {File::Spec->catfile($cwd,$_)} 'gladexmlperl.typemap');

$gladexml->install ('gladexmlperl.h');
$gladexml->save_config ('build/IFiles.pm');

WriteMakefile(
    NAME          => 'Gtk2::GladeXML',
    VERSION_FROM  => 'GladeXML.pm',
    ABSTRACT_FROM => 'GladeXML.pm',
    PREREQ_PM     => \%pre_reqs,
    XSPROTOARG    => '-noprototypes',
    $gladexml->get_makefile_vars,
);


sub MY::postamble
{
	return Glib::MakeHelper->postamble_clean ()
	     . Glib::MakeHelper->postamble_rpms (
		'GLADE' => $build_reqs{'Glade'},
		'PERL_EXTUTILS_DEPENDS' => 
			$build_reqs{'perl-ExtUtils-Depends'},
		'PERL_EXTUTILS_PKGCONFIG' => 
			$build_reqs{'perl-ExtUtils-PkgConfig'},
		'PERL_GLIB' => $build_reqs{'perl-Glib'},
		'PERL_GTK' => $build_reqs{'perl-Gtk2'},
	       );
}
