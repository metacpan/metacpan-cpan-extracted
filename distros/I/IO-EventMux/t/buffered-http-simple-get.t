use strict;
use warnings;

use Test::More tests => 2;
use IO::EventMux;
use Data::Dumper;

my $hasIOBuffered = 1;

eval 'require IO::Buffered';
if ($@) {
    $hasIOBuffered = 0;
}

SKIP: {
    skip "IO::Buffered not installed", 2 unless $hasIOBuffered;

    # FIXME: Add something where buffering would matter, ie try changing to none

    my $mux = IO::EventMux->new();

    sub string_fh {
        my $pid = open my $infh, "-|";
        die if not defined $pid;

        if ($pid == 0) {
            print @_;
            exit;
        }
        return $infh;
    }

    # Handle WSDL request
    my $data = "GET /soap.php?WSDL HTTP/1.0\x0d\x0a".
    "Host: localhost\x0d\x0a\x0d\x0a";

    my $goodfh = string_fh($data);
    $mux->add($goodfh, Buffered => new IO::Buffered(HTTP => 1));

    print "goodfh: $goodfh\n";

    my %types;
    while ($mux->handles > 0) {
        my $event = $mux->mux();
        print "type: $event->{type}\n";
        $types{$event->{fh}}{types} .= $event->{type};

        if($event->{type} eq 'read') {
            $types{$event->{fh}}{data} .= $event->{data};
        } else {
            print "$event->{type}: '".
            (defined $event->{data} ? $event->{data} : 'undef')
            ."'\n";
        }
    }

    is($types{$goodfh}{types}, join("", qw(read closing closed)),
        "Type came back in the right order");

    is($types{$goodfh}{data}, $data, "Data was correct");

};

