# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.


BEGIN { $| = 1; print "1..9\n"; }
END {print "not ok 1\n" unless $loaded;}
use Digest::UserSID;
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):


my $string = $ARGV[0] || "test";
my $user = $ARGV[1] || "xwolf";
my $sid = new Digest::UserSID;
my $res = $sid->create($user,$string);
my %hash;
my %test;

print "Creating key.....\n";

if ($res) {
  print "ok 2\n";
  print "key: $sid->{'sha'}\t";
  print "time: $sid->{'time'}\n";
  dbmopen(%hash,$UserSID::FILE,0644);
  %test = %hash; 
  dbmclose(%hash);

  print "Reading UserSID-Data:\n";
  my $key;
  foreach $key (keys %test) {
    print "\t$key: $test{$key}\n";
  }
} else {
  print "not ok 2\n";
}

print "Removing User.....\n";

$res = $sid->remove;
if ($res) {
  print "ok 3\n";
} else {
  print "not ok 3\n";
}

print "Adding User ($user,$string): .....";
my $sha = USID_add($user,$string);
print "SHA: $sha\n";
dbmopen(%hash,$UserSID::FILE,0644);
%test = %hash;
dbmclose(%hash);
if ($sha) {
  print "ok 4\n";
} else {
  print "not ok 4\n";
}

print "Updating base.....\n";

$res = USID_update($user,$sha);
if ($res) {
  print "ok 5\n";
} else {
  print "not ok 5\n";
}


print "Check after time-delay (sleeping 2 seconds; Valid-delay: $UserSID::MAXSECONDS seconds)....";
sleep(2);
if (USID_check($user,$sha)) {
  print "SID valid\n";
  print "ok 6\n";
} else {
  print "SID not valid\n";
  print "not ok 6\n";
}

$UserSID::MAXSECONDS =1;
print "Changing Delay to $UserSID::MAXSECONDS.....";

if (USID_check($user,$sha)) {
  print "SID valid\n";
  print "not ok 7\n";

} else {
  print "SID not valid\n";
  print "ok 7\n";
}


# print "Test using makewebsid:\n";

# print "Setting Environment:\n";
$ENV{'SERVER_NAME'} = "www.cpan.org";
$ENV{'REMOTE_HOST'} = "209.85.157.220";
$ENV{'HTTP_USER_AGENT'} = "Netscape";
$ENV{'HTTP_REFERER'} = "www.cpan.org";
# print "\tSERVER_NAME: $ENV{'SERVER_NAME'}\n";
# print "\tREMOTE_HOST: $ENV{'REMOTE_HOST'}\n";
# print "\tHTTP_USER_AGENT: $ENV{'HTTP_USER_AGENT'}\n";
# print "\tHTTP_REFERER: $ENV{'HTTP_REFERER'}\n";

my $pass = makewebsid($user);
print "User $user got SID $pass.....";

if (checkwebsid($user,$pass)) {
  print "SID valid\n";
  print "ok 8\n";
} else {
  print "SID not valid\n";
  print "not ok 8\n";
}

print "Check after time-delay using checkwebsid (sleeping 2 seconds; Valid-delay: $UserSID::MAXSECONDS seconds)....";

sleep(2);

if (checkwebsid($user,$pass)) {
  print "SID ok\n";
  print "not ok 9\n";
} else {
  print "SID invalid.\n";
  print "ok 9\n";
}


