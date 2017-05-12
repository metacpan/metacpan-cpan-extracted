use strict;
use warnings;
use Test::More;
require "t/exercises.tt";

PREP('File');

unlink 't/q1';
ok(-d 't', 'queue directory exists');
ok(! -f 't/q1', 'queue file does not exist yet');

########

my $q = Forks::Queue::File->new( file => 't/q1', style => 'fifo' );

ok($q, 'got queue object');
ok(ref($q) eq 'Forks::Queue::File', 'has correct object type');
ok(-f 't/q1', 'queue file created');
ok(-s 't/q1' > 1024, 'queue header section created');

exercise_fifo($q);

undef $q;
ok(! -f 't/q1', 'queue file destroyed when queue object was out of scope');

done_testing;
