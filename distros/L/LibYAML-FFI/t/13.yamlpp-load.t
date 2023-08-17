#!/usr/bin/env perl
use Test2::V0;
use YAML::PP;
use LibYAML::FFI::YPP;
use Test::More ();
use FindBin '$Bin';

my $yaml = <<'EOM';
foo: &X bar
k: !!int "23"
FOO: *X
flow: { "a":23 }
EOM

my $yp = LibYAML::FFI::YPP->new;

my $data = $yp->load_string($yaml);
my $expected = {
    foo => 'bar',
    k => 23,
    FOO => 'bar',
    flow => { a => 23 },
};
is($data, $expected, "load_string data like expected");
#diag Test::More::explain($data);
#diag Test::More::explain($expected);

$yaml = <<'EOM';
foo: "bar"
 x: y
EOM
#eval {
#    $data = $yp->load_string($yaml);
#};
#my $error = $@;
#cmp_ok($error, '=~', qr{did not find expected key}, "Invalid YAML - expected error message");

done_testing;
