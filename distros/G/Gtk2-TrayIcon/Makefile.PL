
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

our %pre_reqs = (
    'Glib'                => $build_reqs{'perl-Glib'},
    'Gtk2'                => $build_reqs{'perl-Gtk2'},
    'ExtUtils::Depends'   => $build_reqs{'perl-ExtUtils-Depends'},
    'ExtUtils::PkgConfig' => $build_reqs{'perl-ExtUtils-PkgConfig'},
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
         PREREQ_PM    => \%pre_reqs,
   );
   exit 1; # not reached
}

mkdir 'build', 0777;

my %pkgcfg = ExtUtils::PkgConfig->find ('gtk+-2.0');

Gtk2::CodeGen->parse_maps ('trayicon');
Gtk2::CodeGen->write_boot;

$trayicon = ExtUtils::Depends->new ('Gtk2::TrayIcon', 'Gtk2', 'Glib');
$trayicon->set_inc ($pkgcfg{cflags} . " -DEGG_COMPILATION");
$trayicon->set_libs ($pkgcfg{libs});
$trayicon->add_c("eggtrayicon.c");
$trayicon->add_xs ("TrayIcon.xs");
$trayicon->add_pm ('TrayIcon.pm' => '$(INST_LIBDIR)/TrayIcon.pm');
my $cwd = cwd();
$trayicon->add_typemaps (map {File::Spec->catfile($cwd,$_)} 'build/trayicon.typemap');

# $trayicon->install (qw(trayicon.h build/trayicon-autogen.h));

$trayicon->install (qw(build/trayicon-autogen.h));
$trayicon->save_config ('build/IFiles.pm');

WriteMakefile(
    NAME            => 'Gtk2::TrayIcon',
    VERSION_FROM    => 'TrayIcon.pm', # finds $VERSION
    ABSTRACT_FROM   => 'TrayIcon.pm', # retrieve abstract from module
    XSPROTOARG      => '-noprototypes',
    $trayicon->get_makefile_vars,
    META_MERGE    => {
       configure_requires => \%pre_reqs,
       x_deprecated       => 1,
    },
);

use Cwd;

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

* Perl URL: https://gitlab.gnome.org/GNOME/perl-gtk2-trayicon
* Upstream URL: https://gitlab.gnome.org/GNOME/libegg
* Last upstream version: N/A
* Last upstream release date: 2009-05-01
* Migration path for this module: Gtk3::StatusIcon
* Migration module URL: https://metacpan.org/pod/Gtk3

NOTICE NOTICE NOTICE NOTICE NOTICE NOTICE NOTICE NOTICE NOTICE NOTICE

__EON__

sub MY::postamble
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

# gcc -I. `pkg-config --cflags gtk+-2.0` `pkg-config --libs gtk+-2.0` -DEGG_COMPILATION -DGTK_DISABLE_DEPRECATED -DGDK_DISABLE_DEPRECATED -DG_DISABLE_DEPRECATED -g -O2 -Wall --shared eggtrayicon.c -o eggtrayicon.o
