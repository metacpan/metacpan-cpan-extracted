package MYDan::Collector::Stat::Call;

use strict;
use warnings;
use Carp;
use POSIX;

use Data::Dumper;

sub co
{
    my ( $this, @call, @stat, %call ) = shift;

    map{ $call{$1} = 1 if $_ =~ /^\{CALL\}\{([^}]+)\}/ }@_;

    push @call, [ 'CALL', 'exit', 'stderr' ];

    for my $call ( keys %call )
    {
        eval{
            my @data;
            confess "open: $!" unless open my $cmd, "$call |";
            while ( my $line = <$cmd> )
            {
                next unless defined $line;
                my @d = split /\s+/, $line;

                if( @d ) { push @data, \@d; }
                else
                {
                    push @stat, \@data if @data;
                    @data  =();
                }

            }
            push @stat, \@data if @data;
        };
        push @call, [ $call, $@? 1: 0, $@||'' ];
    }

    return @stat , \@call;
}

1;
