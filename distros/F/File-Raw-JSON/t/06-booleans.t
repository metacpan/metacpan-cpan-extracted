#!/usr/bin/perl
use strict;
use warnings;
use Test::More;
use File::Raw;
use File::Raw::JSON;
use File::Temp qw(tempdir);

my $dir = tempdir(CLEANUP => 1);

# Default class round-trip
my $f = "$dir/b.json";
File::Raw::spew($f, '{"on":true,"off":false}');
my $r = File::Raw::slurp($f, plugin => 'json');
isa_ok($r->{on},  'File::Raw::JSON::Boolean', 'true sentinel');
isa_ok($r->{off}, 'File::Raw::JSON::Boolean', 'false sentinel');
ok($r->{on},  'true is truthy');
ok(!$r->{off}, 'false is falsy');

# Re-encode preserves
File::Raw::spew("$dir/c.json", $r, plugin => 'json', sort_keys => 1);
is(File::Raw::slurp("$dir/c.json"), '{"off":false,"on":true}',
   'sentinels round-trip to same JSON literals');

my $pay = { on => \1, off => \0 };
File::Raw::spew("$dir/d.json", $pay, plugin => 'json', sort_keys => 1);
is(File::Raw::slurp("$dir/d.json"), '{"off":false,"on":true}',
   'encoder treats \1/\0 as true/false');

# boolean_class option redirects the stash
SKIP: {
    eval { require JSON::PP; 1 } or skip 'JSON::PP not installed', 2;
    my $back = File::Raw::slurp($f, plugin => 'json',
                                boolean_class => 'JSON::PP::Boolean');
    isa_ok($back->{on},  'JSON::PP::Boolean', 'true under JSON::PP::Boolean');
    isa_ok($back->{off}, 'JSON::PP::Boolean', 'false under JSON::PP::Boolean');
}

# Encoder accepts blessed booleans from any of the recognised classes
SKIP: {
    eval { require JSON::PP; 1 } or skip 'JSON::PP not installed', 1;
    my $payload = { on => JSON::PP::true(), off => JSON::PP::false() };
    File::Raw::spew("$dir/e.json", $payload, plugin => 'json', sort_keys => 1);
    is(File::Raw::slurp("$dir/e.json"), '{"off":false,"on":true}',
       'encoder recognises JSON::PP::Boolean by name');
}

done_testing;
