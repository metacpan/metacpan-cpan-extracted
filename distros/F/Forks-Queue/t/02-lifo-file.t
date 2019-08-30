use strict;
use warnings;
use Test::More;
require "t/exercises.tt";

PREP('File');

unlink 't/q2f';
ok(-d 't', 'queue directory exists');
ok(! -f 't/q2f', 'queue file does not exist yet');

my $q = Forks::Queue::File->new( file => 't/q2f', style => 'lifo' );

ok($q && ref($q) eq 'Forks::Queue::File', 'got queue with correct type');
ok(-f 't/q2f', 'queue file created');
ok(-s 't/q2f' > 1024, 'queue header section created');

exercise_lifo($q);

undef $q;
ok(! -f 't/q2f', 'queue file destroyed when queue object left scope');

$q = Forks::Queue::File->new( file => 't/q2f', style => 'lifo' );
ok(-f 't/q2f', 'queue file created');
exercise_lifo2($q);
undef $q;
ok(! -f 't/q2f', 'queue file destroyed when queue object left scope');


done_testing();
