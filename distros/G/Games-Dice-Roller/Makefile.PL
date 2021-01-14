use 5.010;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Games::Dice::Roller',
    AUTHOR           => q{LorenzoTa <LORENZO@cpan.org>},
    VERSION_FROM     => 'lib/Games/Dice/Roller.pm',
    ABSTRACT_FROM    => 'lib/Games/Dice/Roller.pm',
    LICENSE          => 'artistic_2',
    PL_FILES         => {},
    MIN_PERL_VERSION => '5.010',
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '0',
    },
    BUILD_REQUIRES => {
        'Test::More' => '0',
		'Test::Exception' => '0',
    },
    PREREQ_PM => {
		Carp => 0,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Games-Dice-Roller-*' },
);
