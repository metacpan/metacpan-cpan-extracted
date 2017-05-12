use 5.006;
use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Github::Fork::Parent',
    license             => 'perl',
    dist_author         => q{Alexandr Ciornii <alexchorny@gmail.com>},
    dist_version_from   => 'lib/Github/Fork/Parent.pm',
    requires => {
        'Exporter' => 5.57,
        'LWP::UserAgent' => 0,
        'LWP::Protocol::https' => 0,
        'JSON' => 0,
        'perl' => 5.006,
    },
    build_requires => {
        'Test::More' => 0,
        'LWP::Online' => 1.06,
    },
    meta_merge => {
        resources=> {
            repository => 'http://github.com/chorny/Github-Fork-Parent',
        },
        keywords => ['github','repository','fork'],
    },
    add_to_cleanup      => [ 'Github-Fork-Parent-*' ],
    create_makefile_pl => 'traditional',
    auto_configure_requires => 0,
);

$builder->create_build_script();
