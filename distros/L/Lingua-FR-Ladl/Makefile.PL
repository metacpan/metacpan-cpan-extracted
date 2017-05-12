use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
              NAME                => 'Lingua::FR::Ladl',
              AUTHOR              => 'Ingrid Falk <ingrid dot falk at loria dot fr>',
              VERSION_FROM        => 'lib/Lingua/FR/Ladl.pm',
              ABSTRACT_FROM       => 'lib/Lingua/FR/Ladl.pm',
              PL_FILES            => {},
              PREREQ_PM => {
                            'Test::More' => 0,
                            'version'    => 0,
                            'Class::Std' => 0,
                            'Readonly'   => 0,
                            'Graph'      => 0,
                            'Graph::Reader::Dot' => 0,
                            'Exception::Class' => 0,
                            'List::Util' => 0,
                            'List::MoreUtils' => 0,
                            'Contextual::Return' => 0,
                           },
              dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
              clean               => { FILES => 'Lingua-FR-Ladl-*' },
             );
