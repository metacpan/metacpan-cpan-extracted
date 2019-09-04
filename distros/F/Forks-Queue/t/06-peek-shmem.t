use strict;
use warnings;
use Test::More;
use lib '.';   # 5.26 compat
require "t/exercises.tt";

PREP('Shmem');

my $qfile = "q6m-$$";
my $TEMP = do {
    no warnings 'once';
    $Forks::Queue::Shmem::DEV_SHM;
};
unlink "$TEMP/$qfile";

ok(! -f "$TEMP/$qfile", 'queue file does not exist yet');
my $q4 = Forks::Queue->new( impl => 'Shmem', file => "$qfile",
                            style => 'fifo' );
$q4->clear;
exercise_peek($q4);
undef $q4;

done_testing;
