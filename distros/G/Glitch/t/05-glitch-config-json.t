use Test::More;
use lib 't/lib';
use Glitch;
use GlitchesFromConfigTwo;

eval {
	glitch 'one';
};

is($@->name, 'one');

is_deeply( {%{$@}}, {
	'file' => '05-glitch-config-json.t',
	'filepath' => 't/05-glitch-config-json.t',
	'name' => 'one',
	'line' => '6',
	'stacktrace' => '05-glitch-config-json.t:6->05-glitch-config-json.t::(eval):7',
	'module' => 'main'
});

like( $@, qr/this is a test at t\/05-glitch-config-json.t line 6\n/);

done_testing;
