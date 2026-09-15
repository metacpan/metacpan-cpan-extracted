use v5.36;
use strict;
use warnings;
use Test::More;
use Socket qw(AF_INET SOCK_STREAM inet_aton pack_sockaddr_in);

use Linux::Event::Loop;
use Linux::Event::IO::Sock::Listener;

{
    package T::BatchStream;
    use parent 'Linux::Event::IO::Sock::Stream';
    sub on_ready ($stream) {
        push @{ $stream->data->{accepted} }, $stream;
        $stream->loop->stop
            if @{ $stream->data->{accepted} } == $stream->data->{target};
    }
    sub on_data ($stream, $bytes) { }
}

my $loop = Linux::Event::Loop->new;
my $state = { accepted => [], target => 7 };
my $listener = Linux::Event::IO::Sock::Listener->new(
    loop => $loop, host => '127.0.0.1', port => 0,
    stream => { class => 'T::BatchStream', data => $state },
    max_accept_per_tick => 2,
);
my @clients;
for (1 .. $state->{target}) {
    socket(my $client, AF_INET, SOCK_STREAM, 0) or die "socket: $!";
    connect($client,
        pack_sockaddr_in($listener->port, inet_aton('127.0.0.1')))
        or die "connect: $!";
    push @clients, $client;
}
$loop->run;

ok(!$state->{error}, 'bounded accept batches complete without errors');
is(scalar(@{ $state->{accepted} }), $state->{target},
    'level-triggered watcher revisits backlog after each bounded batch');
is($listener->accepted, $state->{target},
    'accepted counter spans multiple native batches');

$_->close for @{ $state->{accepted} };
close $_ for @clients;
$listener->close;
done_testing;
