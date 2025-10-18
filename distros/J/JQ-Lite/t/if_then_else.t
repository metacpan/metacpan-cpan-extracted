use strict;
use warnings;
use Test::More;
use JQ::Lite;

my $jq = JQ::Lite->new;

my $student = q({"name":"Alice","score":85});
my @passed = $jq->run_query($student, 'if .score >= 70 then .name else "retry" end');
is_deeply(\@passed, ['Alice'], 'if/then/else emits the true branch when condition is truthy');

my @failed = $jq->run_query($student, 'if .score > 100 then .score else "retry" end');
is_deeply(\@failed, ['retry'], 'if/then/else falls back to else when condition is falsey');

my @no_else = $jq->run_query($student, 'if .score > 100 then .score end');
ok(!@no_else, 'if/then end without else produces no results when condition is false');

my $second = q({"name":"Bob","score":55});
my @graded = $jq->run_query($second, 'if .score >= 70 then "A" elif .score >= 60 then "B" elif .score >= 50 then "C" else "D" end');
is_deeply(\@graded, ['C'], 'elif clauses cascade until one succeeds');

my @nested = $jq->run_query($student, 'if .score >= 70 then if .score > 90 then "A" else "B" end else "C" end');
is_deeply(\@nested, ['B'], 'nested if expressions are parsed recursively');

done_testing;
