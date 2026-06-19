use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME         => 'JSON::JSONFold',
    VERSION_FROM => 'lib/JSON/JSONFold.pm',
    ABSTRACT     => 'Hybrid pretty/compact JSON output',
    AUTHOR       => 'Yair Lenga',
    LICENSE      => 'mit',
    PREREQ_PM    => {
        'JSON::PP'  => 0,
        'Exporter'  => 0,
    },
    EXE_FILES => [ 'script/jsonfold.pl' ],
    test         => { TESTS => 't/*.t' },
);
