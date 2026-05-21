#!perl
use 5.010;
use strict;
use warnings;
use Test::More;

# file_json_decode / file_json_encode are the in-memory codec
# entry points: no path, no syscalls, just bytes <-> Perl value.
# Same options grammar as the plugin tail.

use File::Raw::JSON qw(file_json_decode file_json_encode);

subtest 'document decode + encode round-trip' => sub {
    my $bytes = q|{"alpha":1,"beta":[2,3,4],"gamma":null,"delta":"hi"}|;
    my $val   = file_json_decode($bytes);
    is(ref $val, 'HASH', 'decoded a hashref');
    is($val->{alpha}, 1,             'integer field');
    is_deeply($val->{beta}, [2,3,4], 'array field');
    is($val->{gamma}, undef,         'null field');
    is($val->{delta}, 'hi',          'string field');

    my $reencoded = file_json_encode($val, sort_keys => 1);
    is(file_json_decode($reencoded)->{alpha}, 1,
       'round-trip: re-decoded matches original alpha');
};

subtest 'pretty + sort_keys' => sub {
    my $out = file_json_encode({b => 2, a => 1, c => 3},
                               pretty => 1, sort_keys => 1);
    like($out, qr/"a": 1.*"b": 2.*"c": 3/s, 'sorted + pretty key order');
    like($out, qr/\n/,                       'pretty -> contains newlines');
};

subtest 'mode => lines (decode JSONL)' => sub {
    my $rows = file_json_decode(qq|{"a":1}\n{"b":2}\n{"c":3}\n|,
                                mode => 'lines');
    is(ref $rows, 'ARRAY',  'decoded JSONL returns AoV');
    is(scalar @$rows, 3,    'three rows');
    is($rows->[0]{a}, 1,    'row 0');
    is($rows->[2]{c}, 3,    'row 2');
};

subtest 'mode => lines (encode JSONL)' => sub {
    my $bytes = file_json_encode([{x => 1}, {y => 2}],
                                 mode => 'lines');
    is($bytes, qq|{"x":1}\n{"y":2}\n|, 'one record per line, trailing \n');
};

subtest 'ordered => 1 preserves key order' => sub {
    my $val = file_json_decode(q|{"z":1,"a":2,"m":3}|, ordered => 1);
    is_deeply([keys %$val], [qw(z a m)], 'keys in document order');
    is(ref(tied(%$val)), 'Tie::OrderedHash', 'tied to Tie::OrderedHash');
};

subtest 'relaxed => 1 tolerates comments + trailing commas' => sub {
    my $val = file_json_decode(
        qq|{\n  // a comment\n  "a": 1,\n  "b": 2,\n}|,
        relaxed => 1,
    );
    is($val->{a}, 1, 'relaxed decode handles comment');
    is($val->{b}, 2, 'relaxed decode handles trailing comma');
};

subtest 'undef bytes -> undef result' => sub {
    is(file_json_decode(undef), undef, 'undef in -> undef out');
};

subtest 'odd-count options croaks' => sub {
    eval { file_json_decode('{}', 'lonely') };
    like($@, qr/odd number of options/i, 'decode: odd-count croaks');

    eval { file_json_encode({}, 'lonely') };
    like($@, qr/odd number of options/i, 'encode: odd-count croaks');
};

subtest 'unknown option croaks' => sub {
    eval { file_json_decode('{}', not_a_real_option => 1) };
    like($@, qr/unknown option/i, 'decode: unknown option croaks');
};

subtest 'matches plugin path output' => sub {
    use File::Raw;
    use File::Temp qw(tempfile);
    my ($fh, $path) = tempfile(UNLINK => 1);
    close $fh;

    my $value = { a => 1, b => [1,2,3], c => { nested => 'hi' } };
    my $direct = file_json_encode($value, sort_keys => 1);
    File::Raw::spew($path, $value, plugin => 'json', sort_keys => 1);
    my $via_plugin = File::Raw::slurp($path);
    is($direct, $via_plugin,
       'file_json_encode output matches spew(plugin=>json) output');

    my $back_direct  = file_json_decode($direct);
    my $back_plugin  = File::Raw::slurp($path, plugin => 'json');
    is_deeply($back_direct, $back_plugin,
              'decoded structures from both paths are equal');
};

done_testing;
