#!usr/bin/perl
#
# Class  : Ham::Packet::DXSpider
# Purpose: Provides a remote interface to the DXSpider DX Cluster software. 
# Author : Bruce James (custard@cpan.org)
# Date   : 13th June 2025

package Ham::Packet::DXSpider;

use strict;
use warnings;
use IO::Handle;
use IO::Socket;
use POSIX;
use Moose;

our $VERSION="0.05";

=pod

=head1 NAME

Ham::Packet::DXSpider - Receives DX Spots from the DXCluster

=head1 SYNOPSIS

    # Construct object using address and optional port  
    my $dx=Ham::Packet::DXSpider->new( 
        callsign => 'your callsign', 
        address => 'dxcluster address', 
        port => 'port', 
    );

    # Construct object using supplied IO::Handle
    my $dx=Ham::Packet::DXSpider->new( 
        callsign => 'your callsign', 
        handle => IO::Handle 
    );

    # Set a handler for received private messages
    $dx->addPrivateMessageHandler( sub {
        my %args=@_;
        my $from=       $args{from} || '';
        my $to=         $args{to}       || '';
        my $body=       $args{body}     || 'no message';
        my $subject=    $args{subject}  || 'no subject';
        my $time=       $args{time}     || gmtime(time());
    } );

    # Set a handler for received DX messages
    $dx->addDXMessageHandler( sub {
        my %args=@_;
        my $from=       $args{from};
        my $frequency=  $args{frequency};
        my $message=    $args{message};
        my $heard=      $args{heard};
        my $time=       $args{time};
        my $locator=    $args{locator};
    } );

    # Add a handler for collecting statistics on DX spots received.
    $dx->addStatsHandler( sub {
        my %args=@_;
        my $from=       $args{from};
        my $freq=       $args{frequency};
        my $message=    $args{message};
        my $heard=      $args{heard};
        my $time=       $args{time};
        my $locator=    $args{locator};
    } );

    # Send a message
    $dx->sendPrivate( $to, $subject, $message );

    $dx->start();

=head1 DESCRIPTION

=head2 CONSTRUCTOR

new( callsign => 'your callsign', address => 'dxcluster address', port => 'port', handle => IO::Handle );

Create a new DXSpider object for the specified callsign. If address and optionally port are
specified, this will also open the connection to the DXSPIDER server.

Address can also be an already open IO::Handle object, in which case port becomes meaningless.

=head2 METHODS

=cut


has 'callsign' => (is=>'ro');
has 'address'  => (is=>'ro');
has 'handle'   => (is=>'rw');
has 'port'     => (is=>'ro');

has 'private_message_handler' => (is=>'rw', default => sub { [] } );
has 'dx_message_handler'      => (is=>'rw', default => sub { [] } );
has 'stats_handler'           => (is=>'rw', default => sub { [] } );

has 'pending_messages'        => (is=>'rw', default => sub { [] } );


=head2 BUILD()

Moose builder. Called after construction. Opens the handle if necessary.

=cut
sub BUILD {
    my $self = shift;
    
    $self->open();
}


=head2 open()

Opens a connection to a DXSPIDER server located at the address and port specified.
Address can also be an already open IO::Handle object, in which case port becomes meaningless.

=cut
sub open {
    my $self=shift;

    return if ( ref($self->handle) && ($self->handle->isa( 'IO::Handle' )));
    if ($self->address) {
        $self->handle( IO::Socket::INET->new(   
            PeerAddr => $self->address,
            PeerPort => $self->port
        ));
    }
}


=head2 addStatsHandler( $codeRef )

Adds a code reference to a function that can be used to collect statistics of the
received DX spot messages. Only DX spot messages will be sent to this handler.

Handlers are added to a list and will be called in turn when a new DX spot message arrives.

=cut
sub addStatsHandler {
    my $self=   shift;
    my $handler=    shift;

    return unless( ref($handler) eq 'CODE' );

    push( @{$self->stats_handler}, $handler );

    return $handler;
}

=head2 addDXMessageHandler( $codeRef )

Adds a code reference to a function that handles DX spot messages.
Handlers are added to a list and will be called in turn when a DX spot message arrives.

=cut
sub addDXMessageHandler {
    my $self=   shift;
    my $handler=    shift;
    return unless( ref($handler) eq 'CODE' );

    push( @{$self->dx_message_handler}, $handler );

    return $handler;
}

=head2 addPrivateMessageHandler( $codeRef )

