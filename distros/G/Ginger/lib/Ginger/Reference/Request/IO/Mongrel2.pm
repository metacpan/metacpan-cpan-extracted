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

Ginger::Reference::Request::IO::Mongrel2 - Ginger::Reference Component

=head1 VERSION

0.02

=cut

package Ginger::Reference::Request::IO::Mongrel2;
use strict;
use ZMQ::LibZMQ3;
use Class::Core 0.03 qw/:all/;
use Data::Dumper;
#use ZMQ::Constants ':all';
use ZMQ::Constants qw/ZMQ_PULL ZMQ_PUB ZMQ_IDENTITY ZMQ_RCVMORE ZMQ_POLLIN ZMQ_MSG_MORE/;
#use URI::Simple;
use CGI;
use Text::TNetstrings qw/:all/;
use threads;
use threads::shared;
use XML::Bare qw/xval/;
use Carp;

use vars qw/$VERSION/;
$VERSION = "0.02";

my $stop :shared;

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
    $self->{'running'} = 1;
    $stop = 0;
    my $app = $self->{'obj'}{'_app'};
    my $sman = $self->{'session_man'} = $app->get_mod( mod => 'session_man' );
    if( !$sman ) {
        confess( "Cannot find session manager" );
    }
}

sub end {
    my ( $core, $self ) = @_;
    #$self->{'closed'} = 1;
    #zmq_close( $self->{'incoming'} );
    #zmq_close( $self->{'outgoing'} );
    #zmq_term( $self->{'ctx'} );
    $stop = 1;
    $self->wait_threads();
}

sub run {
    my ( $core, $self ) = @_;
    
    my $app = $core->get_app();
    #$self->{'request_man'} = $app->get_mod( mod => 'request_man' );
    my $log = $self->{'log'} = $app->get_mod( mod => 'log' );
    my $conf = $self->{'_xml'};
    my $threads = xval $conf->{'threads'}, 2;
    
    #my $session_man = $app->get_mod( mod => 'session_man' );
    #my $session_hash = $session_man->{'sessions'};
    
    $log->note( text => "Spawning $threads thread(s) to handle incoming requests" );
    for( my $i=0;$i<$threads;$i++ ) {
        threads->create( \&server, $core, $self, $i );
    }
}

#my $server;
my %tids :shared;
my %servers;

sub server {
    my ( $core, $self, $sid ) = @_;
    
    my $app = $core->get_app();
    
    $self->{'request_man'} = $app->get_mod( mod => 'request_man' );
    
    #print "Start session hash:".$session_hash."\n";
    
    #$SIG{'INT'} = 'default';
    
    my $thr = threads->self();
    my $tid = $thr->tid();
    $app->init_threads( tid => $tid );    
    {
        lock %tids;
        $tids{ $tid } = $sid;
        $servers{ $tid } = $self;
    }
    
    $self->{'id'} = $sid;
    #my $app = $self->{'obj'}{'_app'};
    my $glob = $self->{'obj'}{'_glob'};
    
    my $log = $self->{'log'}; # this is a thread specific copy of the log module due to the way perl threading works
        
    my $sman = $self->{'session_man'};
    
    #$sman->{'sessions'} = $session_hash;
    
    my $rman = $self->{'request_man'};
    #my $router = $self->{'router'};
    my $ctx = $self->{'ctx'} = zmq_init();
    my $incoming = $self->{'incoming'} = zmq_socket( $ctx, ZMQ_PULL );
    
    my $xml = $self->{'_xml'};
    my $ip = xval $xml->{'ip'};
    my $inconf = $xml->{'incoming'};
    my $outconf = $xml->{'outgoing'};
    my $inport = 6768;
    my $inid = 'blah';
    if( $inconf ) {
        $inport = xval $inconf->{'port'}, 6768;
        $inid = xval $inconf->{'id'}, 'blah';
    }
    my $outport = 6769;
    my $outid = 'blah2';
    if( $outconf ) {
        $outport = xval $outconf->{'port'}, 6769;
        $outid = xval $outconf->{'id'}, 'blah2';
    }
    $log->note( text => "Server $sid started - Listening on ip $ip - in: $inport($inid) - out: $outport($outid)" );
    
    zmq_connect( $incoming, "tcp://$ip:$inport" );
    zmq_setsockopt( $incoming, ZMQ_IDENTITY, $inid ); # Indentity should not be hardcoded
    my $outgoing = $self->{'outgoing'} = zmq_socket( $ctx, ZMQ_PUB );
    zmq_connect( $outgoing, "tcp://$ip:$outport" );
    zmq_setsockopt( $outgoing, ZMQ_IDENTITY, $outid );
    
    #my $q = new CGI;
    while(1) {
        last if( $stop );
        #sleep(1);
        zmq_poll( [ { socket => $incoming, events => ZMQ_POLLIN, callback => \&handle_request } ], 1000 );
    }
    $log->note( text => "Server $sid ending" );
    
    zmq_close( $incoming );
    zmq_close( $outgoing );
    zmq_term( $ctx );
}

