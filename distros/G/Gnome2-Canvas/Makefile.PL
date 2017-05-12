#
# $Header: /cvsroot/gtk2-perl/gtk2-perl-xs/GnomeCanvas/Makefile.PL,v 1.29 2004/03/29 16:55:57 muppetman Exp $
#

use strict;
use 5.008;
use ExtUtils::MakeMaker;
use Cwd;
use File::Spec;

# minimum required version of dependencies we need to build
our %build_reqs = (
	'perl-ExtUtils-Depends'   => '0.200',
	'perl-ExtUtils-PkgConfig' => '1.03',
	'perl-Glib'               => '1.040',
	'perl-Gtk2'               => '1.040',
	'GnomeCanvas'             => '2.0.0',
);

# Writing a fake Makefile ensures that CPAN will pick up the correct
# dependencies and install them.
unless (eval "use ExtUtils::Depends '$build_reqs{'perl-ExtUtils-Depends'}';"
           . "use ExtUtils::PkgConfig;"
           # just seeing if Glib is available isn't enough, make sure
           # it's recent enough, too 
           . "use Glib '$build_reqs{'perl-Glib'}';"
	   . "use Glib::MakeHelper;"
           . "use Gtk2 '$build_reqs{'perl-Gtk2'}';"
           . "use Gtk2::CodeGen;"
           . "1") {
   warn "$@\n";
   WriteMakefile(
         PREREQ_FATAL => 1,
         PREREQ_PM    => {
            Glib::                => $build_reqs{'perl-Glib'},
            Gtk2::                => $build_reqs{'perl-Gtk2'},
            ExtUtils::Depends::   => $build_reqs{'perl-ExtUtils-Depends'},
            ExtUtils::PkgConfig:: => $build_reqs{'perl-ExtUtils-PkgConfig'},
         },
   );
   exit 1; # not reached
}

my %pkgcfg = ExtUtils::PkgConfig->find ('libgnomecanvas-2.0 >= '
				       . $build_reqs{GnomeCanvas});

mkdir 'build', 0777;

#
# autogeneration
#
Gtk2::CodeGen->parse_maps ('gnomecanvasperl');
Gtk2::CodeGen->write_boot (ignore => '^Gnome2::Canvas$');
ExtUtils::PkgConfig->write_version_macros ("build/gnomecanvasperl-version.h",
                                           'libgnomecanvas-2.0' => 'GNOME_CANVAS');

our @xs_files = <xs/*.xs>;
our %pm_files = ('Canvas.pm' => '$(INST_LIBDIR)/Canvas.pm',);
our %pod_files = Glib::MakeHelper->do_pod_files (@xs_files);
our @typemaps = qw(canvas.typemap build/gnomecanvasperl.typemap);
our @headers = qw(gnomecanvasperl.h
                  build/gnomecanvasperl-autogen.h
                  build/gnomecanvasperl-version.h);


# now we're ready to start creating the makefile.
# we need to use ExtUtils::Depends to get relevant information out of
# the Glib extension, and to save config information for other modules which
# will chain from this one.

my $gnomecanvas = ExtUtils::Depends->new ('Gnome2::Canvas', 'Gtk2');
$gnomecanvas->set_inc ($pkgcfg{cflags});
$gnomecanvas->set_libs ($pkgcfg{libs});
$gnomecanvas->add_xs (@xs_files);
$gnomecanvas->add_pm (%pm_files);
my $cwd = cwd();
$gnomecanvas->add_typemaps (map {File::Spec->catfile($cwd,$_)} @typemaps);

$gnomecanvas->install (@headers);
$gnomecanvas->save_config ('build/IFiles.pm');

WriteMakefile(
    NAME            => 'Gnome2::Canvas',
    VERSION_FROM    => 'Canvas.pm', # finds $VERSION
    ABSTRACT        => 'Perl bindings for the 2.x series of the Gnome Canvas widget',
    XSPROTOARG      => '-noprototypes',
    MAN3PODS        => \%pod_files,
    $gnomecanvas->get_makefile_vars,
);


sub MY::postamble {
	return Glib::MakeHelper->postamble_clean ()
	     . Glib::MakeHelper->postamble_docs_full (
	         DEPENDS => $gnomecanvas,
		 COPYRIGHT => "Copyright (C) 2003-2004 by the Gtk2-Perl Team.\n\nThis software is licensed under the LGPL; see L<Gnome2::Canvas> for a full notice.",
	       )
	     . Glib::MakeHelper->postamble_rpms (
		'GNOME_CANVAS' => $build_reqs{'GnomeCanvas'},
		'PERL_EXTUTILS_DEPENDS' => 
			$build_reqs{'perl-ExtUtils-Depends'},
		'PERL_EXTUTILS_PKGCONFIG' => 
			$build_reqs{'perl-ExtUtils-PkgConfig'},
		'PERL_GLIB' => $build_reqs{'perl-Glib'},
		'PERL_GTK' => $build_reqs{'perl-Gtk2'},
	       );
}
