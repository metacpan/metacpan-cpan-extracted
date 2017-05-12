#!/usr/bin/env perl 
use strict;
use warnings;

use IO::Socket::INET;
use IO::EventMux;
use IO::Buffered;
use Compress::Zlib;
use Compress::Bzip2;

# http://www.oreilly.com/openbook/webclient/ch03.html

#add_site(
#    url => 'http://www.google.com',
#    interval => 10 * 60,
#);

my $mux = IO::EventMux->new();

http_get("www.google.com", "80", "/");

while(1) {
    my $event = $mux->mux(10);
   
    print "$event->{type}\n"; 
    #use Data::Dumper; print Dumper($event);
    
    if($event->{type} eq 'ready') {
    
    } elsif($event->{type} eq 'read') {
        if($event->{data} =~ m{
            ^HTTP/(1\.1|1\.0)\s # Version
            (302|200).+?\r\n # Status code
            (.*?)\r\n\r\n # Header
            (.*?)$ # Data
            }sx) {
            my ($version, $status, $header, $data) = ($1, $2, $3, $4);

            if($status eq '302') {  # Document moved
                if($header =~ m{Location:\s
                    (?:(http[s]?)://([^/]+))? # Match domain part if it exists
                    (.*?) # Match document part if it exists
                    (?:\r\n|$)}sx) {
                    my ($port, $domain, $document) = ($1, $2, $3);
                    
                    # FIXME: Handle loops
                    # FIXME: Handle change of port
                    # FIXME: Handle domain not defined
                    # FIXME: Handle document not defined
                    print "$port, $domain, $document\n";
                    http_get($domain, "80", $document);
                }
            }
            
            my %options = ($header =~ 
                /(Content-Encoding|Content-Length):\s(.+?)(?:\r\n|$)/sgx);
            #use Data::Dumper; print Dumper(\%options);
            #print "$header\n"; 
            
            # TODO: Finish and support more formats and bad browsers:
            #       /usr/share/perl5/HTTP/Message.pm
            # TODO: Protect against bad zip files with zero data
            # Get the content encoding
            my $ce = ($options{'Content-Encoding'} or ''); 
            if ($ce eq "gzip" or $ce eq "x-gzip") {
		        if(my $content = Compress::Zlib::memGunzip($data)) {
                    print "$content\n";
                }
		    } elsif ($ce eq "x-bzip2") {
		        if(my $content = Compress::Bzip2::decompress($data)) {
                    print "$content\n";
                }
            } elsif ($ce eq "gzip" or $ce eq "x-gzip") {
		        if(my $content = Compress::Bzip2::uncompress($data)) {
                }
            
            } else {
                #print "$header\n$data\n";
            }

            # FIXME: handle fetching "style="background:url(/intl/en_com/images/logo_plain.png"


            # FIXME: Support HTTP/1.1 302 Found
            #        Location: http://www.google.dk/

        } else {
            print "Could not parse HTTP header\n";
        }
    }

}

sub http_get {
    my ($host, $port, $document) = @_;
    print "GET $host:$port$document";
    
    my $fh = IO::Socket::INET->new(
        PeerAddr => $host,
        PeerPort => $port,
        Proto    => 'tcp',
        Blocking => 0,
    ) or die;
    $mux->add($fh, Buffered => new IO::Buffered(HTTP => 1) );

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


