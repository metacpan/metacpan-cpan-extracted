# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 5;
BEGIN { 
	use_ok('Locale::Framework');
};

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

my $LOC=new Locale::Framework;

### Locale::Framework::Dumb testing

ok(_T("This is a test") eq "This is a test","Lang default - Lang with Locale::Framework::Dumb backend");

### Set language

$LOC->language("nl");
ok(_T("This is a test") eq "This is a test","Lang default - Lang with Locale::Framework::Dumb backend");

### Set translation and reread translation

$LOC->language("nl");
ok((not Locale::Framework::set_translation("This is a test","Dit is een test")),"Lang default - Lang with Locale::Framework::Dumb backend");

$LOC->clear_cache();
ok(_T("This is a test") eq "This is a test","Lang default - Lang with Locale::Framework::Dumb backend");

