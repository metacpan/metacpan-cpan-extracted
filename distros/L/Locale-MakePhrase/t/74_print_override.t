#!/usr/local/bin/perl

use strict;
use warnings;
use Test;
BEGIN { plan tests => 5 };

use Locale::MakePhrase;
use Locale::MakePhrase::BackingStore::File;
ok(1);

$Locale::MakePhrase::DEBUG = 0;
$Locale::MakePhrase::Print::DEBUG = 9;
$Locale::MakePhrase::BackingStore::File::DEBUG = 0;

# ---- Check use of mp() and __() ----

my $bs = new Locale::MakePhrase::BackingStore::File(
  file => 't/lang/lang.mpt',
);
ok($bs) or print "Bail out! Failed to locate translation file.\n";


my $mp = new Locale::MakePhrase(
  language => 'en_au',
  backing_store => $bs,
);
ok($mp) or print "Bail out! Failed to make a 'Locale::MakePhrase' instance.\n";

#
# Testing of L::M::Print is hard, as the test harness captures STDOUT itself...
#

use Locale::MakePhrase::Print;
ok(1);

no Locale::MakePhrase::Print;
ok(1);

