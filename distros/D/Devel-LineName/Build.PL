use 5.006001;
use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name => 'Devel::LineName',
    dist_author => 'Nick Cleaton <nick@cleaton.net>',
    all_from    => 'lib/Devel/LineName.pm',
    license     => 'perl',
    requires => {
        'perl'          => 5.006001,
        'Carp'          => 0,
    },
    build_requires => {
        'Test::More'    => 0,
    },
    create_makefile_pl => 'traditional',
);
$builder->create_build_script();
