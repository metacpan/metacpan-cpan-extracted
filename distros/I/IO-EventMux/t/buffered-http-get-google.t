use strict;
use warnings;

use Test::More tests => 1;

use IO::EventMux;

my $hasIOBuffered = 1;

eval 'require IO::Buffered';
if ($@) {
    $hasIOBuffered = 0;
}

# FIXME: Skip anyway as this test hangs, we need to make the HTTP buffer at bit smarter.
$hasIOBuffered = 0;

SKIP: {
    skip "IO::Buffered not installed or skiped because test hangs", 1 unless $hasIOBuffered;
    my $mux = IO::EventMux->new;

    http_get("www.google.com", 80, "/");

    while(1) {
        my $event = $mux->mux(10);
        my $type = ($mux->meta($event->{fh}) or '');

        print "$event->{type} : $type\n"; 
        #use Data::Dumper; print Dumper($event);

        if($event->{type} eq 'read' and $type eq 'header') {
            if(my ($header, $status) = parse_http_header($event->{data})) {
                if($status eq '302') {
                    if($header =~ m{Location:\s
                            (?:(http[s]?)://([^/]+))? # Match domain part if it exists
                            (.*?) # Match document part if it exists
                            (?:\r\n|$)}sx) {
                        my ($port, $host, $newdocument) = ($1, $2, $3);

                        if($port eq 'http') {            
                            http_get($host, "80", $newdocument);
                        } else {
                            die "SSL not supported: ${port}://$host/$newdocument";
                        }

                    } else {
                        die "Could not parse Location: $header";
                    }

                    $mux->kill($event->{fh});

                } elsif ($status eq '200') {
                    print "$header\n";

                    if($header =~ /(Content-Length):\s(\d+)(?:\r\n|$)/sgx) {
                        $mux->recvdata($event->{fh}, $1);
                    } else {
                        $mux->recvdata($event->{fh}, 10);
                        #die "Could not parse Content-Length: $header";
                    }
                    $mux->meta($event->{fh}, 'data');

                } else {
                    print "Unknown status code $status\n";
                }

            } else {
                die "Could not parse header";
            }

        } elsif($event->{type} eq 'read' and $type eq 'data') {
            print "$event->{data}\n";
            #$mux->meta($event->{fh}, 'header');
        }
    }

    sub http_get {
        my ($host, $port, $document) = @_;
        print "GET $host:$port$document\n";

        my $fh = IO::Socket::INET->new(
            PeerAddr => $host,
            PeerPort => $port,
            Proto    => 'tcp',
            Blocking => 0,
        ) or die;

        $mux->add($fh, 
            Buffered => new IO::Buffered::HTTP(HeaderOnly => 1),
            Meta => 'header',
        );

        my $HTTP_HDR = 
        "GET $document HTTP/1.1\r\n".
        "Host: $host\r\n".
        "User-Agent: Mozilla/5.0 Gecko/20080325 Firefox/2.0.0.13\r\n".
        "Accept: text/xml,application/xml,application/xhtml+xml,".
        "text/html;q=0.9,text/plain;q=0.8,image/png,*/*;q=0.5\r\n".
        "Accept-Language: en-us,en;q=0.5\r\n".
        "Accept-Charset: ISO-8859-1,utf-8;q=0.7,*;q=0.7\r\n".
        "\r\n\r\n";
        $mux->send($fh, $HTTP_HDR, );

        return $fh;
    }

    sub parse_http_header {
        my ($header) = @_;

        if($header =~ m{
                ^HTTP/(1\.1|1\.0)\s # Version
                (302|200).+?\r\n # Status code
                (.*?)\r\n\r\n$ # Headers
            }sx) {
            return ($3, $2, $1);
        } else {
            return;
        }
    }
}
