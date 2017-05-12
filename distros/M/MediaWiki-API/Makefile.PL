use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'MediaWiki::API',
    AUTHOR              => 'Jools Wills <buzz@exotica.org.uk>',
    VERSION_FROM        => 'lib/MediaWiki/API.pm',
    ABSTRACT_FROM       => 'lib/MediaWiki/API.pm',
    LICENSE             => 'GPL-3+',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More'     => 0.98,
        'JSON'           => 0,
        'LWP::UserAgent' => 0,
        'Encode'         => 0,
        'Carp'           => 0
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'MediaWiki-API-*' },
);
