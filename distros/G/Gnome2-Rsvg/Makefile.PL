#!/usr/bin/perl -w
use 5.008;
use strict;
use ExtUtils::MakeMaker;
use Cwd;
use File::Spec;

my %BUILD_REQ = (
  'librsvg-2.0' => '2.12.0',
);

my %PREREQ_PM = (
  'Gtk2'                => '1.02',
  'Glib'                => '1.02',
  'ExtUtils::Depends'   => '0.20',
  'ExtUtils::PkgConfig' => '1.03',
);

my $dep_success = eval <<"__EOE__";
  use ExtUtils::Depends $PREREQ_PM{'ExtUtils::Depends'};
  use ExtUtils::PkgConfig $PREREQ_PM{'ExtUtils::PkgConfig'};
  use Glib '$PREREQ_PM{'Glib'}';
  use Gtk2 '$PREREQ_PM{'Gtk2'}';
  use Glib::MakeHelper;
  use Gtk2::CodeGen;
  1;
__EOE__
if (!$dep_success) {
  warn $@;
  exit 0;
}

my %rsvg_pkgcfg;
my $cfg_success = eval {
  %rsvg_pkgcfg = ExtUtils::PkgConfig->find (
    "librsvg-2.0 >= $BUILD_REQ{'librsvg-2.0'}");
  1;
};
if (!$cfg_success) {
  warn $@;
  exit 0;
}

###############################################################################

my $CAIRO_PREREQ_PM = '1.00'; # if librsvg-2.0 >= 2.14.0

my @rsvg_version = split /\./, $rsvg_pkgcfg{modversion};
my $need_cairo =
  $rsvg_version[0] > 2 || ($rsvg_version[0] == 2 && $rsvg_version[1] >= 14);
if ($need_cairo) {
  # FIXME: Putting Cairo into %PREREQ_PM here means that whenever the package
  # has librsvg-2.0 >= 2.14, the generated tarball's META.yml will always list
  # Cairo as a dependency.  So, even on machines with librsvg-2.0 < 2.14, we
  # will demand Cairo.
  $PREREQ_PM{Cairo} = $CAIRO_PREREQ_PM;
  unless (eval "use Cairo '$CAIRO_PREREQ_PM'; 1;") {
    warn $@;
    exit 0;
  }
}

###############################################################################

mkdir 'build', 0777;

my @xs_files = <xs/*.xs>;
my %pod_files = (
  'Rsvg.pm' => '$(INST_MAN3DIR)/Gnome2::Rsvg.$(MAN3EXT)',
  Glib::MakeHelper->do_pod_files (@xs_files),
);

Gtk2::CodeGen->parse_maps ('rsvg2perl');
Gtk2::CodeGen->write_boot (ignore => qr/^Gnome2::Rsvg$/);

ExtUtils::PkgConfig->write_version_macros (
  "build/rsvg2perl-version.h",
  "librsvg-2.0" => "LIBRSVG",
);

###############################################################################

my @deps = $need_cairo ? qw(Gtk2 Cairo) : qw(Gtk2);
my $rsvg = ExtUtils::Depends->new ('Gnome2::Rsvg', @deps);
$rsvg->set_inc ($rsvg_pkgcfg{cflags});
$rsvg->set_libs ($rsvg_pkgcfg{libs});
$rsvg->add_xs (@xs_files);
$rsvg->add_pm ('Rsvg.pm' => '$(INST_LIBDIR)/Rsvg.pm');
$rsvg->add_typemaps (map { File::Spec->catfile (cwd(), $_) }
                       'rsvg.typemap',
                       'build/rsvg2perl.typemap');

$rsvg->install (qw(rsvg2perl.h
                   build/rsvg2perl-autogen.h
                   build/rsvg2perl-version.h
                   doctypes));
$rsvg->save_config ('build/IFiles.pm');

WriteMakefile(
  NAME            => 'Gnome2::Rsvg',
  VERSION_FROM    => 'Rsvg.pm', # finds $VERSION
  ABSTRACT_FROM   => 'Rsvg.pm', # retrieve abstract from module
  XSPROTOARG      => '-noprototypes',
  MAN3PODS        => \%pod_files,
  PREREQ_PM       => \%PREREQ_PM,

  META_MERGE => {
    configure_requires => \%PREREQ_PM,
  },

  $rsvg->get_makefile_vars,
);

###############################################################################

sub MY::postamble {
  return Glib::MakeHelper->postamble_clean ()
       . Glib::MakeHelper->postamble_docs_full (
		DEPENDS => $rsvg,
		DOCTYPES => 'doctypes',
		COPYRIGHT_FROM => 'copyright.pod'
         )
       . Glib::MakeHelper->postamble_rpms (
		'GNOME_RSVG' => $BUILD_REQ{'librsvg-2.0'},
		'PERL_EXTUTILS_DEPENDS' =>
			$PREREQ_PM{'ExtUtils-Depends'},
		'PERL_EXTUTILS_PKGCONFIG' =>
			$PREREQ_PM{'ExtUtils-PkgConfig'},
		'PERL_GLIB' => $PREREQ_PM{'Glib'},
		'PERL_GTK' => $PREREQ_PM{'Gtk2'},
	);
}
