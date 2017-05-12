# Ginger::Reference::Request::IO::Mongrel2
# Version 0.01
# Copyright (C) 2013 David Helkowski

# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as
# published by the Free Software Foundation; either version 2 of the
# License, or (at your option) any later version.  You may also can
# redistribute it and/or modify it under the terms of the Perl
# Artistic License.
  
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

=head1 NAME

Ginger::Reference::RPC::IO::Mongrel2 - Ginger::Reference Component

=head1 VERSION

0.02

=cut

package Ginger::Reference::RPC::IO::Mongrel2;
use Class::Core 0.03 qw/:all/;
use strict;
use Data::Dumper;
use ZMQ::LibZMQ3;
use ZMQ::Constants qw/ZMQ_PULL ZMQ_PUB ZMQ_IDENTITY ZMQ_RCVMORE ZMQ_POLLIN  ZMQ_REP ZMQ_REQ/;
use threads;
use threads::shared;
use XML::Bare;

use vars qw/$VERSION/;
$VERSION = "0.02";

my $stop :shared;

my $incoming;
my $outgoing;
my $app;

my $death :shared;

sub wait_threads {
    my ( $core, $self ) = @_;
    while( 1 ) {
        my @joinable = threads->list(threads::joinable);
        my @running = threads->list(threads::running);
        
        for my $thr ( @joinable ) { $thr->join(); }
        last if( !@running );
        sleep(1) if( !$stop );
    }
}

sub init {
    my ( $core, $self ) = @_;
    $self->{'ctx'} = zmq_init();
    $stop = 0;
    $incoming = 0;
    $outgoing = 0;
}

sub register_listener {
    my ( $core, $self ) = @_;
    my $modinfo = $core->get('modinfo');
    
    
}

sub start_listening {
    my ( $core, $self ) = @_;
    threads->create( \&start_listening2, $core, $self );
    sleep(2);
}

sub start_listening2 {
    my ( $core, $self ) = @_;
    # setup libzmq to listen
    # potentially spin off some threads that are listening
    
    my $ctx = $self->{'ctx'};
    $app = $core->get_app();
    $incoming = $self->{'incoming'} = zmq_socket( $ctx, ZMQ_REP );
    zmq_bind( $incoming, "tcp://*:9011" );
    #zmq_setsockopt( $incoming, ZMQ_IDENTITY, 'abc' ); # Indentity should not be hardcoded
    while( !$stop ) {
        zmq_poll( [ { socket => $incoming, events => ZMQ_POLLIN, callback => \&handle_request } ], 1000 );
    }
    {
       lock $death;
       zmq_close( $incoming ) if( $incoming );
       zmq_close( $outgoing ) if( $outgoing );
    }
}

sub handle_request {
    print "Received something!";
    my $part;
    zmq_recv( $incoming, $part, 10000 ); # TODO: the size should be configurable
    #print "Recieved request $part\n";
    my ( $ob, $xml ) = new XML::Bare( text => $part );
    $xml = XML::Bare::simplify( $xml ); 
    print Dumper( $xml );
    my $modname = $xml->{'mod'};
    my $func = $xml->{'func'};
    my $mod = $app->get_mod( mod => $modname );
    my $msg = $mod->$func( %$xml );
    
    #my $msg = 'response';
    zmq_send( $incoming, $msg );
}

sub end {
    my ( $core, $self ) = @_;
    # stop listening
    # kill any threads that have been setup
    $stop = 1;
    {
       lock $death;
       zmq_close( $incoming ) if( $incoming );
       zmq_close( $outgoing ) if( $outgoing );
    }
    #wait_threads();
}

sub call {
    my ( $core, $self ) = @_;
    my $xml = $core->get('xml');
    my $mod = $core->get('mod');
    my $func = $core->get('func');
    
    $xml .= "<mod>$mod</mod><func>$func</func>";
    my $ctx = $self->{'ctx'};
    print "Attempting to make a call\n";
    if( !$outgoing ) {
        $outgoing = $self->{'outgoing'} = zmq_socket( $ctx, ZMQ_REQ );
        zmq_connect( $outgoing, "tcp://localhost:9011" );
    }
    
    #zmq_setsockopt( $outgoing, ZMQ_IDENTITY, 'abc' );
    zmq_send( $outgoing, $xml );
    
    my $buffer;
    zmq_recv( $outgoing, $buffer, 100 );
    print "Got back '$buffer'\n";
}


1;

__END__

=head1 SYNOPSIS

Component of L<Ginger::Reference> that handles recieving web requests from Mongrel2 via ZeroMQ.

=head1 DESCRIPTION

The following things are handled by this module:

=over 4

=item * Receiving requests from Mongrel2

=item * Parsing the raw Mongrel2 incoming request into a structure format

=item * Decoding post data if it is set

=item * Routing request via web_router module

=item * Sending the results of a routed request back out to Mongrel2

=item * Sending desired cookies to be set to Mongrel2

=head2 Known Bugs

=over 4

=item * File uploads are not handled properly

=back

=head1 LICENSE

  Copyright (C) 2013 David Helkowski
  
  This program is free software; you can redistribute it and/or
  modify it under the terms of the GNU General Public License as
  published by the Free Software Foundation; either version 2 of the
  License, or (at your option) any later version.  You may also can
  redistribute it and/or modify it under the terms of the Perl
  Artistic License.
  
  This program is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
  GNU General Public License for more details.

=cut