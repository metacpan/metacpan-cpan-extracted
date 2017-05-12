#!perl
use strict;
use warnings;
use Test::More tests => 20;

use IO::Handle::unread;

use File::Spec;

use open IO => ':perlio';

ok open(my $null, '<', File::Spec->devnull), 'open';

is $null->unread("foo\n"), length("foo\n"), 'unread count';

ok !eof($null), 'eof after unread';
is scalar(<$null>), "foo\n", 'unread with a newline';
ok  eof($null), 'eof after read';

$null->unread('a');

ok !eof($null), 'eof after unread';
is scalar(<$null>), 'a', 'unread without newlines';
ok  eof($null), 'eof after read';

$null->unread("foo\nbar\nbaz");

is_deeply [<$null>], ["foo\n", "bar\n", "baz"], 'unread with newlines';
ok eof($null), 'eof';

$null->unread('X' x 5000);

is_deeply [<$null>], ['X' x 5000], 'unread large string';

$null->unread('foo');
$null->unread('bar');

is_deeply [<$null>], ['barfoo'], 'multi-call unread';
is_deeply [<$null>], [], 'null';


$null->unread('foo', 1);
is_deeply [<$null>], ['f'], 'length specified';

$null->unread('foo', 10000);
is_deeply [<$null>], ['foo'], 'length specified (too long)';

eval{
	$null->unread('foo', -1);
};
like $@, qr/Negative length/, 'negatie length';

ok close($null), 'close';

eval{
	use warnings FATAL => 'io';
	$null->unread('foo');
};
like $@, qr/closed/, 'closed filehandle';

eval{
	use warnings FATAL => 'io';
	select select my $unopened;
	$unopened->unread('foo');
};
like $@, qr/unopened/, 'unopened filehandle';


eval{
	use warnings FATAL => 'io';
	STDOUT->unread('foo');
};
like $@, qr/only for output/, 'only for output';
