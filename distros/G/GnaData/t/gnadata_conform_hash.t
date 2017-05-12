#!/usr/bin/perl -w
$::_test = 1;
use GnaData::Conform::Hash;
use Test::Simple tests=>10;


my ($conform) = GnaData::Conform::Hash->new;
$conform->load({"a"=>"b", "b"=>"c"});
%f = ("a"=>"foobar", "b"=>"powbar");
$conform->conform(\%f);
ok($f{'b'} eq "foobar");

$conform->load({"d"=>"boo"});
%f = ("d"=>"powbar");
$conform->conform(\%f);
ok($f{'boo'} eq "powbar", "additional load");
ok(!exists($f{'d'}));

$conform->load_reverse({"e"=>"boo"});
%f = ("boo"=>"powbar");
$conform->conform(\%f);
ok($f{'e'} eq "powbar", "reverse load");
ok(!exists($f{'boo'}));

$conform->load({"FAX"=>"boo"});
%f = ("fax"=>"powbar");
$conform->conform(\%f);
ok($f{'boo'} eq "powbar", "case insensitive");

$conform->delete_blank(0);
%f = ("a"=>"", "b"=>"powbar");
$conform->conform(\%f);
ok(exists($f{'c'}));
ok(exists($f{'b'}));

$conform->delete_blank(1);
%f = ("a"=>"", "b"=>"powbar");
$conform->conform(\%f);
ok(exists($f{'c'}));
ok(!exists($f{'b'}));