Adds a code reference to a function that handles Private messages directed to the logged
in callsign.
Handlers are added to a list and will be called in turn when a new message arrives.

=cut
sub addPrivateMessageHandler {
    my $self=   shift;
    my $handler=    shift;
    return unless( ref($handler) eq 'CODE' );

    push( @{$self->private_message_handler}, $handler );

    return $handler;
}

=head2 start()

Continuously polls the DXSPIDER for new events. Returns if the handle for the connection
closes or becomes undefined for whatever reason.

=cut
sub start {
    # Continuously poll the handle and process responses
    my $self=   shift;

    while ( $self->{handle} ) {
        $self->process( $self->{handle} );
    }

    return $self->{handle};
}

=head2 poll()

Polls the DXSPIDER once for a new event. This will block until something is received and the
current transaction is completed.

TODO: Probably would be a candidate for a timeout when I get time.

=cut
sub poll {
    # Poll the handle once, and process only that response.
    my $self=   shift;

    if ( $self->{handle} ) {
        $self->process( $self->{handle} );
    }
    
    return $self->{handle};
}

=head2 sendPrivate( $to, $subject, $body )

Sends a private message to the callsign specified.

=cut
sub sendPrivate {
    # Queues a private message for sending.
    my $self=   shift;
    my $to=     shift;
    my $subject=    shift;
    my $body=   shift;

    push @{$self->pending_messages}, {
        to =>       $to,
        subject =>  $subject,
        body =>     $body,
    };

    return scalar @{$self->pending_messages};
}



=head2 FUNCTIONS

Three functions are available for use as default handlers for testing and debugging purposes.

=over

=item defaultDXMessageHandler()

=item defaultStatsHandler()

=item defaultPrivateMessageHandler()

=back

=cut

sub defaultStatsHandler {
    my %args=@_;
    my $from=       $args{from};
    my $freq=       $args{frequency};
    my $message=    $args{message};
    my $heard=      $args{heard};
    my $time=       $args{time};
    my $locator=    $args{locator};

    our $BAND={
        80 => [3000,4000],
        40 => [7000,7200],
        20 => [14000,14300],
        10 => [28000,29000]
    } unless $BAND;
    our $COUNT;

    for my $key (keys %{$BAND}) {
        my $span=$BAND->{$key};
        my ($min,$max)=@{$span};
        if ($freq >= $min and $freq <= $max) {
            $COUNT->{$key}++;
        }
    }
    for my $key (keys %{$COUNT}) {
        print( $key." ".$COUNT->{$key}."\n" );
    }
}

sub defaultDXMessageHandler {
    my %args=@_;
    my $from=       $args{from};
    my $freq=       $args{frequency};
    my $message=    $args{message};
    my $heard=      $args{heard};
    my $time=       $args{time};
    my $locator=    $args{locator};

    print( "Heard: $heard on $freq by $from at $time location $locator $message\n" );
}

sub defaultPrivateMessageHandler {
    my %args=@_;
    my $from=       $args{from} || '';
    my $to=         $args{to}       || '';
    my $body=       $args{body}     || 'no message';
    my $subject=    $args{subject}  || 'no subject';
    my $time=       $args{time}     || gmtime(time());

    print( "Private to $to from $from at $time subject $subject message $body\n" );
}

##############
## PRIVATES ##
##############

=head1 Private Methods

=over

=item dispatchStats()

=item dispatchDXMessage()

=item dispatchPrivateMessage()

=item _sendPrivate()

=item processPending()

=item process()

=back

=cut

sub dispatchStats {
    # PRIVATE: Dispatches the message to all the handlers
    my $self=   shift;
    my %args=@_;
    # Fire each handler in turn.
    foreach my $handler (@{$self->stats_handler}) {
        &{$handler}( %args );
    }
}

sub dispatchDXMessage {
    # PRIVATE: Dispatches the message to all the handlers
    my $self=   shift;
    my %args=@_;
    my $from=   $args{from};
    my $frequency=  $args{frequency};
    my $message=    $args{message};
    my $heard=  $args{heard};
    my $time=   $args{time};
    my $locator=    $args{locator};

    # Fire each handler in turn.
    foreach my $handler (@{$self->dx_message_handler}) {
        &{$handler}(  %args );
    }
}

sub dispatchPrivateMessage {
    # PRIVATE: Dispatches the message to all the handlers
    my $self=   shift;
    my %args=@_;
    my $time=   $args{time};
    my $from=   $args{from};
    my $to=     $args{to};
    my $subject=    $args{subject};
    my $body=   $args{body};

    foreach my $handler (@{$self->private_message_handler}) {
        &{$handler}( %args );
    }
}

