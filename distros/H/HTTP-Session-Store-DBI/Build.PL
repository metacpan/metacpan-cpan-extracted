use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'HTTP::Session::Store::DBI',
    license             => 'perl',
    dist_author         => 'Fayland Lam <fayland@gmail.com>',
    dist_version_from   => 'lib/HTTP/Session/Store/DBI.pm',
    build_requires => {
        'Test::More' => 0,
        'HTTP::Session' => '0.26',
        'Moose'      => 0,
        'DBI'        => 0,
        'MIME::Base64' => 0,
        'Storable'   => 0,
    },
    add_to_cleanup      => [ 'HTTP-Session-Store-DBI-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
