#!/usr/bin/perl -w

use strict;
use Test::More tests => 18;

my $mod = "IP::Unique";
use_ok($mod);

# Testing addition functions on bad IP addresses, since we parse in C

my $ipun = IP::Unique->new();

ok($ipun->unique() == 0);
ok($ipun->total() == 0);

# Bad IP addresses
ok($ipun->add_ip("1234.56.78.90") == 0);
ok($ipun->add_ip("123.1234.78.90") == 0);
ok($ipun->add_ip("123.123.1234.123") == 0);
ok($ipun->add_ip("256.0.0.1") == 0);
ok($ipun->add_ip("....") == 0);

ok($ipun->add_ip(".") == 0);
ok($ipun->add_ip("") == 0);
ok($ipun->add_ip("......") == 0);
ok($ipun->add_ip("123456789") == 0);
ok($ipun->add_ip("...0") == 0);

ok($ipun->add_ip("not.a.goo.dip") == 0);
ok($ipun->add_ip("jaybonci") == 0);
ok($ipun->add_ip("-1") == 0);

ok($ipun->unique() == 0);
ok($ipun->total() == 0);

