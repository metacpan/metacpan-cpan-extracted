# Build.PL
use strict; use warnings;
use Module::Build;

my $build = Module::Build->new(
	# look up Module::Build::API for the info!
	'dynamic_config'	=> 0,
	'module_name'		=> 'Filesys::Virtual::Async::Dispatcher',
	'license'		=> 'perl',

	'dist_abstract'		=> "Mounting multiple FsV objects in a single filesystem made possible",
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

		# portable filesystem operations are a must!
		'File::Spec'			=> 0,

		# system constants
		'Errno'				=> 0,
		'Fcntl'				=> 0,

		# we need a recent perl
		'perl'				=> '5.006',
	},

	# include the standard stuff in META.yml
	'meta_merge'	=> {
		'resources'	=> {
			'license'	=> 'http://dev.perl.org/licenses/',
			'homepage'	=> 'http://search.cpan.org/dist/Filesys-Virtual-Async-Dispatcher',
			'bugtracker'	=> 'http://rt.cpan.org/NoAuth/Bugs.html?Dist=Filesys-Virtual-Async-Dispatcher',
			'repository'	=> 'http://github.com/apocalypse/perl-filesys-virtual-async-dispatcher',
		},
	},
);

# all done!
$build->create_build_script;
