use strict;
use Module::Build;

Module::Build
  ->new( module_name => "File::Slurp::Tree",
         license     => 'perl',
         build_requires => {
             'Test::More'       => 0,
         },
         requires    => {
             'File::Path'       => 0,
             'File::Slurp'      => 0,
             'File::Find::Rule' => 0,
         },
         create_makefile_pl => 'traditional',
       )
  ->create_build_script;
