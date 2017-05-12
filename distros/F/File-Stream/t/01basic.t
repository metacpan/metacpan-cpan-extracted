use strict;
use warnings;
use lib 'lib';
use Test::More tests => 12;
binmode(*DATA);
use_ok('File::Stream');
use File::Stream;

my $start = tell DATA;

my ($handler, $stream) = File::Stream->new(\*DATA, separator => ' ');
ok(ref($stream) eq 'FileHandle', 'object creation');

ok(tell($stream) == tell(*DATA));

my $read = readline($stream);
ok($read eq 'thisisastream ', 'Literal separator');

$read = $handler->readline();
ok($read eq 'a ', 'Literal separator');

$handler->{separator} = qr/test\s+/;
$read = <$stream>;
ok($read eq 'test ', 'Regex separator');

seek DATA, $start, 0;
ok(
	eq_array(
		[$handler->find(qr/,\s*/, 'blah')],
		['stream', ', ']
	),
	'find()'
);

ok(
	eq_array(
		[$handler->find(qr/l+y\./, 'blah')],
		['actua', 'lly.']
	),
	'find()'
);

ok(
	eq_array(
		[$handler->find(qr/l+y\./, 'blah')],
		[' Blah ', 'blah']
	),
	'find()'
);

ok(seek($stream, 0, 0), 'seek on stream');

$handler->{separator} = ' ';
$read = readline($stream);
ok($read eq 'use ', 'read after seek works as expected.');

my $pos = tell($stream);
ok($pos == 4, 'tell on stream');

__DATA__
thisisastream a test stream, actually. Blah blah blah!
