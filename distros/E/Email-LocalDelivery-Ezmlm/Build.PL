use strict;
use Module::Build;

Module::Build
  ->new( module_name => "Email::LocalDelivery::Ezmlm",
         license     => 'perl',
         build_requires => {
             'Test::More'       => 0,
         },
         requires    => {
             'Email::LocalDelivery' => 0,
             'Email::FolderType'    => '0.6',
         },
         create_makefile_pl => 'traditional',
       )
  ->create_build_script;
