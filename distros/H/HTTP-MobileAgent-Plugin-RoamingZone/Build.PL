use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'HTTP::MobileAgent::Plugin::RoamingZone',
    license             => 'perl',
    dist_author         => 'OHTSUKA Ko-hei <nene@kokogiko.net>',
    dist_version_from   => 'lib/HTTP/MobileAgent/Plugin/RoamingZone.pm',
    requires => {
        'Test::Base'        => 0,
        'version'           => 0,
        'Mobile::Data::ITU' => 0,
        'Mobile::Data::SID' => 0,
        'HTTP::MobileAgent' => '0.27',
    },
    add_to_cleanup      => [ 'HTTP-MobileAgent-Plugin-RoamingZone-*' ],
);

$builder->create_build_script();
