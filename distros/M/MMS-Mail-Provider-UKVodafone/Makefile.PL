use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'MMS::Mail::Provider::UKVodafone',
    AUTHOR              => 'Rob Lee <robl@robl.co.uk>',
    VERSION_FROM        => 'lib/MMS/Mail/Provider/UKVodafone.pm',
    ABSTRACT_FROM       => 'lib/MMS/Mail/Provider/UKVodafone.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
	'MMS::Mail::Message::Parsed' => 0.06,
	'HTML::TableExtract' => 0,
	'MMS::Mail::Provider' => 0.06,
	'MIME::Entity'	=> 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'MMS-Mail-Provider-UKVodafone-*' },
);
