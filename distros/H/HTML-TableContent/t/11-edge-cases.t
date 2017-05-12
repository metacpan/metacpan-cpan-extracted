use strict;
use warnings;
use Test::More;
use Carp;

use lib '.';

BEGIN {
    use_ok("HTML::TableContent");
}

# All templates are a single table 3 x 3 - but with subtle differences.
subtest "No headers" => sub {
    plan tests => 18;
    run_tests({
        file => 't/html/edge/no-headers.html',
        expected_table_count => 1,
        expected_header_count => 0,
        expected_row_count => 3,
        expected_first_row_cell_count => 3,
        expected_first_row_first_cell_text => 'Mary'
    });
};

subtest "only one header tag" => sub {
    plan tests => 18;
    run_tests({
        file => 't/html/edge/only-one-header.html',
        expected_table_count => 1,
        expected_header_count => 1,
        expected_row_count => 3,
        expected_first_row_cell_count => 3,
        expected_first_row_first_cell_text => 'Mary'
    });
};

subtest "header text only in last column" => sub {
    plan tests => 18;
    run_tests({
        file => 't/html/edge/last-column-only-header-text.html',
        expected_table_count => 1,
        expected_header_count => 3,
        expected_row_count => 3,
        expected_first_row_cell_count => 3,
        expected_first_row_first_cell_text => 'Mary'
    });
};

subtest "header text only in last column - no classes" => sub {
    plan tests => 18;
    run_tests({
        file => 't/html/edge/last-column-only-header-text-no-classes.html',
        expected_table_count => 1,
        expected_header_count => 3,
        expected_row_count => 3,
        expected_first_row_cell_count => 3,
        expected_first_row_first_cell_text => 'Mary'
    });
};

subtest "Empty Rows - row with no cells (drop it)" => sub {
    plan tests => 18;
    run_tests({
        file => 't/html/edge/empty-row.html',
        expected_table_count => 1,
        expected_header_count => 3,
        expected_row_count => 2,
        expected_first_row_cell_count => 3,
        expected_first_row_first_cell_text => 'Raymond'
    });
};

subtest "Empty Cells - should store empty objects in place" => sub {
    plan tests => 18;
    run_tests({
        file => 't/html/edge/empty-cells.html',
        expected_table_count => 1,
        expected_header_count => 3,
        expected_row_count => 3,
        expected_first_row_cell_count => 3,
        expected_first_row_first_cell_text => 'Mary'
    });
};

subtest "Everythings a Numbers" => sub {
    plan tests => 18;
    run_tests({
        file => 't/html/edge/numeric.html',
        expected_table_count => 1,
        expected_header_count => 3,
        expected_row_count => 3,
        expected_first_row_cell_count => 3,
        expected_first_row_first_cell_text => '4'
    });
};

subtest "Expressive characters" => sub {
    plan tests => 18;
    run_tests({
        file => 't/html/edge/special.html',
        expected_table_count => 1,
        expected_header_count => 3,
        expected_row_count => 3,
        expected_first_row_cell_count => 3,
        expected_first_row_first_cell_text => 'たてきごう'
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
            use Data::Dumper; 
            ok($t->parse($html));
        }
        else {
            ok($t->parse_file($file));
        }
        
        is($t->table_count, $args->{expected_table_count}, "correct table count $args->{expected_table_count}");
        
        ok(my $table = $t->get_first_table);
        
        is($table->header_count, $args->{expected_header_count}, "correct header count: $args->{expected_header_count}");
        is($table->row_count, $args->{expected_row_count}, "correct row count: $args->{expected_row_count}");

        ok(my $row = $table->get_first_row);

        is($row->cell_count, $args->{expected_first_row_cell_count}, "correct cell count: $args->{expected_first_row_cell_count}");

        ok(my $cell = $row->get_first_cell);
        is($cell->text, $args->{expected_first_row_first_cell_text}, "correct cell text: $args->{expected_first_row_first_cell_text}");
     }
}

1;
