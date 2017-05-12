use strict;
use warnings;

use ExtUtils::MakeMaker;

use Cwd;
use File::Spec;

use Glib::CodeGen;
use Glib::MakeHelper;
use ExtUtils::Depends;
use ExtUtils::PkgConfig;

my $DEPENDS;
my @XS_FILES = ();

exit main();

sub main {
	
	# Create the build folder used by the code generation utilities
	mkdir 'build', 0777;
	
	# The version of memphis for which this module can built against
	my $memphis_version = '0.2';
	
	# Find libmemphis
	my @typemaps = ();
	my @deps = ('Glib', 'Cairo');
	my %pkgconfig;

	eval {
		%pkgconfig = ExtUtils::PkgConfig->find("memphis-$memphis_version");
		push @XS_FILES, <xs/*.xs>;
		push @typemaps, 'maps';
		push @deps, 'Glib';
	};
	if (my $error = $@) {
		warn "FAIL: ", $error;
		return;
	}

	
	$DEPENDS = ExtUtils::Depends->new('Memphis', @deps);
	$DEPENDS->add_pm(
		File::Spec->catfile('lib', 'Memphis.pm'),
		File::Spec->catfile('$(INST_LIBDIR)', 'Memphis.pm'),
	);

	# Code generation
	Glib::CodeGen->parse_maps('memphis', input => [ @typemaps ]);
	Glib::CodeGen->write_boot(
		xs_files => [ @XS_FILES ],
		ignore   => qr/^Memphis$/,
	);
	
	
	$DEPENDS->set_inc($pkgconfig{cflags} . ' -I./build');
	$DEPENDS->set_libs($pkgconfig{libs});
	$DEPENDS->add_xs(@XS_FILES);
	$DEPENDS->add_typemaps(
		File::Spec->catfile(cwd(), 'build', 'memphis.typemap')
	);
	$DEPENDS->install(
		File::Spec->catfile('build', 'memphis-autogen.h'),
		'memphis-perl.h',
	);
	$DEPENDS->save_config(File::Spec->catfile('build', 'IFiles.pm'));
	

	# Create the Makefile
	WriteMakefile(
		AUTHOR        => 'Emmanuel Rodriguez <potyl@cpan.org>',
		NAME          => 'Memphis',
		VERSION_FROM  => File::Spec->catfile('lib', 'Memphis.pm'),
		ABSTRACT_FROM => File::Spec->catfile('lib', 'Memphis.pm'),
		LICENSE       => 'perl, lgpl',

		PREREQ_PM     => {
			'Glib'  => '1.180',
			'Cairo' => '1.000',
		},
		PREREQ_FATAL  => 1, # Glib is mandatory otherwise the Makefile can't be created
		
		XSPROTOARG    => '-noprototypes ',
		MAN3PODS      => {
			Glib::MakeHelper->do_pod_files(@XS_FILES),
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
		COPYRIGHT => 'Copyright (C) 2010 by Emmanuel Rodriguez'
	);

	return $postamble;
}
