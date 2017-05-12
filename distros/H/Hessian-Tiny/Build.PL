use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Hessian::Tiny',
    license             => 'perl',
    dist_author         => q{DUL <ling.du@gmail.com>},
    dist_version_from   => 'lib/Hessian/Tiny/Client.pm',
    build_requires => {
        'Test::More'    => '0.94', #subtest feature used
    },
    requires => {
        'Config'        => 0,
        'Encode'        => 0,
        'File::Temp'    => 0,
        'HTTP::Headers' => 0,
        'HTTP::Request' => 0,
        'HTTP::Response'=> 0,
        'IO::File'      => 0,
        'IO::Handle'    => 0,
        'LWP::UserAgent'=> 0,
        'List::Util'    => 0,
        'Math::BigInt'  => 0,
        'Scalar::Util'  => 0,
        'Switch'        => 0,
        'Tie::RefHash'  => 0,
        'URI'           => 0,
        'perl'          => '5.6.0'
    },
    add_to_cleanup      => [ 'Hessian-Tiny-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
