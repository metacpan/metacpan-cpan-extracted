use strict;
use warnings;
use Test::More tests => 9;
use FindBin;
use lib "$FindBin::Bin/../lib";
use JQ::Lite;

my $jq = JQ::Lite->new;

my @up_sequence = $jq->run_query('null', 'range(5)');
is_deeply(\@up_sequence, [0, 1, 2, 3, 4], 'range(5) emits 0..4');

my @window = $jq->run_query('null', 'range(2; 5)');
is_deeply(\@window, [2, 3, 4], 'range(2; 5) emits values from 2 up to 5 (exclusive)');

my @stepped = $jq->run_query('null', 'range(1; 6; 2)');
is_deeply(\@stepped, [1, 3, 5], 'range(1; 6; 2) honors custom positive steps');

my @descending = $jq->run_query('null', 'range(10; 2; -3)');
is_deeply(\@descending, [10, 7, 4], 'range(10; 2; -3) supports descending ranges');

my $bad_bounds_ok = eval { $jq->run_query('null', 'range("foo")') };
ok(!$bad_bounds_ok && $@ =~ /range\(\): bounds must be numeric/, 'range() rejects non-numeric bounds');

my $bad_step_ok = eval { $jq->run_query('null', 'range(0; 5; "foo")') };
ok(!$bad_step_ok && $@ =~ /range\(\): step must be numeric/, 'range() rejects non-numeric step values');

my $bool_end_ok = eval { $jq->run_query('null', 'range(1; true)') };
ok(!$bool_end_ok && $@ =~ /range\(\): bounds must be numeric/, 'range() rejects boolean bounds');

my $bool_step_ok = eval { $jq->run_query('null', 'range(1; 5; false)') };
ok(!$bool_step_ok && $@ =~ /range\(\): step must be numeric/, 'range() rejects boolean step values');

my $string_number_ok = eval { $jq->run_query('null', 'range("1"; 5)') };
ok(!$string_number_ok && $@ =~ /range\(\): bounds must be numeric/, 'range() does not coerce string numbers');

