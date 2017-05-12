use ExtUtils::MakeMaker;

use strict ;

WriteMakefile(
    'NAME'          => 'File::SetSize',
    'VERSION_FROM'  => 'SetSize.pm',
    'PREREQ_PM'     => { 
                          'File::Copy' => 2.02,
                       }
);
