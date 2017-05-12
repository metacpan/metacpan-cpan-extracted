use strict;
use warnings;

use lib '.';

use HTML::TableContent;

use Test::More;

my $aoa = [
    [ 'Name', 'Telephone', 'Postcode'],
    [ 'Rich',  '123456',  'OX16 422' ],
    [ 'Sam',   '1243543', 'OX76 55R' ],
    [ 'Frank', '9553234', 'OX14 R4E' ]
];

my $tc = HTML::TableContent->new();

ok(my $basic = $tc->create_table({ aoa => $aoa }));

is_deeply($basic->aoa, $aoa, "aoa is the same as passed in");

my $aoh = [
    {
        'Name' => 'Rich',
        'Telephone' => '123456',
        'Postcode' => 'OX16 422',
    },
    {
        'Name' =>  'Sam',
        'Telephone' => '1243543',
        'Postcode' => 'OX76 55R',
    },
    {
        'Name' => 'Frank',
        'Telephone' => '9553234',
        'Postcode' => 'OX14 R4E',
    }
];

is_deeply($basic->aoh, $aoh, "aoa to aoh");

is($basic->row_count, 3, "expected row count 3");

is($basic->header_count, 3, "expected header count 3");

is($basic->get_first_header->text, 'Name', "expected header text: Name");

is($basic->get_first_header->cell_count, 3, "expected header cell count: 3");

is($basic->get_header(1)->text, 'Telephone', "expected header text: Telephone");

is($basic->get_header(1)->cell_count, 3, "expected header cell count: 3");

is($basic->get_last_header->text, 'Postcode', "expected header text: Postcode");

is($basic->get_last_header->cell_count, 3, "expected header cell count: 3");

ok(my $basic_row = $basic->get_first_row, "get first row");

is($basic_row->cell_count, 3, "expected row cell count: 3");

is($basic_row->get_first_cell->text, 'Rich', "expected cell text: Rich");

is($basic_row->get_first_cell->header->text, 'Name', "expected cell header: Name");

is($basic_row->get_cell(1)->text, '123456', "expected cell text: 123456");

is($basic_row->get_cell(1)->header->text, 'Telephone', "expected cell header text: Telephone");

is($basic_row->get_last_cell->text, 'OX16 422', "expected cell text: OX16 422");

is($basic_row->get_last_cell->header->text, 'Postcode', "expected cell header text: Postcode");

my $options = {
    aoa   => $aoa,
    table => {
        id => 'table-aoa',
    },
    header => {
        class => 'headers',
    },
    row => {
        class => 'rows',
    },
    cell => {
        class => 'cells',
    },
    rows => [
        {
            id    => 'first',
            cells => [
                {
                    id => 'one',
                },
                {
                    id => 'two',
                },
                {
                    id => 'three',
                }
            ]
        },
        {
            id => 'second',
        },
        {
            id => 'third',
        }
    ],
    headers => [
        {
            id => 'first-header',
        },
        {
            id => 'second-header',
        },
        {
            id => 'third-header',
        }
    ],
};

ok(my $table = $tc->create_table($options));

is_deeply($table->aoa, $aoa, "aoa is the same as passed in");

is_deeply($table->aoh, $aoh, "aoa to aoh");

is($table->row_count, 3, "expected row count 3");

is($table->header_count, 3, "expected header count 3");

is($table->id, 'table-aoa', "table id: table-aoa");

is($table->get_first_header->text, 'Name', "expected header text: Name");

is($table->get_first_header->id, 'first-header', "expected header id: first-header");

is($table->get_first_header->cell_count, 3, "expected header cell count: 3");

is($table->get_first_header->class, 'headers', "expected header class: headers");

is($table->get_header(1)->text, 'Telephone', "expected header text: Telephone");

is($table->get_header(1)->id, 'second-header', "expected header id: second-header");

is($table->get_header(1)->cell_count, 3, "expected header cell count: 3");

is($table->get_header(1)->class, 'headers', "expected header class: headers");

is($table->get_last_header->text, 'Postcode', "expected header text: Postcode");

is($table->get_last_header->id, 'third-header', "expected header id: first-header");

