use Test::More;
use lib 't/lib';
use Glitch;
use Glitches;

eval {
	glitch 'one';
};

is($@->name, 'one');

is_deeply( {%{$@}}, {
	'file' => '03-glitch.t',
	'filepath' => 't/03-glitch.t',
	'name' => 'one',
	'line' => '6',
	'stacktrace' => '03-glitch.t:6->03-glitch.t::(eval):7',
	'module' => 'main'
});

like( $@, qr/this is a test at t\/03-glitch.t line 6\n/);

done_testing;
