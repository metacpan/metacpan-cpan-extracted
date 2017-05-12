use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'MMS::Mail::Parser',
    AUTHOR              => 'Rob Lee <robl@robl.co.uk>',
    VERSION_FROM        => 'lib/MMS/Mail/Parser.pm',
    ABSTRACT_FROM       => 'lib/MMS/Mail/Parser.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
	'MMS::Mail::Message' => 0.06,
	'MMS::Mail::Message::Parsed' => 0.06,
	'MIME::Parser' => 5.4,
	'MMS::Mail::Provider' => 0.06,
	'Class::Accessor' => 0.19,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'MMS-Mail-Parser-*' },
);
