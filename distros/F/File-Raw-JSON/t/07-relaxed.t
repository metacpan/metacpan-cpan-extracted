#!/usr/bin/perl
use strict;
use warnings;
use Test::More;
use File::Raw;
use File::Raw::JSON;
use File::Temp qw(tempdir);

my $dir = tempdir(CLEANUP => 1);

sub _slurp {
    my ($json, %opts) = @_;
    my $f = "$dir/r.json";
    File::Raw::spew($f, $json);
    return File::Raw::slurp($f, plugin => 'json', %opts);
}

# Trailing comma: strict rejects, relaxed accepts.
eval { _slurp('{"a":1,}'); };
ok($@, 'strict rejects trailing comma in object');

is_deeply(_slurp('{"a":1,}', relaxed => 1), {a => 1},
          'relaxed accepts trailing comma in object');

is_deeply(_slurp('[1,2,3,]', relaxed => 1), [1,2,3],
          'relaxed accepts trailing comma in array');

# Comments: strict rejects, relaxed accepts.
eval { _slurp("// hi\n{\"a\":1}"); };
ok($@, 'strict rejects line comment');

is_deeply(_slurp("// hi\n{\"a\":1}", relaxed => 1), {a => 1},
          'relaxed accepts // line comment');

is_deeply(_slurp("/* block */ {\"a\":1}", relaxed => 1), {a => 1},
          'relaxed accepts /* */ block comment');

done_testing;
