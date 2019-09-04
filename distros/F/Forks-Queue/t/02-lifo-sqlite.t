use strict;
use warnings;
use Test::More;
use lib '.';   # 5.26 compat
require "t/exercises.tt";

PREP('SQLite');
my $qfile = "t/q2s-$$";

unlink $qfile;
ok(-d 't', 'queue directory exists');
ok(! -f $qfile, 'queue file does not exist yet');

my $q = Forks::Queue::SQLite->new( db_file => $qfile, style => 'lifo' );

ok($q && ref($q) eq 'Forks::Queue::SQLite', 'got queue with correct type');
ok(-f $qfile, 'queue file created');
ok(-s $qfile > 1024, 'queue header section created');

exercise_lifo($q);

undef $q;
ok(! -f $qfile, 'queue file destroyed when queue object left scope');

$q = Forks::Queue::SQLite->new( db_file => $qfile, style => 'lifo' );
ok(-f $qfile, 'queue file created');
exercise_lifo2($q);
undef $q;
ok(! -f $qfile, 'queue file destroyed when queue object left scope');

done_testing();
