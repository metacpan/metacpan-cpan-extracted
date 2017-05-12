#!/usr/bin/env perl 
use strict;
use warnings;

use IO::Socket::INET;
use IO::EventMux;
use IO::Buffered::HTTP;
use Compress::Zlib;
use Compress::Bzip2;

# http://www.oreilly.com/openbook/webclient/ch03.html

#add_site(
#    url => 'http://www.google.com',
#    interval => 10 * 60,
#);

my $mux = IO::EventMux->new();

sub http_get {
    my ($host, $port, $document) = @_;
    print "GET $host:$port$document";
    
    my $fh = IO::Socket::INET->new(
        PeerAddr => $host,
        PeerPort => $port,
        Proto    => 'tcp',
        Blocking => 0,
    ) or die;
    $mux->add($fh, Buffered => new IO::Buffered::HTTP(HeaderOnly => 1));

    my $HTTP_HDR = 
        "GET $document HTTP/1.1\r\n".
        "Host: $host\r\n".
        "User-Agent: Mozilla/5.0 Gecko/20080325 Firefox/2.0.0.13\r\n".
        "Accept: text/xml,application/xml,application/xhtml+xml,".
            "text/html;q=0.9,text/plain;q=0.8,image/png,*/*;q=0.5\r\n".
        "Accept-Language: en-us,en;q=0.5\r\n".
        "Accept-Encoding: gzip,deflate\r\n".
        "Accept-Charset: ISO-8859-1,utf-8;q=0.7,*;q=0.7\r\n".
        "Keep-Alive: 300\r\n".
        "Connection: keep-alive\r\n\r\n";
    
    $mux->send($fh, $HTTP_HDR);
}

http_get("www.google.com", "80", "/");

while(1) {
    my $event = $mux->mux(10);
   
    print "$event->{type}\n"; 
    #use Data::Dumper; print Dumper($event);
    
    if($event->{type} eq 'ready') {
    
    } elsif($event->{type} eq 'read') {
        my $headers = parse_header($event->{data});

        if($headers->{status} eq '302') {
            if($headers->{Location} =~ m{
                (?:(http[s]?)://([^/]+))? # Match domain part if it exists
                (.*?) # Match document part if it exists
                (?:\r\n|$)}sx) {
                my ($port, $domain, $document) = ($1, $2, $3);
                
                http_get($domain, "80", $document);
            }

        } elsif ($event->{status} eq '200') {
            my $ce = ($options{'Content-Encoding'} or '');
            my $cl = ($headers{'Content-Length'} or -1);
            
            if ($ce eq "gzip" or $ce eq "x-gzip") {
                my $x = deflateInit()
                   or die "Cannot create a deflation stream\n" ;
                
                # Receive file of size Content-Length with Perl GZIP filter in 4K chunks
                $mux->recvfile("/tmp/httpfile", $event->{fh}, $cl, 4096, sub {
                    my ($output, $status) = $x->deflate($_[0]);
                    $status == Z_OK or die "deflation failed\n";
                    return $output;
                });
                
		    } elsif ($ce eq "x-bzip2") {
                # Receive file by forking a new bzip2 process a pipe data to it in 4K chunks
                #$mux->recvfile("/tmp/httpfile", $event->{fh}, $cl, 4096, 
                #    qw(bzip2 -d));
            
            } else {
                # Receive file directly to file
                $mux->recvfile("/tmp/httpfile", $event->{fh}, $cl);
            }

            # Receive as normal read events in chunks of 4K
            #$mux->recvevent('read', $event->{fh}, $cl, 4096);
        
        } else {
            print "Unknown status code $headers{status}\n";
        }
    }

}



