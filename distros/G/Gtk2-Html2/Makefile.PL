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
	'perl-ExtUtils-PkgConfig' => '0.1',
	'perl-Glib'               => '1.04',
	'perl-Gtk2'               => '1.00',
	'gtkhtml2'                => '2.0.0',
);

our %pre_reqs = (
   'Glib'                  => $build_reqs{'perl-Glib'},
   'Gtk2'                  => $build_reqs{'perl-Gtk2'},
   'ExtUtils::Depends'     => $build_reqs{'perl-ExtUtils-Depends'},
   'ExtUtils::PkgConfig'   => $build_reqs{'perl-ExtUtils-PkgConfig'},
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
         PREREQ_PM    => { \%pre_reqs },
   );
   exit 1; # not reached
}

#my %pkgcfg = ExtUtils::PkgConfig->find ('libgtkhtml-2.0 >= '
#				       . $build_reqs{gtkhtml2});

mkdir 'build', 0777;

#
# autogeneration
#
Gtk2::CodeGen->parse_maps ('gtkhtml2perl');
Gtk2::CodeGen->write_boot (ignore => '^Gtk2::Html2$');

our @xs_files = <xs/*.xs>;
our %pm_files = ('Html2.pm' => '$(INST_LIBDIR)/Html2.pm',);
our %pod_files = Glib::MakeHelper->do_pod_files (@xs_files);

# now we're ready to start creating the makefile.
# we need to use ExtUtils::Depends to get relevant information out of
# the Glib extension, and to save config information for other modules which
# will chain from this one.

my $gtkhtml2 = ExtUtils::Depends->new ('Gtk2::Html2', 'Gtk2');
#$gtkhtml2->set_inc ($pkgcfg{cflags});
#$gtkhtml2->set_libs ($pkgcfg{libs});
$gtkhtml2->add_xs (@xs_files);
$gtkhtml2->add_pm ('Html2.pm' => '$(INST_LIBDIR)/Html2.pm');
$gtkhtml2->add_typemaps (File::Spec->catfile(cwd(), 'build/gtkhtml2perl.typemap'));

$gtkhtml2->install (qw(gtkhtml2perl.h build/gtkhtml2perl-autogen.h));
$gtkhtml2->save_config ('build/IFiles.pm');

WriteMakefile(
    NAME            => 'Gtk2::Html2',
    VERSION_FROM    => 'Html2.pm', # finds $VERSION
    ABSTRACT        => '(DEPRECATED) Perl bindings for the GtkHtml2 Html display widget',
    PREREQ_PM       => { \%pre_reqs },
    XSPROTOARG      => '-noprototypes',
    META_MERGE    => {
       configure_requires => \%pre_reqs,
       x_deprecated => 1,
    },
    MAN3PODS        => \%pod_files,
    $gtkhtml2->get_makefile_vars,
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

* Perl URL: https://gitlab.gnome.org/GNOME/perl-gtk2-html2
* Upstream URL: https://gitlab.gnome.org/Archive/gtkhtml2
* Last upstream version: 2.11.1
* Last upstream release date: 2007-08-13
* Migration path for this module: maybe Gtk3::WebKit
* Migration module URL: https://metacpan.org/pod/Gtk3::WebKit

NOTICE NOTICE NOTICE NOTICE NOTICE NOTICE NOTICE NOTICE NOTICE NOTICE

__EON__
sub MY::postamble {
	return Glib::MakeHelper->postamble_clean ()
	     . Glib::MakeHelper->postamble_docs_full (
	         DEPENDS => $gtkhtml2,
		 COPYRIGHT => "Copyright (C) 2003-2004 by the Gtk2-Perl Team.\n\nThis software is licensed under the LGPL; see L<Gtk2::Html2> for a full notice.",
	       )
	     . Glib::MakeHelper->postamble_rpms (
		'GTK_HTML2' => $build_reqs{'gtkhtml2'},
		'PERL_EXTUTILS_DEPENDS' => 
			$build_reqs{'perl-ExtUtils-Depends'},
		'PERL_EXTUTILS_PKGCONFIG' => 
			$build_reqs{'perl-ExtUtils-PkgConfig'},
		'PERL_GLIB' => $build_reqs{'perl-Glib'},
		'PERL_GTK' => $build_reqs{'perl-Gtk2'},
	       );
}
