use strict;
use warnings;
use Test::More;
use Carp qw/croak/;

use lib '.';
BEGIN {
    use_ok("HTML::TableContent");
}

subtest "basic_single_column_table" => sub {
    plan tests => 21;
    my $file = 't/html/horizontal/simple-one-column-table.html';
    run_tests({
        file => $file,
        count => 1,
        table => 0,
        table_header_count => 1,
        table_class => 'something',
        table_id => 'test-id',
        table_row_count => 1,
        has_nested => 0,
        row => 0,
        row_cell_count => 1,
        row_class => 'echo',
        row_id => 'test-row-id',
        cell => 0,
        cell_header_class => 'header',
        cell_header_text => 'this',
        cell_header_data_0 => 'this',
        cell_class => 'ping',
        cell_id => 'test-cell-id',
        cell_text => 'thing',
        cell_data_0 => 'thing',
    });
};

subtest "basic_two_column_table" => sub {
    plan tests => 40;
    my $file =  't/html/horizontal/simple-two-column-table.html';
    run_tests({
        file => $file,
        count => 1,
        table => 0,
        table_header_count => 2,
        table_class => 'two-columns',
        table_id => 'two-id',
        table_row_count => 2,
        has_nested => 0,
        row => 0,
        row_cell_count => 2,
        row_class => 'two-column-odd',
        row_id => 'row-1',
        cell => 1,
        cell_header_class => 'savings',
        cell_header_text => 'Savings',
        cell_header_data_0 => 'Savings',
        cell_class => 'price',
        cell_text => '$100',
        cell_data_0 => '$100',
    });
    run_tests({
        file => $file,
        count => 1,
        table => 0,
        table_header_count => 2,
        table_class => 'two-columns',
        table_id => 'two-id',
        table_row_count => 2,
        has_nested => 0,
        row => 1,
        row_cell_count => 2,
        row_class => 'two-column-even',
        row_id => 'row-2',
        cell => 0,
        cell_header_class => 'month',
        cell_header_text => 'Month',
        cell_header_data_0 => 'Month',
        cell_id => 'month-02',
        cell_text => 'Febuary',
        cell_data_0 => 'Febuary',
    });
};

subtest "simple_three_column_table" => sub {
    plan tests => 60;
    my $file =  't/html/horizontal/simple-three-column-table.html';
    run_tests({
        file => $file,
        count => 1,
        table => 0,
        table_class => 'three-columns',
        table_id => 'three-id',
        table_row_count => 3,
        table_header_count => 3,
        has_nested => 0,
        row => 0,
        row_cell_count => 3,
        row_class => 'three-column-odd',
        row_id => 'row-1',
        cell => 1,
        cell_header_class => 'bold',
        cell_header_text => 'Last Name',
        cell_header_data_0 => 'Last Name',
        cell_class => 'second-name ital',
        cell_text => 'Janet',
        cell_data_0 => 'Janet',
    });
    run_tests({
        file => $file,
        count => 1,
        table => 0,
        table_class => 'three-columns',
        table_id => 'three-id',
        table_row_count => 3,
        table_header_count => 3,
        has_nested => 0,
        row => 1,
        row_cell_count => 3,
        row_class => 'three-column-even',
        row_id => 'row-2',
        cell => 0,
        cell_header_class => 'bold',
        cell_header_text => 'First Name',
        cell_header_data_0 => 'First Name',
        cell_class => 'first-name bold',
        cell_text => 'Raymond',
        cell_data_0 => 'Raymond',
    });
    run_tests({
        file => $file,
        count => 1,
        table => 0,
        table_class => 'three-columns',
        table_id => 'three-id',
        table_row_count => 3,
        table_header_count => 3,
        has_nested => 0,
        row => 2,
        row_cell_count => 3,
        row_class => 'three-column-odd',
        row_id => 'row-3',
        cell => 2,
        cell_header_class => 'bold',
        cell_header_text => 'Email',
        cell_header_data_0 => 'Email',
        cell_class => 'email',
        cell_text => 'lukas@emails.com',
        cell_data_0 => 'lukas@emails.com'
    });
};

subtest "two_tables_two_columns" => sub {
    plan tests => 40;
    my $file =  't/html/horizontal/two-two-column-tables.html';
    run_tests({
        file => $file,
        count => 2,
        table => 0,
        table_header_count => 2,
        table_class => 'two-columns',
        table_id => 'table-1',
        table_row_count => 2,
        has_nested => 0,
        row => 0,
        row_cell_count => 2,
        row_class => 'two-column-odd',
        row_id => 'row-1',
        cell => 1,
        cell_header_class => 'savings',
        cell_header_text => 'Savings',
        cell_header_data_0 => 'Savings',
        cell_class => 'price',
        cell_text => '$100',
        cell_data_0 => '$100',
    });
    run_tests({
        file => $file,
        count => 2,
        table => 1,
        table_header_count => 2,
        table_class => 'two-columns',
        table_id => 'table-2',
        table_row_count => 2,
        has_nested => 0,
        row => 1,
        row_cell_count => 2,
        row_class => 'two-column-even',
        row_id => 'row-2',
        cell => 0,
        cell_header_class => 'month',
        cell_header_text => 'Month',
        cell_header_data_0 => 'Month',
        cell_id => 'month-02',
        cell_text => 'Febuary',
        cell_data_0 => 'Febuary',
    });
};

