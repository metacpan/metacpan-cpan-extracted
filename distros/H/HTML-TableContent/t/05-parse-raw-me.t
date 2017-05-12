use strict;
use warnings;
use Test::More;
use Carp qw/croak/;

use lib '.';

BEGIN {
    use_ok("HTML::TableContent");
}

subtest "basic_two_column_table" => sub {
    plan tests => 5;
    my $html = open_file('t/html/horizontal/simple-two-column-table.html');
    run_tests(
        {
            html   => $html,
            raw_me => [
                {
                    'headers' => [
                        {
                            'data'  => [ 'Month' ],
                            'class' => 'month',
                            'text'  => 'Month'
                        },
                        {
                            'data'  => [ 'Savings' ],
                            'text'  => 'Savings',
                            'class' => 'savings'
                        }
                    ],
                    'id'   => 'two-id',
                    'rows' => [
                        {
                            'cells' => [
                                {
                                    'text' => 'January',
                                    'id'   => 'month-01',
                                    'data' => [ 'January' ]
                                },
                                {
                                    'class' => 'price',
                                    'text'  => '$100',
                                    'data'  => [ '$100' ]
                                }
                            ],
                            'id'    => 'row-1',
                            'class' => 'two-column-odd'
                        },
                        {
                            'cells' => [
                                {
                                    'data' => [ 'Febuary' ],
                                    'text' => 'Febuary',
                                    'id'   => 'month-02'
                                },
                                {
                                    'class' => 'price',
                                    'text'  => '$100',
                                    'data'  => [ '$100' ]
                                }
                            ],
                            'id'    => 'row-2',
                            'class' => 'two-column-even'
                        }
                    ],
                    'class' => 'two-columns'
                },
            ],
        }
    );
    run_tests(
        {
            html    => $html,
            headers => [qw/Month/],
            raw_me  => [
                {
                    'rows' => [
                        {
                            'class' => 'two-column-odd',
                            'id'    => 'row-1',
                            'cells' => [
                                {
                                    'data' => [ 'January' ],
                                    'id'   => 'month-01',
                                    'text' => 'January'
                                }
                            ]
                        },
                        {
                            'cells' => [
                                {
                                    'text' => 'Febuary',
                                    'data' => [ 'Febuary' ],
                                    'id'   => 'month-02'
                                }
                            ],
                            'id'    => 'row-2',
                            'class' => 'two-column-even'
                        }
                    ],
                    'class'   => 'two-columns',
                    'id'      => 'two-id',
                    'headers' => [
                        {
                            'data'  => [ 'Month' ],
                            'class' => 'month',
                            'text'  => 'Month'
                        }
                    ]
                },
            ],
        }
    );
};

