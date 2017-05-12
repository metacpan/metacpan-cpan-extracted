use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'HTML::WikiConverter::GoogleCode',
    AUTHOR              => 'Marty Kube <martykube@yahoo.com>',
    VERSION_FROM        => 'lib/HTML/WikiConverter/GoogleCode.pm',
    ABSTRACT_FROM       => 'lib/HTML/WikiConverter/GoogleCode.pm',
    PL_FILES            => {},
    PREREQ_PM => {
				'Test::More' => 0,
        'HTML::WikiConverter' => 0.61,
        'Params::Validate' => 0,
        'URI' => 0
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'HTML-WikiConverter-GoogleCode-*' },
    LICENSE	            => 'perl'
);
