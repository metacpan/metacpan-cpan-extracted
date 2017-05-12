#!/usr/bin/env perl
use strict;
use warnings;

# This example program shows how to wait for a child process and listen to it's
# STDERR, STDOUT and send data to it's STDIN using EventMux. It waits for the 
# child to close its stdout, which for most programs is evidence that it is 
# terminating. Then it calls waitpid to collect the child's exit status and 
# prevent it from becoming a zombie. This call to waitpid is blocking in
# theory, but it will happen instantly for well-behaved children.

use lib "lib";
use IO::EventMux;
use IO::Buffered;
use Carp;

$SIG{PIPE} = sub { croak "Broken pipe"; };
$SIG{__WARN__} = sub { croak @_; };

my $mux = IO::EventMux->new;

pipe my $readerOUT, my $writerOUT or die;
pipe my $readerERR, my $writerERR or die;
pipe my $readerIN, my $writerIN or die;

my $pid = fork;
if ($pid == 0) {
    close $readerOUT or die;
    close $readerERR or die;
    close $writerIN or die;
    open STDOUT, ">&", $writerOUT or die;
    open STDERR, ">&", $writerERR or die;
    open STDIN, ">&", $readerIN or die;
    exec "sh", "-c", q(cat);
    die;
}

close $writerOUT;
close $writerERR;
close $readerIN;

$mux->add($readerOUT, Buffered => new IO::Buffered(Split => qr/\n/));
$mux->add($readerERR, Buffered => new IO::Buffered(Split => qr/\n/));
$mux->add($writerIN, Buffered => new IO::Buffered(Split => qr/\n/));

print "OUT($readerOUT)\n";
print "ERR($readerERR)\n";
print "IN($writerIN)\n";

my $dataIN = "hello\n" x 1;
my $dataOUT = '';
my $dataERR = '';

my $closed = 0;
while (my $event = $mux->mux) {
    print "Got event: $event->{type} : $event->{fh} \n";

    if ($event->{type} eq "ready" and ($event->{fh} == $writerIN)) {
        $mux->send($event->{fh}, $dataIN);

    } elsif ($event->{type} eq "read" and ($event->{fh} == $readerOUT)) {
        $dataOUT .= $event->{data};
        if(length($dataIN)-1 == length($dataOUT)) {
            $mux->kill($writerIN);
        }
    
    } elsif ($event->{type} eq "read" and ($event->{fh} == $readerERR)) {
        $dataERR .= $event->{data};
    
    } elsif ($event->{type} eq "closed" and ($event->{fh} == $readerOUT)) {
        print "OUT:$dataOUT\n";

        if($closed++) {
            waitpid $pid, 0;
            print "Exit status: $?\n";
            last;
        }
    
    } elsif ($event->{type} eq "closed" and ($event->{fh} == $readerERR)) {
        print "ERR:$dataERR\n";
        
        if($closed++) {
            waitpid $pid, 0;
            print "Exit status: $?\n";
            last;
        }
    }
}

# vim: et tw=79 sw=4 sts=4
