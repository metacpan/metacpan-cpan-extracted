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
  'perl-Glib'               => '1.120',
  'GnomeVFS'                => '2.0.0',
);

our %PREREQ_PM = (
  "Glib"                => $build_reqs{'perl-Glib'},
  "ExtUtils::Depends"   => $build_reqs{'perl-ExtUtils-Depends'},
  "ExtUtils::PkgConfig" => $build_reqs{'perl-ExtUtils-PkgConfig'},
);

unless (eval "use ExtUtils::Depends '$build_reqs{'perl-ExtUtils-Depends'}';"
           . "use ExtUtils::PkgConfig '$build_reqs{'perl-ExtUtils-PkgConfig'}';"
           . "use Glib '$build_reqs{'perl-Glib'}';"
           . "use Glib::MakeHelper;"
	   . "use Glib::CodeGen;"
           . "1") {
  warn "$@\n";
  WriteMakefile(
    PREREQ_FATAL => 1,
    PREREQ_PM    => \%PREREQ_PM,
  );
  exit 1; # not reached
}

my %vfs_pkgcfg = ExtUtils::PkgConfig->find("gnome-vfs-2.0 >= $build_reqs{GnomeVFS}");

###############################################################################

mkdir 'build', 0777;

my ($major, $minor, $micro) = split /\./, $vfs_pkgcfg{modversion};
my $needs_gtypes = ($major < 2 or
                    $major == 2 && $minor < 5 or
                    $major == 2 && $minor == 5 && $micro < 3);

