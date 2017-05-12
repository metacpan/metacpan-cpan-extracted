use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Finance::Kitko::Charts',
    AUTHOR              => q{Alberto Simões <ambs@cpan.org>},
    VERSION_FROM        => 'lib/Finance/Kitko/Charts.pm',
    ABSTRACT_FROM       => 'lib/Finance/Kitko/Charts.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Finance-Kitko-Charts-*' },
);
