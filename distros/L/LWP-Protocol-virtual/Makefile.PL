use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'LWP::Protocol::virtual',
    AUTHOR              => 'Rich Paul <cpan@rich-paul.net>',
    VERSION_FROM        => 'lib/LWP/Protocol/virtual.pm',
    ABSTRACT_FROM       => 'lib/LWP/Protocol/virtual.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
		'URI' => 0,
		'LWP' => 0
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'LWP-Protocol-virtual-*' },
);
