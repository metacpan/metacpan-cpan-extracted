use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Maypole::Plugin::LinkTools',
    license             => 'perl',
    dist_author         => 'David Baird <cpan@riverside-cms.co.uk>',
    dist_version_from   => 'lib/Maypole/Plugin/LinkTools.pm',
    requires => {
        'Test::More' => 0,
    },
    add_to_cleanup      => [ 'Maypole-Plugin-LinkTools-*' ],
    create_makefile_pl  => 'traditional',
);

$builder->create_build_script();
