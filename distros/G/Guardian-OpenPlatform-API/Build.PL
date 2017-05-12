use strict;
use warnings;
use Module::Build;

my $build = Module::Build->new(
    module_name => 'Guardian::OpenPlatform::API',
    license     => 'perl',
    requires    => {
        'perl'             => '5.008001',
        'LWP::UserAgent'   => '2.023',
        'Moo'              => '2.000000',
        'namespace::clean' => '0.24',
    },
    build_requires => {
        'Test::More'     => '0.47',
    },
);

$build->create_build_script;
