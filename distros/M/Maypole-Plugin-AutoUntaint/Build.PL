use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Maypole::Plugin::AutoUntaint',
    license             => 'perl',
    dist_author         => 'David Baird <cpan@riverside-cms.co.uk>',
    dist_version_from   => 'lib/Maypole/Plugin/AutoUntaint.pm',
    requires => {
        'Test::More' => 0,
        'NEXT' => 0,
        'Class::DBI::Plugin::AutoUntaint' => 0,
        'UNIVERSAL::require' => 0,
    },
    add_to_cleanup      => [ 'Maypole-Plugin-AutoUntaint-*' ],
    create_makefile_pl  => 'traditional',
);

$builder->create_build_script();
