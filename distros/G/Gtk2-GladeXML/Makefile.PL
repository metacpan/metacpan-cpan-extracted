#
# $Id$
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
	'Glib'                  => $build_reqs{'perl-Glib'},
	'Gtk2'                  => $build_reqs{'perl-Gtk2'},
	'ExtUtils::Depends'     => $build_reqs{'perl-ExtUtils-Depends'},
	'ExtUtils::PkgConfig'   => $build_reqs{'perl-ExtUtils-PkgConfig'},
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
    META_MERGE    => {
       configure_requires => \%pre_reqs,
       x_deprecated => 1,
    },
    $gladexml->get_makefile_vars,
);


print <<__EON__;
NOTICE NOTICE NOTICE NOTICE NOTICE NOTICE NOTICE NOTICE NOTICE NOTICE

This module has been deprecated by the Gtk-Perl project.  This means that the
module will no longer be updated with security patches, bug fixes, or when
changes are made in the Perl ABI.  The Git repo for this module has been
archived (made read-only), it will no longer possible to submit new commits to
it.  You are more than welcome to ask about this module on the Gtk-Perl
mailing list, but our priorities going forward will be maintaining Gtk-Perl
modules that are supported and maintained upstream; this module is neither.

Since this module is licensed under the LGPL v2.1, you may also fork this
module, if you wish, but you will need to use a different name for it on CPAN,
and the Gtk-Perl team requests that you use your own resources (mailing list,
Git repos, bug trackers, etc.) to maintain your fork going forward.

* Perl URL: https://gitlab.gnome.org/GNOME/perl-gtk2-gladexml
* Upstream URL: https://gitlab.gnome.org/Archive/libglade
* Last upstream version: 2.6.4
* Last upstream release date: 2009-03-17
* Migration path for this module: Gtk3::Builder
* Migration module URL: https://metacpan.org/pod/Gtk3

NOTICE NOTICE NOTICE NOTICE NOTICE NOTICE NOTICE NOTICE NOTICE NOTICE

__EON__

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
