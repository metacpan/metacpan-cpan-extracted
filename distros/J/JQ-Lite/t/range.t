use strict;
use warnings;
use Test::More tests => 4;
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

