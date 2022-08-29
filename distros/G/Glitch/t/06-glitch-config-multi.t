use Test::More;
use lib 't/lib';
use Glitch;
use GlitchesFromConfigThree;

eval {
	glitch 'one';
};

is($@->name, 'one');

is_deeply( {%{$@}}, {
	'file' => '06-glitch-config-multi.t',
	'filepath' => 't/06-glitch-config-multi.t',
	'name' => 'one',
	'line' => '6',
	'stacktrace' => '06-glitch-config-multi.t:6->06-glitch-config-multi.t::(eval):7',
	'module' => 'main'
});

like( $@, qr/this is a test at t\/06-glitch-config-multi.t line 6\n/);

eval {
	glitch 'two';
};

is($@->name, 'two');

is_deeply( {%{$@}}, {
	'file' => '06-glitch-config-multi.t',
	'filepath' => 't/06-glitch-config-multi.t',
	'name' => 'two',
	'line' => '23',
	'stacktrace' => '06-glitch-config-multi.t:23->06-glitch-config-multi.t::(eval):24',
	'module' => 'main'
});

like( $@, qr/this is another test at t\/06-glitch-config-multi.t line 23\n/);

done_testing;
