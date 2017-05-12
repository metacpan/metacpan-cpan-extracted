#!/usr/bin/perl -w
use strict;

# $Id: Log-Statistics.t 48 2007-03-24 00:00:22Z root $

#
#_* Libraries
#

use Test::More 'no_plan';
#use Test::More tests => 3;
use Data::Dumper;
use File::Temp qw/ :POSIX /;

require Log::Statistics;

use Log::Log4perl qw(:resurrect :easy);
Log::Log4perl->easy_init($ERROR);

BEGIN { use_ok('Log::Statistics') };

#
#_* Run Tests
#
for my $index ( 0 .. 9 ) {
    my $log;

    my $data = get_test_case_data( $index );

    ok(
        $log = Log::Statistics->new(),
        ">>> $index: " . $data->{'description'} . " <<<"
    );

    for my $field ( @{ $data->{'register_fields'} } ) {
        my ( $column, $name ) = split /:/, $field;
        my $test_text = "$index: registering $name field";
        ok(
            $log->register_field( $name, $column ),
            $test_text
        );
    }

    for my $field ( @{ $data->{'fields'} } ) {
        my ( $column, $name, $thresholds ) = split /:/, $field;
        my $test_text = "$index: adding $name field";
        $test_text .= " (thresholds = $thresholds)" if $thresholds;
        ok(
            $log->add_field( $column, $name, $thresholds ),
            $test_text
        );
    }

    for my $group ( @{ $data->{'groups'} } ) {
        ok(
            $log->add_group( [ split /:/, $group ] ),
            "$index: adding group: $group"
        );
    }

    if ( $data->{'line_regexp'} ) {
        ok(
            $log->add_line_regexp( $data->{'line_regexp'} ),
            "$index: adding line regexp: " . $data->{'line_regexp'}
        );
    }

    if ( $data->{'time_regexp'} ) {
        ok(
            $log->add_time_regexp( $data->{'time_regexp'} ),
            "$index: adding time regexp: " . $data->{'time_regexp'}
        );
    }

    ok(
        $log->parse_text( $data->{'text'} ),
        "$index: Parsing log text"
    );

    #print "\n\nEXPECTED\n";
    #print Dumper $data->{'expected'};
    #print "\n\nGOT\n";
    #print Dumper $log->{'data'};
    is_deeply(
        $log->{'data'},
        $data->{'expected'},
        "$index: testing data after parse_text"
    );

    my ($fh, $tmpfile) = tmpnam();

    ok(
        $log->save_data( $tmpfile ),
        "$index: Saving data to file: $tmpfile"
    );

    my $log2 = Log::Statistics->new();
    is_deeply(
        $log2->read_data( $tmpfile ),
        $log->{'data'},
        "$index: Reading data in from data file and comparing to original data"
    ) or die;
    unlink $tmpfile;

    if ( $data->{'xml'} ) {
        is(
            $log->get_xml(),
            $data->{'xml'},
            "$index: generating xml report"
        );

    }
}


# utime testing

{
    my $log = Log::Statistics->new();

    is(
        $log->get_utime_from_string( "Wed Jan 18 19:17:14 CST 2006" ),
        1137633434,
        "testing parsing unix time from date string"
    );

}


#
#_* Test Case Data
#


