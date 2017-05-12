use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'HTTP::MobileAgent::Plugin::ID',
    license             => 'perl',
    dist_author         => 'OHTSUKA Ko-hei <nene@kokogiko.net>',
    dist_version_from   => 'lib/HTTP/MobileAgent/Plugin/ID.pm',
    requires => {
        'Test::Base'                       => 0,
        'version'                          => 0,
        'HTTP::MobileAgent::Plugin::XHTML' => 0,
    },
    add_to_cleanup      => [ 'HTTP-MobileAgent-Plugin-ID-*' ],
);

$builder->create_build_script();
