#!perl -w
use strict;
use Module::Build;
Module::Build
  ->new( module_name => "Games::Set",
         license     => 'perl',
         build_requires => {
             'Test::More' => 0,
         },
         requires => {
             'Algorithm::ChooseSubsets'    => 0,
             'Algorithm::GenerateSequence' => 0,
             'Class::Accessor::Fast'       => 0,
             'List::Util'                  => 0,
            },
         create_makefile_pl => 'traditional',
        )
  ->create_build_script;

