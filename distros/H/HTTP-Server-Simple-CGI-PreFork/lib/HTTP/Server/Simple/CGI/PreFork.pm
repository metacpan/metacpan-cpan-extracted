package HTTP::Server::Simple::CGI::PreFork;

use strict;
use warnings;
use Socket ':all';
use IO::Handle;

#use Socket6 qw[unpack_sockaddr_in6];

our $VERSION = 6.0;
use Carp;

use base qw[HTTP::Server::Simple::CGI];

sub run {
    my ($self, %config) = @_;
    
    if(!defined($config{prefork})) {
        $config{prefork} = 0;
    }

    if(!defined($config{usessl})) {
        $config{usessl} = 0;
    }
    
    if($config{prefork}) {
        # Create new subroutine to tell HTTP::Server::Simple that we want
        # to be a preforking server
        no strict 'refs'; ## no critic (TestingAndDebugging::ProhibitNoStrict)
        *{__PACKAGE__ . "::net_server"} = sub {
            my $server = 'Net::Server::PreFork';
            return $server;
        };

    } else {
        no strict 'refs'; ## no critic (TestingAndDebugging::ProhibitNoStrict)
        *{__PACKAGE__ . "::net_server"} = sub {
            my $server = 'Net::Server::Single';
            return $server;
        };
    }
    
    # SET UP FOR SSL
    if($config{usessl}) {
        # SET UP FOR SSL
        # we need to ovverride the _process_request sub for IPv6. For SSL, we
        # also need to disable the calls to binmode
    
        no strict 'refs'; ## no critic (TestingAndDebugging::ProhibitNoStrict)
        *{__PACKAGE__ . "::_process_request"} =
            sub {
        
            my $self = shift;

            # Create a callback closure that is invoked for each incoming request;
            # the $self above is bound into the closure.
            sub {
                $self->stdio_handle(*STDIN) unless $self->stdio_handle;
        
                # Default to unencoded, raw data out.
                # if you're sending utf8 and latin1 data mixed, you may need to override this
                #binmode STDIN,  ':raw';
                #binmode STDOUT, ':raw';
                
                my $remote_sockaddr = getpeername( $self->stdio_handle );
                if(!$remote_sockaddr && defined($main::_realpeername)) {
                    $remote_sockaddr = $main::_realpeername;
                }
                
                my ( $iport, $iaddr, $peeraddr );
                if($remote_sockaddr) {
                    eval {
                        # Be fully backwards compatible
                        ( $iport, $iaddr ) = sockaddr_in($remote_sockaddr);
                        $peeraddr = $iaddr ? ( inet_ntoa($iaddr) || "127.0.0.1" ) : '127.0.0.1';
                        1;
                    } or do {
                        # Handle cases where the $remote_sockaddr is an IPv6 structure
                        eval {
                            ( $iport, $iaddr ) = unpack_sockaddr_in6($remote_sockaddr);
                            $peeraddr = inet_ntop(AF_INET6, $iaddr);
                            1;
                        } or do {
                            # What is the best way to handle an unparseable $remote_sockaddr?
                            # Will IPv6 be the "old protocol" one day in our lifetime to be superceded
                            # by something even more complex?
                            #
                            # For now, just return "127.0.0.1", which itself is problematic: What
                            # about the time IPv4 gets switched off and some backend will croak because
                            # the IP is too short?
                            $peeraddr = "127.0.0.1";
                        }
                    }
                }
                
                if(!defined($peeraddr)) {
                    $peeraddr = "";
                } elsif($peeraddr =~ /^\:\:ffff\:(\d+)\./) {
                    # Looks like a IPv4 adress in IPv6 format (e.g. ::ffff:192.168.0.1
                    # turn it into an IPv4 address for backward compatibility
                    $peeraddr =~ s/^\:\:ffff\://;
                }
                
                my ( $method, $request_uri, $proto ) = $self->parse_request;
                
                unless ($self->valid_http_method($method) ) {
                    $self->bad_request;
                    return;
                }
        
                $proto ||= "HTTP/0.9";
        
                my ( $file, $query_string )
                    = ( $request_uri =~ /([^?]*)(?:\?(.*))?/s );    # split at ?
        
                $self->setup(
                    method       => $method,
                    protocol     => $proto,
                    query_string => ( defined($query_string) ? $query_string : '' ),
                    request_uri  => $request_uri,
                    path         => $file,
                    localname    => $self->host,
                    localport    => $self->port,
                    peername     => $peeraddr,
                    peeraddr     => $peeraddr,
                    peerport     => $iport,
                );
        
                # HTTP/0.9 didn't have any headers (I think)
                my %xheaders;
                if ( $proto =~ m{HTTP/(\d(\.\d)?)$} and $1 >= 1 ) {
        
                    my $headers = $self->parse_headers
                        or do { $self->bad_request; return };
        
                    %xheaders = (@$headers);
                    $self->headers($headers);
        
                }
                
                my $do_continue = 1;
                if(defined($xheaders{Expect} && $xheaders{Expect} =~ /100\-continue/i)) {
                    $do_continue = $self->handle_continue_header(%xheaders);
                    flush STDOUT;
                }
                
                if($do_continue) {
                    $self->post_setup_hook if $self->can("post_setup_hook");
            
                    $self->handler;
                }   
            }
        }


    } else {
        # SET UP FOR NON-SSL
        
        # we need to ovverride the _process_request sub for IPv6.
        
        no strict 'refs'; ## no critic (TestingAndDebugging::ProhibitNoStrict)
        *{__PACKAGE__ . "::_process_request"} =
            sub {
        
            my $self = shift;

            # Create a callback closure that is invoked for each incoming request;
            # the $self above is bound into the closure.
            sub {
        
                $self->stdio_handle(*STDIN) unless $self->stdio_handle;
        
                # Default to unencoded, raw data out.
                # if you're sending utf8 and latin1 data mixed, you may need to override this
                binmode STDIN,  ':raw';
                binmode STDOUT, ':raw';
                
                my $remote_sockaddr = getpeername( $self->stdio_handle );
                if(!$remote_sockaddr && defined($main::_realpeername)) {
                    $remote_sockaddr = $main::_realpeername;
                }
                
                my ( $iport, $iaddr, $peeraddr );

                if($remote_sockaddr) {
                    eval {
                        # Be fully backwards compatible
                        ( $iport, $iaddr ) = sockaddr_in($remote_sockaddr);
                        $peeraddr = $iaddr ? ( inet_ntoa($iaddr) || "127.0.0.1" ) : '127.0.0.1';
                        1;
                    } or do {
                        # Handle cases where the $remote_sockaddr is an IPv6 structure
                        #print STDERR $@ . "\n";
                        eval {
                            ( $iport, $iaddr ) = unpack_sockaddr_in6($remote_sockaddr);
                            $peeraddr = inet_ntop(AF_INET6, $iaddr);
                            1;
                        } or do {
                            #print STDERR $@ . "\n";
                            # What is the best way to handle an unparseable $remote_sockaddr?
                            # Will IPv6 be the "old protocol" one day in our lifetime to be superceded
                            # by something even more complex?
                            #
                            # For now, just return "127.0.0.1", which itself is problematic: What
                            # about the time IPv4 gets switched off and some backend will croak because
                            # the IP is too short?
                            $peeraddr = "127.0.0.1";
                        }
                    }
                }
                if(!defined($peeraddr)) {
                    $peeraddr = "";
                } elsif($peeraddr =~ /^\:\:ffff\:(\d+)\./) {
                    # Looks like a IPv4 adress in IPv6 format (e.g. ::ffff:192.168.0.1
                    # turn it into an IPv4 address for backward compatibility
                    $peeraddr =~ s/^\:\:ffff\://;
                }
                
                my ( $method, $request_uri, $proto ) = $self->parse_request;
                
                unless ($self->valid_http_method($method) ) {
                    $self->bad_request;
                    return;
                }
        
                $proto ||= "HTTP/0.9";
        
                # Google-Chrome, Chromium and others sometimes make "futility connections", e.g.
                # they open a connection, do nothing and just close the connection after a few seconds
                if(!defined($request_uri) || $request_uri eq '') {
                    $self->bad_request;
                    return;
                }
                my ( $file, $query_string )
                    = ( $request_uri =~ /([^?]*)(?:\?(.*))?/s );    # split at ?
        
                $self->setup(
                    method       => $method,
                    protocol     => $proto,
                    query_string => ( defined($query_string) ? $query_string : '' ),
                    request_uri  => $request_uri,
                    path         => $file,
                    localname    => $self->host,
                    localport    => $self->port,
                    peername     => $peeraddr,
                    peeraddr     => $peeraddr,
                    peerport     => $iport,
                );
        
                # HTTP/0.9 didn't have any headers (I think)
                my %xheaders;
                if ( $proto =~ m{HTTP/(\d(\.\d)?)$} and $1 >= 1 ) {
        
                    my $headers = $self->parse_headers
                        or do { $self->bad_request; return };
        
                    %xheaders = (@$headers);
                    $self->headers($headers);
        
                }
                
                my $do_continue = 1;
                if(defined($xheaders{Expect} && $xheaders{Expect} =~ /100\-continue/i)) {
                    $do_continue = $self->handle_continue_header(%xheaders);
                    flush STDOUT;
                }
                
                if($do_continue) {
                    $self->post_setup_hook if $self->can("post_setup_hook");
            
                    $self->handler;
                }
            }
        }

    }

    # Ok now fix broken Net::Server*SSL* handling by putting the the SSL options into ARGV
        my @ssl_args = qw(
        SSL_server
        SSL_use_cert
        SSL_verify_mode
        SSL_key_file
        SSL_cert_file
        SSL_ca_path
        SSL_ca_file
        SSL_cipher_list
        SSL_passwd_cb
        SSL_error_callback
        SSL_max_getline_length
    );
    foreach my $ssl_arg (@ssl_args) {
        if(defined($config{$ssl_arg})) {
            push @ARGV, '--' . $ssl_arg . "=" . $config{$ssl_arg};
        }
    }
    
    # Don't call super, just do out stuff here, as we need some changes anyway
    #return $self->SUPER::run(%config); # Call parent run()
    
    #*{__PACKAGE__ . "::_process_request"} = sub {
    {
        my $server = $self->net_server;
    
        local $SIG{CHLD} = 'IGNORE';    # reap child processes
    
        # $pkg is generated anew for each invocation to "run"
        # Just so we can use different net_server() implementations
        # in different runs.
        my $pkg = join '::', ref($self), "NetServer";
        my $thispkg = ref($self);
    
        no strict 'refs';
        *{"$pkg\::process_request"} = $self->_process_request;
    
        if ($server) {
            require join( '/', split /::/, $server ) . '.pm';
            *{"$pkg\::ISA"} = [$server];
    
            # clear the environment before every request
            require HTTP::Server::Simple::CGI;
            *{"$pkg\::post_accept"} = sub {
                HTTP::Server::Simple::CGI::Environment->setup_environment;
                $config{usessl} and $ENV{'HTTPS'} = 'on'; # Required by CGI spec. Also needed for CGI.pm to return 'on' (and not undef) in https() and to return https:// and not http:// links in url().
                # $self->SUPER::post_accept uses the wrong super package
                $server->can('post_accept')->(@_);
            };
            
            *{"$pkg\::post_accept_hook"} = sub {
                my ($xself) = @_;
                $main::_realpeername = $xself->{server}->{peername};
            };
                
        }
        else {
            $self->setup_listener;
        $self->after_setup_listener();
            *{"$pkg\::run"} = $self->_default_run;
        }
    
        #local $SIG{HUP} = sub { $SERVER_SHOULD_RUN = 0; };
    
        $pkg->run( port => $self->port, @_ );
    };
    
    
}

