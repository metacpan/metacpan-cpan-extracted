#!perl
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME         => 'JSON::XS::VersionOneAndTwo',
    VERSION_FROM => 'lib/JSON/XS/VersionOneAndTwo.pm',
    AUTHOR       => 'Leon Brocard <acme@astray.com>',
    LICENSE      => 'perl',
    PREREQ_PM    => {
        'Test::More' => '0',
        'JSON::XS'   => '0',
    },
);
