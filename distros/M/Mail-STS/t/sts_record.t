#!/usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 9;
use Test::Exception;

use_ok('Mail::STS::STSRecord');

my $r = Mail::STS::STSRecord->new(
  v => 'STSv1',
  id => '123',
);
isa_ok($r, 'Mail::STS::STSRecord');
is($r->as_string, 'v=STSv1; id=123;', 'correct string representation');

$r = Mail::STS::STSRecord->new_from_string('v=STSv1; id=zumsel');
isa_ok($r, 'Mail::STS::STSRecord');
is($r->v, 'STSv1', 'parse correct version');
is($r->id, 'zumsel', 'parse correct id');
is($r->as_string, 'v=STSv1; id=zumsel;', 'correct string representation');

throws_ok {
  Mail::STS::STSRecord->new_from_string('v=STSv1;');
} qr/Attribute \(id\) is required/, 'string without an id';

lives_ok {
  Mail::STS::STSRecord->new_from_string('v=STSv1; id=123; unknown=bla');
} 'ignore unknown attributes';
