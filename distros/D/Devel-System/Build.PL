use strict;
use Module::Build;

Module::Build
  ->new( module_name => "Devel::System",
         license     => 'perl',
         build_requires => {
             'Test::More' => 0,
             'IO::Scalar' => 0,
         },
         requires => {
             'String::ShellQuote' => 0,
         },
         create_makefile_pl => 'passthrough',
       )
  ->create_build_script;
