#!/usr/bin/perl -w

use Email::Auth::AddressHash;
use Test::More tests => 10;
use strict;

my $rcpt1 = 'borednow+38765429@domain.com';
my $rcpt2 = 'tla+lj387654@domain.com';
my $real1 = 'borednow+97e65bc5@domain.com';
my $real2 = 'tla+ljedf934@domain.com';

my $sender = 'happyuser@tmomail.net';

my $authen1 = Email::Auth::AddressHash->new('sassifrage', 8);
my $authen2 = Email::Auth::AddressHash->new('Foobar', 6, 'lj');
is(ref($authen1), 'Email::Auth::AddressHash', "Class creation");
is(ref($authen2), 'Email::Auth::AddressHash', "Class creation with prefix");

my $hash1 = $authen1->split_address($rcpt1)->{'extension'};
my $hash2 = $authen2->split_address($rcpt2)->{'extension'};
is($hash1, "38765429", "sub split_address");
is($hash2, "387654", "sub split_address with prefix");

my $hash3 = $authen1->split_address($real1)->{'extension'};
my $hash4 = $authen2->split_address($real2)->{'extension'};

is($authen1->check_hash($sender, $hash1), 0, "sub check_hash false");
is($authen2->check_hash($sender, $hash2), 0, "sub check_hash with prefix false");
is($authen1->check_hash($sender, $hash3), 1, "sub check_hash true");
is($authen2->check_hash($sender, $hash4), 1, "sub check_hash with prefix true");

is($authen1->generate_hash($sender), '97e65bc5', "sub generate_hash");
is($authen2->generate_hash($sender, 1), 'ljedf934', "sub generate_hash with prefix");

