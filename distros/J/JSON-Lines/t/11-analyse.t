use Test::More;

use JSON::Lines;

my $jsonl = JSON::Lines->new(
	canonical => 1,
);

my @data = (
	{
		relation_id => 123,
		name => "parent",
		thing => { id => 10, description => "The parent thing" },
	},
	{
		relation_id => 2,
		name => "child",
		thing => { id => 20, description => "The child thing" },
	},
	{
		relation_id => 3,
		name => "sibling",
		thing => { id => 30, description => "The sibling thing" },
	},
	{
		relation_id => 123,
		name => "cousin",
		thing => { id => 40, description => "The cousin thing" },
	},
	{
		relation_id => 123,
		name => "cousin",
		thing => { id => 40, description => "The related thing" },
	},
	{
		relation_id => 2,
		name => "aunt",
		thing => { id => 50, description => "The aunt thing" },
	},
	{
		relation_id => 2,
		name => "uncle",
		thing => { id => 60, description => "The uncle thing" },
	},
	{
		relation_id => 3,
		name => "grandparent",
		thing => { id => 70, description => "The grandparent thing" },
	}
);

my $file = $jsonl->encode_file('analyse.jsonl', @data);
$jsonl->pretty(1);
my $pretty_file = $jsonl->encode_file('pretty_analyse.jsonl', @data);

is($file, 'analyse.jsonl');

open my $fh, '<', $file or die $!;
my $analyse = $jsonl->group_lines($fh, 'relation_id');
my $analyse_two = $jsonl->group_lines($fh, sub { $_->{relation_id} });
close $fh;

is_deeply($analyse, {
	123 => [ 0, 3, 4 ],
	2   => [ 1, 5, 6 ],
	3   => [ 2, 7 ],
});
is_deeply($analyse, $analyse_two);

open my $pfh, '<', $pretty_file or die $!;
my $pretty_analyse = $jsonl->group_lines($pfh, 'relation_id');
my $pretty_analyse_two = $jsonl->group_lines($pfh, sub { $_->{relation_id} });;
close $pfh;

is_deeply($pretty_analyse, $pretty_analyse_two);
is_deeply($pretty_analyse, {
	123 => [
        0,
    	24,
        32
    ],
	2 => [
		8,
		40,
		48
	],
	3 => [
		16,
		56
	]
});


# Test get_line_at - retrieve records by index
open my $fh2, '<', $file or die $!;
my $first = $jsonl->get_line_at($fh2, 0, 1);
is($first->{name}, 'parent', 'get_line_at index 0');

my $third = $jsonl->get_line_at($fh2, 2, 1);
is($third->{name}, 'sibling', 'get_line_at index 2');

my $last = $jsonl->get_line_at($fh2, 7, 1);
is($last->{name}, 'grandparent', 'get_line_at last index');

my $beyond = $jsonl->get_line_at($fh2, 100, 1);
is($beyond, undef, 'get_line_at beyond end returns undef');
close $fh2;

# Test get_line_at with pretty file (multi-line records)
open my $pfh2, '<', $pretty_file or die $!;
my $pretty_first = $jsonl->get_line_at($pfh2, 0, 1);
is($pretty_first->{name}, 'parent', 'get_line_at pretty file index 0');

my $pretty_second = $jsonl->get_line_at($pfh2, 8);
is($pretty_second->{name}, 'child', 'get_line_at pretty file index 8 (second record)');
close $pfh2;

# Test using group_lines indices with get_line_at
open my $fh3, '<', $file or die $!;
my $group_123_indices = $analyse->{123};
my $first_123 = $jsonl->get_line_at($fh3, $group_123_indices->[0], 1);
is($first_123->{relation_id}, 123, 'get_line_at with group_lines index');
is($first_123->{name}, 'parent', 'correct record from group index');
close $fh3;

unlink $file;
unlink $pretty_file;

done_testing();
