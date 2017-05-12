use strict;
use Module::Build;

Module::Build
  ->new( module_name => 'File::Find::Rule::Ext2::FileAttributes',
         license     => 'perl',
         build_requires => {
             'File::Find::Rule' => 0,
             'Test::More' => 0,
             'Linux::Ext2::FileAttributes' => 0,
         },
   create_makefile_pl => 'traditional',
       )
  ->create_build_script;
