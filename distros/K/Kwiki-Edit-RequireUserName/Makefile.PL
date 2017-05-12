use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Kwiki::Edit::RequireUserName',
    AUTHOR              => 'James Peregrino <jperegrino@post.harvard.edu>',
    VERSION_FROM        => 'lib/Kwiki/Edit/RequireUserName.pm',
    ABSTRACT_FROM       => 'lib/Kwiki/Edit/RequireUserName.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More'             => 0,
	'Kwiki'                  => 0.37,
        'Kwiki::Edit'            => 0,
        'Kwiki::UserPreferences' => 0,
	'Kwiki::UserName'        => 0.13,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Kwiki-Edit-RequireUserName-*' },
);
