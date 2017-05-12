use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Kwiki::Notify::Mail',
    AUTHOR              => 'James Peregrino <jperegrino@post.harvard.edu>',
    VERSION_FROM        => 'lib/Kwiki/Notify/Mail.pm',
    ABSTRACT_FROM       => 'lib/Kwiki/Notify/Mail.pm',
    PL_FILES            => {},
    PREREQ_PM => {
		  'Test::More' => 0,
		  'MIME::Lite' => 0,
		  'Kwiki'      => 0.37,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Kwiki-Notify-Mail-*' },
);
