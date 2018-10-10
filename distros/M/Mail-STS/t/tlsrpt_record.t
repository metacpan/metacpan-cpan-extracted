#!/usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 7;
use Test::Exception;

use_ok('Mail::STS::TLSRPTRecord');

my $r = Mail::STS::TLSRPTRecord->new(
  v => 'TLSRPTv1',
  rua => 'joe@example.com',
);
isa_ok($r, 'Mail::STS::TLSRPTRecord');
is($r->as_string, 'v=TLSRPTv1; rua=joe@example.com;', 'correct string representation');

$r = Mail::STS::TLSRPTRecord->new_from_string('v=TLSRPTv1; rua=john@example.com');
isa_ok($r, 'Mail::STS::TLSRPTRecord');
is($r->v, 'TLSRPTv1', 'parse correct version');
is($r->rua, 'john@example.com', 'parse correct id');
is($r->as_string, 'v=TLSRPTv1; rua=john@example.com;', 'correct string representation');

