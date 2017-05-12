use 5.006;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Lingua::Sindarin::Dictionary',
    AUTHOR           => q{Felipe da Veiga Leprevost <leprevost@cpan.org>},
    VERSION_FROM     => 'lib/Lingua/Sindarin/Dictionary.pm',
    ABSTRACT_FROM    => 'README.pod',
    LICENSE          => 'Perl_5',
    PL_FILES         => {},
    MIN_PERL_VERSION => 5.006,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'Test::More' => 0,
    },
    PREREQ_PM => {
	'Moose'                 => 0,
	'namespace::autoclean' 	=> 0,
    },
    (! eval { ExtUtils::MakeMaker->VERSION(6.46) } ? () :
        (META_ADD => {
    	    resources => {
                homepage   => 'https://github.com/Leprevost/Lingua-Sindarin-Dictionary',
                repository => 'https://github.com/Leprevost/Lingua-Sindarin-Dictionary.git',
                bugtracker => 'http://rt.cpan.org/NoAuth/Bugs.html?Dist=Lingua-Sindarin-Dictionary',
            },
        })
    ),
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Lingua-Sindarin-Dictionary-*' },
);