if ($needs_gtypes) {
  chomp(my $vfs_includes = `pkg-config --variable includedir gnome-vfs-2.0`);
  my @vfs_headers = glob($vfs_includes . "/gnome-vfs-2.0/libgnomevfs/*.h");

  system(q(glib-mkenums --fhead "#ifndef __VFS2PERL_GTYPES_H__\n" ) .
                      q(--fhead "#define __VFS2PERL_GTYPES_H__ 1\n\n" ) .
                      q(--fhead "#include <glib-object.h>\n\n" ) .
                      q(--fhead "G_BEGIN_DECLS\n\n" ) .
                      q(--eprod "#ifndef GNOME_VFS_TYPE_@ENUMSHORT@\n" ) .
                      q(--eprod "#define GNOME_VFS_TYPE_@ENUMSHORT@ vfs2perl_@enum_name@_get_type()\n" ) .
                      q(--eprod "GType vfs2perl_@enum_name@_get_type (void);\n" ) .
                      q(--eprod "#endif /* !GNOME_VFS_TYPE_@ENUMSHORT@ */\n" ) .
                      q(--ftail "G_END_DECLS\n\n" ) .
                      q(--ftail "#endif /* __VFS2PERL_GTYPES_H__ */\n" ) .
                      "@vfs_headers > build/vfs2perl-gtypes.h");

  system(q(glib-mkenums --fhead "#include <libgnomevfs/gnome-vfs-types.h>\n" ) .
                      q(--fhead "#include <libgnomevfs/gnome-vfs-utils.h>\n" ) .
                      q(--fhead "#include <libgnomevfs/gnome-vfs-monitor.h>\n" ) .
                      q(--fhead "#include <libgnomevfs/gnome-vfs-mime-handlers.h>\n" ) .
                      q(--fhead "#include <libgnomevfs/gnome-vfs-directory.h>\n" ) .
                      q(--vhead "static const G@Type@Value _vfs2perl_@enum_name@_values[] = {" ) .
                      q(--vprod "  { @VALUENAME@, \"@VALUENAME@\", \"@valuenick@\" }," ) .
                      q(--vtail "  { 0, NULL, NULL }\n};\n\n" ) .
                      q(--vtail "GType\nvfs2perl_@enum_name@_get_type (void)\n{\n" ) .
                      q(--vtail "  static GType type = 0;\n\n" ) .
                      q(--vtail "  if (!type)\n" ) .
                      q(--vtail "    type = g_@type@_register_static (\"@EnumName@\", _vfs2perl_@enum_name@_values);\n\n" ) .
                      q(--vtail "  return type;\n}\n\n" ) .
                      "@vfs_headers > build/vfs2perl-gtypes.c");

  # UGLY, UGLY, UGLY!
  system("perl -pi -e 's/GNOME_VFS_TYPE_VFSURI_HIDE_OPTIONS/GNOME_VFS_TYPE_VFS_URI_HIDE_OPTIONS/g;
	               s/vfs2perl_gnome_vfsuri_hide_options/vfs2perl_gnome_vfs_uri_hide_options/g' build/vfs2perl-gtypes.h build/vfs2perl-gtypes.c");
}
else {
  open GTYPES, ">build/vfs2perl-gtypes.h" or die("Opening '>build/vfs2perl-gtypes.h': $!");
  print GTYPES "#include <libgnomevfs/gnome-vfs-enum-types.h>\n";
  close GTYPES;
}

###############################################################################

my @xs_files = ();

foreach (Glib::MakeHelper->select_files_by_version ("xs_files", split /\./, $vfs_pkgcfg{modversion})) {
	push @xs_files, Glib::MakeHelper->read_source_list_file ($_);
}

my %pod_files = (
  'VFS.pm' => '$(INST_MAN3DIR)/Gnome2::VFS.$(MAN3EXT)',
  Glib::MakeHelper->do_pod_files (@xs_files),
);

Glib::CodeGen->parse_maps ('vfs2perl', input => [<maps-*\.*>]);
Glib::CodeGen->write_boot (xs_files => \@xs_files,
                           ignore => qr/^Gnome2::VFS$/);

ExtUtils::PkgConfig->write_version_macros (
  "build/vfs2perl-version.h",
  "gnome-vfs-2.0" => "VFS",
);

###############################################################################

my $vfs = ExtUtils::Depends->new ('Gnome2::VFS', 'Glib');
$vfs->set_inc ($vfs_pkgcfg{cflags} . " -I build");
$vfs->set_libs ($vfs_pkgcfg{libs});
$vfs->add_xs (@xs_files);
$vfs->add_c ("vfs2perl.c");
$vfs->add_c ("build/vfs2perl-gtypes.c") if ($needs_gtypes);
$vfs->add_pm ('VFS.pm' => '$(INST_LIBDIR)/VFS.pm');
$vfs->add_typemaps (map {File::Spec->catfile(cwd(), $_)} 'build/vfs2perl.typemap', 'vfs.typemap');

$vfs->install (qw(vfs2perl.h
                  build/vfs2perl-autogen.h
                  build/vfs2perl-version.h
                  build/vfs2perl-gtypes.h
                  doctypes));
$vfs->save_config ('build/IFiles.pm');

WriteMakefile(
  NAME            => 'Gnome2::VFS',
  VERSION_FROM    => 'VFS.pm', # finds $VERSION
  ABSTRACT_FROM   => 'VFS.pm', # retrieve abstract from module
  PREREQ_PM       => \%PREREQ_PM,
  XSPROTOARG      => '-noprototypes',
  MAN3PODS        => \%pod_files,
  $vfs->get_makefile_vars,
);

###############################################################################

sub MY::postamble {
  return Glib::MakeHelper->postamble_clean ()
       . Glib::MakeHelper->postamble_docs_full (
		DEPENDS => $vfs,
		DOCTYPES => 'doctypes',
		COPYRIGHT_FROM => 'copyright.pod'
         )
       . Glib::MakeHelper->postamble_rpms (
		'GNOME_VFS' => $build_reqs{'GnomeVFS'},
		'PERL_EXTUTILS_DEPENDS' => 
			$build_reqs{'perl-ExtUtils-Depends'},
		'PERL_EXTUTILS_PKGCONFIG' => 
			$build_reqs{'perl-ExtUtils-PkgConfig'},
		'PERL_GLIB' => $build_reqs{'perl-Glib'},
	);
}
