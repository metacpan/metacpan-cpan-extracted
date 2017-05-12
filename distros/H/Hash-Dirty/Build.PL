use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Hash::Dirty',
    license             => 'perl',
    dist_author         => 'Robert Krimen <rkrimen@cpan.org>',
    dist_version_from   => 'lib/Hash/Dirty.pm',
    build_requires => {
        'Test::More' => 0,
        'Test::Deep' => 0,
    },
    requires => {
        'Tie::Hash' => "1.00",
        'Scalar::Util' => 0,
        'Sub::Exporter' => 0,
    },
    add_to_cleanup      => [ 'Hash-Dirty-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
