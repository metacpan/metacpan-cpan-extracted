use 5.010;

use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
	module_name    => 'File::Dropbox',
	license        => 'perl',
	create_license => 1,
	create_readme  => 1,

	configure_requires => {
		'Module::Build' => '0.40',
	},

	requires => {
		'Furl'            => '2.16',
		'JSON'            => '2.0',
		'Net::DNS::Lite'  => '0.1',
		'IO::Socket::SSL' => '1.4',
	},
);

$builder->create_build_script();
