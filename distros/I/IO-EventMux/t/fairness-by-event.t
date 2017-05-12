use strict;
use warnings;

# FIXME: Rewrite so it does not fail on *BSD or when the machine is slow. 

use Test::More tests => 9;
use IO::EventMux;

my $hasIOBuffered = 1;

eval 'require IO::Buffered';
if ($@) {
    $hasIOBuffered = 0;
}

SKIP: {
    skip "IO::Buffered not installed", 9 unless $hasIOBuffered;

    my $mux = IO::EventMux->new(ReadPriorityType => ['FairByEvent']);

    sub create_writer {
        my ($data) = @_;

        pipe my ($readerOUT), my ($writerOUT) or die;

        my $pid = fork;
        if ($pid == 0) {
            close $readerOUT or die;
            print {$writerOUT} $data;
            sleep 1; 
            exit;
        }

        close $writerOUT;
        $mux->add($readerOUT, 
            Buffered => new IO::Buffered(Split => qr/\n/),
            ReadSize => 4,
            Meta => { pid => $pid },
        );

        return $readerOUT;
    }

    my $count = 0;

    my $select = IO::Select->new();
    foreach my $i (1..3) {
        my $fh = create_writer(("hello\n" x  3));
        # Sleep until we can read on the socket
        $select->add($fh); $select->can_read(3); $select->remove($fh);
        $count++; 
    }

    my $lastfh = '';
    while (my $event = $mux->mux()) {
        my $fh = $event->{fh};
        my $data = ($event->{data} or '');
        my $meta = $mux->meta($fh);

        # Wait to make sure everybody is ready to fill the buffer.
        print "Got event($fh): $event->{type} -> '$data'\n";

        if ($event->{type} eq "ready") {
        } elsif ($event->{type} eq "read") {
            ok($fh ne $lastfh, "We got a new file handle this time");

        } elsif ($event->{type} eq "closing") {
            waitpid $meta->{pid}, 0;
            print "Exit status: $?\n";

        } elsif ($event->{type} eq "closed") {
            if(--$count == 0) {
                last;
            }
            print "count:$count\n";

        } elsif ($event->{type} eq "timeout") {
        } elsif ($event->{type} eq "read_last") {
        } else {
            die("Unknown event type $event->{type}");
        }

        $lastfh = $fh;
    }
}