subtest "basic nested table" => sub {
    plan tests => 6;
    my $html = open_file('t/html/nest/one-level.html');
    run_tests(
        {
            html   => $html,
            raw_me => [
                {
                    'nested' => [
                        {
                            'headers' => [],
                            'rows'    => [
                                {
                                    'cells' => [
                                        {
                                            'text' => 'Hello',
                                            'data' => [ 'Hello' ]
                                        }
                                    ]
                                },
                                {
                                    'cells' => [
                                        {
                                            'data' => [ 'Goodbye' ],
                                            'text' => 'Goodbye'
                                        }
                                    ]
                                }
                            ]
                        },
                        {
                            'headers' => [],
                            'rows'    => [
                                {
                                    'cells' => [
                                        {
                                            'text' => '你好',
                                            'data' => [ '你好' ]
                                        }
                                    ]
                                },
                                {
                                    'cells' => [
                                        {
                                            'text' => '再見',
                                            'data' => [ '再見' ]
                                        }
                                    ]
                                }
                            ]
                        }
                    ],
                    'class' => 'two-columns',
                    'rows'  => [
                        {
                            'id'     => 'row-1',
                            'nested' => undef,
                            'class'  => 'two-column-odd',
                            'cells'  => [
                                {
                                    'data' => [
                                        'Some Description Some Description Some Description Some Description'
                                    ],
                                    'text' =>
                                        'Some Description Some Description Some Description Some Description',
                                    'id' => 'title'
                                },
                                {
                                    'class'  => 'facts',
                                    'nested' => [
                                        {
                                            'rows' => [
                                                {
                                                    'cells' => [
                                                        {
                                                            'data' =>
                                                              [ 'Hello' ],
                                                            'text' => 'Hello'
                                                        }
                                                    ]
                                                },
                                                {
                                                    'cells' => [
                                                        {
                                                            'text' => 'Goodbye',
                                                            'data' =>
                                                              [ 'Goodbye' ]
                                                        }
                                                    ]
                                                }
                                            ],
                                            'headers' => []
                                        }
                                    ]
                                }
                            ]
                        },
                        {
                            'id'     => 'row-2',
                            'nested' => undef,
                            'class'  => 'two-column-even',
                            'cells'  => [
                                {
                                    'text' => '一些說明',
                                    'data' => [ '一些說明' ],
                                    'id'   => 'title'
                                },
                                {
                                    'class'  => 'facts',
                                    'nested' => [
                                        {
                                            'rows' => [
                                                {
                                                    'cells' => [
                                                        {
                                                            'text' => '你好',
                                                            'data' =>
                                                              [ '你好' ]
                                                        }
                                                    ]
                                                },
                                                {
                                                    'cells' => [
                                                        {
                                                            'data' =>
                                                              [ '再見' ],
                                                            'text' => '再見'
                                                        }
                                                    ]
                                                }
                                            ],
                                            'headers' => []
                                        }
                                    ] 
                                } ]
                      } ],
                'id'      => 'table-1',
                'headers' => [
                    {
                        'data'  => [ 'Description' ],
                        'text'  => 'Description',
                        'class' => 'month'
                    },
                    {
                        'class' => 'savings',
                        'data'  => [ 'Facts' ],
                        'text'  => 'Facts'
                    }
                ]
            } ],
        }
    );
    run_tests(
          {
              html    => $html,
              headers => [qw/Facts/],
              raw_me  => [
                  {
                      'id'    => 'table-1',
                      'class' => 'two-columns',
                      'rows'  => [
                          {
                              'id'    => 'row-1',
                              'class' => 'two-column-odd',
                              'cells' => [
                                  {
                                      'nested' => [
                                          {
                                              'rows' => [
                                                  {
                                                      'cells' => [
                                                          {
                                                              'data' =>
                                                                [ 'Hello' ],
                                                              'text' => 'Hello'
                                                          }
                                                      ]
                                                  },
                                                  {
                                                      'cells' => [
                                                          {
                                                              'text' =>
                                                                'Goodbye',
                                                              'data' =>
                                                                [ 'Goodbye' ]
                                                          }
                                                      ]
                                                  }
                                              ],
                                              'headers' => []
                                          }
                                      ],
                                      'class' => 'facts'
                                  }
                              ],
                              'nested' => undef
                          },
                          {
                              'id'     => 'row-2',
                              'nested' => undef,
                              'cells'  => [
                                  {
                                      'nested' => [
                                          {
                                              'rows' => [
                                                  {
                                                      'cells' => [
                                                          {
                                                              'text' =>
                                                                '你好',
                                                              'data' =>
                                                                [ '你好' ]
                                                          }
                                                      ]
                                                  },
                                                  {
                                                      'cells' => [
                                                          {
                                                              'data' =>
                                                                [ '再見' ],
                                                              'text' => '再見'
                                                          }
                                                      ]
                                                  }
                                              ],
                                              'headers' => []
                                          }
                                      ],
                                      'class' => 'facts'
                                  }
                              ],
                              'class' => 'two-column-even'
                          }
                      ],
                      'headers' => [
                          {
                              'class' => 'savings',
                              'data'  => [ 'Facts' ],
                              'text'  => 'Facts'
                          }
                      ],
                      'nested' => [
                          {
                              'headers' => [],
                              'rows'    => [
                                  {
                                      'cells' => [
                                          {
                                              'text' => 'Hello',
                                              'data' => [ 'Hello' ]
                                          }
                                      ]
                                  },
                                  {
                                      'cells' => [
                                          {
                                              'text' => 'Goodbye',
                                              'data' => [ 'Goodbye' ]
                                          }
                                      ]
                                  }
                              ]
                          },
                          {
                              'headers' => [],
                              'rows'    => [
                                  {
                                      'cells' => [
                                          {
                                              'data' => [ '你好' ],
                                              'text' => '你好'
                                          }
                                      ]
                                  },
                                  {
                                      'cells' => [
                                          {
                                              'data' => [ '再見' ],
                                              'text' => '再見'
                                          }
                                      ]
                                  }
                              ]
                          }
                      ]
                  }
              ],
              nested_cell => {
                  'class'  => 'two-column-odd',
                  'nested' => undef,
                  'id'     => 'row-1',
                  'cells'  => [
                      {
                          'nested' => [
                              {
                                  'rows' => [
                                      {
                                          'cells' => [
                                              {
                                                  'text' => 'Hello',
                                                  'data' => [ 'Hello' ]
                                              }
                                          ]
                                      },
                                      {
                                          'cells' => [
                                              {
                                                  'data' => [ 'Goodbye' ],
                                                  'text' => 'Goodbye'
                                              }
                                          ]
                                      }
                                  ],
                                  'headers' => []
                              }
                          ],
                          'class' => 'facts'
                      }
                  ]
              },
          }
    );
  };

done_testing();

sub open_file {
      my $file = shift;

      open( my $fh, '<', $file ) or croak "could not open html: $file";
      my $html = do { local $/; <$fh> };
      close $fh;

      return $html;
}

sub run_tests {
      my $args = shift;

      my $t = HTML::TableContent->new();

      ok( $t->parse( $args->{html} ), "parse html into HTML::TableContent" );

      if ( my $headers = $args->{headers} ) {
          ok( $t->filter_tables( headers => $headers ) );
      }

      my $raw = $t->raw;

      if ( my $nested = $args->{nested_cell} ) {
          my $first_cell = $raw->[0]->{rows}->[0];
          is_deeply( $first_cell, $nested, "raw nested cell" );
      }

      is_deeply( $raw, $args->{raw_me}, "raw data structure as expected" );
}

1;
