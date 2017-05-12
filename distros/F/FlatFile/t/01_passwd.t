# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

my @TO_REMOVE = my $FILE = "/tmp/FlatFile.$$";
END { unlink @TO_REMOVE }
use File::Copy ();
File::Copy::copy("/etc/passwd", $FILE);

use Test::More tests => 5;
use FlatFile;
ok(1); # If we made it this far, we're ok.

my $pw = FlatFile->new(FILE => $FILE,
                                   FIELDS => [qw(uname passwd uid gid gecos home shell)],
                                   FIELDSEP => ":",
                                  );
ok($pw);

my ($root) = my @rec = $pw->lookup(uname => "root");
is(scalar(@rec), 1, "one record for root");

is($root->uid, 0, "root uid is 0 (method call)");
is($root->get_uid, 0, "root uid is 0 (get method call)");

#########################

# Insert your test code below, the Test module is use()ed here so read
# its man page ( perldoc Test ) for help writing this test script.

