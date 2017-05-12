# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::Simple tests => 11;

use Finance::ChartHist;
ok(1); # If we made it this far, we're ok.

#########################

# Insert your test code below, the Test module is use()ed here so read
# its man page ( perldoc Test ) for help writing this test script.

$c = Finance::ChartHist->new( symbols    => "BHP",
                              start_date => '2001-01-01',
                              end_date   => '2002-01-01',
                              width      => 680,
                              height     => 480
                            );
ok(defined($c));
ok(ref $c eq 'Finance::ChartHist');

ok($c->create_chart());

##
## Check that we create the file
##
$c->save_chart('test5_chart.png', 'png');
ok(-e 'test5_chart.png');

##
## Test the various required parameters
##
eval{ $c = Finance::ChartHist->new( start_date => '1996-01-01',
									end_date => '2002-01-01'
							      );
};
ok($@ =~ m/Must provide symbols/);

eval{ $c = Finance::ChartHist->new( symbols => "BHP",
									end_date => '2002-01-01'
							      );
};
ok($@ =~ m/Must provide start_date/);

eval{ $c = Finance::ChartHist->new( symbols => "BHP",
									start_date => '2001-01-01'
							      );
};
ok($@ =~ m/Must provide end_date/);


## Testing multiple symbols
$c = Finance::ChartHist->new( symbols    => [qw(MSFT AAPL)],
                              start_date => '2002-01-01',
                              end_date   => '2002-02-01',
                              width      => 680,
                              height     => 480
                            );
ok(defined($c) and ref $c eq 'Finance::ChartHist');

## Create the chart with multiple symbols
ok($c->create_chart);

$c->save_chart('multiple.png', 'png');
ok(-e 'multiple.png');

