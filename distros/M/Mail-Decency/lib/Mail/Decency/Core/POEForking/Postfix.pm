package Mail::Decency::Core::POEForking::Postfix;

use strict;
use warnings;

use version 0.74; our $VERSION = qv( "v0.1.5" );

use base qw/
    Mail::Decency::Core::POEForking
/;

use POE qw/
    Wheel::ReadWrite
/;

use Scalar::Util qw/ weaken /;
use Socket qw/ inet_ntoa /;

=head1 NAME

Mail::Decency::Core::POEForking::Postfix

=head1 DESCRIPTION

Postfix instance to be used with POEForking

=head1 METHODS

=head2 create_handler

Called by the forking/treading parent server

=cut

sub create_handler {
    my $class = shift;
    my ( $heap, $session, $socket, $peer_addr, $peer_port )
        = @_[ HEAP, SESSION, ARG0, ARG1, ARG2 ];
    
    POE::Session->create(
        inline_states => {
            _start        => \&postfix_start,
            _stop         => \&postfix_stop,
            postfix_input => \&postfix_input,
            postfix_flush => \&postfix_flush,
            postfix_error => \&postfix_error,
            good_night    => \&postfix_stop,
            #_parent       => sub { 0 },
            # _default           => sub {
            #     my ( $heap, $event, $args ) = @_[ HEAP, ARG0, ARG1 ];
            #     $heap->{ decency }->logger->error( "** UNKNOWN EVENT $event, $args" );
            # }
        },
        heap => {
            decency   => $heap->{ decency },
            logger    => $heap->{ decency }->logger,
            conf      => $heap->{ conf },
            handler   => $heap->{ decency }->get_handlers(),
            server    => $heap->{ server },
            parent    => $session,
            socket    => $socket,
            peer_addr => inet_ntoa( $peer_addr ),
            peer_port => $peer_port,
        }
   );
}


=head2 postfix_start

Start connection from postfix

=cut

sub postfix_start {
    my ( $kernel, $session, $heap ) = @_[ KERNEL, SESSION, HEAP ];
    
    # tell the parent session we are here
    $kernel->post( $heap->{ parent }, "new_client_session", $session );
    
    # start new r/w on the socket
    $heap->{ client } = POE::Wheel::ReadWrite->new(
        Handle       => $heap->{ socket },
        Filter       => POE::Filter::Postfix::Plain->new(),
        InputEvent   => "postfix_input",
        ErrorEvent   => "postfix_error",
        FlushedEvent => "postfix_flush",
    );
}


=head2 postfix_input

Incoming data from postfix

=cut

sub postfix_input {
    my ( $heap, $attr ) = @_[ HEAP, ARG0 ];
    $heap->{ client }->put(
        $heap->{ handler }->( $heap->{ server }, $attr )
    );
}


=head2 postfix_stop

Stop connection.. called when WE finish the connection (eg SIG TERM)

=cut

sub postfix_stop {
    my ( $heap, $session ) = @_[ HEAP, SESSION ];
    
    $heap->{ logger }->debug2( "Disconnecting from postfix" );
    eval {
        delete $heap->{ $_ } for qw/ client socket /;
    };
    $heap->{ logger }->error( "Could not remove client from list after postfix stop: $@" )
        if $@;
    
    return;
}


=head2 postfix_flush

Flush connection .. ignore this

=cut

sub postfix_flush {
    my ( $heap, $session ) = @_[ HEAP, SESSION ];
    $heap->{ logger }->debug3( "Flush from $heap->{ peer_addr } (". $session->ID. ")" );
    eval {
        delete $heap->{ $_ } for qw/ client /;
    };
}


=head2 postfix_error

Handles connection erros from postfix .. as well as disconnects (not flush)

=cut

sub postfix_error {
    my ( $heap, $session, $operation, $errnum, $errstr, $id ) = @_[ HEAP, SESSION, ARG0..ARG3 ];
    
    # disconnect ..
    if ( $operation eq 'read' && $errnum == 0 ) {
        $heap->{ logger }->debug2( "Postfix closed connection" );
    }
    
    # real error ..
    else {
        $heap->{ logger }->error( "Weird disconnection from postfix ". $session->ID. " (OP: $operation, ENUM: $errnum, ESTR: $errstr, WID: $id)" );
    }
    
    # close all sockets ..
    eval {
        #delete $heap->{ $_ } for qw/ client socket /; #
        $heap->{ socket }->flush;
    };
    $heap->{ logger }->error( "Could not remove client from list after weird disconnect: $@" )
        if $@;
    
    return;
}

=head1 AUTHOR

Ulrich Kautz <uk@fortrabbit.de>

=head1 COPYRIGHT

Copyright (c) 2010 the L</AUTHOR> as listed above

=head1 LICENCSE

This library is free software and may be distributed under the same terms as perl itself.

=cut


1;
