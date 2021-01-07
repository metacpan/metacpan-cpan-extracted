use 5.008;
use ExtUtils::MakeMaker;
use Cwd;
use File::Spec;
use ExtUtils::Depends;
use ExtUtils::PkgConfig;
use Gtk2::CodeGen;

# minimum required version of dependancies we need to build
our %build_reqs = (
	'perl-ExtUtils-Depends'   => '0.20',
	'perl-ExtUtils-PkgConfig' => '1.03',
	'perl-Glib'               => '1.120',
	'perl-Gtk2'               => '1.120',
	'perl-Gnome2-VFS'	  => '1.000',
	'Gnome'			  => '2.0.0',
	'Bonobo'		  => '2.0.0',
);

our %pre_reqs = (
   'Glib'                => $build_reqs{'perl-Glib'},
   'Gtk2'                => $build_reqs{'perl-Gtk2'},
   'Gnome2::VFS'         => $build_reqs{'perl-Gnome2-VFS'},
   'ExtUtils::Depends'   => $build_reqs{'perl-ExtUtils-Depends'},
   'ExtUtils::PkgConfig' => $build_reqs{'perl-ExtUtils-PkgConfig'},
);

# Writing a fake Makefile ensures that CPAN will pick up the correct
# dependencies and install them.
unless (eval "use ExtUtils::Depends '$build_reqs{'perl-ExtUtils-Depends'}';"
           . "use ExtUtils::PkgConfig '$build_reqs{'perl-ExtUtils-PkgConfig'}';"
           # just seeing if Glib is available isn't enough, make sure
           # it's recent enough, too
           . "use Glib '$build_reqs{'perl-Glib'}';"
           . "use Gtk2 '$build_reqs{'perl-Gtk2'}';"
	   . "use Gnome2::VFS '$build_reqs{'perl-Gnome2-VFS'}';"
	   . "use Glib::MakeHelper;"
	   . "use Glib::CodeGen;"
           . "1") {
   warn "$@\n";
   WriteMakefile(
         PREREQ_FATAL => 1,
         PREREQ_PM    => { \%pre_reqs },
   );
   exit 1; # not reached
}

mkdir 'build', 0777;

our @c_files = <recent-files/*.c>;
our @xs_files = <xs/*.xs>;
our %pm_files = (
	'Recent.pm' => '$(INST_LIBDIR)/Recent.pm',
);
our %pod_files = (
	'Recent.pm' => '$(INST_MAN3DIR)/Gtk2::Recent.$(MAN3EXT)',
	Glib::MakeHelper->do_pod_files (@xs_files),
);

my %gnomeui_pkgcfg = ExtUtils::PkgConfig->find ('libgnomeui-2.0 >= '.$build_reqs{Gnome});
my %bonobo_pkgcfg = ExtUtils::PkgConfig->find ('libbonoboui-2.0 >= '.$build_reqs{Bonobo});

Glib::CodeGen->parse_maps ('recentfiles');
Glib::CodeGen->write_boot (ignore => '^Gtk2::Recent$');

$recent = ExtUtils::Depends->new ('Gtk2::Recent', 'Gtk2', 'Glib');
$recent->set_inc ($gtk_pkgcfg{cflags}     . " "
	        . $gnomeui_pkgcfg{cflags} . " "
		. $bonobo_pkgcfg{cflags}  . " "
		. "-DEGG_COMPILATION "
		. "-DEGG_ENABLE_RECENT_FILES");
$recent->set_libs ($gtk_pkgcfg{libs}     . " "
	         . $gnomeui_pkgcfg{libs} . " "
		 . $bonobo_pkgcfg{libs});
$recent->add_c(@c_files);
$recent->add_xs (@xs_files);
$recent->add_pm (%pm_files);
$recent->add_typemaps (map {File::Spec->catfile(cwd(),$_)}
	'build/recentfiles.typemap');

# no installation needed
#$recent->install (qw(recentfiles-perl.h
#					 build/recentfiles-perl-autogen.h));
#$recent->save_config ('build/IFiles.pm');

WriteMakefile(
    NAME          => 'Gtk2::Recent',
    VERSION_FROM  => 'Recent.pm', # finds $VERSION
    ABSTRACT_FROM => 'Recent.pm', # retrieve abstract from module
    XSPROTOARG    => '-noprototypes',
    META_MERGE    => {
       configure_requires => \%pre_reqs,
       x_deprecated       => 1,
    },
    MAN3PODS      => \%pod_files,
    $recent->get_makefile_vars,
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

* Perl URL: https://gitlab.gnome.org/GNOME/perl-gtk2-recent
* Upstream URL: https://gitlab.gnome.org/Archive/libgnome
* Last upstream version: 2.32.1
* Last upstream release date: 2011-01-31
* Migration path for this module: Gtk3::Recent*
* Migration module URL: https://metacpan.org/pod/Gtk3

NOTICE NOTICE NOTICE NOTICE NOTICE NOTICE NOTICE NOTICE NOTICE NOTICE

__EON__


sub MY::postamble
{
	return Glib::MakeHelper->postamble_clean ()
		 . Glib::MakeHelper->postamble_docs_full (
		DEPENDS => $main::recent,
		DOCTYPES => 'doctypes',
		COPYRIGHT_FROM => 'copyright.pod'
		   );
}

# gcc -I. `pkg-config --cflags --libs libgnomeui-2.0 libbonoboui-2.0`
# -DEGG_COMPILATION -DGTK_DISABLE_DEPRECATED -DGDK_DISABLE_DEPRECATED
# -DG_DISABLE_DEPRECATED -g -O2 -Wall --shared egg-recent.so
# egg-recent-*
