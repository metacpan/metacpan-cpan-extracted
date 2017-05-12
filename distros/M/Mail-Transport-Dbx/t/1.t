# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'

#########################

# change 'tests => 2' to 'tests => last_test_to_print';

use Test;
BEGIN { plan tests => 2 };

use Mail::Transport::Dbx;
ok(1); # If we made it this far, we're ok.


my $fail;
foreach my $constname (qw(
	DBX_BADFILE DBX_DATA_READ DBX_EMAIL_FLAG_ISSEEN DBX_FLAG_BODY
	DBX_INDEXCOUNT DBX_INDEX_OVERREAD DBX_INDEX_READ DBX_INDEX_UNDERREAD
	DBX_ITEMCOUNT DBX_NEWS_ITEM DBX_NOERROR DBX_TYPE_EMAIL DBX_TYPE_FOLDER
	DBX_TYPE_NEWS DBX_TYPE_VOID)) {
  next if (eval "my \$a = $constname; 1");
  if ($@ =~ /^Your vendor has not defined Mail::Transport::Dbx macro $constname/) {
    print "# pass: $@";
  } else {
    print "# fail: $@";
    $fail = 1;    
  }
}
if ($fail) {
  print "not ok 2\n";
} else {
  print "ok 2\n";
}

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

