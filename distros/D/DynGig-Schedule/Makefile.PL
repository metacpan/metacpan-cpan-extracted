use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'DynGig::Schedule',
    AUTHOR              => q{Kan Liu <kan@cpan.org>},
    VERSION_FROM        => 'lib/DynGig/Schedule.pm',
    ABSTRACT_FROM       => 'lib/DynGig/Schedule.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'Carp' => 0,
        'DateTime' => 0,
        'DynGig::Range' => 0,
        'DynGig::Range::Time' => 0,
        'YAML::XS' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'DynGig-Schedule-*' },
);
