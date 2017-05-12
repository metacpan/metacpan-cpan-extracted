use 5.005;
use strict;
use ExtUtils::MakeMaker;


sub merge_key_into {
	my ($href, $target, $source) = @_;
	%{$href->{$target}} = (%{$href->{$target}}, %{delete $href->{$source}});
}

my %opt = (
	NAME          => 'Dir::Self',
	AUTHOR        => q{Lukas Mai <l.mai@web.de>},
	VERSION_FROM  => 'lib/Dir/Self.pm',
	ABSTRACT_FROM => 'lib/Dir/Self.pm',

	LICENSE => 'perl',
	PL_FILES => {},

	CONFIGURE_REQUIRES => {
		'strict' => 0,
		'ExtUtils::MakeMaker' => '6.48',
	},
	BUILD_REQUIRES => {},
	TEST_REQUIRES => {
		'Test::More' => 0,
		'lib'        => 0,
	},
	PREREQ_PM => {
		'Carp'       => 0,
		'File::Spec' => 0,
		'strict'     => 0,
	},

	dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
	clean => { FILES    => 'Dir-Self-*' },

	META_MERGE => {
		'meta-spec' => { version => 2 },
		'resources' => {
			repository => {
				url  => 'git://github.com/mauke/Dir-Self.git',
				web  => 'https://github.com/mauke/Dir-Self',
				type => 'git',
			},
		},
	},
);

(my $mm_version = ExtUtils::MakeMaker->VERSION($opt{CONFIGURE_REQUIRES}{'ExtUtils::MakeMaker'})) =~ tr/_//d;

if ($mm_version < 6.67_04) {
	# Why? For the glory of satan, of course!
	*ExtUtils::MM_Any::_add_requirements_to_meta_v1_4 = \&ExtUtils::MM_Any::_add_requirements_to_meta_v2;
}

if ($mm_version < 6.63_03) {
	merge_key_into \%opt, 'BUILD_REQUIRES', 'TEST_REQUIRES';
}

if ($mm_version < 6.55_01) {
	merge_key_into \%opt, 'CONFIGURE_REQUIRES', 'BUILD_REQUIRES';
}

if ($mm_version < 6.51_03) {
	merge_key_into \%opt, 'PREREQ_PM', 'CONFIGURE_REQUIRES';
}

WriteMakefile %opt;
