use strict;
use ExtUtils::MakeMaker;
WriteMakefile(
    'NAME'         => 'Email::LocalDelivery::Store',
    'VERSION_FROM' => 'Store.pm',
    'PREREQ_PM'    => { 'Email::Store'      => '0.15',
                        'Email::FolderType'  => '0.3',
                        'File::Path::Expand' => 0,
                        'Test::More'         => 0 },
);
