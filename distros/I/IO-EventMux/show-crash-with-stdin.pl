#!/usr/bin/env perl
use strict;
use warnings;

# FIXME: Make in to test

use lib "lib";
use Carp;
use IO::EventMux;
use IO::Buffered;

$SIG{PIPE} = sub { croak "Broken pipe"; };
$SIG{__WARN__} = sub { croak @_; };

pipe my $readerOUT, my $writerOUT or die;
pipe my $readerERR, my $writerERR or die;
pipe my $readerIN, my $writerIN or die;

#eval {
#    local($SIG{__WARN__})=sub{};
#    sysread($writerOUT, my $data, 10);
#    croak $!;
#};
#if($@ =~ /Bad file descriptor/) {
#    print "$@\n";
#}
#exit;

my $pid = fork;
if ($pid == 0) {
    close $readerOUT or die;
    close $readerERR or die;
    close $writerIN or die;
    open STDOUT, ">&", $writerOUT or die;
    open STDERR, ">&", $writerERR or die;
    open STDIN, ">&", $readerIN or die;
    exec "tftp";
    die;
}

close $writerOUT;
close $writerERR;
close $readerIN;

$readerOUT->autoflush(1);
$readerERR->autoflush(1);
$readerIN->autoflush(1);

my $mux = IO::EventMux->new;
$mux->add($readerOUT, Buffered => new IO::Buffered(Split => qr/\n/));
$mux->add($readerERR, Buffered => new IO::Buffered(Split => qr/\n/));
$mux->add($writerIN, Buffered => new IO::Buffered(Split => qr/\n/));

print "OUT($readerOUT)\n";
print "ERR($readerERR)\n";
print "IN($writerIN)\n";

while (my $event = $mux->mux) {
    use Data::Dumper; print Dumper($event);
   
    print "$event->{data}\n" if defined $event->{data};

    if($event->{type} eq 'ready') {
        #$mux->send($event->{fh}, "?\n");
        $mux->send($event->{fh}, "quit\n");
    }

    if($event->{type} eq 'sent') {
        $mux->send($event->{fh}, "?\n");
        #$mux->close($event->{fh});
    }
    
    if($event->{fh} eq $readerOUT and $event->{type} eq 'closed') {
        #exit;
    }

}

# vim: et tw=79 sw=4 sts=4
