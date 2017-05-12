use strict;
use warnings;

use lib '.';

use Test::More;

BEGIN {
    use_ok('HTML::TableContent');
}

my $t = HTML::TableContent->new();

ok(my $table = $t->add_table({}));

ok($table->style('width:100%;'));
ok($table->id('hello'));
ok($table->class('something'));
ok($table->add_style('font-size:10px;'));

my $table_html = '<table class="something" id="hello" style="width:100%; font-size:10px;"></table>';

is($table->render, $table_html, "expected table html");
is($table->class, 'something', "expected class something");
is($table->id, 'hello', "expected id hello");
is($table->style, 'width:100%; font-size:10px;', "expected style tag: width=100%; font-size:10px");

ok(my $row = $table->add_row({ style => 'width:100%;', id => 'first-row', class => 'odd' }));

my $row_html = '<tr class="odd" id="first-row" style="width:100%;"></tr>';
is($row->render, $row_html, "expected row html");
is($row->id, 'first-row', "expected row id: first row");
is($row->class, 'odd', "expected row class: odd");
is($row->style, 'width:100%;', "expected row style: width:100%");

ok(my $cell = $row->add_cell({ style => 'width:33%;', id => 'first-cell', class => 'even', text => 'something' }));

my $cell_html = '<td class="even" id="first-cell" style="width:33%;">something</td>';
is($cell->render, $cell_html, "expected cell html");
is($cell->style, 'width:33%;', "expected cell style");
is($cell->id, 'first-cell', "expected cell id: first-cell");
is($cell->text, 'something', "expected cell text: something");

my $row_with_cell_html = '<tr class="odd" id="first-row" style="width:100%;"><td class="even" id="first-cell" style="width:33%;">something</td></tr>';
is($row->render, $row_with_cell_html, "correct html");

my $basic_table = '<table class="something" id="hello" style="width:100%; font-size:10px;"><tr class="odd" id="first-row" style="width:100%;"><td class="even" id="first-cell" style="width:33%;">something</td></tr></table>';
is($table->render, $basic_table, "correct table html");

ok($cell->add_text('hello'));

my $added_text_table = '<table class="something" id="hello" style="width:100%; font-size:10px;"><tr class="odd" id="first-row" style="width:100%;"><td class="even" id="first-cell" style="width:33%;">something hello</td></tr></table>';
is($table->render, $added_text_table, "added hello to the cell");

ok(my $header = $table->add_header({ style => 'width:100%;', id => 'header', class => 'table-header', text => 'hello' }));

my $header_html = '<th class="table-header" id="header" style="width:100%;">hello</th>';
is($header->render, $header_html, "expected header html");
is($header->id, 'header', "expected header id: first row");
is($header->class, 'table-header', "expected header class: odd");
is($header->style, 'width:100%;', "expected header style: width:100%");

$table->parse_to_column($cell);

is($header->cell_count, 1, "expected cell count");
is($header->cells->[0]->style, 'width:33%;', "expected cell style");
is($header->cells->[0]->id, 'first-cell', "expected cell id: first-cell");
is($header->cells->[0]->text, 'something hello', "expected cell text: something hello");

ok(my $nested = $cell->add_nested({ id => "nested-table-id" }), "okay add nested table to cell");
ok($table->add_to_nested($nested));

ok(my $nrow = $nested->add_row({ id => 'nested-row-id' }));
ok(my $ncell = $nrow->add_cell({ id => 'nested-cell', text => 'some text' }));

my $nested_html = '<table id="nested-table-id"><tr id="nested-row-id"><td id="nested-cell">some text</td></tr></table>';
is($nested->render, $nested_html, "expected nested html");

is($table->count_nested, 1, "correct nested count");

my $nested_table_html = '<table class="something" id="hello" style="width:100%; font-size:10px;"><tr><th class="table-header" id="header" style="width:100%;">hello</th></tr><tr class="odd" id="first-row" style="width:100%;"><td class="even" id="first-cell" style="width:33%;">something hello<table id="nested-table-id"><tr id="nested-row-id"><td id="nested-cell">some text</td></tr></table></td></tr></table>';
is($table->render, $nested_table_html, "final html with nested table");

done_testing();

1;
