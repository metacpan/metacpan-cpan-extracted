#!/usr/bin/perl -w

use strict;
use Test::More 'no_plan';
$| = 1;



# =begin testing
{
BEGIN { use_ok( 'Fuse::Simple', qw(:usual :debug :tools :filesys)); }
}



# =begin testing
{
is(fetch("README"), $Fuse::Simple::fs->{README}, "fetch() test");
}



# =begin testing
{
is(runcode("foo"), "foo",                        "runcode with string");
is_deeply(runcode(["A","B","C"]), ["A","B","C"], "runcode with arrayref");
is_deeply(runcode({"A"=>"B"}), {"A"=>"B"},       "runcode with hashref");
is(runcode(undef), undef,                        "runcode with undef");
is(runcode(sub {return "foo"}), "foo",           "runcode with foo");
is(runcode(sub {return shift}, "foo"), "foo",    "runcode with an arg");
is_deeply(runcode(sub{return{"a"=>"b"}}, {"a"=>"b"}), {"a"=>"b"},
                                                 "runcode sub returns hash");
}



# =begin testing
{
is(saferun(sub{"foo"}), "foo", "saferun string");
is(saferun(sub{shift}, "foo"), "foo", "saferun arg");
is(ref(saferun(sub{die "foo"})), "ERROR", "saferun error");
is_deeply(saferun(sub{die ["foo"]}), ["foo"], "saferun array die");
}



# =begin testing
{
is(ref(fserr("foo")), "ERROR", "fserr ref type");
is(${&fserr("foo")}, "foo", "fserr arg passed");
}



# =begin testing
{
is(ref(nocache("foo")), "NOCACHE", "nocache ref type");
is(${&nocache("foo")}, "foo", "nocache arg passed");
}



# =begin testing
{
my $test = wrap(sub {return "foo".(shift||"")}, "foo");
is(ref($test), "CODE", "wrap a coderef");
is(&$test(), "foo", "wrapped coderef returns expected");
is(&$test("bar"), "foobar", "wrapped coderef args work");
}



# =begin testing
{
is(quoted("foo"), '"foo"', "quoting");
is(quoted('\\'), '"\\\\"', "quoting backslash");
is(quoted("\$\@\"\t\r\n\f\a\e"), '"\$\@\"\t\r\n\f\a\e"', "quoting fun");
is(quoted('42'), '42', "unquoted numbers");
is(quoted(1,2,3), '1, 2, 3', "quoted list");
}



# =begin testing
{
my $foo = undef;
my $acc = accessor(\$foo);

is(ref($acc), "CODE", "accessor is a coderef");
is($foo, undef, "undef at first");
is(&$acc(), undef, "undef thru accessor");

&$acc("foo");
is($foo, "foo", "foo was set");
is(&$acc(), "foo", "foo thru accessor");

$foo="bar";
is(&$acc(), "bar", "bar thru accessor");
}



# =begin testing
{
is(fs_not_imp(), -38, "fs_not_imp -38");
}



# =begin testing
{
is(fs_flush(), 0, "fs_flush");
}




1;
