use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Log::Dispatch::SNMP',
    license             => 'perl',
    dist_author         => 'Breno G. de Oliveira <garu@cpan.org>',
    dist_version_from   => 'lib/Log/Dispatch/SNMP.pm',
    dist_abstract       => 'Object for logging to SNMP servers',
    build_requires => {
        'Test::More'       => 0,
        'Log::Dispatch'    => 0,
        'Params::Validate' => 0,
        'Net::SNMP'        => 0,
        'Carp'             => 0,
    },
    add_to_cleanup      => [ 'Log-Dispatch-SNMP-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
