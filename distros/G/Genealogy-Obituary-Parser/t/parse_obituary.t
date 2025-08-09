use strict;
use warnings;
use Test::Most;
use Genealogy::Obituary::Parser qw(parse_obituary);

my $text = <<'END';
He is survived by his wife Mary, sons John and David, and grandchildren Sophie, Liam, and Ava.
His parents were George and Helen.
He also leaves behind his sister Claire.
END

my $rel = parse_obituary($text);

# diag(Data::Dumper->new([$rel])->Dump());

cmp_deeply($rel,
	{
		'spouse' => [
			{ 'name' => 'Mary', 'sex' => 'F', 'status' => 'living' }
		], 'parents' => {
			'father' => { 'name' => 'George' },
			'mother' => { 'name' => 'Helen' }
		}, 'children' => [
			{ 'name' => 'John', 'sex' => 'M' },
			{ 'name' => 'David', 'sex' => 'M' }
		], 'grandchildren' => [
			{ 'name' => 'Sophie' },
			{ 'name' => 'Liam' },
			{ 'name' => 'Ava' }
		], 'sisters' => [
			{ 'name' => 'Claire', 'status' => 'living' },
		]
	}
);

done_testing();
