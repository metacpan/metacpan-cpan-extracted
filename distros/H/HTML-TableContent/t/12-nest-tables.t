use strict;
use warnings;
use Test::More;
use Carp;

use lib '.';

BEGIN {
    use_ok("HTML::TableContent");
}

subtest "nested one level" => sub {
    plan tests => 36;
    run_tests({
        file => 't/html/nest/one-level.html',
        table_count => 1,
        header_count => 2,
        row_count => 2,
        has_nested => 1,
        nested_table_count => 2,
        nested_table_column => 1,
        nested_column_header => { 'facts' =>  1 },
        nested_table_header_count => 0,
        first_cell_text => 'Hello',
        second_row_cell_count => 2,
        row_nested_cell => 1,
        row_nested_cell_text => '你好',
    });
};

subtest "nested row two tables" => sub {
    plan tests => 52;
    run_tests({
        file => 't/html/nest/one-level-two-tables.html',
        table_count => 1,
        header_count => 2,
        row_count => 2,
        has_nested => 1,
        nested_table_count => 4,
        nested_table_column => 1,
        nested_column_header => { 'facts' => 1 },
        nested_table_header_count => 0,
        first_cell_text => 'Hello',
        second_row_cell_count => 2,
        row_nested_cell => 1,
        row_nested_cell_text => '你好',
        run_second_tests => 1,
        first_second_table_header_count => 0,
        first_second_table_row_count => 2,
        first_second_table_first_cell => 'Goodbye',
        second_second_table_row_count => 2,
        second_second_table_header_count => 0,
        second_row_second_table_first_cell => '再見',
    });    
};

subtest "nested column three tables" => sub {
    plan tests => 52;
    run_tests({
        file => 't/html/nest/one-level-three-tables.html',
        table_count => 1,
        header_count => 2,
        row_count => 2,
        has_nested => 1,
        nested_table_count => 6,
        nested_table_column => 1,
        nested_column_header => { 'translations' => 1 },
        nested_table_header_count => 0,
        first_cell_text => 'Hello',
        second_row_cell_count => 2,
        row_nested_cell => 1,
        row_nested_cell_text => '你好',
        run_second_tests => 1,
        first_second_table_header_count => 0,
        first_second_table_row_count => 2,
        first_second_table_first_cell => 'Goodbye',
        second_second_table_row_count => 2,
        second_second_table_header_count => 0,
        second_row_second_table_first_cell => '再見',
    }); 
};

subtest "nested tables inside nested tables" => sub {
    plan tests => 62;
    run_tests({
        file => 't/html/nest/double-nest-table.html',
        table_count => 1,
        header_count => 2,
        row_count => 2,
        has_nested => 1,
        nested_table_count => 4,
        nested_table_column => 1,
        nested_column_header => { 'facts' => 1 },
        nested_table_header_count => 0,
        first_cell_text => 'subtitle',
        second_row_cell_count => 2,
        row_nested_cell => 1,
        row_nested_cell_text => '字幕',
        nested_nested_tests => 1,
        nested_has_nested => 1,
        nested_count_nested => 1,
        nested_row_count => 2,
        nested_nested_row_count => '2',
        nested_nested_text => 'Goodbye',
        nested_nested_second_table_first_cell => '再見',
    }); 
};

subtest "nested tables inside nested tables inside nested tables" => sub {
    plan tests => 66;
    run_tests({
        file => 't/html/nest/double-nest-nest-table.html',
        table_count => 1,
        header_count => 2,
        row_count => 2,
        has_nested => 1,
        nested_table_count => 6,
        nested_table_column => 1,
        nested_column_header => { 'facts' => 1 },
        nested_table_header_count => 0,
        first_cell_text => 'subtitle',
        second_row_cell_count => 2,
        row_nested_cell => 1,
        row_nested_cell_text => '字幕',
        nested_nested_tests => 1,
        nested_has_nested => 1,
        nested_count_nested => 1,
        nested_row_count => 2,
        nested_nested_row_count => '2',
        nested_nested_text => 'Goodbye',
        nested_nested_second_table_first_cell => '再見',
        double_nest_nest => 1,
        double_nest_second_table_first_cell => '你好',
    }); 
};

