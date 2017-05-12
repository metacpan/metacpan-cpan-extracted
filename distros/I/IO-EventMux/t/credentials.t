use strict;
use warnings;

use Test::More tests => 1;

use IO::EventMux;
use File::Temp qw(tempfile);
use IO::Socket::UNIX;

# Get a filename to listen to
my ($fh, $filename) = tempfile();
close $fh;
unlink($filename);

my $listener = IO::Socket::UNIX->new(
    Listen   => SOMAXCONN,
    Blocking => 1,
    Local    => $filename,
) or die "Listening to ${filename}: $!";


my $connected = IO::Socket::UNIX->new(
    Blocking => 1,
    Peer     => $filename,
) or die "Listening to ${filename}: $!";

my %fhs = ( $listener => 'listener', $connected => 'connected' );

my $mux = IO::EventMux->new();
$mux->add($listener);
$mux->add($connected);

while(1) {
    my $event = $mux->mux(5);

    #print "FH:".($fhs{$event->{fh}} or 'new') ."\n" if exists $event->{fh};
    use Data::Dumper; print Dumper($event);
    
    if($event->{type} eq 'accepted') {
        is_deeply($event, {
            pid => $$,
            gid => (split(/\s/,$())[0],
            uid => $<,
            parent_fh => $listener,
            fh => $event->{fh},
            type => 'accepted',
        }, "We got back credentials");
        exit;
    
    } elsif($event->{type} eq 'error') {
        use Data::Dumper;
        print Dumper($event);
        fail "Got error";
        exit;

    } elsif($event->{type} eq 'timeout') {
        fail "Got timeout";
        exit;
    }
}
