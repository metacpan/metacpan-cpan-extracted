#!/usr/local/bin/perl

use strict;
use warnings;
use Test;
BEGIN { plan tests => 6 };

use Locale::MakePhrase;
use Locale::MakePhrase::BackingStore::Directory;
ok(1);

$Locale::MakePhrase::DEBUG = 0;
$Locale::MakePhrase::Utils::DEBUG = 0;
$Locale::MakePhrase::LanguageRule::DEBUG = 0;
$Locale::MakePhrase::RuleManager::DEBUG = 0;
$Locale::MakePhrase::BackingStore::DEBUG = 0;
$Locale::MakePhrase::BackingStore::Directory::DEBUG = 0;


my $bs = new Locale::MakePhrase::BackingStore::Directory(
  directory => 't/lang',
);
ok($bs) or print "Bail out! Failed to locate translation directory.\n";


my $mp = new Locale::MakePhrase(
  language => 'en_au',
  backing_store => $bs,
);
ok($mp) or print "Bail out! Failed to make a 'Locale::MakePhrase' instance.\n";

my $result;


$result = $mp->translate("hi there");
ok($result eq "Hello") or print "Bail out! Failed to lookup simple phrase for translation.\n";

$result = $mp->translate("Select [_1] colours",1);
ok($result eq "Select one colour.") or print "Bail out! Failed to retrieve localised left-to-right phrase.\n";

$result = $mp->translate("Select [_1] colours",2);
ok($result eq "Please select 2 colours.") or print "Bail out! Failed to retrieve localised right-to-left phrase.\n";


