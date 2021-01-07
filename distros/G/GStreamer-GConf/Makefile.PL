#!/usr/bin/perl
use 5.008;
use strict;
use warnings;

use ExtUtils::MakeMaker;

# $Id$

our %build_reqs = (
  'perl-ExtUtils-Depends'   => '0.205',
  'perl-ExtUtils-PkgConfig' => '1.07',
  'perl-GStreamer'          => '0.02',
#  'GStreamerGConf'          => '0.8.0',
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

#my %pkgcfg = ExtUtils::PkgConfig->find("gstreamer-gconf-0.8 >= $build_reqs{'GStreamerGConf'}");

mkdir 'build', 0777;

my $gst = ExtUtils::Depends->new('GStreamer::GConf', 'GStreamer');
#$gst->set_inc($pkgcfg{cflags});
#$gst->set_libs($pkgcfg{libs});
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
  META_MERGE    => { x_deprecated => 1, },
  $gst->get_makefile_vars,
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

* Perl URL: https://gitlab.gnome.org/GNOME/perl-gstreamer-gconf
* Upstream URL: None
* Last upstream version: N/A
* Last upstream release date: N/A
* Migration path for this module: no upstream replacement

NOTICE NOTICE NOTICE NOTICE NOTICE NOTICE NOTICE NOTICE NOTICE NOTICE

__EON__

sub MY::postamble {
  return Glib::MakeHelper->postamble_clean ()
       . Glib::MakeHelper->postamble_docs_full (
           DEPENDS => $gst,
           COPYRIGHT_FROM => 'copyright.pod');
}
