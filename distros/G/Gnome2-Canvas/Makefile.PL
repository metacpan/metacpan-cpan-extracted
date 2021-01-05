#
# $Id$
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
         NO_META      => 1,
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
    ABSTRACT        => '(DEPRECATED) A structured graphics canvas',
    XSPROTOARG      => '-noprototypes',
    MAN3PODS        => \%pod_files,
    NO_META         => 1,
    $gnomecanvas->get_makefile_vars,
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

Since this module is licensed under the LGPL v2, you may also fork this
module, if you wish, but you will need to use a different name for it on CPAN,
and the Gtk-Perl team requests that you use your own resources (mailing list,
Git repos, bug trackers, etc.) to maintain your fork going forward.

* Perl URL: https://gitlab.gnome.org/GNOME/perl-gnome2-canvas
* Upstream URL: https://gitlab.gnome.org/Archive/libgnomecanvas
* Last upstream version: 2.30.3
* Last upstream release date: 2011-01-31
* Migration path for this module: Cairo
* Migration module URL: https://metacpan.org/pod/Cairo


NOTICE NOTICE NOTICE NOTICE NOTICE NOTICE NOTICE NOTICE NOTICE NOTICE

__EON__

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
