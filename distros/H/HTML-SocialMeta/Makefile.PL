use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'HTML::SocialMeta',
    AUTHOR           => q{Robert Acock <ThisUsedToBeAnEmail@gmail.com>},
    VERSION_FROM     => 'lib/HTML/SocialMeta.pm',
    ABSTRACT_FROM    => 'lib/HTML/SocialMeta.pm',
    LICENSE          => 'artistic_2',
    PL_FILES         => {},
    MIN_PERL_VERSION => 5.006,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'Test::More' => 0,
        'Test::Exception' => 0
    },
    PREREQ_PM => {
        'Moo' => 1.001001,
    	'List::MoreUtils' => 0.413,
        'MooX::LazierAttributes' => 0.14,
        'MooX::ValidateSubs' => 0.09,
        'Type::Tiny' => '1.000006',
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'HTML-SocialMeta-*' },
);
