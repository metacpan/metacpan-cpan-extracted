#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::Exception;

unless($ENV{'INTERNET_TESTING'}) {
  plan skip_all => 'No remote tests. (to enable set INTERNET_TESTING=1)';
}

plan tests => 23;

use_ok('Mail::STS::Policy');

my $p = Mail::STS::Policy->new;
isa_ok($p, 'Mail::STS::Policy');

# tests defaults
is($p->version, 'STSv1', 'default version');
is($p->mode, 'none', 'default mode');
is($p->max_age, undef, 'default max_age');
is_deeply($p->mx, [], 'empty mx list');

my $hash;
lives_ok { $hash = $p->as_hash } 'format policy as hash';

is_deeply(
  $hash,
  {
    'version' => 'STSv1',
    'mode' => 'none',
    'max_age' => undef,
    'mx' => [],
  },
  'default output as hash'
);

my $string;
lives_ok { $string = $p->as_string } 'format policy as string';

my $expect = 'version: STSv1
mode: none
';
is($string, $expect, 'default policy as string');

# parsing
my $example = 'version: STSv1
mode: enforce
mx: mail.example.com
mx: *.example.net
mx: backupmx.example.com
max_age: 604800';

lives_ok {
 $p = Mail::STS::Policy->new_from_string($example);
} 'parse example policy';

isa_ok($p, 'Mail::STS::Policy');

is($p->version, 'STSv1', 'test version');
is($p->mode, 'enforce', 'correct mode');
is($p->max_age, 604800, 'correct max_age');
is_deeply($p->mx, ['mail.example.com', '*.example.net', 'backupmx.example.com'], 'all mx hosts');

# match mx hosts
is($p->match_mx('mail.example.com'), 1, 'match mail.example.com');
is($p->match_mx('mail.wrong.com'), 0, 'not match mail.wrong.com');
is($p->match_mx('example.net'), 1, 'match example.net domain of wildcard');
is($p->match_mx('test.example.net'), 1, 'match test.example.net subdomain of wildcard');
is($p->match_mx('backupmx.example.com'), 1, 'match mail.example.com');
is($p->match_mx('example.com'), 0, 'dont match example.com');

