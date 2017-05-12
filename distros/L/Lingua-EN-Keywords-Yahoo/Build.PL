use strict;
use Module::Build;

my $build = Module::Build
  ->new( module_name => "Lingua::EN::Keywords::Yahoo",
         license     => 'perl',
         requires    => {
                          'Test::More'            => 0,
                          'LWP::UserAgent'        => 0,
                          'XML::Twig'             => '3.22',
                        },
         create_makefile_pl => 'passthrough',
       );

$build->create_build_script;

