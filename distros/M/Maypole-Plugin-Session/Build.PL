use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Maypole::Plugin::Session',
    license             => 'perl',
    dist_author         => 'David Baird <cpan@riverside-cms.co.uk>',
    dist_version_from   => 'lib/Maypole/Plugin/Session.pm',
    requires => {
        'Test::More' => 0,
        'Apache::Session::Wrapper' => 0.24,
        'Maypole' => 2,
    },
    add_to_cleanup      => [ 'Maypole-Plugin-Session-*' ],
    create_makefile_pl  => 'traditional',
);

$builder->create_build_script();
