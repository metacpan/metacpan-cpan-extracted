#!/usr/bin/perl
#
#   This program is free software; you can redistribute it and/or modify
#   it under the terms of the GNU General Public License as published by
#   the Free Software Foundation; either version 3 of the License, or
#   (at your option) any later version.
#

open STDOUT, '>','proxy.log';
open STDERR, '>','proxy-err.log';

our @sockets = ();

$SIG{'INT'} = sub {
    print "Sig INT... ", @_, "\n";
    foreach my $sock (@sockets) { close $sock; }
};
$SIG{'QUIT'} = $SIG{'INT'};
$SIG{PIPE} = sub { print "Sig PIPE... ", @_, "\n"; };

#$SIG{'USR1'} = 'IGNORE';

$SIG{CHLD} = 'IGNORE';

( fork and exit ) if -f 'daemon';

use strict;
# use warnings;
no warnings;

package proxy;

use IO::Socket;
use IO::Select;
use IO::Handle;

sub say {
    print scalar localtime, ': ', @_, "\n";
    return 1;
}


sub new {
    my $obj  = shift;
    my $self = {};

    my $proxy_port = shift;
    my $acc_port = shift;

    $self->{freehal_host} = shift;
    $self->{freehal_port} = shift;
    $self->{server_host} = shift;
    $self->{server_port} = shift;

    $self->{client_callback} = shift;
    $self->{server_callback} = shift;

    $self->{proxy} = IO::Socket::INET->new(
        LocalPort => $proxy_port,
        Type      => SOCK_STREAM,
        Reuse     => 1,
        Listen    => 100,
        Blocking => 0,
    );

    $self->{acc} = IO::Socket::INET->new(
        LocalPort => $acc_port,
        Type      => SOCK_STREAM,
        Reuse     => 1,
        Listen    => 100,
        Blocking => 0,
    );

    binmode $self->{proxy};
    binmode $self->{acc};

    return bless $self, $obj;
}

my @last_display_statements = ();

