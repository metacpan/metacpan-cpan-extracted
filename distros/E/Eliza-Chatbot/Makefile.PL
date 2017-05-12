use strict;
use warnings;
use ExtUtils::MakeMaker;
use Module::Metadata;

WriteMakefile(
    NAME             => 'Eliza::Chatbot',
    AUTHOR           => q{Robert Acock <thisusedtobeanemail@gmail.com>},
    VERSION_FROM     => 'lib/Eliza/Chatbot.pm',
    ABSTRACT_FROM    => 'lib/Eliza/Chatbot.pm',
    LICENSE          => 'artistic_2',
    PL_FILES         => {},
    MIN_PERL_VERSION => 5.006,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'Test::More' => 0,
        'Array::Utils' => 0.5,
        'Ref::Util' => 0.0020,
    },
    PREREQ_PM => {
        'Moo'              => 1.0010001,
        'MooX::LazierAttributes' => 0.07,
        'Ref::Util'        => 0.0020,
    	'strict'		   => 0,
		'warnings'		   => 0,
	},
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Eliza-Chatbot-*' },
    META_MERGE => {
        'meta-spec' => { version => 2 },
        resources => {
            repository => {
                type => 'git',
                url  => 'https://github.com/ThisUsedToBeAnEmail/Eliza-Chatbot.git',
                web  => 'https://github.com/ThisUsedToBeAnEmail/Eliza-Chatbot',
            },
        },
    },
    META_ADD => {
        provides => Module::Metadata->provides(version => '2', dir => 'lib'),
	}, 
);
