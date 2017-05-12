require 5.008;

use ExtUtils::MakeMaker;
WriteMakefile(
    'NAME'         => 'Devel::STDERR::Indent',
    'VERSION_FROM' => 'lib/Devel/STDERR/Indent.pm',
    'PREREQ_PM'    => {
        'Moose'            => 0,
        'Sub::Exporter'    => 0,
        'Task::Weaken'     => 0,
        'namespace::clean' => 0,
    },
    'INSTALLDIRS' => 'site',
    'EXE_FILES'   => [],
    'SIGN'        => 1,
);
