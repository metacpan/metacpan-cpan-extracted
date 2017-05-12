#!/usr/bin/perl -T

# Note: Some attributes are supposed to have their values normalised when
# accessed through the DOM 0 interface. For this reason, some attributes,
# particularly ‘align’, have weird capitalisations of their values when
# they are set. This is intentional.

use strict; use warnings; use lib 't';
our $tests;
BEGIN { ++$INC{'tests.pm'} }
sub tests'VERSION { $tests += pop };
use Test::More;
plan tests => $tests;

use HTML::DOM;
my $doc = new HTML::DOM;

# Each call to test_attr or test_event runs 3 tests.

sub test_attr {
	my ($obj, $attr, $val, $new_val) = @_;
	my $attr_name = (ref($obj) =~ /[^:]+\z/g)[0] . "'s $attr";

	# I get the attribute first before setting it, because at one point
	# I had it setting it to undef with no arg.
	is $obj->$attr,          $val,     "get $attr_name";
	is $obj->$attr($new_val),$val, "set/get $attr_name";
	is $obj->$attr,$new_val,     ,     "get $attr_name again";
}

# A useful value for testing boolean attributes:
{package false; use overload 'bool' => sub {0}, '""'=>sub{"oenuueo"};}
my $false = bless [], 'false';

# -------------------------#
use tests 87; # HTMLTableElement
{
	is ref(
		my $table = $doc->createElement('table'),
	), 'HTML::DOM::Element::Table',
		"class for table";

	is +()=$table->caption, 0, 'table->caption returns null';
	is +()=$table->tHead, 0, 'table->thead returns null';
	is +()=$table->tFoot, 0, 'table->tfoot returns null';
	isa_ok my $rows = $table->rows, 'HTML::DOM::Collection',
		'table->rows';
	isa_ok my $tbs = $table->tBodies, 'HTML::DOM::Collection',
		'table->tBodies';
	is +()=$table->rows, 0, '()=table->rows returns nothing';
	is +()=$table->tBodies, 0, '()=table->tBodies returns nothing';
	$table->appendChild(my $tbody = $doc->createElement('tbody'));
	is $#$tbs, 0, 'number of tbodies';
	is $tbs->[0], $tbody, 'contents of table->tBodies';
	$tbody->appendChild(my $row = $doc->createElement('tr'));
	is $#$rows, 0, 'number of rows';
	is $rows->[0], $row, 'contents of table->rows';

	# make sure caption tHead etc. are not recrusive:
	$row->appendChild(my $cell = $doc->createElement('td'));
	$cell->appendChild(my $subt=$doc->createElement('table'));
	$subt->push_content(
		map $doc->createElement($_), 'caption', 'thead', 'tfoot'
	);

	is $table->caption, undef, 'table->caption is not recursive';
	is $table->tHead, undef, 'table->tHead is not recursive';
	is $table->tFoot, undef, 'table->tFoot is not recursive';
	is $table->tBodies->length, 1, 'table->tBodies is not recursiev';
	is $rows->length, 1, 'table->rows is not recursive';

	ok !eval{$table->caption($doc->createElement('a'));1},
		'caption dies when set to a non-caption element';
	cmp_ok $@, '==', HTML::DOM::Exception::HIERARCHY_REQUEST_ERR,
		'caption throws the right error';
	$table->caption(my $captain = $doc->createElement('caption'));	
	is +($table->content_list)[0], $captain,
		'setting table->caption adds the element below the table';
	test_attr $table, caption => $captain,
		$doc->createElement('caption');

	ok !eval{$table->tHead($doc->createElement('a'));1},
		'tHead dies when set to a non-caption element';
	cmp_ok $@, '==', HTML::DOM::Exception::HIERARCHY_REQUEST_ERR,
		'tHead throws the right error';
	$table->tHead(my $th = $doc->createElement('thead'));	
	is +($table->content_list)[1], $th,
		'setting table->tHead adds the element below the table';
	test_attr $table, tHead => $th,
		$doc->createElement('thead');

	ok !eval{$table->tFoot($doc->createElement('a'));1},
		'tFoot dies when set to a non-caption element';
	cmp_ok $@, '==', HTML::DOM::Exception::HIERARCHY_REQUEST_ERR,
		'tFoot throws the right error';
	$table->tFoot(my $tf = $doc->createElement('tfoot'));	
	is +($table->content_list)[2], $tf,
		'setting table->tFoot adds the element below the table';
	test_attr $table, tFoot => $tf,
		$doc->createElement('tfoot');

	$table->attr(align => 'LEft');
	$table->attr(bgcolor => 'red');
	$table->attr(border => '2');
	$table->attr(cellpadding => '3');
	$table->attr(cellspacing => '4');
	$table->attr(frame => '5');
	$table->attr(rules => 'noNe');
	$table->attr(summary => 'left');
	$table->attr(width => '80');
	
	test_attr $table, qw/align left right /;
	test_attr $table, qw/bgColor red blue /;
	test_attr $table, qw/border 2 20 /;
	test_attr $table, qw/cellPadding 3 30 /;
	test_attr $table, qw/cellSpacing 4 40 /;
	test_attr $table, qw/frame 5 50 /;
	test_attr $table, qw/rules none lots /;
	test_attr $table, qw/summary left still-here /;
	test_attr $table, qw/width 80 800 /;

	is $table->createTHead, $table->tHead,
		'createTHead returns the existing thead';
	is $table->createTFoot, $table->tFoot,
		'createTFoot returns the existing foot';
	is $table->createCaption, $table->caption,
		'createCaption returns the existing caption';

	is +()=$table->deleteTHead, 0, 'return val of table->deleteTHead';
	is +()=$table->deleteTFoot, 0, 'return val of table->deleteTFoot';
	is +()=$table->deleteCaption, 0, 'retval of table->deleteCaption';

	is $table->tHead, undef, 'result of table->deleteTHead';
	is $table->tFoot, undef, 'result of table->deleteTFoot';
	is $table->caption, undef, 'result of table->deleteCaption';
	
	is $table->createTHead, $table->childNodes->[0],
		'createTHead creates and returns a new table header';
	is $table->createTFoot, $table->childNodes->[1],
		'createTFoot creates and returns a new table footer';
	is $table->createCaption, $table->childNodes->[0],
		'createCaption creates and returns a new table caption';

	isa_ok $row = $table->insertRow(0), 'HTML::DOM::Element::TR',
		'table->insertRow(0)';
	is $row, $rows->[0], 'result of insertRow(0)';
	is $table->insertRow(1), $rows->[1], 'result of insertRow(1)';
	is @$rows, 3, 'number of rows after insertRow';
	
	my $last_row = $rows->[-1];
	is +()=$table->deleteRow(1), 0, 'retval of table->deleteRow';
	is_deeply \@$rows, [$row,$last_row],
		'effect of table->deleteRow';

	(my $doc = new HTML::DOM)->write('
		<table><tbody><tr><tbody><tr></table>
	'); $doc->close;
	my $new_table = $doc->getElementsByTagName('table')->[0];
	$row = $new_table->insertRow(1);
	is $new_table->tBodies->[1]->childNodes->[0], $row,
	    'insertRow inserts in the same section as the following row';
	is $new_table->insertRow(-1), $new_table->rows->[-1],
		'insertRow(-1)';
	is $new_table->insertRow($new_table->rows->length),
		$new_table->rows->[-1], 'insertRow(number of rows)';
	ok !eval{$new_table->insertRow(-2);1},
		'insertRow(negative number less than -1)';
	cmp_ok $@, '==', HTML::DOM::Exception::INDEX_SIZE_ERR,
		'insertRow with neg num too small throws the right error';
	ok !eval{$new_table->insertRow(328);1},
		'insertRow(beeg number)';
	cmp_ok $@, '==', HTML::DOM::Exception::INDEX_SIZE_ERR,
		'insertRow with big number throws the right error';
}

# -------------------------#
use tests 4; # HTMLTableCaptionElement
{
	is ref(
		my $elem = $doc->createElement('caption'),
	), 'HTML::DOM::Element::Caption',
		"class for caption";

	$elem->attr(align => 'lEft');
	test_attr $elem, qw/align left right /;
}

# -------------------------#
use tests 20; # HTMLTableColElement
{
	my $elem;
	is ref(
		$elem = $doc->createElement($_),
	), 'HTML::DOM::Element::TableColumn',
		"class for $_" for qw/ col colgroup /;

	$elem->attr(align => 'LeFt');
	$elem->attr(char => '.');
	$elem->attr(charoff => '8');
	$elem->attr(span => '9');
	$elem->attr(vAlign => 'toP');
	$elem->attr(width => '10');
	no warnings 'qw';
	test_attr $elem, qw/align left right /;
	test_attr $elem, qw/ch . , /;
	test_attr $elem, qw/chOff 8 80 /;
	test_attr $elem, qw/span 9 90 /;
	test_attr $elem, qw/vAlign top bottom /;
	test_attr $elem, qw/width 10 100 /;
}

# -------------------------#
use tests 32; # HTMLTableSectionElement
{
	my $elem;
	is ref(
		$elem = $doc->createElement($_),
	), 'HTML::DOM::Element::TableSection',
		"class for $_" for qw/ thead tbody tfoot /;

	$elem->attr(align => 'LefT');
	$elem->attr(char => '.');
	$elem->attr(charoff => '8');
	$elem->attr(vAlign => 'tOp');
	no warnings 'qw';
	test_attr $elem, qw/align left right /;
	test_attr $elem, qw/ch . , /;
	test_attr $elem, qw/chOff 8 80 /;
	test_attr $elem, qw/vAlign top bottom /;

	isa_ok my $rows = $elem->rows, 'HTML::DOM::Collection',
		'table section ->rows';
	is +()=$elem->rows, 0,'table section ->rows returning null';
	$elem->appendChild(my $row = $doc->createElement('tr'));
	is @$rows, 1, 'number of rows in table section when there is one';
	is join('',$elem->rows), $row,
	    'table section ->rows in list context when there is one row';
	$row->appendChild(my $cell = $doc->createElement('td'));
	$cell->appendChild(my $subt = $doc->createElement('table'));
	$subt->insertRow();
	is @$rows, 1, 'table section ->rows is not recursive';

	isa_ok $row = $elem->insertRow(0), 'HTML::DOM::Element::TR',
		'table section ->insertRow';
	is $row, $rows->[0], 'result of table section ->insertRow(0)';
	is $elem->insertRow(1), $rows->[1],
		'result of table section ->insertRow(1)';
	is @$rows, 3, 'number of rows after table section ->insertRow';
	
	my $last_row = $rows->[-1];
	is +()=$elem->deleteRow(1), 0, 'retval of table sect ->deleteRow';
	is_deeply \@$rows, [$row,$last_row],
		'effect of table section ->deleteRow';

	(my $doc = new HTML::DOM)->write('
		<table><tbody><tr><tr></table>
	'); $doc->close;
	$elem =$doc->getElementsByTagName('table')->[0]->firstChild;
	is $elem->insertRow(-1), $elem->rows->[-1],
		'table section ->insertRow(-1)';
	is $elem->insertRow($elem->rows->length),
		$elem->rows->[-1],
		'table section ->insertRow(no. of rows)';
	ok !eval{$elem->insertRow(-2);1},
		'table section ->insertRow(negative number less than -1)';
	cmp_ok $@, '==', HTML::DOM::Exception::INDEX_SIZE_ERR,
		'table section ->insertRow(neg) throws the right error';
	ok !eval{$elem->insertRow(328);1},
		'table section ->insertRow(beeg number)';
	cmp_ok $@, '==', HTML::DOM::Exception::INDEX_SIZE_ERR,
	   'table section ->insertRow(big number) throws the right error';
}

# -------------------------#
use tests 36; # HTMLTableRowElement
{
	is ref(
		my $row = $doc->createElement('tr'),
	), 'HTML::DOM::Element::TR',
		"class for tr";

	my $table = $doc->createElement('table');
	$table->appendChild(my $tb = $doc->createElement('tbody'));
	$tb->insertRow;
	$table->appendChild($tb = $doc->createElement('tbody'));
	$tb->appendChild($row);

	is $row->rowIndex, 1, 'rowIndex';
	is $row->sectionRowIndex, 0, 'sectionRowIndex';

	isa_ok my $cells = $row->cells, 'HTML::DOM::Collection',
		'cells';
	is +()=$row->cells, 0,'cells returning null';
	$row->appendChild(my $cell = $doc->createElement('th'));
	is @$cells, 1, 'number of cells when there is one';
	is join('',$row->cells), $cell,
	    'cels in list context when there is one row';
	$cell->appendChild(my $subt = $doc->createElement('table'));
	$subt->insertRow()->appendChild($doc->createElement('td'));
	is @$cells, 1, 'cells is not recursive';

	$row->attr(align => 'LEFt');
	$row->attr(bgcolor => 'red');
	$row->attr(char => '.');
	$row->attr(charoff => '8');
	$row->attr(vAlign => 'Top');
	no warnings 'qw';
	test_attr $row, qw/align left right /;
	test_attr $row, qw/bgColor red green /;
	test_attr $row, qw/ch . , /;
	test_attr $row, qw/chOff 8 80 /;
	test_attr $row, qw/vAlign top bottom /;

	isa_ok $cell = $row->insertCell(0),
		'HTML::DOM::Element::TableCell',
		'insertCell';
	is $cell->tag, 'td', 'tag of cell inserted by insertCell';
	is $cell, $cells->[0], 'result of insertCell(0)';
	is $row->insertCell(1), $cells->[1],
		'result of insertCell(1)';
	is @$cells, 3, 'number of cells after insertCell';
	
	my $last_cell = $cells->[-1];
	is +()=$row->deleteCell(1), 0, 'retval of deleteCell';
	is_deeply \@$cells, [$cell,$last_cell],
		'effect of deleteCell';

	is $row->insertCell(-1), $cells->[-1],
		'insertCell(-1)';
	is $row->insertCell($cells->length),
		$cells->[-1],
		'insertCell(no. of rows)';
	ok !eval{$row->insertCell(-2);1},
		'insertCell(negative number less than -1)';
	cmp_ok $@, '==', HTML::DOM::Exception::INDEX_SIZE_ERR,
		'insertCell(neg) throws the right error';
	ok !eval{$row->insertCell(328);1},
		'insertCell(beeg number)';
	cmp_ok $@, '==', HTML::DOM::Exception::INDEX_SIZE_ERR,
	   'insertCell(big number) throws the right error';
}

# -------------------------#
use tests 47; # HTMLTableCellElement
{
	my $cell;
	is ref(
		$cell = $doc->createElement($_),
	), 'HTML::DOM::Element::TableCell',
		"class for $_" for 'td', 'th';

	my $row = $doc->createElement('tr');
	$row->appendChild($cell);
	is $cell->cellIndex, 0, 'cellIndex';

	$cell->attr(abbr => 'evi');
	$cell->attr(align => 'lEfT');
	$cell->attr(axis => 'allies');
	$cell->attr(bgcolor => 'red');
	$cell->attr(char => '.');
	$cell->attr(charoff => '8');
	$cell->attr(colspan => '9');
	$cell->attr(headers => '9');
	$cell->attr(height => '10');
	$cell->attr(nowrap => '10');
	$cell->attr(rowspan => '11');
	$cell->attr(scope => 'roW');
	$cell->attr(vAlign => 'TOp');
	$cell->attr(width => '12');
	no warnings 'qw';
	test_attr $cell, qw/abbr evi ation /;
	test_attr $cell, qw/align left right /;
	test_attr $cell, qw/axis allies whatevere /;
	test_attr $cell, qw/bgColor red green /;
	test_attr $cell, qw/ch . , /;
	test_attr $cell, qw/chOff 8 80 /;
	test_attr $cell, qw/colSpan 9 90 /;
	test_attr $cell, qw/headers 9 23322323puuoeoeeo /;
	test_attr $cell, qw/height 10 1100 /;
	ok $cell->noWrap             ,      'get TableCell’s noWrap';
	ok $cell->noWrap(0),         ,  'set/get TableCell’s noWrap';
	ok!$cell->noWrap             ,      'get TableCell’s noWrap again';
	test_attr $cell, qw/rowSpan 11 110 /;
	test_attr $cell, qw/scope row col /;
	test_attr $cell, qw/vAlign top bottom /;
	test_attr $cell, qw/width 12 234 /;

	$cell->noWrap(1);
	is $cell->getAttribute('nowrap'), 'nowrap',
	 'table cell’s nowrap is set to "nowrap" when true';
	$cell->noWrap($false);
	is $cell->attr('nowrap'), undef,
	 'table cell’s nowrap is deleted when set to false';

}