sub _sendPrivate {
    # Sends a message using the supplied hashRef
    my $self=shift;
    my $hashRef = shift;    # hashRef
    return unless ref($hashRef);
    my $to =    $hashRef->{to};
    my $subject =   $hashRef->{subject};
    my $body =  $hashRef->{body};

    if ( $self->{handle} ) {
        my $fd=$self->{handle};

        print( $fd "sp $to\n" );
        print( $fd "$subject\n" );
        print( $fd "$body\n" );
        print( $fd '/ex'."\n" );
    }

    return $self->{handle};
}

sub processPending {
    # Sends any pending messages from the queue
    my $self=shift;

    while( my $message = shift( @{$self->pending_messages}) ) {
        $self->_sendPrivate( $message );
    }
}

sub process {
    # PRIVATE: Watches the connection, and parses dx spider results.
    # Returns when any messages have been read and the spider
    # has returned to a prompt. 
    # returns 1 if idle, Or undef if a timeout occurs (not yet implemented)
    my $self=shift;
    my $fd=shift;

    $fd->blocking(0);
    my %message=( type=>'start poll' );
    while ( %message ) {
        last unless $fd;
        $_ = <$fd>;
        unless($_) {
            #Wait for more input if none available.
            sleep 1;
            next;
        }
        chomp;
        s/(\r|\n)//g;

        (/^Enter your \*real\* Callsign to continue|login:/i) && do {
            # Login
            sleep 1;
            print( $fd $self->{callsign}."\n" );
            next;
        };

        (/^DX de ([^:]+):\s+([\d.]+)\s+(\S+)\s+(.*)$/) && do {
            #DX de I5WEA:      7058.0  IV3/IK3SSW/P DCI-UD036 Op. TONY
            #DX de PA3GDY:    50108.6  UX2KA/P      599 KO31<es>JO21               1350Z JO21
            my ($from,$freq,$heard,$comment)=($1,$2,$3,$4);
            my ($locator,$time)=('',gmtime(time));
            $comment=~s/([A-Z]{2}\d{2})\s*/$locator=$1,''/e;
            $comment=~s/(\d{4}[A-Z]{1})\s*/$time=$1,''/e;

            my %dx = (
                time =>     $time, 
                from =>     $from, 
                frequency =>    $freq, 
                heard =>    $heard, 
                locator =>  $locator, 
                message =>  $comment 
            );
            $self->dispatchStats( %dx );
            $self->dispatchDXMessage( %dx );
            $self->processPending();    # Process any mesages to send
            next;
        };

        (/dxspider >$/i) && do {
            #M1BSC de GB7EDX 16-Jun-2005 0857Z dxspider >
            # If we're back at a prompt, then no messages are being handled!
            if (%message && ($message{type} eq 'private')) {
                # Got a private message
                $self->dispatchPrivateMessage( %message );
            };

            $self->processPending();    # Process any mesages to send

            %message=();            # Clear the received message
            next;
        };

        (/^New mail has arrived for you/i) && do {
            #New mail has arrived for you
            print( $fd "read\n" );
            next;
        };

        (/^Msg: (\d+) From: (\S+) Date:\s+(\S+)\s+(\S+) Subj: (.*)$/) && do {
            # Read subject and start body reading
            #Msg: 3960 From: M1BSC Date:  3-Jun 1022Z Subj: m1bsc 145.450 13:00 5/9
            my ($id,$from,$date,$time,$subject)=($1,$2,$3,$4,$5);
            %message=( 
                type =>     'private',
                from =>     $from,
                to =>       $self->{callsign},
                subject =>  $subject,
                body =>     '',
                time =>     $date,
            );
            next;
        };

        (%message && $message{type} =~ /(private|public)/) && do {
            # Read body text
            $message{body}.=$_."\n";
            next;
        };


        (/^To ([\w\d]+) de /) && do {
            #To ALL de 9A8A: LZ2HM: FB..here band closed, for now..?
            next;
        };

    }

    return 1;
}

=head1 PREREQUISITES

=over

=item IO::Handle

=item IO::Socket

=item IO::Socket::INET

=item Moose

=item POSIX

=item Test::More

=back

=head1 OSNAMES

Unix or Unix-likes.

=head1 AUTHOR

Bruce James - custard@cpan.org

=head1 VERSION

0.04

=head1 COPYRIGHT

Copyright 2012, Bruce James

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;

