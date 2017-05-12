#
# $Header: /cvsroot/gtk2-perl/gtk2-perl-xs/GnomePrint2/Makefile.PL,v 1.29 2006/11/15 09:38:18 ebassi Exp $
#

use 5.008;
use strict;
use warnings;
use Cwd;
use File::Spec;
use ExtUtils::MakeMaker;

# minimum required version of dependancies we need to build
our %build_reqs = (
	'perl-ExtUtils-Depends'   => '0.1',
	'perl-ExtUtils-PkgConfig' => '1.03',
	'perl-Glib'               => '1.120',
	'perl-Gtk2'               => '1.120',
	'GnomePrint'              => '2.2.0.0',
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
           . "use Glib::MakeHelper;"
           . "1") {
   warn "$@\n";
   WriteMakefile(
         PREREQ_FATAL => 1,
         PREREQ_PM    => {
            'Glib'                => $build_reqs{'perl-Glib'},
            'Gtk2'                => $build_reqs{'perl-Gtk2'},
            'ExtUtils::Depends'   => $build_reqs{'perl-ExtUtils-Depends'},
            'ExtUtils::PkgConfig' => $build_reqs{'perl-ExtUtils-PkgConfig'},
         },
   );
   exit 1; # not reached
}

mkdir 'build', 0777;

our %pkgcfg = ExtUtils::PkgConfig->find ('libgnomeprintui-2.2 >= '
                                         . $build_reqs{GnomePrint});

our @xs_files = <xs/*.xs>;
our %pm_files = (
    'Print.pm'		=> '$(INST_LIBDIR)/Print.pm',
    'pm/Config.pm'	=> '$(INST_LIBDIR)/Print/Config/Constants.pm',
    'pm/Font.pm'	=> '$(INST_LIBDIR)/Print/Font/Constants.pm',
);
our %pod_files = (
    'Print.pm'		=> '$(INST_MAN3DIR)/Gnome2::Print.$(MAN3EXT)',
    'pm/Config.pm'	=> '$(INST_MAN3DIR)/Gnome2::Print::Config::Constants.$(MAN3EXT)',
    'pm/Font.pm'	=> '$(INST_MAN3DIR)/Gnome2::Print::Font::Constants.$(MAN3EXT)',
    Glib::MakeHelper->do_pod_files (@xs_files),
);

ExtUtils::PkgConfig->write_version_macros ("build/gnomeprintperl-version.h",
                                           'libgnomeprintui-2.2' => 'GNOMEPRINT');

#
# autogeneration
#
Gtk2::CodeGen->parse_maps ('gnomeprintperl');
Gtk2::CodeGen->write_boot (ignore => '^Gnome2::Print$');

my $gnomeprint2 = ExtUtils::Depends->new ('Gnome2::Print', 'Gtk2', 'Glib');
$gnomeprint2->set_inc ($pkgcfg{cflags} . ' -I. -I./build ');
$gnomeprint2->set_libs ($pkgcfg{libs});
$gnomeprint2->add_xs (@xs_files);
$gnomeprint2->add_pm (%pm_files);
my $cwd = cwd();
$gnomeprint2->add_typemaps (map { File::Spec->catfile ($cwd, $_) }
							'build/gnomeprintperl.typemap', 'gnomeprint.typemap');
$gnomeprint2->install (qw(gnomeprintperl.h
		build/gnomeprintperl-autogen.h
		build/gnomeprintperl-version.h));
$gnomeprint2->save_config ('build/IFiles.pm');

WriteMakefile(
    NAME          => 'Gnome2::Print',
    VERSION_FROM  => 'Print.pm', # finds $VERSION
    PREREQ_PM     => {}, # e.g., Module::Name => 1.1
    ABSTRACT_FROM => 'Print.pm', # retrieve abstract from module
    XSPROTOARG    => '-noprototypes',
    MAN3PODS	  => \%pod_files,
    $gnomeprint2->get_makefile_vars,
);

sub MY::postamble
{
	return Glib::MakeHelper->postamble_clean ()
	     . Glib::MakeHelper->postamble_docs_full (
            DEPENDS => $gnomeprint2,
            DOCTYPES => 'doctypes',
            COPYRIGHT_FROM => 'copyright.pod',
		   )
	     . Glib::MakeHelper->postamble_rpms (
            'GNOMEPRINT' => $build_reqs{'GnomePrint'},
            'PERL_EXTUTILS_DEPENDS' => $build_reqs{'perl-ExtUtils-Depends'},
            'PERL_EXTUTILS_PKGCONFIG' => $build_reqs{'perl-ExtUtils-PkgConfig'},
            'PERL_GLIB' => $build_reqs{'perl-Glib'},
            'PERL_GTK' => $build_reqs{'perl-Gtk2'},
	       );
}
