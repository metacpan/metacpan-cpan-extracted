use Test::More tests => 5;
use FlatFile;
ok(1); # If we made it this far, we're ok.

package PW;
use File::Copy ();
use vars ('@ISA', '$FILE', '@FIELDS', '$FIELDSEP');
@ISA = qw(FlatFile);
my @TO_REMOVE = $FILE = "/tmp/FlatFile.$$";
END { unlink @TO_REMOVE }
File::Copy::copy("/etc/passwd", $FILE);
$FIELDS = [qw(uname passwd uid gid gecos home shell)];
$FIELDSEP = ":";


package main;

my $pw = PW->new;
ok($pw);

my ($root) = my @rec = $pw->lookup(uname => "root");
is(scalar(@rec), 1, "one record for root");
is($root->uid, 0, "root uid is 0");
is($root->get_uid, 0, "root uid is 0");

#########################

# Insert your test code below, the Test module is use()ed here so read
# its man page ( perldoc Test ) for help writing this test script.