subtest "three_tables_three_columns" => sub {
    plan tests => 60;
    my $file =  't/html/horizontal/three-three-column-tables.html';
    run_tests({
        file => $file,
        count => 3,
        table => 0,
        table_class => 'three-columns',
        table_id => 'table-1',
        table_row_count => 3,
        table_header_count => 3,
        has_nested => 0,
        row => 0,
        row_cell_count => 3,
        row_class => 'three-column-odd',
        row_id => 'row-1',
        cell => 1,
        cell_header_class => 'bold',
        cell_header_text => 'Last Name',
        cell_header_data_0 => 'Last Name',
        cell_class => 'second-name ital',
        cell_text => 'Janet',
        cell_data_0 => 'Janet',
    });
    run_tests({
        file => $file,
        count => 3,
        table => 1,
        table_class => 'three-columns',
        table_id => 'table-2',
        table_row_count => 3,
        table_header_count => 3,
        has_nested => 0,
        row => 1,
        row_cell_count => 3,
        row_class => 'three-column-even',
        row_id => 'row-2',
        cell => 0,
        cell_header_class => 'bold',
        cell_header_text => 'First Name',
        cell_header_data_0 => 'First Name',
        cell_class => 'first-name bold',
        cell_text => 'Ray',
        cell_data_0 => 'Ray',
    });
    run_tests({
        file => $file,
        count => 3,
        table => 2,
        table_class => 'three-columns',
        table_id => 'table-3',
        table_row_count => 3,
        table_header_count => 3,
        has_nested => 0,
        row => 2,
        row_cell_count => 3,
        row_class => 'three-column-odd',
        row_id => 'row-3',
        cell => 2,
        cell_header_class => 'bold',
        cell_header_text => 'Email',
        cell_header_data_0 => 'Email',
        cell_class => 'email',
        cell_text => 'luke@emails.com',
        cell_data_0 => 'luke@emails.com',
    });
};

subtest "page_two_tables" => sub {
    plan tests => 40;
    my $file =  't/html/horizontal/page-two-tables.html';
    run_tests({
        file => $file,
        count => 2,
        table => 0,
        table_header_count => 2,
        table_class => 'two-columns',
        table_id => 'table-1',
        table_row_count => 2,
        has_nested => 0,
        row => 0,
        row_cell_count => 2,
        row_class => 'two-column-odd',
        row_id => 'row-1',
        cell => 1,
        cell_header_class => 'savings',
        cell_header_text => 'Savings',
        cell_header_data_0 => 'Savings',
        cell_class => 'price',
        cell_text => '$100',
        cell_data_0 => '$100'
    });
    run_tests({
        file => $file,
        count => 2,
        table => 1,
        table_header_count => 2,
        table_class => 'two-columns',
        table_id => 'table-2',
        table_row_count => 2,
        has_nested => 0,
        row => 1,
        row_cell_count => 2,
        row_class => 'two-column-even',
        row_id => 'row-2',
        cell => 0,
        cell_header_class => 'month',
        cell_header_text => 'Month',
        cell_header_data_0 => 'Month',
        cell_id => 'month-02',
        cell_text => 'Febuary',
        cell_data_0 => 'Febuary'
    });
};

subtest "page_three_tables" => sub {
    plan tests => 60;
    my $file =  't/html/horizontal/page-three-tables.html';
    run_tests({
        file => $file,
        count => 3,
        table => 0,
        table_class => 'three-columns',
        table_id => 'table-1',
        table_row_count => 3,
        table_header_count => 3,
        has_nested => 0,
        row => 0,
        row_cell_count => 3,
        row_class => 'three-column-odd',
        row_id => 'row-1',
        cell => 1,
        cell_header_class => 'bold',
        cell_header_text => 'Last Name',
        cell_header_data_0 => 'Last Name',
        cell_class => 'second-name ital',
        cell_text => 'Janet',
        cell_data_0 => 'Janet',
    });
    run_tests({
        file => $file,
        count => 3,
        table => 1,
        table_class => 'three-columns',
        table_id => 'table-2',
        table_row_count => 3,
        table_header_count => 3,
        has_nested => 0,
        row => 1,
        row_cell_count => 3,
        row_class => 'three-column-even',
        row_id => 'row-2',
        cell => 0,
        cell_header_class => 'bold',
        cell_header_text => 'First Name',
        cell_header_data_0 => 'First Name',
        cell_class => 'first-name bold',
        cell_text => 'Ray',
        cell_data_0 => 'Ray',
    });
    run_tests({
        file => $file,
        count => 3,
        table => 2,
        table_class => 'three-columns',
        table_id => 'table-3',
        table_row_count => 3,
        table_header_count => 3,
        has_nested => 0,
        row => 2,
        row_cell_count => 3,
        row_class => 'three-column-odd',
        row_id => 'row-3',
        cell => 2,
        cell_header_class => 'bold',
        cell_header_text => 'Email',
        cell_header_data_0 => 'Email',
        cell_class => 'email',
        cell_text => 'luke@emails.com',
        cell_data_0 => 'luke@emails.com',
    });
};

