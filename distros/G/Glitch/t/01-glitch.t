use Test::More;

use Glitch;

eval {
	glitch 'one', message => 'this is a test';
};

is_deeply( {%{$@}}, {
	'file' => '01-glitch.t',
	'filepath' => 't/01-glitch.t',
	'message' => 'this is a test',
	'name' => 'one',
	'line' => '5',
	'stacktrace' => '01-glitch.t:5->01-glitch.t::(eval):6',
	'module' => 'main'
});

done_testing;
