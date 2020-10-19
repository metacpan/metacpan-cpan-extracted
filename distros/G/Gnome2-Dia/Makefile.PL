#!/usr/bin/perl -w
use 5.008;
use strict;

use ExtUtils::MakeMaker;
use Cwd;
use File::Spec;

# $Id$

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
    # don't clobber the existing META.yml
    NO_META      => 1,
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
  # don't clobber the existing META.yml
  NO_META      => 1,
  $diacanvas->get_makefile_vars,
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

* Perl URL: https://gitlab.gnome.org/GNOME/perl-gnome2-dia
* Upstream URL: https://sourceforge.net/projects/diacanvas/
* Last upstream version: 0.15.4 (DiaCanvas2)
* Last upstream release date: 2007-08-03
* Migration path for this module: No upstream replacement

NOTICE NOTICE NOTICE NOTICE NOTICE NOTICE NOTICE NOTICE NOTICE NOTICE

__EON__


sub MY::postamble {
  return Glib::MakeHelper->postamble_clean ()
       . Glib::MakeHelper->postamble_docs_full (
           DEPENDS => $diacanvas,
           COPYRIGHT_FROM => 'copyright.pod',
           DOCTYPES => 'diacanvas.doctypes');
}
