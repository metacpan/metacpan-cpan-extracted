use strict;
use warnings;
use Test::More;
require "t/exercises.tt";

PREP('Shmem');

my $TEMP = TEMP_DIR();
unlink "$TEMP/q6m";

ok(! -f "$TEMP/q6m", 'queue file does not exist yet');
my $q4 = Forks::Queue->new( impl => 'Shmem', file => "q6m",
                            style => 'fifo' );
$q4->clear;
exercise_peek($q4);
undef $q4;

done_testing;
