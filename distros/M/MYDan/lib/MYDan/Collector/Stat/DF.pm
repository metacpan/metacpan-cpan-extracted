package MYDan::Collector::Stat::DF;

use strict;
use warnings;
use Carp;
use POSIX;

use Data::Dumper;
use MYDan::Collector::Util;

sub co
{
    my ( @stat, %data );
    eval{
        for ( '-l', '-i' )
        {
            die "exec df $_ fail.\n" unless my @df 
                = MYDan::Collector::Util::qx( "LANG=en df $_ 2>/dev/null" );
            for my $df ( map { [ ( split /\s+/, $_, 7 )[ 5, 1..4 ] ] } @df )
            {
                next unless my $t = shift @$df;
                $data{$_}{$t} = $df;
                map { $_ = $1 if $_ =~ /(\d+)%/ } @$df;
            }
        }

        map { push @{$data{'-l'}{$_}}, @{delete $data{'-i'}{$_}}; }keys %{$data{'-l'}};
        push @stat, [ 'DF', @{delete $data{'-l'}{Mounted}} ];
        map{ push @stat, [ $_, @{$data{'-l'}{$_}} ]; }keys %{$data{'-l'}};
    };

    if( $@ ) { warn "DF:$@\n"; return (); }

    return \@stat;
}

1;
