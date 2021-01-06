#
# $Id$
#

use 5.008;
use strict;
use warnings;
use Cwd;
use File::Spec;
use ExtUtils::MakeMaker;

# minimum required version of dependancies we need to build
our %build_reqs = (
	'perl-ExtUtils-Depends'   => '0.2',
	'perl-ExtUtils-PkgConfig' => '1.03',
	'perl-Glib'               => '1.120', # for Glib::MakeHelper
	'GConf'                   => '2.0.0',
);

# Writing a fake Makefile ensures that CPAN will pick up the correct
# dependencies and install them.
unless (eval "use ExtUtils::Depends '$build_reqs{'perl-ExtUtils-Depends'}';"
           . "use ExtUtils::PkgConfig '$build_reqs{'perl-ExtUtils-PkgConfig'}';"
	   . "use Glib::CodeGen;"
           # just seeing if Glib is available isn't enough, make sure
           # it's recent enough, too 
           . "use Glib '$build_reqs{'perl-Glib'}';"
           . "use Glib::MakeHelper;"
           . "1") {
   warn "$@\n";
   WriteMakefile(
         # don't clobber the existing META.yml
         NO_META      => 1,
         PREREQ_FATAL => 1,
         PREREQ_PM    => {
            'Glib'                => $build_reqs{'perl-Glib'},
            'ExtUtils::Depends'   => $build_reqs{'perl-ExtUtils-Depends'},
            'ExtUtils::PkgConfig' => $build_reqs{'perl-ExtUtils-PkgConfig'},
         },
   );
   exit 1; # not reached
}

mkdir 'build', 0777;

our %pkgcfg = ExtUtils::PkgConfig->find ('gconf-2.0 >= '.$build_reqs{GConf});


our @xs_files = <xs/*.xs>;
our %pm_files = (
    'GConf.pm' => '$(INST_LIBDIR)/GConf.pm',
);
our %pod_files = (
    'GConf.pm' => '$(INST_MAN3DIR)/Gnome2::GConf.$(MAN3EXT)',
    Glib::MakeHelper->do_pod_files (@xs_files),
);

ExtUtils::PkgConfig->write_version_macros ("build/gconfperl-version.h",
                                           'gconf-2.0' => 'GCONF');

#
# autogeneration
#
Glib::CodeGen->parse_maps ('gconfperl');
Glib::CodeGen->write_boot (ignore => '^Gnome2::GConf$');

# now we're ready to start creating the makefile.
# we need to use ExtUtils::Depends to get relevant information out of
# the Glib extension, and to save config information for other modules which
# will chain from this one.
our $gconf = ExtUtils::Depends->new ('Gnome2::GConf', 'Glib');
$gconf->set_inc ($pkgcfg{cflags} . ' -I./build ');
$gconf->set_libs ($pkgcfg{libs});
$gconf->add_xs (@xs_files);
$gconf->add_pm (%pm_files);
my $cwd = cwd();
$gconf->add_typemaps (map { File::Spec->catfile($cwd, $_) }
                      'build/gconfperl.typemap', 'gconf.typemap');
$gconf->install (qw(gconfperl.h
		build/gconfperl-autogen.h
		build/gconfperl-version.h
		doctypes));
$gconf->save_config ('build/IFiles.pm');

WriteMakefile(
    NAME          => 'Gnome2::GConf',
    VERSION_FROM  => 'GConf.pm', # finds $VERSION
    PREREQ_PM     => {}, # e.g., Module::Name => 1.1
    ABSTRACT_FROM => 'GConf.pm', # retrieve abstract from module
    XSPROTOARG    => '-noprototypes',
    # don't clobber the existing META.yml
    NO_META       => 1,
    MAN3PODS	  => \%pod_files,
    $gconf->get_makefile_vars,
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

* Perl URL: https://gitlab.gnome.org/GNOME/perl-gnome2-gconf
* Upstream URL: https://gitlab.gnome.org/Archive/gconf
* Last upstream version: 3.2.6
* Last upstream release date: 2013-01-21
* Migration path for this module: Glib::IO::Settings
* Migration module URL: https://metacpan.org/pod/Glib::IO

NOTICE NOTICE NOTICE NOTICE NOTICE NOTICE NOTICE NOTICE NOTICE NOTICE

__EON__


sub MY::postamble
{
	return Glib::MakeHelper->postamble_clean ()
	     . Glib::MakeHelper->postamble_docs_full (
		DEPENDS => $gconf,
		DOCTYPES => 'doctypes',
		COPYRIGHT_FROM => 'copyright.pod',
	       )
	     . Glib::MakeHelper->postamble_rpms (
		'GCONF' => $build_reqs{'GConf'},
		'PERL_EXTUTILS_DEPENDS' => 
			$build_reqs{'perl-ExtUtils-Depends'},
		'PERL_EXTUTILS_PKGCONFIG' => 
			$build_reqs{'perl-ExtUtils-PkgConfig'},
		'PERL_GLIB' => $build_reqs{'perl-Glib'},
	       );
}
