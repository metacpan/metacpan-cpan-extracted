use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'DynGig::Range',
    AUTHOR              => 'Kan Liu <kan@cpan.org>',
    VERSION_FROM        => 'lib/DynGig/Range.pm',
    ABSTRACT_FROM       => 'lib/DynGig/Range.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'Carp' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'DynGig-Range-*' },
);
