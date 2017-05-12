use v5.14;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Gcis::Client',
    license             => 'gpl_3',
    dist_version_from   => 'lib/Gcis/Client.pm',
    dist_abstract       => "Client for GCIS Structured Data Server",
    release_status      => 'stable',
    build_requires => {
        'Test::More' => 0,
    },
    requires => {
        'Mojo::UserAgent' => 0,
        'YAML::XS' => 0,
        'JSON::XS' => 0,
        'Path::Class' => 0,
        'Time::HiRes' => 0,
    },
    add_to_cleanup     => [ 'Gcis-Client-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
