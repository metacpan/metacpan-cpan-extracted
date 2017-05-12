use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'IntervalTree',
    AUTHOR              => q{Ben Booth <benwbooth@gmail.com>},
    VERSION_FROM        => 'lib/IntervalTree.pm',
    ABSTRACT_FROM       => 'lib/IntervalTree.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'IntervalTree-*' },
);
