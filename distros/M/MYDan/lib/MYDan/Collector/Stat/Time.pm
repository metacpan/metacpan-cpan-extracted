package MYDan::Collector::Stat::Time;

use strict;
use warnings;
use Carp;
use POSIX;

sub co
{
    local $/ = "\n";

    my $time = time;
    my %time = ( local => [ localtime $time ], utc => [ gmtime $time ] );
    my @fmt = qw( a A b B c C d D e F g G h H I
        j k l m M p P r R s S T u U V w W x X y Y z Z );

    while ( my ( $key, $time ) = each %time )
    {
        unshift @$time, $key, map { POSIX::strftime '%' . $_, @$time } @fmt;
    }

    return [
         [ 'TIME', ( map { '_' . $_ } @fmt ),
           qw( sec min hour mday mon year wday yday dst ) ], values %time
     ];
}

1;
