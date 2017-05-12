use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Filter::Cleanup',
    AUTHOR              => q{"Jeff Ober" <"jeffober@gmail.com">},
    VERSION_FROM        => 'lib/Filter/Cleanup.pm',
    ABSTRACT            => 'Blah blah blah',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002 ? ('LICENSE'=> 'perl') : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'PPI'        => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Filter-Cleanup-*' },
);
