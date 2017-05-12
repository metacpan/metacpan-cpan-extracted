use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Maypole::Plugin::Config::Apache',
    license             => 'perl',
    dist_author         => 'David Baird <cpan@riverside-cms.co.uk>',
    dist_version_from   => 'lib/Maypole/Plugin/Config/Apache.pm',
    requires => {
        'Test::More' => 0,
        'Test::Exception' => 0,
        #'Maypole::Config' => 0,
        'NEXT' => 0,
    },
    add_to_cleanup      => [ 'Maypole-Plugin-Config-Apache-*' ],
    create_makefile_pl  => 'traditional',
);

$builder->create_build_script();
