use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Error::Helper',
    AUTHOR              => q{Zane C. Bowers-Hadley <vvelox@vvelox.net>},
    VERSION_FROM        => 'lib/Error/Helper.pm',
    ABSTRACT_FROM       => 'lib/Error/Helper.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Error-Helper-*' },
);
