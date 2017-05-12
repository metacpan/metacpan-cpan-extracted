#!/usr/bin/perl -w
use 5.008;
use strict;

use ExtUtils::MakeMaker;
use Cwd;
use File::Spec;

# $Header: /cvsroot/gtk2-perl/gtk2-perl-xs/Gnome2-Dia/Makefile.PL,v 1.1 2004/09/14 17:54:16 kaffeetisch Exp $

our %build_reqs = (
  'perl-ExtUtils-Depends'   => '0.20',
  'perl-ExtUtils-PkgConfig' => '1.03',
  'perl-Glib'               => '1.040',
  'perl-Gtk2'               => '1.040',
  'perl-Gnome2-Canvas'      => '1.000',
  'perl-Gnome2-Print'       => '0.94',
  'DiaCanvas2'              => '0.13.0',
);

unless (eval "use ExtUtils::Depends '$build_reqs{'perl-ExtUtils-Depends'}';"
           . "use ExtUtils::PkgConfig '$build_reqs{'perl-ExtUtils-PkgConfig'}';"
           . "use Glib '$build_reqs{'perl-Glib'}';"
           . "use Gtk2 '$build_reqs{'perl-Gtk2'}';"
           . "use Gnome2::Canvas '$build_reqs{'perl-Gnome2-Canvas'}';"
           . "use Gnome2::Print '$build_reqs{'perl-Gnome2-Print'}';"
           . "use Glib::MakeHelper;"
           . "use Gtk2::CodeGen;"
           . "1") {
  warn "$@\n";
  WriteMakefile(
    PREREQ_FATAL => 1,
    PREREQ_PM    => {
      'Glib'                => $build_reqs{'perl-Glib'},
      'Gtk2'                => $build_reqs{'perl-Gtk2'},
      'Gnome2::Canvas'      => $build_reqs{'perl-Gnome2-Print'},
      'Gnome2::Print'       => $build_reqs{'perl-Gnome2-Print'},
      'ExtUtils::Depends'   => $build_reqs{'perl-ExtUtils-Depends'},
      'ExtUtils::PkgConfig' => $build_reqs{'perl-ExtUtils-PkgConfig'},
    },
  );
  exit 1; # not reached
}

my %pkgcfg = ExtUtils::PkgConfig->find("diacanvas2 >= $build_reqs{'DiaCanvas2'}");

mkdir 'build', 0777;

our @xs_files = <xs/*.xs>;
our %pod_files = (
	'Dia.pm' => '$(INST_MAN3DIR)/Gnome2::Dia.$(MAN3EXT)',
	Glib::MakeHelper->do_pod_files (@xs_files),
);

Gtk2::CodeGen->parse_maps('diacanvas2perl');
Gtk2::CodeGen->write_boot(ignore => qr/^Gnome2::Dia$/);

ExtUtils::PkgConfig->write_version_macros (
  "build/diacanvas2perl-version.h",
  "diacanvas2" => "DIACANVAS",
);

my $diacanvas = ExtUtils::Depends->new('Gnome2::Dia', 'Gnome2::Canvas', 'Gnome2::Print');
$diacanvas->set_inc($pkgcfg{cflags});
$diacanvas->set_libs($pkgcfg{libs});
$diacanvas->add_xs(@xs_files);
$diacanvas->add_pm('Dia.pm' => '$(INST_LIBDIR)/Dia.pm');
$diacanvas->add_typemaps(map {File::Spec->catfile(cwd(), $_)} ('diacanvas.typemap', 'build/diacanvas2perl.typemap'));

$diacanvas->install(qw(diacanvas2perl.h
                       build/diacanvas2perl-autogen.h
                       build/diacanvas2perl-version.h
                       diacanvas.doctypes));
$diacanvas->save_config('build/IFiles.pm');

WriteMakefile(
  NAME          => 'Gnome2::Dia',
  VERSION_FROM  => 'Dia.pm',
  ABSTRACT_FROM => 'Dia.pm',
  XSPROTOARG    => '-noprototypes',
  MAN3PODS      => \%pod_files,
  $diacanvas->get_makefile_vars,
);

sub MY::postamble {
  return Glib::MakeHelper->postamble_clean ()
       . Glib::MakeHelper->postamble_docs_full (
           DEPENDS => $diacanvas,
           COPYRIGHT_FROM => 'copyright.pod',
           DOCTYPES => 'diacanvas.doctypes');
}
