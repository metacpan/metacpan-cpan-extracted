# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 6;
BEGIN { 
	use_ok('Locale::Framework');
	use_ok('Locale::Framework::wxLocale');
};

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

my $LOC=new Locale::Framework();

### Locale::Framework::wxLocale testing

$LOC->init(new Locale::Framework::wxLocale("./locale","default"));

ok(_T("This is a test") eq "This is a test","Lang with Locale::Framework::wxLocale backend");

### Set language

Locale::Framework::language("nl");
ok(_T("This is a test") eq "Dit is een test","Lang with Locale::Framework::wxLocale backend");

### Set translation and reread translation

Locale::Framework::language("de");
ok((not Locale::Framework::set_translation("This is a test","Dies ist ein test")),"Lang with Locale::Framework::wxLocale backend");

Locale::Framework::language("nl");
Locale::Framework::clear_cache();
print _T("This is a test"),"\n";
ok(_T("This is a test") eq "Dit is een test","Lang with Locale::Framework::wxLocale backend");



