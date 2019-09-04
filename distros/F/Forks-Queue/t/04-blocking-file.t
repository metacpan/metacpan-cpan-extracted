use strict;
use warnings;
use Test::More;
use lib '.';   # 5.26 compat
require "t/exercises.tt";

PREP('File');

my $TEMP = TEMP_DIR();
my $qfile = "q3c-$$";

ok(! -f "$TEMP/$qfile", 'queue file does not exist yet');

my $q3 = Forks::Queue->new( impl => 'File', file => "$TEMP/$qfile",
                            style => 'lifo' );

ok($q3 && ref($q3) eq 'Forks::Queue::File', 'got queue with correct type');
exercise_blocking($q3);
undef $q3;
ok(! -f "$TEMP/$qfile", 'queue file destroyed when object left scope');

done_testing;
