use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Encode::Bootstring',
    AUTHOR              => q{Soren Dossing <netcom@sauber.net>},
    VERSION_FROM        => 'lib/Encode/Bootstring.pm',
    ABSTRACT_FROM       => 'lib/Encode/Bootstring.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Encode-Bootstring-*' },
);