sub handle_continue_header {
    my ($self, %headers) = @_;
    my $continue = 1;
    
    print "HTTP/1.1 100 Continue\r\n";
    
    return $continue;
    
}

1;
__END__

=head1 NAME

HTTP::Server::Simple::CGI::PreFork - Turn HSS into a preforking webserver and enable SSL

=head1 SYNOPSIS

Are you using HTTP::Server::Simple::CGI (or are you planning to)? But you want to handle multiple
connections at once and even try out this SSL thingy everyone is using these days?

Fear not, the (brilliant) HTTP::Server::Simple::CGI is easy to extend and this (only modestly well-designed)
module does it for you.

HTTP::Server::Simple::CGI::PreFork should be fully IPv6 compliant.

=head1 DESCRIPTION

This module is a plugin module for the "Commands" module and handles
PostgreSQL admin commands scheduled from the WebGUI.

=head1 Configuration

Obviously, you want to read the HTTP::Server::Simple documentation for the bulk
of configuration options. Since we also overload the base tcp connection class
with Net::Server, you might also want to read the documentation for that.

We use two Net::Server classes, depending on if we are preforking or single
threaded:

Net::Server::Single for singlethreaded

Net::Server::PreFork for multithreaded

In addition to the HTTP::Server::Simple configuration,
there are only two additional options (in the hash to) the
run() method: usessl and prefork.

