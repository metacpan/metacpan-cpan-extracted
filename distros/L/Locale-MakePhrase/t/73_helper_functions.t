#!/usr/local/bin/perl

use strict;
use warnings;
use Test;
BEGIN { plan tests => 11 };

use Locale::MakePhrase;
use Locale::MakePhrase::BackingStore::File;
ok(1);

$Locale::MakePhrase::DEBUG = 0;
$Locale::MakePhrase::Numeric::DEBUG = 0;
$Locale::MakePhrase::LanguageRule::DEBUG = 0;
$Locale::MakePhrase::RuleManager::DEBUG = 0;
$Locale::MakePhrase::BackingStore::DEBUG = 0;
$Locale::MakePhrase::BackingStore::File::DEBUG = 0;

# ---- Check use of mp() and __() ----

use Locale::MakePhrase qw(mp __);
my $result;

eval { $result = mp("This is a test of mp()"); };
ok($@ =~ /must construct at least one/) or print "Bail out! Not meant to be able to use helper function mp() until object is constructed.\n";

eval { $result = __"This is a test of __()"; };
ok($@ =~ /must construct at least one/) or print "Bail out! Not meant to be able to use helper function __() until object is constructed.\n";


my $bs = new Locale::MakePhrase::BackingStore::File(
  file => 't/lang/lang.mpt',
);
ok($bs) or print "Bail out! Failed to locate translation file.\n";

my $mp = new Locale::MakePhrase(
  language => 'en_au',
  backing_store => $bs,
);
ok($mp) or print "Bail out! Failed to make a 'Locale::MakePhrase' instance.\n";


eval { $result = mp(); };
ok($@ =~ /requires at least one parameter/) or print "Bail out! Helper function mp() need at least one argument.\n";

eval { $result = __; };
ok($@ =~ /requires at least one parameter/) or print "Bail out! Helper function __() need at least one argument.\n";


$result = mp("This is a test of mp()");
ok($result eq "This is a test of mp()") or print "Bail out! Failed the test for mp() (got: $result)\n";

$result = mp("Select [_1] colours",1);
ok($result eq "Select one colour.") or print "Bail out! Failed the localised test for mp() (got: $result)\n";

$result = __"This is a test of __()";
ok($result eq "This is a test of __()") or print "Bail out! Failed the test for __() (got: $result)\n";

$result = __"Select [_1] colours",1;
ok($result eq "Select one colour.") or print "Bail out! Failed the localised test for __() (got: $result)\n";


