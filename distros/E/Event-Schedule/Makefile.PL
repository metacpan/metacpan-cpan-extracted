use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Event::Schedule',
    AUTHOR              => 'Michael Roberts <michael@vivtek.com>',
    VERSION_FROM        => 'lib/Event/Schedule.pm',
    ABSTRACT_FROM       => 'lib/Event/Schedule.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Event-Schedule-*' },
);
