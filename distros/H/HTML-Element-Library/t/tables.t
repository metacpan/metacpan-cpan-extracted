#!/usr/bin/perl -T
use lib '.';
use t::lib tests => 9;

my $tree;
sub data () {
	[map { +{name => $_->[0], age => $_->[1], weight => $_->[2]} } (
		[qw/bob 99 99/],
		[qw/bill 12 52/],
		[qw/brian 44 80/],
		[qw/babette 52 124/],
		[qw/bobo 12 120/],
		[qw/bix 43 230/],
	)];
}

sub data2 () {
	{
		'3dig' => [
			['437', 'MS-DOS', 'United States',       '0', '1', '1', '1', '1'],
			['708', 'Arabic (ASMO 708)',             '0', '1', '0', '0', '1'],
			['709', 'Arabic (ASMO 449+ BCON V4)',    '0', '1', '0', '0', '1'],
			['710', 'Arabic (Transparent Arabic)',   '0', '1', '0', '0', '1'],
			['720', 'Arabic (Transparent ASMO)',     '0', '1', '0', '0', '1']],
		'4dig' => [
			['1200', 'Unicode (BMP of ISO 10646)',   '0', '0', '1', '1', '2'],
			['1250', 'Windows 3.1 Eastern European', '1', '0', '1', '1', '1'],
			['1251', 'Windows 3.1 Cyrillic',         '1', '0', '1', '1', '1'],
			['1252', 'Windows 3.1 US (ANSI)',        '1', '0', '1', '1', '1'],
			['1253', 'Windows 3.1 Greek',            '1', '0', '1', '1', '1'],
			['1254', 'Windows 3.1 Turkish',          '1', '0', '1', '1', '1'],
			['1255', 'Hebrew',                       '1', '0', '0', '0', '1'],
			['1256', 'Arabic',                       '1', '0', '0', '0', '1'],
			['1257', 'Baltic',                       '1', '0', '0', '0', '1'],
			['1361', 'Korean (Johab)',               '1', '0', '0', '3', '1']]
	};
}

$tree = mktree 't/html/table.html';

$tree->table(
	gi_table    => 'load_data',
	gi_tr       => 'data_row',
	table_data  => data,
	tr_data     => sub {
		my ($self, $data) = @_;
		shift(@{$data}) ;
	},
	td_data     => sub {
		my ($tr_node, $tr_data) = @_;
		$tr_node->content_handler($_ => $tr_data->{$_}) for qw(name age weight)
	});

isxml $tree, 't/html/table-exp.html', 'table';

###

$tree = mktree 't/html/table-alt.html';

$tree->table(
	gi_table    => 'load_data',
	gi_tr       => ['iterate1', 'iterate2'],
	table_data  => data,
	tr_data     => sub {
		my ($self, $data) = @_;
		shift @{$data};
	},
	td_data     => sub {
		my ($tr_node, $tr_data) = @_;
		$tr_node->content_handler($_ => $tr_data->{$_}) for qw(name age weight)
	});

isxml $tree, 't/html/table-alt-exp.html', 'table (alternating)';

###

my $d = data2;
$tree = mktree 't/html/table2.html';

for my $dataset (keys %$d) {
	my %tbody = ('4dig' => 0, '3dig' => 1);
	$tree->table2 (
		debug => $ENV{TEST_VERBOSE},
		table_data => $d->{$dataset},
		tr_base_id => $dataset,
		tr_ld => sub {
			my $t = shift;
			my $tbody = ($t->look_down('_tag' => 'tbody'))[$tbody{$dataset}];
			my @tbody_child = $tbody->content_list;
			$tbody_child[$_]->detach for (1 .. $#tbody_child) ;
			$tbody->content_list;
		},
		td_proc => sub {
			my ($tr, $data) = @_;
			my @td = $tr->look_down('_tag' => 'td');
			for my $i (0..$#td) {
				#	warn $i;
				$td[$i]->splice_content(0, 1, $data->[$i]);
			}
		}
	);
}

isxml $tree, 't/html/table2-exp.html', 'table2';

###

# a - default table_ld
$tree = mktree 't/html/table2.html';
my $table = HTML::Element::Library::ref_or_ld(
	$tree,
	['_tag' => 'table']
);
isxml $table, 't/html/table2-table_ld-exp.html', 'table2 look_down default';

###

# b - arrayref table_ld
$table = HTML::Element::Library::ref_or_ld(
	$tree,
	[frame => 'hsides', rules => 'groups']
);
isxml $table, 't/html/table2-table_ld-exp.html', 'table2 look_down arrayref';

# c - coderef table_ld
$table = HTML::Element::Library::ref_or_ld(
	$tree,
	sub {
		my ($t) = @_;
		my $caption = $t->look_down('_tag' => 'caption');
		$caption->parent;
	}
);
isxml $table, 't/html/table2-table_ld-exp.html', 'table2 look_down coderef';

###

# a - default table_ld
my @tr = HTML::Element::Library::ref_or_ld(
	$tree,
	['_tag' => 'tr']
);
is (scalar @tr, 16, 'table2 tr look_down (default)');

# b - coderef tr_ld
# removes windows listings before returning @tr

HTML::Element::Library::ref_or_ld(
	$tree,
	sub {
		my ($t) = @_;
		my @trs = $t->look_down('_tag' => 'tr');
		my @keep;
		for my $tr (@trs) {

			my @td = $tr->look_down ('_tag' => 'td') ;
			my $detached;
			for my $td (@td) {
				if (grep { $_ =~ /Windows/ } $td->content_list) {
					$tr->detach;
					++$detached;
					last;
				}
			}
			push @keep, $tr unless $detached;
		}
		@keep;
	}
);
isxml $tree, 't/html/table2-tr_ld-coderef-exp.html', 'table2 tr look_down (coderef)';

# c - arrayref tr_ld

$tree = mktree 't/html/table2-tr_ld-arrayref.html';
my $tr = HTML::Element::Library::ref_or_ld(
	$tree,
	[class => 'findMe']
);
isxml $tr, 't/html/table2-tr_ld-arrayref-exp.html', 'table2 tr look_down (arrayref)';
