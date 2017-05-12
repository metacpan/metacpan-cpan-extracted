#
# $Header: /cvsroot/gtk2-perl/gtk2-perl-xs/Gtk2-GLExt/Makefile.PL,v 1.7 2004/10/29 00:18:43 rwmcfa1 Exp $
#

use 5.008;
use ExtUtils::MakeMaker;
use Cwd;
use File::Spec;
use ExtUtils::MakeMaker;

# minimum required version of dependancies we need to build
our %build_reqs = (
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

%pkgcfg = ExtUtils::PkgConfig->find ('gtkglext-1.0 >= '
				     .$build_reqs{GtkGLExt});

our @xs_files = <xs/*.xs>;
our %pod_files = (
	'GLExt.pm'          => '$(INST_MAN3DIR)/Gtk2::GLExt.$(MAN3EXT)',
	Glib::MakeHelper->do_pod_files (@xs_files),
);

mkdir 'build', 0777;

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
    MAN3PODS        => \%pod_files,
    $gtkglext->get_makefile_vars,
);

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
