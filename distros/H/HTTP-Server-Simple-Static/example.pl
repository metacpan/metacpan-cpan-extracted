#!/usr/bin/perl
use strict;
use warnings;

package MyServer;

use lib qw(./lib);
use base 'HTTP::Server::Simple::CGI';
use HTTP::Server::Simple::Static;

my $webroot = '/tmp';

sub handle_request {
    my ( $self, $cgi ) = @_;

    if ( !$self->serve_static( $cgi, $webroot ) ) {
        print "HTTP/1.0 404 Not found\r\n";
        print $cgi->header, 
        $cgi->start_html('Not found'),
        $cgi->h1('Not found'),
        $cgi->end_html;
    }
}

package main;

my $server = MyServer->new();
$server->run();


