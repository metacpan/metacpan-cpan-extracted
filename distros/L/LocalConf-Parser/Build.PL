use 5.006;
use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'LocalConf::Parser',
    license             => 'artistic_2',
    dist_author         => q{nickniu <nick.niu.china@gmail.com>},
    dist_version_from   => 'lib/LocalConf/Parser.pm',
    release_status      => 'stable',
    configure_requires => {
        'Module::Build' => '0',
    },
    build_requires => {
        'Test::More' => '0',
    },
    requires => {
        #'ABC'              => '1.6',
        #'Foo::Bar::Module' => '5.0401',
    },
    add_to_cleanup     => [ 'LocalConf-Parser-*' ],
);

$builder->create_build_script();
