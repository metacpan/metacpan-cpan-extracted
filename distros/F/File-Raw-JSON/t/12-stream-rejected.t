#!/usr/bin/perl
use strict;
use warnings;
use Test::More;
use File::Raw;
use File::Raw::JSON;
use File::Temp qw(tempdir);

# each_line($p, $cb, plugin => 'json') must croak with a useful
# message - single-document JSON doesn't decompose into records.

my $dir = tempdir(CLEANUP => 1);
my $f = "$dir/doc.json";
File::Raw::spew($f, '{"a":1}');

eval { File::Raw::each_line($f, sub {}, plugin => 'json') };
like($@, qr/json.*plugin.*does not support streaming/i,
     'json plugin rejects each_line with explanation');
like($@, qr/jsonl/, 'error message mentions jsonl as alternative');

done_testing;
