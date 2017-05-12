use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Hatena::API::Auth',
    AUTHOR              => 'Naoya Ito <naoya@bloghackers.net>',
    VERSION_FROM        => 'lib/Hatena/API/Auth.pm',
    ABSTRACT_FROM       => 'lib/Hatena/API/Auth.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More'            => 0,
        'Class::Accessor::Fast' => 0,
        'Class::ErrorHandler'   => 0,
        'LWP::UserAgent'        => 0,
        'Digest::MD5'           => 0,
        'JSON'                  => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Hatena-API-Auth-*' },
);
