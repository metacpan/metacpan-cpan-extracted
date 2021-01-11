use 5.008;
use strict;
use warnings;
use Cwd;
use File::Spec;
use ExtUtils::MakeMaker;

# minimum required version of dependancies we need to build
our %build_reqs = (
	'perl-ExtUtils-Depends'   => '0.2',
	'perl-ExtUtils-PkgConfig' => '1.0',
	'perl-Glib'               => '1.103',
	'perl-Gtk2'               => '1.100',
	'perl-Gnome2-Print'       => '0.60',
	'GtkSourceView'           => '0.5.0',
);

our %prereqs = (
	'Glib'                => $build_reqs{'perl-Glib'},
	'Gtk2'                => $build_reqs{'perl-Gtk2'},
	'Gnome2::Print'       => $build_reqs{'perl-Gnome2-Print'},
	'ExtUtils::Depends'   => $build_reqs{'perl-ExtUtils-Depends'},
	'ExtUtils::PkgConfig' => $build_reqs{'perl-ExtUtils-PkgConfig'},
);

# Writing a fake Makefile ensures that CPAN will pick up the correct
# dependencies and install them.
unless (eval "use ExtUtils::Depends;"
           . "use ExtUtils::PkgConfig;"
	   . "use Gtk2::CodeGen;"
           # just seeing if Glib is available isn't enough, make sure
           # it's recent enough, too 
           . "use Glib '$build_reqs{'perl-Glib'}';"
           . "use Gtk2 '$build_reqs{'perl-Gtk2'}';"
           . "use Gnome2::Print '$build_reqs{'perl-Gnome2-Print'}';"
           . "use Glib::MakeHelper;"
           . "1") {
   warn "$@\n";
   WriteMakefile(
         PREREQ_FATAL => 1,
         PREREQ_PM    => \%prereqs,
   );
   exit 1; # not reached
}

mkdir 'build', 0777;

#our %pkgcfg = ExtUtils::PkgConfig->find ('gtksourceview-1.0 >= '
#				     .$build_reqs{GtkSourceView});

# now we're ready to start creating the makefile.
# we need to use ExtUtils::Depends to get relevant information out of
# the Glib extension, and to save config information for other modules which
# will chain from this one.

our @xs_files = <xs/*.xs>;
our %pm_files = (
    'SourceView.pm' => '$(INST_LIBDIR)/SourceView.pm',
);
our %pod_files = (
    'SourceView.pm' => '$(INST_MAN3DIR)/Gtk2::SourceView.$(MAN3EXT)',
    Glib::MakeHelper->do_pod_files (@xs_files),
);

#ExtUtils::PkgConfig->write_version_macros ("build/gtksourceviewperl-version.h",
#                                           'gtksourceview-1.0' => 'GTK_SOURCE_VIEW');

#
# autogeneration
#
Gtk2::CodeGen->parse_maps ('gtksourceviewperl');
Gtk2::CodeGen->write_boot (ignore => '^Gtk2::SourceView$');

my $sview = ExtUtils::Depends->new ('Gtk2::SourceView', 'Gnome2::Print', 'Gtk2', 'Glib');
#$sview->set_inc ($pkgcfg{cflags} . ' -I./build ');
#$sview->set_libs ($pkgcfg{libs});
$sview->add_xs (@xs_files);
$sview->add_pm (%pm_files);
my $cwd = cwd();
$sview->add_typemaps (File::Spec->catfile($cwd, 'build/gtksourceviewperl.typemap'));
$sview->install (qw(gtksourceviewperl.h
		build/gtksourceviewperl-autogen.h
		build/gtksourceviewperl-version.h));
$sview->save_config ('build/IFiles.pm');

WriteMakefile(
    NAME          => 'Gtk2::SourceView',
    VERSION_FROM  => 'SourceView.pm', # finds $VERSION
    PREREQ_PM     => \%prereqs,
    ABSTRACT_FROM => 'SourceView.pm', # retrieve abstract from module
    XSPROTOARG    => '-noprototypes',
    META_MERGE    => { x_deprecated => 1, },
    MAN3PODS      => \%pod_files,
    $sview->get_makefile_vars,
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

* Perl URL: https://gitlab.gnome.org/GNOME/perl-gtk2-sourceview
* Upstream URL: https://gitlab.gnome.org/GNOME/gtksourceview
* Last compatible upstream version: 1.8.6
* Last upstream release date: 2007-05-01
* Migration path for this module: G:O:I
* Migration module URL: https://metacpan.org/pod/Glib::Object::Introspection

NOTICE NOTICE NOTICE NOTICE NOTICE NOTICE NOTICE NOTICE NOTICE NOTICE

__EON__

sub MY::postamble
{
	return Glib::MakeHelper->postamble_clean ()
	     . Glib::MakeHelper->postamble_docs (@main::xs_files)
	     . Glib::MakeHelper->postamble_rpms (
		'GTK_SOURCE_VIEW' => $build_reqs{'GtkSourceView'},
		'PERL_EXTUTILS_DEPENDS' => 
			$build_reqs{'perl-ExtUtils-Depends'},
		'PERL_EXTUTILS_PKGCONFIG' => 
			$build_reqs{'perl-ExtUtils-PkgConfig'},
		'PERL_GLIB' => $build_reqs{'perl-Glib'},
		'PERL_GTK' => $build_reqs{'perl-Gtk2'},
	       );
}
