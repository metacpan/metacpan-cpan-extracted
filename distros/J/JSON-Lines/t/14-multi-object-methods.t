use Test::More;
use File::Temp qw(tempfile);

use JSON::Lines;

my $jsonl = JSON::Lines->new(canonical => 1);

# Create a temp file with multiple objects per line
my ($fh, $filename) = tempfile(UNLINK => 1);
print $fh qq|{"id":1}{"id":2}\n|;
print $fh qq|{"id":3}\n|;
print $fh qq|{"id":4}{"id":5}{"id":6}\n|;
close $fh;

subtest 'get_line with multi-object lines' => sub {
	open my $rfh, '<', $filename or die $!;
	my @objects;
	while (my $obj = $jsonl->get_line($rfh)) {
		push @objects, $obj;
	}
	close $rfh;

	is(scalar @objects, 6, 'got all 6 objects');
	is_deeply($objects[0], { id => 1 }, 'first object');
	is_deeply($objects[1], { id => 2 }, 'second object (same line as first)');
	is_deeply($objects[2], { id => 3 }, 'third object (own line)');
	is_deeply($objects[5], { id => 6 }, 'last object');
};

subtest 'get_line_at with multi-object lines' => sub {
	open my $rfh, '<', $filename or die $!;

	# Line 0 has {"id":1}{"id":2}
	my $obj0_0 = $jsonl->get_line_at($rfh, '0:0', 1);  # seek to start
	is_deeply($obj0_0, { id => 1 }, 'object at line 0, offset 0');

	my $obj0_1 = $jsonl->get_line_at($rfh, '0:1');
	is_deeply($obj0_1, { id => 2 }, 'object at line 0, offset 1');

	# Line 1 has {"id":3} (single object, can use plain index)
	my $obj1 = $jsonl->get_line_at($rfh, 1);
	is_deeply($obj1, { id => 3 }, 'object at line 1 (plain index)');

	# Line 2 has {"id":4}{"id":5}{"id":6}
	my $obj2_0 = $jsonl->get_line_at($rfh, '2:0');
	is_deeply($obj2_0, { id => 4 }, 'object at line 2, offset 0');

	my $obj2_2 = $jsonl->get_line_at($rfh, '2:2');
	is_deeply($obj2_2, { id => 6 }, 'object at line 2, offset 2');

	# Go back to earlier line
	my $obj0_0_again = $jsonl->get_line_at($rfh, '0:0', 1);  # seek to start
	is_deeply($obj0_0_again, { id => 1 }, 'object at 0:0 after seek');

	close $rfh;
};

subtest 'get_subset with multi-object lines' => sub {
	my $subset = $jsonl->get_subset($filename, 1, 3);

	is(scalar @$subset, 3, 'got 3 objects in subset');
	is_deeply($subset->[0], { id => 2 }, 'first in subset');
	is_deeply($subset->[1], { id => 3 }, 'second in subset');
	is_deeply($subset->[2], { id => 4 }, 'third in subset');
};

subtest 'group_lines with multi-object lines' => sub {
	# Create a temp file with groupable data on multi-object lines
	my ($gfh, $gfilename) = tempfile(UNLINK => 1);
	# Line 0: two objects (type a at 0:0, type b at 0:1)
	print $gfh qq|{"type":"a","val":1}{"type":"b","val":2}\n|;
	# Line 1: one object (type a, plain index 1)
	print $gfh qq|{"type":"a","val":3}\n|;
	# Line 2: two objects (type b at 2:0, type a at 2:1)
	print $gfh qq|{"type":"b","val":4}{"type":"a","val":5}\n|;
	close $gfh;

	open my $rfh, '<', $gfilename or die $!;
	my $groups = $jsonl->group_lines($rfh, 'type');
	close $rfh;

	# Group "a": line 0 offset 0, line 1 (single), line 2 offset 1
	is_deeply($groups->{a}, ['0:0', 1, '2:1'], 'group "a" has correct indices');
	# Group "b": line 0 offset 1, line 2 offset 0
	is_deeply($groups->{b}, ['0:1', '2:0'], 'group "b" has correct indices');
};

subtest 'group_lines with coderef' => sub {
	my ($gfh, $gfilename) = tempfile(UNLINK => 1);
	# Line 0: two objects (cat x at 0:0, cat y at 0:1)
	print $gfh qq|{"n":{"cat":"x"}}{"n":{"cat":"y"}}\n|;
	# Line 1: one object (cat x, plain index 1)
	print $gfh qq|{"n":{"cat":"x"}}\n|;
	close $gfh;

	open my $rfh, '<', $gfilename or die $!;
	my $groups = $jsonl->group_lines($rfh, sub { $_->{n}{cat} });
	close $rfh;

	is_deeply($groups->{x}, ['0:0', 1], 'nested group "x"');
	is_deeply($groups->{y}, ['0:1'], 'nested group "y"');
};

subtest 'group_lines indices work with get_line_at' => sub {
	my ($gfh, $gfilename) = tempfile(UNLINK => 1);
	print $gfh qq|{"type":"a","val":1}{"type":"b","val":2}\n|;
	print $gfh qq|{"type":"a","val":3}\n|;
	print $gfh qq|{"type":"b","val":4}{"type":"a","val":5}\n|;
	close $gfh;

	# Get groups
	open my $rfh, '<', $gfilename or die $!;
	my $groups = $jsonl->group_lines($rfh, 'type');
	close $rfh;

	# Use group indices with get_line_at
	open $rfh, '<', $gfilename or die $!;
	my @group_a_objects;
	for my $idx (@{$groups->{a}}) {
		push @group_a_objects, $jsonl->get_line_at($rfh, $idx, !@group_a_objects);
	}
	close $rfh;

	is(scalar @group_a_objects, 3, 'retrieved 3 objects from group a');
	is_deeply($group_a_objects[0], { type => 'a', val => 1 }, 'first group a object');
	is_deeply($group_a_objects[1], { type => 'a', val => 3 }, 'second group a object');
	is_deeply($group_a_objects[2], { type => 'a', val => 5 }, 'third group a object');
};

done_testing();
