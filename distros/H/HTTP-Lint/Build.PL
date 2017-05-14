use strict;
use warnings;

use Module::Build;

my $build = new Module::Build (
	module_name => 'HTTP::Lint',
	license => 'perl',
	dist_author => 'Lubomir Rintel <lkundrak@v3.sk>',
	dist_version => '1.1',
	dist_abstract => 'Check HTTP messages and transactions for protocol violations',
	meta_merge => {
		resources => {
			bugtracker => 'http://rt.cpan.org/NoAuth/Bugs.html?Dist=HTTP-Lint',
			repository => 'https://github.com/lkundrak/http-lint',
		}
	},
	requires => {
		'LWP::UserAgent' => 0,
		'HTTP::Message' => 0,
	},
	build_requires => {
		'HTTP::Message' => 0,
		'Test::Pod' => '1.0',
		'Test::Deep' => 0,
	},
);

$build->create_build_script;
