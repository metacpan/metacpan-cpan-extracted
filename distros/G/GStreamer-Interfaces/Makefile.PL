#!/usr/bin/perl

BEGIN { require 5.008; }

use strict;
use warnings;

use ExtUtils::MakeMaker;
use Cwd qw(cwd);
use File::Spec;

# $Id$

our %build_reqs = (
  'perl-ExtUtils-Depends'       => '0.205',
  'perl-ExtUtils-PkgConfig'     => '1.07',
  'perl-Glib'                   => '1.180',
  'perl-GStreamer'              => '0.06',
  'gstreamer-plugins-base-0.10' => '0.10.0',
);

our %pre_reqs = (
  'ExtUtils::Depends'   => $build_reqs{'perl-ExtUtils-Depends'},
  'ExtUtils::PkgConfig' => $build_reqs{'perl-ExtUtils-PkgConfig'},
  'Glib'                => $build_reqs{'perl-Glib'},
  'GStreamer'           => $build_reqs{'perl-GStreamer'},
);

unless (eval "use ExtUtils::Depends '$build_reqs{'perl-ExtUtils-Depends'}';"
           . "use ExtUtils::PkgConfig '$build_reqs{'perl-ExtUtils-PkgConfig'}';"
           . "use GStreamer '$build_reqs{'perl-GStreamer'}';"
           . "use Glib '$build_reqs{'perl-Glib'}';"
           . "use Glib::MakeHelper;"
           . "use Glib::CodeGen;"
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
my %pkgcfg;
unless (eval { %pkgcfg = ExtUtils::PkgConfig->find (
                 "gstreamer-plugins-base-0.10 >= $build_reqs{'gstreamer-plugins-base-0.10'}");
	       1; })
{
	warn $@;
	exit 0;
}

mkdir 'build', 0777;

Glib::CodeGen->parse_maps('gstinterfacesperl');
Glib::CodeGen->write_boot(ignore => qr/^GStreamer::Interfaces$/);

ExtUtils::PkgConfig->write_version_macros (
  "build/gstinterfacesperl-version.h",
  "gstreamer-plugins-base-0.10" => "GST_INTERFACES",
);

my $gst = ExtUtils::Depends->new('GStreamer::Interfaces', 'GStreamer');
$gst->set_inc($pkgcfg{cflags});
$gst->set_libs($pkgcfg{libs} . ' -lgstinterfaces-0.10');
$gst->add_xs(<xs/*.xs>);
$gst->add_pm('lib/GStreamer/Interfaces.pm' => '$(INST_LIBDIR)/Interfaces.pm');
$gst->add_typemaps(map {File::Spec->catfile(cwd(), $_)}
                       ('build/gstinterfacesperl.typemap'));

$gst->install(qw(gstinterfacesperl.h
                 build/gstinterfacesperl-autogen.h
                 build/gstinterfacesperl-version.h));
$gst->save_config('build/IFiles.pm');

my $configure_requires =
  Glib::MakeHelper->get_configure_requires_yaml(%pre_reqs);

WriteMakefile(
  NAME          => 'GStreamer::Interfaces',
  VERSION_FROM  => 'lib/GStreamer/Interfaces.pm',
  ABSTRACT_FROM => 'lib/GStreamer/Interfaces.pm',
  PREREQ_PM     => \%pre_reqs,
  XSPROTOARG    => '-noprototypes',

  META_MERGE    => {
    configure_requires => \%pre_reqs,
  },

  $gst->get_makefile_vars,
);

sub MY::postamble {
  return Glib::MakeHelper->postamble_clean ();
}
