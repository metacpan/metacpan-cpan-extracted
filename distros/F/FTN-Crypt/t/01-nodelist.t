#!perl -T
use v5.10.1;
use strict;
use warnings;
use Test::More;

plan tests => 10;

use FTN::Crypt::Nodelist;

# Test #1
my $obj = new_ok('FTN::Crypt::Nodelist', [
    Nodelist => 't/data/nodelist.*',
    Pointlist => [
        't/data/pointlist.*',
        't/data/pointlist_zone66',
    ],
    Username => 'user',
], 'Create FTN::Crypt::Nodelist object') or BAIL_OUT(FTN::Crypt::Nodelist->error);

# Test #2
can_ok($obj, qw/get_email_addr/) or BAIL_OUT('Required methods are unsupported by FTN::Crypt::Nodelist');

# Test #3
my ($addr1, $method1) = $obj->get_email_addr('99:8877/1');
is($addr1, undef, 'Encryption unsupported');

# Test #4
my ($addr2, $method2) = $obj->get_email_addr('99:8877/2');
is($addr2, '<user@f2.n8877.z99.fidonet.net>', 'Get encryption-capable address #1');

# Test #5
is($method2, 'PGP5', 'Get encryption method #1');

# Test #6
my ($addr3, $method3) = $obj->get_email_addr('99:8877/3');
is($addr3, undef, 'Node not found');

# Test #7
my ($addr4, $method4) = $obj->get_email_addr('99:8877/1.1');
is($addr4, '<user@p1.f1.n8877.z99.fidonet.net>', 'Get encryption-capable address #2');

# Test #8
is($method4, 'GnuPG', 'Get encryption method #2');

# Test #9
my ($addr5, $method5) = $obj->get_email_addr('66:5544/1.1');
is($addr4, '<user@p1.f1.n8877.z99.fidonet.net>', 'Get encryption-capable address #3');

# Test #10
is($method5, 'PGP5', 'Get encryption method #3');
