use utf8;
use strict;
use warnings;
use ExtUtils::MakeMaker;

my %WriteMakefileArgs = (
    NAME               => 'Math::RPN::Simple',
    AUTHOR             => q{Michał Wróblewski <debos@cpan.org>},
    VERSION_FROM       => 'lib/Math/RPN/Simple.pm',
    ABSTRACT_FROM      => 'lib/Math/RPN/Simple.pm',
    LICENSE            => 'mit',
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '0',
    },
    PREREQ_PM          => {
        'Carp'       => '0',
		'Exporter'   => '0',
		'List::Util' => '1.33',
    },
	(! eval { ExtUtils::MakeMaker->VERSION('6.46') } ? () :
        (META_MERGE => {
            dynamic_config => 0,
            'meta-spec'    => { version => 2 },
            resources      => {
                homepage   => 'https://github.com/DeBos99/Math-RPN-Simple',
                repository => {
                    type => 'git',
                    url  => 'https://github.com/DeBos99/Math-RPN-Simple.git',
                    web  => 'https://github.com/DeBos99/Math-RPN-Simple',
                },
                bugtracker => { web => 'https://github.com/DeBos99/Math-RPN-Simple/issues' },
            },
        })
    ),
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Math-RPN-Simple-*' },
);

unless (eval { ExtUtils::MakeMaker->VERSION('6.64'); 1 }) {
    my $test_requires = delete $WriteMakefileArgs{TEST_REQUIRES} || {};
    @{$WriteMakefileArgs{PREREQ_PM}}{keys %$test_requires} = values %$test_requires;
}

unless (eval { ExtUtils::MakeMaker->VERSION('6.55_03'); 1 }) {
    my $build_requires = delete $WriteMakefileArgs{BUILD_REQUIRES} || {};
    @{$WriteMakefileArgs{PREREQ_PM}}{keys %$build_requires} = values %$build_requires;
}

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
    unless eval { ExtUtils::MakeMaker->VERSION('6.52'); 1 };
delete $WriteMakefileArgs{MIN_PERL_VERSION}
    unless eval { ExtUtils::MakeMaker->VERSION('6.48'); 1 };
delete $WriteMakefileArgs{LICENSE}
    unless eval { ExtUtils::MakeMaker->VERSION('6.31'); 1 };

WriteMakefile(%WriteMakefileArgs);
