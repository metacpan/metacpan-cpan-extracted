use strict;
use warnings;
use Test::More;
require "t/exercises.tt";

PREP('File');

my $TEMP = TEMP_DIR();

unlink "$TEMP/q5f";
ok(-d $TEMP, 'queue directory exists');
ok(! -f "$TEMP/q5f", 'queue file does not exist yet');

my $q = Forks::Queue->new( impl => 'File', limit => 5, on_limit => 'fail' );

exercise_limits($q, 'fail');

$q->{on_limit} = 'block';
exercise_limits($q, 'block');

undef $q;
ok(! -f "$TEMP/q5f", 'queue file deleted on queue destruction');

done_testing;
