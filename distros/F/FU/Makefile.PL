use ExtUtils::MakeMaker;
use Config;

os_unsupported if $^O eq 'MSWin32'; # I don't know on which OS'es the code will work exactly, but this one I can easily rule out.
os_unsupported if $Config{ptrsize} < 8;
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
        'meta-spec' => { version => 2 },
        resources => {
            homepage => 'https://dev.yorhel.nl/fu',
            repository => {
                web => 'https://code.blicky.net/yorhel/fu',
                type => 'git',
            },
            bugtracker => {
                web => 'https://code.blicky.net/yorhel/fu/issues',
                mailto => 'projects@yorhel.nl',
            },
        },
    },
    depend => { '$(OBJECT)', 'c/*.c' },
);
