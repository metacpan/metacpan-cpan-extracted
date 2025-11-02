use strict;
use warnings;
use ExtUtils::MakeMaker;

my $resources = {
    homepage => 'https://kawamurashingo.github.io/JQ-Lite/index-en.html',
    repository => {
        type => 'git',
        url  => 'https://github.com/kawamurashingo/JQ-Lite.git',
        web  => 'https://github.com/kawamurashingo/JQ-Lite',
    },
    bugtracker => {
        web => 'https://github.com/kawamurashingo/JQ-Lite/issues',
    },
};

WriteMakefile(
    NAME             => 'JQ::Lite',
    VERSION_FROM     => 'lib/JQ/Lite.pm',
    ABSTRACT         => 'A lightweight jq-like JSON query engine in Perl',
    AUTHOR           => 'Kawamura Shingo <perl.jq.lite@gmail.com>',
    LICENSE          => 'perl',
    MIN_PERL_VERSION => '5.014',
    PREREQ_PM        => {
        'JSON::PP'        => 0,
        'Encode'          => 0,
        'Test::More'      => 0,
        'FindBin'         => 0,
        'Getopt::Long'    => 0,
        'IO::File'        => 0,
        'List::Util'      => 0,
        'MIME::Base64'    => 0,
        'Scalar::Util'    => 0,
        'Term::ANSIColor' => 0,
    },
    EXE_FILES        => ['bin/jq-lite'],
    META_MERGE       => {
        'meta-spec' => { version => 2 },
        resources   => $resources,
        no_index    => {
            directory => [ 't', 'inc' ],
        },
    },
    META_ADD => {
        resources => $resources,
    },
);
