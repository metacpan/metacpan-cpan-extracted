use strict;
use warnings;
use Test::More;
use lib '.';   # 5.26 compat
require "t/exercises.tt";

PREP('SQLite');
my $qfile = "t/q1s-$$";

unlink $qfile;
ok(-d 't', 'queue directory exists');
ok(! -f $qfile, 'queue file does not exist yet');

########

my $q = Forks::Queue::SQLite->new;

ok($q, 'got queue object');
ok(ref($q) eq 'Forks::Queue::SQLite', 'has correct object type');

exercise_fifo($q);

undef $q;

done_testing;