sub get_test_case_data {
    my ( $case ) = @_;

    my $text_1 = <<EOL;
SUCCESS, mytrans1.do, 101, 2006/01/15 00:06:22:310
# test comment
SUCCESS, mytrans2.do, 102, 2006/01/15 00:06:23:310
SUCCESS, mytrans1.do, 103, 2006/01/15 00:06:23:310
SUCCESS, mytrans2.do, 104, 2006/01/15 00:06:23:310
SUCCESS, mytrans1.do, 105, 2006/01/15 00:06:24:110
SUCCESS, mytrans2.do, 106, 2006/01/15 00:06:24:210
SUCCESS, mytrans1.do, 107, 2006/01/15 00:06:24:310
FAILURE, mytrans2.do, 108, 2006/01/15 00:06:24:410
FAILURE, mytrans1.do, 109, 2006/01/15 00:06:24:510
EOL

    my $test_case_data = [
        {
            'description' => "basic simple test case, two fields and duration",
            'fields' => [ qw( 2:duration 0:status 1:transaction ) ],
            'text' => $text_1,
            'expected' => {
                'fields' => {
                    'status' => {
                        'FAILURE' => {
                            'count' => 2,
                            'duration' => 217
                        },
                        'SUCCESS' => {
                            'count' => 7,
                            'duration' => 728
                        }
                    },
                    'transaction' => {
                        'mytrans2.do' => {
                            'count' => 4,
                            'duration' => 420
                        },
                        'mytrans1.do' => {
                            'count' => 5,
                            'duration' => 525
                        }
                    },
                },
                'total' => {
                    'count' => 9,
                    'duration' => 945
                }
            },
            'xml' =><<EOXML,
<?xml version="1.0" standalone="yes"?>

<log-statistics>
  <fields name="status">
    <status name="FAILURE" count="2" duration="217" duration_average="108.5000" />
    <status name="SUCCESS" count="7" duration="728" duration_average="104.0000" />
  </fields>
  <fields name="transaction">
    <transaction name="mytrans1.do" count="5" duration="525" duration_average="105.0000" />
    <transaction name="mytrans2.do" count="4" duration="420" duration_average="105.0000" />
  </fields>
</log-statistics>
EOXML
        },
        {
            "description" => "two fields with duration and group",
            'fields' => [ qw( 2:duration 0:status 1:transaction ) ],
            'groups'  => [ qw( status:transaction ) ],
            'text' => $text_1,
            'expected' => {
                'fields' => {
                    'status' => {
                        'FAILURE' => {
                            'count' => 2,
                            'duration' => 217
                        },
                        'SUCCESS' => {
                            'count' => 7,
                            'duration' => 728
                        }
                    },
                    'transaction' => {
                        'mytrans2.do' => {
                            'count' => 4,
                            'duration' => 420
                        },
                        'mytrans1.do' => {
                            'count' => 5,
                            'duration' => 525
                        }
                    },
                },
                'groups' => {
                    'status-transaction' => {
                        'FAILURE' => {
                                'mytrans2.do' => {
                                    'count' => 1,
                                    'duration' => 108
                                },
                                'mytrans1.do' => {
                                    'count' => 1,
                                    'duration' => 109
                                }
                        },
                        'SUCCESS' => {
                                'mytrans2.do' => {
                                    'count' => 3,
                                    'duration' => 312
                                },
                                'mytrans1.do' => {
                                    'count' => 4,
                                    'duration' => 416
                                }
                        }
                    },
                },
                'total' => {
                    'count' => 9,
                    'duration' => 945
                }
            },
            'xml' =><<EOXML,
<?xml version="1.0" standalone="yes"?>

<log-statistics>
  <fields name="status">
    <status name="FAILURE" count="2" duration="217" duration_average="108.5000" />
    <status name="SUCCESS" count="7" duration="728" duration_average="104.0000" />
  </fields>
  <fields name="transaction">
    <transaction name="mytrans1.do" count="5" duration="525" duration_average="105.0000" />
    <transaction name="mytrans2.do" count="4" duration="420" duration_average="105.0000" />
  </fields>
  <groups name="status-transaction">
    <status name="FAILURE">
      <transaction name="mytrans1.do" count="1" duration="109" duration_average="109.0000" />
      <transaction name="mytrans2.do" count="1" duration="108" duration_average="108.0000" />
    </status>
    <status name="SUCCESS">
      <transaction name="mytrans1.do" count="4" duration="416" duration_average="104.0000" />
      <transaction name="mytrans2.do" count="3" duration="312" duration_average="104.0000" />
    </status>
  </groups>
</log-statistics>
EOXML
        },
        {
            'description' => "one field with thresholds and one field without",
            'fields' => [ qw( 2:duration 0:status:103|106|112 1:transaction ) ],
            'text' => $text_1,
            'expected' => {
                'fields' => {
                    'status' => {
                        'FAILURE' => {
                            'count' => 2,
                            'duration' => 217,
                            'th_2' => 2
                        },
                        'SUCCESS' => {
                            'count' => 7,
                            'duration' => 728,
                            'th_0' => 2,
                            'th_1' => 3,
                            'th_2' => 2
                        }
                    },
                    'transaction' => {
                        'mytrans2.do' => {
                            'count' => 4,
                            'duration' => 420
                        },
                        'mytrans1.do' => {
                            'count' => 5,
                            'duration' => 525
                        }
                    },
                },
                'total' => {
                    'count' => 9,
                    'duration' => 945
                }
            },
            'xml' =><<EOXML,
<?xml version="1.0" standalone="yes"?>

<log-statistics>
  <fields name="status">
    <status name="FAILURE" count="2" duration="217" duration_average="108.5000" th_2="2" />
    <status name="SUCCESS" count="7" duration="728" duration_average="104.0000" th_0="2" th_1="3" th_2="2" />
  </fields>
  <fields name="transaction">
    <transaction name="mytrans1.do" count="5" duration="525" duration_average="105.0000" />
    <transaction name="mytrans2.do" count="4" duration="420" duration_average="105.0000" />
  </fields>
</log-statistics>
EOXML
        },
        {
            'description' => "basic simple test case plus time field",
            'fields' => [ qw( 2:duration 3:time ) ],
            'text' => $text_1,
            'time_regexp' => '\s(\d\d\:\d\d:\d\d)\:',
            'expected' => {
                'fields' => {
                    'time' => {
                        '00:06:23' => {
                            'count' => 3,
                            'duration' => 309
                        },
                        '00:06:22' => {
                            'count' => 1,
                            'duration' => 101
                        },
                        '00:06:24' => {
                            'count' => 5,
                            'duration' => 535
                        }
                    },
                },
                'total' => {
                    'count' => 9,
                    'duration' => 945
                }
            },
            'xml' =><<EOXML,
<?xml version="1.0" standalone="yes"?>

<log-statistics>
  <fields name="time">
    <time name="00:06:22" count="1" duration="101" duration_average="101.0000" />
    <time name="00:06:23" count="3" duration="309" duration_average="103.0000" />
    <time name="00:06:24" count="5" duration="535" duration_average="107.0000" />
  </fields>
</log-statistics>
EOXML
        },
        {
            'description' => "two fields plus time field and time field group",
            'fields' => [ qw( 0:status 2:duration 3:time ) ],
            'groups'  => [ qw( status:time ) ],
            'text' => $text_1,
            'time_regexp' => '\s(\d\d\:\d\d:\d\d)\:',
            'expected' => {
                'fields' => {
                    'time' => {
                        '00:06:23' => {
                            'count' => 3,
                            'duration' => 309
                        },
                        '00:06:22' => {
                            'count' => 1,
                            'duration' => 101
                        },
                        '00:06:24' => {
                            'count' => 5,
                            'duration' => 535
                        }
                    },
                    'status' => {
                        'FAILURE' => {
                            'count' => 2,
                            'duration' => 217,
                        },
                        'SUCCESS' => {
                            'count' => 7,
                            'duration' => 728,
                        }
                    },
                },
                'total' => {
                    'count' => 9,
                    'duration' => 945
                },
                'groups' => {
                    'status-time' => {
                        'FAILURE' => {
                            '00:06:24' => {
                                'count' => 2,
                                'duration' => 217
                            }
                        },
                        'SUCCESS' => {
                            '00:06:23' => {
                                'count' => 3,
                                'duration' => 309
                            },
                            '00:06:22' => {
                                'count' => 1,
                                'duration' => 101
                            },
                            '00:06:24' => {
                                'count' => 3,
                                'duration' => 318
                            }
                        }
                    },
                },
            },
            'xml' =><<EOXML,
<?xml version="1.0" standalone="yes"?>

<log-statistics>
  <fields name="status">
    <status name="FAILURE" count="2" duration="217" duration_average="108.5000" />
    <status name="SUCCESS" count="7" duration="728" duration_average="104.0000" />
  </fields>
  <fields name="time">
    <time name="00:06:22" count="1" duration="101" duration_average="101.0000" />
    <time name="00:06:23" count="3" duration="309" duration_average="103.0000" />
    <time name="00:06:24" count="5" duration="535" duration_average="107.0000" />
  </fields>
  <groups name="status-time">
    <status name="FAILURE">
      <time name="00:06:24" count="2" duration="217" duration_average="108.5000" />
    </status>
    <status name="SUCCESS">
      <time name="00:06:22" count="1" duration="101" duration_average="101.0000" />
      <time name="00:06:23" count="3" duration="309" duration_average="103.0000" />
      <time name="00:06:24" count="3" duration="318" duration_average="106.0000" />
    </status>
  </groups>
</log-statistics>
EOXML
        },
        {
            "description" => "two grouped fields with duration and time",
            'fields' => [ qw( 2:duration 0:status 1:transaction 3:time ) ],
            'time_regexp' => '\s(\d\d\:\d\d:\d\d)\:',
            'groups'  => [ qw( status:transaction status:time ) ],
            'text' => $text_1,
            'expected' => {
                'fields' => {
                    'status' => {
                        'FAILURE' => {
                            'count' => 2,
                            'duration' => 217
                        },
                        'SUCCESS' => {
                            'count' => 7,
                            'duration' => 728
                        }
                    },
                    'transaction' => {
                        'mytrans2.do' => {
                            'count' => 4,
                            'duration' => 420
                        },
                        'mytrans1.do' => {
                            'count' => 5,
                            'duration' => 525
                        }
                    },
                    'time' => {
                        '00:06:23' => {
                            'count' => 3,
                            'duration' => 309
                        },
                        '00:06:22' => {
                            'count' => 1,
                            'duration' => 101
                        },
                        '00:06:24' => {
                            'count' => 5,
                            'duration' => 535
                        }
                    },
                },
                'groups' => {
                    'status-transaction' => {
                        'FAILURE' => {
                            'mytrans2.do' => {
                                'count' => 1,
                                'duration' => 108
                            },
                            'mytrans1.do' => {
                                'count' => 1,
                                'duration' => 109
                            }
                        },
                        'SUCCESS' => {
                            'mytrans2.do' => {
                                'count' => 3,
                                'duration' => 312
                            },
                            'mytrans1.do' => {
                                'count' => 4,
                                'duration' => 416
                            }
                        }
                    },
                    'status-time' => {
                        'FAILURE' => {
                            '00:06:24' => {
                                'count' => 2,
                                'duration' => 217
                            }
                        },
                        'SUCCESS' => {
                            '00:06:23' => {
                                'count' => 3,
                                'duration' => 309
                            },
                            '00:06:22' => {
                                'count' => 1,
                                'duration' => 101
                            },
                            '00:06:24' => {
                                'count' => 3,
                                'duration' => 318
                            }
                        }
                    },
                },
                'total' => {
                    'count' => 9,
                    'duration' => 945
                }
            },
            'xml' =><<EOXML,
<?xml version="1.0" standalone="yes"?>

<log-statistics>
  <fields name="status">
    <status name="FAILURE" count="2" duration="217" duration_average="108.5000" />
    <status name="SUCCESS" count="7" duration="728" duration_average="104.0000" />
  </fields>
  <fields name="time">
    <time name="00:06:22" count="1" duration="101" duration_average="101.0000" />
    <time name="00:06:23" count="3" duration="309" duration_average="103.0000" />
    <time name="00:06:24" count="5" duration="535" duration_average="107.0000" />
  </fields>
  <fields name="transaction">
    <transaction name="mytrans1.do" count="5" duration="525" duration_average="105.0000" />
    <transaction name="mytrans2.do" count="4" duration="420" duration_average="105.0000" />
  </fields>
  <groups name="status-time">
    <status name="FAILURE">
      <time name="00:06:24" count="2" duration="217" duration_average="108.5000" />
    </status>
    <status name="SUCCESS">
      <time name="00:06:22" count="1" duration="101" duration_average="101.0000" />
      <time name="00:06:23" count="3" duration="309" duration_average="103.0000" />
      <time name="00:06:24" count="3" duration="318" duration_average="106.0000" />
    </status>
  </groups>
  <groups name="status-transaction">
    <status name="FAILURE">
      <transaction name="mytrans1.do" count="1" duration="109" duration_average="109.0000" />
      <transaction name="mytrans2.do" count="1" duration="108" duration_average="108.0000" />
    </status>
    <status name="SUCCESS">
      <transaction name="mytrans1.do" count="4" duration="416" duration_average="104.0000" />
      <transaction name="mytrans2.do" count="3" duration="312" duration_average="104.0000" />
    </status>
  </groups>
</log-statistics>
EOXML
        },
        {
            'description' => "basic simple test case, two fields, no duration",
            'fields' => [ qw( 0:status 1:transaction ) ],
            'text' => $text_1,
            'expected' => {
                'fields' => {
                    'status' => {
                        'FAILURE' => {
                            'count' => 2,
                        },
                        'SUCCESS' => {
                            'count' => 7,
                        }
                    },
                    'transaction' => {
                        'mytrans2.do' => {
                            'count' => 4,
                        },
                        'mytrans1.do' => {
                            'count' => 5,
                        }
                    },
                },
                'total' => {
                    'count' => 9,
                }
            },
        },
        {
            'description' => "custom apache log format",
            'fields' => [ qw( 0:ip 1:time 2:transaction 3:status ) ],
            'line_regexp' => '^\".*?\"\s+([\d\.]+).*?\:(\d\d\:\d\d).*?\".*?\s[^\s]+\s+([^\s]+).*?\"\s(\d+)\s+\d+\s+(\d+)',
            'text' => <<EOF,
"10.0.0.1 https" 10.0.0.1 - - [15/Jan/2006:23:46:39 -0800] "host1.domain.abc GET / HTTP/1.0" 301 366 6358 - - - text/html "-"
"10.0.0.2 https" 10.0.0.2 - - [15/Jan/2006:23:46:49 -0800] "host2.domain.abc GET /app/servlet/xyz HTTP/1.0" 200 302 6358 - - - text/xml "-"
"10.0.0.1 https" 10.0.0.1 - - [15/Jan/2006:23:46:39 -0800] "host1.domain.abc GET / HTTP/1.0" 200 366 6358 - - - text/html "-"
"10.0.0.2 https" 10.0.0.2 - - [15/Jan/2006:23:46:49 -0800] "host2.domain.abc GET /app/servlet/xyz HTTP/1.0" 200 302 6358 - - - text/xml "-"
EOF
            'expected' => {
                'fields' => {
                    'status' => {
                        '200' => {
                            'count' => 3
                        },
                        '301' => {
                            'count' => 1
                        }
                    },
                    'time' => {
                        '23:46' => {
                            'count' => 4
                        }
                    },
                    'ip' => {
                        '10.0.0.2' => {
                            'count' => 2
                        },
                        '10.0.0.1' => {
                            'count' => 2
                        }
                    },
                    'transaction' => {
                        '/app/servlet/xyz' => {
                            'count' => 2
                        },
                        '/' => {
                            'count' => 2
                        }
                    },
                },
                'total' => {
                    'count' => 4
                }
            },
        },
        {
            "description" => "no fields with duration and group",
            'register_fields' => [ qw( 2:duration 0:status 1:transaction ) ],
            'groups'  => [ qw( status:transaction ) ],
            'text' => $text_1,
            'expected' => {
                'groups' => {
                    'status-transaction' => {
                        'FAILURE' => {
                                'mytrans2.do' => {
                                    'count' => 1,
                                    'duration' => 108
                                },
                                'mytrans1.do' => {
                                    'count' => 1,
                                    'duration' => 109
                                }
                        },
                        'SUCCESS' => {
                                'mytrans2.do' => {
                                    'count' => 3,
                                    'duration' => 312
                                },
                                'mytrans1.do' => {
                                    'count' => 4,
                                    'duration' => 416
                                }
                        }
                    },
                },
                'total' => {
                    'count' => 9,
                    'duration' => 945
                }
            },
        },
        {
            "description" => "no fields with duration and three fields grouped",
            'register_fields' => [ qw( 2:duration 0:status 1:transaction 3:time ) ],
            'groups'  => [ qw( status:time:transaction ) ],
            'time_regexp' => '\s(\d\d\:\d\d:\d\d)\:',
            'text' => $text_1,
            'expected' => {
                'groups' => {
                    'status-time-transaction' => {
                        'FAILURE' => {
                            '00:06:24' => {
                                'mytrans2.do' => {
                                    'count' => 1,
                                    'duration' => 108
                                },
                                'mytrans1.do' => {
                                    'count' => 1,
                                    'duration' => 109
                                }
                            }
                        },
                        'SUCCESS' => {
                            '00:06:23' => {
                                'mytrans2.do' => {
                                    'count' => 2,
                                    'duration' => 206
                                },
                                'mytrans1.do' => {
                                    'count' => 1,
                                    'duration' => 103
                                }
                            },
                            '00:06:22' => {
                                'mytrans1.do' => {
                                    'count' => 1,
                                    'duration' => 101
                                }
                            },
                            '00:06:24' => {
                                'mytrans2.do' => {
                                    'count' => 1,
                                    'duration' => 106
                                },
                                'mytrans1.do' => {
                                    'count' => 2,
                                    'duration' => 212
                                }
                            }
                        }
                    },
                },
                'total' => {
                    'count' => 9,
                    'duration' => 945
                }
            },
        },
    ];

    return $test_case_data->[$case];
}