sub handle_request {
    my $sid;
    my $thr = threads->self();
    my $tid = $thr->tid();
    my $self;
    {
        lock %tids;
        $sid = $tids{ $tid };
        $self = $servers{ $tid };
    }
    
    my $app = $self->{'obj'}{'_app'};
    
    my $log = $self->{'log'};
    my $sman = $self->{'session_man'};
    
    my $rman = $self->{'request_man'};
    my $incoming = $self->{'incoming'};
    my $outgoing = $self->{'outgoing'};
    
    #my $sid = $server->{'id'};
    #print "Server: $sid - $tid\n";
    
    my $buffer = '';
    while( 1 ) {
        my $part;
        zmq_recv( $incoming, $part, 32768 ); # TODO: the size should be configurable
        $buffer .= $part;
        my $rc = zmq_getsockopt( $incoming, ZMQ_RCVMORE );
        last if( !$rc );
        print "Extra part; size of part1 = " . length( $part ) . "\n";
    }
    
    #print "Sid: $sid\n";
    $buffer =~ m/^([^ ]+) ([^ ]+) ([^ ]+) (.+)$/s;
    my $sender = $1;
    my $id = $2;
    my $path = $3;
    my $data = $4;
    my $type = 'get';
    
    #print "Sending: $sender Id $id\n";
    # $data =~ s/\0*$//; remove the null from the end for printing more easily
    
    $data =~ m/^([0-9]+):/; 
    
    my $tnetlen = $1;
    my $lenlen = length( $tnetlen );
    
    my $extra = length( $data ) - ( $tnetlen + $lenlen + 2 );
    my $post = '';
    my $postvars = {};
    
    if( $extra > 0 ) {
        my $xstr = substr( $data, $tnetlen + $lenlen + 2 );
        $xstr =~ s/,\0*$//;
        if( $xstr eq '0:' ) {
        }
        elsif( $xstr eq '21:{"type":"disconnect"}' ) {
            $type = "disconnect_notice";
            #print "Disconnect of $id\n";
            return; # TODO; pass notice on to routing to potentially terminate long running reports
        }
        else {
            $post = $xstr;
            $post =~ s/^([0-9]+)://; 
        }
    }
    
    my $hash = decode_tnetstrings( $data );
    
    my $queryhash = 0;
    if( $hash && defined $hash->{'QUERY'} ) {
        $queryhash = url2hash( $hash->{'QUERY'} );
    }
    
    my $content_type = $hash->{'content-type'};
    
    if( $content_type && $content_type =~ m|^multipart/form-data; boundary=(.+)$| ) {
        my $bound = "--$1";#\r\n
        if( $hash->{'x-mongrel2-upload-start'} ) {
            if( ! $hash->{'x-mongrel2-upload-done'} ) {
                $type = "largepost_notice";#$hash->{'x-mongrel2-upload-start'};
                my $postid;
                if( $queryhash && ( $postid = $queryhash->{'postid'} ) ) {
                    # store off the temp file location with the postid so that it can be retrieved by a later status check
                    # TODO
                }
                # potentially it is pointless to pass the upload start notice on to routing,
                # but current we are doing so, comment out the following line to avoid passing it on
                # next;
            }
            else {
                $type = "largepost";
                # open the file and parse it
                my $tmpfile = $hash->{'x-mongrel2-upload-start'};
                process_postfile( $postvars, $bound, $tmpfile );
            }
        }
        else {
            $type = 'post';
            my @postarr = split( $bound, $post );
            shift @postarr;
            while( @postarr ) {
                my $part = shift @postarr;
                last if( $part =~ m"^--" );
                my $parthash = process_multipart( $part );
                my $partname = $parthash->{'name'};
                if( !@{$parthash->{'headers'}} ) {
                    $postvars->{ $partname } = $parthash->{'body'};
                }
                else {
                    $postvars->{ $partname } = $parthash;
                }
            }
        }
    }
    elsif( $hash->{'METHOD'} eq 'POST' ) {
        $type = 'post';
        $postvars = url2hash( $post );
    }
    
    my $session = 0;
    
    my $r = $rman->new_request(
        path => $path,
        query => $queryhash,
        postvars => $postvars,
        id => $id,
        ip => $hash->{'x-forwarded-for'},
        type => $type # either 'post', 'get', or 'disconnect_notice'
        );
    $log->{'r'} = $r;
    
    $log->note( text => "Recieved request to $path");
    
    my $cookieman = $r->get_mod( mod => 'cookie_man' );
    
    if( $hash->{'cookie'} ) {
        $cookieman->parse( raw => $hash->{'cookie'} );
    }
    
    my $router = $r->get_mod( mod => 'web_router' );

    my $res = $router->route( session_man => $sman );
    if( $type =~ m/notice/ ) {
        next;
    }
    
    my $typeinfo = $r->get_type();
    my $restype = $typeinfo->get_res('type');
    
    my $code = $r->get_code();
    my $body = $r->get_body();
    
    my $headers = $r->get_headers();
    
    $headers .= $cookieman->set_header();
    my $raw;
    use bytes;
    if( $body ne '' ) {
        my $blen = length( $body );
        $headers .= "Content-Length: $blen\r\n";
        $raw = "$headers\r\n$body";
    }
    else {
        $raw = $headers . "\r\n\r\n";
    }
    
    my $idlen = length( $id );
    my $msg   = "blah2 $idlen:$id, HTTP/1.1 $code\r\n$raw";
    my $len   = length( $msg );
    
    if( $len > 100000 ) {
        # Theoretically this should work, but Mongrel2 apparently does not support this
        #for( my $st = 0; $st < $len; $st+= 100000 ) {
        #    my $end = $st + 100000 - 1;
        #    if( $end > $len ) { $end = $len; }
        #    if( $end < $len ) {
        #        $log->note( text => "Sending $st - $end" );
        #        zmq_send( $outgoing, substr( $msg, $st, $end ), -1, ZMQ_MSG_MORE );
        #    }
        #    else {
        #        $log->note( text => "Sending $st - $end" );
        #        zmq_send( $outgoing, substr( $msg, $st, $end ) );
        #    }
        #}
        
        # This -seems- to work more often than the zmq_send below for large messages
        my $ob = zmq_msg_init_data( $msg );
        zmq_sendmsg( $outgoing, $ob );
        zmq_msg_close( $ob );
    }
    else {
        zmq_send( $outgoing, $msg );
    }
    
    $r->end();
    
    my $rlen = $r->{'end'} - $r->{'start'};
    $rlen *= 100000;
    $rlen = int( $rlen );
    $rlen /= 100;
    
    $log->note( text => "Request finished; len=${rlen}ms" );
}

