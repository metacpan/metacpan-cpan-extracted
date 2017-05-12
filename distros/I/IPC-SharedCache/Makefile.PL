use ExtUtils::MakeMaker;

WriteMakefile(
              'NAME'	=> 'IPC::SharedCache',
              'VERSION_FROM' => 'SharedCache.pm', # finds $VERSION
              'PREREQ_PM' => { 
                              'IPC::ShareLite' => '0.06',
                              'Storable' => '0',
                              'Carp' => '0',
                              'IPC::SysV' => '0'
                             },
              
                              
);
