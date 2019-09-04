use strict;
use warnings;
use Test::More;
use lib '.';   # 5.26 compat
require "t/exercises.tt";

PREP('Shmem');

my $TEMP = TEMP_DIR();
my $qfile = "q5m-$$";

unlink "$TEMP/$qfile";
ok(-d $TEMP, 'queue directory exists');
ok(! -f "$TEMP/$qfile", 'queue file does not exist yet');

my $q = Forks::Queue->new( impl => 'Shmem', limit => 5, on_limit => 'fail' );

exercise_limits($q, 'fail');

$q->{on_limit} = 'block';
exercise_limits($q, 'block');

undef $q;
ok(! -f "$TEMP/$qfile", 'queue file deleted on queue destruction');

done_testing;
