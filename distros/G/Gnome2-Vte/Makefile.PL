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
  'perl-Glib'               => '1.01',
  'perl-Gtk2'               => '1.00',
  'Vte'                     => '0.10',
);

our %prereqs = (
  'Glib'                => $build_reqs{'perl-Glib'},
  'Gtk2'                => $build_reqs{'perl-Gtk2'},
  'ExtUtils::Depends'   => $build_reqs{'perl-ExtUtils-Depends'},
  'ExtUtils::PkgConfig' => $build_reqs{'perl-ExtUtils-PkgConfig'},
);

my %meta_merge = (
    q(meta-spec)          => {
        version => '2',
        url     => 'http://search.cpan.org/perldoc?CPAN::Meta::Spec',
    },
    author              =>
        ['Cairo Perl Team <gtk-perl-list at gnome dot org>'],
    release_status      => 'stable',
    # valid values: https://metacpan.org/module/CPAN::Meta::Spec#license
    license             => 'lgpl_2_1',
    resources => {
        license     => 'http://www.gnu.org/licenses/lgpl-2.1.html',
        homepage    => 'http://gtk2-perl.sourceforge.net',
        x_MailingList =>
            'https://mail.gnome.org/mailman/listinfo/gtk-perl-list',
        bugtracker  => {
                web     =>
                'http://rt.cpan.org/Public/Dist/Display.html?Name=Gnome2-Vte',
                mailto  => 'bug-Gnome2-Vte [at] rt.cpan.org',
        },
        repository  => {
                url     => 'git://git.gnome.org/perl-Gnome2-Vte',
                type    => 'git',
                web     => 'http://git.gnome.org/browse/perl-Gnome2-Vte',
        },
    },
    prereqs => {
      configure => {
        requires => {%prereqs}, # no direct ref for 5.14 compatibility
      },
    },
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
    PREREQ_PM    => \%prereqs,
  );
  exit 1; # not reached
}

my %pkgcfg;
unless (eval { %pkgcfg = ExtUtils::PkgConfig->find("vte >= $build_reqs{'Vte'}");
	       1; })
{
  warn $@;
  exit 0;
}

mkdir 'build', 0777;

our @xs_files = <xs/*.xs>;
our %pod_files = (
	'Vte.pm' => '$(INST_MAN3DIR)/Gnome2::Vte.$(MAN3EXT)',
	Glib::MakeHelper->do_pod_files (@xs_files),
);

Gtk2::CodeGen->parse_maps('vte2perl');
Gtk2::CodeGen->write_boot(ignore => qr/^Gnome2::Vte$/);

ExtUtils::PkgConfig->write_version_macros (
  "build/vte2perl-version.h",
  "vte" => "VTE",
);

my $vte = ExtUtils::Depends->new('Gnome2::Vte', 'Gtk2');
$vte->set_inc($pkgcfg{cflags});
$vte->set_libs($pkgcfg{libs});
$vte->add_xs(@xs_files);
$vte->add_pm('Vte.pm' => '$(INST_LIBDIR)/Vte.pm');
$vte->add_typemaps(map {File::Spec->catfile(cwd(), $_)} 'build/vte2perl.typemap');

$vte->install(qw(vte2perl.h build/vte2perl-autogen.h build/vte2perl-version.h));
$vte->save_config('build/IFiles.pm');

WriteMakefile(
  NAME          => 'Gnome2::Vte',
  VERSION_FROM  => 'Vte.pm', # finds $VERSION
  ABSTRACT_FROM => 'Vte.pm', # retrieve abstract from module
  XSPROTOARG    => '-noprototypes',
  MAN3PODS      => \%pod_files,
  PREREQ_PM     => \%prereqs,
  META_MERGE    => \%meta_merge,
  $vte->get_makefile_vars,
);

sub MY::postamble {
	return Glib::MakeHelper->postamble_clean ()
	     . Glib::MakeHelper->postamble_docs_full (
		DEPENDS => $vte,
		COPYRIGHT_FROM => 'copyright.pod')
	     . Glib::MakeHelper->postamble_rpms (
		'GNOME_VTE' => $build_reqs{'Vte'},
		'PERL_EXTUTILS_DEPENDS' =>
			$build_reqs{'perl-ExtUtils-Depends'},
		'PERL_EXTUTILS_PKGCONFIG' =>
			$build_reqs{'perl-ExtUtils-PkgConfig'},
		'PERL_GLIB' => $build_reqs{'perl-Glib'},
		'PERL_GTK' => $build_reqs{'perl-Gtk2'},
	       );
}
