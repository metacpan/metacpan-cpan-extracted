use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Form::Processor::Model::DOD',
    AUTHOR              => 'Yann Kerherve',
    VERSION_FROM        => 'lib/Form/Processor/Model/DOD.pm',
    ABSTRACT_FROM       => 'lib/Form/Processor/Model/DOD.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'Data::ObjectDriver' => 0,
        'Form::Processor' => 0.11,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Form-Processor-Model-DOD-*' },
);
