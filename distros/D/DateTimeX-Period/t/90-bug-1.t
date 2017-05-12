#!/usr/bin/env perl

use warnings;
use strict;

use Test::More;
use Test::Exception;
use DateTimeX::Period qw();

# At the end of Thursday, 29 December 2011, Samoa continued directly to
# Saturday, 31 December 2011, skipping the entire calendar day of Friday
# 30 December 2011 ( source: http://en.wikipedia.org/wiki/Time_in_Samoa )

my $dt = DateTimeX::Period->from_epoch(
	epoch => 1325152800, # 2011-12-29T00:00:00
	time_zone => 'Pacific/Apia'
);

lives_ok{
	$dt->get_end('day')
} "Doesn't throw Runtime error if next day does not exist";

is(
	$dt->get_end('day')->ymd() . ' ' . $dt->get_end('day')->hms(),
	'2011-12-31 00:00:00',
	"29/12/2011 Follows 31/12/2011 in 'Pacific/Apia' timezone"
);

done_testing();
