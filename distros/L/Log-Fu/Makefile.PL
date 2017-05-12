use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    META_MERGE  => {
        'recommends' => {
            'Term::Terminfo' => 0
        }
    },
    NAME                => 'Log::Fu',
    AUTHOR              => q{M. Nunberg <mnunberg@haskalah.org>},
    VERSION_FROM        => 'lib/Log/Fu.pm',
    ABSTRACT_FROM       => 'lib/Log/Fu.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More'            => 0,
        'Dir::Self'             => 0,
        'Constant::Generate'    => 0.04
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Log-Fu-*' },
);
