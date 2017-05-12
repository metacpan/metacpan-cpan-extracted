#!perl
use strict;
use warnings;
use ExtUtils::MakeMaker;
WriteMakefile(
    NAME         => 'LWP::ConnCache::MaxKeepAliveRequests',
    VERSION_FROM => 'lib/LWP/ConnCache/MaxKeepAliveRequests.pm',
    ABSTRACT     => 'A connection cache that enforces a max keep alive limit',
    AUTHOR       => 'Leon Brocard <acme@astray.com>',
    LICENSE      => 'perl',
    PREREQ_PM    => {
        'LWP'   => '0',
        'Moose' => '0',
    }
);

