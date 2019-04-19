use strict;
use warnings;
use Test::More;
use Test::Warnings;
use IPC::ReadpipeX;

$? = 1;
is readpipex($^X, '-e', 'print "42\n43\n"'), "42\n43\n", 'right output';
is $?, 0, '$? is 0';

$? = 1;
is_deeply [readpipex($^X, '-e', 'print "42\n43\n"')], ["42\n","43\n"], 'right output';
is $?, 0, '$? is 0';

is readpipex($^X, '-e', 'exit 5'), '', 'no output';
is +($? >> 8), 5, 'exit status is 5';

$! = 0;
ok !eval { readpipex('command-that-does-not-exist', 'args'); 1 }, 'invalid command';
my $file = __FILE__;
like $@, qr/\Q$file/, 'caller context in error';
isnt 0+$!, 0, '$! is set';

done_testing;
