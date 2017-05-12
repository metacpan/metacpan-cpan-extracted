use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Finance::FIX',
    AUTHOR              => q{Blair Christensen <blair.christensen@gmail.com>},
    VERSION_FROM        => 'lib/Finance/FIX.pm',
    ABSTRACT_FROM       => 'lib/Finance/FIX.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Finance-FIX-*' },
);
