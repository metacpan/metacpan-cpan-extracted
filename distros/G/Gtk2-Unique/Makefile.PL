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
	
	# Find libunique
	my @typemaps = ();
	my @deps = ('Glib');
	my %pkgconfig;
	
   my %pre_reqs = (
      # Other versions might work too (Ubuntu 8.04 has this version)
      'Gtk2' => '1.161',
   );
	eval {
		%pkgconfig = ExtUtils::PkgConfig->find("unique-1.0");
		push @XS_FILES, <xs/*.xs>;
		push @typemaps, 'maps';
		push @deps, 'Gtk2';
	};
	if (my $error = $@) {
		warn "FAIL: ", $error;
		return;
	}
	
	$DEPENDS = ExtUtils::Depends->new('Gtk2::Unique', @deps);
	
	$DEPENDS->add_pm(
		File::Spec->catfile('lib', 'Gtk2', 'Unique.pm'),
		File::Spec->catfile('$(INST_LIBDIR)', 'Unique.pm'),
	);
	
	# Code generation
	Gtk2::CodeGen->parse_maps('unique', input => [ @typemaps ]);
	Gtk2::CodeGen->write_boot(
		ignore   => qr/^Gtk2::Unique$/,
		xs_files => [ @XS_FILES ],
	);
	
	
	$DEPENDS->set_inc($pkgconfig{cflags} . ' -I./build');
	$DEPENDS->set_libs($pkgconfig{libs});
	$DEPENDS->add_xs(@XS_FILES);
	$DEPENDS->add_typemaps(
		File::Spec->catfile(cwd(), 'build', 'unique.typemap'),
	);
	$DEPENDS->install(
		File::Spec->catfile('build', 'unique-autogen.h'),
		'unique-perl.h',
	);
	$DEPENDS->save_config(File::Spec->catfile('build', 'IFiles.pm'));
	

	# Create the Makefile
	WriteMakefile(
		AUTHOR        => 'Emmanuel Rodriguez <potyl@cpan.org>',
		NAME          => 'Gtk2::Unique',
		VERSION_FROM  => File::Spec->catfile('lib', 'Gtk2', 'Unique.pm'),
		ABSTRACT_FROM => File::Spec->catfile('lib', 'Gtk2', 'Unique.pm'),
		LICENSE       => 'perl, lgpl',
		PREREQ_PM     => { %pre_reqs, },
		
		XSPROTOARG    => '-noprototypes ',
		MAN3PODS      => {
			Glib::MakeHelper->do_pod_files(@XS_FILES),
		},
		
		META_MERGE => {
			repository => 'http://github.com/potyl/gtk2-unique/tree/master',
         configure_requires => \%pre_reqs,
         x_deprecated       => 1,
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

* Perl URL: https://gitlab.gnome.org/GNOME/perl-gtk2-unique
* Upstream URL: https://gitlab.gnome.org/Archive/unique
* Last upstream version: 1.1.6
* Last upstream release date: 2009-11-12
* Migration path for this module: Gtk3::Application
* Migration module URL: https://metacpan.org/pod/Gtk3

NOTICE NOTICE NOTICE NOTICE NOTICE NOTICE NOTICE NOTICE NOTICE NOTICE

__EON__

	return 0;
}


sub MY::postamble {
	
	my $postamble = Glib::MakeHelper->postamble_clean();
	$postamble .= Glib::MakeHelper->postamble_docs_full(
		DEPENDS   => $DEPENDS,
		XS_FILES  => [ @XS_FILES ],
		COPYRIGHT => 'Copyright (C) 2009-2017 by Emmanuel Rodriguez'
	);
	
	return $postamble;
}
