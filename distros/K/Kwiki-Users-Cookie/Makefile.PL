use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Kwiki::Users::Cookie',
    AUTHOR              => 'John cappiello <jcap@cpan.org>',
    VERSION_FROM        => 'lib/Kwiki/Users/Cookie.pm',
    ABSTRACT_FROM       => 'lib/Kwiki/Users/Cookie.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More'   => 0,
				'Kwiki::Users' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Kwiki-Users-Cookie-*' },
);
