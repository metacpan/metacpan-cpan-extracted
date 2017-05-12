use strict;
use warnings;
use Test::More;
use Carp qw/croak/;

use lib '.';

BEGIN {
    use_ok("HTML::TableContent");
}

subtest "basic_two_column_table" => sub {
    plan tests => 9;
    my $html = open_file('t/html/horizontal/page-two-tables.html');
    run_tests({
        html => $html,
        get_first_table => 1,
        get_first_row => 1,
        cell_count => 2,
        raw => {
          'class' => 'two-column-odd',
          'id' => 'row-1',
          'cells' => [
                       {
                         'id' => 'month-01',
                         'data' => [
                                     'January'
                                   ],
                         'text' => 'January'
                       },
                       {
                         'text' => '$100',
                         'data' => [
                                     '$100'
                                   ],
                         'class' => 'price'
                       }
                     ]
        },
        hash => {
            'Month' => 'January',
            'Savings' => '$100',
        },
        array => [ 'January', '$100' ],
        get_first_cell => 1,
    });
};

subtest "basic_two_column_table_file" => sub {
    plan tests => 9;
    my $file = 't/html/horizontal/page-two-tables.html';
    run_tests({
        file => $file,
        get_first_table => 1,
        get_first_row => 1,
        cell_count => 2,
        raw => {
          'class' => 'two-column-odd',
          'id' => 'row-1',
          'cells' => [
                       {
                         'id' => 'month-01',
                         'data' => [
                                     'January'
                                   ],
                         'text' => 'January'
                       },
                       {
                         'text' => '$100',
                         'data' => [
                                     '$100'
                                   ],
                         'class' => 'price'
                       }
                     ]
        },
        get_first_cell => 1,
        hash => {
            'Month' => 'January',
            'Savings' => '$100',
        },
        array => [ 'January', '$100' ],
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

    my $t = HTML::TableContent->new();
    
    if (my $html = $args->{html} ) {    
        ok($t->parse($args->{html}), "parse html into HTML::TableContent");
    } else {
        ok($t->parse_file($args->{file}, "parse file into HTML::TableContent"));
    }

    ok(my $table = $t->get_first_table, "get first table");
      
    ok(my $row = $table->get_first_row, "get first row");

    is_deeply($row->hash, $args->{hash}, "hash row");

    my @array = $row->array;
    is_deeply(\@array, $args->{array}, "array row");

    is($table->get_first_row->get_first_cell->links->[0], qw/work.html/);

    is($row->cell_count, $args->{cell_count}, "expected row count");

    is_deeply($row->raw, $args->{raw}, "expected raw structure");
       
    ok( $row->get_first_cell, "okay get first cell" );
}

1;
