#!/usr/bin/env perl

use lib '../lib';
use IO::Socket::Socks qw(:constants $SOCKS_ERROR);
use IO::Select;
use strict;

# return bind address as ip address like most socks5 proxyes does
$IO::Socket::Socks::SOCKS5_RESOLVE = 1;

# create socks server
my $server = IO::Socket::Socks->new(SocksVersion => 5, SocksDebug => 1, ProxyAddr => 'localhost', ProxyPort => 1080, Listen => 10)
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
                # success
                $client->command_reply(REPLY_SUCCESS, $socket->sockhost, $socket->sockport);
            }
            else
            {
                # Host Unreachable
                $client->command_reply(REPLY_HOST_UNREACHABLE, $host, $port);
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
                # success
                $client->command_reply(REPLY_SUCCESS, $socket->sockhost, $socket->sockport);
            }
            else
            {
                # request rejected or failed
                $client->command_reply(REPLY_HOST_UNREACHABLE, $host, $port);
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
                
                $client->command_reply(REPLY_SUCCESS, $conn->peerhost, $conn->peerport);
                
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
        elsif($cmd == CMD_UDPASSOC)
        { # UDP associate
            # who really need it?
            # you could send me a patch
            
            warn 'UDP assoc: not implemented';
            $client->command_reply(REPLY_GENERAL_FAILURE, $host, $port);
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
{ # add `UserAuth => \&auth, RequireAuth => 1' to the server constructor if you want to authenticate user by login and password
    my $login = shift;
    my $password = shift;
    
    my %allowed_users = (root => 123, oleg => 321, ryan => 213);
    return $allowed_users{$login} eq $password;
}

# tested with `curl --socks5'
