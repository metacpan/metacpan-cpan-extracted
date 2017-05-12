use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Hatena::Keyword',
    AUTHOR              => 'Naoya Ito <naoya@bloghackers.net>',
    VERSION_FROM        => 'lib/Hatena/Keyword.pm',
    ABSTRACT_FROM       => 'lib/Hatena/Keyword.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More'               => 0,
        'RPC::XML'                 => 0,
        'Jcode'                    => 0,
        'URI'                      => 0,
        'Class::Data::Inheritable' => 0,
        'Class::Accessor::Fast'    => 0,
        'Class::ErrorHandler'      => 0,
        'Storable'                 => 0,
        'Digest::MD5'              => 0,
        'Cache::File'              => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Hatena-Keyword-*' },
);
