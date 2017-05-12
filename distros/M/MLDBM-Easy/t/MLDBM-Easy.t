# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl MLDBM-Easy.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 4;
BEGIN { use_ok('MLDBM::Easy') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

use Fcntl;

tie my(%db), 'MLDBM::Easy', 'mldbm-easy', O_CREAT|O_RDWR, 0640 or die $!;

my $old = ($db{this}[0] ||= 0);
my $new = ++$db{this}[0];

ok($old == $new - 1);
ok($old == $db{this}[0] - 1);
ok($new == $db{this}[0]);
