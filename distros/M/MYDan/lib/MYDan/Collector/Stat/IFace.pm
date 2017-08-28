package MYDan::Collector::Stat::IFace;

use strict;
use warnings;
use Carp;
use POSIX;

use Data::Dumper;
use MYDan::Collector::Util;

my $isvm;
BEGIN{
    $isvm = MYDan::Collector::Util::qx( 'dmidecode' ) =~ /No SMBIOS nor DMI entry point found, sorry\./ ? 1 : 0;
};


sub co
{
    my ( $this, @stat ) = shift;

    push @stat, [ qw( IFACE speed ) ];
    return \@stat if $isvm;
    my %eth = map { split /\s+/, $_, 2 } MYDan::Collector::Util::qx( 'ifconfig | grep ^eth' );

    for my $iface ( keys %eth )
    {
        my $info = MYDan::Collector::Util::qx( "ethtool $iface | grep Speed" );
        push @stat, [ $iface, $info && $info =~ /:\s(\d+)\D+/ ? $1 : -1 ];
    }

    return \@stat;
}

1;
