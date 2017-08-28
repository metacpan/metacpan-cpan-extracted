package MYDan::Collector::Stat::User;

use strict;
use warnings;
use Carp;
use POSIX;

use Data::Dumper;
use MYDan::Collector::Util;

sub co
{
    my ( $this, @stat ) = shift;


    my @data = MYDan::Collector::Util::qx( "w|sed '1d'" );
    return () if $? >> 8;

    for my $data ( @data )
    {
        chomp $data;
        push @stat, [ split /\s+/, $data, 8 ];

    }

    return \@stat;
}

1;
