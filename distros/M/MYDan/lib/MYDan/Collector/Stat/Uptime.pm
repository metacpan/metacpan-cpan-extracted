package MYDan::Collector::Stat::Uptime;

use strict;
use warnings;
use Carp;
use POSIX;

use Data::Dumper;
use MYDan::Collector::Util;

sub co
{
    my ( $this, @stat ) = shift;

    push @stat, [ qw( UPTIME time uptime idle )];
    push @stat, [ 'value', time, split /\s+/, MYDan::Collector::Util::qx( 'cat /proc/uptime' )  ];

    return \@stat;
}

1;
