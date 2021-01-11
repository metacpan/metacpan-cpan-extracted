use strict;
use warnings;

use ExtUtils::MakeMaker;

use Cwd;
use File::Spec;

use Gtk2::CodeGen;
use Glib::MakeHelper;
use ExtUtils::Depends;
use ExtUtils::PkgConfig;

my $DEPENDS;
my @XS_FILES = ();

exit main();

sub main {
	
	# Create the build folder used by the code generation utilities
	mkdir 'build', 0777;
	
	my @typemaps = ();
	my @deps = ('Glib');
	my %pkgconfig;
	
	# Find gtksourceview 2.0
	eval {
		%pkgconfig = ExtUtils::PkgConfig->find("gtksourceview-2.0");
		push @XS_FILES, <xs/*.xs>;
		push @typemaps, 'maps';
		push @deps, 'Gtk2';
	};
	if (my $error = $@) {
		warn "FAIL: ", $error;
		return;
	}
	
	$DEPENDS = ExtUtils::Depends->new('Gtk2::SourceView2', @deps);
	
	$DEPENDS->add_pm(
		File::Spec->catfile('lib', 'Gtk2', 'SourceView2.pm'),
		File::Spec->catfile('$(INST_LIBDIR)', 'SourceView2.pm'),
	);
	
	# Code generation
	Gtk2::CodeGen->parse_maps('gtk2-sourceview2', input => [ @typemaps ]);
	Gtk2::CodeGen->write_boot(
		ignore   => qr/^Gtk2::SourceView2$/,
		xs_files => [ @XS_FILES ],
	);
	
	
	$DEPENDS->set_inc($pkgconfig{cflags} . ' -I./build');
	$DEPENDS->set_libs($pkgconfig{libs});
	$DEPENDS->add_xs(@XS_FILES);
	$DEPENDS->add_typemaps(
		File::Spec->catfile(cwd(), 'build', 'gtk2-sourceview2.typemap'),
	);
	$DEPENDS->install(
		File::Spec->catfile('build', 'gtk2-sourceview2-autogen.h'),
		'gtk2-sourceview2-perl.h',
	);
	$DEPENDS->save_config(File::Spec->catfile('build', 'IFiles.pm'));
	

	# Create the Makefile
	WriteMakefile(
		AUTHOR        => 'Emmanuel Rodriguez <potyl@cpan.org>',
		NAME          => 'Gtk2::SourceView2',
		VERSION_FROM  => File::Spec->catfile('lib', 'Gtk2', 'SourceView2.pm'),
		ABSTRACT_FROM => File::Spec->catfile('lib', 'Gtk2', 'SourceView2.pm'),
		LICENSE       => 'perl, gpl',

		PREREQ_PM     => {
			'Gtk2' => '1.160',
		},

		CONFIGURE_REQUIRES => {
			'Gtk2::CodeGen'       => 0,
			'Glib::MakeHelper'    => 0,
			'ExtUtils::Depends'   => 0,
			'ExtUtils::PkgConfig' => 0,
		},

		PREREQ_FATAL  => 1,
		
		XSPROTOARG    => '-noprototypes',
		MAN3PODS      => {
			Glib::MakeHelper->do_pod_files(@XS_FILES),
		},
		
		META_MERGE => {
			repository => 'http://github.com/potyl/gtk2-sourceview2',
         x_deprecated => 1,
		},
		
		$DEPENDS->get_makefile_vars(),
		
		# Remove the build folder when doing "make clean"
		clean => {
			FILES => 'build',
		},
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

* Perl URL: https://gitlab.gnome.org/GNOME/perl-gtk2-sourceview2
* Upstream URL: https://gitlab.gnome.org/GNOME/gtksourceview
* Last compatible upstream version: 2.10.5
* Last upstream release date: 2010-09-28
* Migration path for this module: G:O:I
* Migration module URL: https://metacpan.org/pod/Glib::Object::Introspection

NOTICE NOTICE NOTICE NOTICE NOTICE NOTICE NOTICE NOTICE NOTICE NOTICE

__EON__

	return 0;
}


sub MY::postamble {
	
	my $postamble = Glib::MakeHelper->postamble_clean();
	$postamble .= Glib::MakeHelper->postamble_docs_full(
		DEPENDS   => $DEPENDS,
		XS_FILES  => [ @XS_FILES ],
		COPYRIGHT => 'Copyright (C) 2009 by Emmanuel Rodriguez'
	);
	
	return $postamble;
}
