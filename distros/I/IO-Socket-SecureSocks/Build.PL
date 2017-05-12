use strict;
use Module::Build;

my $build = Module::Build->new(
    create_makefile_pl => 'traditional',
    license            => 'perl',
    module_name        => 'IO::Socket::SecureSocks',
    requires           => {
        'IO::Socket::Socks' => 0.00,
        'IO::Socket::SSL'   => 0.00,
    },
    reccomends    => {},
    create_readme => 1,
    sign          => 0,
);
$build->create_build_script;
