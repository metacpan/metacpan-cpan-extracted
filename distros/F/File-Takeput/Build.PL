# Build.PL for File::Takeput.
use Module::Build;
use strict;
use 5.030000;

Module::Build->new(
    module_name         => 'File::Takeput' ,
    license             => 'apache' ,
    dist_author         => 'Bjoern Hee <github@spredehagl.com>' ,
    dist_abstract       => 'Slurp style file IO with locking.' ,
    dist_version_from   => 'lib/File/Takeput.pm' ,
    create_makefile_pl  => 0 ,
    create_readme       => 0 ,
    requires            => {
        'Cwd'             => 0 ,
        'Exporter'        => 0 ,
        'Fcntl'           => 0 ,
        'File::Basename'  => 0 ,
        'Scalar::Util'    => 0 ,
        'Time::HiRes'     => 0 ,
        } ,
    test_requires       => {
        'Cwd'             => 0 ,
        'File::Basename'  => 0 ,
        'File::Copy'      => 0 ,
        'File::Spec'      => 0 ,
        'Test::More'      => 0 ,
        } ,
    meta_merge => {
        resources => {
            repository => 'https://github.com/spragl/Takeput' ,
            bugtracker => 'https://github.com/spragl/Takeput/issues' ,
            } ,
        } ,
    )->create_build_script;
