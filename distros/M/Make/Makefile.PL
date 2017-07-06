use strict;
use warnings;

use ExtUtils::MakeMaker;

my %WriteMakefileArgs = (
	"ABSTRACT"           => "module for processing makefiles",
	"AUTHOR"             => "Nick Ing-Simmons",
	"CONFIGURE_REQUIRES" => {
		"ExtUtils::MakeMaker" => 0
	},
	"DISTNAME"   => "Make",
	"EXE_FILES"  => [],
	"LICENSE"    => "perl",
	"META_MERGE" => {
		dynamic_config => 0,
		'meta-spec'    => { version => 2 },
		no_index       => { directory => ['t'] },
		prereqs        => { runtime => { requires => { perl => '5.006' } } },
		resources      => {
			bugtracker => { web => 'http://github.com/klp2/Make/issues' },
			homepage   => 'http://metacpan.org/pod/Make',
			repository => {
				type => 'git',
				url  => 'http://github.com/klp2/Make.git',
				web  => 'http://github.com/klp2/Make',
			},
			x_IRC => 'irc://irc.perl.org/#perl'
		},
	},
	"MIN_PERL_VERSION" => "5.006",
	"NAME"             => "Make",
	"PREREQ_PM"        => {
		"Carp"       => 0,
		"Config"     => 0,
		"Cwd"        => 0,
		"File::Spec" => 0,
		"strict"     => 0,
		"warnings"   => 0
	},
	"TEST_REQUIRES" => {
		"ExtUtils::MakeMaker" => 0,
		"Test::Compile"       => "1.002001",
		"Test::More"          => "1.00",
		"Test::Pod"           => "1.00",
	},
	"VERSION" => "1.1.5",
	"test"    => {
		"TESTS" => "t/*.t"
	}
);

my %FallbackPrereqs = (
	"Carp"                => 0,
	"Config"              => 0,
	"Cwd"                 => 0,
	"File::Spec"          => 0,
	"ExtUtils::MakeMaker" => 0,
	"File::Spec"          => 0,
	"Test::Compile"       => "1.002001",
	"Test::More"          => "1.00",
	"Test::Pod"           => "1.00",
	"strict"              => 0,
	"warnings"            => 0
);

unless ( eval { ExtUtils::MakeMaker->VERSION(6.63_03) } ) {
	delete $WriteMakefileArgs{TEST_REQUIRES};
	delete $WriteMakefileArgs{BUILD_REQUIRES};
	$WriteMakefileArgs{PREREQ_PM} = \%FallbackPrereqs;
}

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
	unless eval { ExtUtils::MakeMaker->VERSION(6.52) };

WriteMakefile(%WriteMakefileArgs);
