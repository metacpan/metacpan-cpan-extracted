use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Lingua::Flags',
    AUTHOR              => 'Alberto Simoes <ambs@cpan.org>',
    VERSION_FROM        => 'lib/Lingua/Flags.pm',
    ABSTRACT_FROM       => 'lib/Lingua/Flags.pm',
    PL_FILES            => {},
    PREREQ_PM => {
	    'MIME::Base64' => 0,
        'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Lingua-Flags-*' },
);
