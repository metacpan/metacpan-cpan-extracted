use strict;
use ExtUtils::MakeMaker;
WriteMakefile(
    'NAME'         => 'File::Find::Rule',
    'VERSION_FROM' => 'lib/File/Find/Rule.pm',
    'PREREQ_PM'    => {
        'File::Find'      => 0,
        'File::Spec'      => 0,
        'Number::Compare' => 0,
        'Text::Glob'      => '0.07',
        'Test::More'      => 0,
    },
    'EXE_FILES' => ['findrule'],
);
