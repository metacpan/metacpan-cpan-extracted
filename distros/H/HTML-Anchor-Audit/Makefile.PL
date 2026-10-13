use 5.016;
use strict;
use warnings;
use ExtUtils::MakeMaker 6.64;

WriteMakefile(
    NAME => 'HTML::Anchor::Audit',
    VERSION_FROM => 'lib/HTML/Anchor/Audit.pm',
    ABSTRACT_FROM => 'lib/HTML/Anchor/Audit.pm',
    AUTHOR => 'Nedal Shabaan',
    LICENSE => 'mit',
    MIN_PERL_VERSION => '5.016',
    EXE_FILES => ['script/html-anchor-audit'],
    PREREQ_PM => { 'HTML::Parser' => '3.72', 'Encode' => 0, 'Exporter' => 0,
        'Carp' => 0, 'Unicode::Normalize' => 0, 'Getopt::Long' => 0, 'JSON::PP' => 0 },
    TEST_REQUIRES => { 'Test::More' => '0.98', 'File::Temp' => 0,
        'IPC::Open3' => 0, 'Symbol' => 0, 'Pod::Checker' => 0 },
    META_MERGE => {
        'meta-spec' => { version => 2 },
        resources => { homepage => 'https://idraaak.com/',
            repository => { type => 'git', url => 'https://github.com/nedal-dev/html-anchor-audit.git',
                web => 'https://github.com/nedal-dev/html-anchor-audit' },
            bugtracker => { web => 'https://github.com/nedal-dev/html-anchor-audit/issues' } },
        no_index => { directory => ['t', 'examples'] },
    },
);
