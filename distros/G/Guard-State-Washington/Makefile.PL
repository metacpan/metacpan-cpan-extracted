use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Guard::State::Washington',
    AUTHOR              => q{C.J. Adams-Collier <cjac@uw.edu>},
    VERSION_FROM        => 'lib/Guard/State/Washington.pm',
    ABSTRACT_FROM       => 'lib/Guard/State/Washington.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Guard-State-Washington-*' },
);
