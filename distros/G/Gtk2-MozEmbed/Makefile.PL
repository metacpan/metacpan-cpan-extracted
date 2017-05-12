#!/usr/bin/perl
use 5.008;
use strict;
use warnings;

use ExtUtils::MakeMaker;
use Config;
use Cwd;
use File::Spec;

# $Id$

our %build_reqs = (
  'perl-ExtUtils-Depends'   => '0.20',
  'perl-ExtUtils-PkgConfig' => '1.03',
  'perl-Glib'               => '1.180',
  'perl-Gtk2'               => '1.081',
  'perl-Mozilla-DOM'        => '0.01',
  'Mozilla'                 => '1.7',
  'Firefox'                 => '1.0',
  'XULRunner'               => '1.8',
);

our %pre_reqs = (
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
    PREREQ_PM    => \%pre_reqs,
  );
  exit 1; # not reached
}

# Check if Mozilla::DOM is installed. (could use an ENABLE_DOM option)
my $use_dom = 1;
unless (eval "use Mozilla::DOM '$build_reqs{'perl-Mozilla-DOM'}'; 1") {
  $use_dom = 0;
}

# If the package can't be found, warn and exit with status 0 to indicate to
# CPAN testers that their system is not supported.
my %pkgcfg;
unless (eval {
          %pkgcfg = ExtUtils::PkgConfig->find(
            "xulrunner-gtkmozembed >= $build_reqs{'XULRunner'}",
            "mozilla-gtkmozembed >= $build_reqs{'Mozilla'}",
            "firefox-gtkmozembed >= $build_reqs{'Firefox'}",
            "mozilla-firefox-gtkmozembed >= $build_reqs{'Firefox'}");
          1; })
{
	warn $@;
	exit 0;
}

mkdir 'build', 0777;

our @xs_files = <xs/*.xs>;
our %pod_files = (
	'lib/Gtk2/MozEmbed.pm' => '$(INST_MAN3DIR)/Gtk2::MozEmbed.$(MAN3EXT)',
	Glib::MakeHelper->do_pod_files (@xs_files),
);

Gtk2::CodeGen->parse_maps('gtkmozembed2perl');
Gtk2::CodeGen->write_boot(ignore => qr/^Gtk2::MozEmbed$/);

my ($pkg) = $pkgcfg{pkg} =~ /^(\S+)/;
print "Compiling against $pkg\n";

ExtUtils::PkgConfig->write_version_macros (
  "build/gtkmozembed2perl-version.h",
  $pkg => "GTK_MOZ_EMBED",
);

my $inc = $pkgcfg{cflags};
my $libs = $pkgcfg{libs};

if ($libs =~ m#(lib|lib64)/xulrunner-(devel|sdk)-([^/]+)#) {
	$inc .= qq( -DGTK_MOZ_EMBED_PERL_XULRUNNER_PATH=)
	      . qq("\\"/usr/$1/xulrunner-$3\\"" );
}

my $mozembed = ExtUtils::Depends->new('Gtk2::MozEmbed', 'Gtk2',
                                      ($use_dom ? ('Mozilla::DOM') : ()));

$mozembed->set_inc($inc);
$mozembed->set_libs($libs);
$mozembed->add_xs(@xs_files);
$mozembed->add_pm('lib/Gtk2/MozEmbed.pm' => '$(INST_LIBDIR)/MozEmbed.pm');
$mozembed->add_typemaps(map { File::Spec->catfile(cwd(), $_) }
                          qw(gtkmozembed.typemap
                             build/gtkmozembed2perl.typemap));

$mozembed->install(qw(gtkmozembed2perl.h
                      build/gtkmozembed2perl-autogen.h));
$mozembed->save_config('build/IFiles.pm');

my $configure_requires =
  Glib::MakeHelper->get_configure_requires_yaml(%pre_reqs);

WriteMakefile(
  NAME          => 'Gtk2::MozEmbed',
  VERSION_FROM  => 'lib/Gtk2/MozEmbed.pm',
  ABSTRACT_FROM => 'lib/Gtk2/MozEmbed.pm',
  PREREQ_PM     => \%pre_reqs,
  XSPROTOARG    => '-noprototypes',
  MAN3PODS      => \%pod_files,

  ($use_dom ? (CC => 'c++', XSOPT => '-C++') : ()),

  $mozembed->get_makefile_vars,

  META_MERGE => {
    configure_requires => \%pre_reqs,
    no_index => {
      file => [@xs_files],
    },
  },
);

sub MY::postamble {
  return Glib::MakeHelper->postamble_clean ()
       . Glib::MakeHelper->postamble_docs_full (
           DEPENDS => $mozembed,
           COPYRIGHT_FROM => 'copyright.pod');
}