subtest "nested tables inside nested tables - empty rows" => sub {
    plan tests => 62;
    run_tests({
        file => 't/html/nest/double-nest-table-empty-rows.html',
        table_count => 1,
        header_count => 2,
        row_count => 2,
        has_nested => 1,
        nested_table_count => 4,
        nested_table_column => 1,
        nested_column_header => { 'facts' => 1 },
        nested_table_header_count => 0,
        first_cell_text => '',
        second_row_cell_count => 2,
        row_nested_cell => 1,
        row_nested_cell_text => '',
        nested_nested_tests => 1,
        nested_has_nested => 1,
        nested_count_nested => 1,
        nested_row_count => 1,
        nested_nested_row_count => 1,
        nested_nested_text => 'Goodbye',
        nested_nested_second_table_first_cell => '再見',
        first => 1,
    }); 
};

subtest "nested tables inside nested tables - empty cells" => sub {
    plan tests => 62;
    run_tests({
        file => 't/html/nest/double-nest-table-empty-cells.html',
        table_count => 1,
        header_count => 2,
        row_count => 2,
        has_nested => 1,
        nested_table_count => 4,
        nested_table_column => 1,
        nested_column_header => { 'facts' => 1 },
        nested_table_header_count => 0,
        first_cell_text => '',
        second_row_cell_count => 2,
        row_nested_cell => 1,
        row_nested_cell_text => '',
        nested_nested_tests => 1,
        nested_has_nested => 1,
        nested_count_nested => 1,
        nested_row_count => 2,
        nested_nested_row_count => 2,
        nested_nested_text => 'Goodbye',
        nested_nested_second_table_first_cell => '再見',
    }); 
};

subtest "nested tables with headers" => sub {
    plan tests => 36;
    run_tests({
        file => 't/html/nest/one-level-header-table.html',
        table_count => 1,
        header_count => 2,
        row_count => 2,
        has_nested => 1,
        nested_table_count => 2,
        nested_table_column => 1,
        nested_column_header => { 'facts' =>  1 },
        nested_table_header_count => 2,
        first_cell_text => 'Hello',
        second_row_cell_count => 2,
        row_nested_cell => 1,
        row_nested_cell_text => '你好',
    });
};

subtest "nested nested tables with headers" => sub {
    plan tests => 72;
    run_tests({
        file => 't/html/nest/double-nest-nest-header-table.html',
        table_count => 1,
        header_count => 2,
        row_count => 2,
        has_nested => 1,
        nested_table_count => 6,
        nested_table_column => 1,
        nested_column_header => { 'facts' => 1 },
        nested_table_header_count => 2,
        first_cell_text => '',
        second_row_cell_count => 2,
        row_nested_cell => 1,
        row_nested_cell_text => '字幕',
        nested_nested_tests => 1,
        nested_has_nested => 1,
        nested_count_nested => 1,
        nested_row_count => 1,
        nested_nested_row_count => 1,
        nested_nested_text => '',
        nested_nested_second_table_first_cell => '再見',
        double_nest_nest => 1,
        double_nest_header => 1,
        double_nest_header_count => 1,
        double_nest_header_text => 'something',
        double_nest_header_cell_count => 2,
        double_nest_second_table_first_cell => '你好',
    }); 
};

subtest "vertical nested table" => sub {
    run_tests({
        file => 't/html/nest/vertical-one-level.html',
        table_count => 1,
        header_count => 3,
        row_count => 1,
        has_nested => 1,
        nested_table_count => 1,
        nested_table_column => 1,
        nested_column_header => { 'name:' =>  1 },
        nested_table_header_count => 0,
        first_cell_text => 'Bill Thing',
        second_row_cell_count => 3,
        row_nested_cell => 1,
        first_row => 1
    });
};

done_testing();

sub open_file {
    my $file = shift;

    open ( my $fh, '<', $file ) or croak "could not open html: $file";
    my $html = do { local $/; <$fh> };
    close $fh;

    return $html;
}

