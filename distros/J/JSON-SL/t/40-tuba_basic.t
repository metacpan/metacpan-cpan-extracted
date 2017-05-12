#!/usr/bin/perl
use strict;
use warnings;
use Test::More;
use_ok("JSON::SL::Tuba");

my $tuba = JSON::SL::Tuba->new();
isa_ok($tuba, "JSON::SL::Tuba");

#check defaults
ok($tuba->accum_kv, "kv accum enabled by default");
foreach my $sym ('=', '~', '?', '#', '"') {
    ok($tuba->accum_enabled_for($sym),
       "accum enabled for '$sym' by default");
}

ok(!$tuba->cb_unified, "cb_unified disabled by default");
$tuba->allow_unhandled(1);
$tuba->parse('["Hello World"]');
ok(1, "didn't die (yay!)");
done_testing();