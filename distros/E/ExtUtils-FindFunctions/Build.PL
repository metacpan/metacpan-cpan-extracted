use strict;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'ExtUtils::FindFunctions',
    license             => 'perl',
    dist_author         => 'Sébastien Aperghis-Tramoni <sebastien@aperghis.net>',
    dist_version_from   => 'lib/ExtUtils/FindFunctions.pm',
    script_files        => [ 'bin/install-extutils-findfunctions' ], 
    build_requires => {
        'Test::More' => 0,
    },
    add_to_cleanup      => [ 'ExtUtils-FindFunctions-*' ],
);

$builder->create_build_script();
