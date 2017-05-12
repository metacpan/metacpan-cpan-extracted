use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'JDBC',
    license             => 'perl',
    dist_author         => 'Tim Bunce <Tim.Bunce@pobox.com>',
    dist_version_from   => 'lib/JDBC.pm',
    requires => {
        'Test::More'   => 0,
        'Inline::Java' => '0.50',
    },
    add_to_cleanup      => [ 'JDBC-*', '_Inline', 'derbydb', 'derby.log' ],
);

$builder->create_build_script();
