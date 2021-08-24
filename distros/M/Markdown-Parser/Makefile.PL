use ExtUtils::MakeMaker;
use strict;
use warnings;

# Call 'perldoc ExtUtils::MakeMaker' for details of how to influence
# the contents of the Makefile that is written.

my %WriteMakefileArgs = (
    NAME                => 'Markdown::Parser',
    VERSION_FROM        => 'lib/Markdown/Parser.pm',
    ABSTRACT_FROM       => 'lib/Markdown/Parser.pm',
    AUTHOR              => 'Jacques Deguest (jack@deguest.jp)',
    INSTALLDIRS         => ($] < 5.011 ? 'perl' : 'site'),
    PL_FILES            => {},
    PREREQ_PM           => {
        'strict'            => 0,
        'warnings'          => 0,
        'parent'            => 0,
        'CSS::Object'       => 'v0.1.4',
        'Devel::Confess'    => '0.009004',
        'HTML::TreeBuilder' => '5.07',
        'Module::Generic'   => 'v0.15.8',
        'Nice::Try'         => 'v1.1.2',
    	'POSIX'             => '1.53_01',
        'URI'               => 0,
    },
    TEST_REQUIRES       => {
        'File::Find'        => 0,
        'Test::More'        => '1.302162',
        'Test::Pod'         => '1.52',
    },
    LICENSE             => 'perl_5',
    MIN_PERL_VERSION    => 'v5.26.1',
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Markdown-Parser-*' },
    ( eval { ExtUtils::MakeMaker->VERSION(6.46) } ? ( META_MERGE => {
        'meta-spec' => { version => 2 },
        dynamic_config => 1,
        resources => {
            # homepage    => undef,
            repository  => {
                url         => 'git@git.deguest.jp:jack/Markdown-Parser.git',
                web         => 'https://git.deguest.jp/jack/Markdown-Parser',
                type        => 'git',
            },
            bugtracker => {
                web         => 'https://git.deguest.jp/jack/Markdown-Parser/issues',
            },
        },
    }) : ()),
);

WriteMakefile(%WriteMakefileArgs);
