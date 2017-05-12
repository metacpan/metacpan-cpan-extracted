use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Games::SGF::Tournament',
    license             => 'gpl',
    dist_author         => 'Al Nikolov <alnikolov@narod.ru>',
    dist_version_from   => 'lib/Games/SGF/Tournament.pm',
    requires => {
        'version'    => 0,
    },
    add_to_cleanup      => [ 'Games-SGF-Tournament-*' ],
);

$builder->create_build_script();
