use strict;
use Module::Build;

my $build = Module::Build
  ->new( module_name => "LWPx::TimedHTTP",
         license     => 'perl',
         requires    => {
                          'LWP::UserAgent'  => 6, # this is the version of libwww-perl we modified
                          'Time::HiRes'     => 0, # needed for timing
                         },
         build_requires => {
             'HTTP::Daemon'    => 0,             
             'Test::More'      => 0,
         },
         create_makefile_pl => 'passthrough',
       );

$build->create_build_script;

