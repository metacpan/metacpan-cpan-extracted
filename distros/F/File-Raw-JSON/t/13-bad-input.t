#!/usr/bin/perl
use strict;
use warnings;
use Test::More;
use File::Raw;
use File::Raw::JSON;
use File::Temp qw(tempdir);

my $dir = tempdir(CLEANUP => 1);
my $f   = "$dir/b.json";

# Malformed input croaks with byte offset
File::Raw::spew($f, '{"a":1');
eval { File::Raw::slurp($f, plugin => 'json') };
like($@, qr/byte offset/, 'truncated object: error names byte offset');

File::Raw::spew($f, '{"a":}');
eval { File::Raw::slurp($f, plugin => 'json') };
ok($@, 'missing value croaks');

File::Raw::spew($f, 'not json');
eval { File::Raw::slurp($f, plugin => 'json') };
ok($@, 'plain text croaks');

# Unknown option key
File::Raw::spew($f, '{}');
eval { File::Raw::slurp($f, plugin => 'json', bogus_key => 1) };
like($@, qr/unknown option/, 'unknown option rejected');

# Bad mode
eval { File::Raw::slurp($f, plugin => 'json', mode => 'sideways') };
like($@, qr/mode must be/, 'unknown mode rejected');

# allow_nonref => 0 rejects bare scalar
File::Raw::spew($f, '42');
eval { File::Raw::slurp($f, plugin => 'json', allow_nonref => 0) };
like($@, qr/not an object\/array/, 'allow_nonref=>0 rejects bare scalar');

# Unknown plugin
File::Raw::spew($f, '{}');
eval { File::Raw::slurp($f, plugin => 'no_such_plugin') };
like($@, qr/unknown plugin/, 'unknown plugin caught at File::Raw layer');

# Truncated JSONL value
my $jl = "$dir/t.jsonl";
File::Raw::spew($jl, qq({"a":1}\n{"b":));
eval { File::Raw::slurp($jl, plugin => 'jsonl') };
like($@, qr/truncated/, 'truncated JSONL value caught');

done_testing;
