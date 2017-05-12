# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::Simple tests => 4;

use Finance::ChartHist;

$c = Finance::ChartHist->new( symbols    => "BHP",
                              start_date => '2001-01-01',
                              end_date   => '2002-01-01',
                              width      => 680,
                              height     => 480
                            );
ok(defined($c));

## Check some of the private methods
($a, $b) = $c->_normalise_range(5.4, 6.8);
ok($a == 5 && $b == 7);
($a, $b) = $c->_normalise_range(5.4, 16.8);
ok($a == 4  && $b == 18);
($a, $b) = $c->_normalise_range(-5.4, 26.8);
ok($a == -10  && $b == 30);