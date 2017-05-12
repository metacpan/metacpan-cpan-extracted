#!/usr/bin/perl

use strict;
use warnings;

use CGI;
use HTTP::Daemon;
use HTTP::Request;
use HTTP::Request::AsCGI;
use HTTP::Response;
use URI;

$SIG{'PIPE'} = 'IGNORE';

my $server = HTTP::Daemon->new( LocalPort => 3000, ReuseAddr => 1 )
  or die( "Can't create daemon: $!" );

print "Please contact me at: <URL:", $server->url, ">\n";

while ( my $client = $server->accept ) {
    
    my %e = (
        REMOTE_ADDR => $client->peerhost,
        REMOTE_HOST => $client->peerhost,
        REMOTE_PORT => $client->peerport
    );

    while ( my $request = $client->get_request ) {

        unless ( $request->uri->host ) {
            $request->uri( URI->new_abs( $request->uri, $server->url ) );
        }

        my $c = HTTP::Request::AsCGI->new( $request, %e )->setup;
        my $q = CGI->new;

        print $q->header( -charset => 'UTF-8' ),
              $q->start_html( 
                  -title    => 'Hello World',
                  -encoding => 'UTF-8'
              ),
              $q->h1('Hello World'),
              $q->start_form,
              $q->table(
                  $q->Tr( [
                      $q->td( [ 'Name',  $q->textfield( -name => 'name'  ) ] ),
                      $q->td( [ 'Email', $q->textfield( -name => 'email' ) ] ),
                      $q->td( [ 'Phone', $q->textfield( -name => 'phone' ) ] ),
                      $q->td( [ 'File',  $q->filefield( -name => 'file'  ) ] )
                  ] )
              ),
              $q->submit,
              $q->end_form,
              $q->h2('Parameters'),
              $q->Dump,
              $q->h2('Enviroment'),
              $q->table(
                  $q->Tr( [
                      map{ $q->td( [ $_, $ENV{$_} ] ) } sort keys %ENV
                  ] )
              ),
              $q->end_html;

        my $response = $c->restore->response;

        # tell client to close socket to prevent blocking problems
        # in this single threaded daemon.
        $response->header( Connection => 'close' );

        $client->send_response($response);
    }

    $client->close;
}