sub run_tests {
    my $args = shift;

    my $file = $args->{file};
    
    my @loops = qw/parse parse_file/;

    foreach my $loop ( @loops ) {
        my $t = HTML::TableContent->new();
        if ( $loop eq 'parse' ) {
            my $html = open_file($file);
            ok($t->parse($html));
        }
        else {
            ok($t->parse_file($file));
        }
        
        is($t->table_count, $args->{table_count}, "correct table count $args->{table_count}");

        ok(my $table = $t->get_first_table);

        is($table->header_count, $args->{header_count}, "correct table header count $args->{header_count}");

        is($table->row_count, $args->{row_count}, "correct row count: $args->{row_count}");

        is($table->has_nested, $args->{has_nested}, "table has nested tables: $args->{has_nested}");

        is($table->count_nested, $args->{nested_table_count}, "correct nested table count: $args->{nested_table_count}");

        is($table->has_nested_table_column, $args->{nested_table_column}, "has nested table column");

        is_deeply($table->nested_column_headers, $args->{nested_column_header}, "correct nested column headers");

        ok(my $col = $table->get_col((keys %{ $args->{nested_column_header}})[0]));
        
        ok( my $col_table = $col->[0]->get_first_nested);

        is($col_table->header_count, $args->{nested_table_header_count}, "correct header count: $args->{nested_table_header_count}");

        is($col_table->get_first_row->get_first_cell->text, $args->{first_cell_text}, "correct cell value: $args->{first_cell_text}");
       
        my $row;
        if (defined $args->{first_row}) {
            ok($row = $table->get_first_row);
        }
        else {
            ok($row = $table->get_row(1));
        }

        is($row->cell_count, $args->{second_row_cell_count}, "expected row cell count: $args->{second_row_cell_count}");

        is($row->has_nested, $args->{row_nested_cell}, "nested cell: $args->{row_nested_cell}");

        return unless defined $args->{row_nested_cell_text};

        ok(my $tcell = $row->get_cell(1));

        is($tcell->get_first_nested->get_first_row->get_first_cell->text, $args->{row_nested_cell_text}, "nested text: $args->{row_nested_cell_text}");
     
        if ( $args->{run_second_tests} ) { 
        
            ok( $col_table = $col->[0]->get_nested(1) );

            is( $col_table->header_count, $args->{first_second_table_header_count}, "first second table header count $args->{first_second_table_header_count}" );

            is( $col_table->row_count, $args->{first_second_table_row_count}, "first second table row count: $args->{first_second_table_row_count}" );

            is( $col_table->get_first_row->get_first_cell->text, $args->{first_second_table_first_cell}, "first second table first cell: $args->{first_second_table_first_cell}" );

            ok( my $tab = $tcell->nested->[1] );

            is( $tab->row_count, $args->{second_second_table_row_count}, "second second table row count: $args->{second_second_table_row_count}");

            is( $tab->header_count, $args->{second_second_table_header_count}, "second second table header count:  $args->{second_second_table_header_count}");

            is( $tab->get_first_row->get_first_cell->text, $args->{second_row_second_table_first_cell}, "second second table first cell: $args->{second_row_second_table_first_cell}");
        }

        if ( $args->{nested_nested_tests} ) {
            
            ok( $col_table = $col->[0]->get_nested(0) );
            
            is( $col_table->has_nested, $args->{nested_has_nested}, "nested has nested: $args->{nested_has_nested}");

            is( $col_table->count_nested, $args->{nested_count_nested}, "nested nest count: $args->{nested_count_nested}");

            is( $col_table->row_count, $args->{nested_row_count}, "nested row count: $args->{nested_row_count}" );

            ok( my $nest_col_table = $col_table->get_first_nested);
           
            is( $nest_col_table->row_count, $args->{nested_nested_row_count}, "nested nested count: $args->{nested_nested_row_count}");

            is( $nest_col_table->get_first_row->get_first_cell->text, $args->{nested_nested_text}, "nested nested text: $args->{nested_nested_text}");
        
            ok( my $t = $table->get_row(1), "get first row" );
            ok( my $c = $t->get_cell(1), "get second cell by index" );
            ok( my $i = $c->get_first_nested, "get first nested table" );
           
            my $r;
            if ( $args->{first} ){
                ok( $r = $i->get_row(0)->get_first_cell, "get first cell");
            } else {
                ok( $r = $i->get_row(1)->get_first_cell, "get first cell of second row" );
            }

            ok( my $n = $r->get_first_nested, "get first nested" ); 
            is( $n->get_first_row->get_first_cell->text, $args->{nested_nested_second_table_first_cell}, "nested second row text $args->{nested_nested_second_table_first_cell}"); 

            if ( $args->{double_nest_nest} ) {
                ok( my $u = $n->get_row(1)->get_first_cell->get_first_nested, "okay get the nested nested table" );
                
                if ( $args->{double_nest_header} ) {
                    
                    is($u->header_count, $args->{double_nest_header_count}, "header count: $args->{double_nest_header_count}");
                   
                    ok(my $header = $u->get_first_header);

                    is($header->text, $args->{double_nest_header_text}, "header text: $args->{double_nest_header_text}");

                    is($header->cell_count, $args->{double_nest_header_cell_count}, "header cell count: $args->{double_nest_header_cell_count}");
                }
                else { 
                    is ($u->get_first_row->get_first_cell->text, $args->{double_nest_second_table_first_cell}, "okay nested nested text: $args->{double_nest_second_table_first_cell}");
                }
            }
        }
    }
}

1;
