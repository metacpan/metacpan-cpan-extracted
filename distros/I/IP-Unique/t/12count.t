#!/usr/bin/perl -w

use strict;
use Test::More tests => 30;

my $mod = "IP::Unique";
use_ok($mod);

my $ipun = IP::Unique->new();

ok($ipun->unique() == 0);
ok($ipun->total() == 0);

# Good IP addresses
ok($ipun->add_ip("127.0.0.1"));
ok($ipun->add_ip("0.0.0.0"));
ok($ipun->add_ip("1.0.0.0"));
ok($ipun->add_ip("255.0.0.0"));
ok($ipun->add_ip("12.34.56.78"));

ok($ipun->add_ip("255.255.255.255"));
ok($ipun->add_ip("0.0.0.1"));
ok($ipun->add_ip("123.45.67.0"));
ok($ipun->add_ip("100.0.0.5"));
ok($ipun->add_ip("0.0.0.255"));

ok($ipun->unique() == 10);
ok($ipun->total() == 10);

ok($ipun->add_ip("127.0.0.1"));
ok($ipun->add_ip("127.0.0.1"));
ok($ipun->add_ip("127.0.0.1"));
ok($ipun->add_ip("127.0.0.1"));
ok($ipun->add_ip("127.0.0.1"));
ok($ipun->add_ip("127.0.0.1"));
ok($ipun->add_ip("127.0.0.1"));
ok($ipun->add_ip("127.0.0.1"));
ok($ipun->add_ip("127.0.0.1"));
ok($ipun->add_ip("127.0.0.1"));

ok($ipun->unique() == 10);
ok($ipun->total() == 20);

ok($ipun->add_ip("5.5.5.5"));

ok($ipun->unique() == 11);
ok($ipun->total() == 21);

