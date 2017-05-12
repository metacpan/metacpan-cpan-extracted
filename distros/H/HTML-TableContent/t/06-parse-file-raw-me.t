use strict;
use warnings;
use Test::More;
use Carp qw/croak/;

use lib '.';

BEGIN {
    use_ok("HTML::TableContent");
}

subtest "basic_two_column_table" => sub {
    plan tests => 4;
    my $html = 't/html/horizontal/simple-two-column-table.html';
    run_tests({
        file => $html,
        raw_me => [ {
          'headers' => [
                         {
                           'data' => [
                                       'Month'
                                     ],
                           'class' => 'month',
                           'text' => 'Month'
                         },
                         {
                           'data' => [
                                       'Savings'
                                     ],
                           'text' => 'Savings',
                           'class' => 'savings'
                         }
                       ],
          'id' => 'two-id',
          'rows' => [
                      {
                        'cells' => [
                                     {
                                       'text' => 'January',
                                       'id' => 'month-01',
                                       'data' => [
                                                   'January'
                                                 ]
                                     },
                                     {
                                       'class' => 'price',
                                       'text' => '$100',
                                       'data' => [
                                                   '$100'
                                                 ]
                                     }
                                   ],
                        'id' => 'row-1',
                        'class' => 'two-column-odd'
                      },
                      {
                        'cells' => [
                                     {
                                       'data' => [
                                                   'Febuary'
                                                 ],
                                       'text' => 'Febuary',
                                       'id' => 'month-02'
                                     },
                                     {
                                       'class' => 'price',
                                       'text' => '$100',
                                       'data' => [
                                                   '$100'
                                                 ]
                                     }
                                   ],
                        'id' => 'row-2',
                        'class' => 'two-column-even'
                      }
                    ],
          'class' => 'two-columns'
        }, ], 
    });
    run_tests({
        file => $html,
        headers => [qw/Month/],
        raw_me => [{
          'rows' => [
                      {
                        'class' => 'two-column-odd',
                        'id' => 'row-1',
                        'cells' => [
                                     {
                                       'data' => [
                                                   'January'
                                                 ],
                                       'id' => 'month-01',
                                       'text' => 'January'
                                     }
                                   ]
                      },
                      {
                        'cells' => [
                                     {
                                       'text' => 'Febuary',
                                       'data' => [
                                                   'Febuary'
                                                 ],
                                       'id' => 'month-02'
                                     }
                                   ],
                        'id' => 'row-2',
                        'class' => 'two-column-even'
                      }
                    ],
          'class' => 'two-columns',
          'id' => 'two-id',
          'headers' => [
                         {
                           'data' => [
                                       'Month'
                                     ],
                           'class' => 'month',
                           'text' => 'Month'
                         }
                       ]
        }, ], 
    });
};

done_testing();

sub run_tests {
    my $args = shift;

    my $t = HTML::TableContent->new();
    
    ok($t->parse_file($args->{file}), "parse file into HTML::TableContent");

    if (my $headers = $args->{headers}) {
        $t->filter_tables(headers => $headers);
    }
   
    is_deeply($t->raw, $args->{raw_me}, "raw data structure as expected");
}

1;
