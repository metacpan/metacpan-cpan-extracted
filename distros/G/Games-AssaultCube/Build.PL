# Build.PL
use strict; use warnings;
use Module::Build;

my $build = Module::Build->new(
	# look up Module::Build::API for the info!
	'dynamic_config'	=> 0,
	'module_name'		=> 'Games::AssaultCube',
	'license'		=> 'perl',

	'dist_abstract'		=> "The AssaultCube perl libraries",
	'dist_author'		=> 'Apocalypse <APOCAL@cpan.org>',

	'create_packlist'	=> 1,
	'create_makefile_pl'	=> 'traditional',
	'create_readme'		=> 1,
	'create_license'	=> 1,
	'sign'			=> 0,

	'test_files'		=> 't/*.t',

	'add_to_cleanup'	=> [ 'META.yml', 'Makefile.PL', 'README', 'Makefile', 'LICENSE' ],	# automatically generated

	'build_requires'	=> {
		# for serverquery.t
		'Storable'		=> '2.18',	# force latest so it can read the data...
		'MIME::Base64'		=> 0,
		'Test::More'		=> 0,
		'HTTP::Response'	=> 0,
		'DateTime'		=> 0,
	},

	'requires'		=> {
		# our Moose crap :)
		'Moose'				=> 0,
		'Moose::Role'			=> 0,
		'MooseX::StrictConstructor'	=> 0,
		'MooseX::POE::SweetArgs'	=> 0,
		'Moose::Util::TypeConstraints'	=> 0,

		# Socket stuff
		'IO::Socket::INET'		=> 0,
		'LWP::UserAgent'		=> 0,
		'HTTP::Request'			=> 0,

		# Needed for Log::Line
		'DateTime'			=> 0,

		# POE stuff
		'POE::Filter::Stream'		=> 0,
		'POE::Wheel::UDP'		=> 0,
		'Socket'			=> 0,
		'Time::HiRes'			=> 0,

		# perl stuff
		'Exporter'			=> 0,

		# set our minimum perl version ( needed for utf8 support )
		'perl'				=> '5.008',
	},

	# include the standard stuff in META.yml
	'meta_merge'		=> {
		'keywords'	=> [ 'POE', 'AssaultCube' ],
		'resources'	=> {
			'repository'	=> 'http://github.com/apocalypse/perl-games-assaultcube',
			'license'	=> 'http://dev.perl.org/licenses/',
			'bugtracker'	=> 'http://rt.cpan.org/NoAuth/Bugs.html?Dist=Games-AssaultCube',
			'homepage'	=> 'http://search.cpan.org/dist/Games-AssaultCube',
		},
	},
);

# all done!
$build->create_build_script;
