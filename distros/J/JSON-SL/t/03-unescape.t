#!/usr/bin/perl
use strict;
use warnings;
use Test::More;
use JSON::SL qw(unescape_json_string);
use utf8;

my $jsn = JSON::SL->new();

my $str = "\\u0041";
my $res = unescape_json_string($str);
is($res, 'A', "Unescaped single sequence OK");

eval {
    unescape_json_string("\\invalid\\escape");
};
ok($@, "Got error for invalid escape $@");

$str = "\\ud790"; # < aleph >
$res = unescape_json_string($str);
is(length($res), 1, "Got single character length for multibyte utf8");
is($res, "א", "character matches");

my $sl = JSON::SL->new();
$sl->unescape_settings(n => 0);
$str = '{"LF_Key\n":"LF_Value\n"}';
$res = $sl->feed($str);
ok($res, "Got result..");
ok(exists $res->{'LF_Key\n'}, "embedded '\\n' key in tact");
is($res->{'LF_Key\n'}, 'LF_Value\n', '\n value in tact');

$sl->unescape_settings(n => 1);
$sl->reset();
$res = $sl->feed($str);
ok(exists $res->{"LF_Key\n"}, "Newline key unescaped..");
is($res->{"LF_Key\n"}, "LF_Value\n", "Newline value unescaped");
done_testing();
