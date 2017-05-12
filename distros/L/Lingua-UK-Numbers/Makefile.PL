use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Lingua::UK::Numbers',
    AUTHOR              => q{"koorchik" <"koorchik@cpan.org">},
    VERSION_FROM        => 'lib/Lingua/UK/Numbers.pm',
    ABSTRACT_FROM       => 'lib/Lingua/UK/Numbers.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Lingua-UK-Numbers-*' },
);
