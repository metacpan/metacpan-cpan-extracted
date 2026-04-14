use strict;
use warnings;
use Test::More;

use Enum::Declare::Common::Color;

subtest 'primary colors' => sub {
	is(Red,   '#ff0000', 'Red');
	is(Green, '#008000', 'Green');
	is(Blue,  '#0000ff', 'Blue');
};

subtest 'common web colors' => sub {
	is(White,  '#ffffff', 'White');
	is(Black,  '#000000', 'Black');
	is(Gray,   '#808080', 'Gray');
	is(Yellow, '#ffff00', 'Yellow');
	is(Orange, '#ffa500', 'Orange');
	is(Purple, '#800080', 'Purple');
	is(Teal,   '#008080', 'Teal');
	is(Navy,   '#000080', 'Navy');
	is(Coral,  '#ff7f50', 'Coral');
};

subtest 'extended colors' => sub {
	is(Tomato,        '#ff6347', 'Tomato');
	is(SteelBlue,     '#4682b4', 'SteelBlue');
	is(RebeccaPurple, '#663399', 'RebeccaPurple');
	is(MintCream,     '#f5fffa', 'MintCream');
	is(Salmon,        '#fa8072', 'Salmon');
};

subtest 'meta accessor' => sub {
	my $meta = CSS();
	ok($meta->valid('#ff0000'), '#ff0000 is valid');
	ok(!$meta->valid('#123456'), '#123456 is not valid');
	is($meta->name('#0000ff'), 'Blue', 'name of #0000ff is Blue');
	ok($meta->count >= 140, 'at least 140 CSS colors');
};

done_testing;
