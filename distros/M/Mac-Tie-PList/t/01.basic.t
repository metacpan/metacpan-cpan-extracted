use Test::More tests => 2;

BEGIN { use_ok('Mac::Tie::PList') };

my $plist = Mac::Tie::PList->new_from_file("notthere");
ok(!$plist);


#########################
# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

