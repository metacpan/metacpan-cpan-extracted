use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'LWP::UserAgent::ProxyHopper::Base',
    license             => 'perl',
    dist_author         => 'Zoffix Znet <zoffix@cpan.org>',
    dist_version_from   => 'lib/LWP/UserAgent/ProxyHopper/Base.pm',
    build_requires => {
        'Test::More' => 0,
    },
    requires => {
        'Carp'                   => 1.04,
        'Devel::TakeHashArgs'    => 0.001,
        'List::MoreUtils'        => 0.21,
        'WWW::FreeProxyListsCom' => 0.002,
        'WWW::Proxy4FreeCom'     => 0.001,
        'Class::Data::Accessor'  => 0.04001,
    },
    add_to_cleanup      => [ 'LWP-UserAgent-ProxyHopper-Base-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
