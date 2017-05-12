use strict;
use warnings;
use Test::More;
use Test::MockObject;

use Dist::Zilla::Tester;
use lib 't/lib';
use Dist::Zilla::Plugin::TestDynamicConfig;

my %confs = (
	't/ini-none' => undef,
	't/ini-noconf' => {
		extra => '',
		_config => {},
	},
	't/ini-sep'  => {
		extra => '',
		_config => {
			'hello'   => 'there',
			'goodbye' => 'now',
		}
	},
	't/ini-test' => {
		extra => 'extra goodness',
		_config => {
			'@ABundle-fakeattr'    => 'fakevalue1',
			'-APlugin/fakeattr'    => 'fakevalue2',
			'ASection->heading'    => 'head5',
			'-APlug::Name::config' => 'confy',
		}
	}
);

foreach my $dir ( keys %confs ){

	my $zilla = Dist::Zilla::Tester->from_config(
		{ dist_root => $dir },
		{}
	);

	$zilla->build;

	my $plug = $zilla->plugin_named('TestDynamicConfig');
	$plug &&= {extra => $plug->extra, _config => $plug->_config};
	is_deeply($plug, $confs{$dir}, "config matches in $dir");
}

done_testing;
