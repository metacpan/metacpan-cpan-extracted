# Build.PL
use strict; use warnings;
use Module::Build;

my $build = Module::Build->new(
	# look up Module::Build::API for the info!
	'dynamic_config'	=> 0,
	'module_name'		=> 'Filesys::Virtual::Async::inMemory',
	'license'		=> 'perl',

	'dist_abstract'		=> "In-Memory filesystem using the Filesys::Virtual::Async API",
	'dist_author'		=> 'Apocalypse <APOCAL@cpan.org>',

	'create_packlist'	=> 1,
	'create_makefile_pl'	=> 'traditional',
	'create_readme'		=> 1,
	'create_license'	=> 1,
	'sign'			=> 0,

	'test_files'		=> 't/*.t',

	'add_to_cleanup'	=> [ 'META.yml', 'Makefile.PL', 'README', 'Makefile', 'LICENSE' ], # automatically generated

	'requires'		=> {
		# our superclass
		'Filesys::Virtual::Async'	=> 0,

		# system constants
		'Errno'				=> 0,
		'Fcntl'				=> 0,

		# handy in-memory FHs
		'IO::Scalar'			=> 0,
		'File::Spec'			=> 0,

		# we need a recent perl
		'perl'				=> '5.006',
	},

	# include the standard stuff in META.yml
	'meta_merge'	=> {
		'resources'	=> {
			'license'	=> 'http://dev.perl.org/licenses/',
			'homepage'	=> 'http://search.cpan.org/dist/Filesys-Virtual-Async-inMemory',
			'bugtracker'	=> 'http://rt.cpan.org/NoAuth/Bugs.html?Dist=Filesys-Virtual-Async-inMemory',
			'repository'	=> 'http://github.com/apocalypse/perl-filesys-virtual-async-inmemory',
		},
	},
);

# all done!
$build->create_build_script;
