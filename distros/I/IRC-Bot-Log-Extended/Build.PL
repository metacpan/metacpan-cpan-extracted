use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'IRC::Bot::Log::Extended',
    license             => 'perl',
    dist_author         => 'Fayland Lam <fayland@gmail.com>',
    dist_version_from   => 'lib/IRC/Bot/Log/Extended.pm',
    build_requires => {
        'Test::More' => 0,
        'IRC::Bot'   => 0,
        'Moose'      => 0,
    },
    add_to_cleanup      => [ 'IRC-Bot-Log-Extended-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
