use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Kwiki::UserName::Cookie',
    AUTHOR              => 'John cappiello <jcap@cpan.org>',
    VERSION_FROM        => 'lib/Kwiki/UserName/Cookie.pm',
    ABSTRACT_FROM       => 'lib/Kwiki/UserName/Cookie.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More'       => 0,
				'Kwiki::UserName'  => 0,
				'Kwiki::Installer' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Kwiki-UserName-Cookie-*' },
);
