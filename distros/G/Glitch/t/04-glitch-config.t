use Test::More;
use lib 't/lib';
use Glitch;
use GlitchesFromConfigOne;

eval {
	glitch 'one';
};

is($@->name, 'one');

is_deeply( {%{$@}}, {
	'file' => '04-glitch-config.t',
	'filepath' => 't/04-glitch-config.t',
	'name' => 'one',
	'line' => '6',
	'stacktrace' => '04-glitch-config.t:6->04-glitch-config.t::(eval):7',
	'module' => 'main'
});

like( $@, qr/this is a test at t\/04-glitch-config.t line 6\n/);

done_testing;
