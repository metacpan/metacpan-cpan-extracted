#!/usr/bin/perl -T
use lib '.';
use t::lib tests => 27;

##################################################
# Short tests based on mklol

sub mklol {
	HTML::Element->new_from_lol(
		['html',
		 ['head',
		  [ 'title', 'I like stuff!' ]],
		 ['body', {id => 'corpus'}, {'lang', 'en-JP'},
		  'stuff',
		  ['p', 'um, p < 4!', {'class' => 'par123'}],
		  ['div', {foo => 'bar'}, '123'],
		  ['div', {jack => 'olantern'}, '456']]]);
}

my $tree_replaced = \'<html><head><title>I like stuff!</title></head><body id="corpus" lang="en-JP">all gone!</body></html>';
my $tree;

$tree = mklol;
$tree->content_handler(corpus => 'all gone!');
isxml $tree, $tree_replaced, 'content_handler';

$tree = mklol;
$tree->set_child_content(id => 'corpus', 'all gone!');
isxml $tree, $tree_replaced, 'set_child_content';

$tree = mklol;
$tree->look_down('_tag' => 'body')->replace_content('all gone!');
isxml $tree, $tree_replaced, 'replace_content';

$tree = mklol;
my $p = $tree->look_down('_tag' => 'body')->look_down(_tag => 'p');
is $p->sibdex, 1, 'p tag has 1 as its index';

$tree = mklol;
my $div = $tree->look_down('_tag' => 'body')->look_down(_tag => 'p');
my @sibs = $div->siblings;
is $sibs[0], 'stuff', "first sibling is simple text";
is $sibs[2]->tag, 'div', "3rd tag is a div tag";
is scalar @sibs, 4, "4 siblings total";

$tree = mklol;
my $bold = HTML::Element->new('b', id => 'wrapper');
my $w = $tree->look_down(_tag => 'p');
$w->wrap_content($bold);
isxml $w, \'<p class="par123"><b id="wrapper">um, p &lt; 4!</b></p>', 'wrap_content';

##################################################
# Short tests

$tree = mktree 't/html/crunch.html';
$tree->crunch(look_down => [ class => 'imageElement' ], leave => 1);
isxml $tree, 't/html/crunch-exp.html', 'crunch';

$tree = mktree 't/html/defmap.html';
$tree->defmap(smap => {pause => 'arsenal rules'}, $ENV{TEST_VERBOSE});
isxml $tree, 't/html/defmap-exp.html', 'defmap';

$tree = mktree 't/html/fillinform.html';
isxml \($tree->fillinform({state => 'catatonic'})), 't/html/fillinform-exp.html', 'fillinform';

$tree = mktree 't/html/hashmap.html';
$tree->hash_map(
	hash      => {people_id => 888, phone => '444-4444', email => 'm@xml.com'},
	to_attr   => 'sid',
	excluding => ['email']
);
isxml $tree, 't/html/hashmap-exp.html', 'hash_map';

$tree = mktree 't/html/iter.html';
my $li = $tree->look_down(class => 'store_items');
$tree->iter($li, qw/bread butter vodka/);
isxml $tree, 't/html/iter-exp.html', 'iter';

my @list = map { [item => $_] } qw/bread butter beans/;
my $initial_lol = [ note => [ list => [ item => 'sample' ] ] ];
my ($new_lol) = HTML::Element::newchild($initial_lol, list => @list);
my $expected = [note => [list => [item => 'bread'], [item => 'butter'], [item => 'beans']]];
is_deeply $new_lol, $expected, 'newchild unrolling';

$tree = mktree 't/html/highlander2.html';
$tree->passover('under18');
isxml $tree, 't/html/highlander2-passover-exp.html', 'passover';

$tree = mktree 't/html/position.html';
my $found = $tree->look_down(id => 'findme');
my $pos = join ' ', $found->position;
is $pos, '-1 1 0 1 2', 'position';

$tree = mktree 't/html/prune.html';
$tree->prune;
isxml $tree, 't/html/prune-exp.html', 'prune';

##################################################
# Longer tests

