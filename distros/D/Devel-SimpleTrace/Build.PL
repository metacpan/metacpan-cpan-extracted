use strict;
use Module::Build;

Module::Build->new(
    module_name         => 'Devel::SimpleTrace', 
    license             => 'perl', 
    dist_author         => 'Sébastien Aperghis-Tramoni <sebastien@aperghis.net>', 
    dist_version_from   => 'lib/Devel/SimpleTrace.pm', 
    requires => {
        'Data::Dumper'  => 0, 
    }, 
    build_requires => {
        'Test'          => 0,
        'Test::More'    => 0,
    },
    add_to_cleanup      => [ 'Devel-SimpleTrace-*' ],
)->create_build_script;
