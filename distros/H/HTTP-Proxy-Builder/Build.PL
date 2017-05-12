use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'HTTP::Proxy::Builder',
    license             => 'perl',
    dist_author         => 'Philippe Bruhat (BooK) <book@cpan.org>',
    dist_version_from   => 'lib/HTTP/Proxy/Builder.pm',
    build_requires => {
        'Test::More' => 0,
        'HTTP::Proxy' => '0.10',
    },
    add_to_cleanup      => [ 'HTTP-Proxy-Builder-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
