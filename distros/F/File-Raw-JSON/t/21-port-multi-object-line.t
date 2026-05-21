#!/usr/bin/perl
use strict;
use warnings;
use Test::More;
use File::Raw;
use File::Raw::JSON;
use File::Temp qw(tempdir);

# Ported from JSON-Lines-1.11/t/13-multi-object-line.t
# Multiple JSON values concatenated on one line (no separators) must
# all decode. This is what `jq -c | tee` produces under streaming.

my $dir = tempdir(CLEANUP => 1);

sub _decode {
    my ($bytes) = @_;
    my $f = "$dir/m.jsonl";
    File::Raw::spew($f, $bytes);
    return File::Raw::slurp($f, plugin => 'jsonl');
}

subtest 'multiple objects on a single line' => sub {
    my $string = q|{"type":"init","id":1}{"type":"message","id":2}{"type":"result","id":3}|;
    my $rows = _decode($string);
    is(scalar @$rows, 3, 'decoded 3 objects from single line');
    is_deeply($rows->[0], { type => 'init',    id => 1 }, 'first');
    is_deeply($rows->[1], { type => 'message', id => 2 }, 'second');
    is_deeply($rows->[2], { type => 'result',  id => 3 }, 'third');
};

subtest 'mixed single- and multi-line' => sub {
    my $string = qq|{"a":1}{"b":2}\n{"c":3}\n{"d":4}{"e":5}|;
    my $rows = _decode($string);
    is(scalar @$rows, 5, 'decoded 5 from mixed input');
    is_deeply($rows, [
        { a => 1 }, { b => 2 }, { c => 3 }, { d => 4 }, { e => 5 },
    ], 'all objects decoded correctly');
};

subtest 'nested objects on a single line' => sub {
    my $string = q|{"outer":{"inner":"value"}}{"list":[1,2,3]}|;
    my $rows = _decode($string);
    is(scalar @$rows, 2, 'two values');
    is_deeply($rows->[0], { outer => { inner => 'value' } }, 'nested object');
    is_deeply($rows->[1], { list  => [1,2,3] },              'nested array');
};

done_testing;
