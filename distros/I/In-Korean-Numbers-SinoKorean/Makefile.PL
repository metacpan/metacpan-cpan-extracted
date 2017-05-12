use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'In::Korean::Numbers::SinoKorean',
    AUTHOR              => q{Bryan Smith <bryan@cpan.org>},
    VERSION_FROM        => 'lib/In/Korean/Numbers/SinoKorean.pm',
    ABSTRACT_FROM       => 'lib/In/Korean/Numbers/SinoKorean.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'In-Korean-Numbers-SinoKorean-*' },
);
