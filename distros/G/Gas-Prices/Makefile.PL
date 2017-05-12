use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Gas::Prices',
    AUTHOR              => 'Ashish Kasturia <ashoooo@hotmail.com>',
    VERSION_FROM        => 'lib/Gas/Prices.pm',
    ABSTRACT_FROM       => 'lib/Gas/Prices.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'version'    => 0,
	'HTTP::Lite'	=> '0', # or a minimum working version
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Gas-Prices-*' },
);
