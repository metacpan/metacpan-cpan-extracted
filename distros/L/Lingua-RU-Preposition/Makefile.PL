use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Lingua::RU::Preposition',
    AUTHOR              => q{Alexander Sapozhnikov <shoorick@cpan.org>},
    VERSION_FROM        => 'lib/Lingua/RU/Preposition.pm',
    ABSTRACT            => 'Lingua::RU::Preposition - Russian preposition choosing',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'List::MoreUtils' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Lingua-RU-Preposition-*' },
);
#     ABSTRACT_FROM       => 'lib/Lingua/RU/Preposition.pm',