subtest "simple-one-file-column" => sub {
    plan tests => 22;
    my $file =  't/html/horizontal/simple-one-html-column.html';
    run_tests({
        file => $file,
        count => 1,
        table => 0,
        table_header_count => 1,
        table_class => 'something',
        table_id => 'test-id',
        table_row_count => 1,
        has_nested => 0,
        row => 0,
        row_cell_count => 1,
        row_class => 'echo',
        row_id => 'test-row-id',
        cell => 0,
        cell_header_class => 'header',
        cell_header_text => 'this',
        cell_header_data_0 => 'this',
        cell_class => 'ping',
        cell_id => 'test-cell-id',
        cell_text => 'thing just because they can',
        cell_data_0 => 'thing',
        cell_data_1 => 'just because they can',
    });  
};

subtest "broken-file-two-columns" => sub {
    plan tests => 43;
    my $file = 't/html/horizontal/page-two-tables-columns.html';
    run_tests({
        file => $file,
        count => 2,
        table => 0,
        table_header_count => 2,
        table_class => 'two-columns',
        table_id => 'table-1',
        table_row_count => 2,
        has_nested => 0,
        row => 0,
        row_cell_count => 2,
        row_class => 'two-column-odd',
        row_id => 'row-1',
        cell => 1,
        cell_header_class => 'savings', 
        cell_header_text => 'Savings',
        cell_header_data_0 => 'Savings',
        cell_class => 'price',
        cell_text => '$100 usd',
        cell_data_0 => '$100',
        cell_data_1 => 'usd',
    }); 
    run_tests({
        file => $file,
        count => 2,
        table => 1,
        table_header_count => 2,
        table_class => 'two-columns',
        table_id => 'table-2',
        has_nested => 0,
        table_row_count => 2,
        row => 1,
        row_cell_count => 2,
        row_class => 'two-column-even',
        row_id => 'row-2',
        cell => 0,
        cell_header_class => 'month',
        cell_header_text => 'Month thing',
        cell_header_data_0 => 'Month',
        cell_header_data_1 => 'thing',
        cell_id => 'month-02',
        cell_text => 'Febuary 02',
        cell_data_0 => 'Febuary',
        cell_data_1 => '02',
    });
};

done_testing();

sub run_tests {
    my $args = shift;

    my $t = HTML::TableContent->new();
    ok($t->parse_file($args->{file}), "parse file into HTML::TableContent");
    
    is($t->table_count, $args->{count}, "correct table count: $args->{count}");
    
    ok(my $table = $t->tables->[$args->{table}], "found table index: $args->{table}");
 
    is($table->row_count, $args->{table_row_count}, "correct row count: $args->{table_row_count}");

    is($table->header_count, $args->{table_header_count}, "expected header count: $args->{table_header_count}");
    
    is($table->class, $args->{table_class}, "table class: $args->{table_class}");

    is($table->has_nested, $args->{has_nested}, "no nested tables");

    is($table->id, $args->{table_id}, "table class: $args->{table_id}");

    ok(my $row = $table->rows->[$args->{row}], "found row index: $args->{row}");

    is($row->cell_count, $args->{row_cell_count}, "expected cell count: $args->{row_cell_count}");

    is($row->class, $args->{row_class}, "row class: $args->{row_class}");

    is($row->id, $args->{row_id}, "row id: $args->{row_id}"); 
            
    ok(my $header = $table->headers->[$args->{cell}], "found header for cell: $args->{cell}");
    
    is($header->text, $args->{cell_header_text}, "expected cell_header: $args->{cell_header_text}");
                
    is($header->data->[0], $args->{cell_header_data_0}, "expected cell_header: $args->{cell_header_data_0}");
    
    if ( my $cell_header_1 = $args->{cell_header_data_1} ) {
        is($header->data->[1], $cell_header_1, "expected cell_header: $cell_header_1}");
    }

    is( $header->class, $args->{cell_header_class}, "header class: $args->{cell_header_class}");   
            
    ok(my $cell = $row->cells->[$args->{cell}], "found cell index: $args->{cell}");
    
    if (my $cell_class = $args->{cell_class}) {          
        is($cell->class, $cell_class, "cell class: $cell_class");
    }
    
    if (my $cell_id = $args->{cell_id}) {
        is($cell->id, $cell_id, "cell id: $cell_id");
    }

    is($cell->text, $args->{cell_text}, "cell text: $args->{cell_text}");

    is($cell->data->[0], $args->{cell_data_0}, "cell data: $args->{cell_data_0}");
            
    if ( my $cell_data_1 = $args->{cell_data_1} ) {
        is($cell->data->[1], $cell_data_1, "cell data: $cell_data_1");
    }
}

1;
