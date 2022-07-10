# -*- perl -*-
use Test::More tests => 4;

use strict;
use warnings;

use JSON::JQ;

my $jq1 = JSON::JQ->new({ script => '.' });

my $input101 = 1651546351000;
my $input101_expected = 1651546351000;
is_deeply($jq1->process({ data => $input101 }), $input101_expected);

my $input102 = -$input101;
my $input102_expected = -$input101_expected;
is_deeply($jq1->process({ data => $input102 }), $input102_expected);

my $input103 = 1651546351000.1;
my $input103_expected = 1651546351000.1;
is_deeply($jq1->process({ data => $input103 }), $input103_expected);

my $input104 = -$input103;
my $input104_expected = -$input103_expected;
is_deeply($jq1->process({ data => $input104 }), $input104_expected);
