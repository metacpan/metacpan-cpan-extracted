package Devel::FakeOSName;

use ExtUtils::MakeMaker;

BEGIN { require 5.002 }

use strict;

WriteMakefile(
    NAME           => __PACKAGE__,
    VERSION_FROM   => 'FakeOSName.pm',
    PREREQ_PM      => { 'Test::More' => 0, },
    dist => {
        PREOP        => 'pod2text FakeOSName.pm > $(DISTVNAME)/README', 
        COMPRESS     => 'gzip -9f',
        SUFFIX       => '.gz',
        ZIP          => 'zip',
        ZIPFLAGS     => '-r',
        DIST_DEFAULT => 'tardist',
    },
);
