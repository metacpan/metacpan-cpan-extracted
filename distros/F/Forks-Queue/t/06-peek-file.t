use strict;
use warnings;
use Test::More;
require "t/exercises.tt";

PREP('File');

my $TEMP = TEMP_DIR();
unlink "$TEMP/q6f";

ok(! -f "$TEMP/q6f", 'queue file does not exist yet');
my $q4 = Forks::Queue->new( impl => 'File', file => "$TEMP/q6f",
                            style => 'fifo' );
$q4->clear;
exercise_peek($q4);
undef $q4;

done_testing;
