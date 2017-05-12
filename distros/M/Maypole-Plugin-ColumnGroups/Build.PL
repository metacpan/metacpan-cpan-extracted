use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Maypole::Plugin::ColumnGroups',
    license             => 'perl',
    dist_author         => 'David Baird <cpan@riverside-cms.co.uk>',
    dist_version_from   => 'lib/Maypole/Plugin/ColumnGroups.pm',
    requires => {
        'Test::More' => 0,
        'NEXT' => 0,
        'Maypole::Config' => 0,
    },
    add_to_cleanup      => [ 'Maypole-Plugin-ColumnGroups-*' ],
    create_makefile_pl  => 'traditional',
);

$builder->create_build_script();