is($table->get_last_header->cell_count, 3, "expected header cell count: 3");

is($table->get_last_header->class, 'headers', "expected header class: headers");

ok(my $row = $table->get_first_row, "get first row");

is($row->id, 'first', "expected row id: first");

is($row->cell_count, 3, "expected row cell count: 3");

is($row->class, 'rows', "expected row class: rows");

is($row->get_first_cell->text, 'Rich', "expected cell text: Rich");

is($row->get_first_cell->id, 'one', "expected cell id: one");

is($row->get_first_cell->header->text, 'Name', "expected cell header text: Name");

is($row->get_first_cell->class, 'cells', "expected cell class: cells");

is($row->get_cell(1)->text, '123456', "expected cell text: 123456");

is($row->get_cell(1)->id, 'two', "expected cell id: two");

is($row->get_cell(1)->header->text, 'Telephone', "expected cell header text: Telephone");

is($row->get_cell(1)->class, 'cells', "expected cell class: cells");

is($row->get_last_cell->text, 'OX16 422', "expected cell text: OX16 422");

is($row->get_last_cell->id, 'three', "expected cell id: three");

is($row->get_last_cell->header->text, 'Postcode', "expected cell header text: Postcode");

is($row->get_last_cell->class, 'cells', "expected cell class: cells");

shift @{ $aoa };

my $no_header_options = {
    aoa   => $aoa,
    no_headers => 1,
    table => {
        id => 'table-aoa',
    },
    row => {
        class => 'rows',
    },
    cell => {
        class => 'cells',
    },
    rows => [
        {
            id    => 'first',
            cells => [
                {
                    id => 'one',
                },
                {
                    id => 'two',
                },
                {
                    id => 'three',
                }
            ]
        },
        {
            id => 'second',
        },
        {
            id => 'third',
        }
    ],
};

ok($table = $tc->create_table($no_header_options));

is_deeply($table->aoa, $aoa, "aoa is the same as passed in");

is($table->row_count, 3, "expected row count 3");

is($table->header_count, 0, "expected header count 0");

is($table->id, 'table-aoa', "table id: table-aoa");

ok($row = $table->get_first_row, "get first row");

is($row->id, 'first', "expected row id: first");

is($row->cell_count, 3, "expected row cell count: 3");

is($row->class, 'rows', "expected row class: rows");

is($row->get_first_cell->text, 'Rich', "expected cell text: Rich");

is($row->get_first_cell->id, 'one', "expected cell id: one");

is($row->get_first_cell->class, 'cells', "expected cell class: cells");

is($row->get_cell(1)->text, '123456', "expected cell text: 123456");

is($row->get_cell(1)->id, 'two', "expected cell id: two");

is($row->get_cell(1)->class, 'cells', "expected cell class: cells");

is($row->get_last_cell->text, 'OX16 422', "expected cell text: OX16 422");

is($row->get_last_cell->id, 'three', "expected cell id: three");

is($row->get_last_cell->class, 'cells', "expected cell class: cells");

=pod

# order
ok($basic = $tc->create_table({ aoa => $aoa, order => [qw/Name Postcode/] }));

is($basic->header_count, 2, "header count 2");

is($basic->get_first_header->text, 'Name', "first header text: Name");

is($basic->get_header(1)->text, 'Postcode', "second header text: Postcode");

is($basic->get_first_row->cell_count, 2, "first row cell count: 2");

is($basic->get_first_row->get_first_cell->text, 'Rich', "first cell text: Rich");

is($basic->get_first_row->get_cell(1)->text, "OX16 422", "second cell text: OX16 422");

# switch order
ok($basic = $tc->create_table({ aoa => $aoa, order => [qw/Postcode Name/] }));

is($basic->header_count, 2, "header count 2");

is($basic->get_first_header->text, 'Postcode', "first header text: Postcode");

is($basic->get_header(1)->text, 'Name', "second header text: Name");

is($basic->get_first_row->cell_count, 2, "first row cell count: 2");

is($basic->get_first_row->get_first_cell->text, 'OX16 422', "first cell text: Rich");

is($basic->get_first_row->get_cell(1)->text, 'Rich', "second cell text: OX16 422");

=cut

done_testing();

1;
