use Test::More;

use Glitch (
	one => {
		message => 'this is a test'
	}
);

eval {
	glitch 'one';
};

is_deeply( {%{$@}}, {
	'file' => '02-glitch.t',
	'filepath' => 't/02-glitch.t',
	'name' => 'one',
	'line' => '9',
	'stacktrace' => '02-glitch.t:9->02-glitch.t::(eval):10',
	'module' => 'main'
});

like( $@, qr/this is a test at t\/02-glitch.t line 9\n/);

done_testing;
