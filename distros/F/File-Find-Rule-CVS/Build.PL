#!perl -w
use strict;
use Module::Build;
Module::Build
  ->new( module_name => "File::Find::Rule::CVS",
         license     => 'perl',
         build_requires => {
             'File::Slurp::Tree' => 0,
             'Test::More'        => 0,
         },
         requires    => {
             'Parse::CVSEntries' => '0.03',
             'File::Find::Rule'  => '0.20', # 0.20 introduced relative
             'version'           => 0,
         },
         create_makefile_pl => 'traditional',
        )
  ->create_build_script;

