use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Hash::SafeKeys',
    AUTHOR              => q{Marty O'Brien <mob@cpan.org>},
    VERSION_FROM        => 'lib/Hash/SafeKeys.pm',
    ABSTRACT_FROM       => 'lib/Hash/SafeKeys.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Hash-SafeKeys-* _Inline' },
);
