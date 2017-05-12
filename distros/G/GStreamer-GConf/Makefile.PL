#!/usr/bin/perl
use 5.008;
use strict;
use warnings;

use ExtUtils::MakeMaker;

# $Id: Makefile.PL,v 1.1 2005/08/13 17:22:58 kaffeetisch Exp $

our %build_reqs = (
  'perl-ExtUtils-Depends'   => '0.205',
  'perl-ExtUtils-PkgConfig' => '1.07',
  'perl-GStreamer'          => '0.02',
  'GStreamerGConf'          => '0.8.0',
);

our %pre_reqs = (
  'ExtUtils::Depends'   => $build_reqs{'perl-ExtUtils-Depends'},
  'ExtUtils::PkgConfig' => $build_reqs{'perl-ExtUtils-PkgConfig'},
  'GStreamer'           => $build_reqs{'perl-GStreamer'},
);

unless (eval "use ExtUtils::Depends '$build_reqs{'perl-ExtUtils-Depends'}';"
           . "use ExtUtils::PkgConfig '$build_reqs{'perl-ExtUtils-PkgConfig'}';"
           . "use GStreamer '$build_reqs{'perl-GStreamer'}';"
           . "use Glib::MakeHelper;"
           . "1") {
  warn "$@\n";
  WriteMakefile(
    PREREQ_FATAL => 1,
    PREREQ_PM    => \%pre_reqs,
  );
  exit 1; # not reached
}

my %pkgcfg = ExtUtils::PkgConfig->find("gstreamer-gconf-0.8 >= $build_reqs{'GStreamerGConf'}");

mkdir 'build', 0777;

my $gst = ExtUtils::Depends->new('GStreamer::GConf', 'GStreamer');
$gst->set_inc($pkgcfg{cflags});
$gst->set_libs($pkgcfg{libs});
$gst->add_xs(<xs/*.xs>);
$gst->add_pm('GConf.pm' => '$(INST_LIBDIR)/GConf.pm');

$gst->install(qw(gstgconfperl.h));
$gst->save_config('build/IFiles.pm');

WriteMakefile(
  NAME          => 'GStreamer::GConf',
  VERSION_FROM  => 'GConf.pm',
  ABSTRACT_FROM => 'GConf.pm',
  PREREQ_PM     => \%pre_reqs,
  XSPROTOARG    => '-noprototypes',
  $gst->get_makefile_vars,
);

sub MY::postamble {
  return Glib::MakeHelper->postamble_clean ()
       . Glib::MakeHelper->postamble_docs_full (
           DEPENDS => $gst,
           COPYRIGHT_FROM => 'copyright.pod');
}
