#!/usr/bin/perl

BEGIN { require 5.008; }

use strict;
use warnings;

use ExtUtils::MakeMaker;
use Cwd;
use File::Spec;

# $Id$

my %build_reqs = (
  'perl-ExtUtils-Depends'   => '0.20',
  'perl-ExtUtils-PkgConfig' => '1.03',
  'perl-Glib'               => '1.180',
  'perl-Gtk2'               => '1.00',
  'Wnck'                    => '2.20.0',
);

my %pm_reqs = (
  'Glib'                => $build_reqs{'perl-Glib'},
  'Gtk2'                => $build_reqs{'perl-Gtk2'},
  'ExtUtils::Depends'   => $build_reqs{'perl-ExtUtils-Depends'},
  'ExtUtils::PkgConfig' => $build_reqs{'perl-ExtUtils-PkgConfig'},
);

unless (eval "use ExtUtils::Depends '$build_reqs{'perl-ExtUtils-Depends'}';"
           . "use ExtUtils::PkgConfig '$build_reqs{'perl-ExtUtils-PkgConfig'}';"
           . "use Glib '$build_reqs{'perl-Glib'}';"
           . "use Gtk2 '$build_reqs{'perl-Gtk2'}';"
           . "use Glib::MakeHelper;"
           . "use Gtk2::CodeGen;"
           . "1") {
  warn "$@\n";
  WriteMakefile(
    PREREQ_FATAL => 1,
    PREREQ_PM    => \%pm_reqs,
  );
  exit 1; # not reached
}

# --------------------------------------------------------------------------- #

my %pkgcfg = ExtUtils::PkgConfig->find("libwnck-1.0 >= $build_reqs{Wnck}");

mkdir 'build', 0777;

my @xs_files = <xs/*.xs>;
my %pod_files = (
  'Wnck.pm' => '$(INST_MAN3DIR)/Gnome2::Wnck.$(MAN3EXT)',
  Glib::MakeHelper->do_pod_files (@xs_files),
);

Gtk2::CodeGen->parse_maps('wnck2perl');
Gtk2::CodeGen->write_boot(ignore => qr/^Gnome2::Wnck$/);

ExtUtils::PkgConfig->write_version_macros (
  "build/wnck2perl-version.h",
  "libwnck-1.0" => "WNCK",
);

# --------------------------------------------------------------------------- #

my $wnck = ExtUtils::Depends->new('Gnome2::Wnck', 'Gtk2');
$wnck->set_inc($pkgcfg{cflags} . " -DWNCK_I_KNOW_THIS_IS_UNSTABLE");
$wnck->set_libs($pkgcfg{libs});
$wnck->add_xs(@xs_files);
$wnck->add_pm('Wnck.pm' => '$(INST_LIBDIR)/Wnck.pm');
$wnck->add_typemaps(map {File::Spec->catfile(cwd(), $_)} 'build/wnck2perl.typemap');

$wnck->install(qw(wnck2perl.h build/wnck2perl-autogen.h build/wnck2perl-version.h));
$wnck->save_config('build/IFiles.pm');

my $configure_requires =
  Glib::MakeHelper->get_configure_requires_yaml(%pm_reqs);

WriteMakefile(
  NAME          => 'Gnome2::Wnck',
  VERSION_FROM  => 'Wnck.pm', # finds $VERSION
  ABSTRACT_FROM => 'Wnck.pm', # retrieve abstract from module
  XSPROTOARG    => '-noprototypes',
  MAN3PODS      => \%pod_files,
  PREREQ_PM     => \%pm_reqs,

  $wnck->get_makefile_vars,

  EXTRA_META    => $configure_requires,
  META_MERGE => {
    x_deprecated => 1,
  },
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

* Perl URL: https://gitlab.gnome.org/GNOME/perl-gnome2-wnck
* Upstream URL: https://gitlab.gnome.org/GNOME/libwnck
* Last upstream version: 2.30.7
* Last upstream release date: 2011-08-31
* Migration path for this module: G:O:I
* Migration module URL: https://metacpan.org/pod/Glib::Object::Introspection

NOTICE NOTICE NOTICE NOTICE NOTICE NOTICE NOTICE NOTICE NOTICE NOTICE

__EON__

sub MY::postamble {
  return Glib::MakeHelper->postamble_clean ()
       . Glib::MakeHelper->postamble_docs_full (
           DEPENDS => $wnck,
           COPYRIGHT_FROM => 'copyright.pod')
       . Glib::MakeHelper->postamble_rpms (
           GNOME_WNCK => $build_reqs{'Wnck'},
           PERL_EXTUTILS_DEPENDS => $build_reqs{'perl-ExtUtils-Depends'},
           PERL_EXTUTILS_PKGCONFIG => $build_reqs{'perl-ExtUtils-PkgConfig'},
           PERL_GLIB => $build_reqs{'perl-Glib'},
           PERL_GTK => $build_reqs{'perl-Gtk2'});
}
