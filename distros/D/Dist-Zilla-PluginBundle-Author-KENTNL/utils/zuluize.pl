#!/usr/bin/env perl

# Replace DZIL style date-time with W3CDTF style while keeping the time right.
use strict;
use warnings;

use DateTime::Format::Strptime;

my $strp = DateTime::Format::Strptime->new(
  pattern   => '%Y-%m-%d %H:%M:%S',
  time_zone => 'Pacific/Auckland',
);
while (<>) {
  if ( $_ =~ qr{(^[\d.]+\s+)(\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}) Pacific/Auckland} ) {
    my $prelude = $1;
    my $date    = $2;
    print $prelude, $strp->parse_datetime($date)->set_time_zone('UTC'), "Z\n";
  }
  else {
    print $_;
  }
}

