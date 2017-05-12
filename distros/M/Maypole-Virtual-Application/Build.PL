use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Maypole::Virtual::Application',
    license             => 'perl',
    dist_author         => 'David Baird <cpan@riverside-cms.co.uk>',
    dist_version_from   => 'lib/Maypole/Virtual/Application.pm',
    requires => {
        'Test::More' => 0,
        'Maypole::Application' => 2.10, 
    },
    add_to_cleanup      => [ 'Maypole-Virtual-Application-*' ],
    create_makefile_pl  => 'traditional',
);

$builder->create_build_script();
