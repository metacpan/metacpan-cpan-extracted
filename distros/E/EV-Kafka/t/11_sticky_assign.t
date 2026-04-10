use strict;
use warnings;
use Test::More;
use EV::Kafka;

plan tests => 12;

my $k = EV::Kafka->new(on_error => sub {});

# seed metadata: 2 topics, 3 partitions each
$k->{cfg}{meta} = {
    topics => [
        { name => 'a', partitions => [map {{ partition => $_, leader => 0 }} 0..2] },
        { name => 'b', partitions => [map {{ partition => $_, leader => 0 }} 0..2] },
    ],
};

# --- first assignment: 2 members, 6 partitions -> 3 each ---
my $members = [{ member_id => 'x' }, { member_id => 'y' }];
my $a1 = $k->_assign_partitions($members, ['a', 'b']);
is scalar @$a1, 2, 'first: 2 assignments';

# decode and count
my %counts1;
for my $a (@$a1) {
    my $data = $a->{assignment};
    my $off = 2; # skip version
    my $tc = unpack('N', substr($data, $off, 4)); $off += 4;
    my $total = 0;
    for (1..$tc) {
        my $tlen = unpack('n', substr($data, $off, 2)); $off += 2;
        $off += $tlen;
        my $pc = unpack('N', substr($data, $off, 4)); $off += 4;
        $total += $pc;
        $off += $pc * 4;
    }
    $counts1{$a->{member_id}} = $total;
}
is $counts1{x}, 3, 'first: member x gets 3 partitions';
is $counts1{y}, 3, 'first: member y gets 3 partitions';

# --- second assignment after rebalance: 3 members ---
# sticky: x and y should keep their partitions, z gets redistribution
my $members2 = [{ member_id => 'x' }, { member_id => 'y' }, { member_id => 'z' }];
my $a2 = $k->_assign_partitions($members2, ['a', 'b']);
is scalar @$a2, 3, 'second: 3 assignments';

my %counts2;
for my $a (@$a2) {
    my $data = $a->{assignment};
    my $off = 2;
    my $tc = unpack('N', substr($data, $off, 4)); $off += 4;
    my $total = 0;
    for (1..$tc) {
        my $tlen = unpack('n', substr($data, $off, 2)); $off += 2;
        $off += $tlen;
        my $pc = unpack('N', substr($data, $off, 4)); $off += 4;
        $total += $pc;
        $off += $pc * 4;
    }
    $counts2{$a->{member_id}} = $total;
}
is $counts2{x} + $counts2{y} + $counts2{z}, 6, 'second: total 6 partitions';
ok $counts2{z} >= 1, 'second: new member z gets at least 1 partition';
ok $counts2{x} <= 3, 'second: x gives up some partitions';

# --- member leaves: back to 2 members, sticky keeps assignments ---
my $a3 = $k->_assign_partitions($members, ['a', 'b']);
is scalar @$a3, 2, 'third: 2 assignments';

my %counts3;
for my $a (@$a3) {
    my $data = $a->{assignment};
    my $off = 2;
    my $tc = unpack('N', substr($data, $off, 4)); $off += 4;
    my $total = 0;
    for (1..$tc) {
        my $tlen = unpack('n', substr($data, $off, 2)); $off += 2;
        $off += $tlen;
        my $pc = unpack('N', substr($data, $off, 4)); $off += 4;
        $total += $pc;
        $off += $pc * 4;
    }
    $counts3{$a->{member_id}} = $total;
}
is $counts3{x} + $counts3{y}, 6, 'third: total 6';
is $counts3{x}, 3, 'third: balanced 3 each';
is $counts3{y}, 3, 'third: balanced 3 each';

# --- single member ---
my $a4 = $k->_assign_partitions([{ member_id => 'solo' }], ['a', 'b']);
is scalar @$a4, 1, 'solo gets all 6';
