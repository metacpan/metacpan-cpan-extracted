use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'GSM::Nbit',
    AUTHOR              => q{Aleksandar Petrovic <techcode@cpan.org>},
    VERSION_FROM        => 'lib/GSM/Nbit.pm',
    ABSTRACT_FROM       => 'lib/GSM/Nbit.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'GSM-Nbit-*' },
);
