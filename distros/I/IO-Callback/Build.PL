use 5.006;
use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'IO::Callback',
    license             => 'perl',
    dist_author         => 'Dave Taylor <dave.taylor.cpan@gmail.com>',
    dist_version_from   => 'lib/IO/Callback.pm',
    requires => {
        'perl'       => 5.006,
        'Carp'       => 0,
        'Errno'      => 0,
        'IO::String' => 0,
    },
    build_requires => {
        'Fatal'            => 0,
        'Fcntl'            => 0,
        'File::Slurp'      => 0,
        'File::Temp'       => 0,
        'IO::Handle'       => 0,
        'Module::Build'    => 0,
        'Test::Exception'  => 0,
        'Test::More'       => 0,
        'Test::NoWarnings' => 0,
    },
    add_to_cleanup      => [ 'IO::Callback-*' ],
    create_makefile_pl => 'small',
);

$builder->create_build_script();
