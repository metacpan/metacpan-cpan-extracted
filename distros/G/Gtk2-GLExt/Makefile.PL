#
# $Id$
#

use 5.008;
use ExtUtils::MakeMaker;
use Cwd;
use File::Spec;
use ExtUtils::MakeMaker;

# minimum required version of dependancies we need to build
my %build_reqs = (
	'perl-ExtUtils-Depends'   => '0.2',
	'perl-ExtUtils-PkgConfig' => '1.03',
	'perl-Glib'               => '1.060',
	'perl-Gtk2'               => '1.060',
	'GtkGLExt'		  => '1.0',
);

# Writing a fake Makefile ensures that CPAN will pick up the correct
# dependencies and install them.
unless (eval "use ExtUtils::Depends '$build_reqs{'perl-ExtUtils-Depends'}';"
           . "use ExtUtils::PkgConfig '$build_reqs{'perl-ExtUtils-PkgConfig'}';"
	   . "use Glib '$build_reqs{'perl-Glib'}';"
           . "use Glib::MakeHelper;" # for do_pod_files()
	   . "use Gtk2 '$build_reqs{'perl-Gtk2'}';"
           . "use Gtk2::CodeGen;"
           . "1") {
   warn "$@\n";
   WriteMakefile(
         PREREQ_FATAL => 1,
         PREREQ_PM    => {
            Glib::                => $build_reqs{'perl-Glib'},
            Gtk2::                => $build_reqs{'perl-Glib'},
            ExtUtils::Depends::   => $build_reqs{'perl-ExtUtils-Depends'},
            ExtUtils::PkgConfig:: => $build_reqs{'perl-ExtUtils-PkgConfig'},
         },
   );
   exit 1; # not reached
}

my %pkgcfg = ExtUtils::PkgConfig->find ('gtkglext-1.0 >= '
				       .$build_reqs{GtkGLExt});

mkdir 'build', 0777;

our @xs_files = <xs/*.xs>;
our %pod_files = (
	'GLExt.pm'          => '$(INST_MAN3DIR)/Gtk2::GLExt.$(MAN3EXT)',
	Glib::MakeHelper->do_pod_files (@xs_files),
);

#
# autogeneration
#
Gtk2::CodeGen->parse_maps ('gtkglextperl');
Gtk2::CodeGen->write_boot (ignore => '^Gtk2::GLExt$');

# now we're ready to start creating the makefile.
# we need to use ExtUtils::Depends to get relevant information out of
# the Glib extension, and to save config information for other modules which
# will chain from this one.

$gtkglext = ExtUtils::Depends->new ('Gtk2::GLExt', 'Gtk2');
$gtkglext->set_inc ($pkgcfg{cflags});
$gtkglext->set_libs ($pkgcfg{libs});
$gtkglext->add_xs (<xs/*.xs>);
$gtkglext->add_pm ('GLExt.pm' => '$(INST_LIBDIR)/GLExt.pm');
my $cwd = cwd();
$gtkglext->add_typemaps (map {File::Spec->catfile($cwd,$_)} 'build/gtkglextperl.typemap');

$gtkglext->install (qw(gtkglextperl.h build/gtkglextperl-autogen.h));
$gtkglext->save_config ('build/IFiles.pm');

WriteMakefile(
    NAME            => 'Gtk2::GLExt',
    VERSION_FROM    => 'GLExt.pm', # finds $VERSION
    XSPROTOARG      => '-noprototypes',
    META_MERGE      => { x_deprecated => 1, },
    MAN3PODS        => \%pod_files,
    $gtkglext->get_makefile_vars,
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

* Perl URL: https://gitlab.gnome.org/GNOME/perl-gtk2-glext
* Upstream URL: https://gitlab.gnome.org/Archive/gtkglext
* Last upstream version: N/A
* Last upstream release date: N/A
* Migration path for this module: Gtk3::GLArea
* Migration module URL: https://metacpan.org/pod/Glib::Object::Introspection

NOTICE NOTICE NOTICE NOTICE NOTICE NOTICE NOTICE NOTICE NOTICE NOTICE

__EON__


sub MY::postamble
{
	return Glib::MakeHelper->postamble_clean ()
	     . Glib::MakeHelper->postamble_docs (@main::xs_files)
	     . Glib::MakeHelper->postamble_rpms (
			'GTK_GL_EXT' => $build_reqs{'GtkGLExt'},
			'PERL_EXTUTILS_DEPENDS' => 
				$build_reqs{'perl-ExtUtils-Depends'},
			'PERL_EXTUTILS_PKGCONFIG' => 
				$build_reqs{'perl-ExtUtils-PkgConfig'},
			'PERL_GLIB' => $build_reqs{'perl-Glib'},
			'PERL_GTK' => $build_reqs{'perl-Gtk2'},
		);
}
