use strict;
use warnings;
use Test::More;
use Carp qw/croak/;

use lib '.';

BEGIN {
    use_ok("HTML::TableContent");
}

subtest "basic_two_column_table" => sub {
    plan tests => 16;
    my $html = open_file('t/html/horizontal/page-two-tables.html');
    run_tests({
        html => $html,
        get_first_table => 1,
        row_count => 2,
        header_count => 2,
        headers_spec => {
            'month' => 1,
            'savings' => 1,
        },
        has_nested => 0,
        has_nested_column => 0,
        header_exists => qw/Savings/,
        raw => {
            'class' => 'two-columns',
            'rows' => [
                        {
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
                        {
                          'id' => 'row-2',
                          'cells' => [
                                       {
                                         'id' => 'month-02',
                                         'text' => 'Febuary',
                                         'data' => [
                                                     'Febuary'
                                                   ]
                                       },
                                       {
                                         'text' => '$100',
                                         'data' => [
                                                     '$100'
                                                   ],
                                         'class' => 'price'
                                       }
                                     ],
                          'class' => 'two-column-even'
                        }
                      ],
            'id' => 'table-1',
            'headers' => [
                           {
                             'class' => 'month',
                             'text' => 'Month',
                             'data' => [
                                         'Month'
                                       ]
                           },
                           {
                             'text' => 'Savings',
                             'data' => [
                                         'Savings'
                                       ],
                             'class' => 'savings'
                           }
                         ]
          },
        get_first_header => 1,
        get_first_row => 1,
        get_header_column => [
            '$100',
            '$100'
        ],
        get_dedupe_header_column => [
            '$100',
        ],
        aoa => [
          [ 'Month', 'Savings' ],
          [ 'January', '$100' ],
          [ 'Febuary', '$100' ]
        ],
        aoh => [
            { 
                'Month' => 'January',
                'Savings' => '$100',
            },
            {
                'Month' => 'Febuary',
                'Savings' => '$100',
            }
        ]
    });
};

subtest "basic_two_column_table_file" => sub {
    plan tests => 16;
    my $file = 't/html/horizontal/page-two-tables.html';
    run_tests({
        file => $file,
        get_first_table => 1,
        row_count => 2,
        header_count => 2,
        has_nested => 0,
        has_nested_column => 0,
        headers_spec => {
            'month' => 1,
            'savings' => 1,
        },
        header_exists => qw/Savings/,
        raw => {
            'class' => 'two-columns',
            'rows' => [
                        {
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
                        {
                          'id' => 'row-2',
                          'cells' => [
                                       {
                                         'id' => 'month-02',
                                         'text' => 'Febuary',
                                         'data' => [
                                                     'Febuary'
                                                   ]
                                       },
                                       {
                                         'text' => '$100',
                                         'data' => [
                                                     '$100'
                                                   ],
                                         'class' => 'price'
                                       }
                                     ],
                          'class' => 'two-column-even'
                        }
                      ],
            'id' => 'table-1',
            'headers' => [
                           {
                             'class' => 'month',
                             'text' => 'Month',
                             'data' => [
                                         'Month'
                                       ]
                           },
                           {
                             'text' => 'Savings',
                             'data' => [
                                         'Savings'
                                       ],
                             'class' => 'savings'
                           }
                         ]
          },
        get_first_header => 1,
        get_first_row => 1,
        get_header_column => [
            '$100',
            '$100'
        ],
        get_dedupe_header_column => [
            '$100',
        ],
        aoa => [
          [ 'Month', 'Savings' ],
          [ 'January', '$100' ],
          [ 'Febuary', '$100' ]
        ],
        aoh => [
            { 
                'Month' => 'January',
                'Savings' => '$100',
            },
            {
                'Month' => 'Febuary',
                'Savings' => '$100',
            }
        ],
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
    
    is_deeply($table->aoa, $args->{aoa}, "expected table as aoa");
    is_deeply($table->aoh, $args->{aoh}, "expected table as aoh");

    is($table->header_count, $args->{header_count}, "expected headers count");

    is($table->row_count, $args->{row_count}, "expected row count");

    is_deeply( $table->headers_spec, $args->{headers_spec}, "expected header spec" );

    is($table->header_exists($args->{header_exists}), 1, "okay header exists: $args->{header_exists}" );

    is_deeply($table->raw, $args->{raw}, "expected raw structure");
    
    is($table->has_nested, $args->{has_nested}, "no nested tables");

    is($table->has_nested_table_column, $args->{has_nested_column}, "no nested column");

    ok( $table->get_first_row, "okay get first row" );

    ok( $table->get_first_header, "okay get first header" );

    is_deeply($table->get_col_text('Savings'), $args->{get_header_column}, "okay get_header_column");
  
    is_deeply($table->get_header_column_text(header => 'Savings'), $args->{get_header_column}, "okay get_header_column");

    is_deeply($table->get_header_column_text(header => 'Savings', dedupe => 1), $args->{get_dedupe_header_column}, "okay dedupe get_header_column");
}

1;