$tree = mktree 't/html/dual_iter.html';

$tree->iter2(
	wrapper_data => [
		['the pros' => 'never have to worry about service again'],
		['the cons' => 'upfront extra charge on purchase'],
		['our choice' => 'go with the extended service plan']
	],
	wrapper_proc => sub {
		my ($container) = @_;
		# only keep the last 2 dts and dds
		my @content_list = $container->content_list;
		$container->splice_content(0, @content_list - 2);
	},
	splice       => sub {
		my ($container, @item_elems) = @_;
		$container->unshift_content(@item_elems);
	},
	debug        => $ENV{TEST_VERBOSE},
);

isxml $tree, 't/html/dual_iter-exp.html', 'dual_iter';

###

sub cb {
	my ($data, $tr) = @_;
	$tr->look_down(class => 'first')->replace_content($data->{first});
	$tr->look_down(class => 'last')->replace_content($data->{last});
	$tr->look_down(class => 'option')->replace_content($data->{option});
}

my @cbdata = (
	{first => 'Foo', last => 'Bar', option => 2},
	{first => 'Bar', last => 'Bar', option => 3},
	{first => 'Baz', last => 'Bar', option => 4},
);

$tree = mktree 't/html/itercb.html';
$tree->find('table')->find('tbody')->find('tr')->itercb(\@cbdata, \&cb);
isxml $tree, 't/html/itercb-exp.html', 'itercb';

###

for my $age (qw/5 15 50/) {
	$tree = mktree 't/html/highlander.html';
	$tree->highlander(
		age_dialog => [
			under10 => sub { $_[0] < 10 },
			under18 => sub { $_[0] < 18 },
			welcome => sub { 1 }
		],
		$age
	);
	isxml $tree, "t/html/highlander-$age-exp.html", "highlander for $age";
}

###

sub replace_age {
	my ($branch, $age) = @_;
	$branch->look_down(id => 'age')->replace_content($age);
}

for my $age (qw/5 15 27/) {
	$tree = mktree 't/html/highlander2.html';
	my $if_then = $tree->look_down(id => 'age_dialog')->highlander2(
		cond => [
			under10 => [ sub { $_[0] < 10 }, \&replace_age ],
			under18 => [ sub { $_[0] < 18 }, \&replace_age ],
			welcome => [ sub { 1          }, \&replace_age ]
		],
		cond_arg => [ $age ]
	);

	isxml ($tree, "t/html/highlander2-$age-exp.html", "highlander2 for age $age");
}

###

$tree = mktree 't/html/iter2.html';

$tree->iter2(
	# default wrapper_ld ok
	wrapper_data => [
		[ Programmer => 'one who likes Perl and Seamstress' ],
		[ DBA        => 'one who does business as' ],
		[ Admin      => 'one who plays Tetris all day' ]
	],
	wrapper_proc => sub {
		my ($container) = @_;

		# only keep the last 2 dts and dds
		my @content_list = $container->content_list;
		$container->splice_content(0, @content_list - 2);
	},
	# default item_ld is k00l
	# default item_data is phrEsh
	# default item_proc will do w0rk
	splice       => sub {
		my ($container, @item_elems) = @_;
		$container->unshift_content(@item_elems);
	},

	debug => $ENV{TEST_VERBOSE},
);

isxml $tree, 't/html/iter2-exp.html', 'iter2';

###

my @data = (
	{ clan_name => 'janglers',    clan_id => 12, selected => 1 },
	{ clan_name => 'thugknights', clan_id => 14 },
	{ clan_name => 'cavaliers' ,  clan_id => 13 }
);
$tree = mktree 't/html/unroll_select.html';

$tree->unroll_select(
	select_label     => 'clan_list',
	option_value     => sub { my $row = shift; $row->{clan_id} },
	option_content   => sub { my $row = shift; $row->{clan_name} },
	option_selected  => sub { my $row = shift; $row->{selected} },
	data             => \@data,
	data_iter        => sub { my $data = shift; shift @$data });

isxml $tree, 't/html/unroll_select-exp.html', 'unroll_select';
