use strict;
use warnings;

use ExtUtils::MakeMaker;

my $meta_merge = {
	META_MERGE => {
		'meta-spec' => { version => 2 },
		resources => {
			repository  =>  {
				type => 'git',
				url => 'https://github.com/dinesh-it/Git-Hooks-CheckYoutrack.git',
				web => 'https://github.com/dinesh-it/Git-Hooks-CheckYoutrack'
			},
		},
	}
};

WriteMakefile(
	'NAME'         => 'Git::Hooks::CheckYoutrack',
	'VERSION_FROM' => 'lib/Git/Hooks/CheckYoutrack.pm',
	'LICENSE'      => 'perl_5',
	'PREREQ_PM'    => {
		'Git::Hooks' => 0,
		'Log::Any' => 0,
		'Path::Tiny' => '0.060',
		'LWP::UserAgent' => 0,
		'URI::Builder' => 0,
		'JSON::XS' => 0,
	},
	"TEST_REQUIRES" => {
		"Config" => 0,
		"Email::Sender::Transport::Mbox" => 0,
		"Path::Tiny" => "0.060",
		"Test::Requires::Git" => 0,
		"lib" => 0
	},
	EXE_FILES                => [],
	"test" => {
		"TESTS" => "t/*.t"
	},
	clean => { FILES => 'Git-Hooks-CheckYoutrack-*' },
	$ExtUtils::MakeMaker::VERSION >= 6.50 ? (%$meta_merge) : (),
	($] >= 5.005 ?    ## Add these new keywords supported since 5.005
		(AUTHOR => 'Dinesh Dharmalingam <dd.dinesh.rajakumar@gmail.com>') : ()),
);