sub url2hash {
    my $url = shift;
    my $hash;
    
    my @parts = split('&', $url );
    for my $part ( @parts ) {
        next if( ! defined $part );
        if( $part =~ m/(.+)=(.+)/ ) {
            my $key = $1;
            my $val = $2;
            $key =~ s/%([a-zA-Z0-9]{2})/pack('H2',$1)/ge;$key =~ s/\+/ /g;
            $val =~ s/%([a-zA-Z0-9]{2})/pack('H2',$1)/ge;$val =~ s/\+/ /g;
            if( $key =~ m/^(.+)\[([0-9]+)\]$/ ) {
                my $arr = $hash->{ $1 } ||= [];
                $arr->[$2] = $val;
            }
            else {
                $hash->{ $key } = $val;
            }
        }
    }
    return $hash;
}

sub process_postfile {
    my ( $postvars, $bound, $tmpfile ) = @_;
    if( ! -e $tmpfile ) {
        # perhaps not running on the same server?
        return;
    }
    # TODO: process the contents of tmpfile
    # - store short variables in postvars
    # - store pointers to the region of the tmpfile that matters for larger files
}

sub process_multipart {
    # Example parts:
    # Content-Disposition: form-data; name="pw"
    # Content-Disposition: form-data; name="myfile"; filename="test.txt"
    # Content-Type: text/plain
    my $part = shift;
    my $headers = [];
    $part =~ s/\r\n//;
    my $name = '';
    while( $part =~ m/^(Content-[^:]+): ([^\r]+)\r\n(.+)/s ) {
        my $varname = $1;
        my $val = $2;
        $part = $3;
        if( $varname eq 'Content-Disposition' ) {
            #print "Val:$val\n";
            if( $val =~ m/form-data; name="([^"]+)"(; filename="([^"]+)")?/ ) {
                my $disp_name = $1;
                my $disp_file = $2;
                if( $disp_file ) { # we have a filename
                }
                else {
                    $name = $disp_name;
                }
            }
        }
        else {
            push( @$headers, { name => $name, varname => $varname, val => $val } );
        }
    }
    $part =~ s/^\r\n//;
    $part =~ s/\r\n$//;
    
    return {
        name => $name,
        headers => $headers,
        body => $part  
    }
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