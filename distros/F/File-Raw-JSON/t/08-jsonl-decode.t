#!/usr/bin/perl
use strict;
use warnings;
use Test::More;
use File::Raw;
use File::Raw::JSON;
use File::Temp qw(tempdir);

my $dir = tempdir(CLEANUP => 1);

sub _slurp_jsonl {
    my ($bytes) = @_;
    my $f = "$dir/jl.txt";
    File::Raw::spew($f, $bytes);
    return File::Raw::slurp($f, plugin => 'jsonl');
}

# Vanilla NDJSON
is_deeply(_slurp_jsonl(qq({"a":1}\n{"b":2}\n{"c":3}\n)),
          [{a=>1},{b=>2},{c=>3}],
          'vanilla NDJSON');

# Without trailing newline
is_deeply(_slurp_jsonl(qq({"a":1}\n{"b":2}\n{"c":3})),
          [{a=>1},{b=>2},{c=>3}],
          'no trailing newline tolerated');

# Empty file
is_deeply(_slurp_jsonl(''), [], 'empty file -> empty AV');

# Whitespace only
is_deeply(_slurp_jsonl("\n\n   \n"), [], 'whitespace-only file -> empty AV');

# Single value
is_deeply(_slurp_jsonl(q({"single":42})), [{single=>42}], 'single value');

# Mix of objects and arrays
is_deeply(_slurp_jsonl(qq([1,2,3]\n{"a":"b"}\n[4,5])),
          [[1,2,3], {a=>'b'}, [4,5]],
          'objects and arrays in same stream');

done_testing;
