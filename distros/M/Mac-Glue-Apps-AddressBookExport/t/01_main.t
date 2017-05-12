#!/usr/bin/perl -w

use strict;
use Test::More tests => 2;

use lib qw( ./blib/lib ../blib/lib );

# Find out if OS is a Mac
my $is_mac = 0;
$is_mac = 1 if ($^O eq 'darwin');

BEGIN { use_ok('Mac::Glue::Apps::AddressBookExport'); }

my $ex = Mac::Glue::Apps::AddressBookExport->new();

isa_ok($ex,'Mac::Glue::Apps::AddressBookExport');

# Add LOTS more tests here, tricky though if we do
# not know their Address Book glue name ?
