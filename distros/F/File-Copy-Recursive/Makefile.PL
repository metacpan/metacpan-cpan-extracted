use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME          => 'File::Copy::Recursive',
    VERSION_FROM  => 'lib/File/Copy/Recursive.pm',
    ABSTRACT_FROM => 'lib/File/Copy/Recursive.pm',
    AUTHOR        => 'Daniel Muey <http://drmuey.com/cpan_contact.pl>',
    PREREQ_PM     => {
        'File::Copy' => 0,
        'File::Spec' => 0,
        'File::Glob' => 0,
        'Cwd'        => 0,
    },
    TEST_REQUIRES => {
        'Test::More'       => '0.88',
        'Test::Deep'       => 0,
        'Test::File'       => 0,
        'File::Temp'       => 0,
        'Test::Warnings'   => 0,
        'Path::Tiny'       => 0,
        'Test::Fatal'      => 0,
    },
    META_ADD => {
        'meta-spec'    => { version => 2 },
        dynamic_config => 0,
        resources      => {
            repository => {
                url  => 'https://github.com/drmuey/p5-File-Copy-Recursive.git',
                web  => 'https://github.com/drmuey/p5-File-Copy-Recursive',
                type => 'git',
            },
            bugtracker => {
                mailto => 'bug-File-Copy-Recursive@rt.cpan.org',
                web    => 'https://rt.cpan.org/Public/Dist/Display.html?Name=File-Copy-Recursive',
            },
        },
    },
);
