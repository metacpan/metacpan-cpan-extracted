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

		PREREQ_PM     => {
			'Gtk2' => '1.161', # Other verions might work too (Ubuntu 8.04 has this version)
		},
		PREREQ_FATAL  => 1,
		
		XSPROTOARG    => '-noprototypes ',
		MAN3PODS      => {
			Glib::MakeHelper->do_pod_files(@XS_FILES),
		},
		
		META_MERGE => {
			repository => 'http://github.com/potyl/gtk2-unique/tree/master',
		},
		
		$DEPENDS->get_makefile_vars(),
		
		# Remove the build folder when doing "make clean"
		clean => {
			FILES => 'build',
		},
	);
	
	return 0;
}


sub MY::postamble {
	
	my $postamble = Glib::MakeHelper->postamble_clean();
	$postamble .= Glib::MakeHelper->postamble_docs_full(
		DEPENDS   => $DEPENDS,
		XS_FILES  => [ @XS_FILES ],
		COPYRIGHT => 'Copyright (C) 2009-2010 by Emmanuel Rodriguez'
	);
	
	return $postamble;
}
