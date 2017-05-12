use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'MMS::Mail::Provider::UKVirgin',
    AUTHOR              => 'Rob Lee <robl@robl.co.uk>',
    VERSION_FROM        => 'lib/MMS/Mail/Provider/UKVirgin.pm',
    ABSTRACT_FROM       => 'lib/MMS/Mail/Provider/UKVirgin.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'MMS::Mail::Message::Parsed' => 0.06,
        'MMS::Mail::Provider' => 0.06,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'MMS-Mail-Provider-UKVirgin-*' },
);
