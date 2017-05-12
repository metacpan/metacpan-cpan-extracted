use strict;
use warnings;

use Test::More tests => 2;
use IO::EventMux;
use Data::Dumper;

# FIXME: Add something to the data stream so buffering matters ie. multi request pr. fh.

my $hasIOBuffered = 1;

eval 'require IO::Buffered';
if ($@) {
    $hasIOBuffered = 0;
}

SKIP: {
    skip "IO::Buffered not installed", 2 unless $hasIOBuffered;

    my $mux = IO::EventMux->new();

    sub string_fh {
        my $pid = open my $infh, "-|";
        die if not defined $pid;

        if ($pid == 0) {
            use IO::Handle;
            STDOUT->autoflush(1);
            STDERR->autoflush(1);
            foreach my $var (@_) {
                print $var;
                #sleep 1;
            }
            exit;
        }
        return $infh;
    }

    # Handle WSDL request
    my @data = ( 
        "POST /soap HTTP/1.1\r\n".
        "Host: localhost:1981\r\n".
        "Connection: Keep-Alive\r\n".
        "User-Agent: PHP-SOAP/5.2.5\r\n".
        "Content-Type: text/xml; charset=utf-8\r\n".
        "SOAPAction: \"http://soap.netlookup.dk/test/get_commits\"\r\n".
        "Content-Length: 264\r\n\r\n",
        "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\r\n".
        "<SOAP-ENV:Envelope xmlns:SOAP-ENV=".
        "\"http://schemas.xmlsoap.org/soap/envelope/\" xmlns:ns1=\"".
        "http://soap.netlookup.dk/svn\">".
        "<SOAP-ENV:Body><ns1:get_commits><limit>0,30</limit></ns1:".
        "get_commits></SOAP-ENV:Body></SOAP-ENV:Envelope>");

    my $goodfh = string_fh(@data);
    $mux->add($goodfh, Buffered => new IO::Buffered(HTTP => 1));

    my %types;
    while ($mux->handles > 0) {
        my $event = $mux->mux();
        $types{$event->{fh}}{types} .= $event->{type};

        if($event->{type} eq 'read') {
            $types{$event->{fh}}{data} .= $event->{data};
        } 
    }

    is($types{$goodfh}{types}, join("", qw(read closing closed)),
        "Type came back in the right order");

    is($types{$goodfh}{data}, join("", @data), "Data was correct");
}
