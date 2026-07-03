use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME         => 'JSON::JSONFold',
    VERSION_FROM => 'lib/JSON/JSONFold.pm',
    ABSTRACT     => 'Hybrid pretty/compact JSON output',
    AUTHOR       => 'Yair Lenga',
    LICENSE      => 'mit',

    MIN_PERL_VERSION => '5.014',

    PREREQ_PM    => {
	'JSON'      => 0,
        'JSON::PP'  => 0,
        'Exporter'  => 0,
    },

    TEST_REQUIRES => {
        'Test::More' => 0,
        'IPC::Open3' => 0,
        'Symbol'     => 0,
    },
    EXE_FILES => [ 'script/jsonfold.pl' ],
    test         => { TESTS => 't/*.t' },

    META_MERGE => {
        'meta-spec' => { version => 2 },
        resources => {
            homepage => 'https://jsonfold.dev',
            repository => {
                type => 'git',
                url  => 'https://github.com/ylenga/jsonfold.git',
                web  => 'https://github.com/ylenga/jsonfold',
            },
            bugtracker => {
                web => 'https://github.com/ylenga/jsonfold/issues',
            },
        },
        keywords => [qw(json formatter pretty-print compact streaming folding)],
    },
);
