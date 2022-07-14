# -*- perl -*-
use Test::More tests => 4;
use Test::Number::Delta;

use strict;
use warnings;

use JSON::JQ;

my $jq1 = JSON::JQ->new({ script => '.' });

my $input101 = 1651546351000;
my $input101_expected = 1651546351000;
(my $input101_got) = $jq1->process({ data => $input101 });
delta_ok($input101_got, $input101_expected);

my $input102 = -$input101;
my $input102_expected = -$input101_expected;
(my $input102_got) = $jq1->process({ data => $input102 });
delta_ok($input102_got, $input102_expected);

my $input103 = 1651546351000.1;
my $input103_expected = 1651546351000.1;
(my $input103_got) = $jq1->process({ data => $input103 });
delta_ok($input103_got, $input103_expected);

my $input104 = -$input103;
my $input104_expected = -$input103_expected;
(my $input104_got) = $jq1->process({ data => $input104 });
delta_ok($input104_got, $input104_expected);
