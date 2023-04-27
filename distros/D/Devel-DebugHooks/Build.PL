use strict;
use warnings;

use Module::Build;

my $build = Module::Build->new(
	module_name => 'Devel::DebugHooks',
	dist_author => 'Eugen Konkov <cpan@konkov.top>',
	requires => {
		'Scope::Cleanup' =>  0,
		'Sub::Metadata'  =>  0,
		'B::Deparse'     =>  0,
		'Data::Dump'     =>  0,
		'PadWalker'      =>  0,
		'Package::Stash' =>  0,
		'perl'           =>  '5.12.0',
	},
	recommends         => {
		'Log::Log4perl'   =>  0,            # Devel::DebugHooks::TraceAccess.pm
		'IO::Async::Loop' =>  0,            # bin/dclient.pl
	},
	test_requires      => {                 # Requires Module::Build 0.4004
		'Test::More'            =>  0,
		'Test::Output'          =>  0,
		'Test::CheckDeps'       =>  0,
		'Test::Differences'     =>  0,
		'Data::Section::Simple' =>  0,
	},
	configure_requires => {
		'Module::Build'         =>  0.42,   # Recomented by LEONT
	},
	license            => 'perl',
	create_makefile_pl => 'traditional',
	create_license     => 1,
	meta_merge         => {
		resources => {
			# Need help? Feel free to ask questions on:
			x_IRC      =>  "irc://irc.perl.org/#debughooks",
			repository =>  'https://github.com/KES777/Devel-DebugHooks',
			bugtracker =>  'https://github.com/KES777/Devel-DebugHooks/issues',
		},
	},
);

$build->create_build_script;
