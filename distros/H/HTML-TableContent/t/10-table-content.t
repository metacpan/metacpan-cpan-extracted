use strict;
use warnings;
use Test::More;
use Carp qw/croak/;

use lib '.';

BEGIN {
    use_ok("HTML::TableContent");
}

subtest "basic_two_column_table" => sub {
    plan tests => 8;
    my $html = open_file('t/html/horizontal/page-two-tables.html');
    run_tests({
        html => $html,
        table_count => 2,
        headers_spec => {
          'expenditure' => 1,
          'savings' => 1,
          'month' => 2
        },
        headers_exist => qw/Savings/,
        raw => [
          {
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
          {
            'headers' => [
                           {
                             'text' => 'Month',
                             'data' => [
                                         'Month'
                                       ],
                             'class' => 'month'
                           },
                           {
                             'class' => 'expence',
                             'text' => 'Expenditure',
                             'data' => [
                                         'Expenditure'
                                       ]
                           }
                         ],
            'rows' => [
                        {
                          'cells' => [
                                       {
                                         'id' => 'month-01',
                                         'data' => [
                                                     'January'
                                                   ],
                                         'text' => 'January'
                                       },
                                       {
                                         'text' => '$1000',
                                         'data' => [
                                                     '$1000'
                                                   ],
                                         'class' => 'price'
                                       }
                                     ],
                          'id' => 'row-1',
                          'class' => 'two-column-odd'
                        },
                        {
                          'class' => 'two-column-even',
                          'cells' => [
                                       {
                                         'text' => 'Febuary',
                                         'data' => [
                                                     'Febuary'
                                                   ],
                                         'id' => 'month-02'
                                       },
                                       {
                                         'data' => [
                                                     '$500'
                                                   ],
                                         'text' => '$500',
                                         'class' => 'price'
                                       }
                                     ],
                          'id' => 'row-2'
                        }
                      ],
            'id' => 'table-2',
            'class' => 'two-columns'
          }
        ],
        filter_headers => qw/Savings/,
        filtered_raw => [
          {
            'class' => 'two-columns',
            'headers' => [
                           {
                             'data' => [
                                         'Savings'
                                       ],
                             'text' => 'Savings',
                             'class' => 'savings'
                           }
                         ],
            'rows' => [
                        {
                          'cells' => [
                                       {
                                         'data' => [
                                                     '$100'
                                                   ],
                                         'class' => 'price',
                                         'text' => '$100'
                                       }
                                     ],
                          'class' => 'two-column-odd',
                          'id' => 'row-1'
                        },
                        {
                          'id' => 'row-2',
                          'class' => 'two-column-even',
                          'cells' => [
                                       {
                                         'data' => [
                                                     '$100'
                                                   ],
                                         'text' => '$100',
                                         'class' => 'price'
                                       }
                                     ]
                        }
                      ],
            'id' => 'table-1'
          }
        ],
        get_first_table => 1,
    });
};


subtest "basic_two_column_table_file" => sub {
    plan tests => 8;
    my $file = 't/html/horizontal/page-two-tables.html';
    run_tests({
        file => $file,
        table_count => 2,
        headers_spec => {
          'expenditure' => 1,
          'savings' => 1,
          'month' => 2
        },
        headers_exist => qw/Savings/,
        raw => [
          {
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
          {
            'headers' => [
                           {
                             'text' => 'Month',
                             'data' => [
                                         'Month'
                                       ],
                             'class' => 'month'
                           },
                           {
                             'class' => 'expence',
                             'text' => 'Expenditure',
                             'data' => [
                                         'Expenditure'
                                       ]
                           }
                         ],
            'rows' => [
                        {
                          'cells' => [
                                       {
                                         'id' => 'month-01',
                                         'data' => [
                                                     'January'
                                                   ],
                                         'text' => 'January'
                                       },
                                       {
                                         'text' => '$1000',
                                         'data' => [
                                                     '$1000'
                                                   ],
                                         'class' => 'price'
                                       }
                                     ],
                          'id' => 'row-1',
                          'class' => 'two-column-odd'
                        },
                        {
                          'class' => 'two-column-even',
                          'cells' => [
                                       {
                                         'text' => 'Febuary',
                                         'data' => [
                                                     'Febuary'
                                                   ],
                                         'id' => 'month-02'
                                       },
                                       {
                                         'data' => [
                                                     '$500'
                                                   ],
                                         'text' => '$500',
                                         'class' => 'price'
                                       }
                                     ],
                          'id' => 'row-2'
                        }
                      ],
            'id' => 'table-2',
            'class' => 'two-columns'
          }
        ],
        filter_headers => qw/Savings/,
        filtered_raw => [
          {
            'class' => 'two-columns',
            'headers' => [
                           {
                             'data' => [
                                         'Savings'
                                       ],
                             'text' => 'Savings',
                             'class' => 'savings'
                           }
                         ],
            'rows' => [
                        {
                          'cells' => [
                                       {
                                         'data' => [
                                                     '$100'
                                                   ],
                                         'class' => 'price',
                                         'text' => '$100'
                                       }
                                     ],
                          'class' => 'two-column-odd',
                          'id' => 'row-1'
                        },
                        {
                          'id' => 'row-2',
                          'class' => 'two-column-even',
                          'cells' => [
                                       {
                                         'data' => [
                                                     '$100'
                                                   ],
                                         'text' => '$100',
                                         'class' => 'price'
                                       }
                                     ]
                        }
                      ],
            'id' => 'table-1'
          }
        ],
        get_first_table => 1,
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
   
    is($t->table_count, $args->{table_count}, "expected table count");

    is_deeply( $t->headers_spec, $args->{headers_spec}, "expected header spec" );

    is($t->headers_exist($args->{headers_exist}), 1, "okay header exists: $args->{headers_exist}" );

    is_deeply($t->raw, $args->{raw}, "expected raw structure");
       
    ok($t->filter_tables(header => $args->{filter_headers}), "filter tables: $args->{filter_headers}");
    
    is_deeply($t->raw, $args->{filtered_raw}, "expected filtered raw structure");
   
    ok($t->get_first_table, "get first table");
}

1;
