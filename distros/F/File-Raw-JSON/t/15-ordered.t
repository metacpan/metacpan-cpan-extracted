#!/usr/bin/perl
use strict;
use warnings;
use Test::More;
use File::Raw;
use File::Raw::JSON;
use File::Temp qw(tempdir);

# `ordered => 1` decodes JSON objects as Tie::OrderedHash hashes so
# insertion order is preserved on the Perl side. yyjson already
# preserves source order on parse; the regular HV walks it loses
# is what this option works around.
#
# Tie::OrderedHash is now a hard dep of File::Raw::JSON (declared in
# PREREQ_PM), so we don't skip-all - if it's missing the install was
# broken and we want a loud failure.

my $dir = tempdir(CLEANUP => 1);

subtest 'top-level keys preserved in source order' => sub {
    my $f = "$dir/o1.json";
    File::Raw::spew($f, q|{"z":1,"a":2,"m":3,"_":4}|);
    my $r = File::Raw::slurp($f, plugin => 'json', ordered => 1);
    is_deeply([keys %$r], ['z','a','m','_'], 'keys in document order');
    is($r->{z}, 1, 'value via key access');
    is($r->{a}, 2, 'value via key access');
    is(ref(tied(%$r)), 'Tie::OrderedHash', 'top-level hash is tied');
};

subtest 'default mode (no ordered) produces a plain HV' => sub {
    my $f = "$dir/o2.json";
    File::Raw::spew($f, q|{"a":1,"b":2}|);
    my $r = File::Raw::slurp($f, plugin => 'json');
    is(scalar(tied(%$r) // ''), '', 'no tie under default');
};

subtest 'nested objects propagate ordered through' => sub {
    my $f = "$dir/o3.json";
    File::Raw::spew($f, q|{"top":{"z":1,"a":2},"more":{"y":1,"x":2}}|);
    my $r = File::Raw::slurp($f, plugin => 'json', ordered => 1);
    is_deeply([keys %{$r->{top}}],  ['z','a'], 'inner top keys ordered');
    is_deeply([keys %{$r->{more}}], ['y','x'], 'inner more keys ordered');
    is(ref(tied(%{$r->{top}})), 'Tie::OrderedHash', 'nested HV also tied');
};

subtest 'arrays of objects: each object preserves order' => sub {
    my $f = "$dir/o4.json";
    File::Raw::spew($f, q|[{"z":1,"a":2},{"y":1,"x":2}]|);
    my $r = File::Raw::slurp($f, plugin => 'json', ordered => 1);
    is(ref($r), 'ARRAY', 'top-level array');
    is_deeply([keys %{$r->[0]}], ['z','a'], 'first object ordered');
    is_deeply([keys %{$r->[1]}], ['y','x'], 'second object ordered');
};

subtest 'jsonl + ordered: each row preserves key order' => sub {
    my $f = "$dir/o5.jsonl";
    File::Raw::spew(
        $f,
        qq({"z":1,"a":2}\n{"y":1,"x":2}\n{"q":1,"w":2,"e":3}\n),
    );
    my $rows = File::Raw::slurp($f, plugin => 'jsonl', ordered => 1);
    is(scalar @$rows, 3, 'three rows');
    is_deeply([keys %{$rows->[0]}], ['z','a'],     'row 1 ordered');
    is_deeply([keys %{$rows->[1]}], ['y','x'],     'row 2 ordered');
    is_deeply([keys %{$rows->[2]}], ['q','w','e'], 'row 3 ordered');
};

subtest 'jsonl streaming: callback receives ordered hashref per record' => sub {
    my $f = "$dir/o6.jsonl";
    File::Raw::spew(
        $f,
        qq({"z":1,"a":2}\n{"y":1,"x":2}\n),
    );
    my @seen;
    File::Raw::each_line(
        $f,
        sub { push @seen, [keys %{$_[0]}] },
        plugin => 'jsonl', ordered => 1,
    );
    is_deeply($seen[0], ['z','a'], 'streamed row 1 ordered');
    is_deeply($seen[1], ['y','x'], 'streamed row 2 ordered');
};

subtest 'round-trip preserves order byte-for-byte' => sub {
    my $f1 = "$dir/o7-in.json";
    my $f2 = "$dir/o7-out.json";
    my $payload = q|{"z":1,"a":2,"m":3,"_":4}|;
    File::Raw::spew($f1, $payload);

    my $r = File::Raw::slurp($f1, plugin => 'json', ordered => 1);
    File::Raw::spew($f2, $r, plugin => 'json');
    is(File::Raw::slurp($f2), $payload,
       'decode-then-encode reproduces the input bytes');
};

subtest 'pretty + ordered round-trip' => sub {
    my $f1 = "$dir/o8-in.json";
    my $f2 = "$dir/o8-out.json";
    File::Raw::spew($f1, q|{"alpha":1,"beta":2,"gamma":3}|);

    my $r = File::Raw::slurp($f1, plugin => 'json', ordered => 1);
    File::Raw::spew($f2, $r, plugin => 'json', pretty => 1);
    my $pretty = File::Raw::slurp($f2);
    # Source key order is alpha, beta, gamma - so the pretty-printed
    # output must list them in that order, not Perl-randomised.
    like($pretty, qr/"alpha".*"beta".*"gamma"/s,
         'pretty output preserves decoded order');
};

subtest 'value-mapping: types round-trip cleanly through the tied path' => sub {
    my $f = "$dir/o9.json";
    File::Raw::spew(
        $f,
        q|{"int":42,"float":0.5,"str":"hi","null":null,|
        . q|"true":true,"false":false,"arr":[1,2,3],"obj":{"k":"v"}}|,
    );
    my $r = File::Raw::slurp($f, plugin => 'json', ordered => 1);
    is($r->{int},                     42,        'int round-trips');
    cmp_ok($r->{float}, '==',         0.5,       'float round-trips');
    is($r->{str},                     'hi',      'string round-trips');
    is($r->{null},                    undef,     'null round-trips');
    ok($r->{true},                               'true round-trips truthy');
    ok(!$r->{false},                             'false round-trips falsy');
    is_deeply($r->{arr},              [1,2,3],   'array round-trips');
    is($r->{obj}{k},                  'v',       'nested obj round-trips');
};

subtest 'default decode produces a plain HV (no tie magic)' => sub {
    # ordered => 1 is opt-in; the default path must NOT install tie
    # magic.  Probes the produced HV via Scalar::Util::reftype-style
    # check - if tied() returns defined, ordered-mode leaked.
    my $f = "$dir/o10.json";
    File::Raw::spew($f, q|{"k":1}|);
    my $r = File::Raw::slurp($f, plugin => 'json');
    ok(!defined(tied(%$r)), 'default decode produces a plain HV');
};

done_testing;
