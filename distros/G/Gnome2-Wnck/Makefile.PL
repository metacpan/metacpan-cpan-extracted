#!/usr/bin/perl

BEGIN { require 5.008; }

use strict;
use warnings;

use ExtUtils::MakeMaker;
use Cwd;
use File::Spec;

# $Header: /cvsroot/gtk2-perl/gtk2-perl-xs/Gnome2-Wnck/Makefile.PL,v 1.17 2008/03/16 12:58:16 kaffeetisch Exp $

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
);

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
