use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'IO::EditPrompt',
    AUTHOR              => 'G. Wade Johnson <wade@cpan.org>',
    VERSION_FROM        => 'lib/IO/EditPrompt.pm',
    ABSTRACT_FROM       => 'lib/IO/EditPrompt.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More'      => 0,
        'Test::Exception' => 0,
        'File::Temp'      => 0,
        'IO::Prompter'    => 0,
    },
    LICENSE             => 'perl',
    META_MERGE          => {
        'meta-spec' => { version => 2 },
        resources => {
            repository => {
                type => 'git',
                url  => 'https://github.com/gwadej/io-editprompt.git',
                web  => 'https://github.com/gwadej/io-editprompt',
            },
        },
    },
    MIN_PERL_VERSION    => 5.006,
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'IO-EditPrompt-*' },
    test               => {
        TESTS => 't/*.t xt/*.t',
    },
);
