use ExtUtils::MakeMaker;
use Config;

os_unsupported if $^O eq 'MSWin32'; # I don't know on which OS'es the code will work exactly, but this one I can easily rule out.
os_unsupported if $Config{ivsize} < 8;
os_unsupported if $Config{usequadmath};

WriteMakefile(
    NAME => 'FU',
    VERSION_FROM => 'FU.pm',
    ABSTRACT_FROM => 'FU.pm',
    LICENSE => 'mit',
    AUTHOR => 'Yorhel <projects@yorhel.nl>',
    NO_MYMETA => 1,
    MIN_PERL_VERSION => 'v5.36',
    META_MERGE => {
        dynamic_config => 0,
        resources => {
            repository => 'https://code.blicky.net/yorhel/fu',
            bugtracker => 'https://code.blicky.net/yorhel/fu/issues',
        },
        no_index => {
            file => 'bench.PL',
        },
    },
    depend => { '$(OBJECT)', 'c/*.c' },
);
