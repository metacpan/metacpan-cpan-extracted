#!/usr/bin/perl
use strict;
use warnings;
use JSON::SL qw(decode_json);
use Test::More;
use Data::Dumper;


my $res;

$res = decode_json('{"boolean":true}');
isa_ok($res->{boolean}, 'JSON::SL::Boolean');
ok(${$res->{boolean}}, "::Boolean true variant");


$res = decode_json('{"boolean":false}');
isa_ok($res->{boolean}, 'JSON::SL::Boolean');
ok(!${$res->{boolean}}, "::Boolean false variant");

$res = decode_json('{"something":null}');
ok(exists $res->{something}, "null value exists");
ok(!defined $res->{something}, "but is undef");

done_testing();