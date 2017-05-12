use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'List::Maker',
    license             => 'perl',
    dist_author         => 'Damian Conway <DCONWAY@CPAN.org>',
    dist_version_from   => 'lib/List/Maker.pm',
    requires => {
        'Test::More' => 0,
        'File::Glob' => 0,
    },
    add_to_cleanup      => [ 'List-Maker-*' ],
);

$builder->create_build_script();
