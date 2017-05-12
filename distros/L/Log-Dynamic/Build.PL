#!perl

use strict;
use warnings;

use Module::Build;

Module::Build->new (
	module_name       => 'Log::Dynamic',
	license           => 'perl',
	dist_author       => 'James Conerly',
	dist_abstract     => 'OOish dynamic and customizable logging',
	dist_version_from => 'lib/Log/Dynamic.pm',
	requires          => { 
		'Carp'         => 0,
		'Data::Dumper' => '2.121_08', 
	},
)->create_build_script;

__END__
