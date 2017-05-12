package MColPro::Dispatch;

=head1 NAME

Collect - MColPro Data collector

=cut

use strict;
use warnings;
use Data::Dumper;

use Carp;
use Thread::Queue;
use Time::HiRes qw( time sleep alarm );
use MColPro::Util::Serial qw( serial unserial deepcopy );

use lib 'lib';
use MColPro::TimeList;

sub dispatch
{
    my ( $from, $to ) = @_;

    my $queue = MColPro::TimeList->new();

    while(1)
    {
        ## put into timelist
        my $max = 20;
        while( $max && ( my $task = $from->dequeue_nb() ) )
        {
            $queue->put( $task );
            $max--;
        }

        ## get from timelist
        for my $t ( @{ $queue->get() } )
        {
            $to->enqueue( $t->[1] );
        }

        sleep 0.5;
    }
}

1;
