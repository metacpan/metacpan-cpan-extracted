#!/usr/local/bin/perl

use strict;
use warnings;
use Test;
BEGIN { plan tests => 3 };

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


