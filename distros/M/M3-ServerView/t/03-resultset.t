#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 17;
use Test::Exception;

BEGIN { use_ok("M3::ServerView::ResultSet"); }

throws_ok {
    M3::ServerView::ResultSet->new({});
} qr/Not an array reference/;

my $rs = M3::ServerView::ResultSet->new([]);
isa_ok($rs, "M3::ServerView::ResultSet");
is($rs->count, 0);

$rs = M3::ServerView::ResultSet->new([1..5]);
is($rs->count, 5);

is($rs->next, 1);
is($rs->next, 2);
is($rs->next, 3);
is($rs->next, 4);
is($rs->next, 5);
ok(!defined $rs->next);

$rs->reset();
is($rs->next, 1);
is($rs->next, 2);
is($rs->next, 3);
is($rs->next, 4);
is($rs->next, 5);
ok(!defined $rs->next);