sub accept {
    my $self = shift;

    my %redirect_to = ();
    my %offers = ();
    my %offer_sockets = ();
    my %request_sockets = ();
    my %has_offer_sockets = ();
    my %has_request_sockets = ();

    my $select = new IO::Select;
    my $freehal;
    if ( $self->{freehal_host} ) {
        say "proxy: local freehal server: ", $self->{freehal_host}, ':', $self->{freehal_port};
        $freehal = IO::Socket::INET->new(
            PeerAddr => $self->{freehal_host},
            PeerPort => $self->{freehal_port},
            Blocking => 0,
        );

        binmode $freehal;
        $freehal->blocking(0);
        $select->add($freehal);
        autoflush $freehal;
        
        $offers{ $freehal } = $freehal->peerhost;
        $offers{ $freehal->peerhost } = $freehal;
        $offer_sockets{ $freehal->peerhost } = $freehal;
        
        print $freehal "OFFER:.\n";
    }
    else {
        say "proxy: no local freehal server";
    }
    my $server;
    if ( $self->{server_host} ) {
        say "proxy: server to offer to: ", $self->{server_host}, ':', $self->{server_port};
        $server = IO::Socket::INET->new(
            PeerAddr => $self->{server_host},
            PeerPort => $self->{server_port},
            Blocking => 0,
        );

        binmode $server;
        $server->blocking(0);
        $select->add($server);
        autoflush $server;

        print $server "OFFER:.\n";
        print $server "OFFER:.\n";
        print $server "OFFER:.\n";
    }
    else {
        say "proxy: no server to offer to given";
    }

    $select->add( $self->{proxy} );
    $select->add( $self->{acc} );

    while ( 1 ) {
        foreach my $fd (grep { defined $_ } $select->can_read(1)) {

            my $buf = "";

            if ( defined $fd && ($fd||0) == ($self->{proxy}||0) ) {
                my $client = $self->{proxy}->accept();
                binmode $client;
                $client->blocking(0);
                $select->add($client);
                autoflush $client;
                print $client "OK:.\n";
                $request_sockets{ $client->peerhost } = $client;
                $has_request_sockets{ $client->peerhost } = 1;
            }
            
            elsif ( defined $fd && ($fd||0) == ($self->{acc}||0) ) {
                my $client = $self->{acc}->accept();
                binmode $client;
                $client->blocking(0);
                $select->add($client);
                autoflush $client;

                $offers { $client } = $client->peerhost;
                $offers { $client->peerhost } = $client;
                $offer_sockets{ $client->peerhost } = $client;
                $has_offer_sockets{ $client->peerhost } = 1;
                print $client "AHA:.";
                say "offer from ", $client->peerhost;
            }
            
            #~ elsif ( defined $fd && $fd == $freehal ) {
                #~ #sysread( $server, $buf, 1024 );
                #~ $buf = <$fd>;
                #~ chomp $buf;
                
                #~ if ( $buf ) {

                    #~ &{ $self->{server_callback} }($buf);
                    #~ foreach my $target ( $server, values %request_sockets ) {
                        #~ next if !$server;
                        #~ say "proxy: (2) from ", $freehal->peerhost, " to ", $target->peerhost, ": ", $buf;
                        #~ print $target $buf, "\n";
                    #~ }
                #~ }
            #~ }

            elsif ( defined $fd && $fd == $server ) {
                #sysread( $server, $buf, 1024 );
                #sysread( $fd, $buf, 1024 );
                $buf = <$fd>;
                chomp $buf;
                
                if ( $buf ) {

                    &{ $self->{server_callback} }($buf);
                    foreach my $target ( $freehal ) {
                        next if !$freehal;
                        say "proxy: (3) from ", $server->peerhost, " to ", $target->peerhost, ": ", $buf;
                        print $target $buf, "\n";
                    }
                }
            }

            elsif ( defined $fd )  {
                $buf = <$fd>;
                chomp $buf;
                
                if ( !$buf ) {
                    next;
                }
                
                if ( $has_offer_sockets{ $fd->peerhost } ) {
                    if ( $buf =~ m/display/i ) {
                        push @last_display_statements, $buf;
                    }
                    else {
                        foreach my $target ( values %request_sockets ) {
                            
                            say "proxy: (1) from ", $fd->peerhost, " to ", $target->peerhost, ": ", $buf;
                            print $target $buf, "\n";
                        }
                    }
                }
                if ( $has_request_sockets{ $fd->peerhost } ) {
                    if ( $buf =~ m/get[:]+?lines/i ) {
                        foreach my $target ( values %request_sockets ) {
                            print $target $last_display_statements[-1], "\n";
                        }
                    }
                    else {
                        foreach my $target ( values %offer_sockets ) {
                            say "proxy: (4) from ", $fd->peerhost, " to ", $target->peerhost, ": ", $buf;
                            print $target $buf, "\n" and do {
                                $has_offer_sockets{ $target->peerhost } = 1;
                                $request_sockets{ $fd } = $fd;
                            };
                        }
                    }
                }
            }
        }
    }
}

my $masterproxy_port    = 5100;
my $mode                = shift;
my $is_central_master   = ( ( -f 'master' ) || $mode =~ /master/ );
my $is_offering_only_to = ( ( -f 'offerto' ) || $mode =~ /offerto/ );
my $offer_to            = shift;
if ( !$offer_to && -f 'offerto' ) {
    open my $file, '<', 'offerto';
    $offer_to = <$file>;
    close $file;
    chomp $offer_to;
}

say "proxy: I am masterproxy\n" if $is_central_master;
say "proxy: I am masterproxy, but I offer to $offer_to\n"
  if $is_offering_only_to;
say "proxy: I am a normal proxy \n"
  if !$is_offering_only_to && !$is_central_master;

package main;

sub from_client {
}
sub from_server {
}

my $proxy = new proxy(
    5100,
    5099,
    ( !$is_central_master || $is_offering_only_to ) ? 'localhost' : undef,
    ( !$is_central_master || $is_offering_only_to ) ? 5173        : undef,
    $offer_to ? $offer_to : undef,
    $offer_to ? 5099      : undef,
    \&from_client,
    \&from_server
);

$proxy->accept();

1;

