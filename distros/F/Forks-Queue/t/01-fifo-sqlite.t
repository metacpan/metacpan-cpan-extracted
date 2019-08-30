use strict;
use warnings;
use Test::More;
require "t/exercises.tt";

PREP('SQLite');

unlink 't/q1s';
ok(-d 't', 'queue directory exists');
ok(! -f 't/q1s', 'queue file does not exist yet');

########

my $q = Forks::Queue::SQLite->new;

ok($q, 'got queue object');
ok(ref($q) eq 'Forks::Queue::SQLite', 'has correct object type');

exercise_fifo($q);

undef $q;

done_testing;
