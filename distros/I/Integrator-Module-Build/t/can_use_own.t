#!/usr/bin/perl

#######################################################################################################################
use Test::More tests => 11;
#######################################################################################################################
# basic object methods loads and executes
use Integrator::Module::Build;

# localy decalred (and sub-classed) stuff
can_ok ( 'Integrator::Module::Build', 'ACTION_integrator_sync'		);
can_ok ( 'Integrator::Module::Build', 'ACTION_integrator_test'		);
can_ok ( 'Integrator::Module::Build', 'ACTION_integrator_version'	);
can_ok ( 'Integrator::Module::Build', 'ACTION_integrator_xml_report'	);
can_ok ( 'Integrator::Module::Build', 'ACTION_version'			);
can_ok ( 'Integrator::Module::Build', 'read_config'			);
can_ok ( 'Integrator::Module::Build', 'write_config'			);

can_ok ( 'Integrator::Module::Build', 'Dumper'		);
can_ok ( 'Integrator::Module::Build', 'XMLin'		);
can_ok ( 'Integrator::Module::Build', 'XMLout'		);
can_ok ( 'Integrator::Module::Build', 'md5_hex'		);
