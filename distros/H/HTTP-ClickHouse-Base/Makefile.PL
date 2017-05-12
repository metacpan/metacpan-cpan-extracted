use 5.010000;
use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
    NAME              => 'HTTP::ClickHouse::Base',
    VERSION_FROM      => 'lib/HTTP/ClickHouse/Base.pm',
    PREREQ_PM         => {
        'Scalar::Util'          => 1.46,
        'strict'        => 0,
        'warnings'      => 0,
    },
    ABSTRACT_FROM     => 'lib/HTTP/ClickHouse/Base.pm', # retrieve abstract from module
    AUTHOR            => 'Maxim Motylkov <mmv@cpan.org>',
    LICENSE           => 'perl',
    META_MERGE          => {
        requires        => {
                perl    => '5.10.0'
        }
    }
);
