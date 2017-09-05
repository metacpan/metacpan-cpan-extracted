#!/usr/bin/env perl
#
# Test processing of Authentication-Results
#

use strict;
use warnings;

use Mail::Message::Test;
use Mail::Message::Field::AuthResults;
use Mail::Message::Field::Full;

use Test::More tests => 42;

my $mmff  = 'Mail::Message::Field::Full';
my $mmfa  = 'Mail::Message::Field::AuthResults';

#use Data::Dumper;

#
### constructing
#

my $ar = $mmfa->new('Authentication-Results', server => 'example.com',
  version => 1);
ok defined $ar, 'creation of header';
isa_ok $ar, $mmfa;

is $ar->string, "Authentication-Results: example.com; none\n";

$ar->addResult(method => 'dkim', result => 'fail');
is $ar->string, "Authentication-Results: example.com; dkim=fail\n";

$ar->addResult(method => 'spf', method_version => 2, result => 'pass',
  comment => 'comment', 'ptype.prname' => 'tic', 'p2.p2' => 'tac');

is $ar->string, qq{Authentication-Results: example.com; dkim=fail;
 spf/2=pass (comment) p2.p2="tac" ptype.prname="tic"\n};

#
### Parsing
#

## none

my $ar1 = $mmff->new('Authentication-Results: example.com; none');
isa_ok $ar1, $mmfa;
is $ar1->server, 'example.com', '1 server';
is $ar1->version, 1, '1 version';
my @results1 = $ar1->results;
cmp_ok @results1, '==', 0, '1 results';

### RFC7601 section B6

my $ar2 = $mmff->new('Authentication-Results: example.com;
              dkim=pass reason="good signature"
                header.i=@mail-router.example.net;
              dkim=fail reason="bad signature"
                header.i=@newyork.example.com');

isa_ok $ar2, $mmfa;
is $ar2->server, 'example.com', '2 server';
is $ar2->version, 1, '2 version';
my @results2 = $ar2->results;
cmp_ok @results2, '==', 2, '2 results';

#warn Dumper \@results2;

is_deeply $results2[0],
  { method => 'dkim'
  , method_version => 1
  , result => 'pass'
  , reason => 'good signature'
  , 'header.i' => '@mail-router.example.net'
  }, '2 results[0]';

is_deeply $results2[1],
  { method => 'dkim'
  , method_version => 1
  , result => 'fail'
  , reason => 'bad signature'
  , 'header.i' => '@newyork.example.com'
  }, '2 results[1]';


### RFC7601 section B5 (1)

my $ar3 = $mmff->new('Authentication-Results: example.com;
                  sender-id=fail header.from=example.com;
                  dkim=pass (good signature) header.d=example.com');

isa_ok $ar3, $mmfa;
is $ar3->server, 'example.com', '3 server';
is $ar3->version, 1, '3 version';
my @results3 = $ar3->results;
cmp_ok @results3, '==', 2, '3 results';

#warn Dumper \@results3;

is_deeply $results3[0],
  { method => 'sender-id'
  , method_version => 1
  , result => 'fail'
  , 'header.from' => 'example.com'
  }, '3 results[0]';

is_deeply $results3[1],
  { method => 'dkim'
  , method_version => 1
  , result => 'pass'
  , comment => 'good signature'
  , 'header.d' => 'example.com'
  }, '3 results[1]';

### RFC7601 section B5 (2)

my $ar4 = $mmff->new('Authentication-Results: example.com;
                  auth=pass (cram-md5) smtp.auth=sender@example.com;
                  spf=fail smtp.mailfrom=example.com');

isa_ok $ar4, $mmfa;
is $ar4->server, 'example.com', '4 server';
is $ar4->version, 1, '4 version';
my @results4 = $ar4->results;
cmp_ok @results4, '==', 2, '4 results';

#warn Dumper \@results4;

is_deeply $results4[0],
  { method => 'auth'
  , method_version => 1
  , result => 'pass'
  , comment => 'cram-md5'
  , 'smtp.auth' => 'sender@example.com'
  }, '4 results[0]';

is_deeply $results4[1],
  { method => 'spf'
  , method_version => 1
  , result => 'fail'
  , 'smtp.mailfrom' => 'example.com'
  }, '4 results[1]';


### RFC7601 section B2

my $ar5 = $mmff->new('Authentication-Results: example.com 2; none');
isa_ok $ar5, $mmfa;
is $ar5->server, 'example.com', '5 server';
is $ar5->version, 2, '5 version';
my @results5 = $ar5->results;
cmp_ok @results5, '==', 0, '5 results';

### recover broken

my $ar6 = $mmff->new('Authentication-Results: ; none');
is $ar6->server, 'unknown', '6 server';

my $ar7 = $mmff->new('Authentication-Results: example.com 42 xyz; dkim=pass');
is $ar7->server, 'example.com', '7 server';
is $ar7->version, 42;
is +($ar7->results)[0]{method}, 'dkim';

# Everywhere comments

my $ar8 = $mmff->new('Authentication-Results: (A) example.com (B) 2 (C);
  (C) auth (C2) / (C3) 1 (D) = (E) pass (cram-md5) (G) smtp (H) . (I) auth (J) = (K)
   sender@example.com (L) ; (M) spf (N) = (O) fail smtp (Q) . (R)
   mailfrom (S) = (T) example.com (U) ');

ok defined $ar8, 'header with comments everywhere';
isa_ok $ar8, $mmfa;
is $ar8->server, 'example.com', '8 server';
is $ar8->version, 2, '8 version';
my @results8 = $ar8->results;
cmp_ok @results8, '==', 2, '8 results';

is_deeply $results8[0], $results4[0], '8 results[0]';
is_deeply $results8[1], $results4[1], '8 results[1]';
#warn Dumper $ar8;