=head2 prefork

Basic usage:

$myserver->run(prefork => 1):

Per default, prefork is turned off (e.g. server runs singlethreaded). This
is very usefull for debugging and backward compatibility.

Beware when forking: Keep in mind how database and filehandles behave. Normally,
you should set up everything before the run method (cache files, load confiugurations,...),
then close all handles and run(). Then, depending on your site setup, either open a
database connection for every request and close it again, or (and this is the better
performing option) open a database handle at every request you don't have an open handle yet -
since we are forking, every thread get's its own unique handle while not constantly opening and
closing the handles.

Optionally, you can also add all the different options of Net::Server::Prefork like "max_servers" on
the call to run() to optimize your configuration.

=head2 usessl

Caution: SSL support is experimental at best. I got this to work with a lot of warnings,
sometimes it might not work at all. If you use this, please send patches!

Set this option to 1 if you want to use SSL (default is off). For SSL to actually work, need
to add some extra options (required for the underlying Net::Server classes, something like this
usually does the trick:

$webserver->run(usessl => 1,
                proto => 'ssleay',
                "--SSL_key_file"=> 'mysite.key',
                "--SSL_cert_file"=>'mysite.crt',
                );


=head2 run

Internal functions that overrides the HTTP::Server::Simple::CGI run function. Just as explained above.

=head2 handle_continue_header

Overrideable function that allows to to custom-handle the "100 Continue" status codes. This function
is called if the client sends a a "Expect: 100-continue" header. It defaults to sending a "100 Continue"
status line and proceed with the rest of the request.

If you want to override this, for example to check upload size or permissions, subclass this function. You
will recieve the headers as a hash as the only input (nothing much else has been parsed from the client as of
this moment in time).

It is your job to send/print the appropriate status line header, either "100 Continue" or the appropriate error code.
Return true if you want HSS::Prefork to continue data transfer and finish setting up the CGI environment for the request
or false to abort.

BEWARE: Since only the headers have been parsed at this point of time, you don't have the full CGI kaboodle at your disposal.
The way HSS:Prefork overrides the base modules, the internal setup phase is not complete and you should only use the headers
provided to make a basic decision if you want to continue and make a full check later (permissions, client IP, whatever) on,
just as you would when the client wouldn't have send the Expect-Header

=head1 IPv6

This module overrides also the pure IPv4 handling of HTTP::Server::Simple::CGI and turns
it into an IPv4/IPv6 multimode server.

Only caveat here is, that you need the Net::Server modules in version 2.0
or higher. If you still use Net::Server 0.99.6.*, you should install
HTTP::Server::Simple::CGI::PreFork 1.2 from BackPan. 

Net::Server version 0.99 and lower only supports IPv4.

=head1 Possible incompatibilities with your computer

Older versions of HSSC::Prefork did not automatically require the IPv6 modules on installation.
This behaviour has changed, starting at version 2.0. This is in accordance with with RFC6540, titled
"IPv6 Support Required for All IP-Capable Nodes". If you don't have an IPv6 address, thats OK (or more
precisely *your* problem). But the software now assumes that your system is technicaly capable of handling 
IPv6 connections, even if you don't have an IPv6 uplink at the moment.

Doing it this way simplifies many future tasks. Anyway, if your system is old enough to be incapable of
handling IPv6... according to RFC6540 you are not connected to what is nowadays defined as "the internet".


=head1 QUICK-HACK-WARNING

This module "patches" HTTP::Server::Simple by overloading one
of the functions. Updating HTTP::Server::Simple *might* break
something. While this is not very likely, make sure to test
updates before updating a production system!

=head1 AUTHOR

Rene Schickbauer, E<lt>cavac@cpan.orgE<gt>

This module borrows heavily from the follfowing modules:

HTTP::Server::Simple by Jesse Vincent

Net::Server by Paul T. Seamons

HTTPS bugfix for version 6 by Luigi Iotti

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.

=head1 THANKS

Special thanks to Jesse Vincent for giving me quick feedback when i needed it.

Also thanks to the countless PerlMonks helping me out when i'm stuck. This module
is dedicated to you!

=cut

