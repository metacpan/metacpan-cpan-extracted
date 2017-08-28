package MYDan::Collector::Stat::Proc;

use strict;
use warnings;
use Carp;
use POSIX;
use MYDan::Collector::Util;

my %eo = ( 
    'pcpu' => 1, 'pmem' => 1, 'sz'   => 1, 'rsz'  => 1,
    'vsz'  => 1, 'nlwp' => 1, 'etime'=> 1,
);

my ( $i, @eo, %eoi ) = 0;
map{ $eoi{$_} = ++ $i }
    @eo = qw( user ppid pcpu pmem sz rsz vsz nlwp state etime args );

sub co
{
    my ( $this, @jobs, @stat, @proc, %proc ) = @_;

    my $eo = join ',', @eo;
    my @ps = MYDan::Collector::Util::qx( "ps -eo pid,$eo" );

    my %index;
    my $i = 0;
    map{
         chomp;
         $_ =~ s/^\s+//;
         my $d = [  split /\s+/, $_,  1 + @eo ];
         push @stat, $d;
         $index{$d->[0]} = $i++;
    }@ps;

    $stat[0][0] = 'PS';

    push @proc, [ 'PROC', 'count', 'info',
            map{ $eo{$_} ? ( "min-$_", "avg-$_", "max-$_" ) : $_ } @eo 
    ];


    map{ $proc{$1} = 1 if $_ =~ /^\{PROC\}\{([^}]+)\}/ }@jobs;

    my %data;
    for my $jobs ( keys %proc )
    {
        my $data = $data{$jobs} = {};

        my %pids;
        if( $jobs =~ /^\s*\// && $jobs =~ /\/\s*$/ )
        {
            $jobs =~ s/^\s*\///;
            $jobs =~ s/\/\s*$//;
            map{ 
                warn "$_\n" if -t STDIN;
                $pids{$1} = 1 if $_ =~ /^\s*(\d+)/;
            }grep{ $_ =~ /$jobs/ }@ps;

        }
        else
        {
            my @pids = MYDan::Collector::Util::qx( $jobs );
            my $pids = join ',',@pids;

            map{ $pids{$_} = 1 }$pids =~ /(\d+)/g;
            
        }

        $data->{count} = 0;
        for ( keys %pids )
        {
            next unless my $i = $index{$_};
            $data->{count} ++;
            push @{$data->{info}}, $_;

            for my $t ( @eo )
            {
                my $v = $stat[$i][$eoi{$t}];

                if( $t eq 'etime')
                {
                    my @time = reverse split /[-:]/, $v;
                    while ( @time < 4 ) { push @time, 0 }
                    $v = 86400 * pop @time;
                    map { $v += $time[$_] * 60 ** $_ } 0 .. $#time;
                }
                unless( $eo{$t} )
                {
                    $data->{$t} = $v;
                    next;
                }
                map
                {
                    $data->{"$_-$t"} = $v unless defined $data->{"$_-$t"} 
                }qw( min max );
                $data->{"min-$t"} = $v if $data->{"min-$t"} > $v;
                $data->{"max-$t"} = $v if $data->{"max-$t"} < $v;
                $data->{"avg-$t"} += $v;
            }
        }
        
        map{ $data->{"avg-$_"} /= $data->{count} }grep{ $eo{$_} } keys %eo if $data->{count} > 1;
        $data->{info} = join ',', sort @{$data->{info}} if $data->{info};
    }

    map{
        my ( $k, @d ) = ( $_, $_, $data{$_}{count}, $data{$_}{info} );
        map{ push @d, $data{$k}{$proc[0][$_]} } 3.. @{$proc[0]} -1;
        push @proc, \@d;
    }keys %data;

    return ( \@stat, \@proc );
}

1;
