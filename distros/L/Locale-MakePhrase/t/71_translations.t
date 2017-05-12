#!/usr/local/bin/perl

use strict;
use warnings;
use Test;
BEGIN { plan tests => 15 };

use Locale::MakePhrase;
use Locale::MakePhrase::BackingStore::File;
ok(1);

$Locale::MakePhrase::DEBUG = 0;
$Locale::MakePhrase::Utils::DEBUG = 0;
$Locale::MakePhrase::LanguageRule::DEBUG = 0;
$Locale::MakePhrase::RuleManager::DEBUG = 0;
$Locale::MakePhrase::BackingStore::DEBUG = 0;
$Locale::MakePhrase::BackingStore::File::DEBUG = 0;


my $bs = new Locale::MakePhrase::BackingStore::File(
  file => 't/lang/lang.mpt',
);
ok($bs) or print "Bail out! Failed to locate translation file.\n";


my $mp = new Locale::MakePhrase(
  language => 'en_au',
  backing_store => $bs,
);
ok($mp) or print "Bail out! Failed to make a 'Locale::MakePhrase' instance.\n";

my $result;


# ---- Generic translation test ----

$result = $mp->translate("hi there");
ok($result eq "Hello") or print "Bail out! Failed to lookup simple phrase for translation.\n";


# ---- AU localisation of English, left-to-right & right-to-left expressions ----

$result = $mp->translate("Select [_1] colours",1);
ok($result eq "Select one colour.") or print "Bail out! Failed to retrieve localised left-to-right phrase.\n";

$result = $mp->translate("Select [_1] colours",2);
ok($result eq "Two colours selected.") or print "Bail out! Failed to retrieve localised right-to-left phrase.\n";

$result = $mp->translate("Select [_1] colours",5);
ok($result eq "Please select 5 colours.") or print "Bail out! Failed to retrieve localised phrase.\n";


# ---- Function test - defined / undefined ----

$result = $mp->translate("Top [_1] paths", 10);
ok($result eq "Top 10 paths") or print "Bail out! Failed defined() test 1.\n";

$result = $mp->translate("Top [_1] paths", undef),
ok($result eq "Top paths") or print "Bail out! Failed defined() test 2.\n";


# ---- Function test - left() ----

$result = $mp->translate("This is my [_1]", "houses");
ok($result eq "This is my house") or print "Bail out! Failed left() test 1.\n";

$result = $mp->translate("This is my [_1]", "anything"),
ok($result eq "This is my home") or print "Bail out! Failed left() test 2.\n";


# ---- Function test - substr() 2-arg & 3-arg ----

$result = $mp->translate("My name is [_1]", "mathew");
ok($result eq "My name is Mathew") or print "Bail out! Failed substr() test 1 : 2-arg.\n";

$result = $mp->translate("My name is [_1]", "Wilma"),
ok($result eq "My name is Wilma") or print "Bail out! Failed substr() test 2.\n";

$result = $mp->translate("I live in [_1]", "oozz"),
ok($result eq "I live in Australia") or print "Bail out! Failed substr() test 3 : 3-arg.\n";

$result = $mp->translate("I live in [_1]", "Egypt"),
ok($result eq "I live in Egypt") or print "Bail out! Failed substr() test 4.\n";

