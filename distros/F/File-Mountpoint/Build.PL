use Module::Build;
# See perldoc Module::Build for details of how this works

Module::Build->new(
    module_name         => 'File::Mountpoint',
    dist_version_from   => 'lib/File/Mountpoint.pm',
    author              => 'Joshua Hoblitt <jhoblitt@cpan.org>',
    license             => 'perl',
    create_makefile_pl  => 'passthrough',
    requires            => {
        'Carp'      => 0,
        'File::stat'=> 0,
        'Fcntl'     => 0,
        'File::Spec'=> 0,
    },
    build_requires      => {
        'Test::More'=> 0,
        'File::Temp'=> 0,
    },
    recommends          => {
        'Test::Distribution'    => '1.22',
    },
)->create_build_script;
