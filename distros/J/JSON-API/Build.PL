use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
	module_name         => 'JSON::API',
	create_license      => 1,
	license             => 'perl',
	dist_author         => q{Geoff Franks <geoff.franks@gmail.com>},
	dist_version_from   => 'lib/JSON/API.pm',
	meta_merge => {
		resources => {
			homepage   => 'https://github.com/geofffranks/json-api',
			bugtracker => 'https://github.com/geofffranks/json-api/issues',
			repository => 'git://github.com/geofffranks/json-api.git',
		},
	},

	configure_requires => {
		'Module::Build' => '0.38',
	},
	requires => {
		'JSON'           => 0,
		'LWP::UserAgent' => 0,
		'URI::Encode'    => 0,
	},
	build_requires => {
		'JSON' => 0,
		'Test::Fake::HTTPD'   => 0,
		'IO::Capture'         => 0,
		'LWP::UserAgent'      => 0,
		'Test::More'          => 0,
		'Test::Pod::Coverage' => 0,

	},

	add_to_cleanup => [
		'JSON-API-*',
		'cover_db',
		'*.rpm',
		'*.deb',
	]
);

$builder->create_build_script();
