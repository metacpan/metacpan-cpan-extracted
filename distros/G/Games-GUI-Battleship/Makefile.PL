use 5.038000;
use strict;
use warnings;
use ExtUtils::MakeMaker;

my %WriteMakefileArgs = (
    NAME             => 'Games::GUI::Battleship',
    AUTHOR           => ['Matt Johnson <mjohnson@affectivesilicon.com>'],
    VERSION_FROM     => 'lib/Games/GUI/Battleship.pm',
    ABSTRACT_FROM    => 'lib/Games/GUI/Battleship.pm',
    LICENSE          => 'gpl_3',
    MIN_PERL_VERSION => '5.038000',
    EXE_FILES        => ['bin/battleship'],
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '0',
    },
    TEST_REQUIRES => {
        'Test2::V0'  => '0.000155',
    },
    PREREQ_PM => {
        'Prima'                     =>  '1.74',
        'Cairo'                     =>  '1.109',
        'Prima::Cairo'              =>  '1.08',
		'Logic::Relational' 		=> 	'0.01',
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Games-GUI-Battleship-*' },
    META_MERGE => {
        'meta-spec' => { version => 2 },
         resources => {
             repository => {
                 type => 'git',
                 url  => 'https://github.com/mjohnson108/p5-Games-GUI-Battleship.git',
                 web  => 'https://github.com/mjohnson108/p5-Games-GUI-Battleship',
             },
             bugtracker => {
                 web => 'https://github.com/mjohnson108/p5-Games-GUI-Battleship/issues'
             },
             homepage   => 'https://github.com/mjohnson108/',
         },
    },
);

# Compatibility with old versions of ExtUtils::MakeMaker
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
