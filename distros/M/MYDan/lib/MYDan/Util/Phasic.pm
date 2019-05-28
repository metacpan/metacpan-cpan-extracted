package MYDan::Util::Phasic;

use warnings;
use strict;
use Carp;
use threads;
use Thread::Queue;
use Time::HiRes qw( time sleep alarm stat );

use MYDan::Util::Say;

=head1 SYNOPSIS

 use MYDan::Util::Phasic;

 my $phase = MYDan::Util::Phasic->new
 (
     src => \@src, dst => \@dst, quiesce => [],
     code => sub { .. }, weight => sub { return int .. }
 );

 $phase->run
 ( 
     retry => 3, timeout => 100, log => $handle, param => { .. },
 );

=cut
our ( $MAX, $POLL, $SPLIT ) = ( 128, 0.01, 0.5 );

sub new
{
    my ( $class, %self ) = splice @_;

    $self{weight} ||= sub { 0 };
    $self{quiesce} ||= [];

    for my $name ( qw( code weight ) )
    {
        my $code = $self{$name};
        confess "undefined/invalid $name" unless $code && ref $code eq 'CODE';
    }

    for my $name ( qw( src dst quiesce ) )
    {
        confess "undefined/invalid $name" unless my $node = $self{$name};
        $self{$name} = [ $node ] if ref $node ne 'ARRAY';
    }

    bless \%self, ref $class || $class
}

=head1 METHODS

=head3 run( %param )

The following parameters may be defined in %param.

 timeout : ( default 0 = no timeout ) number of retries.
 retry : ( default 0 = no retry ) number of retries.
 log : ( default STDERR ) file handle for logging.

=cut
sub run
{
    my $self = shift;
    my %run = ( retry => 0, timeout => 0, log => \*STDERR, @_ );

    my ( $retry, $log, $gave ) = delete @run{ qw( retry log gave ) };
    my $MULTI = ( $gave && $gave > 0 ) ? $gave - 1 : 2;

    my $timeout = $run{timeout};
    my ( $w8, $code ) = @$self{ 'weight', 'code' };

    $log = MYDan::Util::Say->new( $log );
    $run{log} = sub { $log->say( @_ ) };

    my ( @w8queue, %w8 ) = map { Thread::Queue->new() } 0, 1;
    my $thrc = ( sort { $a <=> $b } 0 + @{ $self->{dst}}, $MAX )[0];
    map{ $w8queue[0]->enqueue( $_ ) }@{ $self->{src} }, @{ $self->{dst} };

    my @queue = map { Thread::Queue->new() } 0, 1;
    $thrc ||= 1;
    for my $i ( 1 .. $thrc )
    {
        threads::async
        {
            while ( $w8queue[0]->pending() )
            {
                 my $hostname = $w8queue[0]->dequeue_nb( 1 );
                 next unless $hostname;
                 my $ipw8 = &$w8( $hostname );
                 $w8queue[1]->enqueue( $hostname, $ipw8 );
            }

            while ( 1 )
            {
                my ( $ok, $src, $dst, $info ) = 1;
                eval
                {
#                   local $SIG{ALRM} = sub { die "timeout\n" if $src };
                    ( $src, $dst ) = $queue[0]->dequeue( 2 );
                    $info = &$code( $src, $dst, %run );
                };
                if ( $@ ) { $ok = 0; $info = $@ }
                $queue[1]->enqueue( $src, $dst, $ok, $info );
            }
        }->detach;
    }

    my $count = @{ $self->{src} } + @{ $self->{dst} };
    my $split = int ( $SPLIT * $count );

    while( 1 )
    {
        my ( $h, $i ) = $w8queue[1]->dequeue( 2 );
        $w8{$h} = $i; $count --;
        last unless $count;
    }

    my %src = map { $_ => $w8{$_} } @{ $self->{src} };
    my %dst = map { $_ => $w8{$_} } @{ $self->{dst} };
    my %quiesce = map { $_ => 1 } @{ $self->{quiesce} };

    my ( %multi, %busy, %err ) = map{ $_ => $MULTI }keys %src;

    for ( my $now = time; %dst || %busy; sleep $POLL )
    {
        while ( $queue[1]->pending() )
        {
            my ( $src, $dst, $ok, $info ) = $queue[1]->dequeue_nb( 4 );
            delete @busy{ $src, $dst };

            $multi{$src} ++ if defined $src{$src};

            $src{$src} = $w8{$src} unless $quiesce{$src};

            if ( $ok )
            {
                unless( $quiesce{$dst} )
                { 
                    $src{$dst} = $w8{$dst};
                    $multi{$dst} = $MULTI;
                }
            }
            elsif ( $err{$dst} ++ < $retry )
            {
                $dst{$dst} = $w8{$dst};
            }
            else
            {
                delete $dst{$dst};
            }

            $log->say( "$dst <= $src: $info" );
        }

        if ( $timeout && time - $now > $timeout )
        {
            map{
                unless( defined $multi{$_} )
                {
                    $err{$_} = $retry +1;
                    $log->say( "$_: timeout" );
                }
            }keys %busy, keys %dst; last;
        }
        elsif ( %src && %dst )
        {
            my $dst = ( keys %dst )[ int( rand time ) % 2 ? -1 : 0 ];
            my $w8 = $busy{$dst} = delete $dst{$dst};
            my %dist = map { $_ => abs( $w8{$_} - $w8 ) }keys %src;
            my $src = ( sort { $dist{$a} <=> $dist{$b} } keys %dist )[0];

            $busy{$src} = delete $src{$src};
	    $log->say( "$src => $dst: RSYNC" );
            $queue[0]->enqueue( $src, $dst );
        }
        elsif( $MULTI && %dst && ( scalar keys %dst ) > $split ) 
        {
            next unless my @multi = grep{ $multi{$_} > 0 }keys %multi;

            my $dst = ( keys %dst )[ int( rand time ) % 2 ? -1 : 0 ];
            my $w8 = $busy{$dst} = delete $dst{$dst};
            my %dist = map { $_ => abs( $w8{$_} - $w8 ) }@multi;
            my $src = ( sort { $dist{$a} <=> $dist{$b} } keys %dist )[0];

            $multi{$src} --;
	    $log->say( "$src => $dst: MULTI" );
            $queue[0]->enqueue( $src, $dst );
        }
    }

    $self->{failed} = [ grep { $err{$_} > $retry } keys %err ];
    return $self;
}

sub failed
{
    my $self = shift;
    my $failed = $self->{failed};
    return wantarray ? @$failed : $failed;
}

1;
