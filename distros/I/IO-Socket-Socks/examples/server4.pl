#!/usr/bin/env perl

# Simple socks4 server
# implemented with IO::Socket::Socks module

use lib '../lib';
use IO::Socket::Socks qw(:constants $SOCKS_ERROR);
use IO::Select;
use strict;

# allow socks4a protocol extension
$IO::Socket::Socks::SOCKS4_RESOLVE = 1;

# create socks server
my $server = IO::Socket::Socks->new(SocksVersion => 4, SocksDebug => 1, ProxyAddr => 'localhost', ProxyPort => 1080, Listen => 10)
    or die $SOCKS_ERROR;

# accept connections
while()
{
    my $client = $server->accept();
    
    if($client)
    {
        my ($cmd, $host, $port) = @{$client->command()};
        if($cmd == CMD_CONNECT)
        { # connect
            # create socket with requested host
            my $socket = IO::Socket::INET->new(PeerHost => $host, PeerPort => $port, Timeout => 10);
            
            if($socket)
            {
                # request granted
                $client->command_reply(REQUEST_GRANTED, $socket->sockhost, $socket->sockport);
            }
            else
            {
                # request rejected or failed
                $client->command_reply(REQUEST_FAILED, $host, $port);
                $client->close();
                next;
            }
            
            my $selector = IO::Select->new($socket, $client);
            
            MAIN_CONNECT:
            while()
            {
                my @ready = $selector->can_read();
                foreach my $s (@ready)
                {
                    my $readed = $s->sysread(my $data, 1024);
                    unless($readed)
                    {
                        # error or socket closed
                        warn 'connection closed';
                        $socket->close();
                        last MAIN_CONNECT;
                    }
                    
                    if($s == $socket)
                    {
                        # return to client data readed from remote host
                        $client->syswrite($data);
                    }
                    else
                    {
                        # return to remote host data readed from the client
                        $socket->syswrite($data);
                    }
                }
            }
        }
        elsif($cmd == CMD_BIND)
        { # bind
            # create listen socket
            my $socket = IO::Socket::INET->new(Listen => 10);
            
            if($socket)
            {
                # request granted
                $client->command_reply(REQUEST_GRANTED, $socket->sockhost, $socket->sockport);
            }
            else
            {
                # request rejected or failed
                $client->command_reply(REQUEST_FAILED, $host, $port);
                $client->close();
                next;
            }
            
            while()
            {
                # accept new connection needed proxifycation
                my $conn = $socket->accept()
                    or next;
                
                $socket->close();
                if($conn->peerhost ne join('.', unpack('C4', (gethostbyname($host))[4])))
                {
                    # connected host should be same as specified in the client bind request
                    last;
                }
                
                $client->command_reply(REQUEST_GRANTED, $conn->peerhost, $conn->peerport);
                
                my $selector = IO::Select->new($conn, $client);
                
                MAIN_BIND:
                while()
                {
                    my @ready = $selector->can_read();
                    foreach my $s (@ready)
                    {
                        my $readed = $s->sysread(my $data, 1024);
                        unless($readed)
                        {
                            # error or socket closed
                            warn 'connection closed';
                            $conn->close();
                            last MAIN_BIND;
                        }
                        
                        if($s == $conn)
                        {
                            # return to client data readed from remote host
                            $client->syswrite($data);
                        }
                        else
                        {
                            # return to remote host data readed from the client
                            $conn->syswrite($data);
                        }
                    }
                }
                
                last;
            }
        }
        else
        {
            warn 'Unknown command';
        }
        
        $client->close();
    }
    else
    {
        warn $SOCKS_ERROR;
    }
}

sub auth
{ # add `UserAuth => \&auth' to the server constructor if you want to authenticate user by its id
    my $userid = shift;
    
    my %allowed_users = (root => 1, oleg => 1, ryan => 1);
    return exists($allowed_users{$userid});
}

# tested with `curl --socks4' and `curl --socks4a'
