use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Lingua::RU::Inflect',
    AUTHOR              => q{Alexander Sapozhnikov <shoorick@cpan.org>},
    VERSION_FROM        => 'lib/Lingua/RU/Inflect.pm',
    ABSTRACT            => 'Lingua::RU::Inflect - Inflect russian names',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'List::MoreUtils' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Lingua-RU-Inflect-*' },
);
#     ABSTRACT_FROM       => 'lib/Lingua/RU/Inflect.pm',
