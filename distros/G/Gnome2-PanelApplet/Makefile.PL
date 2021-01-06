#!/usr/bin/perl
# $Id$

use 5.008;
use strict;
use warnings;

use Cwd qw(cwd);
use ExtUtils::MakeMaker;

our %build_reqs = (
  'libpanelapplet-2.0' => '2.0.0',
);

our %perl_reqs = (
  'ExtUtils::Depends'   => '0.20',
  'ExtUtils::PkgConfig' => '1.03',
  'Glib'                => '1.160',
  'Gtk2'                => '1.040',
  'Gnome2'              => '1.042',
  'Gnome2::GConf'       => '1.044',
);

unless (eval "use ExtUtils::Depends '$perl_reqs{'ExtUtils::Depends'}';"
           . "use ExtUtils::PkgConfig '$perl_reqs{'ExtUtils::PkgConfig'}';"
           . "use Glib '$perl_reqs{'Glib'}';"
           . "use Gtk2 '$perl_reqs{'Gtk2'}';"
           . "use Gnome2 '$perl_reqs{'Gnome2'}';"
           . "use Gnome2::GConf '$perl_reqs{'Gnome2::GConf'}';"
           . "use Glib::MakeHelper;"
           . "use Gtk2::CodeGen;"
           . "1") {
  warn "$@\n";
  WriteMakefile(
    # don't clobber the existing META.yml
    NO_META      => 1,
    PREREQ_FATAL => 1,
    PREREQ_PM    => \%perl_reqs,
  );
  exit 1; # not reached
}

# If the package can't be found, warn and exit with status 0 to indicate to
# CPAN testers that their system is not supported.
my %pkgcfg;
#unless (eval { %pkgcfg = ExtUtils::PkgConfig->find (
#                 "libpanelapplet-2.0 >= $build_reqs{'libpanelapplet-2.0'}");
#	       1; })
#{
#	warn $@;
#	exit 0;
#}

mkdir 'build', 0777;

our @xs_files = <xs/*.xs>;
our %pod_files = (
  'lib/Gnome2/PanelApplet.pm' => '$(INST_MAN3DIR)/Gnome2::PanelApplet.$(MAN3EXT)',
  Glib::MakeHelper->do_pod_files (@xs_files),
);

Gtk2::CodeGen->parse_maps('libpanelapplet-perl');
Gtk2::CodeGen->write_boot(ignore => qr/^Gnome2::PanelApplet$/);

#ExtUtils::PkgConfig->write_version_macros (
#  "build/libpanelapplet-perl-version.h",
#  "libpanelapplet-2.0" => "PANEL_APPLET",
#);

my $dep = ExtUtils::Depends->new('Gnome2::PanelApplet', qw/Gnome2 Gnome2::GConf/);
$dep->set_inc($pkgcfg{cflags});
$dep->set_libs($pkgcfg{libs});
$dep->add_xs(@xs_files);
$dep->add_pm('lib/Gnome2/PanelApplet.pm' => '$(INST_LIBDIR)/PanelApplet.pm');
$dep->add_typemaps(map {File::Spec->catfile(cwd(), $_)} 'build/libpanelapplet-perl.typemap');

$dep->install(qw(libpanelapplet-perl.h build/libpanelapplet-perl-autogen.h build/libpanelapplet-perl-version.h));
$dep->save_config('build/IFiles.pm');

WriteMakefile(
  NAME          => 'Gnome2::PanelApplet',
  VERSION_FROM  => 'lib/Gnome2/PanelApplet.pm',
  ABSTRACT_FROM => 'lib/Gnome2/PanelApplet.pm',
  XSPROTOARG    => '-noprototypes',
  MAN3PODS      => \%pod_files,
  PREREQ_PM     => \%perl_reqs,
  # don't clobber the existing META.yml
  NO_META      => 1,
  $dep->get_makefile_vars,
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

* Perl URL: https://gitlab.gnome.org/GNOME/perl-gnome2-panelapplet
* Upstream URLs: https://developer.gnome.org/panel-applet/ and https://gitlab.gnome.org/GNOME/gnome-applets
* Last compatible upstream version: 2.32.1.1
* Last compatible upstream release date: 2010-11-22
* Migration path for this module: Gtk3::StatusIcon
* Migration module URL: https://metacpan.org/pod/Gtk3

NOTICE NOTICE NOTICE NOTICE NOTICE NOTICE NOTICE NOTICE NOTICE NOTICE

__EON__

sub MY::postamble {
	return Glib::MakeHelper->postamble_clean ()
	     . Glib::MakeHelper->postamble_docs_full (
		DEPENDS => $dep,
		COPYRIGHT_FROM => 'copyright.pod');
}
